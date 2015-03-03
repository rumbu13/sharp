module internals.checked;

import system;
import internals.traits;
import internals.resources;

import core.stdc.math;

//pragma(inline, true)
public T checkedMul(T)(in T a, in T b) if (__traits(isIntegral, T))
{
    Unqual!T ret = cast(Unqual!T)(a * b);
    if (a != 0 && ret / a != b)
        throw new OverflowException();
    return ret;
}

//pragma(inline, true)
public T checkedAdd(T)(in T a, in T b) if (__traits(isIntegral, T))
{
    if (a > 0 && b > 0 && T.max - a < b)
        throw new OverflowException();
    else if (a < 0 && b < 0 && T.min - a > b) 
        throw new OverflowException();
    return cast(T)(a + b);
}

//pragma(inline, true)
public T checkedAdd(T)(in T a, in T b) if (isAnyFloat!T)
{
    Unqual!T ret = cast(Unqual!T)(a + b);
    if (!isfinite(ret))
        throw new OverflowException();
    return ret;
}

//pragma(inline, true)
public T checkedMul(T)(in T a, in T b) if (isAnyFloat!T)
{
    Unqual!T ret = cast(Unqual!T)(a * b);
    if (!isfinite(ret))
        throw new OverflowException();
    return ret;
}

//pragma(inline, true)
public T checkedPow(T)(in T a, in T b) if (isAnyFloat!T)
{
    Unqual!T ret = cast(Unqual!T)(a ^^ b);
    if (!isfinite(ret))
        throw new OverflowException();
    return ret;
}

void checkNull(T)(T value, wstring param = null) if (is(typeof(T.init is null) == bool))
{
    if (value is null)
       throw new ArgumentNullException(param is null ? "value" : param);
}

void checkIndex(T, U, V)(T[] value, U index, V count, wstring param1 = null, wstring param2 = null) if (isAnyIntegral!U && isAnyIntegral!V)
{
    if (index < 0 || index >= value.length)
        throw new ArgumentOutOfRangeException(param1 is null ? "index" : param1);
    if (index > value.length - count)
        throw new ArgumentOutOfRangeException(param2 is null ? "count" : param2);
}

void checkIndex(T, U)(T[] value, U index, wstring param = null) if (isAnyIntegral!U)
{
    if (index < 0 || index >= value.length)
       throw new ArgumentOutOfRangeException(param is null ? "index": param);
}

void checkRange(T, U, V)(T value, U min, V max, wstring param = null)
{
    if (value < min || value > max)
        throw new ArgumentOutOfRangeException(param is null ? "value" : param, 
                                              SharpResources.GetString("ArgumentOutOfRange", min, max));
}

void checkPositive(T)(T value, bool strict, wstring param = null)
{
    if (strict && value <= 0)
        throw new ArgumentOutOfRangeException(param is null ? "value" : param, SharpResources.GetString("ArgumentOutOfRangeStrictlyPositive"));
    if (value < 0)
        throw new ArgumentOutOfRangeException(param is null ? "value" : param, SharpResources.GetString("ArgumentOutOfRangePositive"));
}

U invalidCast(T, U)()
{
    throw new InvalidCastException(SharpResources.GetString("InvalidCast", T.stringof, U.stringof));
}

uint safe32bit(size_t value)
{
    static if(size_t.sizeof == 4)
        return value;
    else
    {
        if (value > uint.max)
            throw new OverflowException();
        return cast(uint)value;
    }
}

//pragma(inline, true)
@property int Length(L)(L list) if (isFinite!L)
{
    static if (is(typeof(list.length) : int))
        return list.length;
    else
    {
        auto len = list.length;
        if (len > int.max)
            throw new OverflowException();
        return cast(int)len;
    }

}


