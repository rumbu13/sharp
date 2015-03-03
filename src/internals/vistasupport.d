module internals.vistasupport;

import internals.kernel32;
import internals.interop;
import system.runtime.interopservices;
import system;

extern(Windows) __gshared:

uint VistaLocaleNameToLCID(in wchar* lpName, in uint dwFlags)
{

    auto lcid = LocaleNameToLCID(lpName, 0);

    if (dwFlags != LOCALE_ALLOW_NEUTRAL_NAMES || lcid == 0)
        return lcid;

    return lcid & 0x3ff;
}

int VistaLCIDToLocaleName(in uint Locale, wchar* lpName, in int cchName, in uint dwFlags)
{
    bool isNeutral = (Locale & 0x3ff) == Locale;
    auto ret = LCIDToLocaleName(Locale, lpName, cchName, 0);
    if (dwFlags != LOCALE_ALLOW_NEUTRAL_NAMES || ret == 0 || !isNeutral != 0)
        return ret;

    wchar* lpLang = cast(wchar*)LocalAlloc(0, 16);
    scope(exit) LocalFree(lpLang);
    auto lret = GetLocaleInfoEx(lpName, LOCALE_SISO639LANGNAME, lpLang, 16);
    if (lret > 0 && IsValidLocaleName(lpLang))
    {
        if (lret > cchName)
        {
            SetLastError(122);
            return 0;
        }
        lstrcpynW(lpName, lpLang, lret);
        return lret;
    }

    auto ptr = lpName;
    int len = 0;
    while (*ptr != '\0' && *ptr != '-')
    {
        ptr++;
        len++;
    }
    *ptr = '\0';

    if (IsValidLocaleName(lpName))
        return len + 1;
    else
    {
        if (len + 1 != ret)
            *ptr = '-';
        return ret;
    }

}

