module system.collections.generic;

import system;
import internals.core;

interface IEnumerator(T = Object) : IDisposable
{
    @property T Current();
    bool MoveNext();
    void Reset();
}



interface IEnumerable(T = Object)
{
    IEnumerator!T GetEnumerator();

    final int opApply(int delegate(T) dg)
    {
        auto enumerator = GetEnumerator();
        scope(exit) enumerator.Dispose();
        int r = 0;
        while (enumerator.MoveNext() && r == 0)
            r = dg(enumerator.Current);
        return r;
    }
}

template isEnumerable(T, U)
{
    enum isEnumerable = __traits(compiles, { foreach(U u; T.init) {} });
}

interface ICollection(T) : IEnumerable!T
{
    @property int Count();
    @property Object SyncRoot();
    @property bool IsSynchronized();
    void CopyTo(T[] array, int index);
}

interface IReadOnlyCollection(T) : IEnumerable!T
{
    @property int Count();
}

interface IList(T) : ICollection!T
{
    T opIndex(size_t index);
    T opIndexAssign(T value, size_t index);
    @property bool IsReadOnly();
    @property bool IsFixedSize();
    int Add(T value);
    bool Contains(T value);
    void Clear();
    int IndexOf(T value);
    void Insert(int index, T value);
    void Remove(T value);
    void RemoveAt(int index);
}

interface IReadOnlyList(T) : IReadOnlyCollection!T
{
    T opIndex(size_t index);
}

struct KeyValuePair(K, V)
{
private:
    K key;
    V value;
public:
    this(K key, V value) { this.key = key; this.value = value; }
    @property K Key() { return key; }
    @property V Value() { return value; }
    wstring ToString()
    {
        return "[" ~ defaultToString(key) ~ ", " ~ defaultToString(value) ~ "]";
    }
}


interface IDictionary(K = Object, V = Object) : ICollection!(KeyValuePair!(K, V))
{
    V opIndex(K value);
    V opIndexAssign(V value, K key);
    @property ICollection!K Keys();
    @property ICollection!V Values();
    bool ContainsKey(K key);
    void Add(K key, V value);
    void Remove(K key);
    bool TryGetValue(K key, out V value);
}
