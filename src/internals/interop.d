module internals.interop;

import system.runtime.interopservices;

import internals.kernel32;
import internals.resources;
import internals.utf;
import internals.traits;

wstring getSystemErrorMessage(in int errorCode)
{
    wchar* ptr;
    auto result = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS, 
                                 null, errorCode, 0, cast(wchar*)(&ptr), 0, null);
    if (result > 0 && ptr !is null && *ptr != 0)
    {
        scope(exit) LocalFree(ptr);
        return ptr[0 .. result - 1].idup;
    }
    else
        return SharpResources.GetString("ExceptioNSystemError", errorCode);
}

pure nothrow
const(C*) zeroTerminated(C)(in C[] s)
{
    static immutable C[] empty = ['\0'];
    if (s is null)
        return null;
    if (s.length == 0)
        return empty.ptr;
    C[] result = new C[s.length + 1];
    result[0 .. $ - 1] = s;
    result[$ - 1] = cast(C)0;    
    return result.ptr;    
}


nothrow @nogc @trusted
bool isWindowsVersionOrGreater(in ushort wMajorVersion, in ushort wMinorVersion, in ushort wServicePackMajor)
{
    OSVERSIONINFOEXW osvi;

    ulong dwlConditionMask = 
        VerSetConditionMask(
                           VerSetConditionMask(
                                              VerSetConditionMask(0, VER_MAJORVERSION, VER_GREATER_EQUAL),
                                              VER_MINORVERSION, VER_GREATER_EQUAL),
                           VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);

    osvi.dwMajorVersion = wMajorVersion;
    osvi.dwMinorVersion = wMinorVersion;
    osvi.wServicePackMajor = wServicePackMajor;

    return VerifyVersionInfoW(osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_SERVICEPACKMAJOR, dwlConditionMask) != 0;
}


nothrow @nogc @trusted
bool isWindowsXPOrGreater()
{
    return isWindowsVersionOrGreater(5, 1, 0);
}

nothrow @nogc @trusted
bool isWindowsXPSP1OrGreater()
{
    return isWindowsVersionOrGreater(5, 1, 1);
}

nothrow @nogc @trusted
bool isWindowsXPSP2OrGreater()
{
    return isWindowsVersionOrGreater(5, 1, 2);
}

nothrow @nogc @trusted
bool isWindowsXPSP3OrGreater()
{
    return isWindowsVersionOrGreater(5, 1, 3);
}

nothrow @nogc @trusted
bool isWindowsVistaOrGreater()
{
    return isWindowsVersionOrGreater(6, 0, 0);
}

nothrow @nogc @trusted
bool isWindowsVistaSP1OrGreater()
{
    return isWindowsVersionOrGreater(6, 0, 1);
}

nothrow @nogc @trusted
bool isWindowsVistaSP2OrGreater()
{
    return isWindowsVersionOrGreater(6, 0, 2);
}

nothrow @nogc @trusted
bool isWindows7OrGreater()
{
    return isWindowsVersionOrGreater(6, 1, 0);
}

nothrow @nogc @trusted
bool isWindows7SP1OrGreater()
{
    return isWindowsVersionOrGreater(6, 1, 1);
}

nothrow @nogc @trusted
bool isWindows8OrGreater()
{
    return isWindowsVersionOrGreater(6, 2, 0);
}

nothrow @nogc @trusted
bool isWindows8Point1OrGreater()
{
    return isWindowsVersionOrGreater(6, 3, 0);
}

nothrow @nogc @trusted
bool isWindows10OrGreater()
{
    return isWindowsVersionOrGreater(6, 4, 0);
}

nothrow @nogc @trusted
bool isWindowsServer()
{
    OSVERSIONINFOEXW osvi;
    ulong dwlConditionMask = VerSetConditionMask( 0, VER_PRODUCT_TYPE, VER_EQUAL);
    return VerifyVersionInfoW(osvi, VER_PRODUCT_TYPE, dwlConditionMask) != 0;
}

pure @safe nothrow @nogc
I dtoi(I)(in C[] str)
{
    I result = 0;
    size_t len = str.length;
    size_t i = 0;
    while (i < len && str[i] == '0')
        i++;
    while(i < len)
    {
        C c = str[i++];
        assert(c >= '0' && c <= '9', "Invalid character.");
        I ret = cast(I)(result * 10);
        assert(result == ret / 10, "Overflow.");
        result = ret;
        assert(c - '0' <= I.max - result, "Overflow.");
        result += c - '0';
    }
    return result;
}

pure @safe nothrow @nogc
I htoi(I)(in char[] str)
{
    I result = 0;
    int digits = 0;
    size_t len = str.length;
    size_t i = 0;
    while (i < len && str[i] == '0')
        i++;
    while(i < len)
    {
        char c = str[i++];
        assert(digits++ < I.sizeof * 2, "Overflow.");
        assert((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'));
        result <<= 4;
        if (c >= '0' && c <= '9')
            result |= cast(byte)(c - '0');
        else if (c >= 'a' && c <= 'f')
            result |= cast(byte)(c - 'a' + 10);
        else
            result |= cast(byte)(c - 'A' + 10);
    }
    return result;
}

pure @safe nothrow
C[] itod(C, I)(in I value)
{
    static if (I.sizeof == 1)
        enum len = 4;
    else static if (I.sizeof == 2)
        enum len = 6;
    else static if (I.sizeof == 4)
        enum len = 11;
    else
        enum len = 20;
    if (value == 0)
        return ['0'];
    C[] buf = new C[len];
    int i = len - 1;
    Unsigned!I v = value < 0 ? -value : value;
    while (v != 0)
    {
        buf[i--] = cast(C)('0' + v % 10);
        v /= 10;
    }
    if (value < 0)
        buf[i--] = '-';
    return buf[i + 1 .. $];
}

pure @safe nothrow
char[] itoh(I)(in I value, in bool uppercase)
{
    if (value == 0)
        return ['0'];
    char[] buf = new char[I.sizeof * 2];
    int i = I.sizeof * 2 - 1;
    I v = value;
    auto base = (uppercase ? 'A': 'a') - 10;
    while (v != 0)
    {
        ubyte b = cast(ubyte)(v & 0xf);
        buf[i--] = v < 10 ? cast(char)('0' + b) : cast(char)(base + b);
        v >>> 4;
    }
    return buf[i + 1 .. $];
}

pure @trusted nothrow
wchar[] fromSz(in wchar* str, size_t maxLen)
{
    if (str is null)
        return null;
    if (*str == 0)
        return [];
    wchar* ptr = cast(wchar*)str;
    size_t len = 0;
    while(*ptr++ != 0 && len < maxLen)
        len++;
    return str[0 .. len].dup;
}

pure @trusted nothrow
wstring fromSz(in wchar* str)
{
    if (str is null)
        return null;
    if (*str == 0)
        return [];
    wchar* ptr = cast(wchar*)str;
    size_t len = 0;
    while(*ptr++ != 0)
        len++;
    return str[0 .. len].idup;
}



