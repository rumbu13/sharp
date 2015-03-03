module internals.ole32;

import system;
import system.runtime.interopservices;
import internals.kernel32;

mixin LinkLibrary!"ole32.lib";

bool SUCCEEDED(int hr) { return hr >= 0; }
bool FAILED(int hr) { return hr < 0; }

extern(Windows)  :

enum
{
    COINITBASE_MULTITHREADED  = 0x0,
    COINIT_APARTMENTTHREADED  = 0x2,
    COINIT_MULTITHREADED      = COINITBASE_MULTITHREADED,
    COINIT_DISABLE_OLE1DDE    = 0x4,     
    COINIT_SPEED_OVER_MEMORY  = 0x8,     
}

int CoCreateGuid(ref Guid guid);
int CoCreateInstance(in ref Guid rclsid, IUnknown pUnkOuter, uint dwlsContext, in ref Guid riid, void** ppv);
int CoInitializeEx(void* pvReserved, uint dwoInit);
void CoUninitialize();

void* CoTaskMemAlloc(in size_t cb);
void CoTaskMemFree(in void* pv);

interface IUnknown
{
    static immutable IID = g!"00000000-0000-0000-c000-000000000046";
    int QueryInterface(in ref Guid riid, void** ppvObject);
    uint AddRef();
    uint Release();
}

interface AsyncIUnknown : IUnknown
{
    static immutable IID = g!"000e0000-0000-0000-c000-000000000046";
    int  Begin_QueryInterface(in ref Guid riid);
    int  Finish_QueryInterface(void **ppvObject);
    int  Begin_AddRef();
    uint Finish_AddRef();
    int  Begin_Release();
    uint Finish_Release();
}

interface IClassFactory : IUnknown
{
    static immutable IID = g!"00000001-0000-0000-c000-000000000046";
    int CreateInstance(IUnknown * pUnkOuter, in ref Guid riid, void **ppvObject);
    int RemoteCreateInstance(in ref Guid riid, IUnknown **ppvObject);
    int LockServer(in bool fLock);
    int RemoteLockServer(in bool fLock);
}


struct STATSTG 
{
    wchar* pwcsName;
    uint type;
    ulong cbSize;
    FILETIME mtime;
    FILETIME ctime;
    FILETIME atime;
    uint grfMode;
    uint grfLocksSupported;
    Guid clsid;
    uint grfStateBits;
    uint reserved;
}

interface ISequentialStream : IUnknown
{
    static immutable IID = g!"0c733a30-2a1c-11ce-ade5-00aa0044773d";
    int Read(void* pv, uint cb, ref uint pcbRead);
    int Write(in void* pv, uint cb, ref uint pcbWritten);
}

interface IStream : ISequentialStream 
{
    static immutable IID = g!"0000000c-0000-0000-c000-000000000046";
    int Seek(long dlibMove, uint dwOrigin, ref ulong plibNewPosition);
    int SetSize(ulong libNewSize);
    int CopyTo(IStream stm, ulong cb, ref ulong pcbRead, ref ulong pcbWritten);
    int Commit(uint hrfCommitFlags);
    int Revert();
    int LockRegion(ulong libOffset, ulong cb, uint dwLockType);
    int UnlockRegion(ulong libOffset, ulong cb, uint dwLockType);
    int Stat(out STATSTG pstatstg, uint grfStatFlag);
    int Clone(out IStream ppstm);
}

struct MIMECPINFO
{
    uint  dwFlags;
    uint  uiCodePage;
    uint  uiFamilyCodePage;
    wchar wszDescription[64];
    wchar wszWebCharset[50];
    wchar wszHeaderCharset[50];
    wchar wszBodyCharset[50];
    wchar wszFixedWidthFont[32];
    wchar wszProportionalFont[32];
    ubyte bGDICharset;
}

struct MIMECHARSETINFO
{
    uint uiCodePage;
    uint uiInternetEncoding;
    wchar wszCharset[50];
}

struct RFC1766INFO
{
    uint lcid;
    wchar wszRfc1766[6];
    wchar wszLocaleName[32];
}

struct DetectEncodingInfo
{
    uint nLangID;
    uint nCodePage;
    int nDocPercent;
    int nConfidence;
}

struct SCRIPTINFO 
{
    ubyte ScriptId;
    uint uiCodePage;
    wchar wszDescription[64];
    wchar wszFixedWidthFont[32];
    wchar wszProportionalFont[32];
}

enum
{
    MIMECONTF_MAILNEWS	            = 0x1,
    MIMECONTF_BROWSER	            = 0x2,
    MIMECONTF_MINIMAL	            = 0x4,
    MIMECONTF_IMPORT	            = 0x8,
    MIMECONTF_SAVABLE_MAILNEWS	    = 0x100,
    MIMECONTF_SAVABLE_BROWSER	    = 0x200,
    MIMECONTF_EXPORT	            = 0x400,
    MIMECONTF_PRIVCONVERTER	        = 0x10000,
    MIMECONTF_VALID	                = 0x20000,
    MIMECONTF_VALID_NLS	            = 0x40000,
    MIMECONTF_MIME_IE4	            = 0x10000000,
    MIMECONTF_MIME_LATEST	        = 0x20000000,
    MIMECONTF_MIME_REGISTRY	        = 0x40000000
}

interface IEnumCodePage : IUnknown
{
    static immutable IID = g!"275c23e3-3747-11d0-9fea-00aa003f8646";
    int Clone(out IEnumCodePage ppEnum);
    int Next(uint celt, MIMECPINFO* rgelt, out uint pceltFetched);
    int Reset();
    int Skip(uint celt);
}

interface IMLangConvertCharset : IUnknown 
{
    static immutable IID = g!"d66d6f98-cdaa-11d0-b822-00c04fc9b31f";
    int Initialize(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty);
    int GetSourceCodePage(out uint puiSrcCodePage);
    int GetDestinationCodePage(out uint puiDstCodePage);
    int GetProperty(out uint pdwProperty);
    int DoConversion(ubyte* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
    int DoConversionToUnicode(ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize);
    int DoConversionFromUnicode(wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
}

interface IEnumRfc1766 : IUnknown 
{
    static immutable IID = g!"3dc39d1d-c030-11d0-b81b-00c04fc9b31f";
    int lCone(out IEnumRfc1766 ppEnum);
    int Next(uint celt, RFC1766INFO* rgelt, out uint pceltFetched);
    int Reset();
    int Skip(uint celt);
}

interface IEnumScript : IUnknown 
{
    static immutable IID = g!"ae5f1430-388b-11d2-8380-00c04f8f5da1";
    int Clone(out IEnumScript ppEnum);
    int Next(uint celt, SCRIPTINFO* rgelt, out uint pceltFetched);
    int Reset();
    int Skip(uint celt);
}

interface IMultiLanguage2 : IUnknown 
{
    static immutable IID = g!"dccfc164-2b38-11d2-b7ec-00c04f8f5d9a";
    int GetNumberOfCodePageInfo(out uint pCodePage);
    int GetCodePageInfo(uint uiCodePage, ushort LangId, out MIMECPINFO pCodePageInfo);
    int GetFamilyCodePage(uint uiCodePage, out uint puiFamilyCodePage);
    int EnumCodePages(uint grfFlags, ushort LangId, out IEnumCodePage ppEnumodePage);
    int GetCharsetInfo(wchar* Charset, out MIMECHARSETINFO pCharsetInfo);
    int IsConvertible(uint dwSrcEncoding, uint dwDstEncoding);
    int ConvertString(ref uint pdwMode, uint dwSrcEncoding, uint dwDstEncoding, ubyte* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
    int ConvertStringToUnicode(ref uint pdwMode, uint dwEncoding, ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize);
    int ConvertStringFromUnicode(ref uint pdwMode, uint dwEncoding, wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize);
    int ConvertStringReset();
    int GetRfc1766FromLcid(uint Locale, out wchar* pbstrRfc1766);
    int GetLcidFromRfc1766(out uint Locale, wchar* bstrRfc1766);
    int EnumRfc1766(out IEnumRfc1766 ppEnumRfc1766);
    int GetRfc1766Info(uint Locale, out RFC1766INFO pRfc1766Info);
    int CreateConvertCharset(uint uiSrcCodePage, uint uiDstCodePage, uint dwProperty, out IMLangConvertCharset ppMLangConvertCharset);
    int ConvertStringInIStream(ref uint pdwMode, uint dwFlag, wchar* lpFallBack, uint dwSrcEncoding, uint dwDstEncoding, IStream pstmIn, IStream pstmOut);
    int ConvertStringToUnicodeEx(uint dwEncoding, ubyte* pSrcStr, ref uint pcSrcSize, wchar* pDstStr, ref uint pcDstSize, uint dwFlag, wchar* lpFallBack);
    int ConvertStringFromUnicodeEx(uint dwEncoding, wchar* pSrcStr, ref uint pcSrcSize, ubyte* pDstStr, ref uint pcDstSize, uint dwFlag, wchar* lpFallBack);
    int DetectCodepageInIStream(uint dwFlag, uint dwPrefWinCodePage, IStream pstmIn, ref DetectEncodingInfo lpEncoding, ref int pcScores);
    int DetectInputCodepage(uint dwFlag, uint dwPrefWinCodePage, ubyte* pSrcStr, ref int pcSrcSize, ref DetectEncodingInfo lpEncoding, ref int pcScores);
    int ValidateCodePage(uint uiCodePage, void* hwnd);
    int GetCodePageDescription(uint uiCodePage, uint lcid, wchar* lpWideCharStr, int cchWideChar);
    int IsCodePageInstallable(uint uiCodePage);
    int SetMimeDBSource(uint dwSource);
    int GetNumberOfScripts(out uint pnScripts);
    int EnumScripts(uint dwFlags, ushort LangId, out IEnumScript ppEnumScript);
    int ValidateCodePageEx(uint uiodePage, void* hwnd, uint dwfIODControl);
}

interface IErrorInfo : IUnknown
{
    static immutable IID = g!"1cf2b120-547d-101b-8e65-08002b2bd119";
    int GetGUID(out Guid pGUID);
    int GetSource(out wchar* pBstrSource);
    int GetDescription(out wchar* pBstrDescription);
    int GetHelpFile(out wchar* pBstrHelpFile);
    int GetHelpontext(out uint pdwHelpContext);
}