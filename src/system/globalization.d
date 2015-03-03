module system.globalization;

import system;
import system.reflection;

import internals.locale;
import internals.resources;
import internals.utf;
import internals.interop;
import internals.checked;
import internals.traits;
import internals.datetime;

enum UnicodeCategory
{
    UppercaseLetter,
    LowercaseLetter,
    TitlecaseLetter,
    ModifierLetter,
    OtherLetter,
    NonspacingMark,
    SpacingombiningMark,
    EnclosingMark,
    DecimalDigitNumber,
    LetterNumber,
    OtherNumber,
    SpaceSeparator,
    LineSeparator,
    ParagraphSeparator,
    Control,
    Format,
    Surrogate,
    PrivateUse,
    ConnectorPunctuation,
    DashPunctuation,
    OpenPunctuation,
    ClosePunctuation,
    InitialQuotePunctuation,
    FinalQuotePunctuation,
    OtherPunctuation,
    MathSymbol,
    CurrencySymbol,
    ModifierSymbol,
    OtherSymbol,
    OtherNotAssigned,
}

// =====================================================================================================================
// CharUnicodeInfo
// =====================================================================================================================

struct CharUnicodeInfo
{
    @disable this();
private:

    pure nothrow @nogc
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

    pure nothrow @nogc
    static void skip7bitInt(ref ubyte* bytes)
    {
        int shift = 0;
        ubyte b;
        do {
            assert(shift != 32);
            b = *bytes++;
            shift += 7;
        } while ((b & 0x80) != 0);
    }

    pure nothrow @nogc
    static int readInt(ref ubyte* ptr)
    {
        int r = *(cast(int*)ptr);
        ptr += 4;
        return r;
    }

    pure nothrow @nogc
    static double readDouble(ref ubyte* ptr)
    {
        double r = *(cast(double*)ptr);
        ptr += 8;
        return r;
    }


    static immutable (ubyte[]) data = cast(immutable (ubyte[]))(import("unicodedata.bin"));
    static immutable (ubyte*) dataPtr;
    static immutable (ubyte*) rangesPtr;
    static immutable (ubyte*) codesPtr;
    static immutable (ubyte*) valuesPtr;
    static immutable (ubyte*) decimalsPtr;
    static immutable (ubyte*) lowercasePtr;
    static immutable (ubyte*) uppercasePtr;
    static immutable (ubyte*) titlecasePtr;

    static immutable int rangesCount;
    static immutable int codesCount;
    static immutable int valuesCount;
    static immutable int decimalsCount;
    static immutable int lowercaseCount;
    static immutable int uppercaseCount;
    static immutable int titlecaseCount;

    pure nothrow @nogc
    static this()
    {
        dataPtr = data.ptr;
        ubyte* ptr = cast(ubyte*)(dataPtr + 256);

        rangesCount = readInt(ptr);
        rangesPtr = cast(immutable)ptr;
        int i = rangesCount;
        while (i-- > 0 )
        {
            skip7bitInt(ptr);
            skip7bitInt(ptr);
            ptr++;
        }

        codesCount = readInt(ptr);
        codesPtr = cast(immutable)ptr;
        i = codesCount;
        while (i-- > 0 )
        {
            skip7bitInt(ptr);
            ptr++;
        }

        valuesCount = readInt(ptr);
        valuesPtr = cast(immutable)ptr;
        i = valuesCount;
        while (i-- > 0 )
        {
            skip7bitInt(ptr);
            ptr += 8;
        }

        decimalsCount = readInt(ptr);
        decimalsPtr = cast(immutable)ptr;
        i = decimalsCount;
        while (i-- > 0 )
        {
            skip7bitInt(ptr);
            ptr += 2;
        }

        lowercaseCount = readInt(ptr);
        lowercasePtr = cast(immutable)ptr;
        i = lowercaseCount;
        while (i-- > 0 )
        {
            skip7bitInt(ptr);
            skip7bitInt(ptr);
        }

        uppercaseCount = readInt(ptr);
        uppercasePtr = cast(immutable)ptr;
        i = uppercaseCount;
        while (i-- > 0 )
        {
            skip7bitInt(ptr);
            skip7bitInt(ptr);
        }

        titlecaseCount = readInt(ptr);
        titlecasePtr = cast(immutable)ptr;
    }

    pure nothrow @nogc
    static ubyte getCategory(uint codePoint)
    {
        if (codePoint < 256)
            return *(dataPtr + codePoint);
        ubyte* ptr = cast(ubyte*)rangesPtr;
        int i = 0;
        while (i++ < rangesCount)
        {
            uint rangeStart = cast(uint)read7bitInt(ptr);
            if (codePoint >= rangeStart)
            {
                uint rangeEnd = cast(uint)read7bitInt(ptr);
                if (codePoint <= rangeEnd)
                    return *ptr;
                ptr++;
            }
            else
                break;
        }

        ptr = cast(ubyte*)codesPtr;
        i = 0;
        while (i++ < codesCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
                ptr++; //skip category
            else if (code == codePoint)
                return *ptr;
            else
                break;
        }

        return UnicodeCategory.OtherNotAssigned;
    }

    pure nothrow @nogc
    static double getValue(uint codePoint)
    {
        if (codePoint >= '0' && codePoint <= '9')
            return codePoint - '0';
        auto ptr = cast(ubyte*)valuesPtr;
        int i = 0;
        while (i++ < valuesCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
                ptr += 8;
            else if (code == codePoint)
                return readDouble(ptr);
            else
                break;
        }
        return -1;
    }

    pure nothrow @nogc
    static int getDecimalDigit(uint codePoint)
    {
        if (codePoint >= '0' && codePoint <= '9')
            return codePoint - '0';
        auto ptr = cast(ubyte*)decimalsPtr;
        int i = 0;
        while (i++ < decimalsCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
                ptr += 2;  //skip 2 byte values
            else if (code == codePoint)
                return *ptr;
            else
                break;
        }
        return -1;
    }

    pure nothrow @nogc
    static int getDigit(uint codePoint)
    {
        if (codePoint >= '0' && codePoint <= '9')
            return codePoint - '0';
        auto ptr = cast(ubyte*)decimalsPtr;
        int i = 0;
        while (i++ < decimalsCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
                ptr += 2; //skip 2 byte values
            else if (code == codePoint)
                return *(++ptr);
            else
                break;
        }
        return -1;
    }

    pure nothrow @nogc
    static uint getLowercase(uint codePoint)
    {
        if (codePoint >= 'a' && codePoint <= 'z')
            return codePoint;
        if (codePoint >= 'A' && codePoint <= 'Z')
            return codePoint + 'a' - 'A';
        auto ptr = cast(ubyte*)lowercasePtr;
        int i = 0;
        while (i++ < lowercaseCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
                skip7bitInt(ptr);  //skip lowercase
            else if (code == codePoint)
                return read7bitInt(ptr);
            else
                break;
        }
        return codePoint;
    }

    pure nothrow @nogc
    static uint getUppercase(uint codePoint)
    {
        if (codePoint >= 'A' && codePoint <= 'Z')
            return codePoint;
        if (codePoint >= 'a' && codePoint <= 'z')
            return codePoint - ('a' - 'A');
        auto ptr = cast(ubyte*)uppercasePtr;
        int i = 0;
        while (i++ < uppercaseCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint) 
                skip7bitInt(ptr); //skip uppercase
            else if (code == codePoint)
                return read7bitInt(ptr);
            else
                break;
        }

        ptr = cast(ubyte*)titlecasePtr;

        i = 0;
        while (i++ < titlecaseCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
            {
                skip7bitInt(ptr); //skip uppercase
                skip7bitInt(ptr); //skip titlecase
            }
            else if (code == codePoint)
                return read7bitInt(ptr);
            else
                break;
        }
        return codePoint;
    }

    pure nothrow @nogc
    static uint getTitlecase(uint codePoint)
    {
        if (codePoint >= 'A' && codePoint <= 'Z')
            return codePoint;
        if (codePoint >= 'a' && codePoint <= 'z')
            return codePoint - ('a' - 'A');


        auto ptr = cast(ubyte*)uppercasePtr;
        int i = 0;
        while (i++ < uppercaseCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
                skip7bitInt(ptr);  //skip uppercase
            else if (code == codePoint)
                return read7bitInt(ptr);
            else
                break;
        }

        ptr = cast(ubyte*)titlecasePtr;

        i = 0;
        while (i++ < titlecaseCount)
        {
            uint code = cast(uint)read7bitInt(ptr);
            if (code < codePoint)
            {
                skip7bitInt(ptr); //skip uppercase
                skip7bitInt(ptr); //skip titlecase
            }
            else if (code == codePoint)
            {
                skip7bitInt(ptr);  //skip uppercase
                return read7bitInt(ptr);
            }
            else
                break;
        }
        return codePoint;
    }

package:
    pure nothrow @nogc
    static wchar getLowercaseChar(wchar c)
    {
        auto cp = getLowercase(c);
        return cp <= 0xffff ? cast(wchar)cp : c;
    }

    pure nothrow @nogc
    static wchar getUppercaseChar(wchar c)
    {
        auto cp = getUppercase(c);
        return cp <= 0xffff ? cast(wchar)cp : c;
    }

    pure nothrow @nogc
    static wchar getTitlecaseChar(wchar c)
    {
        auto cp = getTitlecase(c);
        return cp <= 0xffff ? cast(wchar)cp : c;
    }

public:
    
    pure nothrow @nogc
    static int GetDecimalDigitValue(wchar c)
    {
        return getDecimalDigit(c);
    }

    static int GetDecimalDigitValue(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index);
        return getDecimalDigit(Char.ConvertToUTF32(s, index));
    }

    pure nothrow @nogc
    static int GetDigitValue(wchar c)
    {
        return getDigit(c);
    }

    static int GetDigitValue(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index);
        return getDigit(Char.ConvertToUTF32(s, index));
    }

    pure nothrow @nogc
    static double GetNumericValue(wchar c)
    {
        return getValue(c);
    }

    static double GetNumericValue(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index);
        return getValue(Char.ConvertToUTF32(s, index));
    }

    pure nothrow @nogc
    static UnicodeCategory GetUnicodeCategory(wchar c)
    {
        return cast(UnicodeCategory)getCategory(c);
    }

    static UnicodeCategory GetUnicodeCategory(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index);
        return cast(UnicodeCategory)getCategory(Char.ConvertToUTF32(s, index));
    }
}

// =====================================================================================================================
// CultureNotFoundException
// =====================================================================================================================

class CultureNotFoundException: ArgumentException
{
private:
    uint invalidCultureId;
    wstring invalidCultureName;

public:
    this()
    {
        super(SharpResources.GetString("ExceptionCultureNotFound"));
    }

    this(wstring msg)
    {
        super(msg);
    }

    this(wstring paramName, wstring msg)
    {
        super(msg, paramName);
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
    }

    this(wstring paramName, wstring msg, uint invalidCultureId)
    {
        super(msg, paramName);
        this.invalidCultureId = invalidCultureId;
    }

    this(wstring msg, uint invalidCultureId, Throwable next)
    {
        super(msg, next);
        this.invalidCultureId = invalidCultureId;
    }

    this(wstring paramName, wstring msg, wstring invalidCultureName)
    {
        super(msg, paramName);
        this.invalidCultureName = invalidCultureName;
    }

    this(wstring msg, wstring invalidCultureName, Throwable next)
    {
        super(msg, next);
        this.invalidCultureName = invalidCultureName;
    }

    @property pure @safe nothrow
    uint InvalidCultureId()
    {
        return invalidCultureId;
    }

    @property pure @safe nothrow
    wstring InvalidCultureName()
    {
        return invalidCultureName;
    }

    @property
    override wstring Message() 
    {
        wstring s = super.Message;
        wstring i = String.IsNullOrEmpty(invalidCultureName) ? String.Format("{0:X4}", invalidCultureId): invalidCultureName;
        wstring m = SharpResources.GetString("ArgumentInvalidCulture", i);
        return String.IsNullOrEmpty(m) ? s : s ~ Environment.NewLine ~ m;
    }
}

// =====================================================================================================================
// CultureInfo
// =====================================================================================================================

class CultureInfo : ICloneable, IFormatProvider
{
private:
    static CultureInfo[wstring] nameMap;
    static CultureInfo[int] lcidMap;

    bool _isReadOnly;
    bool _isInherited;
    wstring _reqName;
    LocaleData data;
    NumberFormatInfo _numberFormat;
    DateTimeFormatInfo _dateTimeFormat;
    .TextInfo _textInfo;
    .CompareInfo _compareInfo;
    Calendar _calendar;
    static CultureInfo _invariantCulture;
    static CultureInfo _currentCulture;
    static CultureInfo _currentUICulture;

    this()
    {
        _isReadOnly = true;
        _isInherited = typeid(this) == typeid(CultureInfo);
    }

public:
    this(wstring name, bool useUserOverride)
    {
        if (String.IsNullOrEmpty(name))
            data = new LocaleData(cast(wstring)null, useUserOverride);
        else
            data = new LocaleData(name, useUserOverride);
        _isInherited = typeid(this) == typeid(CultureInfo);
        _reqName = name;
    }

    this(uint culture, bool useUserOverride)
    {
        data = new LocaleData(culture, useUserOverride);
        _isInherited = typeid(this) == typeid(CultureInfo);
    }

    this(wstring name)
    {
        this(name, true);
    }

    this(uint culture)
    {
        this(culture, true);
    }

    Object Clone()
    {
        CultureInfo ci = cast(CultureInfo)this.MemberwiseClone();
        ci._isReadOnly = false;
        return ci;
    }

    Object GetFormat(TypeInfo type)
    {
        if (type == typeid(NumberFormatInfo))
            return NumberFormat;
        if (type == typeid(DateTimeFormatInfo))
            return DateTimeFormat;
        return null;
    }

    void ClearCachedData()
    {
        _currentCulture = null;
        _currentUICulture = null;
        _numberFormat = null;
        _dateTimeFormat = null;
        _textInfo = null;
        _compareInfo = null;
    }

    @property NumberFormatInfo NumberFormat()
    {
        if (_numberFormat is null)
            _numberFormat = new NumberFormatInfo(data, _isReadOnly);
        return _numberFormat;
    }

    @property 
    DateTimeFormatInfo DateTimeFormat()
    {
        if (_dateTimeFormat is null)
            _dateTimeFormat = new DateTimeFormatInfo(data, _calendar, _isReadOnly);
        return _dateTimeFormat;
    }

    @property 
    .TextInfo TextInfo()
    {
        if (_textInfo is null)
            _textInfo = new .TextInfo(data, _isReadOnly);
        return _textInfo;
    }

    @property 
    .CompareInfo CompareInfo()
    {
        if (_compareInfo is null)
            _compareInfo = new .CompareInfo(data);
        return _compareInfo;
    }

    @property 
    wstring Name()
    {
        return data.sName;
    }

    @property 
    static CultureInfo InvariantCulture()
    {
        if (_invariantCulture is null)
        {
            _invariantCulture = new CultureInfo();
            _invariantCulture.data = LocaleData.invariant_;
        }

        return _invariantCulture;
    }

    @property 
    static CultureInfo CurrentCulture()
    {
        if (_currentCulture is null)
        {
            _currentCulture = new CultureInfo();
            _currentCulture.data = LocaleData.current;
        }
        return _currentCulture;
    }

    @property 
    static CultureInfo CurrentUICulture()
    {
        if (_currentUICulture is null)
        {
            _currentUICulture = new CultureInfo();
            _currentUICulture.data = LocaleData.uiCurrent;
        }
        return _currentUICulture;
    }

    static CultureInfo GetCultureInfo(wstring name)
    {
        wstring loName = InvariantCulture.TextInfo.ToLower(name);
        auto pci = loName in nameMap;
        if (pci)
            return *pci;
        auto ci = new CultureInfo(name, false);
        nameMap[InvariantCulture.TextInfo.ToLower(ci.Name)] = ci;
        lcidMap[ci.LCID] = ci;
        return ci;
    }

    static CultureInfo GetCultureInfo(wstring name, wstring altName)
    {
        try
        {
            return GetCultureInfo(name);
        }
        catch (CultureNotFoundException)
        {
            return GetCultureInfo(altName);
        }
    }

    static CultureInfo GetCultureInfo(uint culture)
    {
        auto pci = culture in lcidMap;
        if (pci)
            return *pci;
        auto ci = new CultureInfo(culture, false);
        nameMap[InvariantCulture.TextInfo.ToLower(ci.CompareInfo.Name)] = ci;
        lcidMap[ci.LCID] = ci;
        return ci;
    }

    @property 
    uint LCID()
    {
        return data.lcid;
    }
}


// =====================================================================================================================
// TextInfo
// =====================================================================================================================

class TextInfo: SharpObject, ICloneable
{
private:
    bool _isReadOnly;
    LocaleData _data;
    int _ansiCodePage = -1;
    int _ebcdicCodePage = -1;
    int _macCodePage = -1;
    int _oemCodePage = -1;
    wstring _cultureName;
    int _iReadingLayout = -1;
    wstring _listSeparator;

    this(LocaleData data, bool readOnly)
    {
        _isReadOnly = readOnly;
        _data = data;
         _cultureName = _data.sName;
    }

    pure @safe nothrow @nogc
    static bool isLetter(UnicodeCategory c)
    {
        return   c == UnicodeCategory.UppercaseLetter ||
                 c == UnicodeCategory.LowercaseLetter ||
                 c == UnicodeCategory.TitlecaseLetter ||
                 c == UnicodeCategory.ModifierLetter ||
                 c == UnicodeCategory.OtherLetter;
    }

    pure @safe nothrow @nogc
    static bool isSeparator(UnicodeCategory c)
    {
        return  (c >= UnicodeCategory.SpaceSeparator && c <= UnicodeCategory.Format) ||
                (c >= UnicodeCategory.ConnectorPunctuation && c <= UnicodeCategory.OtherSymbol);
    }

    wstring internalTitleCase(wstring s)
    {
        wstring ret;
        int len = safe32bit(s.length);
        int i = 0;
        while (i < len)
        {
            auto j = i;
            UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, i);
            while (i < len && !isLetter(c))
            {
                i += Char.IsSurrogatePair(s, i) ? 2 : 1;
                c = CharUnicodeInfo.GetUnicodeCategory(s, i);
            }
            ret ~= s[j .. i];

            if (i < len)
            {
                if (c != UnicodeCategory.TitlecaseLetter)
                    ret ~= Char.ConvertFromUTF32(CharUnicodeInfo.getTitlecase(Char.ConvertToUTF32(s, i)));
                i += Char.IsSurrogatePair(s, i) ? 2 : 1;
                if (i < len)
                {
                    c = CharUnicodeInfo.GetUnicodeCategory(s, i);
                    j = i;
                    bool hasLower = (c == UnicodeCategory.LowercaseLetter);
                    while (i < len && (!isSeparator(c) || s[i] == '\''))
                    {
                        if (c == UnicodeCategory.LowercaseLetter)
                            hasLower = true;
                        i += Char.IsSurrogatePair(s, i) ? 2 : 1;
                        if (i < len)
                            c = CharUnicodeInfo.GetUnicodeCategory(s, i);
                    }
                    if (hasLower)
                        ret ~= ToLower(s[j .. i]);
                    else
                        ret ~= s[j .. i];
                }
            }
        }

        return ret;
    }

public:
    Object Clone()
    {
        TextInfo obj = cast(TextInfo)MemberwiseClone();
        obj._isReadOnly = false;
        return obj;
    }

    wstring ToLower(wstring s)
    {
        if (s is null)
            return null;
        if (s.length == 0)
            return [];
        return _data.toLowercase(s);
    }

    wstring ToUpper(wstring s)
    {
        if (s is null)
            return null;
        if (s.length == 0)
            return [];
        return _data.toUppercase(s);
    }

    wstring ToTitleCase(wstring s)
    {
        if (s is null)
            return null;
        if (s.length == 0)
            return [];
        if (!isWindows7OrGreater())
            return internalTitleCase(s);
        return _data.toTitlecase(s);
    }

    wchar ToLower(wchar ch)
    {
        auto low = ToLower([ch]);
        return low.length > 0 ? low[0] : ch;
    }

    wchar ToUpper(wchar ch)
    {
        auto up = ToUpper([ch]);
        return up.length > 0 ? up[0] : ch;
    }

    @property 
    int AnsiCodePage()    
    {
        if (_ansiCodePage < 0)
            _ansiCodePage = _data.iDefaultAnsiCodePage;
        return _ansiCodePage;
    }

    @property 
    int OemCodePage()    
    {
        if (_oemCodePage < 0)
            _oemCodePage = _data.iDefaultOEMCodePage;
        return _oemCodePage;
    }

    @property 
    int EbcdicCodePage()    
    {
        if (_ebcdicCodePage < 0)
            _ebcdicCodePage = _data.iDefaultEBCDICCodePage;
        return _ebcdicCodePage;
    }

    @property 
    int MacCodePage()     
    {
        if (_macCodePage < 0)
            _macCodePage = _data.iDefaultMACCodePage;
        return _macCodePage;
    }

    @property 
    bool IsRightToLeft()    
    {
        if (_iReadingLayout < 0)
            _iReadingLayout = _data.iReadingLayout;
        return _iReadingLayout == 1;
    }

    @property pure @safe nothrow @nogc
    final bool IsReadOnly()    
    {
        return _isReadOnly;
    }

    @property pure @safe nothrow @nogc
    final int LCID()    
    {
        return _data.lcid;
    }

    @property nothrow
    final wstring CultureName()  
    {           
        return _cultureName;
    }

    @property 
    wstring ListSeparator()    
    {
        if (_listSeparator is null)
            _listSeparator = _data.sList;
        return _listSeparator;
    }

    @property 
    wstring ListSeparator(wstring value)  
    {
        checkNull(value);
        if (_isReadOnly)
            throw new InvalidOperationException(SharpResources.GetString("InvalidOperationReadOnly"));
        return _listSeparator = value;
    }

    override wstring ToString()
    {
        return "TextInfo - " ~ _cultureName;
    }  

    override bool opEquals(Object other)
    {
        if (auto ti = cast(TextInfo)other)
            return ti.CultureName == this.CultureName;
        return false;
    }

    @trusted nothrow
    override int GetHashCode()
    {
        return CultureName.GetHashCode();
    }

    static TextInfo ReadOnly(TextInfo textInfo)
    {
        checkNull(textInfo);
        if (textInfo.IsReadOnly)
            return textInfo;
        auto ti = cast(TextInfo)textInfo.Clone();
        ti._isReadOnly = true;
        return ti;
    }
}

@(Serializable(), Flags())
enum CompareOptions
{
    None                = 0x00000000,
    IgnoreCase          = 0x00000001,
    IgnoreNonSpace      = 0x00000002,
    IgnoreSymbols       = 0x00000004,
    IgnoreKanaType      = 0x00000008,
    IgnoreWidth         = 0x00000010,
    OrdinalIgnoreCase   = 0x10000000,
    StringSort          = 0x20000000,
    Ordinal             = 0x40000000,
}

// =====================================================================================================================
// NumberFormatInfo
// =====================================================================================================================

enum DigitShapes
{
    Context,
    None,
    NativeNational,
}

@Serializable()
final class NumberFormatInfo: SharpObject, ICloneable, IFormatProvider
{
private:
    LocaleData _data;
    int _currencyDecimalDigits = -1;
    wstring _currencyDecimalSeparator;
    wstring _currencyGroupSeparator;
    int[] _currencyGroupSizes;
    int _currencyNegativePattern = -1;
    int _currencyPositivePattern = -1;
    wstring _currencySymbol;

    int _numberDecimalDigits = -1;
    wstring _numberDecimalSeparator;
    wstring _numberGroupSeparator;
    int[] _numberGroupSizes;
    int _numberNegativePattern = -1;

    int _percentDecimalDigits = -1;
    wstring _percentDecimalSeparator;
    wstring _percentGroupSeparator;
    int[] _percentGroupSizes;
    int _percentNegativePattern = -1;
    int _percentPositivePattern = -1;
    wstring _percentSymbol;
    wstring _permilleSymbol;

    DigitShapes _digitSubstitution = cast(DigitShapes)-1;
    wstring[] _nativeDigits;

    wstring _nanSymbol;
    wstring _negativeSign;
    wstring _positiveSign;
    wstring _negativeInfinitySymbol;
    wstring _positiveInfinitySymbol;


    bool _isReadOnly;

    pure @safe nothrow
    int[] getGroupSizes(wstring grouping)
    {
        int[] ret;
        if (grouping.length == 0)
        {
            ret = new int[1];
            ret[0] = 3;
        }
        else if (grouping[0] == '0')
        {
            ret = new int[1];
            ret[0] = 0;
        }
        else
        {
            ret = new int[grouping.length * 2 + 2];
            ret[$ - 1] = 0;
            for (int i = 0; i < grouping.length; i += 2)
            {
                if (grouping[i] < '1' || grouping[i] > '9')
                {
                    ret = new int[1];
                    ret[0] = 3;
                    break;
                }
                ret[i / 2] = grouping[i] - '0';
            }
        }
        return ret;
    }

    pure @safe nothrow
    wstring[] getNativeDigits(wstring native)
    {
        wstring[] ret = new wstring[10];
        if (native.length == 10)
        {
            for (int i = 0; i < 10; i++)
                ret[i] = native[i..i + 1];
        }
        else
        {
            for(int i = 0; i <= 10; i++)
                ret[i] = [cast(wchar)('0' + i)];
        }
        return ret;
    }

    this(LocaleData data, bool readOnly)
    {
        _isReadOnly = readOnly;
        _data = data;      
    }

    static NumberFormatInfo _invariantInfo;

    void checkWriteable()
    {
        if (_isReadOnly)
            throw new InvalidOperationException();
    }

    static void checkDecimalSeparator(wstring sep, wstring prop)
    {
        if (sep is null)
            throw new ArgumentNullException(prop);
        if (sep.length == 0)
            throw new ArgumentException(SharpResources.GetString("ArgumentDecimalSeparator"), prop);
    }

    static void checkGroupSeparator(wstring sep, wstring prop)
    {
        if (sep is null)
            throw new ArgumentNullException(prop);
    }

    static void checkGroupSizes(int[] sizes, wstring prop)
    {
        for (auto i = 0; i < sizes.length; i++)
        {
            if (sizes[i] < 1 && i != sizes.length - 1)
                throw new ArgumentException(SharpResources.GetString("ArgumentGroupSize"), prop);
            if (sizes[i] > 9)
                throw new ArgumentException(SharpResources.GetString("ArgumentGroupSize"), prop);
        }
    }

    static void checkNegativePattern(int pattern, wstring prop)
    {
        if (pattern < 0 || pattern > 15)
            throw new ArgumentOutOfRangeException(prop, SharpResources.GetString("ArgumentOutOfRange", 0, 15));
    }

    static void checkPositivePattern(int pattern, wstring prop)
    {
        if (pattern < 0 || pattern > 3)
            throw new ArgumentOutOfRangeException(prop, SharpResources.GetString("ArgumentOutOfRange", 0, 3));
    }

    static void checkDecimalDigits(int digits, wstring prop)
    {
        if (digits < 0 || digits > 99)
            throw new ArgumentOutOfRangeException(prop, SharpResources.GetString("ArgumentOutOfRange", 0, 99));
    }


public:

    this()
    {
        this(LocaleData.invariant_, false);
    }

    Object Clone() 
    {
        NumberFormatInfo n = cast(NumberFormatInfo)MemberwiseClone();
        n._isReadOnly = false;
        return n;
    }

    Object GetFormat(TypeInfo type)
    {
        return type == typeid(this) ? this : null;
    }

    static NumberFormatInfo ReadOnly(NumberFormatInfo nfi)
    {
        if (nfi is null)
            throw new ArgumentNullException("nfi");
        NumberFormatInfo n = cast(NumberFormatInfo)nfi.Clone();
        n._isReadOnly = true;
        return n;
    }

    @property 
    int CurrencyDecimalDigits()
    {
        if (_currencyDecimalDigits < 0)
            _currencyDecimalDigits = _data.iCurrDigits;
        return _currencyDecimalDigits;
    }

    @property 
    int CurrencyDecimalDigits(int value)
    {
        checkWriteable();
        checkDecimalDigits(value, "CurrencyDecimalDigits");
        return _currencyDecimalDigits = value;
    }

    @property 
    wstring CurrencyDecimalSeparator()
    {
        if (_currencyDecimalSeparator is null)
            _currencyDecimalSeparator = _data.sMonDecimalSep;
        return _currencyDecimalSeparator;
    }

    @property 
    wstring CurrencyDecimalSeparator(wstring value)
    {
        checkWriteable();
        checkDecimalSeparator(value, "CurrencyDecimalSeparator");
        return _currencyDecimalSeparator = value;
    }

    @property 
    wstring CurrencyGroupSeparator()
    {
        if (_currencyGroupSeparator is null)
            _currencyGroupSeparator = _data.sMonThousandSep;
        return _currencyGroupSeparator;
    }

    @property 
    wstring CurrencyGroupSeparator(wstring value)
    {
        checkWriteable();
        checkGroupSeparator(value, "CurrencyGroupSeparator");
        return _currencyGroupSeparator = value;
    }

    @property 
    int[] CurrencyGroupSizes()
    {
        if (_currencyGroupSizes is null)
            _currencyGroupSizes = getGroupSizes(_data.sMonGrouping);
        return _currencyGroupSizes.dup;
    }

    @property 
    int[] CurrencyGroupSizes(int[] value)
    {
        checkWriteable();
        checkGroupSizes(value, "CurrencyGroupSizes");
        return _currencyGroupSizes = value.dup;
    }

    @property 
    int CurrencyNegativePattern()
    {
        if (_currencyNegativePattern < 0)
            _currencyNegativePattern = _data.iNegCurr;
        return _currencyNegativePattern;
    }

    @property 
    int CurrencyNegativePattern(int value)
    {
        checkWriteable();
        checkNegativePattern(value, "CurrencyNegativePattern");
        return _currencyNegativePattern = value;
    }

    @property 
    int CurrencyPositivePattern() 
    {
        if (_currencyPositivePattern < 0)
            _currencyPositivePattern = _data.iCurrency;
        return _currencyPositivePattern;
    }

    @property 
    int CurrencyPositivePattern(int value)
    {
        checkWriteable();
        checkPositivePattern(value, "CurrencyPositivePattern");
        return _currencyPositivePattern = value;
    }

    @property 
    wstring CurrencySymbol()
    {
        if (_currencySymbol is null)
            _currencySymbol = _data.sCurrency;
        return _currencySymbol;
    }
    
    @property 
    wstring CurrencySymbol(wstring value)
    {
        checkWriteable();
        checkNull(value, "CurrencySymbol");
        return _currencySymbol = value;
    }

    @property 
    DigitShapes DigitSubstitution()
    {
        if (_digitSubstitution < 0)
            _digitSubstitution = cast(DigitShapes)_data.iDigitSubstitution;
        return _digitSubstitution;
    }

    @property 
    DigitShapes DigitSubstitution(DigitShapes value)
    {
        checkWriteable();
        checkEnum(value, "DigitSubstitution");
        return _digitSubstitution = value;
    }

    @property 
    static NumberFormatInfo InvariantInfo()
    {
        if (_invariantInfo is null)
            _invariantInfo = ReadOnly(new NumberFormatInfo());
        return _invariantInfo;
    }

    @property 
    wstring NanSymbol() 
    {
        if (_nanSymbol is null)
            _nanSymbol = _data.sNan;
        return _nanSymbol;
    }

    @property 
    wstring NanSymbol(wstring value)
    {
        checkWriteable();
        checkNull(value, "NanSymbol");
        return _nanSymbol = value;
    }

    @property 
    wstring[] NativeDigits()
    {
        if (_nativeDigits is null)
            _nativeDigits = getNativeDigits(_data.sNativeDigits);
        return _nativeDigits.dup;
    }

    @property 
    wstring[] NativeDigits(wstring[] value)
    {
        checkWriteable();
        checkNull(value, "NativeDigits");
        if (value.length != 10)
            throw new ArgumentException(SharpResources.GetString("ArgumentNativeDigitsCount"), "NativeDigits");
        for (int i = 0; i < 10; i++)
        {
            if (value[i] is null)
                throw new ArgumentNullException("NativeDigits", SharpResources.GetString("ArgumentNativeDigit"));
            if (value[i].length != 1 || (Char.IsHighSurrogate(value[i], 0) && value[i].length != 2))
                throw new ArgumentException(SharpResources.GetString("ArgumentNativeDigit"), "NativeDigits");
            if (CharUnicodeInfo.GetDecimalDigitValue(value[i], 0) != i)
                throw new ArgumentException(SharpResources.GetString("ArgumentNativeDigit"), "NativeDigits");
        }
        return NativeDigits = value.dup;
    }

    @property 
    wstring NegativeInfinitySymbol() 
    {
        if (_negativeInfinitySymbol is null)
            _negativeInfinitySymbol = _data.sNegInfinity;
        return _negativeInfinitySymbol;
    }

    @property 
    wstring NegativeInfinitySymbol(wstring value)
    {
        checkWriteable();
        checkNull(value, "NegativeInfinitySymbol");
        return _negativeInfinitySymbol = value;
    }

    @property
    wstring NegativeSign() 
    {
        if (_negativeSign is null)
            _negativeSign = _data.sNegativeSign;
        return _negativeSign;
    }

    @property 
    wstring NegativeSign(wstring value)
    {
        checkWriteable();
        checkNull(value, "NegativeSign");
        return _negativeSign = value;
    }

    @property
    int NumberDecimalDigits()
    {
        if (_numberDecimalDigits < 0)
            _numberDecimalDigits = _data.iDigits;
        return _numberDecimalDigits;
    }

    @property 
    int NumberDecimalDigits(int value)
    {
        checkWriteable();
        checkDecimalDigits(value, "NumberDecimalDigits");
        return _numberDecimalDigits = value;
    }

    @property 
    wstring NumberDecimalSeparator()
    {
        if (_numberDecimalSeparator is null)
            _numberDecimalSeparator = _data.sDecimal;
        return _numberDecimalSeparator;
    }

    @property
    wstring NumberDecimalSeparator(wstring value)
    {
        checkWriteable();
        checkDecimalSeparator(value, "NumberDecimalSeparator");
        return _numberDecimalSeparator = value;
    }

    @property 
    wstring NumberGroupSeparator()
    {
        if (_numberGroupSeparator is null)
            _numberGroupSeparator = _data.sThousand;
        return _numberGroupSeparator;
    }

    @property
    wstring NumberGroupSeparator(wstring value)
    {
        checkWriteable();
        checkGroupSeparator(value, "NumberGroupSeparator");
        return _numberGroupSeparator = value;
    }

    @property 
    int[] NumberGroupSizes() 
    {
        if (_numberGroupSizes is null)
            _numberGroupSizes = getGroupSizes(_data.sGrouping);
        return _numberGroupSizes.dup;
    }

    @property 
    int[] NumberGroupSizes(int[] value)
    {
        checkWriteable();
        checkGroupSizes(value, "NumberGroupSizes");
        return _numberGroupSizes = value.dup;
    }

    @property
    int NumberNegativePattern() 
    {
        if (_numberNegativePattern < 0)
            _numberNegativePattern = _data.iNegNumber;
        return _numberNegativePattern;
    }

    @property 
    int NumberNegativePattern(int value)
    {
        checkWriteable();
        checkNegativePattern(value, "NumberNegativePattern");
        return _numberNegativePattern = value;
    }

    @property
    int PercentDecimalDigits() 
    {
        if (_percentDecimalDigits < 0)
            _percentDecimalDigits = _data.iDigits;
        return _percentDecimalDigits;
    }

    @property 
    int PercentDecimalDigits(int value)
    {
        checkWriteable();
        checkDecimalDigits(value, "PercentDecimalDigits");
        return _percentDecimalDigits = value;
    }

    @property 
    wstring PercentDecimalSeparator() 
    {
        if (_percentDecimalSeparator is null)
            _percentDecimalSeparator = NumberDecimalSeparator;
        return _percentDecimalSeparator;
    }

    @property
    wstring PercentDecimalSeparator(wstring value)
    {
        checkWriteable();
        checkDecimalSeparator(value, "PercentDecimalSeparator");
        return _percentDecimalSeparator = value;
    }

    @property
    wstring PercentGroupSeparator()
    {
        if (_percentGroupSeparator is null)
            _percentGroupSeparator = NumberGroupSeparator;
        return _percentGroupSeparator;
    }

    @property 
    wstring PercentGroupSeparator(wstring value)
    {
        checkWriteable();
        checkGroupSeparator(value, "PercentGroupSeparator");
        return _percentGroupSeparator = value;
    }

    @property 
    int[] PercentGroupSizes()
    {
        if (_percentGroupSizes is null)
            _percentGroupSizes = NumberGroupSizes;
        return _percentGroupSizes.dup;
    }

    @property 
    int[] PercentGroupSizes(int[] value)
    {
        checkWriteable();
        checkGroupSizes(value, "PercentGroupSizes");
        return _percentGroupSizes = value.dup;
    }

    @property 
    int PercentNegativePattern()
    {
        if (_percentNegativePattern < 0)
            _percentNegativePattern = _data.iNegPercent;
        return _percentNegativePattern;
    }

    @property 
    int PercentNegativePattern(int value)
    {
        checkWriteable();
        checkNegativePattern(value, "PercentNegativePattern");
        return _percentNegativePattern = value;
    }

    @property 
    int PercentPositivePattern() 
    {
        if (_percentPositivePattern < 0)
            _percentPositivePattern = _data.iPosPercent;
        return _percentPositivePattern;
    }

    @property 
    int PercentPositivePattern(int value)
    {
        checkWriteable();
        checkPositivePattern(value, "PercentPositivePattern");
        return _percentPositivePattern = value;
    }

    @property 
    wstring PercentSymbol()
    {
        if (_percentSymbol is null)
            _percentSymbol = _data.sPercent;
        return _percentSymbol;
    }

    @property 
    wstring PercentSymbol(wstring value)
    {
        checkWriteable();
        checkNull(value, "PercentSymbol");
        return _percentSymbol = value;
    }

    @property 
    wstring PermilleSymbol()
    {
        if (_permilleSymbol is null)
            _permilleSymbol = _data.sPermille;
        return _permilleSymbol;
    }

    @property
    wstring PermilleSymbol(wstring value)
    {
        checkWriteable();
        checkNull(value, "PermilleSymbol");
        return _permilleSymbol = value;
    }

    @property 
    wstring PositiveInfinitySymbol()
    {
        if (_positiveInfinitySymbol is null)
            _positiveInfinitySymbol = _data.sPosInfinity;
        return _positiveInfinitySymbol;
    }

    @property 
    wstring PositiveInfinitySymbol(wstring value)
    {
        checkWriteable();
        checkNull(value, "PositiveInfinitySymbol");
        return _positiveInfinitySymbol = value;
    }

    @property
    wstring PositiveSign() 
    {
        if (_positiveSign is null)
            _positiveSign = _data.sPositiveSign;
        return _positiveSign;
    }

    @property 
    wstring PositiveSign(wstring value)
    {
        checkWriteable();
        checkNull(value, "PositiveSign");
        return _positiveSign = value;
    }

    @property pure @safe nothrow @nogc
    bool IsReadOnly()
    {
        return _isReadOnly;
    }

    static NumberFormatInfo GetInstance(IFormatProvider provider)
    {
        NumberFormatInfo ret;
        CultureInfo ci = cast(CultureInfo)provider;
        if (ci)
            return ci.NumberFormat;

        if (provider !is null)
        {
            ret = cast(NumberFormatInfo)provider;
            if (ret is null)
                ret = cast(NumberFormatInfo)(provider.GetFormat(typeid(NumberFormatInfo)));
        }
        return ret;
    }

    @property static NumberFormatInfo CurrentInfo()
    {
        CultureInfo culture = CultureInfo.CurrentCulture;
        NumberFormatInfo info = culture.NumberFormat;
        if (info is null)
            info = cast(NumberFormatInfo)(culture.GetFormat(typeid(NumberFormatInfo)));
        return info;
    }

}

// =====================================================================================================================
// SortVersion
// =====================================================================================================================

final class SortVersion: SharpObject, IEquatable!SortVersion
{
private:
    int _nlsVersion;
    Guid _sortId;

package:
    this(LocaleData data)
    {
        _nlsVersion = data.nlsVersion;
        if (data.nlsCustom == Guid.Empty)
            _sortId = Guid(0u, 0u, 0u, 0u, 0u, 0u, 0u,
                           cast(ubyte)(cast(uint)data.nlsEffective >> 24),
                           cast(ubyte)(cast(uint)(data.nlsEffective & 0x00ff0000) >> 16),
                           cast(ubyte)(cast(uint)(data.nlsEffective & 0x0000ff00) >> 8),
                           cast(ubyte)(cast(uint)(data.nlsEffective & 0x000000ff)));
        else
            _sortId = data.nlsCustom;
    }

public:
    this(int fullVersion, Guid sortId)   
    {
        _nlsVersion = fullVersion;
        _sortId = sortId;
    }

    bool Equals(SortVersion other)    
    {
        if (other is null)
            return false;
        return this._nlsVersion == other._nlsVersion && this._sortId == other._sortId;
    }

    override bool Equals(Object obj)
    {
        SortVersion sv = cast(SortVersion)obj;
        return Equals(sv);
    }

    override int GetHashCode() nothrow
    {
        return _sortId.GetHashCode() | _nlsVersion;
    }

    @property 
    int FullVersion()    
    {
        return _nlsVersion;
    }

    @property 
    Guid SortId()    
    {
        return _sortId;
    }
}


// =====================================================================================================================
// CompareInfo
// =====================================================================================================================

class CompareInfo: SharpObject
{
private:
    LocaleData _data;
    wstring _sortName;
    SortVersion _version;
    uint _lcid;

    pure @safe nothrow @nogc
    static int compareOrdinal(wstring s1, int o1, int l1, wstring s2, int o2, int l2)
    {

        auto i = o1;
        auto j = o2;
        immutable lo1 = o1 + l1;
        immutable lo2 = o2 + l2;
        while (i < lo1 && j < o2 + lo2)
        {
            wchar c1 = s1[i++];
            wchar c2 = s2[j++];
            if (c1 > c2)
                return 1;
            else if (c1 < c2)
                return -1;
        }
        if (l1 > l2)
            return 1;
        else if (l1 < l2)
            return -1;
        return 0;
    }


    static int compareOrdinalIgnoreCase(wstring s1, int o1, int l1, wstring s2, int o2, int l2)
    {
        int i = o1;
        int j = o2;
        immutable lo1 = o1 + l1;
        immutable lo2 = o2 + l2;
        while (i < lo1 && j < lo2)
        {
            wchar c1 = Char.ToUpperInvariant(s1[i++]);
            wchar c2 = Char.ToUpperInvariant(s2[j++]);
            if (c1 > c2)
                return 1;
            else if (c1 < c2)
                return -1;
        }
        if (l1 > l2)
            return 1;
        else if (l1 < l2)
            return -1;
        return 0;
    }

    pure @safe nothrow @nogc
    static int indexOfOrdinal(wstring s1, wstring s2, int o1, int l1)
    {
        immutable l2 = s2.length;
        if (l2 > l1)
            return -1;
        auto i = o1;
        immutable lim = o1 + l1 - l2;
        while (i < lim)
        {
            if (compareOrdinal(s1, i, l2, s2, 0, l2) == 0)
                return i;
            i++;
        }
        return -1;
    }

    static int indexOfOrdinalIgnoreCase(wstring s1, wstring s2, int o1, int l1)
    {
        immutable l2 = s2.length;
        if (l2 > l1)
            return -1;
        auto i = o1;
        immutable lim = o1 + l1 - l2;
        while (i < lim)
        {
            if (compareOrdinalIgnoreCase(s1, i, l2, s2, 0, l2) == 0)
                return i;
            i++;
        }
        return -1;
    }

    static int lastIndexOfOrdinal(wstring s1, wstring s2, int o1, int l1)
    {
        immutable l2 = safe32bit(s2.length);
        if (l2 > l1)
            return -1;
        auto i = o1 + l1 - l2 - 1;
        while (i >= 0)
        {
            if (compareOrdinal(s1, i, l2, s2, 0, l2) == 0)
                return i;
            i--;
        }
        return -1;
    }

    static int lastIndexOfOrdinalIgnoreCase(wstring s1, wstring s2, int o1, int l1)
    {
        immutable l2 = safe32bit(s2.length);
        if (l2 > l1)
            return -1;
        auto i = o1 + l1 - l2 - 1;
        while (i >= 0)
        {
            if (compareOrdinalIgnoreCase(s1, i, l2, s2, 0, l2) == 0)
                return i;
            i--;
        }
        return -1;
    }

    static bool isPrefixOrdinal(wstring s1, wstring s2)
    {
        immutable l1 = s1.length;
        immutable l2 = s2.length;
        if (l2 > l1)
            return false;
        return compareOrdinal(s1, 0, l2, s2, 0, l2) == 0;
    }

    static bool isPrefixOrdinalIgnoreCase(wstring s1, wstring s2)
    {
        immutable l1 = s1.length;
        immutable l2 = s2.length;
        if (l2 > l1)
            return false;
        return compareOrdinalIgnoreCase(s1, 0, l2, s2, 0, l2) == 0;
    }

    static bool isSuffixOrdinal(wstring s1, wstring s2)
    {
        immutable l1 = s1.length;
        immutable l2 = s2.length;
        if (l2 > l1)
            return false;
        return compareOrdinal(s1, l1 - l2, l2, s2, 0, l2) == 0;
    }

    static bool isSuffixOrdinalIgnoreCase(wstring s1, wstring s2)
    {
        immutable l1 = s1.length;
        immutable l2 = s2.length;
        if (l2 > l1)
            return false;
        return compareOrdinalIgnoreCase(s1, l1 - l2, l2, s2, 0, l2) == 0;
    }

    this(LocaleData data)
    {
        _data = data;
        _sortName = _data.sSortLocale;
        _lcid = _data.lcid;
    }

public:

    int Compare(wstring string1, int offset1, int length1, wstring string2, int offset2, int length2, CompareOptions options)
    {
        checkEnum(options);

        if (offset1 > string1.length - length1)
            throw new ArgumentOutOfRangeException("offset1");
        if (offset2 > string2.length - length2)
            throw new ArgumentOutOfRangeException("offset2");

        if (options == CompareOptions.Ordinal)
            return compareOrdinal(string1, offset1, length1, string2, offset2, length2);
        if (options == CompareOptions.OrdinalIgnoreCase)
            return compareOrdinalIgnoreCase(string1, offset1, length1, string2, offset2, length2);

        if ((options & CompareOptions.Ordinal) != 0)
            throw new ArgumentException(null, "options");
        if ((options & CompareOptions.OrdinalIgnoreCase) != 0)
            throw new ArgumentException(null, "options");

        if (string1 is null)
            return string2 is null ? 0 : -1;
        if (string2 is null)
            return 1;
        if (string1.length == 0)
            return string2.length == 0 ? 0 : -1;
        if (string2.length == 0)
            return 1;
        return _data.compare(string1[offset1 .. offset1 + length1], string2[offset2 .. offset2 + length2], options);
    }

    int Compare(wstring string1, wstring string2, CompareOptions options)
    {
        return Compare(string1, 0, string1.length, string2, 0, string2.length, options);
    }

    int Compare(wstring string1, int offset1, int length1, wstring string2, int offset2, int length2)
    {
        return Compare(string1, offset1, length1, string2, offset2, length2, CompareOptions.None);
    }

    int Compare(wstring string1, int offset1, wstring string2, int offset2) 
    {
        return Compare(string1, offset1, string1.length - offset1, string2, offset2, string2.length - offset2, CompareOptions.None);
    }

    int Compare(wstring string1, int offset1, wstring string2, int offset2, CompareOptions options)
    {
        return Compare(string1, offset1, string1.length - offset1, string2, offset2, string2.length - offset2, options);
    }

    int Compare(wstring string1, wstring string2)
    {
        return Compare(string1, 0, string1.length, string2, 0, string2.length, CompareOptions.None);
    }

    

    int IndexOf(wstring source, wstring value, int startIndex, int count, CompareOptions options)
    {
        checkNull(source, "source");
        checkNull(value);
        checkIndex(source, startIndex, count, "startIndex");
        checkEnum(options, "options");
        if (source.length == 0)
            return value.length == 0 ? 0 : -1;
       
        if (options == CompareOptions.Ordinal)
            return indexOfOrdinal(source, value, startIndex, count);
        if (options == CompareOptions.OrdinalIgnoreCase)
            return indexOfOrdinalIgnoreCase(source, value, startIndex, count);
        return _data.IndexOf(source[startIndex .. startIndex + count], value, options);

    }

    int IndexOf(wstring source, wchar value, int startIndex, int count, CompareOptions options)
    {
        return IndexOf(source, [value], startIndex, count, options);
    }

    int IndexOf(wstring source, wstring value, int startIndex, int count)
    {
        return IndexOf(source, value, startIndex, count, CompareOptions.None);
    }

    int IndexOf(wstring source, wchar value, int startIndex, int count)
    {
        return IndexOf(source, [value], startIndex, count, CompareOptions.None);
    }

    int IndexOf(wstring source, wstring value)
    {
        return IndexOf(source, value, 0, source.length, CompareOptions.None);
    }

    int IndexOf(wstring source, wchar value)
    {
        return IndexOf(source, [value], 0, source.length, CompareOptions.None);
    }

    int IndexOf(wstring source, wstring value, int startIndex, CompareOptions options)
    {
        return IndexOf(source, value, startIndex, source.length - startIndex, CompareOptions.None);
    }

    int IndexOf(wstring source, wchar value, int startIndex, CompareOptions options)
    {
        return IndexOf(source, [value], startIndex, source.length - startIndex, CompareOptions.None);
    }

    int IndexOf(wstring source, wstring value, int startIndex)
    {
        return IndexOf(source, value, startIndex, source.length - startIndex, CompareOptions.None);
    }

    int IndexOf(wstring source, wchar value, int startIndex)
    {
        return IndexOf(source, [value], startIndex, source.length - startIndex, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wstring value, int startIndex, int count, CompareOptions options)
    {
        checkNull(source, "source");
        checkNull(value);
        checkIndex(source, startIndex, count, "startIndex");
        checkEnum(options, "options");
        checkEnum(options);
        if (source.length == 0)
            return value.length == 0 ? 0 : -1;      
        if (options == CompareOptions.Ordinal)
            return lastIndexOfOrdinal(source, value, startIndex, count);
        if (options == CompareOptions.OrdinalIgnoreCase)
            return lastIndexOfOrdinalIgnoreCase(source, value, startIndex, count);
        return _data.LastIndexOf(source[startIndex .. startIndex + count], value, options);
    }

    int LastIndexOf(wstring source, wchar value, int startIndex, int count, CompareOptions options)
    {
        return LastIndexOf(source, [value], startIndex, count, options);
    }

    int LastIndexOf(wstring source, wstring value, int startIndex, int count)
    {
        return LastIndexOf(source, value, startIndex, count, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wchar value, int startIndex, int count)
    {
        return LastIndexOf(source, [value], startIndex, count, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wstring value)
    {
        return LastIndexOf(source, value, 0, source.length, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wchar value)
    {
        return LastIndexOf(source, [value], 0, source.length, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wstring value, int startIndex, CompareOptions options)
    {
        return LastIndexOf(source, value, startIndex, source.length - startIndex, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wchar value, int startIndex, CompareOptions options)
    {
        return LastIndexOf(source, [value], startIndex, source.length - startIndex, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wstring value, int startIndex)
    {
        return LastIndexOf(source, value, startIndex, source.length - startIndex, CompareOptions.None);
    }

    int LastIndexOf(wstring source, wchar value, int startIndex)
    {
        return LastIndexOf(source, [value], startIndex, source.length - startIndex, CompareOptions.None);
    }

    bool IsPrefix(wstring source, wstring prefix, CompareOptions options)
    {
        checkNull(source, "source");
        checkNull(prefix, "prefix");
        if (prefix.length == 0)
            return true;
        if (options == CompareOptions.Ordinal)
            return isPrefixOrdinal(source, prefix);
        if (options == CompareOptions.OrdinalIgnoreCase)
            return isPrefixOrdinalIgnoreCase(source, prefix);
            return _data.IsPrefix(source, prefix, options);
    }

    bool IsPrefix(wstring source, wstring prefix)
    {
        return IsPrefix(source, prefix, CompareOptions.None);
    }

    bool IsSuffix(wstring source, wstring suffix, CompareOptions options)
    {
        checkNull(source, "source");
        checkNull(suffix, "suffix");
        if (suffix.length == 0)
            return true;
        if (options == CompareOptions.Ordinal)
            return isSuffixOrdinal(source, suffix);
        if (options == CompareOptions.OrdinalIgnoreCase)
            return isSuffixOrdinalIgnoreCase(source, suffix);
        return _data.IsSuffix(source, suffix, options);
    }

    bool IsSuffix(wstring source, wstring suffix)
    {
        return IsSuffix(source, suffix, CompareOptions.None);
    }

    @property 
    SortVersion Version()
    {
        if (_version is null)
            _version = new SortVersion(_data);
        return _version;
    }

    override bool opEquals(Object obj)
    {
        CompareInfo ci = cast(CompareInfo)obj;
        return ci !is null && ci._sortName == this._sortName;
    }

    nothrow
    override int GetHashCode()
    {
        return _sortName.GetHashCode();
    }

    static bool IsSortable(wchar ch)
    {
        UnicodeCategory categ = CharUnicodeInfo.GetUnicodeCategory(ch);
        return (categ != UnicodeCategory.PrivateUse && categ != UnicodeCategory.Surrogate); 
    }

    static bool IsSortable(wstring s)
    {
        auto len = s.length;
        auto i = 0;
        while (i < len)
        {
            UnicodeCategory categ = CharUnicodeInfo.GetUnicodeCategory(s, i);
            if (categ != UnicodeCategory.PrivateUse || categ != UnicodeCategory.Surrogate)
                return false;
            i += Char.IsSurrogatePair(s, i) ? 2 : 1;
        }
        return true;
    }

    SortKey GetSortKey(wstring source, CompareOptions options)
    {
        checkNull(source, "source");
        checkEnum(options, "options");
        return new SortKey(_data, source, options);
    }

    SortKey GetSortKey(wstring source)
    {
        return GetSortKey(source, CompareOptions.None);
    }

    @property wstring Name()
    {
        return _sortName;
    }

    @property uint LCID()
    {
        return _lcid;
    }

    static CompareInfo GetCompareInfo(wstring name)
    {
        checkNull(name, "name");
        return CultureInfo.GetCultureInfo(name).CompareInfo;
    }

    static CompareInfo GetCompareInfo(int culture)
    {
        return CultureInfo.GetCultureInfo(culture).CompareInfo;
    }

    static CompareInfo GetCompareInfo(wstring name, Assembly assembly)
    {
        checkNull(assembly, "assembly");
        return CultureInfo.GetCultureInfo(name).CompareInfo;
    }

    static CompareInfo GetCompareInfo(int culture, Assembly assembly)
    {
        checkNull(assembly, "assembly");
        return CultureInfo.GetCultureInfo(culture).CompareInfo;
    }

    override wstring ToString()
    {
        return "CompareInfo - " ~ _sortName;
    }
}

// =====================================================================================================================
// SortKey
// =====================================================================================================================

class SortKey:  SharpObject 
{
private:
    LocaleData _data;
    wstring _str;
    CompareOptions _options;
    ubyte[] _keyData = null;

    this(LocaleData data, wstring str, CompareOptions options)
    {
        _data = data;
        _str = str;
        _options = options;
    }

public:

    @property 
    wstring OriginalString()
    {
        return _str;
    }

    @property ubyte[] KeyData()
    {
        if (_keyData is null)
            _keyData = _data.GetSortKey(_str, _options);
        return _keyData.dup();
    }

    static int Compare(SortKey k1, SortKey k2)
    {
        if (k1 is k2)
            return 0;
        if (k1 is null)
            return -1;
        if (k2 is null)
            return 1;
        k1.KeyData();
        k2.KeyData();

        if (k1._keyData.length == 0)
        {
            if (k2._keyData.length == 0)
                return 0;
            return -1;
        }

        if (k2._keyData.length == 0)
            return 1;

        auto len = k1._keyData.length > k2._keyData.length ? k2._keyData.length : k1._keyData.length;

        for(auto i = 0; i < len; i++)
        {
            if (k1._keyData[i] > k2._keyData[i])
                return 1;
            else if (k1._keyData[i] < k2._keyData[i]) 
                return -1;
        }

        return 0;
    }

    static bool Equals(SortKey k1, SortKey k2)
    {
        return Compare(k1, k2) == 0;
    }

    nothrow
    override int GetHashCode()
    {
        return _str.GetHashCode() | _options;
    }

}

// =====================================================================================================================
// Calendar
// =====================================================================================================================

enum CalendarWeekRule
{
    FirstDay,
    FirstFullWeek,
    FirstFourDayWeek,
}

enum CalendarAlgorithmType
{
    Unknown,
    SolarCalendar,
    LunarCalendar,
    LunisolarCalendar,
}

abstract class Calendar : SharpObject, ICloneable
{
private:
    bool _isReadOnly;

    DateTime add(DateTime time, double value, int scale) 
    {
        long ticks = getTicks(value, scale) + time.Ticks;
        if (ticks < MinSupportedDateTime.Ticks || ticks > MaxSupportedDateTime.Ticks)
            throw new ArgumentException(null, "value");
        return DateTime(ticks, DateTimeKind.Unspecified);
    }

    int getFirstDayWeekOfYear(DateTime d, int firstDayOfWeek)
    {
        int dayOfYear = GetDayOfYear(d) - 1; 
        int dayForJan1 = cast(int)getDayOfWeek(d) - (dayOfYear % 7);
        int offset = (dayForJan1 - firstDayOfWeek + 14) % 7;
        return ((dayOfYear + offset) / 7 + 1);
    }

    int getWeekOfYearFullDays(DateTime d, int firstDayOfWeek, int fullDays) 
    {
        int dayOfYear = GetDayOfYear(d) - 1; 
        int dayForJan1 = cast(int)getDayOfWeek(d) - (dayOfYear % 7);
        int offset = (firstDayOfWeek - dayForJan1 + 14) % 7;
        if (offset != 0 && offset >= fullDays)
            offset -= 7;
        int day = dayOfYear - offset;
        if (day >= 0) 
            return (day / 7 + 1);
        if (d <= MinSupportedDateTime.AddDays(dayOfYear))
            return getWeekOfYearOfMinSupportedDateTime(firstDayOfWeek, fullDays);
        return getWeekOfYearFullDays(d.AddDays(-(dayOfYear + 1)), firstDayOfWeek, fullDays);
    }

    int getWeekOfYearOfMinSupportedDateTime(int firstDayOfWeek, int minimumDaysInFirstWeek) 
    {
        int dayOfYear = GetDayOfYear(MinSupportedDateTime) - 1;
        int dayOfWeekOfFirstOfYear = cast(int)getDayOfWeek(MinSupportedDateTime) - dayOfYear % 7;
        int offset = (firstDayOfWeek + 7 - dayOfWeekOfFirstOfYear) % 7;
        if (offset == 0 || offset >= minimumDaysInFirstWeek)
            return 1;
        int daysInYearBeforeMinSupportedYear = DaysInYearBeforeMinSupportedYear - 1; 
        int dayOfWeekOfFirstOfPreviousYear = dayOfWeekOfFirstOfYear - 1 - (daysInYearBeforeMinSupportedYear % 7);

        int daysInInitialPartialWeek = (firstDayOfWeek - dayOfWeekOfFirstOfPreviousYear + 14) % 7;
        int day = daysInYearBeforeMinSupportedYear - daysInInitialPartialWeek;
        if (daysInInitialPartialWeek >= minimumDaysInFirstWeek)
            day += 7;
        return (day / 7 + 1);
    }

protected:

    int _twoDigitYearMax = -1;
    final void checkWriteable()
    {
        if (_isReadOnly)
            throw new InvalidOperationException();
    }

    @property int calID()
    {
        return -1;
    }

package:
    int getCalID()
    {
        return calID;
    }

public:

    enum CurrentEra = 0;

    abstract DateTime AddMonths(DateTime d, int months);
    abstract DateTime AddYears(DateTime d, int years);
    abstract int GetDayOfMonth(DateTime d);
    abstract DayOfWeek getDayOfWeek(DateTime d);
    abstract int GetDayOfYear(DateTime d);
    abstract int GetDaysInMonth(int year, int month, int era);
    abstract int GetDaysInYear(int year, int era);
    abstract int GetEra(DateTime d);
    abstract bool IsLeapYear(int year, int era);
    abstract bool IsLeapMonth(int year, int month, int era);
    abstract bool IsLeapDay(int year, int month, int day, int era);
    abstract int GetMonthsInYear(int year, int era);
    abstract int GetMonth(DateTime d);
    abstract int GetYear(DateTime d);
    @property abstract int DaysInYearBeforeMinSupportedYear();
    @property abstract int[] Eras();

    int GetWeekOfYear(DateTime d, CalendarWeekRule rule, DayOfWeek firstDayOfWeek)
    {
        if (firstDayOfWeek < DayOfWeek.min || firstDayOfWeek > DayOfWeek.max)
            throw new ArgumentOutOfRangeException("firstDayOfWeek");         
        if (rule < CalendarWeekRule.min || rule > CalendarWeekRule.max)
            throw new ArgumentOutOfRangeException("rule");   
        final switch (rule) 
        {
            case CalendarWeekRule.FirstDay:
                return (getFirstDayWeekOfYear(d, firstDayOfWeek));
            case CalendarWeekRule.FirstFullWeek:
                return (getWeekOfYearFullDays(d, firstDayOfWeek, 7));
            case CalendarWeekRule.FirstFourDayWeek:
                return (getWeekOfYearFullDays(d, firstDayOfWeek, 4));
        }
    }

    bool IsLeapDay(int year, int month, int day)
    {
        return IsLeapDay(year, month, day, CurrentEra);
    }

    int GetLeapMonth(int year, int era)
    {
        if (!IsLeapYear(year, era))
            return 0;
        int months = GetMonthsInYear(year, era);
        for (int month = 1; month <= months; month++)
        {
            if (IsLeapMonth(year, month, era))
                return month;
        }
        return 0;
    }

    int GetLeapMonth(int year)
    {
        return GetLeapMonth(year, CurrentEra);
    }

    int GetMonthsInYear(int year)
    {
        return GetMonthsInYear(year, CurrentEra);
    }

    bool IsLeapYear(int year)
    {
        return IsLeapYear(year, CurrentEra);
    }

    bool IsLeapMonth(int year,  int month) 
    {
        return IsLeapMonth(year, month, CurrentEra);
    }

    int GetHour(DateTime d) 
    {
        return (d.Ticks / ticksPerHour) % hoursPerDay;
    }

    int GetMilliseconds(DateTime d) 
    {
        return (d.Ticks / ticksPerMillisecond) % millisecondsPerSecond;
    }

    int GetMinute(DateTime d) 
    {
        return (d.Ticks / ticksPerMinute) % minutesPerHour;
    }

    int GetSecond(DateTime d)
    {
        return (d.Ticks / ticksPerSecond) % secondsPerMinute;
    }

    int GetDaysInMonth(int year, int month)
    {
        return GetDaysInMonth(year, month, CurrentEra);
    }

    int GetDaysInYear(int year)
    {
        return GetDaysInYear(CurrentEra);
    }

    DateTime AddDays(DateTime d, int days)
    {
        return add(d, days, millisecondsPerDay);
    }

    DateTime AddHours(DateTime d, int hours)
    {
        return add(d, hours, millisecondsPerHour);
    }

    DateTime AddMinutes(DateTime d, int minutes)
    {
        return add(d, minutes, millisecondsPerMinute);
    }

    DateTime AddSeconds(DateTime d, int seconds)
    {
        return add(d, seconds, millisecondsPerSecond);
    }

    DateTime AddMilliseconds(DateTime d, int milliseconds)
    {
        return add(d, milliseconds, 1);
    }

    DateTime AddWeeks(DateTime d, int weeks)
    {
        return AddDays(d, weeks * 7);
    }

    static Calendar ReadOnly(Calendar calendar)
    {
        Calendar c = cast(Calendar)(calendar.Clone());
        c._isReadOnly = true;
        return c;
    }

    Object Clone() 
    {
        Calendar c = cast(Calendar)MemberwiseClone();
        c._isReadOnly = false;
        return c;
    }

    @property DateTime MinSupportedDateTime()    
    {
        return DateTime.MinValue;
    }

    @property DateTime MaxSupportedDateTime()    
    {
        return DateTime.MaxValue;
    }

    @property CalendarAlgorithmType algorithmType()
    {
        return CalendarAlgorithmType.Unknown;
    }

    @property final bool IsReadOnly()    
    {
        return _isReadOnly;
    }

    abstract DateTime ToDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era);

    DateTime ToDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond)
    {
        return ToDateTime(year, month, day, hour, minute, second, millisecond, CurrentEra);
    }

    int ToFourDigitYear(int year)
    {
        if (year < 0)
            throw new ArgumentOutOfRangeException("year");
        if (year < 100)
            return ((TwoDigitYearMax / 100 - ( year > TwoDigitYearMax % 100 ? 1 : 0)) * 100 + year);
        return year;
    }

    @property int TwoDigitYearMax()
    {
        return _twoDigitYearMax;
    }

    @property int TwoDigitYearMax(int value)
    {
        checkWriteable();
        return _twoDigitYearMax = value;
    }
}

// =====================================================================================================================
// DateTimeFormatInfo
// =====================================================================================================================

final class DateTimeFormatInfo: SharpObject
{
    LocaleData _data;
    CalendarData _calData;

    static DateTimeFormatInfo _invariantInfo;

    bool _isReadOnly;
    Calendar _calendar;
    wstring[] _abbreviatedDayNames;
    wstring[] _dayNames;
    wstring[] _abbreviatedMonthNames;
    wstring[] _abbreviatedGenitiveMonthNames;
    wstring[] _monthNames;
    wstring[] _genitiveMonthNames;
    wstring[] _eraNames;
    wstring[] _abbreviatedEraNames;
    wstring[] _shortestDayNames;
    wstring _amDesignator;
    wstring _pmDesignator;
    wstring[] _shortDatePatterns;
    wstring[] _longDatePatterns;
    wstring[] _shortTimePatterns;
    wstring[] _longTimePatterns;
    wstring[] _yearMonthPatterns;
    wstring _shortDatePattern;
    wstring _longDatePattern;
    wstring _shortTimePattern;
    wstring _longTimePattern;
    wstring _yearMonthPattern;
    wstring _monthDayPattern;
    int _calendarWeekRule = -1;
    wstring _dateSeparator;
    wstring _timeSeparator;
    int _firstDayOfWeek = -1;
    wstring _fullDateTimePattern;
    wstring _nativeCalendarName;

    void checkWriteable()
    {
        if (_isReadOnly)
            throw new InvalidOperationException();
    }

    static wstring unescape(wstring s)
    {
        auto len = s.length;
        if (len == 0)
            return s;
        wstring result;
        for (auto i = 0; i < len; i++)
        {
            if (s[i] == '\\')
            {
                i++;
                if (i < len)
                    result ~= s[i];
            }
            else if (s[i] == '\'')
            {
                if (result is null)
                    result = s[0 .. i];
            }
            else if (result !is null)
                result ~= s[i];
        }
        return result is null ? s : result;
    }

    static int indexOfPart(wstring format, int start, wstring parts)
    {
        bool verbatim;
        auto len = format.length;
        for(auto i = start; i < format.length; i++)
        {
            wchar c = format[i];
            if (!verbatim && parts.IndexOf(c) >= 0)
                return i;
            if (c == '\'')
                verbatim = !verbatim;
            else if (c == '\\')
            {
                if (i < len - 1)
                    c = format[++i];
                if (c != '\'' && c != '\\')
                    i--;
            }
        }
        return -1;
    }

    static wstring findSeparator(wstring format, wstring parts)
    {
        auto i = indexOfPart(format, 0, parts);
        if (i < 0)
            return null;
        wchar part = format[i++];
        auto len = format.length;
        while (i < len && format[i] == part)
            i++;
        auto j = i;
        if (j >= len)
            return null;
        i = indexOfPart(format, j, parts);
        if (i < 0)
            return null;
        return unescape(format[j .. i]);
    }

    static wstring[] combineDateTimePatterns(wstring[] datePatterns, wstring[] timePatterns)
    {
        wstring[] result = new wstring[datePatterns.length * timePatterns.length];
        int k = 0;
        for (int i = 0; i < datePatterns.length; i++)
            for (int j = 0; j < timePatterns.length; j++)
                result[k++] = datePatterns[i] ~ ' ' ~ timePatterns[i];
        return result;
    }

    static wstring[] zipPatterns(wstring[]s)
    {
        int[wstring] hash;
        foreach(i; s)
            hash[i] = 0;
        return hash.keys;
    }

    this(LocaleData data, Calendar calendar, bool isReadOnly)
    {
        _data = data;
        _isReadOnly = isReadOnly;
        _calData = data.getCalendarData(calendar.getCalID());
        _calendar = calendar;
    }

    void clearCache(bool includingLocale)
    {
        _abbreviatedDayNames = null;
        _dayNames = null;
        _abbreviatedMonthNames = null;
        _abbreviatedGenitiveMonthNames = null;
        _monthNames = null;
        _genitiveMonthNames = null;
        _eraNames = null;
        _abbreviatedEraNames = null;
        _shortestDayNames = null;
        _shortDatePatterns = null;
        _longDatePatterns = null;
        _yearMonthPatterns = null;
        _shortDatePattern = null;
        _longDatePattern = null;
        _yearMonthPattern = null;
        _monthDayPattern = null;
        _dateSeparator = null;
        _fullDateTimePattern = null;
        if (includingLocale)
        {
            _amDesignator = null;
            _pmDesignator = null;
            _shortTimePatterns = null;
            _longTimePatterns = null;
            _shortTimePattern = null;
            _longTimePattern = null;
            _calendarWeekRule = -1;
            _timeSeparator = null;
            _firstDayOfWeek = -1;
        }
    }

    @property 
    wstring[] ShortDatePatterns()
    {
        if (_shortDatePatterns is null)
        {
            wstring[] patterns = _calData.getShortDateFormats();
            _shortDatePatterns = new wstring[patterns.length];
            for (int i = 0; i < patterns.length; i++)
                _shortDatePatterns[i] = patterns[i];
        }
        return _shortDatePatterns;
    }

    @property 
    wstring[] LongDatePatterns()
    {
        if (_longDatePatterns is null)
        {
            wstring[] patterns = _calData.getLongDateFormats();
            _longDatePatterns = new wstring[patterns.length];
            for (int i = 0; i < patterns.length; i++)
                _longDatePatterns[i] = patterns[i];
        }
        return _longDatePatterns;
    }

    @property 
    wstring[] ShortTimePatterns()
    {
        if (_shortTimePatterns is null)
        {
            wstring[] patterns = _data.getShortTimeFormats();
            _shortTimePatterns = new wstring[patterns.length];
            for (int i = 0; i < patterns.length; i++)
                _shortTimePatterns[i] = patterns[i];
        }
        return _shortTimePatterns;
    }

    @property 
    wstring[] LongTimePatterns()
    {
        if (_longTimePatterns is null)
        {
            wstring[] patterns = _data.getLongTimeFormats();
            _longTimePatterns = new wstring[patterns.length];
            for (int i = 0; i < patterns.length; i++)
                _longTimePatterns[i] = patterns[i];
        }
        return _longTimePatterns;
    }

    @property 
    wstring[] YearMonthPatterns()
    {
        if (_yearMonthPatterns is null)
        {
            wstring[] patterns = _calData.getYearMonthFormats();
            _yearMonthPatterns = new wstring[patterns.length];
            for (int i = 0; i < patterns.length; i++)
                _yearMonthPatterns[i] = patterns[i];
        }
        return _yearMonthPatterns;
    }

    

public:

    enum SortableDateTimePattern = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"w;
    enum UniversalSortableDateTimePattern = "yyyy'-'MM'-'dd HH':'mm':'ss'Z'"w;
    enum RFC1123Pattern = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";

    this()
    {
        //this(LocaleData.invariant_, new GregorianCalendar(), false);
        //todo
    }

    Object Clone() 
    {
        DateTimeFormatInfo d = cast(DateTimeFormatInfo)MemberwiseClone();
        d._isReadOnly = false;
        if (_isReadOnly)
            d._calendar = cast(Calendar)(_calendar.Clone());      
        return d;
    }

    static DateTimeFormatInfo ReadOnly(DateTimeFormatInfo dfi)
    {
        checkNull(dfi, "dfi");
        DateTimeFormatInfo d = cast(DateTimeFormatInfo)dfi.Clone();
        d._isReadOnly = true;
        return d;
    }

    static DateTimeFormatInfo GetInstance(IFormatProvider provider)
    {
        CultureInfo ci = cast(CultureInfo)provider;
        if (ci !is null)
            return ci.DateTimeFormat;
        DateTimeFormatInfo dfi = cast(DateTimeFormatInfo)provider;
        if (dfi !is null)
            return dfi;

        if (provider !is null)
            return cast(DateTimeFormatInfo)(provider.GetFormat(typeid(DateTimeFormatInfo)));
        return null;
    }

    wstring GetAbbreviatedDayName(DayOfWeek day)
    {
        checkEnum(day, "day");
        return AbbreviatedDayNames[day];
    }

    wstring GetDayName(DayOfWeek day)
    {
        checkEnum(day, "day");
        return DayNames[day];
    }

    Object GetFormat(TypeInfo type)
    {
        return type == typeid(this) ? this : null;
    }

    @property Calendar Calendar_() 
    {
        return _calendar;
    }

    @property Calendar Calendar_(Calendar value)
    {
        checkWriteable();
        checkNull(value);
        if (_calendar == value)
            return _calendar;
        CalendarData cd = _data.getCalendarData(value.getCalID());
        checkNull(cd);
        _calData = cd;
        _calendar = value;
        clearCache(false);
        return _calendar;
    }

    @property wstring[] AbbreviatedDayNames()
    {
        if (_abbreviatedDayNames is null || _abbreviatedDayNames.length == 0)
        {
            _abbreviatedDayNames = new wstring[7];
            for (int i = 0; i < 7; i++)
                _abbreviatedDayNames[i] = _calData.getDayName(i, true);
        }
        return _abbreviatedDayNames;
    }

    @property wstring[] AbbreviatedDayNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 7)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _abbreviatedDayNames = value;
        return _abbreviatedDayNames;
    }

    @property wstring[] DayNames()
    {
        if (_dayNames is null || _dayNames.length == 0)
        {
            _dayNames = new wstring[7];
            for (int i = 0; i < 7; i++)
                _dayNames[i] = _calData.getDayName(i, false);
        }
        return _dayNames;
    }

    @property wstring[] DayNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 7)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _dayNames = value;
        return _dayNames;
    }

    @property wstring[] ShortestDayNames()
    {
        if (_shortestDayNames is null || _shortestDayNames.length == 0)
        {
            _shortestDayNames = new wstring[7];
            for (int i = 0; i < 7; i++)
                _shortestDayNames[i] = _calData.getShortestDayName(i);
        }
        return _shortestDayNames;
    }

    @property wstring[] ShortestDayNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 7)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _shortestDayNames = value;
        return _shortestDayNames;
    }

    @property wstring[] AbbreviatedMonthNames()
    {
        if (_abbreviatedMonthNames is null || _abbreviatedMonthNames.length == 0)
        {
            _abbreviatedMonthNames = new wstring[13];
            for (int i = 0; i < 13; i++)
                _abbreviatedMonthNames[i] = _calData.getMonthName(i, true);
        }
        return _abbreviatedMonthNames;
    }

    @property wstring[] AbbreviatedMonthNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 13)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _abbreviatedMonthNames = value;
        return _abbreviatedMonthNames;
    }

    @property wstring[] AbbreviatedMonthGenitiveNames()
    {
        if (_abbreviatedGenitiveMonthNames is null || _abbreviatedGenitiveMonthNames.length == 0)
        {
            _abbreviatedGenitiveMonthNames = new wstring[13];
            for (int i = 0; i < 13; i++)
                _abbreviatedGenitiveMonthNames[i] = _calData.getGenitiveMonthName(i, true);
        }
        return _abbreviatedGenitiveMonthNames;
    }

    @property wstring[] AbbreviatedMonthGenitiveNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 13)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _abbreviatedGenitiveMonthNames = value;
        return _abbreviatedGenitiveMonthNames;
    }

    @property wstring[] MonthNames()
    {
        if (_monthNames is null || _monthNames.length == 0)
        {
            _monthNames = new wstring[13];
            for (int i = 0; i < 13; i++)
                _monthNames[i] = _calData.getMonthName(i, false);
        }
        return _monthNames;
    }

    @property wstring[] MonthNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 13)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _monthNames = value;
        return _monthNames;
    }

    @property wstring[] MonthGenitiveNames()
    {
        if (_genitiveMonthNames is null || _genitiveMonthNames.length == 0)
        {
            _genitiveMonthNames = new wstring[13];
            for (int i = 0; i < 13; i++)
                _genitiveMonthNames[i] = _calData.getGenitiveMonthName(i, false);
        }
        return _genitiveMonthNames;
    }

    @property wstring[] MonthGenitiveNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        if (value.length != 13)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _genitiveMonthNames = value;
        return _genitiveMonthNames;
    }

    @property wstring[] EraNames()
    {
        if (_eraNames is null || _eraNames.length == 0)
        {
            wstring[] names = _calData.getEraNames(false);
            _eraNames = new wstring[names.length];
            for (int i = 0; i < names.length; i++)
                _eraNames[i] = names[i];
        }
        return _eraNames;
    }

    @property wstring[] EraNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        int len = _eraNames.length == 0 ? _calData.getEraNames(false).length : _eraNames.length;
        if (value.length != len)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _eraNames = value;
        return _eraNames;
    }

    @property wstring[] AbbreviatedEraNames()
    {
        if (_abbreviatedEraNames is null || _abbreviatedEraNames.length == 0)
        {
            auto names = _calData.getEraNames(true);
            _abbreviatedEraNames = new wstring[names.length];
            for (int i = 0; i < names.length; i++)
                _abbreviatedEraNames[i] = names[i];
        }
        return _abbreviatedEraNames;
    }

    @property wstring[] AbbreviatedEraNames(wstring[] value)
    {
        checkWriteable();
        checkNull(value);
        int len = _abbreviatedEraNames.length == 0 ? _calData.getEraNames(false).length : _abbreviatedEraNames.length;
        if (value.length != len)
            throw new ArgumentException(null, "value");
        foreach(v; value)
            checkNull(v);
        _abbreviatedEraNames = value;
        return _abbreviatedEraNames;
    }

    wstring GetAbbreviatedEraName(int era)
    {
        checkRange(era, 1, AbbreviatedEraNames.length, "era");
        return _abbreviatedEraNames[era - 1];
    }

    wstring GetEraName(int era)
    {
        checkRange(era, 1, EraNames.length, "era");
        return _eraNames[era - 1];
    }

    int GetEra(wstring name)
    {
        checkNull(name, "name");
        if (name.length == 0)
            return -1;
        foreach(i, m; EraNames)
            if (_data.compare(m, name, CompareOptions.IgnoreCase))
                return i;
        foreach(i, m; AbbreviatedEraNames)
            if (_data.compare(m, name, CompareOptions.IgnoreCase))
                return i;
        return -1;
        //todo english names
    }

    wstring GetAbbreviatedMonthName(int month)
    {
        checkRange(month, 1, 12, "month");
        return AbbreviatedMonthNames[month];
    }

    @property 
    wstring AMDesignator()
    {
        if (_amDesignator is null)
            _amDesignator = _data.s1159;
        return _amDesignator;
    }

    @property
    wstring AMDesignator(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _amDesignator = value;
    }

    @property
    wstring PMDesignator()
    {
        if (_pmDesignator is null)
            _pmDesignator = _data.s2359;
        return _pmDesignator;
    }

    @property
    wstring PMDesignator(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _pmDesignator = value;
    }  

    @property 
    wstring ShortDatePattern()
    {
        if (_shortDatePattern is null)
            _shortDatePattern = ShortDatePatterns[0];
        return _shortDatePattern;
    }

    @property 
    wstring ShortDatePattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _shortDatePattern = value;
    }

    @property 
    wstring LongDatePattern()
    {
        if (_longDatePattern is null)
            _longDatePattern = LongDatePatterns[0];
        return _longDatePattern;
    }

    @property 
    wstring LongDatePattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        _fullDateTimePattern = null;
        return _longDatePattern = value;
    }

    @property
    wstring ShortTimePattern()
    {
        if (_shortTimePattern is null)
            _shortTimePattern = ShortTimePatterns[0];
        return _shortTimePattern;
    }

    @property 
    wstring shortTimePattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _shortTimePattern = value;
    }

    @property wstring LongTimePattern()
    {
        if (_longTimePattern is null)
            _longTimePattern = LongTimePatterns[0];
        _fullDateTimePattern = null;
        return _longTimePattern;
    }

    @property wstring LongTimePattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _longTimePattern = value;
    }

    @property 
    CalendarWeekRule CalendarWeekRule_()
    {
        if (_calendarWeekRule < 0)
            _calendarWeekRule = _data.iFirstWeekOfYear;
        return cast(CalendarWeekRule)_calendarWeekRule;
    }

    @property 
    CalendarWeekRule CalendarWeekRule_(CalendarWeekRule value)
    {
        checkWriteable();
        checkEnum(value);
        return cast(CalendarWeekRule)(_calendarWeekRule = value);
    }

    @property DateTimeFormatInfo CurrentInfo()
    {
        auto culture = CultureInfo.CurrentCulture;
        DateTimeFormatInfo dtf = culture.DateTimeFormat;
        if (dtf is null)
            dtf = cast(DateTimeFormatInfo)culture.GetFormat(typeid(DateTimeFormatInfo));
        return dtf;
    }

    @property 
    wstring DateSeparator()
    {
        if (_dateSeparator is null)
            _dateSeparator = findSeparator(ShortDatePattern, "dyM");
        return _dateSeparator;
    }

    @property wstring DateSeparator(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _dateSeparator = value;
    }

    @property 
    DayOfWeek FirstDayOfWeek()
    {
        if (_firstDayOfWeek < 0)
            _firstDayOfWeek = _data.iFirstDayOfWeek;
        return cast(DayOfWeek)_firstDayOfWeek;
    }

    @property 
    DayOfWeek FirstDayOfWeek(DayOfWeek value)
    {
        checkWriteable();
        checkEnum(value);
        return cast(DayOfWeek)(_firstDayOfWeek = value);
    }

    @property 
    wstring FullDateTimePattern()
    {
        if (_fullDateTimePattern is null)
            _fullDateTimePattern = LongDatePattern ~ ' ' ~ LongTimePattern;
        return _fullDateTimePattern;
    }

    @property
    wstring FullDateTimePattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _fullDateTimePattern = value;
    }

    @property 
    DateTimeFormatInfo InvariantInfo()
    {
        if (_invariantInfo is null)
            _invariantInfo = ReadOnly(new DateTimeFormatInfo());
        return _invariantInfo;
    }

    @property pure @safe nothrow @nogc
    bool IsReadOnly()
    {
        return _isReadOnly;
    }

    @property 
    wstring TimeSeparator()
    {
        if (_timeSeparator is null)
            _timeSeparator = findSeparator(ShortTimePattern, "hHms");
        return _timeSeparator;
    }

    @property 
    wstring TimeSeparator(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _timeSeparator = value;
    }

    @property 
    wstring YearMonthPattern()
    {
        if (_yearMonthPattern is null)
            _yearMonthPattern = YearMonthPatterns[0];
        return _yearMonthPattern;
    }

    @property 
    wstring YearMonthPattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _yearMonthPattern = value;
    }

    @property 
    wstring MonthDayPattern()
    {
        if (_monthDayPattern is null)
            _monthDayPattern = _calData.getMonthDayFormat();
        return _monthDayPattern;
    }

    @property 
    wstring MonthDayPattern(wstring value)
    {
        checkWriteable();
        checkNull(value);
        return _monthDayPattern = value;
    }

    wstring[] GetAllDateTimePatterns()
    {
        wstring[] result;
        for (int i = 0; i < DateFormatter.dateTimeFormats.length; i++)
            result ~= GetAllDateTimePatterns(DateFormatter.dateTimeFormats[i]);
        return zipPatterns(result);
    }

    wstring[] GetAllDateTimePatterns(wchar format)
    {
        switch(format)
        {
            case 'd': 
                return zipPatterns(ShortDatePatterns ~ ShortDatePattern);
            case 'D':
                return zipPatterns(LongDatePatterns ~ LongDatePattern);
            case 'f':
                return zipPatterns(combineDateTimePatterns(LongDatePatterns ~ LongDatePattern, ShortTimePatterns ~ ShortTimePattern));
            case 'F':
            case 'U':
                return zipPatterns(combineDateTimePatterns(LongDatePatterns ~ LongDatePattern, LongTimePatterns ~ LongTimePattern));
            case 'g':
                return zipPatterns(combineDateTimePatterns(ShortDatePatterns ~ ShortDatePattern, ShortTimePatterns ~ ShortTimePattern));
            case 'G':
                return zipPatterns(combineDateTimePatterns(ShortDatePatterns ~ ShortDatePattern, LongTimePatterns ~ LongTimePattern));
            case 'm':
            case 'M':
                return [MonthDayPattern];
            case 'o':
            case 'O':
                return [DateFormatter.roundtripFormat];
            case 'r':
            case 'R':
                return [RFC1123Pattern];
            case 's':
                return [SortableDateTimePattern];
            case 't':
                return zipPatterns(ShortTimePatterns ~ ShortTimePattern);
            case 'T':
                return zipPatterns(LongTimePatterns ~ LongTimePattern);
            case 'u':
                return [UniversalSortableDateTimePattern];
            case 'y':
            case 'Y':
                return zipPatterns(YearMonthPatterns ~ YearMonthPattern);
            default:
                throw new ArgumentException(null, "format");
        }
    }

    wstring GetMonthName(int month)
    {
        checkRange(month, 1, 13, "month");
        return MonthNames[month];
    }

    wstring GetShortestDayName(DayOfWeek dayOfWeek)
    {
        checkEnum(dayOfWeek, "dayOfWeek");
        return ShortestDayNames[dayOfWeek];
    }

    void SetAllDateTimePatterns(wstring[] patterns, wchar format)
    {
        checkWriteable();
        checkNull(patterns, "patterns");
        if (patterns.length == 0)
            throw new ArgumentException(null, "patterns");
        for (int i = 0; i < patterns.length; i++)
            checkNull(patterns[i], "patterns");
        switch(format)
        {
            case 'd':
                _shortDatePatterns = patterns;
                _shortDatePattern = null;
                break;
            case 'D':
                _longDatePatterns = patterns;
                _longDatePattern = null;
                break;
            case 't':
                _shortTimePatterns = patterns;
                _shortTimePattern = null;
                break;
            case 'T':
                _longTimePatterns = patterns;
                _longTimePattern = null;
                break;
            case 'y':
            case 'Y':
                _yearMonthPatterns = patterns;
                _yearMonthPattern = null;
                break;
            default:
                throw new ArgumentException(null, "format");
        }
    }

    @property
    wstring NativeCalendarName()
    {
        if (_nativeCalendarName is null)
            _nativeCalendarName = _calData.sCalName;
        return _nativeCalendarName;
    }

}

// =====================================================================================================================
// DaylightTime
// =====================================================================================================================

class DaylightTime
{
private:
    DateTime start;
    DateTime end;
    TimeSpan delta;

public:
    pure @safe nothrow
    private this() { }

    pure @safe nothrow
    public this(DateTime start, DateTime end, TimeSpan delta) 
    {
        this.start = start;
        this.end = end;
        this.delta = delta;
    }    

    @property pure @safe nothrow
    public DateTime Start()
    {
        return start;
    }

    @property pure @safe nothrow
    public DateTime End()
    {
        return end;
    }

    @property pure @safe nothrow
    public TimeSpan Delta()
    {
        return delta;
    }

}