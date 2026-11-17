// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
#include "lua.h"
#include "lualib.h"
#include "luacode.h"

#include "Luau/Common.h"

#include <string>
#include <unordered_set>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// Runs untrusted source the way an embedder that hosts plugins does: one VM per input, with a memory cap enforced by
// the allocator, a CPU-time budget enforced by the interrupt, and the sandbox. The value the chunk returns is read back
// through the C API with bounded depth and size; when it is a function, it is called again with a table built by the
// host, and its result is read back as well.
//
// A call must not run past its budget: the longest stretch of CPU time between two interrupt calls, and the CPU time
// from the end of the budget to the end of the call, are each held to a stall limit. Past it the run aborts, so libFuzzer
// saves the input. The limit is 100 ms, times 5 under AddressSanitizer and times 2 without it; LUAU_FUZZ_STALL_MS=N sets
// it.
//
// Flags keep their defaults unless set with --fflags=name,name=false,... ('true' sets every Luau flag).
//
// Build with the C stack limit an embedder like mlua uses, and run:
//   make config=fuzz CXX="clang++ -DLUAI_MAXCSTACK=1000000" fuzz-plugin
//   ./fuzz-plugin -timeout=5 -max_len=65536 -dict=fuzz/syntax.dict corpus/ tests/conformance/

namespace
{

const size_t kMaxSource = 64 << 10;
const long long kMemoryCap = 32 << 20;
const long long kMemoryRoom = 64 << 10; // a call that leaves less room than this under the cap fails the plugin
const double kBudgetMs = 100;
#if defined(__has_feature)
#if __has_feature(address_sanitizer)
#define FUZZ_PLUGIN_ASAN 1
#endif
#endif
// A stretch of 100 ms of CPU in a release build is 1.2x to 9x longer under AddressSanitizer and UBSan (memcmp loops gain
// least, byte loops most), and up to 2.3x longer with libFuzzer's coverage instrumentation alone
#if defined(__SANITIZE_ADDRESS__) || defined(FUZZ_PLUGIN_ASAN)
const double kStallMs = 100 * 5;
#else
const double kStallMs = 100 * 2;
#endif
const int kMaxPrint = 4 << 10;
const int kMaxDepth = 128;
const long kMaxParts = 16 * 20000;
const long long kMaxBytes = 32 << 20;

struct Memory
{
    long long used = 0;
    bool limitReached = false;
    bool ignoreLimit = false; // set while the host works outside a protected call: VM setup and its own pushes
};

Memory memory;

void* allocate(void* ud, void* ptr, size_t osize, size_t nsize)
{
    Memory* m = static_cast<Memory*>(ud);
    m->limitReached = false;

    if (nsize == 0)
    {
        if (ptr)
        {
            free(ptr);
            m->used -= osize;
        }
        return nullptr;
    }

    long long diff = (long long)nsize - (ptr ? (long long)osize : 0);
    if (diff > 0 && m->used + diff > kMemoryCap && !m->ignoreLimit)
    {
        m->limitReached = true;
        return nullptr;
    }

    void* result = ptr ? realloc(ptr, nsize) : malloc(nsize);
    if (!result)
        abort();

    m->used += diff;
    return result;
}

double clockMs(clockid_t clock)
{
    timespec ts;
    clock_gettime(clock, &ts);
    return ts.tv_sec * 1e3 + ts.tv_nsec / 1e6;
}

double cpuMs()
{
    return clockMs(CLOCK_THREAD_CPUTIME_ID);
}

struct Budget
{
    bool armed = false;
    bool stopped = false;
    double start = 0;    // thread CPU time at the start of the call
    double lastCpu = 0;  // thread CPU time when it was last read
    double lastWall = 0; // wall time when the thread CPU time was last read
    double maxGap = 0;   // the longest stretch between two interrupt calls, at most 1 ms over
};

Budget budget;
double stallMs = kStallMs;

// Reads the thread CPU time, a system call, once a millisecond of wall time passed since the last read; the wall clock
// is cheap. So a call stops within a millisecond past the budget, and each stretch between two interrupt calls is
// measured with at most a millisecond too much: a stretch that ends without a read is shorter than that.
void interrupt(lua_State* L, int gc)
{
    if (gc >= 0 || !budget.armed)
        return;

    if (!budget.stopped)
    {
        double wall = clockMs(CLOCK_MONOTONIC);
        if (wall - budget.lastWall < 1)
            return;

        double now = cpuMs();
        if (now - budget.lastCpu > budget.maxGap)
            budget.maxGap = now - budget.lastCpu;
        budget.lastCpu = now;
        budget.lastWall = wall;

        if (now - budget.start < kBudgetMs)
            return;
    }

    // once the budget is spent, every safepoint raises again, so a pcall in the plugin cannot keep the call running
    budget.stopped = true;
    luaL_error(L, "stopped by the budget");
}

void checkStall(double end)
{
    double gap = end - budget.lastCpu > budget.maxGap ? end - budget.lastCpu : budget.maxGap;
    double late = end - budget.start - kBudgetMs;

    if (gap > stallMs || late > stallMs)
    {
        fprintf(
            stderr, "fuzz-plugin: stall: %.1f ms of CPU between two interrupt calls, %.1f ms past the budget (limit %.0f ms)\n", gap, late, stallMs
        );
        abort();
    }
}

int messageHandler(lua_State* L)
{
    if (memory.limitReached || !lua_checkstack(L, 2))
        return 1;

    const char* s = luaL_tolstring(L, -1, nullptr);
    if (lua_checkstack(L, 11))
    {
        luaL_traceback(L, L, s, 0);
        lua_remove(L, -2);
    }
    return 1;
}

int collectgarbage(lua_State* L)
{
    const char* option = luaL_optstring(L, 1, "collect");
    if (strcmp(option, "count") == 0)
    {
        lua_pushnumber(L, lua_gc(L, LUA_GCCOUNT, 0) + lua_gc(L, LUA_GCCOUNTB, 0) / 1024.0);
        return 1;
    }
    luaL_error(L, "collectgarbage called with invalid option");
}

// keeps at most kMaxPrint bytes of the arguments, converted by tostring, and writes nothing
int print(lua_State* L)
{
    int n = lua_gettop(L);
    char kept[kMaxPrint];
    size_t used = 0;

    for (int i = 1; i <= n; i++)
    {
        size_t len = 0;
        const char* s = luaL_tolstring(L, i, &len);
        size_t take = len < sizeof(kept) - used ? len : sizeof(kept) - used;
        memcpy(kept + used, s, take);
        used += take;
        lua_pop(L, 1);
    }

    volatile char last = used ? kept[used - 1] : 0;
    (void)last;
    return 0;
}

// Reads a value the way a host converts it to its own data: tables are walked with lua_rawiter on the stack, each table
// at most once, within a depth, a count of parts and a count of string bytes; the first refusal ends the walk.
struct Walk
{
    long parts = 0;
    long long bytes = 0;
    std::unordered_set<const void*> seen;
};

bool readString(lua_State* L, int idx, Walk& w)
{
    size_t len = 0;
    const char* s = lua_tolstring(L, idx, &len);
    w.bytes += len;
    if (w.bytes > kMaxBytes)
        return false;

    volatile char last = len ? s[len - 1] : 0;
    (void)last;
    return true;
}

bool walk(lua_State* L, int idx, int depth, Walk& w);

// A key 1..length is an array slot, and the host fills the slots before it, so a gap counts as parts; any other key
// makes the table an object, whose keys must be strings or numbers
bool walkKey(lua_State* L, int length, int& filled, Walk& w)
{
    int type = lua_type(L, -2);
    if (type == LUA_TSTRING)
    {
        filled = -1;
        return readString(L, -2, w);
    }

    if (type != LUA_TNUMBER)
        return false;

    double key = lua_tonumber(L, -2);
    if (filled < 0 || key < 1 || key > length || key != double(int(key)))
    {
        filled = -1;
        return true;
    }

    if (int(key) > filled)
    {
        w.parts += int(key) - 1 - filled;
        filled = int(key);
    }
    return w.parts <= kMaxParts;
}

bool walk(lua_State* L, int idx, int depth, Walk& w)
{
    idx = lua_absindex(L, idx);

    if (++w.parts > kMaxParts)
        return false;

    switch (lua_type(L, idx))
    {
    case LUA_TNIL:
    case LUA_TBOOLEAN:
        return true;
    case LUA_TNUMBER:
    {
        double d = lua_tonumber(L, idx);
        return d - d == 0; // finite
    }
    case LUA_TSTRING:
        return readString(L, idx, w);
    case LUA_TLIGHTUSERDATA:
        return lua_touserdata(L, idx) == nullptr;
    case LUA_TTABLE:
        break;
    default:
        return false;
    }

    if (depth >= kMaxDepth)
        return false;

    if (!w.seen.insert(lua_topointer(L, idx)).second)
        return false;

    if (!lua_checkstack(L, 2))
        return false;

    int length = lua_objlen(L, idx);
    int filled = 0;
    int iter = 0;
    while ((iter = lua_rawiter(L, idx, iter)) >= 0)
    {
        bool ok = walk(L, -1, depth + 1, w) && walkKey(L, length, filled, w);
        lua_pop(L, 2);
        if (!ok)
            return false;
    }
    return true;
}

int protectedWalk(lua_State* L)
{
    Walk w;
    walk(L, 1, 0, w);
    return 0;
}

// Calls the function under the arguments with the budget armed, leaves its result (or nil) on the stack and reads it
void call(lua_State* L, int nargs)
{
    budget = Budget();
    budget.armed = true;
    budget.start = budget.lastCpu = cpuMs();
    budget.lastWall = clockMs(CLOCK_MONOTONIC);
    int status = lua_pcall(L, nargs, 1, 1);
    budget.armed = false;
    checkStall(cpuMs());

    if (status == 0 && memory.used + kMemoryRoom >= kMemoryCap)
    {
        lua_gc(L, LUA_GCCOLLECT, 0);
        if (memory.used + kMemoryRoom >= kMemoryCap)
            status = LUA_ERRMEM;
    }

    if (status != 0 || budget.stopped)
    {
        lua_pop(L, 1);
        lua_pushnil(L);
        return;
    }

    memory.ignoreLimit = true;
    lua_pushcfunction(L, protectedWalk, "walk");
    memory.ignoreLimit = false;
    lua_pushvalue(L, -2);
    if (lua_pcall(L, 1, 0, 0) != 0)
        lua_pop(L, 1); // the error object: leave only the result on the stack
}

void setFlags(const char* list)
{
    while (*list)
    {
        const char* end = strchr(list, ',');
        std::string item = end ? std::string(list, end - list) : std::string(list);
        list = end ? end + 1 : list + item.size();

        std::string name = item;
        bool value = true;
        size_t eq = item.find('=');
        if (eq != std::string::npos)
        {
            name = item.substr(0, eq);
            std::string text = item.substr(eq + 1);
            if (text != "true" && text != "false")
            {
                fprintf(stderr, "fuzz-plugin: flag '%s' takes true or false\n", name.c_str());
                exit(1);
            }
            value = text == "true";
        }

        bool found = false;
        for (Luau::FValue<bool>* flag = Luau::FValue<bool>::list; flag; flag = flag->next)
        {
            if (name == "true" ? strncmp(flag->name, "Luau", 4) == 0 : name == flag->name)
            {
                flag->value = value;
                found = true;
            }
        }

        if (!found)
        {
            fprintf(stderr, "fuzz-plugin: unknown flag '%s'\n", name.c_str());
            exit(1);
        }

        fprintf(stderr, "fuzz-plugin: %s=%s\n", name == "true" ? "every Luau flag" : name.c_str(), value ? "true" : "false");
    }
}

} // namespace

// A UBSan report stops the run, so libFuzzer saves the input as an artifact; UBSAN_OPTIONS=halt_on_error=0 continues
extern "C" const char* __ubsan_default_options()
{
    return "halt_on_error=1:print_stacktrace=1";
}

extern "C" int LLVMFuzzerInitialize(int* argc, char*** argv)
{
    if (const char* ms = getenv("LUAU_FUZZ_STALL_MS"))
        stallMs = atof(ms);

    // libFuzzer ignores arguments that start with '--'
    for (int i = 1; i < *argc; i++)
        if (strncmp((*argv)[i], "--fflags=", 9) == 0)
            setFlags((*argv)[i] + 9);

    return 0;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* Data, size_t Size)
{
    if (Size > kMaxSource)
        return 0;

    lua_CompileOptions options = {};
    options.optimizationLevel = 1;
    options.debugLevel = 1;

    size_t bytecodeSize = 0;
    char* bytecode = luau_compile(reinterpret_cast<const char*>(Data), Size, &options, &bytecodeSize);

    // a compile error is a single zero byte followed by the message
    if (bytecodeSize == 0 || bytecode[0] == 0)
    {
        free(bytecode);
        return 0;
    }

    memory = Memory();

    lua_State* L = lua_newstate(allocate, &memory);

    // the host sets up the VM before the cap applies
    memory.ignoreLimit = true;
    luaL_openlibs(L);
    // the collector's pace for heaps of 8 MiB and more, as the embedder sets it: LUA_GCSETGOALLARGE, LUA_GCSETSTEPMULLARGE
    // and LUA_GCSETGOALTHRESHOLD; a tree without them returns -1 and keeps its defaults
    lua_gc(L, 11, 115);
    lua_gc(L, 13, 1600);
    lua_gc(L, 12, 8192);

    lua_pushcfunction(L, collectgarbage, "collectgarbage");
    lua_setglobal(L, "collectgarbage");
    lua_pushcfunction(L, print, "print");
    lua_setglobal(L, "print");
    lua_callbacks(L)->interrupt = interrupt;

    luaL_sandbox(L);
    luaL_sandboxthread(L);

    lua_pushcfunction(L, messageHandler, "messageHandler");
    memory.ignoreLimit = false;

    if (luau_load(L, "=fuzz", bytecode, bytecodeSize, 0) == 0)
    {
        call(L, 0);

        if (lua_isfunction(L, -1))
        {
            // an input the host builds: a field, a number and a null in an array
            memory.ignoreLimit = true;
            lua_pushvalue(L, -1);
            lua_createtable(L, 2, 1);
            lua_pushstring(L, "id");
            lua_setfield(L, -2, "name");
            lua_pushnumber(L, 1.5);
            lua_rawseti(L, -2, 1);
            lua_pushlightuserdata(L, nullptr);
            lua_rawseti(L, -2, 2);
            memory.ignoreLimit = false;

            call(L, 1);
        }
    }

    free(bytecode);
    lua_close(L);

    if (memory.used != 0)
    {
        fprintf(stderr, "fuzz-plugin: %lld bytes still counted after lua_close\n", memory.used);
        abort();
    }
    return 0;
}
