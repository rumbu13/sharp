module internals.number;

import system;
import system.globalization;

import internals.utf;
import internals.checked;
import internals.traits;

import core.stdc.math;

template prec(T) if (isAnyIntegral!T)
{
    static if (T.sizeof == 1)
        enum prec = 3;
    else static if (T.sizeof == 2)
        enum prec = 5;
    else static if (T.sizeof == 4)
        enum prec = 10;
    else static if (isUnsigned!T)
        enum prec = 20;
    else
        enum prec = 19;
}

template prec(T) if (isAnyFloat!T)
{
    enum prec = T.dig;
}

template prec(T) if (is(T == decimal))
{
    enum prec = 29;
}

struct Number
{
    ulong hi;
    ulong lo;
    int scale;
    bool isNegative;
    bool isNAN;
    bool isInfinite;
    bool isDecimal;
    int precision;
    int length;


    static immutable wstring[] numberNegativeFormat =
    ["(#)", "-#", "- #", "#-", "# -"];
    static immutable wstring[] currencyNegativeFormat =
    ["($#)", "-$#", "$-#", "$#-", "(#$)", "-#$", "#-$", "#$-", "-# $", "-$ #", "# $-", "$ #-", "$ -#", "#- $", "($ #)", "(# $)"];
    static immutable wstring[] currencyPositiveFormat =
    ["$#", "#$", "$ #", "# $"];
    static immutable wstring[] percentNegativeFormat =
    ["-# %", "-#%", "-%#", "%-#", "%#-", "#-%", "#%-", "-% #", "# %-", "% #-", "% -#", "#- %"];
    static immutable wstring[] percentPositiveFormat =
    ["# %", "#%", "%#", "% #"];

    pure @safe nothrow @nogc
    ubyte opIndex(in size_t index)
    {
        assert(index <= 31);
        if (index < 16)
            return cast(ubyte)(lo >> (index * 4)) & 0xf;
        return cast(ubyte)(hi >> ((index - 16) * 4)) & 0xf;
    }

    pure @safe nothrow @nogc
    void opIndexAssign(in ubyte value, in size_t index)
    {
        assert(index <= 31);
        assert (value <= 9);
        if (index < 16)
        {
            ulong bitmask = cast(ulong)0xf << (index * 4);
            ulong v = cast(ulong)(value) << (index * 4);
            lo = lo & (~bitmask) | v;
        }
        else
        {
            ulong bitmask = cast(ulong)0xf << ((index - 16) * 4);
            ulong v = cast(ulong)(value) << ((index - 16) * 4);
            hi = hi & (~bitmask) | v;
        }
    }

    pure @safe nothrow @nogc
    this(T)(in T value) if (isAnyIntegral!T)
    {
        isNegative = value < 0;
        precision = prec!T;
        Unsigned!T u = isNegative ? -value : value;
        while(u != 0)
        {
            static if (prec!T > 16)
            {
                hi <<= 4;
                hi |= (lo >> 60);
            }
            lo <<= 4;
            lo |= u % 10;         
            u /= 10;
            scale++;
        }
        length = scale;
    }

    pure @safe nothrow @nogc
    static ubyte divdec10(ref uint lo, ref uint mi, ref uint hi)
    {
        uint Remainder;
        if (hi != 0)
        {
            Remainder = hi % 10;
            hi = hi / 10;            
        }

        if (mi != 0 || Remainder != 0)
        {
            ulong n = (cast(ulong)Remainder << 32) | mi;
            Remainder = n % 10;
            mi = cast(uint)(n / 10);
        }
        if (lo != 0 || Remainder != 0)
        {
            ulong n = (cast(ulong)Remainder << 32) | lo;
            Remainder = n % 10;
            lo = cast(uint)(n / 10);
        }
        return cast(ubyte)Remainder;
    }

    this(in decimal d)
    {
        isDecimal = true;
        precision = prec!decimal;
        uint[] bits = cast(uint[])decimal.GetBits(d);
        if (bits[0] == 0 && bits[1] == 0 && bits[2] == 0)
        {
            length = 0;
            return;
        }
        isNegative = (bits[3] & 0x80000000) != 0;
        scale = (bits[3] & 0x00FF0000) >> 16;
        while (bits[0] != 0 || bits[1] != 0 || bits[2] != 0)
        {
            ubyte b = divdec10(bits[0], bits[1], bits[2]);
            hi <<= 4;
            hi |= (lo >> 60);
            lo <<= 4;
            lo |= b;         
            length++;
        }      
        scale = length - scale;
    }


    this(T)(T f) if (isAnyFloat!T)
    {
        static if (is(T == real))
            alias mod = modfl;
        else static if (is(T == double))
            alias mod = modf;
        else
            alias mod = modff;

        isNAN = isnan(f) != 0;
        isInfinite = isinf(f) != 0;
        precision = prec!T;
        if (f < 0)
        {
            f = -f;
            isNegative = true;
        }

        if (isNAN || isInfinite)
            return;


        T fi, fj;
        f = mod(f, &fi);
        if (fi != 0)
        {
            while (fi != 0)
            {
                fj = mod(fi / 10, &fi);
                hi <<= 4u;
                hi |= (lo >> 60u);
                lo <<= 4;                   
                ubyte u = cast(ubyte)((fj + 0.03) * 10);
                lo |= u;     
                scale++;         
            }
        }
        else if (f > 0)
        {
            fj = f * 10;
            while (fj < 1) 
            {
                f = fj;
                fj = f * 10;
                scale--;
            }
        }

        auto decimals = scale >= 0 ? 32 - scale : 32;
        if (decimals > 0)
        {
            auto index = 32 - decimals;
            while (index < 32)
            {
                f *= 10;
                f = mod(f, &fj);
                ubyte u = cast(ubyte)fj;                
                if (index < 16)
                    lo |= cast(ulong)u << (index * 4);
                else
                    hi |= cast(ulong)u << ((index - 16) * 4);
                index++;
            }
        }

        length = 32;
    }


    void Round(int digits)
    {
        if (isNAN || isInfinite)
            return;
        int i = digits < length ? digits : length;
        if (i == digits && this[i] >= 0x5)
        {
            while (i > 0 && this[i - 1] == 0x9)
                i--;
            if (i > 0)
            {
                ubyte u = cast(ubyte)(this[i-1] + 1);
                this[i-1] = u;
            }
            else
            {
                scale++;
                this[0] = 0x1;
                i = 1;
            }
        }
        else
        {
            while (i > 0 && this[i - 1] == 0x0)
                i--;
        }
        if (i == 0)
        {
            scale = 0;
            isNegative = false;
        }
        length = i;
    }

    wstring getPatterned(int digits, wstring pattern,
                        wstring  decSeparator, wstring groupSeparator, 
                        wstring negSymbol, wstring CurrencySymbol, wstring PercentSymbol, 
                        int[] groupSizes, wstring[] dig)
    {
        int i = 0;
        wstring ret;
        while (i < pattern.length)
        {
            wchar c = pattern[i++];
            switch(c)
            {
                case '-':
                    ret ~= negSymbol;
                    break;
                case '$':
                    ret ~= CurrencySymbol;
                    break;
                case '%':
                    ret ~= PercentSymbol;
                    break;
                case '#':
                    ret ~= getFixed(digits, groupSizes, decSeparator, groupSeparator, dig);
                    break;
                default:
                    ret ~= c;
                    break;
            }
        }
        return ret;
    }

    wstring toCurrency(int digits, NumberFormatInfo nfi, bool isNativeContext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;

        if (digits < 0) digits = nfi.CurrencyDecimalDigits; 

        Round(scale + digits);

        wstring[] dig = getDigits(nfi, isNativeContext);

        if (isNegative)
            return getPatterned(digits,
                                nfi.CurrencyNegativePattern < currencyNegativeFormat.length ? currencyNegativeFormat[nfi.CurrencyNegativePattern] : currencyNegativeFormat[0],
                                nfi.CurrencyDecimalSeparator, nfi.CurrencyGroupSeparator,
                                nfi.NegativeSign, nfi.CurrencySymbol, nfi.PercentSymbol,
                                nfi.CurrencyGroupSizes, dig);
        else
            return getPatterned(digits,
                                nfi.CurrencyPositivePattern < currencyPositiveFormat.length ? currencyPositiveFormat[nfi.CurrencyPositivePattern] : currencyPositiveFormat[0],
                                nfi.CurrencyDecimalSeparator, nfi.CurrencyGroupSeparator,
                                nfi.NegativeSign, nfi.CurrencySymbol, nfi.PercentSymbol,
                                nfi.CurrencyGroupSizes, dig);
    }

    static wstring getExponent(int value, wchar expSym, int digits, NumberFormatInfo nfi, bool isNativeContext)
    {
        wstring ret = [expSym];
        if (value < 0)
        {
            value = -value;
            ret ~= '-';
        }
        else
            ret ~= '+';
        return ret ~ intToDec!int(value, digits, nfi, isNativeContext);
    }

    wstring toExponential(int digits, NumberFormatInfo nfi, wchar expSym, bool isNativeContext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;

        if (digits < 0)
            digits = 6;
        digits++;
        Round(digits);
        wstring ret = isNegative ? nfi.NegativeSign : null;
        auto dig = getDigits(nfi, isNativeContext);
        int j = 0;
        ret ~= length == 0 ? dig[0] : dig[this[j++]]; 
        if (digits != 1)
            ret ~= nfi.NumberDecimalSeparator;
        while (--digits > 0)
            ret ~= j < length ? dig[this[j++]] : dig[0];
        int e = j <= length ? scale - 1 : 0;
        ret ~= getExponent(e, expSym, 3, nfi, isNativeContext);
        return ret;
    }

    wstring getFixed(int digits, int[] grouping, wstring dec, wstring grp, wstring[] dig)
    {
        wstring ret;
        int digPos = scale;
        int j = 0;

        if (digPos <= 0)
            ret ~= dig[0];
        else
        {
            if (grouping is null || grouping.length == 0)
            {
                do
                {
                    ret ~= j < length ? dig[this[j++]] : dig[0];
                }
                while (--digPos > 0);
            }
            else
            {
                int index = 0;
                int count = grouping[index];
                int len = safe32bit(grouping.length);
                int sepLen = safe32bit(grp.length);
                int size = 0;

                while (digPos > count)
                {
                    size = grouping[index];
                    if (size == 0)
                        break;
                    if (index < len - 1)
                        index++;
                    count += grouping[index];
                    if (count < 0)
                        throw new ArgumentOutOfRangeException();
                }

                size = count == 0 ? 0 : grouping[0];

                index = 0;
                int digount = 0;
                int digLen = length;
                int digStart = digPos < digLen ? digPos : digLen;
                for (int i = digPos - 1; i >= 0; i--)
                {
                    ret = (i < digStart ? dig[this[i]] : dig[0]) ~ ret;
                    if (size > 0)
                    {
                        digount++;
                        if (digount == size && i != 0)
                        {
                            ret = grp ~ ret;
                            if (index < len - 1)
                            {
                                index++;
                                size = grouping[index];
                            }
                            digount = 0;
                        }
                    }
                }
                j += digStart;
            }
        }

        if (digits > 0)
        {
            ret ~= dec;
            while (digPos < 0 && digits > 0) 
            {
                ret ~= dig[0];
                digPos++;
                j--;
            }

            while (digits > 0) 
            {
                ret ~= j < length ? dig[this[j++]] : dig[0];
                digits--;
            }
        }

        return ret;
    }

    wstring toFixed(int digits, NumberFormatInfo nfi, bool isNativeContext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;

        if (digits < 0) 
            digits = nfi.NumberDecimalDigits;

        Round(scale + digits);

        auto dig = getDigits(nfi, isNativeContext);
        wstring ret = isNegative ? nfi.NegativeSign : null;
        return ret ~ getFixed(digits, null, nfi.NumberDecimalSeparator, null, dig);
    }

    wstring toGeneral(int digits, NumberFormatInfo nfi, wchar expSym, bool isNativeContext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;

        if (digits < 1)
        {
            //if (digits < 0 && isDecimal)
            //    digits = prec!decimal;
            //else
                digits = precision;
        }

        Round(digits);

        auto dig = getDigits(nfi, isNativeContext);
        wstring ret = isNegative ? nfi.NegativeSign : null;


        int decimalPos = scale;
        bool useScientific = !isDecimal && (decimalPos > digits || decimalPos < -3);
        if (useScientific)
            decimalPos = 1;
        int j = 0;
        if (decimalPos > 0)
        {
            do
            {
                ret ~= j < length ? dig[this[j++]] : dig[0];
            } 
            while (--decimalPos > 0);
        }
        else
            ret ~= dig[0];

        if (j < length || decimalPos < 0)
        {
            ret ~= nfi.NumberDecimalSeparator;
            while (decimalPos++ < 0) 
                ret ~= dig[0];
            while (j < length)
                ret ~= dig[this[j++]];
        }
        if (useScientific)
            ret ~= getExponent(scale - 1, expSym, 2, nfi, isNativeContext);
        return ret;
    }

    wstring toNumeric(int digits, NumberFormatInfo nfi, bool isNativeContext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;

        if (digits < 0) digits = nfi.NumberDecimalDigits; 

        Round(scale + digits);

        auto dig = getDigits(nfi, isNativeContext);

        if (isNegative)
        {
            return getPatterned(digits,
                                nfi.NumberNegativePattern < numberNegativeFormat.length ? numberNegativeFormat[nfi.NumberNegativePattern] : numberNegativeFormat[0],
                                nfi.NumberDecimalSeparator, nfi.NumberGroupSeparator,
                                nfi.NegativeSign, nfi.CurrencySymbol, nfi.PercentSymbol,
                                nfi.NumberGroupSizes, dig);
        }
        else
            return getFixed(digits, nfi.NumberGroupSizes, nfi.NumberDecimalSeparator, nfi.NumberGroupSeparator, dig);
    }

    wstring toPercent(int digits, NumberFormatInfo nfi, bool isNativeontext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;

        scale += 2;

        if (digits < 0) digits = nfi.PercentDecimalDigits; 

        Round(scale + digits);

        auto dig = getDigits(nfi, isNativeontext);

        if (isNegative)
            return getPatterned(digits,
                                nfi.PercentNegativePattern < percentNegativeFormat.length ? percentNegativeFormat[nfi.PercentNegativePattern] : percentNegativeFormat[0],
                                nfi.PercentDecimalSeparator, nfi.PercentGroupSeparator,
                                nfi.NegativeSign, nfi.CurrencySymbol, nfi.PercentSymbol,
                                nfi.PercentGroupSizes, dig);
        else
            return getPatterned(digits,
                                nfi.PercentPositivePattern < percentPositiveFormat.length ? percentPositiveFormat[nfi.PercentPositivePattern] : percentPositiveFormat[0],
                                nfi.PercentDecimalSeparator, nfi.PercentGroupSeparator,
                                nfi.NegativeSign, nfi.CurrencySymbol, nfi.PercentSymbol,
                                nfi.PercentGroupSizes, dig);
    }

    wstring toString(wchar fmt, int digits, NumberFormatInfo nfi, bool isNativeContext)
    {
        switch(fmt)
        {
            case 'c':
            case 'C':
                return toCurrency(digits, nfi, isNativeContext);
            case 'e':
            case 'E':
                return toExponential(digits, nfi, fmt, isNativeContext);
            case 'f':
            case 'F':
                return toFixed(digits, nfi, isNativeContext);
            case 'g':
            case 'G':
                return toGeneral(digits, nfi, fmt == 'g' ? 'e' : 'E', isNativeContext);
            case 'n':
            case 'N':
                return toNumeric(digits, nfi, isNativeContext);
            case 'p':
            case 'P':
                return toPercent(digits, nfi, isNativeContext);
            default:
                throw new FormatException();
        }
    }

    static void getCustomPatterns(wstring fmt, out wstring positive, out wstring negative, out wstring zero)
    {
        auto sectionStart = 0;
        auto section = 0;
        auto i = 0;
        auto len = fmt.length;
        while (i < len)
        {
            wchar c = fmt[i++];
            switch(c)
            {
                case ';':
                    if (section == 0)
                        positive = fmt[sectionStart .. i - 1];
                    else if (section == 1)
                    {
                        negative = fmt[sectionStart .. i - 1];
                        if (i < len)
                            zero = fmt[i .. $];
                        return;
                    }
                    section++;
                    sectionStart = i;
                    break;
                case '\\':
                    i++;
                    break;
                case '\'':
                case '\"':
                    while (i < len && fmt[i] != c)
                        i++;
                    i++;
                    break;
                default:
                    break;
            }
        }

        if (section == 0)
            positive = fmt; 
        else
            negative = fmt[sectionStart .. $];

    }

    struct CustomFormat
    {
        int digitount;
        int firstDigit = -1;
        int lastDigit = -1;
        int decimalPos = -1;
        int scaling;
        bool exponential;
        bool grouping;

        this(wstring pattern)
        {
            int commaPos = -1;
            int len = safe32bit(pattern.length);
            int commas;
            int i = 0;
            while (i < len)
            {
                wchar c = pattern[i++];
                switch(c)
                {
                    case '#':
                        digitount++;
                        break;
                    case '0':
                        if (firstDigit < 0)
                            firstDigit = digitount;
                        lastDigit = ++digitount;
                        break;
                    case '.':
                        if (decimalPos < 0)
                            decimalPos = digitount;
                        break;
                    case '\'':
                    case '"':
                        while (i < len && pattern[i] != c)
                            i++;
                        i++;
                        break;
                    case '\\':
                        if (i < len)
                            i++;
                        break;
                    case 'e':
                    case 'E':
                        if (i < len)
                        {
                            if (pattern[i] == '+' || pattern[i] == '-')
                                i++;
                            if (i < len && pattern[i] == '0')
                            {
                                while (i < len && pattern[i] == '0')
                                    i++;
                                exponential = true;
                            }
                        }
                        break;
                    case ',':
                        if (digitount > 0 && decimalPos < 0)
                        {
                            if (commaPos >= 0)
                            {
                                if (commaPos == digitount)
                                {
                                    commas++;
                                    break;
                                }
                                grouping = true;
                            }
                            commaPos = digitount;
                            commas = 1;
                        }
                        break;
                    case '%':
                        scaling += 2;
                        break;
                    case '‰':
                        scaling += 3;
                        break;
                    default:
                        break;
                }
            }
            if (decimalPos < 0)
                decimalPos = digitount;
            if (commaPos >= 0)
            {
                if (commaPos == decimalPos)
                    scaling -= commas * 3;
                else
                    grouping = true;
            }
        }

    }

    wstring toString(wstring fmt, NumberFormatInfo nfi, bool isNativeContext)
    {
        if (isNAN)
            return nfi.NanSymbol;
        if (isInfinite)
            return isNegative ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;
        wstring positivePattern;
        wstring negativePattern;
        wstring zeroPattern;
        getCustomPatterns(fmt, positivePattern, negativePattern, zeroPattern);
        wstring currentPattern;
        if (length == 0)
            currentPattern = zeroPattern;
        else
            currentPattern = isNegative && negativePattern.length > 0 ? negativePattern : positivePattern;
        auto f = CustomFormat(currentPattern);
        scale += f.scaling;

        if (length > 0)
        {
            scale += f.scaling;
            int digits = f.exponential ? f.digitount : scale + f.digitount - f.decimalPos;
            Round(digits);
            if (length == 0)
            {
                currentPattern = zeroPattern.length > 0 ? zeroPattern : positivePattern;
                f = CustomFormat(currentPattern);
                isNegative = false;
                scale = 0;
            }
        }

        f.firstDigit = f.firstDigit < f.decimalPos ? f.decimalPos - f.firstDigit : 0;
        f.lastDigit = f.lastDigit > f.decimalPos ? f.decimalPos - f.lastDigit : 0;

        int adjust = f.exponential ? 0 : scale - f.decimalPos;
        int pos = f.exponential ? f.decimalPos : (scale > f.decimalPos ? scale : f.decimalPos);

        int[] groupSeparators;

        if (f.grouping && nfi.NumberGroupSizes.length > 0)
        {
            int groupIndex;
            int groupTotalount = nfi.NumberGroupSizes[0];
            int groupSize = groupTotalount;
            int totalDigits = pos + (adjust < 0 ? adjust : 0);
            int numDigits = f.firstDigit > totalDigits ? f.firstDigit : totalDigits;
            while (numDigits > groupTotalount)
            {
                if (groupSize == 0)
                    break;
                groupSeparators ~= groupTotalount;
                if (groupIndex < nfi.NumberGroupSizes.length - 1)
                    groupSize = nfi.NumberGroupSizes[++groupIndex];
                groupTotalount += groupSize;
            }
        }
        else
            f.grouping = false;

        wstring ret;

        if (isNegative && String.IsNullOrEmpty(negativePattern))
            ret ~= nfi.NegativeSign;
        int len = safe32bit(currentPattern.length);
        int i = 0;
        int j = 0;
        int k = safe32bit(groupSeparators.length) - 1;

        auto dig = getDigits(nfi, isNativeContext);

        bool decimalWritten;

        while (i < len)
        {
            wchar c = currentPattern[i++];
            if (adjust > 0 && (c == '0' || c == '#' || c == '.'))
            {
                while (adjust > 0)
                {
                    ret ~= j < length ? dig[this[j++]] : dig[0];
                    if (f.grouping && pos > 1 && k >= 0)
                        if (pos == groupSeparators[k] + 1)
                        {
                            ret ~= nfi.NumberGroupSeparator;
                            k--;
                        }
                    pos--;
                    adjust--;
                }
            }

            switch(c)
            {
                case '0':
                case '#':
                    wstring s;
                    if (adjust < 0)
                    {
                        adjust++;
                        s = pos < f.firstDigit ? dig[0] : null;
                    }
                    else
                        s = j < length ? dig[this[j++]] : (pos > f.lastDigit ? dig[0] : null);
                    if (s.length > 0)
                    {
                        ret ~= s;
                        if (f.grouping && pos > 1 && k > 0)
                            if (pos == groupSeparators[k] + 1)
                            {
                                ret ~= nfi.NumberGroupSeparator;
                                k++;
                            }
                    }
                    pos--;
                    break;
                case '.':
                    if (pos != 0 || decimalWritten)
                        break;
                    if (f.lastDigit < 0 || (f.decimalPos < f.digitount))
                    {
                        ret ~= nfi.NumberDecimalSeparator;
                        decimalWritten = true;
                    }
                    break;
                case '%':
                    ret ~= nfi.PercentSymbol;
                    break;          
                case '‰':
                    ret ~= nfi.PermilleSymbol;
                    break;  
                case '\'':
                case '"':
                    int copyFrom = i;
                    while (i < len && currentPattern[i] != c)
                        i++;
                    ret ~= currentPattern[copyFrom .. i];
                    i++;
                    break;
                case '\\':
                    ret ~= currentPattern[i];
                    i++;
                    break;
                case 'e':
                case 'E':
                    wstring sgn;
                    int expDig;
                    if (f.exponential)
                    {
                        if (currentPattern[i] == '+')
                        {
                            sgn ~= nfi.PositiveSign;
                            i++;
                        }
                        else if (currentPattern[i] == '-')
                            i++;
                        while (i < len && currentPattern[i] == '0')
                        {
                            i++;
                            expDig++;
                        }
                        ret ~= getExponent(length == 0 ? 0 : scale - f.decimalPos, c, expDig, nfi, isNativeContext);
                        f.exponential = false;
                    }
                    else
                    {
                        int copyFrom = i;
                        if (i < len && (currentPattern[i] == '-' || currentPattern[i] == '+'))
                            i++;
                        while (i < len && currentPattern[i] == '0')
                            i++;
                        ret ~= currentPattern[copyFrom .. i];
                    }
                    break;
                case ',':
                    while (i < len && currentPattern[i] == ',')
                        i++;
                    break;
                default:
                    ret ~= c;
                    break;
            }
        }
        return ret;
    }
}

wchar parseFormatSpecifier(wstring fmt, out int digits)
{
    digits = -1;
    if (fmt.length == 0)
        return 'G';
    wchar ret = fmt[0];
    if (fmt.length == 1)
        return ret;
    if (Char.IsUpper(ret) || Char.IsLower(ret))
    {
        digits = 0;
        for (int i = 1; i < fmt.length; i++)
        {
            if (Char.IsDigit(fmt[i]))
                return 0;
            digits *= 10;
            digits += fmt[i] - '0';
            if (digits < 0)
                return 0;
        }
        return ret;
    }
    else
        return 0;

}

wstring[] getDigits(NumberFormatInfo nfi, bool isNativeContext)
{
    auto digits = (isNativeContext && nfi.DigitSubstitution != DigitShapes.None) || 
        nfi.DigitSubstitution == DigitShapes.NativeNational ? nfi.NativeDigits : 
    CultureInfo.InvariantCulture.NumberFormat.NativeDigits;
    if (digits.length != 10)
        digits = CultureInfo.InvariantCulture.NumberFormat.NativeDigits;
    return digits;
}

immutable wchar[][] hex = 
[
    ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'],
    ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']
];

wstring intToHex(T)(T value, int digits, bool uppercase) if (isAnyIntegral!T)
{
    if (digits < 0)
        digits = 0;
    wchar[] buf = new wchar[digits > T.sizeof * 2 ? digits : T.sizeof * 2];
    int i = buf.length;
    while (digits-- > 0 || value != 0)
    {
        i--;
        buf[i] = i >= 0 ? hex[cast(int)uppercase][value & 0xf] : '0';
        value >>>= 4;
    }
    return buf[i < 0 ? 0 : i .. $];
}

wstring intToDec(T)(T value, int digits, NumberFormatInfo nfi, bool isNativeContext) if (isAnyIntegral!T)
{
    if (digits < 0)
        digits = 0;
    auto dig = getDigits(nfi, true);
    int maxDigitLen = safe32bit(dig[0].length);
    for(auto i = 0; i < 10; i++)
        if (dig[i].length > maxDigitLen)
            maxDigitLen = safe32bit(dig[i].length);
    wchar[] buf = new wchar[(digits > prec!T ? digits * maxDigitLen : prec!T * maxDigitLen) + nfi.NegativeSign.length]; 
    Unsigned!T v = value < 0 ? -value : value;
    int i = safe32bit(buf.length);
    while (digits-- > 0 || v != 0)
    {
        wstring d = dig[v % 10];
        buf[i - d.length..i] = d;
        i -= d.length;
        v /= 10;
    }
    if (value < 0)
    {
        wstring n = nfi.NegativeSign;
        buf[i - n.length..i] = n;
        i -= n.length;
    }
    return cast(wstring)buf[i..$];
}

wstring formatIntegral(T)(T value, wstring fmt, NumberFormatInfo nfi, bool isNativeContext) if (isAnyIntegral!T)
{
    int digits;
    wchar c = parseFormatSpecifier(fmt, digits);
    switch (c)
    {
        case 'x':
        case 'X':
            return intToHex!(T)(value, digits, c == 'X');
        case 'd':
        case 'D':
            return intToDec!(T)(value, digits, nfi, isNativeContext);
        default:
            Number n = Number(value);
            if (c != 0)
                return n.toString(c, digits, nfi, isNativeContext);
            return n.toString(fmt, nfi, isNativeContext);
    }
}

wstring formatFloat(T)(T value, wstring fmt, NumberFormatInfo nfi, bool isNativeContext) if (isAnyFloat!T)
{
    if (isnan(value))
        return nfi.NanSymbol;
    if (!isfinite(value))
        return value < 0 ? nfi.NegativeInfinitySymbol : nfi.PositiveInfinitySymbol;
    int digits;
    wchar c = parseFormatSpecifier(fmt, digits);
    switch (c)
    {
        case 'e':
        case 'E':
            if (digits > prec!T - 1)
                digits = prec!T + 2;
            goto default;
        case 'g':
        case 'G':
            if (digits > prec!T)
                digits = prec!T + 2;
            goto default;
        case 'r':
        case 'R':
            Number n = Number(value);
            wstring s = n.toString('G', prec!T, nfi, isNativeContext);
            T v;
            Throwable exc;
            if (parse(s, nfi, NumberStyles.Float, v, false, exc, isNativeContext))
            {
                if (v == value)
                    return s;
            }
            return n.toString('G', prec!T + 2, nfi, isNativeContext);
        default:
            Number n = Number(value);
            if (c != 0)
                return n.toString(c, digits, nfi, isNativeContext);
            return n.toString(fmt, nfi, isNativeContext);
    }
}

wstring formatDecimal(decimal value, wstring fmt, NumberFormatInfo nfi, bool isNativeContext)
{
    int digits;
    wchar c = parseFormatSpecifier(fmt, digits);
    Number n = Number(value);
    if (c != 0)
        return n.toString(c, digits, nfi, isNativeContext);
    return n.toString(fmt, nfi, isNativeContext);
}


int GetDigitValue(wstring s, ref int index, wstring[] dig)
{
    for(auto i = 0; i < 10; i++)
    {
        if (s.Substring(index).StartsWith(dig[i]))
        {
            index += dig[i].length;
            return i;
        }
    }
    return -1;
}


bool parseHex(T)(wstring s, out T result, bool spawnExceptions, out Throwable exc) if (isAnyIntegral!T)
{
    exc = null;
    if (s is null)
    {
        if (spawnExceptions)
            exc = new ArgumentNullException("value");
        return false;
    }

    if (s.length == 0)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    result = 0;
    int i = 0;
    while (i < s.length && s[i] == '0')
        i++;

    if (s.length - i > T.sizeof * 2)
    {
        if (spawnExceptions)
        {
            for (int j = i; j < s.length; j++)
                if (s[j] < '0' || (s[j] > '9' && s[j] < 'A') ||
                    (s[j] > 'F' && s[j] < 'a') || s[j] > 'f')
                {
                    exc = new FormatException();
                    break;
                }
            if (exc is null)
                exc = new OverflowException();
        }
        return false;
    }

    for (int j = i; j < s.length; j++)
    {
        ubyte val;
        if (s[j] >= '0' && s[j] <= '9')
            val = cast(ubyte)(s[j] - '0');
        else if (s[j] >= 'a' && s[j] <= 'f')
            val = cast(ubyte)(s[j] - 'a' + 10);
        else if (s[j] >= 'A' && s[j] <= 'F')
            val = cast(ubyte)(s[j] - 'A' + 10);
        else 
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
        result = cast(T)(result << 4);
        result |= val;
    }
    return true;
}

bool parseInt(T)(wstring s, out T result, bool spawnExceptions, out Throwable exc)
{
    exc = null;
    if (s is null)
    {
        if (spawnExceptions)
            exc = new ArgumentNullException("value");
        return false;
    }

    if (s.length == 0)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    int i = 0;
    bool isNegative;
    if (s[0] == '-')
    {
        isNegative = true;
        i = 1;
    }

    static if (is(Unqual!(Unsigned!T) == Unqual!T))       
    {
        if (isNegative)
        {
            if (spawnExceptions)
                exc = new OverflowException();
            return false;
        }
    }

    result = 0;    
    while (i < s.length && s[i] == '0')
        i++;

    for (int j = i; j < s.length; j++)
    {
        T val;
        if (s[j] >= '0' && s[j] <= '9')
            val = cast(T)(s[j] - '0');
        else if (s[j] == '.' && j < s.length - 1 && s[j + 1] == '0')
        {
            for (int k = j + 1; k < s.length; k++)
                if (s[k] != '0')
                {
                    if (spawnExceptions)
                        exc = new FormatException();
                    return false;
                }
            return true;
        }
        else 
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
        try
        {
            if (isNegative)
                val = -val;
            result = checkedMul(result, cast(T)10);
            result = checkedAdd(result, val);

        }
        catch (OverflowException o)
        {
            if (spawnExceptions)
                exc = o;
            return false;
        }
    }

    return true;
}

bool parseFloat(T)(wstring s, out T result, bool spawnExceptions, out Throwable exc) if (isAnyFloat!T)
{
    exc = null;
    if (s is null)
    {
        if (spawnExceptions)
            exc = new ArgumentNullException("value");
        return false;
    }

    if (s.length == 0)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    result = cast(T)0.0;

    int i = 0;
    bool isNegative;
    if (s[0] == '-')
    {
        isNegative = true;
        i = 1;
    }

    while (i < s.length && s[i] == '0')
        i++;

    while(i < s.length && s[i] != '.' && s[i] != 'e' && s[i] != 'E')
    {
        int val;
        if (s[i] >= '0' && s[i] <= '9')
            val = (s[i] - '0');
        else 
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
        try
        {
            result = checkedMul(result, 10);
            result = checkedAdd(result, val);
        }
        catch (OverflowException e)
        {
            if (spawnExceptions)
                exc = e;
            return false;
        }
    }

    if (i < s.length && s[i] == '.')
    {
        i++;
        T pow = 10.0;
        while (i < s.length && s[i] != 'e' && s[i] != 'E')
        {
            int val;
            if (s[i] >= '0' && s[i] <= '9')
                val = (s[i] - '0');
            else 
            {
                if (spawnExceptions)
                    exc = new FormatException();
                return false;
            }   
            try
            {
                T div = checkedMul(val, 1 / pow);
                result = checkedAdd(result, div);
                pow *= 10;
            }
            catch (OverflowException e)
            {
                if (spawnExceptions)
                    exc = new OverflowException();
                return false;
            }
            if (!isfinite(pow))
            {
                while (i < s.length && s[i] != 'e' && s[i] != 'E')
                    i++;
                break;
            }
        }
    }

    if (i < s.length && s[i] == 'e' || s[i] == 'E')
    {
        i++;
        if (i < s.length)
        {
            bool positiveExponent = true;
            if (s[i] == '-' || s[i] == '+')
            {
                positiveExponent = s[i] != '-';
                i++;
            }
            long exponent;
            if (!parseInt(s[i .. $], exponent, true, exc))
                return false;
            T exp = exponent;
            if (!positiveExponent)
                exp = -exp;
            try
            {
                exp = checkedPow(cast(T)10, cast(T)exponent);
                result = checkedMul(result, exp);
            }
            catch (OverflowException e)
            {
                if (spawnExceptions)
                    exc = new OverflowException();
                return false;
            }
        }
        else if (i < s.length)
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
    }
    if (isNegative)
        result = -result;
    return true;
}

bool parseDecimal(wstring s, out decimal result, bool spawnExceptions, out Throwable exc)
{
    exc = null;
    if (s is null)
    {
        if (spawnExceptions)
            exc = new ArgumentNullException("value");
        return false;
    }

    if (s.length == 0)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    result = decimal.Zero;
    decimal ten = decimal(10);

    int i = 0;
    bool isNegative;
    if (s[0] == '-')
    {
        isNegative = true;
        i = 1;
    }
    while (i < s.length && s[i] == '0')
        i++;

    while(i < s.length && s[i] != '.' && s[i] != 'e' && s[i] != 'E')
    {
        decimal val;
        if (s[i] >= '0' && s[i] <= '9')
            val = decimal(s[i] - '0');
        else 
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
        try
        {
            result = result * ten;
            result = result + val;
        }
        catch (Throwable t)
        {
            if (spawnExceptions)
                exc = t;
            return false;
        }
        i++;
    }

    if (i < s.length && s[i] == '.')
    {
        i++;
        decimal pow = ten;
        while (i < s.length && s[i] != 'e' && s[i] != 'E')
        {
            decimal val;
            if (s[i] >= '0' && s[i] <= '9')
                val = decimal(s[i] - '0');
            else 
            {
                if (spawnExceptions)
                    exc = new FormatException();
                return false;
            }

            try
            {
                result = result + val / pow;
                if (i < s.length - 1)
                    pow = pow * ten;
            }
            catch (Throwable t)
            {
                if (spawnExceptions)
                    exc = t;
                return false;
            }
            i++;
        }
    }

    if (i < s.length && (s[i] == 'e' || s[i] == 'E'))
    {
        i++;
        if (i < s.length)
        {
            bool positiveExponent = true;
            if (s[i] == '-' || s[i] == '+')
            {
                positiveExponent = s[i] != '-';
                i++;
            }
            long exponent;
            if (!parseInt(s[i .. $], exponent, spawnExceptions, exc))
                return false;
            try
            {
                decimal exp = ten;
                while (--exponent > 0)
                    exp = exp * ten;        
                result = result * exp;
            }
            catch(Throwable t)
            {
                if (spawnExceptions)
                    exc = new OverflowException();
                return false;
            }
        }
        else if (i < s.length)
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
    }
    if (isNegative)
        result = -result;
    return true;
}


bool parse(T)(wstring str, NumberFormatInfo nfi, NumberStyles styles, out T result, bool spawnExceptions, out Throwable exc, bool isNativeContext) if (isNumeric!T)
{
    auto i = 0; 
    wstring s = str;
    int j = s.length - 1;
    if (styles & NumberStyles.AllowLeadingWhite)
        while (i < s.length && (s[i] == 0x09 || s[i] == 0x0a || s[i] == 0x0c || s[i] == 0x0d || s[i] == 0x20))
            i++;
    if (styles & NumberStyles.AllowTrailingWhite)
        while (j > 0 && (s[j] == 0x09 || s[j] == 0x0a || s[j] == 0x0c || s[j] == 0x0d || s[j] == 0x20))
            j--;
    if (i != 0 || j != s.length - 1)
        if (i < s.length - 1 && j > 0)
            s = s[i .. j + 1];

    static if (is(T == real) || is(T == double) || is(T == float))
    {
        if (s == nfi.NanSymbol)
        {
            result = T.nan;
            return true;
        }
        if (s == nfi.NegativeInfinitySymbol)
        {
            result = -T.infinity;
            return true;
        }
        if (s == nfi.PositiveInfinitySymbol)
        {
            result = T.infinity;
            return true;
        }
    }

    static if (__traits(isIntegral, T))
    {
        if (styles & NumberStyles.AllowHexSpecifier)
            return parseHex(s, result, spawnExceptions, exc);
    }

    wchar[] ret = new wchar[s.length + 1];
    j = 1;

    wstring decSep, groupSep;
    if (styles & NumberStyles.AllowDecimalPoint)
    {
        if ((styles & NumberStyles.AllowCurrencySymbol) &&
            IndexOf(cast(wstring)(s), nfi.CurrencySymbol, StringComparison.Ordinal) != -1)
            decSep = nfi.CurrencyDecimalSeparator;
        else
            decSep = nfi.NumberDecimalSeparator;
    }
    if (styles & NumberStyles.AllowThousands)
    {
        if ((styles & NumberStyles.AllowCurrencySymbol) &&
            IndexOf(cast(wstring)s, nfi.CurrencySymbol, StringComparison.Ordinal) != -1)
            groupSep = nfi.CurrencyGroupSeparator;
        else
            groupSep = nfi.NumberGroupSeparator;
    }

    i = 0;

    //leading symbols $+-(
    bool expectingCurrency      = (styles & NumberStyles.AllowCurrencySymbol) != 0;
    bool expectingParanthese    = (styles & NumberStyles.AllowParantheses) != 0;
    bool expectingSign          = (styles & NumberStyles.AllowLeadingSign) != 0;
    bool expectingWhite         = false;
    bool isNegativeBySign       = false;
    bool isNegativeByParanthese = false;
    bool hadCurrency            = false;
    bool hadSign                = false;


    while (i < s.length && (expectingCurrency || expectingParanthese || expectingSign || expectingWhite))
    {
        if (expectingCurrency && !String.IsNullOrEmpty(nfi.CurrencySymbol) && s[i .. $].StartsWith(nfi.CurrencySymbol))
        {
            i += nfi.CurrencySymbol.length;
            expectingCurrency = false;
            expectingWhite = true;
            hadCurrency = true;
        }
        else if (expectingSign && !String.IsNullOrEmpty(nfi.NegativeSign) && s.Substring(i).StartsWith(nfi.NegativeSign))
        {
            i += nfi.NegativeSign.length;
            expectingSign = false;
            expectingParanthese = false;
            expectingWhite = false;
            isNegativeBySign = true;
            hadSign = true;
        }
        else if (expectingSign && !String.IsNullOrEmpty(nfi.PositiveSign) && s.Substring(i).StartsWith(nfi.PositiveSign))
        {
            i += nfi.PositiveSign.length;
            expectingSign = false;
            expectingParanthese = false;
            expectingWhite = false;
            hadSign = true;
        }
        else if (expectingParanthese && s[i] == '(')
        {
            i++;
            expectingSign = false;
            expectingParanthese = false;
            expectingWhite = false;
            isNegativeByParanthese = true;
        }
        else if (expectingWhite && s[i] == 0x20)
        {
            i++;
            expectingWhite = false;
        }
        else
            break;      
    }

    auto dig = getDigits(nfi, isNativeContext);

    //0..9 or decimal point or group separator
    bool expectingDecimalPoint = (styles & NumberStyles.AllowDecimalPoint) != 0;
    bool expectingGroupSeparator = false;
    bool digitIsMandatory = false;
    bool hadAnyDigit = false;

    while (i < s.length)
    {
        if (expectingDecimalPoint && !String.IsNullOrEmpty(decSep) && s.Substring(i).StartsWith(decSep))
        {
            i += decSep.length;
            ret[j++] = '.';
            hadAnyDigit = false;
            break;
        }
        else if (expectingGroupSeparator && !String.IsNullOrEmpty(groupSep) && s.Substring(i).StartsWith(groupSep))
        {
            i += groupSep.length;
            digitIsMandatory = true;
        }
        else
        {
            int k = GetDigitValue(cast(wstring)s, i, dig);
            if (k < 0)
                break;
            ret[j++] = cast(wchar)('0' + k);
            digitIsMandatory = false;
            expectingGroupSeparator = (styles & NumberStyles.AllowThousands) != 0;
            hadAnyDigit = true;
        }
    }

    if (digitIsMandatory)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    //decimals 0..9, e, E
    bool expectingE = hadAnyDigit && (styles & NumberStyles.AllowExponent) != 0;
    bool hadE = false;

    while (i < s.length)
    {
        if (expectingE && (s[i] == 'e' || s[i] == 'E'))
        {
            i++;
            ret[j++] = 'e';
            expectingE = false;
            hadE = true;
            digitIsMandatory = true;
            break;
        }
        else
        {
            int k = GetDigitValue(cast(wstring)s, i, dig);
            if (k < 0)
                break;
            ret[j++] = cast(wchar)('0' + k);
        }
    }

    //e, expecting sign

    if (hadE && i < s.length)
    {
        if (!String.IsNullOrEmpty(nfi.NegativeSign) && s.Substring(i).StartsWith(nfi.NegativeSign))
        {
            i += nfi.NegativeSign.length;
            ret[j++] = '-';
        }
        else if (!String.IsNullOrEmpty(nfi.PositiveSign) && s.Substring(i).StartsWith(nfi.PositiveSign))
        {
            i += nfi.PositiveSign.length;
            ret[j++] = '+';
        }
    }

    //e, expecting exponent
    if (hadE && i < s.length)
    {
        while (i < s.length)
        {
            int k = GetDigitValue(cast(wstring)s, i, dig);
            if (k < 0)
                break;
            ret[j++] = cast(wchar)('0' + k);
            digitIsMandatory = false;
        }
    }

    if (digitIsMandatory)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    expectingCurrency      = !hadCurrency && (styles & NumberStyles.AllowCurrencySymbol) != 0;
    expectingParanthese    = isNegativeByParanthese && (styles & NumberStyles.AllowParantheses) != 0;
    expectingSign          = !isNegativeBySign && (styles & NumberStyles.AllowLeadingSign) != 0;
    expectingWhite         = true;
    bool endsInWhite       = false;

    while (i < s.length && (expectingCurrency || expectingParanthese || expectingSign || expectingWhite))
    {
        if (expectingCurrency && !String.IsNullOrEmpty(nfi.CurrencySymbol) && s.Substring(i).StartsWith(nfi.CurrencySymbol))
        {
            i += nfi.CurrencySymbol.length;
            expectingCurrency = false;
            expectingWhite = true;
            hadCurrency = true;
            endsInWhite = false;
        }
        else if (expectingSign && !String.IsNullOrEmpty(nfi.NegativeSign) && s.Substring(i).StartsWith(nfi.NegativeSign))
        {
            i += nfi.NegativeSign.length;
            expectingSign = false;
            expectingParanthese = false;
            expectingWhite = true;
            isNegativeBySign = true;
            hadSign = true;
            endsInWhite = false;
        }
        else if (expectingParanthese && s[i] == ')')
        {
            i++;
            expectingSign = false;
            expectingParanthese = false;
            expectingWhite = true;
            isNegativeByParanthese = true;
            endsInWhite = false;
        }
        else if (expectingWhite && s[i] == 0x20)
        {
            i++;
            expectingWhite = false;
            endsInWhite = true;
        }
        else
        {
            if (spawnExceptions)
                exc = new FormatException();
            return false;
        }
    }

    if (i < s.length || endsInWhite)
    {
        if (spawnExceptions)
            exc = new FormatException();
        return false;
    }

    if (isNegativeBySign || isNegativeByParanthese)
    {
        ret[0] = '-';
        ret = ret[0 .. j];
    }
    else
        ret = ret[1 .. j];

    static if (__traits(isIntegral, T))
        return parseInt(cast(wstring)ret, result, spawnExceptions, exc);
    else static if (is(T == decimal))
        return parseDecimal(cast(wstring)ret, result, spawnExceptions, exc);
    else
        return parseFloat(cast(wstring)ret, result, spawnExceptions, exc);

}