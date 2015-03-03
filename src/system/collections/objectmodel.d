module system.collections.objectmodel;

import system;
import system.collections.generic;
import internals.checked;

class ReadOnlyCollection(T) : IList!T, IReadOnlyList!T
{
private:
    IList!T list;
    Object syncRoot;
public:
    this(IList!T list)
    {
        checkNull(list);
        this.list = list;
    }

    bool Contains(T value) { return list.Contains(value); }
    IEnumerator!T GetEnumerator() { return list.GetEnumerator(); }
    int IndexOf(T value) { return list.IndexOf(value); }

    @property @safe nothrow @nogc
    bool IsFixedSize() {return true; }

    @property @safe nothrow @nogc
    bool IsReadOnly() {return true; }

    @property @safe nothrow @nogc
    bool IsSynchronized() {return false; }   

    @property
    Object SyncRoot() { if (syncRoot is null) syncRoot = list.SyncRoot; return syncRoot; }

    @property 
    int Count() { return list.Count; }

    void CopyTo(T[] array, int index) { list.CopyTo(array, index); }
    T opIndex(size_t index) { return list.opIndex(index); }
    T opIndexAssign(T value, size_t index) { throw new NotSupportedException(); }
    int Add(T value) { throw new NotSupportedException(); }
    void Clear() { throw new NotSupportedException(); }
    void Insert(int index, T value) { throw new NotSupportedException(); }
    void Remove(T value) { throw new NotSupportedException(); }
    void RemoveAt(int index) { throw new NotSupportedException(); }
}

unittest
{
    
}