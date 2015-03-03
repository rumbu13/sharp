module internals.resources;

import core.stdc.string;
import system;
import internals.utf;
import internals.checked;

struct InternalResource(string fileName)
{
private:
    ubyte[] data;
    ubyte* namePtr;
    ubyte* dataPtr;
    ubyte* positionPtr;
    ubyte* typePtr;
    int resCount;
    int typeCount;

    static int read7bitInt(ref ubyte* bytes)
    {
        int count = 0;
        int shift = 0;
        ubyte b;
        do {
            assert(shift != 32);
            b = *bytes++;
            count |= (b & 0x7F) << shift;
            shift += 7;
        } while ((b & 0x80) != 0);
        return count;
    }

    static int readInt(ref ubyte* ptr)
    {
        int r = *(cast(int*)ptr);
        ptr += 4;
        return r;
    }
   
    ubyte* getTypeNamePtr(int index)
    {
        assert(index < typeCount);
        auto ptr = typePtr;
        while(index-- > 0)
            ptr += read7bitInt(ptr);
        return ptr;
    }

    ubyte* getNamePtr(int index)
    {
        assert(index < resCount);
        auto ptr = positionPtr + index * 4;
        return namePtr + readInt(ptr);
    }

    ubyte* getResourcePtr(wstring name)
    {
        synchronized
        {
            auto p = name in cache;
            if (p) 
                return *p;
        }
        for (int i = 0; i < resCount; i++)
        {
            auto ptr = getNamePtr(i);
            auto len = read7bitInt(ptr);
            assert(len % 2 == 0);
            if (name.length * 2 == len)
            {
                if(memcmp(name.ptr, ptr, len) == 0)
                {
                    ptr += len;
                    ptr = dataPtr + readInt(ptr);
                    synchronized
                    {
                        cache[name] = ptr;
                    }
                    return ptr;
                }
            }
        }
        return null;
    }

    ubyte*[wstring] cache;

    void load()
    {
        data = cast(ubyte[])import(fileName);
        auto ptr = data.ptr;

        auto magic = readInt(ptr);
        assert(magic == 0xbeefcace);

        auto ver = readInt(ptr);
        assert(ver >= 1);

        auto skip = readInt(ptr);
        if (ver > 1)
            ptr += skip;

        ptr += read7bitInt(ptr); //skip assembly
        ptr += read7bitInt(ptr); //skip resource set

        auto rver = readInt(ptr);
        assert(rver == 1 || rver == 2);

        resCount = readInt(ptr);
        assert(resCount >= 0);

        typeCount = readInt(ptr);
        assert(typeCount >= 0);
        typePtr = ptr;
        auto tcnt = typeCount;
        while (tcnt-- > 0)
            ptr += read7bitInt(ptr); //skip type names

        auto pos = safe32bit(ptr - data.ptr);
        auto pad_align = pos & 7;
        auto padChars = 0;
        if (pad_align != 0) 
            padChars = 8 - pad_align;
        assert(ptr[0.. padChars] == cast(byte[])"PADPADPA"[0 .. padChars]);
        ptr += padChars;

        ptr += resCount * 4; //skip hashes

        positionPtr = ptr;
        ptr += resCount * 4; //skip positions

        dataPtr = data.ptr + readInt(ptr);
        namePtr = ptr;
    }
public:
    wstring GetString(wstring key)
    {
        auto ptr = getResourcePtr(key);
        assert(ptr);
        auto type = read7bitInt(ptr);
        assert(type == 1);
        auto len = read7bitInt(ptr);
        char* cptr = cast(char*)ptr;
        return toUTF16(cptr[0 .. len]);
    }

    wstring GetString(A...)(wstring key, A args) if (A.length > 0)
    {
        return String.Format(GetString(key), args);
    }
}

__gshared InternalResource!"strings.resources" SharpResources;

static this()
{
    SharpResources.load();
}



