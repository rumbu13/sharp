module system.threading;

private import
    core.atomic;

struct Interlocked
{
    @disable this();
    alias MemoryBarrier = atomicFence;

    static int Exchange(ref shared int location, int value)
    {
        atomicStore(location, value);
        return atomicLoad(location);
    }

    static long Exchange(ref shared long location, long value)
    {
        atomicStore(location, value);
        return atomicLoad(location);
    }

    static float Exchange(ref shared float location, float value)
    {
        atomicStore(location, value);
        return atomicLoad(location);
    }

    static double Exchange(ref shared double location, double value)
    {
        atomicStore(location, value);
        return atomicLoad(location);
    }

    static void* Exchange(ref shared void* location, void* value)
    {
        shared size_t loc = cast(shared size_t)location;
        atomicStore(loc, cast(size_t)value);
        location = cast(shared void*)atomicLoad(loc);
        return cast(void*)atomicLoad(location);
    }

    static T Exchange(T)(ref shared T location, T value) if (is(T == class))
    {
        shared size_t loc = cast(shared size_t)cast(shared void*)location;
        atomicStore(loc, cast(size_t)cast(void*)value);
        location = cast(shared T)cast(shared void*)atomicLoad(loc);
        return cast(T)atomicLoad(location);
    }

    static int CompareExchange(ref shared int location, int value, int comparand)
    {
        cas(&location, comparand, value);
        return location;
    }

    static long CompareExchange(ref shared long location, long value, long comparand)
    {
        cas(&location, comparand, value);
        return location;
    }

    static double CompareExchange(ref shared double location, double value, double comparand)
    {
        cas(&location, comparand, value);
        return location;
    }

    static float CompareExchange(ref shared float location, float value, float comparand)
    {
        cas(&location, comparand, value);
        return location;
    }

    static void* CompareExchange(ref shared void* location, shared void* value, shared void* comparand)
    {
        cas(&location, comparand, value);
        return cast(void*)location;
    }

    static T CompareExchange(T)(ref shared T location, shared T value, shared T comparand) if (is(T == class))
    {
        cas(&location, comparand, value);
        return cast(T)(location);
    }

    static int Add(ref shared int location, int value)
    {
        return atomicOp!("+=")(location, value);
    }

    static long Add(ref shared long location, int value)
    {
        return atomicOp!("+=")(location, value);
    }

    static int Increment(ref shared int location)
    {
        return atomicOp!("+=")(location, 1);
    }

    static int Decrement(ref shared int location)
    {
        return atomicOp!("-=")(location, 1);
    }

    static long Increment(ref shared long location)
    {
        return atomicOp!("+=")(location, 1L);
    }

    static long Decrement(ref shared long location)
    {
        return atomicOp!("-=")(location, 1L);
    }

    alias Read = atomicLoad!(MemoryOrder.seq, long);
}