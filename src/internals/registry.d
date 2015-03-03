module internals.registry;

import system;
import internals.advapi32;
import internals.kernel32;
import internals.user32;
import internals.interop;
import internals.checked;


private extern(C) ulong wcstoul(const wchar* str, wchar** endptr, int base);


bool registryOpenKeyReadOnly(void * hkey, wstring subkey, out void* hsubkey)
{
    return RegOpenKeyExW(hkey, subkey.zeroTerminated(), 0, KEY_READ, &hsubkey) == 0;
}


bool registryRead(T)(void* hkey, wstring valueName, ref T value) if (is(T==int) || is(T == uint))
{
    uint bufSize = uint.sizeof;
    uint dwType;
    auto ret = RegQueryValueExW(hkey, valueName.zeroTerminated(), null, &dwType, &value, &bufSize);
    return ret == 0 && (dwType == REG_DWORD || dwType == REG_DWORD_BIG_ENDIAN);
}


bool registryRead(T)(void* hkey, wstring valueName, ref T value) if (is(T==long) || is(T == ulong))
{
    uint bufSize = ulong.sizeof;
    uint dwType;
    auto ret = RegQueryValueExW(hkey, valueName.zeroTerminated(), null, &dwType, &value, &bufSize);
    return ret == 0 && (dwType == REG_QWORD);
}


bool registryRead(void* hkey, wstring valueName, out wstring value)
{
    uint dwType;
    uint bufSize;
    auto zvalueName = valueName.zeroTerminated();
    auto ret = RegQueryValueExW(hkey, zvalueName, null, &dwType, null, &bufSize);
    if (ret != 0 || (dwType != REG_SZ && dwType != REG_EXPAND_SZ))
        return false;
    wchar[] buf = new wchar[bufSize / 2 + 1];
    ret = RegQueryValueExW(hkey, zvalueName, null, null, buf.ptr, &bufSize);
    if (ret != 0)
        return false;
    auto len = bufSize / 2 - 1;
    if (buf[$ - 2] != '\0')
    {
        buf[$ - 1] = '\0';
        len++;
    }

    if (dwType == REG_EXPAND_SZ)
    {
        ret = ExpandEnvironmentStringsW(buf.ptr, null, 0);
        if (ret > 0)
        {
            wchar[] expBuf = new wchar[ret];
            ret = ExpandEnvironmentStringsW(buf.ptr, expBuf.ptr, ret);
            if (ret > 0)
            {
                buf = expBuf;
                len = ret - 1;
            }
        }
    }

    if (len > 0 && buf[0] == '@')
    {
        auto i = 0;
        while (i < len && buf[i] != ',')
            i++;
        if (i < len)
        {
            buf[i] = '\0';
            auto lib = LoadLibraryW(buf[1 .. $].ptr);
            buf[i] = ',';
            if (lib !is null)
            {
                auto j = i + 2;
                if (j < len)
                {
                    auto l = wcstoul(buf[j .. $].ptr, null, 10);
                    if (l > 0 && l <= uint.max)
                    {
                        wchar* str;
                        ret = LoadStringW(lib, cast(uint)l, cast(wchar*)&str, 0);
                        if (ret != 0)
                        {
                            buf = fromSz(str, ret);
                            len = safe32bit(buf.length);
                        }
                    }
                }
            }
        }
    }

    value = cast(wstring)buf[0 .. len];
    return true;
}

nothrow
bool registryRead(void* hkey, wstring valueName, out wstring[] value)
{
    uint dwType;
    uint bufSize;
    auto zvalueName = valueName.zeroTerminated();
    auto ret = RegQueryValueExW(hkey, zvalueName, null, &dwType, null, &bufSize);
    if (ret != 0 || dwType != REG_MULTI_SZ)
        return false;
    wchar[] buf = new wchar[bufSize / 2];
    ret = RegQueryValueExW(hkey, zvalueName, null, null, buf.ptr, &bufSize);
    if (ret != 0)
        return false;

    value.length = 0;
    auto len = bufSize / 2;
    auto i = 0;
    auto j = 0;
    while (i < len)
    {
        if (buf[i] == '\0')
        {
            if (j < i)
                value ~= cast(wstring)buf[j .. i];
            j = i + 1;
        }
        i++;
    }
    return true;
}

nothrow
bool registryRead(T)(void* hkey, wstring valueName, ref T value) if (is(T == struct))
{
    uint dwType;
    uint bufSize;
    auto zvalueName = valueName.zeroTerminated();
    auto ret = RegQueryValueExW(hkey, zvalueName, null, &dwType, null, &bufSize);
    if (ret != 0 || dwType != REG_BINARY || bufSize != T.sizeof)
        return false;
    ret = RegQueryValueExW(hkey, zvalueName, null, &dwType, &value, &bufSize);
    if (ret != 0)
        return false;
    return true;
}

struct RegistryKeyEnumerator
{
    void* hkey;
    @disable this();
    this(void* hkey)
    {
        this.hkey = hkey;
    }

    int opApply(int delegate(ref wstring key) dg)
    {
        uint subkeycount;
        uint subkeymaxlen;
        auto ret = RegQueryInfoKeyW(hkey, null, null, null, &subkeycount, &subkeymaxlen, null, null, null, null, null, null);
        if (ret != 0)
            return 0;
        wchar[] buf = new wchar[subkeymaxlen + 1];    
        for(uint i = 0; i < subkeycount; i++)
        {
            uint len = safe32bit(buf.length);
            ret = RegEnumKeyExW(hkey, i, buf.ptr, &len, null, null, null, null);
            if (ret != 0)
                return 0;
            wstring value = cast(wstring)buf[0 .. len];
            ret = dg(value);
            if (ret != 0)
                break;
        }
        return ret;
    }
}

struct RegistryValueEnumerator
{
    void* hkey;
    @disable this();
    this(void* hkey)
    {
        this.hkey = hkey;
    }

    int opApply(int delegate(ref wstring value) dg)
    {
        uint valuecount;
        uint valuemaxlen;
        auto ret = RegQueryInfoKeyW(hkey, null, null, null, null, null, null, &valuecount, &valuemaxlen, null, null, null);
        if (ret != 0)
            return 0;
        wchar[] buf = new wchar[valuemaxlen + 1];
        for(uint i = 0; i < valuecount; i++)
        {
            uint len = safe32bit(buf.length);
            ret = RegEnumValueW(hkey, i, buf.ptr, &len, null, null, null, null);
            if (ret != 0)
                return 0;
            wstring key = cast(wstring)buf[0 .. len];
            ret = dg(key);
            if (ret != 0)
                break;
        }
        return ret;
    }
}

