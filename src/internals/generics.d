module internals.generics;

import system.collections.generic;
import system;
import internals.checked;
import internals.core;

class ArrayEnumerator(T) : IEnumerator!T
{
    int index = -1;
    T[] array;
    @property T Current()
    {
        if (index < 0 || index >= array.length)
            throw new InvalidOperationException();
        return array[index];
    }

    bool MoveNext()
    {
        return ++index < array.length;

    }
    void Reset()
    {
        index = -1;
    }

    void Dispose()
    {
        array = null;
    }

    this(T[] array)
    {
        this.array = array;
    }
}

class ArrayAsEnumerable(T): IEnumerable!T
{
    T[] array;
    IEnumerator!T GetEnumerator()
    {
        return new ArrayEnumerator!T(array);
    }

    this(T[] array)
    {
        this.array = array;
    }
}

class ArrayAsCollection(T): ArrayAsEnumerable!T, ICollection!T
{
    Object syncRoot;

    @property 
    int Count() 
    { 
        return array.length; 
    }

    @property 
    Object SyncRoot()
    {
        if (syncRoot is null)
            syncRoot = new Object();
        return syncRoot;
    }

    @property 
    bool IsSynchronized()
    {
        return false;
    }

    void CopyTo(T[] array, int index)
    {
        checkIndex(array, index, this.array.length);
        array[index .. index + array.length] = this.array;
    }

    this(T[] array)
    {
        super(array);
    }
}

class ArrayAsReadOnlyCollection(T): ArrayAsEnumerable!T, IReadOnlyCollection!T
{
    @property 
    int Count() 
    { 
        return array.length; 
    }

    this(T[] array)
    {
        super(array);
    }
}

class ArrayAsList(T) : ArrayAsCollection!T, IList!T
{
    this(T[] array)
    {
        super(array);
    }

    @property
    bool IsFixedSize()
    {
        return false;
    }

    @property
    bool IsReadOnly()
    {
        return false;
    }

    bool Contains(T value)
    {
        foreach(e;array)
            if (e == value)
                return true;
        return false;
    }

    void Insert(int index, T value)
    {
        checkIndex(array, index);
        array = array[0 .. index] ~ value ~ array[index .. $];
    }

    void RemoveAt(int index)
    {
        checkIndex(array, index);
        array = array[0 .. index] ~ array[index + 1 .. $];
    }

    void Remove(T value)
    {
        for (auto i = 0; i < array.length; i++)
        {
            if (array[i] == value)
            {
                RemoveAt(i);
                break;
            }
        }
    }

    int IndexOf(T value)
    {
        return search(array, value);
    }

    T opIndex(size_t index)
    {
        checkIndex(array, index);
        return array[index];
    }

    T opIndexAssign(T value, size_t index)
    {
        checkIndex(array, index);
        return array[index] = value;
    }

    int Add(T value)
    {
        array = array ~ value;
        return array.length - 1;
    }

    void Clear()
    {
        array = [];
    }
}

class AssociativeArrayEnumerator(K, V) : IEnumerator!(KeyValuePair!(K, V))
{
    V[K] array;
    K[] keys;
    int index = -1;

    @property KeyValuePair!(K, V) Current()
    {
        if (index < 0 || index >= array.length)
            throw new InvalidOperationException();
        return KeyValuePair!(K, V)(keys[index], array[keys[index]]);
    }

    bool MoveNext()
    {
        return ++index < array.length;

    }
    void Reset()
    {
        index = -1;
    }

    void Dispose()
    {
        array = null;
    }

    this(V[K] array)
    {
        this.array = array.dup();
    }
    

}

class AssociativeArrayAsEnumerable(K, V): IEnumerable!(KeyValuePair!(K, V))
{
    V[K] array;
    IEnumerator!(KeyValuePair!(K, V)) GetEnumerator()
    {
        return new AssociativeArrayEnumerator!(K, V)(array);
    }

    this(V[K] array)
    {
        this.array = array;
    }
}


