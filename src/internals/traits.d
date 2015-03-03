module internals.traits;

import system;

template Unqual(T)
{
    static if (is(T U ==          immutable U)) alias Unqual = U;
	else static if (is(T U == shared inout const U)) alias Unqual = U;
	else static if (is(T U == shared inout       U)) alias Unqual = U;
	else static if (is(T U == shared       const U)) alias Unqual = U;
	else static if (is(T U == shared             U)) alias Unqual = U;
	else static if (is(T U ==        inout const U)) alias Unqual = U;
	else static if (is(T U ==        inout       U)) alias Unqual = U;
	else static if (is(T U ==              const U)) alias Unqual = U;
	else                                             alias Unqual = T;
}

template isAnyChar(C)
{
    enum isAnyChar = is(C == char) || is(C == wchar) || is(C == dchar);
}

template isAnyFloat(T)
{
    enum isAnyFloat = is(T == float) || is(T == double) || is(T == real);
}

template isUnsigned(T)
{
    enum isUnsigned = is(T == ubyte) || is(T == ushort) || is(T == uint) || is(T == ulong);
}

template isSigned(T)
{
    enum isSigned = is(T == byte) || is(T == short) || is(T == int) || is(T == long);
}

template isAnyIntegral(T)
{
    enum isAnyIntegral = isUnsigned!T || isSigned!T;
}

template isNumeric(T)
{
    enum isNumeric = isAnyIntegral!T || isAnyFloat!T || is(T == decimal);
}


template Unsigned(T) if (isAnyIntegral!T)
{
    static if(is(T == byte))
    {
        alias Unsigned = ubyte;
    }
    else static if(is(T == short))
    {
        alias Unsigned = ushort;
    }
    else static if(is(T == int))
    {
        alias Unsigned = uint;
    }
    else static if(is(T == long))
    {
        alias Unsigned = ulong;
    }
    else
        alias Unsigned = T;
}

template Signed(T) if (isAnyIntegral!T)
{
    static if(is(T == ubyte))
    {
        alias Signed = byte;
    }
    else static if(is(T == ushort))
    {
        alias Signed = short;
    }
    else static if(is(T == uint))
    {
        alias Signed = int;
    }
    else static if(is(T == ulong))
    {
        alias Signed = long;
    }
    else
        alias Signed = T;
}


template isCloneable(T)
{
    enum isCloneable = is(T : ICloneable) ||
        is(typeof(T.init.clone()) : Object); 
}

Object box(T)(T value)
{
    static if (!is(T == class) && !is(T == interface))
        return new ValueType!T(value);
    else
        return value;
}

T unbox(T)(Object value)
{
    ValueType!T vt = cast(ValueType!T)value;
    if (vt !is null)
        return vt._value;
    throw new InvalidCastException();
}


void checkEnum(E)(E value, wstring prop = "value") if (is(E == enum))
{
    enum isFlags = hasAttribute!(E, Flags);
    static if (isFlags)
    {
        ulong allFlags;
    }

    foreach(m; __traits(allMembers, E))
    {
        static if (isFlags)
        {
            allFlags |= __traits(getMember, E, m);
        }
        else
        {
            if (__traits(getMember, E, m) == value)
                return;
        }
    }

    static if (isFlags)
    {
        if ((cast(ulong)value & allFlags) != allFlags)
            throw new ArgumentOutOfRangeException(prop);
    }
    else
        throw new ArgumentOutOfRangeException(prop);
}

template hasAttribute(T, A)
{
    bool func()
    {
        foreach(a; __traits(getAttributes, T))
        {
            static if (is(typeof(a) == A))
                return true;
        }
        return false;
    }
    enum hasAttribute = func();
}

template isEquatableByMethod(T)
{
    enum isEquatableByMethod = is(typeof(T.init.Equals(T.init)) : bool);
}

template areEquatableByMethod(T, U)
{
    static if(is(typeof(T.init.Equals(U.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u) { return t.Equals(u); }
    }
    else static if(is(typeof(U.init.Equals(T.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u) { return u.Equals(t); }
    }
    else
        enum isTrue = false;
}


template isComparableByMethod(T)
{
    enum isComparableByMethod = is(typeof(T.init.CompareTo(T.init)) : int);
}

template areComparableByMethod(T, U)
{
    static if(is(typeof(T.init.CompareTo(U.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u) { return t.CompareTo(u); }
    }
    else static if(is(typeof(U.init.CompareTo(T.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u) { return u.CompareTo(t); }
    }
    else
        enum isTrue = false;
}

template isEquatableByOperator(T)
{
    enum isEquatableByOperator = is(typeof(T.init == T.init) : bool) &&
                                 is(typeof(T.init != T.init) : bool);
}

template areEquatableByOperator(T, U)
{
    enum areEquatableByOperator = is(typeof(T.init == U.init) : bool) &&
                                  is(typeof(T.init != U.init) : bool);
}

template isComparableByOperator(T)
{
    enum isComparableByOperator = is(typeof(T.init == T.init) : bool) &&
                                  is(typeof(T.init > T.init) : bool) &&
                                  is(typeof(T.init < T.init) : bool);
}

template isEquatableByOperatorOverload(T)
{
    enum isEquatableByOperatorOverload = is(typeof(T.init.opEquals(T.init)) : bool);
}

template areEquatableByOperatorOverload(T, U)
{
    static if (is(typeof(T.init.opEquals(U.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u) { return t.opEquals(u); }
    }
    else static if (is(typeof(U.init.opEquals(T.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u) { return u.opEquals(t); }
    }
    else
        enum isTrue = false;
}

template isComparableByOperatorOverload(T)
{
    enum isComparableByOperatorOverload = is(typeof(T.init.opCmp(T.init)) : int);
}

template areComparableByOperatorOverload(T, U)
{
    static if (is(typeof(T.init.opCmp(U.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u) { return t.opCmp(u); }
    }
    else static if (is(typeof(U.init.opCmp(T.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u) { return u.opCmp(t); }
    }
    else
        enum isTrue = false;
}

template isEquatableByDelegate(T, D)
{
    enum isEquatableByDelegate = is(typeof(D.init(T.init, T.init)) : bool);
}

template areEquatableByDelegate(T, U, D)
{
    static if(is(typeof(D.init(T.init, U.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u, D d) { return d(t, u); }
    }
    else static if(is(typeof(D.init(U.init, T.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u, D d) { return d(u, t); }
    }
    else
        enum isTrue = false;
}

template isComparableByDelegate(T, D)
{
    enum isComparableByDelegate = is(typeof(D.init(T.init, T.init)) : int);
}

template areComparableByDelegate(T, U, D)
{
    static if(is(typeof(D.init(T.init, U.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u, D d) { return d(t, u); }
    }
    else static if(is(typeof(D.init(U.init, T.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u, D d) { return d(u, t); }
    }
    else
        enum isTrue = false;
}

template isEquatableByEqualizer(T, E)
{
    enum isEquatableByEqualizer = is(typeof(E.init.Equals(T.init, T.init)) : bool);
}

template areEquatableByEqualizer(T, U, E)
{
    static if(is(typeof(E.init.Equals(T.init, U.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u, E e) { return e.Equals(t, u); }
    }
    else static if(is(typeof(E.init.Equals(U.init, T.init)) : bool))
    {
        enum isTrue = true;
        bool call(T t, U u, E e) { return e.Equals(u, t); }
    }
    else
        enum isTrue = false;
}

template isComparableByComparer(T, C)
{
    enum isComparableByComparer = is(typeof(C.init.Compare(T.init, T.init)) : int);
}

template areComparableByComparer(T, U, E)
{
    static if(is(typeof(E.init.Compare(T.init, U.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u, E e) { return e.Compare(t, u); }
    }
    else static if(is(typeof(E.init.Compare(U.init, T.init)) : int))
    {
        enum isTrue = true;
        int call(T t, U u, E e) { return e.Compare(u, t); }
    }
    else
        enum isTrue = false;
}

template isEquatable(T)
{
    enum isEquatable = isEquatableByMethod!T || 
         isEquatableByOperatorOverload!T ||
         isEquatableByOperator!T;
}

template areEquatable(T, U)
{
    enum areEquatable = areEquatableByMethod!(T, U).isTrue || 
                        areEquatableByOperatorOverload!(T, U).isTrue ||
                        areEquatableByOperator!(T, U).isTrue;
}


template isComparable(T)
{
    enum isComparable = isComparableByMethod!T || 
        isComparableByOperatorOverload!T ||
        isComparableByOperator!T;
}

template areComparable(T, U)
{
    enum areComparable = areComparableByMethod!(T, U).isTrue || 
                         areComparableByOperatorOverload!(T, U).isTrue ||
                         areComparableByOperator!(T, U).isTrue;
}

template isEquatable(T, U)
{
    enum isEquatable = isEquatableByDelegate!(T, U) || isEquatableByEqualizer!(T, U);
}

template areEquatable(T, U, V)
{
    enum areEquatable = areEquatableByDelegate!(T, U, V).isTrue || areEquatableByEqualizer!(T, U, V).isTrue;
}


template isComparable(T, U)
{
    enum isComparable = isComparableByDelegate!(T, U) || isComparableByComparer!(T, U);
}

template areComparable(T, U, V)
{
    enum areComparable = areComparableByDelegate!(T, U, V).isTrue || areComparableByEqualizer!(T, U, V).isTrue;
}

template isReferenceType(T)
{
    enum isReferenceType = is(typeof(T.init is null) == bool);
}

template isIndexable(T)
{
	enum isIndexable = is(typeof(T.init[0]));
}

template isIndexable(T, E)
{
	enum isIndexable = is(typeof(T.init[0]) : E);
}

template isIndexableWithWriteAccess(T)
{
	enum isIndexableWithWriteAccess = isIndexable!T && is(typeof(T.init[0] = T.init[0]));
}

template isIndexableWithWriteAccess(T, E)
{
	enum isIndexableWithWriteAccess = isIndexable!T && is(typeof(T.init[0] = E.init));
}

template isFinite(T)
{
	enum isFinite = is(typeof(T.init.length) : size_t);
}