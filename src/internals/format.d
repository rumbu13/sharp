module internals.format;

import system;
import internals.resources;
import internals.checked;
import internals.number;
import internals.traits;
import internals.utf;

wstring compositeFormat(A...)(wstring fmt, IFormatProvider provider, A args) if (A.length > 0)
{
    alias FormatFunc = wstring function(wstring, const(void)*, IFormatProvider, ICustomFormatter);
    FormatFunc[A.length] funcs;
    const(void)* [A.length] argAddresses;
    foreach(i, R; A)
    {
        funcs[i] = &argumentFormat!(Unqual!R);
        argAddresses[i] = cast(const(void)*)&args[i];
    }

    ICustomFormatter formatter = cast(ICustomFormatter)provider.GetFormat(typeid(ICustomFormatter));
    auto len = fmt.length;
    wstring ret;
    auto f = 0;
    while (f < len)
    {
        if (fmt[f] == '{' && f < len - 1 && fmt[f + 1] == '{')
            ret ~= fmt[f++];
        else if (fmt[f] == '}' && f < len - 1 && fmt[f + 1] == '}')
            ret ~= fmt[f++];
        else if (fmt[f] != '{')
            ret ~= fmt[f];
        else
        {
            f++;
            int argIndex;
            if (f >= len || !Char.IsDigit(fmt[f]))
                throw new FormatException(SharpResources.GetString("FormatExpectingDigit", f));
            while (f < len && Char.IsDigit(fmt[f]))
            {
                try
                {
                    argIndex = checkedMul(argIndex, 10);
                    argIndex = checkedAdd(argIndex, fmt[f] - '0');
                }
                catch(OverflowException oe)
                {
                    throw new FormatException(SharpResources.GetString("FormatArgIndexOverflow", f), oe);
                }
                f++;
            }
            if (argIndex >= A.length)
                throw new FormatException(SharpResources.GetString("FormatArgIndexInvalid", f), 
                          new ArgumentOutOfRangeException(SharpResources.GetString("ArgumentOutOfRange", 0, A.length -1)));
            int argAlignment = 0;
            if (f < len && fmt[f] == ',')
            {
                f++;
                bool isNegative = false;
                if (f < len && fmt[f] == '-')
                {
                    f++;
                    isNegative = true;
                }
                else if (f < len && fmt[f] == '+')
                    f++;
                if (f >= len || !Char.IsDigit(fmt[f]))
                    throw new FormatException(SharpResources.GetString("FormatExpectingDigit", f));
                while (f < len && Char.IsDigit(fmt[f]))
                {
                    try
                    {
                        argAlignment = checkedMul(argAlignment, cast(int)10);
                        argAlignment = checkedAdd(argAlignment, cast(int)(fmt[f] - '0'));
                    }
                    catch(OverflowException oe)
                    {
                        throw new FormatException(SharpResources.GetString("FormatArgAlignmentOverflow", f), oe);
                    }
                    f++;
                }
                if (isNegative)
                    argAlignment = -argAlignment;
            }

            wstring argFmt;
            if (f < len && fmt[f] == ':')
            {
                f++;
                while (f < len)
                {
                    if (fmt[f] == '{' && f < len - 1 && fmt[f + 1] == '{')
                        argFmt ~= fmt[f++];
                    else if (fmt[f] == '}' && f < len - 1 && fmt[f + 1] == '}')
                        argFmt ~= fmt[f++];
                    else if (fmt[f] != '}')
                        argFmt ~= fmt[f];
                    else
                        break;
                    f++;
                }
            }

            if (f >= len || fmt[f] != '}')
                throw new FormatException(SharpResources.GetString("FormatArgUnterminated", f));

            ret ~= alignFormat(funcs[argIndex](argFmt, argAddresses[argIndex], provider, formatter), argAlignment);
        }
        f++;
    }

    return ret;
}

wstring argumentFormat(A)(wstring fmt, const(void)* arg, IFormatProvider provider, ICustomFormatter formatter)
{

    static if (is(A == typeof(null)))
        return ""w;
    else
    {
        A a = *cast(A*)(arg);
        if (formatter)
            return formatter.Format(fmt, box(a), provider);

        static if (is(A == class) || is(A == interface))
        {
            if (a is null)
                return ""w;
            if (auto formattable = cast(IFormattable)(a))
                return formattable.ToString(fmt, provider);
        }    
        static if (is(typeof(a.ToString(fmt, provider)) : wstring))
            return a.ToString(fmt, provider);
        else static if (is(typeof(a.ToString()) : wstring))
            return a.ToString();
        else static if (is(typeof(a.toString()) : string))
            return a.toString().toUTF16();
        else static if (is(A: wstring))
            return a;
        else static if (is(A : string) || is(A: dstring))
            return a.toUTF16();
        else
            return A.stringof.toUTF16();
    }
}

wstring alignFormat(wstring fmt, int alignment)
{
    bool isLeftAligned = alignment < 0;
	if (isLeftAligned)
		alignment = -alignment;
	if (alignment > fmt.length)
	{
		auto pad = alignment - fmt.length;
		wchar[] padding = new wchar[pad];
		padding[] = ' ';
		return !isLeftAligned ? cast(wstring)padding ~ fmt : fmt ~ cast(wstring)padding;
	}
    else
        return fmt;
}