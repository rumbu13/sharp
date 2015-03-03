module system.runtime.interopservices;

import system;
import system.io;
import system.runtime.serialization;

import internals.interop;
import internals.resources;
import internals.hresults;
import internals.kernel32;
import internals.utf;
import internals.ole32;

mixin template LinkLibrary(string libname)
{
    version(X86)
    {
        pragma(lib, "..\\lib\\x86\\" ~ libname);
    }
    else version(X86_64)
    {
        pragma(lib, "..\\lib\\amd64\\" ~ libname);
    }
    else version(ARM)
    {
        pragma(lib, "..\\lib\\arm\\" ~ libname);
    }
}

// =====================================================================================================================
// DLLImport
// =====================================================================================================================


enum Charset
{
    None,
    Ansi,
    Auto,
    Unicode,
}

__gshared const(void)*[string] fmap;
__gshared const(void)*[string] mmap;

struct DllImport(string dllName, string entryPoint, F,
                 Charset charSet = Charset.Auto, bool exactSpelling = false, 
                 bool setLastError = false, bool throwHResult = false) 
{
    static if (is(F R == return) && is(F FP: FP*) && is(FP P == function))
    {
        static R opCall(P args) 
        {
            static assert(dllName.length > 0, "Library name is mandatory");
            static assert(entryPoint.length > 0, "Entry point name is mandatory");
            static if (entryPoint[0] == '#')
            {
                static assert(entryPoint.length > 1, "Entry point Ordinal is missing");
                static assert(entryPoint.length < 7, "Entry point Ordinal is too big");
                static if (entryPoint.length >= 2)
                    static assert(entryPoint[1] >= '0' && entryPoint[1] <= '9', "Expecting integral digit : (" ~ entryPoint[1] ~ ")");
                static if (entryPoint.length >= 3)
                    static assert(entryPoint[2] >= '0' && entryPoint[2] <= '9', "Expecting integral digit : (" ~ entryPoint[2] ~ ")");
                static if (entryPoint.length >= 4)
                    static assert(entryPoint[3] >= '0' && entryPoint[1] <= '9', "Expecting integral digit : (" ~ entryPoint[3] ~ ")");
                static if (entryPoint.length >= 5)
                    static assert(entryPoint[4] >= '0' && entryPoint[1] <= '9', "Expecting integral digit : (" ~ entryPoint[4] ~ ")");
                static if (entryPoint.length >= 6)
                    static assert(entryPoint[5] >= '0' && entryPoint[1] <= '9', "Expecting integral digit : (" ~ entryPoint[5] ~ ")");
                static if (entryPoint.length == 6)
                {
                    static assert(entryPoint[1] < '7', "Entry point Ordinal is out of range (ushort)");
                    static if (entryPoint[1] == '6')
                        static assert(entryPoint[2] <= '5', "Entry point Ordinal is out of range (ushort)");
                    static if (entryPoint[2] == '5')
                        static assert(entryPoint[3] <= '5', "Entry point Ordinal is out of range (ushort)");
                    static if (entryPoint[3] == '5')
                        static assert(entryPoint[4] <= '3', "Entry point Ordinal is out of range (ushort)");
                    static if (entryPoint[4] == '3')
                        static assert(entryPoint[5] <= '5', "Entry point Ordinal is out of range (ushort)");
                }
            }
            enum key = dllName ~ "." ~ entryPoint ~ "." ~ cast(char)(charSet + '0') ~ "." ~ (exactSpelling ? '1' : '0');

            F func;
            auto fp = key in fmap;
            if (fp)
            {
                func = cast(F)(*fp);
                if (func is null)
                    throw new EntryPointNotFoundException();
            }
            else
            {

                auto phModule = dllName in mmap;             
                auto hModule = phModule !is null ? *phModule : LoadLibraryW(dllName.toUTF16z());
                synchronized
                {
                    mmap[dllName] = hModule;
                }
                if (hModule is null)
                {
                    throw new DLLNotFoundException();
                }
                static if (entryPoint[0] == '#')
                {
                    ushort Ordinal = dtoi!ushort(entryPoint[1 .. $]);
                    func = cast(F)GetProcAddress(hModule, cast(char*)Ordinal);
                }
                else
                {
                    func = cast(F)(GetProcAddress(hModule, entryPoint.zeroTerminated()));
                    static if (!exactSpelling)
                    {
                        if (func is null)
                        {
                            static if (charSet == Charset.Auto || charset == Charset.Unicode)
                                func = cast(F)(GetProcAddress(hModule, (entryPoint ~ "W").zeroTerminated()));
                            else
                                func = cast(F)(GetProcAddress(hModule, (entryPoint ~ "A").zeroTerminated()));
                        }
                    }
                }
                synchronized
                {
                    fmap[key] = cast(const(void)*)func;
                }
                if (func is null)
                    throw new EntryPointNotFoundException();
            }
            static if (setLastError)
            {
                Marshal.SetLastWin32Error(0);
            }
            R result = func(args);
            static if (is(R == int) && throwHResult)
            {
                if (throwHResult)
                    Marshal.ThrowExceptionForHR(result);
            }
            else static if (throwHResult)
            {
                static assert(false, "Return type must be int, not " ~ R.stringof ~ ", to throw HRESULT");
            }
            return result;
        }
    }
    else
        static assert(false, F.stringof ~ " is not a function");
}

// =====================================================================================================================
// ExternalException
// =====================================================================================================================

@Serializable()
class ExternalException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionExternal"));
        HResult = E_FAIL;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = E_FAIL;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = E_FAIL;
    }
}

// =====================================================================================================================
// COMException
// =====================================================================================================================

class COMException: ExternalException
{
    this(int errorCode)
    {
        super(getSystemErrorMessage(errorCode));
        HResult = errorCode;
    }

    this()
    {
        super(SharpResources.GetString("ExceptionCOM"));
        HResult = E_FAIL;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = E_FAIL;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = E_FAIL;
    }
}

// =====================================================================================================================
// Marshal
// =====================================================================================================================

struct Marshal
{
    @disable this();

    nothrow @nogc
    static void SetLastWin32Error(int code)
    {
        SetLastError(code);
    }

    nothrow @nogc 
    static int GetLastWin32Error()
    {
        return GetLastError();
    }

    nothrow @nogc
    static int GetHRForLastWin32Error()
    {
        int le = GetLastWin32Error();
        if ((le & 0x80000000) == 0x80000000)
            return le;
        return ((le & 0x0000FFFF) | 0x80070000);
    }

    static int GetHRForWin32Error(int err)
    {
        if ((err & 0x80000000) == 0x80000000)
            return err;
        return ((err & 0x0000FFFF) | 0x80070000);
    }

    static SharpException GetExceptionForHR(in int errorCode)
    {
        if (errorCode >= 0)
            return null;
        switch (errorCode)
        {
            case E_FAIL:
                return new ExternalException();
            case E_NOTIMPL:
                return new NotImplementedException();
            case E_POINTER:
                return new ArgumentNullException();
            case COR_E_ARGUMENT:
                return new ArgumentException();
            case COR_E_ARGUMENTOUTOFRANGE:
                return new ArgumentOutOfRangeException();
            case COR_E_ARITHMETIC:
                return new ArithmeticException();
            case COR_E_DIRECTORYNOTFOUND:
               return new DirectoryNotFoundException();
            case COR_E_DLLNOTFOUND:
                return new DLLNotFoundException();
            case COR_E_ENTRYPOINTNOTFOUND:
                return new EntryPointNotFoundException();
            case COR_E_EXCEPTION:
                return new SharpException();
            case COR_E_FILENOTFOUND:
               return new FileNotFoundException();
            case COR_E_FORMAT:
                return new FormatException();
            case COR_E_INVALIDCAST:
                return new InvalidCastException();
            case COR_E_INVALIDOPERATION:
                return new InvalidOperationException();
            case COR_E_IO:
               return new IOException();
            case COR_E_NOTSUPPORTED:
                return new NotSupportedException();
            case COR_E_OBJECTDISPOSED:
                return new ObjectDisposedException();
            case COR_E_OUTOFMEMORY:
                return new OutOfMemoryException();
            case COR_E_OVERFLOW:
                return new OverflowException();
            case COR_E_SERIALIZATION:
                return new SerializationException();
            case COR_E_SYSTEM:
                return new SystemException();
            case COR_E_TYPELOAD:
                return new TypeLoadException();
            case COR_E_UNAUTHORIZEDACCESS:
                return new UnauthorizedAccessException();
            case DISP_E_OVERFLOW:
                return new OverflowException();
            default:
                return new COMException(errorCode);
        }
    }

    static void ThrowExceptionForHR(in int errorCode)
    {
        auto exc = GetExceptionForHR(errorCode);
        if (exc !is null)
            throw exc;
    }
}

enum MidpointRounding
{
    ToEven,
    AwayFromZero,
}

// =====================================================================================================================
// COM
// =====================================================================================================================


private string mixInterface(I, bool throwOnHResult = false)() 
{
    string s;
    foreach(member; __traits(allMembers, I))
    {
        foreach(overload; __traits(getOverloads, I, member))
        {
            alias O = typeof(overload);
            static if (is(O R == return) && is(O F == function) && is(O P == __parameters))
            {
                s ~= R.stringof ~ " " ~ member ~ P.stringof ~ "\r";
                s ~= "{\r";
                static if (throwOnHResult && is(R == int))
                    s ~= "    int hr = ";
                else
                    s ~= "    return ";

                s ~= "_interface." ~ member ~ "(";
                bool firstTime = true;
                foreach(i, p; P)
                {
                    if (!firstTime)
                        s ~= ", ";
                    else
                        firstTime = false;
                    s ~= __traits(identifier, P[i .. i + 1]);
                }
                s ~= ");\r";
                static if (throwOnHResult && is(R == int))
                    s ~= "    check(hr);\r    return hr;\r";                   
                s ~= "}\r";               
            }

        }
    }
    return s;
}

private void** comret(T)(out T ppv)
{
    return cast(void**)&ppv;
}

enum RegistrationClassContext
{
    InProcessServer                 = 0x00000001,
    InProcessHandler                = 0x00000002,
    LocalServer                     = 0x00000004,
    InProcessServer16               = 0x00000008,
    RemoteServer                    = 0x00000010,
    InProcessHandler16              = 0x00000020,
    Reserved1                       = 0x00000040,
    Reserved2                       = 0x00000080,
    Reserved3                       = 0x00000100,
    Reserved4                       = 0x00000200,
    NoCodeDownload                  = 0x00000400,
    Reserved5                       = 0x00000800,
    NoCustomMarshal                 = 0x00001000,
    EnableCodeDownload              = 0x00002000,
    NoFailureLog                    = 0x00004000,
    DisableActivateAsActivator      = 0x00008000,
    EnableActivateAsActivator       = 0x00010000,
    FromDefaultContext              = 0x00020000,
}

final class COMImport(Guid clsid, I, bool throwOnHResult = false) : IDisposable if (is(I : IUnknown))
{
    private I _interface;
    private bool _disposed;

    public static immutable CLSID = clsid;
    private void Dispose(bool disposing)
    {
        if (_disposed)
            return;
        if (disposing)
            GC.SuppressFinalize(this);
        _interface.Release();
        _disposed = true;
    }

    static if (throwOnHResult)
    {
        private void check(int hr)
        {
            if (FAILED(hr))
                Marshal.ThrowExceptionForHR(hr);
        }
    }

    public this(RegistrationClassContext context)
    {
        startupCOM();
        int hr = CoCreateInstance(CLSID, null, context, _interface.IID, comret(_interface));
        if (FAILED(hr))
            Marshal.ThrowExceptionForHR(hr);
    }

    public this()
    {
        this(RegistrationClassContext.InProcessServer);
    }

    ~this()
    {
        Dispose(false);
    }

    public void Dispose()
    {
        Dispose(true);
    }

    mixin(mixInterface!I());
}

private bool isCOMStartedUp;
private uint comMode;

void startupCOM(uint mode)
{
    if (isCOMStartedUp && comMode == mode)
        return;
    if (isCOMStartedUp)
        shutdownCOM();
    int hr = CoInitializeEx(null, mode);
    if (FAILED(hr))
        Marshal.ThrowExceptionForHR(hr);
    isCOMStartedUp = true;
    comMode = mode;
}

void startupCOM()
{
    if (!isCOMStartedUp)
        startupCOM(COINIT_APARTMENTTHREADED);
}

void shutdownCOM()
{
    if (!isCOMStartedUp)
        return;
    GC.Collect();
    CoUninitialize();
}


//cyclic bug
//static ~this()
//{
//    shutdownCOM();
//}