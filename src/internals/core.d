module internals.core;

import internals.utf;
import internals.traits;
import system;

bool defaultEquals(T)(T x, T y)
{
    static if (isReferenceType!T)
    {
        if (x is y) return true;
        if (x is null || y is null) return false;
    }

    static if (isEquatableByMethod!T)
        return x.Equals(y);
    else static if (isEquatableByOperatorOverload!T)
        return x.opEquals(y);
    else static if (isEquatableByOperator!T)
        return x == y;
    else
        static assert(0, "Cannot compare for equality two values of type " ~ T.stringof);
}

bool defaultEquals(T, U)(T x, U y) if (!is(T == U))
{
    static if (isReferenceType!T && isReferenceType!U)
    {
        if (x is y) return true;
        if (x is null || y is null) return false;
    }

    static if (areEquatableByMethod!(T, U).isTrue)
        return areEquatableByMethod!(T, U).call(x, y);
    else static if (areEquatableByOperatorOverload!(T, U).isTrue)
        return areEquatableByOperatorOverload!(T, U).call(x, y);
    else static if (areEquatableByOperator!(T, U))
        return x == y;
    else
        static assert(0, "Cannot compare for equality two values of type " ~ T.stringof ~ " and " ~ U.stringof);
}

int defaultCompare(T)(T x, T y)
{
    static if (isReferenceType!T)
    {
        if (x is y) return 0;
        if (x is null) return -1;
        if (y is null) return 1;
    }

    static if (isComparableByMethod!T)
        return x.CompareTo(y);
    else static if (isComparableByOperatorOverload!T)
        return x.opCmp(y);
    else static if (isComparableByOperator!T)
    {
        if (x < y) return -1;
        if (x > y) return 1;
        return 0;
    }
    else
        static assert(0, "Cannot compare two values of type " ~ T.stringof);
}

bool defaultEquals(T, E)(T x, T y, E equalizer)
{
    static if (isEquatableByDelegate!(T, E))
        return equalizer(x, y);
    else static if (isEquatableByEqualizer(T, E))
        return equalizer.Equals(x, y);
    else
        static assert(0, "Cannot compare for equality values of type " ~ T.stringof ~ " using " ~ E.stringof);
}

bool defaultEquals(T, U, E)(T x, U y, E equalizer) if (!is(T == U))
{
    static if (areEquatableByDelegate!(T, U, E).isTrue)
        return areEquatableByDelegate!(T, U, E).call(x, y);
    else static if (areEquatableByEqualizer(T, U, E).isTrue)
        return areEquatableByEqualizer(T, U, E).call(x, y);
    else
        static assert(0, "Cannot compare for equality two values of type " ~ T.stringof ~ " and " ~ U.stringof ~ " using " ~ E.stringof);
}

int defaultCompare(T, C)(T x, T y, C comparer)
{
    static if (isComparableByDelegate!(T, C))
        return comparer(x, y);
    else static if (isComparableByComparer!(T, C))
        return comparer.Compare(x, y);
    else
        static assert(0, "Cannot compare two values of type " ~ T.stringof ~ " using " ~ E.stringof);
}

int defaultCompare(T, U, C)(T x, U y, C comparer) if (!is(T == U))
{
    static if (areComparableByDelegate!(T, U, C).isTrue)
        return areComparableByDelegate!(T, U, C).call(x, y);
    else static if (areComparableByComparer!(T, U, C).isTrue)
        return areComparableByComparer!(T, U, C).call(x, y);
    else
        static assert(0, "Cannot compare two values of type " ~ T.stringof ~ " and " ~ U.stringof ~ " using " ~ C.stringof);
}

template isHashable(T)
{
    enum isHashable = is(typeof(T.init.toHash()) == size_t) ||
                      is(typeof(T.init.GetHashCode()) == int);
}

int defaultHash(T)(T x)
{
    static if (isReferenceType!T)
    {
        if (x is null) return 0;
    }
    static if (isHashable!T)
    {
        static if (is(typeof(T.init.GetHashCode()) == int))
            return x.GetHashCode();
        else
            return cast(int)x.toHash();
    }
    else
        return cast(int)typeid(T).getHash(&x);
}

wstring defaultToString(T)(T x)
{
    static if (isReferenceType!T)
    {
        if (x is null)
            return ""w;
    }
    static if (is(T: wstring))
        return x;
    else static if (is(T : string) || is(T: dstring))
        return x.toUTF16();
    else static if (is(typeof(x.ToString()) : wstring))
        return x.ToString();
    else static if (is(typeof(x.toString()) : string))
        return x.toString().toUTF16();   
    else static if (is(T : char) || is(T: wchar))
        return [cast(wchar)x];
    else static if (is(T : dchar))
        return [a].toUTF16();
    else
        return T.stringof.toUTF16();
}

wstring defaultToString(T)(T x, IFormatProvider provider, wstring fmt = null)
{
    static if (isReferenceType!T)
    {
        if (x is null)
            return ""w;
    }

    static if (is(T == class) || is(T == interface))
    {
        if (auto formattable = cast(IFormattable)(a))
            return formattable.ToString(fmt, provider);
    }    

    static if (is(typeof(x.ToString(fmt, provider)) : wstring))
        return x.ToString(fmt, provider);
    
    static if (is(typeof(x.ToString(provider)) : wstring))
        return x.ToString(provider);

    return defaultToString(x);   
}

ptrdiff_t search(L, V)(L list, V value) if (isIndexable!(L, V) &&
                                            isFinite!L &&
                                            isEquatable!V)
{
	static if(isReferenceType!L)
	{
		if (list is null) return -1;
	}

	auto len = list.length;

	if (len == 0) return -1;

	size_t i = 0;
	while (i < len)
	{
		if (defaultEquals(list[i], value))
			return i;
		i++;
	}
	return -1;
}

ptrdiff_t search(L, V, C)(L list, V value, C equalizer) if (isIndexable!(L, V) &&
                                                            isFinite!L &&
                                                            isEquatable!(V, C))
{
	static if(isReferenceType!L)
	{
		if (list is null) return -1;
	}

	auto len = list.length;

	if (len == 0) return -1;

	size_t i = 0;
	while (i < len)
	{
		if (defaultEquals(list[i], value, equalizer))
			return i;
		i++;
	}
	return -1;
}

ptrdiff_t reverseSearch(L, V)(L list, V value) if (isIndexable!(L, V) &&
                                                   isFinite!L &&
                                                   isEquatable!V)
{
	static if(isReferenceType!L)
	{
		if (list is null) return -1;
	}

	auto len = list.length;

	if (len == 0) return -1;

	auto i = len;
	while (i > 0)
	{
		if (defaultEquals(list[i - 1], value))
			return i;
		i--;
	}
	return -1;
}

ptrdiff_t reverseSearch(L, V, C)(L list, V value, C equalizer) if (isIndexable!(L, V) &&
                                                                   isFinite!L &&
                                                                   isEquatable!(V, C))
{
	static if(isReferenceType!L)
	{
		if (list is null) return -1;
	}

	auto len = list.length;

	if (len == 0) return -1;

	auto i = len;
	while (i > 0)
	{
		if (defaultEquals(list[i - 1], value, equalizer))
			return i;
		i--;
	}
	return -1;
}

ptrdiff_t binarySearch(L, V)(L list, V value) if (isIndexable!(L, V) &&
                                                  isFinite!L &&
                                                  isComparable!V)
{
	static if(isReferenceType!L)
	{
		if (list is null) return -1;
	}

	auto len = list.length;

	if (len == 0) return -1;

	typeof(len) imin = 0;
	auto imax = len - 1;
	while (imax >= imin)
	{
		auto imid = imin + (imax - imin) / 2;	
		int c = defaultCompare(list[imid], value);
		if (c == 0) return imid;
		if (c < 0) imin = imid + 1; else imax = imid - 1;
	}
	return -1;
}

ptrdiff_t binarySearch(L, V, C)(L list, V value, C comparer) if (isIndexable!(L, V) &&
                                                                 isFinite!T &&
                                                                 isComparable!(V, C))
{
	static if(isReferenceType!L)
	{
		if (list is null) return -1;
	}

	auto len = list.length;

	if (len == 0) return -1;

	typeof(len) imin = 0;
	auto imax = len - 1;
	while (imax >= imin)
	{
		auto imid = imin + (imax - imin) / 2;	
		int c = defaultCompare(list[imid], value, comparer);
		if (c == 0) return imid;
		if (c < 0) imin = imid + 1; else imax = imid - 1;
	}
	return -1;
}

