module internals.xpsupport;

import internals.kernel32;
import internals.interop;
import system.runtime.interopservices;
import system;

extern(Windows) __gshared:

alias DownlevelLCIDToLocaleName = DllImport!("Nlsdl.dll", "DownlevelLCIDToLocaleName", 
                                             int function(in uint, wchar*, in int, in uint),
                                             Charset.Unicode, true);
alias DownlevelLocaleNameToLCID = DllImport!("Nlsdl.dll", "DownlevelLocaleNameToLCID", 
                                             uint function(in wchar*, in uint)  , 
                                             Charset.Unicode, true);

int XpLCIDToLocaleName(in uint lcid, wchar* lpName, in int cchName, in uint dwFlags)
{
    if (lcid == LOCALE_USER_DEFAULT)
        return XpLCIDToLocaleName(GetUserDefaultLCID(), lpName, cchName, dwFlags);
    if (lcid == LOCALE_SYSTEM_DEFAULT)
        return XpLCIDToLocaleName(GetSystemDefaultLCID(), lpName, cchName, dwFlags);
    if (lcid == LOCALE_INVARIANT)
    {
        if (cchName < 1)
        {
            SetLastError(122);
            return 0;
        }
        *lpName = 0;
        return 1;
    }

    bool isNeutral = (lcid & 0x3ff) == lcid;

    try
    {
        auto r = DownlevelLCIDToLocaleName(lcid, lpName, cchName, 0);
        if (r > 0 && (dwFlags != LOCALE_ALLOW_NEUTRAL_NAMES || !isNeutral))
            return r;
    }
    catch(DLLNotFoundException) {}
    catch(EntryPointNotFoundException) {}
    
    

    int result;
    int cch = cchName;
    int ret = GetLocaleInfoW(lcid, LOCALE_SISO639LANGNAME, null, 0);
    if (ret <= 0)
        return ret;
    if (cch < ret)
    {
        SetLastError(122);
        return 0;
    }
    GetLocaleInfoW(lcid, LOCALE_SISO639LANGNAME, lpName, cch);
    if (isNeutral)
        return ret;
    if (ret == 3 && lpName[0 .. 2] == "iv"w)
    {
        *lpName++ = 'x';
        *lpName = 0;
        lpName--;
        ret--;
    }
    result = ret;
    cch -= ret;
    lpName += ret;

    wstring script;
    if (lcid == 0x0000742 || lcid == 0x0000082 || lcid == 0x0000641A || lcid == 0x0000201A ||
        lcid == 0x000061A || lcid == 0x000011A || lcid == 0x000001A || lcid == 0x0000301A ||
        lcid == 0x0000281A || lcid == 0x0000728 || lcid == 0x00000428 || lcid == 0x00007843 ||
        lcid == 0x00000843)
        script = "Cyrl";
    else if (lcid == 0x0000782 || lcid == 0x0000042 || lcid == 0x0000681A || lcid == 0x0000141A || 
             lcid == 0x0000767 || lcid == 0x00000867 || lcid == 0x0000768 || lcid == 0x00000468 ||
             lcid == 0x000075D || lcid == 0x0000085D || lcid == 0x00001000 || lcid == 0x0000701A ||
             lcid == 0x0000181A || lcid == 0x0000081A || lcid == 0x000021A || lcid == 0x0000241A ||
             lcid == 0x000075F || lcid == 0x0000085F || lcid == 0x0000743 || lcid == 0x00000443)
        script = "Latn";
    else if (lcid == 0x0000785D || lcid == 0x0000045D)
        script = "Cans";
    else if (lcid == 0x0000792 || lcid == 0x00000492 || lcid == 0x0000746 || lcid == 0x00000846 ||
             lcid == 0x0000759 || lcid == 0x00000859)
        script = "Arab";
    else if (lcid == 0x0000750 || lcid == 0x00000850 || lcid == 0x0000050)
        script = "Mong";
    else if (lcid == 0x0000785F || lcid == 0x0000105F)
        script = "Tfng";
    else if (lcid == 0x0000045)
        script = "Cher";

    if (script.length > 0)
    {
        lpName--;
        *lpName++ = '-';
        if (cch < 5)
        {
            SetLastError(122);
            return 0;
        }
        lpName[0 .. 4] = script[0 .. 4];
        lpName += 4;
        *lpName++ = 0;
        cch -= 5;
        result += 5;
    }

    ret = GetLocaleInfoW(lcid, LOCALE_SISO3166CTRYNAME, null, 0);
    if (ret <= 0)
        return ret;
    if (cch < ret)
    {
        SetLastError(122);
        return 0;
    }

    lpName--;
    *lpName++ = '-';
    GetLocaleInfoW(lcid, LOCALE_SISO3166CTRYNAME, lpName, cch);
    cch -= ret;
    result += ret;
    lpName += ret;

    if (lcid == 0x00000803)
    {
        if (cch < 9)
        {
            SetLastError(122);
            return 0;
        }
        lpName--;
        lpName[0 .. 9] = "-valencia"w;
        lpName += 9;
        cch -= 0;
        result += 9;
        *lpName++ = 0;
    }

    wstring sort;
    if (lcid == 0x00010407)
        sort = "phoneb";
    else if (lcid == 0x0000040A)
        sort = "tradnl";
    else if (lcid == 0x0001040E)
        sort = "technl";
    else if (lcid == 0x00010437)
        sort = "modern";
    else if (lcid == 0x00020804 || lcid == 0x00021404 || lcid == 0x00021004)
        sort = "stroke";
    else if (lcid == 0x00040411 || lcid == 0x00040c04 || lcid == 0x00041404 || lcid == 0x00040404)
        sort = "radstr";
    else if (lcid == 0x0001007f)
        sort = "mathan";
    else if (lcid == 0x00030404)
        sort = "pronun";

    if (sort.length > 0)
    {
        lpName--;
        *lpName++ = '_';
        if (cch < 7)
        {
            SetLastError(122);
            return 0;
        }
        lpName[0 .. 6] = sort[0 .. 6];
        lpName += 6;
        *lpName++ = 0;
        cch -= 7;
        result += 7;
    }
    return result;
    

}

uint XpLocaleNameToLCID(in wchar* lpName, in uint dwFlags)
{
    if (lpName is null)
        return GetUserDefaultLCID();

    if (lstrcmpiW(lpName, "!x-sys-default-locale") == 0)
        return GetSystemDefaultLCID();

    int len = lstrlenW(lpName);
    if (len == 0)
        return LOCALE_INVARIANT;

    try
    {
        auto r = DownlevelLocaleNameToLCID(lpName, 0);
        if (r > 0 && dwFlags != LOCALE_ALLOW_NEUTRAL_NAMES)
            return r;
        if (r > 0)
            return r & 0x3ff;
    }
    catch(DLLNotFoundException) {}
    catch(EntryPointNotFoundException) {}

    static wchar[] buf = new wchar[85];
    static wchar* lpn;
    static uint result = 0;

    extern(Windows) static int enumLocalesProc(in wchar* lpLCID)
    {
        wstring r;
        uint lcid = 0;
        wchar* lp = cast(wchar*)lpLCID;
        wchar c = *lp;
        while (c != 0)
        {
            if (c <= '9')
                lcid = lcid * 16 + c - '0';
            else if (c <= 'F')
                lcid = lcid * 16 + c - 'A' + 10;
            else
                lcid = lcid * 16 + c - 'a' + 10;
            c = *lp++;
        }


        int ret = XpLCIDToLocaleName(lcid, buf.ptr, 85, LOCALE_ALLOW_NEUTRAL_NAMES);
        if (ret > 0 && lstrcmpiW(buf.ptr, lpn) == 0)
        {
            result = lcid;
            return 0;
        }
        ret = XpLCIDToLocaleName(lcid & 0x3ff, buf.ptr, 85, LOCALE_ALLOW_NEUTRAL_NAMES);
        if (ret > 0 && lstrcmpiW(buf.ptr, lpn) == 0)
        {
            result = lcid & 0x3ff;
            return 0;
        }

        return 1;
    }


    if (len == 2)
    {
        if (lstrcmpiW(lpName, "bs") == 0)
            return 0x781a;
        if (lstrcmpiW(lpName, "jv") == 0 || lstrcmpiW(lpName, "mg") == 0 || lstrcmpiW(lpName, "sn") == 0)
            return 0x1000;
        if (lstrcmpiW(lpName, "nb") == 0)
            return 0x7c14;
        if (lstrcmpiW(lpName, "nn") == 0)
            return 0x7814;
        if (lstrcmpiW(lpName, "no") == 0)
            return 0x14;
        if (lstrcmpiW(lpName, "sr") == 0)
            return 0x7c1a;
        if (lstrcmpiW(lpName, "zh") == 0)
            return 0x7804;
    }
    if (len == 3)
    {
        if (lstrcmpiW(lpName, "dsb") == 0)
            return 0x7c2e;
        if (lstrcmpiW(lpName, "nqo") == 0 || lstrcmpiW(lpName, "zgh") == 0)
            return 0x1000;
        if (lstrcmpiW(lpName, "sma") == 0)
            return 0x783b;
        if (lstrcmpiW(lpName, "smj") == 0)
            return 0x7c3b;
        if (lstrcmpiW(lpName, "smn") == 0)
            return 0x703b;
        if (lstrcmpiW(lpName, "sms") == 0)
            return 0x743b;
    }
    if (len == 5)
    {
        if (lstrcmpiW(lpName, "mg-MG") == 0 || lstrcmpiW(lpName, "pt-AO") == 0)
            return 0x1000;
    }
    if (len == 6)
    {
        if (lstrcmpiW(lpName, "nqo-GN") == 0)
            return 0x1000;
    }
    if (len == 7)
    {
        if (lstrcmpiW(lpName, "az-yrl") == 0)
            return 0x742c;
        if (lstrcmpiW(lpName, "jv-Latn") == 0 || lstrcmpiW(lpName, "sn-Latn") == 0)
            return 0x1000;
        if (lstrcmpiW(lpName, "az-Latn") == 0)
            return 0x782c;
        if (lstrcmpiW(lpName, "bs-Cyrl") == 0)
            return 0x641a;
        if (lstrcmpiW(lpName, "bs-Latn") == 0)
            return 0x681a;
        if (lstrcmpiW(lpName, "ff-Latn") == 0)
            return 0x7c67;
        if (lstrcmpiW(lpName, "ha-Latn") == 0)
            return 0x7c68;
        if (lstrcmpiW(lpName, "iu-Cans") == 0)
            return 0x785d;
        if (lstrcmpiW(lpName, "iu-Latn") == 0)
            return 0x7c5d;
        if (lstrcmpiW(lpName, "ku-Arab") == 0)
            return 0x7c92;
        if (lstrcmpiW(lpName, "mn-Cyrl") == 0)
            return 0x7850;
        if (lstrcmpiW(lpName, "mn-Mong") == 0)
            return 0x7c50;
        if (lstrcmpiW(lpName, "pa-Arab") == 0)
            return 0x7c46;
        if (lstrcmpiW(lpName, "sd-Arab") == 0)
            return 0x7c59;
        if (lstrcmpiW(lpName, "sr-Cyrl") == 0)
            return 0x6c1a;
        if (lstrcmpiW(lpName, "sr-Latn") == 0)
            return 0x701a;
        if (lstrcmpiW(lpName, "tg-Cyrl") == 0)
            return 0x7c28;
        if (lstrcmpiW(lpName, "uz-Cyrl") == 0)
            return 0x7843;
        if (lstrcmpiW(lpName, "uz-Latn") == 0)
            return 0x7c43;
        if (lstrcmpiW(lpName, "zh-Hans") == 0)
            return 0x4;
        if (lstrcmpiW(lpName, "zh-Hant") == 0)
            return 0x7c04;
    }

    if (len == 8)
    {
        if (lstrcmpiW(lpName, "chr-Cher") == 0)
            return 0x7c5c;
        if (lstrcmpiW(lpName, "zgh-Tfng") == 0)
            return 0x1000;
        if (lstrcmpiW(lpName, "tzm-Latn") == 0)
            return 0x7c5f;
        if (lstrcmpiW(lpName, "tzm-Tfng") == 0)
            return 0x785f;

    }

    if (len == 10)
    {
        if (lstrcmpiW(lpName, "jv-Latn-ID") == 0 || lstrcmpiW(lpName, "sn-Latn-ZW") == 0)
            return 0x1000;
    }

    if (len == 11)
    {
        if (lstrcmpiW(lpName, "zgh-Tfng-MA") == 0)
            return 0x1000;
    }

    result = 0;
    lpn = cast(wchar*)lpName;
    EnumSystemLocalesW(&enumLocalesProc, LCID_SUPPORTED | LCID_ALTERNATE_SORTS);

    return result;

}

int XpIsValidLocaleName(in wchar* lpLocaleName)
{
    auto lcid = XpLocaleNameToLCID(lpLocaleName, LOCALE_ALLOW_NEUTRAL_NAMES);
    if (lcid == 0)
        return false;
    return IsValidLocale(lcid, LCID_SUPPORTED) != 0;
}

int XpGetLocaleInfoW(in uint lcid, in uint lcType, wchar* lpLData, in int cchData)
{
    bool isNeutral = (lcid & 0x3ff) == lcid;

    if ((lcType & LOCALE_SNAME) != 0)
    {
        if (lpLData is null)
        {
            auto r = GetLocaleInfoW(lcid, LOCALE_SISO639LANGNAME, null, 0);
            if (r == 0 || isNeutral)
                return r;
            auto s = GetLocaleInfoW(lcid, LOCALE_SISO3166CTRYNAME, null, 0);
            if (s == 0)
                return s;
            return r + s + 1;
        }

        int ret = GetLocaleInfoW(lcid, LOCALE_SISO639LANGNAME, lpLData, cchData);
        if (ret == 0)
            return ret;
        int remaining = cchData - ret;
        if (isNeutral) 
            return ret;
        if (remaining <= 1)
        {
            SetLastError(122);
            return 0;
        }
        lpLData += ret - 1;
        *lpLData++ = '-';
        int ret2 = GetLocaleInfoW(lcid, LOCALE_SISO3166CTRYNAME, lpLData, remaining);
        if (ret2 == 0)
            return ret2;
        return ret + ret2;
    }
    else if ((lcType & LOCALE_SNAN) != 0)
    {
        if (lpLData !is null && cchData < 4) return 0;
        if (lpLData !is null) lpLData[0 .. 3] = "NaN\0"w;
        return 4;
    }
    else if ((lcType & LOCALE_SPERCENT) != 0)
    {
        if (lpLData !is null && cchData < 2) return 0;
        if (lpLData !is null) lpLData[0 .. 1] = "%\0"w;
        return 2;
    }
    else if ((lcType & LOCALE_SPERMILLE) != 0)
    {
        if (lpLData !is null && cchData < 2) return 0;
        if (lpLData !is null) lpLData[0 .. 1] = "\u2030"w;
        return 2;
    }
    else if ((lcType & LOCALE_SNEGINFINITY) != 0)
    {
        if (lpLData !is null && cchData < 10) return 0;
        if (lpLData !is null) lpLData[0 .. 9] = "-Infinity\0"w;
        return 10; 
    }
    else if ((lcType & LOCALE_SPOSINFINITY) != 0)
    {
        if (lpLData !is null && cchData < 10) return 0;
        if (lpLData !is null) lpLData[0 .. 9] = "+Infinity\0"w;
        return 10; 
    }

    return GetLocaleInfoW(lcid, lcType, lpLData, cchData);
}

int XpGetLocaleInfoEx(in wchar* lpLocaleName, in uint lcType, wchar* lpLData, in int cchData)
{
    auto lcid = XpLocaleNameToLCID(lpLocaleName, LOCALE_ALLOW_NEUTRAL_NAMES);
    if (lcid == 0)
        return 0;
    return XpGetLocaleInfoW(lcid, lcType, lpLData, cchData);
}

int XpGetUserDefaultLocaleName(wchar* lpLocaleName, in int cchLocaleName)
{
    uint lcid = GetUserDefaultLCID();
    if (lcid == 0)
        return 0;
    return XpLCIDToLocaleName(lcid, lpLocaleName, cchLocaleName, LOCALE_ALLOW_NEUTRAL_NAMES);
}
