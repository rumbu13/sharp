module internals.interning;

//private extern(C) void* malloc(size_t) nothrow pure @nogc @trusted;
//private extern(C) void free(void*) nothrow pure @nogc @trusted;
//
//private enum MEMORYPOOLSIZE = 512;
//
//struct StringPool
//{
//    @disable this();
//    @disable this(this);
//
//    Node*[] buckets;
//    Block* root;
//
//    static struct Element
//    {
//        wstring str;
//        size_t hash;
//        Element* next;
//    }
//
//    static struct MemoryPool
//    {
//        wchar[] content;
//        size_t used;
//        MemoryPool* next;
//    }
//
//    wchar[] requestMemory(size_t charCount)
//    {
//        if (charCount > MEMORYPOOLSIZE / 2)
//            return cast(wchar*)(malloc(charCount * 2))[0 .. charCount];
//        MemoryPool* pool = root;
//        while(pool)
//        {
//            if (MEMORYPOOLSIZE - pool.used >= charCount)
//            {
//                auto oldUsed = pool.used;
//                pool.used += charCount;
//                return pool.content[oldUsed .. pool.used];
//            }
//            pool = pool.next;
//        }
//
//        MemoryPool* newPool = cast(MemoryPool*)malloc(MemoryPool.sizeof);
//        newPool.content = (cast(wchar*) malloc(MEMORYPOOLSIZE * 2))[0 .. MEMORYPOOLSIZE];
//        newPool.used = charCount;
//        newPool.next = root;
//        root = newPool;
//        return newPool.content[0 .. charCount];
//    }
//
//    ~this()
//    {
//        auto pool = root;
//        while(pool)
//        {
//            auto previous = pool;
//            pool = pool.next;
//            free(previous.content.ptr);
//            free(previous);
//        }
//        root = null;
//        free(buckets.ptr);
//        buckets = null;
//    }
//}
