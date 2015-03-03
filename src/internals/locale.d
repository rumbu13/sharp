module internals.locale;

import system;
import system.globalization;
import system.runtime.interopservices;

import internals.interop;
import internals.kernel32;
import internals.utf;
import internals.xpsupport;
import internals.vistasupport;
import internals.checked;

import internals.core;

alias DownlevelLCIDToLocaleName = DllImport!("Nlsdl.dll", "DownlevelLCIDToLocaleName", 
                                            int function(in uint, wchar*, in int, in uint),
                                            Charset.Unicode, true);
alias DownlevelLocaleNameToLCID = DllImport!("Nlsdl.dll", "DownlevelLocaleNameToLCID", 
                                            uint function(in wchar*, in uint)  , 
                                            Charset.Unicode, true);

final class LocaleData : SharpObject
{
private:
    wstring localeName;
    const(wchar)* zlocaleName;
    uint localeID;
    bool useLocaleName;
    bool useUserOverride;

    uint _nlsVersion = uint.max;
    uint _nlsEffective;
    Guid _nlsCustom;

    static LocaleData _invariant;
    static LocaleData _current;
    static LocaleData _uiCurrent;

    static CalendarData[uint] calendarDataMap;

    void fillNlsVersion()
    {
        NLSVERSIONINFOEX viex;
        if (useLocaleName)
        {
            if (GetNLSVersionEx(COMPARE_STRING, zlocaleName, viex) == 0)
                Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
            _nlsVersion = viex.dwNLSVersion;
            _nlsEffective = viex.dwEffectiveId;
            _nlsCustom = viex.guidCustomVersion;

        }
        else
        {
            NLSVERSIONINFO vi;
            if (!GetNLSVersion(COMPARE_STRING, localeID, vi) == 0) 
                Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
            _nlsVersion = vi.dwNLSVersion;
        }
    }

    pure nothrow
    void setLocaleName(wstring localeName)
    {
        if (localeName != this.localeName)
        {
            this.localeName = localeName;
            zlocaleName = zeroTerminated(localeName);
        }
    }

    wstring getLocaleName(uint lcid)
    {
        if (lcid == LOCALE_NEUTRAL)
            return "";
        wchar[LOCALE_NAME_MAX_LENGTH] buf;
        int ret;
        
        if (isWindows7OrGreater())
            ret = LCIDToLocaleName(lcid, buf.ptr, LOCALE_NAME_MAX_LENGTH, LOCALE_ALLOW_NEUTRAL_NAMES);
        else if (isWindowsVistaOrGreater())
            ret = VistaLCIDToLocaleName(lcid, buf.ptr, LOCALE_NAME_MAX_LENGTH, LOCALE_ALLOW_NEUTRAL_NAMES);
        else
            ret = XpLCIDToLocaleName(lcid, buf.ptr, LOCALE_NAME_MAX_LENGTH, LOCALE_ALLOW_NEUTRAL_NAMES);
        if (ret > 0)
            return buf[0..ret - 1].idup;      
        return null;
    }

    static uint getLocaleId(wstring name)
    {
        if (name == "")
            return LOCALE_INVARIANT;
        uint lcid;
        
        if (isWindows7OrGreater())
            lcid = LocaleNameToLCID(name.zeroTerminated(), LOCALE_ALLOW_NEUTRAL_NAMES);
        else if (isWindowsVistaOrGreater())
            lcid = VistaLocaleNameToLCID(name.zeroTerminated(), LOCALE_ALLOW_NEUTRAL_NAMES);
        else
            lcid = XpLocaleNameToLCID(name.zeroTerminated(), LOCALE_ALLOW_NEUTRAL_NAMES);
        return lcid;
    }

    wstring getLocaleInfoStr(in int lc, bool fail = true)
    {
        int ret = useLocaleName ? 
            GetLocaleInfoEx(zlocaleName, lc | (!useUserOverride ? LOCALE_NOUSEROVERRIDE : 0), null, 0):
            XpGetLocaleInfoW(localeID, lc | (!useUserOverride ? LOCALE_NOUSEROVERRIDE : 0), null, 0);
        if (ret == 0 && fail)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        if (ret == 0)
            return null;
        wchar[] result = new wchar[ret];
        ret = useLocaleName ?
            GetLocaleInfoEx(zlocaleName, lc | (!useUserOverride ? LOCALE_NOUSEROVERRIDE : 0), result.ptr, ret):
            XpGetLocaleInfoW(localeID, lc | (!useUserOverride ? LOCALE_NOUSEROVERRIDE : 0), result.ptr, ret);
        if (ret == 0 && fail)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        if (ret == 0)
            return null;
        return cast(wstring)result[0 .. ret - 1];
    }

    int getLocaleInfoInt(in int lc)
    {
        wchar[2] result;
        int ret = useLocaleName ?
            GetLocaleInfoEx(zlocaleName, lc | LOCALE_RETURN_NUMBER | 
                            (!useUserOverride ? LOCALE_NOUSEROVERRIDE : 0), result.ptr, 2) :
            XpGetLocaleInfoW(localeID, lc | LOCALE_RETURN_NUMBER | 
                           (!useUserOverride ? LOCALE_NOUSEROVERRIDE : 0), result.ptr, 2);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return *cast(int*)(result.ptr);
    }

    pure @safe nothrow @nogc
    static uint getCompareFlags(CompareOptions options)
    {
        uint flags = NORM_LINGUISTIC_CASING;
        if ((options & CompareOptions.IgnoreCase) != 0)
            flags |= NORM_IGNORECASE;
        if ((options & CompareOptions.IgnoreKanaType) != 0)
            flags |= NORM_IGNOREKANATYPE;
        if ((options & CompareOptions.IgnoreNonSpace) != 0)
            flags |= NORM_IGNORENONSPACE;
        if ((options & CompareOptions.IgnoreSymbols) != 0)
            flags |= NORM_IGNORESYMBOLS;
        if ((options & CompareOptions.IgnoreWidth) != 0)
            flags |= NORM_IGNOREWIDTH;
        if ((options & CompareOptions.StringSort) != 0)
            flags |= SORT_STRINGSORT;
        return flags;
    }

public:
    bool init(wstring localeName, bool fallback)
    {
        useLocaleName = true;
        setLocaleName(localeName);
        if (isWindowsVistaOrGreater())
        {
            if (localeName.length == 0 || IsValidLocaleName(zlocaleName) != 0)
            {
                this.localeID = isWindows7OrGreater() ? 
                    LocaleNameToLCID(zlocaleName, LOCALE_ALLOW_NEUTRAL_NAMES) :
                    VistaLocaleNameToLCID(zlocaleName, LOCALE_ALLOW_NEUTRAL_NAMES);
                return true;
            }
            return false;
        }
        else if (fallback)
        {
            useLocaleName = false;
            if (localeName.length == 0)
                return init(LOCALE_INVARIANT, false);
            uint lcid = getLocaleId(localeName);
            if (lcid != 0)
                return init(lcid, false);
            return false;
        }
        return false;
    }

    bool init(uint lcid, bool fallback)
    {
        localeID = lcid;
        if (isWindowsVistaOrGreater() && fallback)
        {
            wstring lname = getLocaleName(lcid);
            setLocaleName(lname);
            if (lname !is null)
                return init(this.localeName, false);
        }
        useLocaleName = false;
        if (IsValidLocale(lcid, LCID_SUPPORTED) != 0)
        {
            setLocaleName(getLocaleName(lcid));
            return true;
        }
        return false;
    }

    this(wstring cultureName, bool useUserOverride)
    {
        if (!init(cultureName, true))
            throw new CultureNotFoundException("cultureName", null, localeName);
        this.useUserOverride = useUserOverride;
    }

    this(uint lcid, bool useUserOverride)
    {
        if (!init(lcid, true))
            throw new CultureNotFoundException("lcid", null, lcid);
        this.useUserOverride = useUserOverride;
    }  

    wstring toUppercase(in wchar[] ws) const
    {
        int ret = useLocaleName ?
            LCMapStringEx(zlocaleName, LCMAP_UPPERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), null, 0, null, null, 0) :
            LCMapStringW(localeID, LCMAP_UPPERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), null, 0);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        wchar[] result = new wchar[ret];
        ret = useLocaleName ?
            LCMapStringEx(zlocaleName, LCMAP_UPPERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), result.ptr, safe32bit(result.length), null, null, 0) :
            LCMapStringW(localeID, LCMAP_UPPERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), result.ptr, safe32bit(result.length));
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return cast(wstring)result[0 .. ret];
    }

    wstring toLowercase(wstring ws) const
    {
        int ret = useLocaleName ?
            LCMapStringEx(zlocaleName, LCMAP_LOWERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), null, 0, null, null, 0) :
            LCMapStringW(localeID, LCMAP_LOWERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), null, 0);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        wchar[] result = new wchar[ret];
        ret = useLocaleName ?
            LCMapStringEx(zlocaleName, LCMAP_LOWERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), result.ptr, safe32bit(result.length), null, null, 0) :
            LCMapStringW(localeID, LCMAP_LOWERCASE | LCMAP_LINGUISTIC_CASING, ws.ptr, safe32bit(ws.length), result.ptr, safe32bit(result.length));
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return cast(wstring)result[0 .. ret];
    }

    wstring toTitlecase(wstring ws) const
    {
        if (!isWindows7OrGreater())
            return null;
        int ret = useLocaleName ?
            LCMapStringEx(zlocaleName, LCMAP_TITLECASE, ws.ptr, safe32bit(ws.length), null, 0, null, null, 0) :
            LCMapStringW(localeID, LCMAP_TITLECASE, ws.ptr, safe32bit(ws.length), null, 0);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        wchar[] result = new wchar[ret];
        ret = useLocaleName ?
            LCMapStringEx(zlocaleName, LCMAP_TITLECASE, ws.ptr, safe32bit(ws.length), result.ptr, safe32bit(result.length), null, null, 0) :
            LCMapStringW(localeID, LCMAP_TITLECASE, ws.ptr, safe32bit(ws.length), result.ptr, safe32bit(result.length));
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return cast(wstring)result[0 .. ret];
    }

    @property 
    int iDefaultAnsiCodePage()
    {
        return getLocaleInfoInt(LOCALE_IDEFAULTANSICODEPAGE);
    }

    @property 
    int iDefaultEBCDICCodePage()
    {
        return getLocaleInfoInt(LOCALE_IDEFAULTEBCDICCODEPAGE);
    }

    @property 
    int iDefaultOEMCodePage()
    {
        return getLocaleInfoInt(LOCALE_IDEFAULTCODEPAGE);
    }

    @property 
    int iDefaultMACCodePage()
    {
        return getLocaleInfoInt(LOCALE_IDEFAULTMACCODEPAGE);
    }

    @property 
    int iReadingLayout()
    {
        static immutable uint[] rlCultures = 
        [
            0x0001, 0x000D, 0x0020, 0x0029, 0x0059, 0x005A, 0x0063, 0x0065, 0x0080,
            0x008C, 0x0092, 0x0401, 0x040D, 0x0420, 0x0429, 0x045A, 0x0463, 0x0465,
            0x0480, 0x048C, 0x0492, 0x0801, 0x0820, 0x0846, 0x0859, 0x0C01, 0x1000,
            0x1000, 0x1001, 0x1401, 0x1801, 0x1C01, 0x2001, 0x2401, 0x2801, 0x2C01,
            0x3001, 0x3401, 0x3801, 0x3C01, 0x4001, 0x7C46, 0x7C59, 0x7C92,
        ];
        if (isWindows7OrGreater())
            return getLocaleInfoInt(LOCALE_IREADINGLAYOUT);
        else
            return binarySearch(rlCultures, localeID) >= 0 ? 1 : 0;
    }

    @property 
    wstring sList()
    {
        return getLocaleInfoStr(LOCALE_SLIST);
    }

    @property pure @safe nothrow @nogc
    int lcid() const
    {
        return localeID;
    }

    @property
    wstring sName()
    {
        return getLocaleInfoStr(LOCALE_SNAME);
    }

    @property 
    wstring sISO3166Country()
    {
        return getLocaleInfoStr(LOCALE_SISO3166CTRYNAME);
    }

    @property 
    wstring sISO639Lang()
    {
        return getLocaleInfoStr(LOCALE_SISO639LANGNAME);
    }

    @property 
    wstring sDecimal()
    {
        return getLocaleInfoStr(LOCALE_SDECIMAL);
    }

    @property 
    wstring sMonDecimalSep()
    {
        return getLocaleInfoStr(LOCALE_SMONDECIMALSEP);
    }

    @property 
    wstring sGrouping()
    {
        return getLocaleInfoStr(LOCALE_SGROUPING);
    }

    @property 
    wstring sMonGrouping()
    {
        return getLocaleInfoStr(LOCALE_SMONGROUPING);
    }

    @property 
    wstring sCurrency()
    {
        return getLocaleInfoStr(LOCALE_SCURRENCY);
    }

    @property 
    wstring sNan()
    {
        return getLocaleInfoStr(LOCALE_SNAN);
    }

    @property 
    wstring sPercent()
    {
        return getLocaleInfoStr(LOCALE_SPERCENT);
    }

    @property 
    wstring sPermille()
    {
        return getLocaleInfoStr(LOCALE_SPERMILLE);
    }

    @property 
    wstring sThousand()
    {
        return getLocaleInfoStr(LOCALE_STHOUSAND);
    }

    @property 
    wstring sMonThousandSep()
    {
        return getLocaleInfoStr(LOCALE_SMONTHOUSANDSEP);
    }


    @property 
    wstring sPositiveSign()
    {
        return getLocaleInfoStr(LOCALE_SPOSITIVESIGN);
    }

    @property 
    wstring sNegativeSign()
    {
        return getLocaleInfoStr(LOCALE_SNEGATIVESIGN);
    }

    @property 
    wstring sNegInfinity()
    {
        return getLocaleInfoStr(LOCALE_SNEGINFINITY);
    }

    @property 
    wstring sPosInfinity()
    {
        return getLocaleInfoStr(LOCALE_SPOSINFINITY);
    }


    @property 
    wstring sNativeDigits()
    {
        return getLocaleInfoStr(LOCALE_SNATIVEDIGITS);
    }

    @property 
    int iDigits()
    {
        return getLocaleInfoInt(LOCALE_IDIGITS);
    }

    @property 
    int iCurrDigits()
    {
        return getLocaleInfoInt(LOCALE_ICURRDIGITS);
    }

    @property 
    int iNegCurr()
    {
        return getLocaleInfoInt(LOCALE_INEGCURR);
    }

    @property 
    int iNegNumber()
    {
        return  getLocaleInfoInt(LOCALE_INEGNUMBER);
    }

    @property 
    int iNegPercent()
    {
        return isWindows7OrGreater() ? getLocaleInfoInt(LOCALE_INEGATIVEPERCENT) : 0;
    }

    @property 
    int iPosPercent()
    {
        return isWindows7OrGreater() ? getLocaleInfoInt(LOCALE_IPOSITIVEPERCENT) : 0;
    }

    @property 
    int iDigitSubstitution()
    {
        return getLocaleInfoInt(LOCALE_IDIGITSUBSTITUTION);
    }

    @property int iCurrency()
    {
        return getLocaleInfoInt(LOCALE_ICURRENCY);
    }

    @property 
    static LocaleData invariant_()
    {
        if (_invariant is null)
            _invariant = new LocaleData("", false);
        return _invariant;
    }

    @property 
    static LocaleData current()
    {
        if (_current is null)
        {
            if (isWindowsVistaOrGreater())
            {
                wchar[LOCALE_NAME_MAX_LENGTH] buf;
                int ret = GetUserDefaultLocaleName(buf.ptr, LOCALE_NAME_MAX_LENGTH);
                if (ret > 0)
                {
                    _current = new LocaleData(buf[0..ret - 1].idup, true);
                    return _current;
                }
            }
            _current = new LocaleData(GetUserDefaultLCID(), true);
        }
        return _current;

    }

    @property
    static LocaleData uiCurrent()
    {
        if (_uiCurrent is null)
            _uiCurrent = new LocaleData(GetUserDefaultUILanguage(), true);
        return _uiCurrent;
    }


    int compare(wstring s1, wstring s2, CompareOptions options) const
    {
        int result = useLocaleName ?
            CompareStringEx(zlocaleName, getCompareFlags(options), s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null, null, 0) :
            CompareStringW(localeID,  getCompareFlags(options), s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length));
        if (result == 1)
            return -1;
        else if (result == 2)
            return 0;
        else if (result == 3)
            return 1;
        Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        assert(false);
    }

    int IndexOf(wstring s1, wstring s2, CompareOptions options) const
    {
        uint flags = getCompareFlags(options) | FIND_FROMSTART;
        int result = useLocaleName ?
            FindNLSStringEx(zlocaleName, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null, null, null, 0) :
            FindNLSString(localeID, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null);
        if (result >= 0)
            return result;
        if (Marshal.GetLastWin32Error() == 0)
            return -1;
        Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        assert(false);
    }

    int LastIndexOf(wstring s1, wstring s2, CompareOptions options) const
    {
        uint flags = getCompareFlags(options) | FIND_FROMEND;
        int result = useLocaleName ?
            FindNLSStringEx(zlocaleName, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null, null, null, 0) :
        FindNLSString(localeID, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null);
        if (result >= 0)
            return result;
        if (Marshal.GetLastWin32Error() == 0)
            return -1;
        Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        assert(false);
    }

    bool IsPrefix(wstring s1, wstring s2, CompareOptions options) const
    {
        uint flags = getCompareFlags(options) | FIND_STARTSWITH;
        int result = useLocaleName ?
            FindNLSStringEx(zlocaleName, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null, null, null, 0) :
            FindNLSString(localeID, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null);
        return result >= 0;
    }

    bool IsSuffix(wstring s1, wstring s2, CompareOptions options) const
    {
        uint flags = getCompareFlags(options) | FIND_ENDSWITH;
        int result = useLocaleName ?
            FindNLSStringEx(zlocaleName, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null, null, null, 0) :
            FindNLSString(localeID, flags, s1.ptr, safe32bit(s1.length), s2.ptr, safe32bit(s2.length), null);
        return result >= 0;
    }

    ubyte[] GetSortKey(wstring ws, CompareOptions options) const
    {
        uint flags = getCompareFlags(options) | LCMAP_SORTKEY;
        int ret = useLocaleName ?
            LCMapStringEx(zlocaleName, flags, ws.ptr, safe32bit(ws.length), null, 0, null, null, 0) :
            LCMapStringW(localeID, flags, ws.ptr, safe32bit(ws.length), null, 0);

        if (ret > 0)
        {
            ubyte[] buf = new ubyte[ret];
            ret = useLocaleName ?
                LCMapStringEx(zlocaleName, flags, ws.ptr, safe32bit(ws.length), cast(wchar*)buf, ret, null, null, 0) :
                LCMapStringW(localeID, flags, ws.ptr, safe32bit(ws.length), cast(wchar*)buf, ret);
            return buf[0 .. ret - 1];
        }
        return null;
    }

    @property 
    wstring sSortLocale()
    {
        return isWindows7OrGreater() ? getLocaleInfoStr(LOCALE_SSORTLOCALE) : sName;
    }

    @property 
    uint nlsVersion()
    {
        if (_nlsVersion == uint.max)
            fillNlsVersion();
        return _nlsVersion;
    }

    @property 
    uint nlsEffective()
    {
        if (_nlsVersion == uint.max)
            fillNlsVersion();
        return _nlsEffective;
    }

    @property 
    Guid nlsCustom()
    {
        if (_nlsVersion == uint.max)
            fillNlsVersion();
        return _nlsCustom;
    }

    wstring[] getDateFormats(in uint flags, in uint calID)
    {
        static wstring[] sresult;
        static int targetCal;

        extern(Windows) static int enumDateEx(in wchar* info, in uint calID, in size_t lParam)
        {
            if (targetCal == 0 || calID == targetCal)
            {
                int len = lstrlenW(info);
                sresult ~= info[0..len].idup; 
            }
            return 1;
        }

        extern(Windows) static int enumDate(in wchar* info, in uint calID)
        {
            if (targetCal == 0 || calID == targetCal)
            {
                int len = lstrlenW(info);
                sresult ~= info[0..len].idup; 
            }
            return 1;
        }

        sresult = null;
        targetCal = calID;

        if (isWindowsVistaOrGreater())
            EnumDateFormatsExEx(&enumDateEx, zlocaleName, flags , 0);           
        else
            EnumDateFormatsExW(&enumDate, localeID, flags);

        return sresult;
    }

    wstring[] getTimeFormats(in uint flags)
    {
        static wstring[] sresult;

        extern(Windows) static int enumTimeEx(in wchar* info, in size_t lParam)
        {
            int len = lstrlenW(info);
            sresult ~= info[0..len].idup; 
            return 1;
        }

        extern(Windows) static int enumTime(in wchar* info)
        {
            int len = lstrlenW(info);
            sresult ~= info[0..len].idup; 
            return 1;
        }

        sresult = null;

        if (isWindowsVistaOrGreater())
            EnumTimeFormatsEx(&enumTimeEx, zlocaleName, flags, 0);           
        else
            EnumTimeFormatsW(&enumTime, localeID, flags);

        return sresult;
    }

    CalendarData getCalendarData(uint calID)
    {
        auto p = calID in calendarDataMap;
        if (p)
            return *p;
        if (!isCalendarAvailable(calID))
            return null;
        auto cd = new CalendarData(this, calID);
        calendarDataMap[calID] = cd;
        return cd;
    }

    bool isCalendarAvailable(uint calID)
    {
        static bool isAvailable;
        static uint cid;

        extern(Windows) static int enumCalendarProc(in wchar* info, in uint calInfo)
        {
            isAvailable = calInfo == cid;
            return isAvailable ? 0 : 1;
        }

        extern(Windows) static int enumCalendarProcEx(in wchar* info, in uint calInfo, in wchar* reserved, in size_t lParam)
        {
            isAvailable = calInfo == cid;
            return isAvailable ? 0 : 1;
        }

        isAvailable = getLocaleInfoInt(LOCALE_ICALENDARTYPE) == calID;

        if (isAvailable)
            return true;
        cid = calID;
        if (useLocaleName)
            EnumCalendarInfoExEx(&enumCalendarProcEx, zlocaleName, ENUM_ALL_CALENDARS, null, CAL_ICALINTVALUE, 0);
        else
            EnumCalendarInfoExW(&enumCalendarProc, localeID, ENUM_ALL_CALENDARS, CAL_ICALINTVALUE);

        return isAvailable;
    }

    wstring[] getLongTimeFormats()
    {
        wstring[] result = getTimeFormats(0);
        wstring r = getLocaleInfoStr(LOCALE_STIMEFORMAT, false);
        if (r.length > 0)
        {
            bool alreadyIn = false;
            foreach(s; result)
                if (s == r)
                {
                    alreadyIn = true;
                    break;
                }
            if (!alreadyIn)
                result = r ~ result;
        }
        return result;
    }

    wstring[] getShortTimeFormats()
    {
        wstring[] result;
        if (isWindows7OrGreater())
        {
            result = getTimeFormats(TIME_NOSECONDS);
            wstring r = getLocaleInfoStr(LOCALE_SSHORTTIME, false);
            if (r.length > 0)
            {
                bool alreadyIn = false;
                foreach(s; result)
                    if (s == r)
                    {
                        alreadyIn = true;
                        break;
                    }
                if (!alreadyIn)
                    result = r ~ result;
            }
        }

        if (result.length > 0)
            return result;

        return ["HH:mm"];

    }

    @property wstring s1159()
    {
        return getLocaleInfoStr(LOCALE_S1159);
    }

    @property wstring s2359()
    {
        return getLocaleInfoStr(LOCALE_S2359);
    }

    @property int iFirstWeekOfYear()
    {
        return getLocaleInfoInt(LOCALE_IFIRSTWEEKOFYEAR);
    }

    @property int iFirstDayOfWeek()
    {
        return getLocaleInfoInt(LOCALE_IFIRSTDAYOFWEEK);
    }
}

int InternalLCIDToLocaleName(in uint lcid, wchar* lpName, in int cchName, in uint dwFlags)
{
    if (lcid == LOCALE_USER_DEFAULT)
        return InternalLCIDToLocaleName(GetUserDefaultLCID(), lpName, cchName, dwFlags);
    if (lcid == LOCALE_SYSTEM_DEFAULT)
        return InternalLCIDToLocaleName(GetSystemDefaultLCID(), lpName, cchName, dwFlags);
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

    bool isNeutral = (lcid & 0x03ff) == lcid;

    if (isNeutral && (dwFlags & LOCALE_ALLOW_NEUTRAL_NAMES) == 0)
    {
        SetLastError(87);
        return 0;
    }

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
        script = "yrl";
    else if (lcid == 0x0000782 || lcid == 0x0000042 || lcid == 0x0000681A || lcid == 0x0000141A || 
             lcid == 0x0000767 || lcid == 0x00000867 || lcid == 0x0000768 || lcid == 0x00000468 ||
             lcid == 0x000075D || lcid == 0x0000085D || lcid == 0x00001000 || lcid == 0x0000701A ||
             lcid == 0x0000181A || lcid == 0x0000081A || lcid == 0x000021A || lcid == 0x0000241A ||
             lcid == 0x000075F || lcid == 0x0000085F || lcid == 0x0000743 || lcid == 0x00000443)
        script = "Latn";
    else if (lcid == 0x0000785D || lcid == 0x0000045D)
        script = "ans";
    else if (lcid == 0x0000792 || lcid == 0x00000492 || lcid == 0x0000746 || lcid == 0x00000846 ||
             lcid == 0x0000759 || lcid == 0x00000859)
        script = "Arab";
    else if (lcid == 0x0000750 || lcid == 0x00000850 || lcid == 0x0000050)
        script = "Mong";
    else if (lcid == 0x0000785F || lcid == 0x0000105F)
        script = "Tfng";
    else if (lcid == 0x0000045)
        script = "her";

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

int InternalLocaleNameToLCID(in wchar* lpName, in uint dwFlags)
{
    static wchar[] buf = new wchar[85];
    static wchar* lpn;
    static uint result = 0;
    extern(Windows) static int enumLocalesProc(in wchar* lpLID)
    {
        wstring r;
        uint lcid = 0;
        wchar* lp = cast(wchar*)lpLID;
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


        int ret = InternalLCIDToLocaleName(lcid, buf.ptr, 85, LOCALE_ALLOW_NEUTRAL_NAMES);
        if (ret > 0 && lstrcmpiW(buf.ptr, lpn) == 0)
        {
            result = lcid;
            return 0;
        }
        ret = InternalLCIDToLocaleName(lcid & 0x3ff, buf.ptr, 85, LOCALE_ALLOW_NEUTRAL_NAMES);
        if (ret > 0 && lstrcmpiW(buf.ptr, lpn) == 0)
        {
            result = lcid & 0x3ff;
            return 0;
        }

        return 1;
    }

    if (lpName is null)
        return GetUserDefaultLCID();

    if (lstrcmpiW(lpName, "!x-sys-default-locale") == 0)
        return GetSystemDefaultLCID();

    int len = lstrlenW(lpName);
    if (len == 0)
        return LOCALE_INVARIANT;
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
        if (lstrcmpiW(lpName, "bs-yrl") == 0)
            return 0x641a;
        if (lstrcmpiW(lpName, "bs-Latn") == 0)
            return 0x681a;
        if (lstrcmpiW(lpName, "ff-Latn") == 0)
            return 0x7c67;
        if (lstrcmpiW(lpName, "ha-Latn") == 0)
            return 0x7c68;
        if (lstrcmpiW(lpName, "iu-ans") == 0)
            return 0x785d;
        if (lstrcmpiW(lpName, "iu-Latn") == 0)
            return 0x7c5d;
        if (lstrcmpiW(lpName, "ku-Arab") == 0)
            return 0x7c92;
        if (lstrcmpiW(lpName, "mn-yrl") == 0)
            return 0x7850;
        if (lstrcmpiW(lpName, "mn-Mong") == 0)
            return 0x7c50;
        if (lstrcmpiW(lpName, "pa-Arab") == 0)
            return 0x7c46;
        if (lstrcmpiW(lpName, "sd-Arab") == 0)
            return 0x7c59;
        if (lstrcmpiW(lpName, "sr-yrl") == 0)
            return 0x6c1a;
        if (lstrcmpiW(lpName, "sr-Latn") == 0)
            return 0x701a;
        if (lstrcmpiW(lpName, "tg-yrl") == 0)
            return 0x7c28;
        if (lstrcmpiW(lpName, "uz-yrl") == 0)
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
        if (lstrcmpiW(lpName, "chr-her") == 0)
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

nothrow
int InternalEnumSystemLocalesEx(in LOCALE_ENUMPROCEX proc, in uint dwFlags, in size_t lParam, in void* lpReserved)
{
    static wchar[] buf = new wchar[82];
    static size_t param;
    static LOCALE_ENUMPROCEX prc;
    static string[int] map;

    extern(Windows) static int enumLocalesProc(in wchar* lpLID)
    {
        uint lcid = 0;
        wchar* lp = cast(wchar*)lpLID;
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

        uint nlcid = lcid & 0x3ff;

        if (!(nlcid in map) && nlcid != LOCALE_INVARIANT)
        {
            map[nlcid] = null;
            int ret = InternalLCIDToLocaleName(nlcid, buf.ptr, 85, LOCALE_ALLOW_NEUTRAL_NAMES);
            if (ret > 0)
            {
                if (prc(buf.ptr, LOCALE_NEUTRALDATA, 0) == 0)
                    return 0;
            }
        }

        int ret = InternalLCIDToLocaleName(lcid, buf.ptr, 85, LOCALE_ALLOW_NEUTRAL_NAMES);
        if (ret > 0)
        {
            if (prc(buf.ptr, (lcid & 0x3ff) != 0 ? LOCALE_NEUTRALDATA : 0, 0) == 0)
                return 0;
        }


        return 1;
    }

    if (proc is null)
    {
        SetLastError(82);
        return 0;
    }
    prc = proc;

    param = lParam;
    uint flags =  LCID_SUPPORTED;
    if (dwFlags == 0 || ((dwFlags & LOCALE_ALTERNATE_SORTS) != 0))
        flags |= LCID_ALTERNATE_SORTS;
    map = null;
    EnumSystemLocalesW(&enumLocalesProc, flags);
    return 1;
}


final class CalendarData
{   
    LocaleData _localeData;
    uint calID;

    static CalendarData[uint] calendarMap;



    static wstring getDefaultLocaleForCalendar(uint calID)
    {
        switch(calID)
        {
            case CAL_GREGORIAN:
                return "en-US";
            case CAL_GREGORIAN_US:
                return "fa-IR";
            case CAL_GREGORIAN_ARABIC:
            case CAL_HIJRI:
            case CAL_UMALQURA:
                return "ar-SA";
            case CAL_GREGORIAN_ME_FRENCH:
                return "ar-DZ";
            case CAL_GREGORIAN_XLIT_FRENCH:
            case CAL_GREGORIAN_XLIT_ENGLISH:
                return "ar-IQ";
            case CAL_HEBREW:
                return "he-IL";
            case CAL_JAPAN:
                return "ja-JP";
            case CAL_KOREA:
                return "ko-KR";
            case CAL_TAIWAN:
                return "zh-TW";
            case CAL_THAI:
                return "th-TH";
            default:
                return "en-US";
        }
    }

    static uint getDefaultLCIDForCalendar(uint calID)
    {
        switch(calID)
        {
            case CAL_GREGORIAN:
                return 0x00000409;
            case CAL_GREGORIAN_US:
                return 0x00000429;
            case CAL_GREGORIAN_ARABIC:
            case CAL_HIJRI:
            case CAL_UMALQURA:
                return 0x00000401;
            case CAL_GREGORIAN_ME_FRENCH:
                return 0x00001401;
            case CAL_GREGORIAN_XLIT_FRENCH:
            case CAL_GREGORIAN_XLIT_ENGLISH:
                return 0x00000801;
            case CAL_HEBREW:
                return 0x0000040D;
            case CAL_JAPAN:
                return 0x00000411;
            case CAL_KOREA:
                return 0x00000412;
            case CAL_TAIWAN:
                return 0x00000404;
            case CAL_THAI:
                return 0x0000041E;
            default:
                return 0x00000409;
        }
    }

    wstring getCalendarInfoStr(in int lc, bool fail = true)
    {
        int ret = _localeData.useLocaleName ? 
            GetCalendarInfoEx(_localeData.zlocaleName, calID, null, lc | (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0), null, 0, null):
            GetCalendarInfoW(_localeData.localeID, calID, lc | (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0), null, 0, null);
        if (ret == 0 && fail)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        if (ret == 0)
            return null;
        wchar[] result = new wchar[ret];
        ret = _localeData.useLocaleName ?
            GetCalendarInfoEx(_localeData.zlocaleName, calID, null, lc | (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0), result.ptr, ret, null):
            GetCalendarInfoW(_localeData.localeID, calID, lc | (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0), result.ptr, ret, null);
        if (ret == 0 && fail)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        if (ret == 0)
            return null;
        return cast(wstring)result[0..ret - 1];
    }

    int getCalendarInfoInt(in int lc)
    {
        uint result;
        int ret = _localeData.useLocaleName ?
            GetCalendarInfoEx(_localeData.zlocaleName, calID, null, lc | CAL_RETURN_NUMBER | 
                             (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0), null, 0, &result) :
            GetCalendarInfoW(_localeData.localeID, calID, lc | CAL_RETURN_NUMBER | 
                             (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0), null, 0, &result);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return result;
    }

    wstring[] getCalendarInfoArray(in int lc)
    {
        static wstring[] sresult;

        extern(Windows) static int enumCalendarProcEx(in wchar* info, in uint calInfo, in wchar* reserved, in size_t lParam)
        {
            int len = lstrlenW(info);
            sresult ~= info[0..len].idup; 
            return 1;
        }

        extern(Windows) static int enumCalendarProc(in wchar* info, in uint calInfo)
        {
            int len = lstrlenW(info);
            sresult ~= info[0..len].idup; 
            return 1;
        }

        sresult = null;

        if (isWindowsVistaOrGreater())
            EnumCalendarInfoExEx(&enumCalendarProcEx, _localeData.zlocaleName, calID, null, lc | (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0) , 0);           
        else
            EnumCalendarInfoExW(&enumCalendarProc, _localeData.localeID, calID, lc | (!_localeData.useUserOverride ? CAL_NOUSEROVERRIDE : 0));

        return sresult;
    }

    uint _calID;


public:

    this(LocaleData localeData, uint calID)
    {
        if (localeData is null)
        {
            if (isWindowsVistaOrGreater())
                _localeData = new LocaleData(getDefaultLocaleForCalendar(calID), false);
            else
                _localeData = new LocaleData(getDefaultLCIDForCalendar(calID), false);
        }
        else
            _localeData = localeData;
        _calID = calID;
    }

    static CalendarData getCultureAgnosticData(uint calID)
    {
        auto p = calID in calendarMap;
        if (p)
            return *p;
        auto data = new CalendarData(null, calID);
        calendarMap[calID] = data;
        return data;
    }

    @property int iTwoDigitYearMax()
    {
        return getCalendarInfoInt(CAL_ITWODIGITYEARMAX);
    }


    wstring getDayName(int day, bool abbreviated)
    {
        wstring result = getCalendarInfoStr(abbreviated ? CAL_SABBREVDAYNAME1 + day : CAL_SDAYNAME1 + day, false);
        if (String.IsNullOrEmpty(result))
            result = _localeData.getLocaleInfoStr(abbreviated ? LOCALE_SABBREVDAYNAME1 + day : LOCALE_SDAYNAME1 + day, true);
        return result;
    }

    wstring getShortestDayName(int day)
    {
        if (!isWindowsVistaOrGreater())
            return getDayName(day, true);
        wstring result = getCalendarInfoStr(CAL_SSHORTESTDAYNAME1 + day, false);
        if (String.IsNullOrEmpty(result))
            result = _localeData.getLocaleInfoStr(LOCALE_SSHORTESTDAYNAME1 + day, true);
        return result;
    }

    wstring getMonthName(int month, bool abbreviated)
    {
        wstring result = getCalendarInfoStr(abbreviated ? CAL_SABBREVMONTHNAME1 + month : CAL_SMONTHNAME1 + month, false);
        if (String.IsNullOrEmpty(result))
            result = _localeData.getLocaleInfoStr(abbreviated ? LOCALE_SABBREVMONTHNAME1 + month : LOCALE_SMONTHNAME1 + month, true);
        return result;
    }

    wstring getGenitiveMonthName(int month, bool abbreviated)
    {
        wstring result;
        if (isWindows7OrGreater())
        {
            result = getCalendarInfoStr(abbreviated ? 
                                       (CAL_SABBREVMONTHNAME1 + month) | CAL_RETURN_GENITIVE_NAMES : 
                                       (CAL_SMONTHNAME1 + month) | CAL_RETURN_GENITIVE_NAMES, false);
            if (String.IsNullOrEmpty(result))
                result = getCalendarInfoStr(abbreviated ? 
                                           (LOCALE_SABBREVMONTHNAME1 + month) | LOCALE_RETURN_GENITIVE_NAMES : 
                                           (LOCALE_SMONTHNAME1 + month) | LOCALE_RETURN_GENITIVE_NAMES, false);
        }

        if (String.IsNullOrEmpty(result))
        {
            SYSTEMTIME date;
            date.wDay = 1;
            date.wMonth = cast(ushort)month;
            date.wYear = 2015;
            wchar[] buf = new wchar[100];
            int ret;
            if (_localeData.useLocaleName)
                ret = GetDateFormatEx(_localeData.zlocaleName, 0, &date, abbreviated ? "ddMMM" : "ddMMMM", buf.ptr, 100, null);
            else
                ret = GetDateFormatW(_localeData.localeID, 0, &date, abbreviated ? "ddMMM" : "ddMMMM", buf.ptr, 100);
            if (ret > 0)
                result = cast(wstring)buf[2 .. ret - 1];
        }

        if (String.IsNullOrEmpty(result))
            result = getMonthName(month, abbreviated);

        return result;
    }

    wstring[] getEraNames(bool abbreviated)
    {
        wstring[] result = getCalendarInfoArray(abbreviated && isWindows7OrGreater() ? CAL_SABBREVERASTRING : CAL_SERASTRING);

        if (result.length > 0)
            return result;

        switch (calID)
        {
            case CAL_HEBREW:
                return ["C.E."w];
            case CAL_GREGORIAN_ME_FRENCH:
                return ["ap. J.-C."w];
            case CAL_GREGORIAN_ARABIC:
            case CAL_GREGORIAN_XLIT_ENGLISH:
            case CAL_GREGORIAN_XLIT_FRENCH:
                return ["\u0645"w];
            case CAL_KOREA:
                return ["\ub2e8\uae30"w];
            case CAL_THAI:
                return ["\u0e1e\u002e\u0e28\u002e"w];
            case CAL_TAIWAN:
                return abbreviated ? ["\u6c11\u570b"w] : ["\u4e2d\u83ef\u6c11\u570b"w];
            case CAL_HIJRI:
            case CAL_UMALQURA:
                return String.Equals(_localeData.localeName, "dv-MV", StringComparison.OrdinalIgnoreCase) || _localeData.localeID == 0x00000465 ?
                    (abbreviated ? ["\u0780\u002e"w] : ["\u0780\u07a8\u0796\u07b0\u0783\u07a9"w]) :
                    (abbreviated ? ["\u0647\u0640"w] : ["\u0628\u0639\u062F \u0627\u0644\u0647\u062c\u0631\u0629"w]);
            case CAL_JAPAN:
                return abbreviated ? ["\u5e73"w, "\u662d"w, "\u5927"w, "\u660e"w] :
                                     ["\u5e73\u6210"w, "\u662d\u548c"w, "\u5927\u6b63"w, "\u660e\u6cbb"w];
            default:
                return abbreviated ? ["AD"w] : ["A.D."w];
        }
    }

    wstring[] getShortDateFormats()
    {
        wstring[] result = getCalendarInfoArray(CAL_SSHORTDATE);
        if (result.length == 0)
            result = _localeData.getDateFormats(DATE_SHORTDATE, calID);
        if (result.length == 0)
            result = _localeData.getDateFormats(DATE_SHORTDATE, 0);
        if (result.length == 0)
        {
            wstring r = getCalendarInfoStr(CAL_SSHORTDATE);
            if (r.length > 0)
                result ~= r;
        }
        if (result.length == 0)
        {
            wstring r = _localeData.getLocaleInfoStr(LOCALE_SSHORTDATE, false);
            if (r.length > 0)
                result ~= r;
        }
        return result;
    }

    wstring[] getLongDateFormats()
    {
        wstring[] result = getCalendarInfoArray(CAL_SLONGDATE);
        if (result.length == 0)
            result = _localeData.getDateFormats(DATE_LONGDATE, calID);
        if (result.length == 0)
            result = _localeData.getDateFormats(DATE_LONGDATE, 0);
        if (result.length == 0)
        {
            wstring r = getCalendarInfoStr(CAL_SLONGDATE);
            if (r.length > 0)
                result ~= r;
        }
        if (result.length == 0)
        {
            wstring r = _localeData.getLocaleInfoStr(LOCALE_SLONGDATE, false);
            if (r.length > 0)
                result ~= r;
        }
        return result;
    }

    wstring[] getYearMonthFormats()
    {
        wstring[] result = getCalendarInfoArray(CAL_SYEARMONTH);
        if (result.length == 0)
            result = _localeData.getDateFormats(DATE_YEARMONTH, calID);
        if (result.length == 0)
            result = _localeData.getDateFormats(DATE_YEARMONTH, 0);
        if (result.length == 0)
        {
            wstring r = getCalendarInfoStr(CAL_SYEARMONTH);
            if (r.length > 0)
                result ~= r;
        }
        if (result.length == 0)
        {
            wstring r = _localeData.getLocaleInfoStr(LOCALE_SYEARMONTH, false);
            if (r.length > 0)
                result ~= r;
        }
        return result;
    }

    wstring getMonthDayFormat()
    {
        if (!isWindows7OrGreater())
            return "MMMM dd";

        wstring result = getCalendarInfoStr(CAL_SMONTHDAY, false);
        if (result.length == 0)
            result = _localeData.getLocaleInfoStr(LOCALE_SMONTHDAY, false);
        return result;
    }

    @property
    wstring sCalName()
    {
        return getCalendarInfoStr(CAL_SCALNAME);
    }
}
