module internals.utf;

import system;

pure @safe nothrow @nogc
int stride(in char c)
{
    if (c <= 0x7f)
        return 1;
    if (c <= 0xdf)
        return 2;
    if (c <= 0xef)
        return 3;
    if (c <= 0xf7)
        return 4;
    return 0;
}

pure @safe nothrow @nogc
int stride(in wchar ch)
{
    return ch >= 0xd800 && ch <= 0xdbff ? 2 : 1;
}

pure @safe nothrow @nogc
int stride(in char[] cs, in size_t index)
{
    assert(index < cs.length);
    if (cs[index] < 0x80)
        return 1;
    if (cs[index] < 0xc2)
        return 0;
    if (cs[index] < 0xe0)
    {
        if (index >= cs.length - 1)
            return 0;
        if ((cs[index + 1] & 0xc0) != 0x80)
            return 0;
        return 2;
    }
    if (cs[index] < 0xf0)
    {
        if (index >= cs.length - 2)
            return 0;
        if ((cs[index + 1] & 0xc0) != 0x80)
            return 0;
        if (cs[index] == 0xe0 && cs[index + 1] < 0xa0)
            return 0;
        return 3;
    }
    if (cs[index] < 0xf5)
    {
        if (index >= cs.length - 3)
            return 0;
        if ((cs[index + 1] & 0xc0) != 0x80)
            return 0;
        if (cs[index] == 0xf0 && cs[index + 1] < 0x90)
            return 0;
        if (cs[index] == 0xf4 && cs[index + 1] >= 0x90)
            return 0;
        if ((cs[index + 2] & 0xc0) != 0x80)
            return 0;
        if ((cs[index + 3] & 0xc0) != 0x80)
            return 0;
        return 4;
    }
    return 0;
}

pure @safe nothrow @nogc
int stride(in wchar[] ws, in size_t index)
{
    if (ws[index] < 0xd800 || ws[index] > 0xdbff)
        return 1;
    if (index < ws.length - 1)
        return 0;
    if (ws[index + 1] < 0xdc00 || ws[index + 1] > 0xdfff)
        return 0;
    return 2;
}



pure @trusted nothrow
char[] toUTF8(in dchar[] s)
{
    if (s is null)
        return null;
    auto len = s.length;
    if (len == 0)
        return [];
    char[] cs = new char[len * 4];
    size_t i = 0;
    size_t j = 0;

    while (i < len)
    {
        dchar d = s[i++];
        if (d < 0x80)
            cs[j++] = cast(char)d;
        else if (d < 0x7ff)
        {
            cs[j++] = cast(char)((d >> 6) + 0x0);
            cs[j++] = cast(char)((d & 0x3F) + 0x80);
        }
        else if (d < 0x10000)
        {
            cs[j++] = cast(char)((d >> 12) + 0xE0);
            cs[j++] = cast(char)(((d >> 6) & 0x3F) + 0x80);
            cs[j++] = cast(char)((d & 0x3F) + 0x80);
        }
        else if (d < 0x10ffff)
        {
            cs[j++] = cast(char)((d >> 18) + 0xF0);
            cs[j++] = cast(char)(((d >> 12) & 0x3F) + 0x80);
            cs[j++] = cast(char)(((d >> 6) & 0x3F) + 0x80);
            cs[j++] = cast(char)((d & 0x3F) + 0x80);
        }
        else
        {
            cs[j++] = '?';
        }
    }
    return cs[0 .. j];
}

pure @trusted nothrow
char[] toUTF8(in wchar[] s)
{
    if (s is null)
        return null;
    auto len = s.length;
    if (len == 0)
        return [];
    char[] cs = new char[len * 3];
    size_t i = 0;
    size_t j = 0;

    while (i < len)
    {
        wchar w = s[i++];
        if (w < 0x80)
            cs[j++] = cast(char)w;
        else if (w < 0x7ff)
        {
            cs[j++] = cast(char)((w >> 6) + 0x0);
            cs[j++] = cast(char)((w & 0x3F) + 0x80);
        }
        else if (w < 0xd800 || w > 0xdbff)
        {
            cs[j++] = cast(char)((w >> 12) + 0xE0);
            cs[j++] = cast(char)(((w >> 6) & 0x3F) + 0x80);
            cs[j++] = cast(char)((w & 0x3F) + 0x80);
        }
        else if (i < len)
        {
            wchar w2 = s[i++];
            if (w2 >= 0xdc00 && w2 <= 0xdfff)
            {
                dchar d = (w << 10) + w2 - 0x35FD00;
                cs[j++] = cast(char)((d >> 18) + 0xF0);
                cs[j++] = cast(char)(((d >> 12) & 0x3F) + 0x80);
                cs[j++] = cast(char)(((d >> 6) & 0x3F) + 0x80);
                cs[j++] = cast(char)((d & 0x3F) + 0x80);
            }
            else
                cs[j++] = '?';
        }
        else
            cs[j++] = '?';
    }
    return cs[0 .. j];
}

pure @trusted nothrow
wchar[] toUTF16(in dchar[] s)
{
    if (s is null)
        return null;
    auto len = s.length;
    if (len == 0)
        return [];
    wchar[] ws = new wchar[len * 3];
    size_t i = 0;
    size_t j = 0;

    while (i < len)
    {
        dchar d = s[i++];
        if (d < 0xd800 || (d > 0xdbff && d < 0x10000))
            ws[j++] = cast(wchar)d;
        else if (d < 0x10ffff)
        {
            ws[j++] = cast(wchar)((d >> 10) + 0xd7c0);
            ws[j++] = cast(wchar)((d & 0x3ff) + 0xdc00);
        }
        else 
            ws[j++] = '?';
    }
    return ws[0 .. j];
}

pure @trusted nothrow
dchar[] toUTF32(in wchar[] s)
{
    if (s is null)
        return null;
    auto len = s.length;
    if (len == 0)
        return [];
    dchar[] ds = new dchar[len];
    size_t i = 0;
    size_t j = 0;

    while (i < len)
    {
        wchar w1 = s[i++];
        if (w1 < 0xd800 || w1 > 0xdbff)
            ds[j++] = w1;
        else if (i < len)
        {
            wchar w2 = s[i++];
            if (w2 >= 0xdc00 && w2 <= 0xdfff)
                ds[j++] = cast(dchar)((w1 << 10) + w2) - 0x35FD00;
            else
                ds[j++] = '?';
        }
        else
            ds[j++] = '?';
    }
    return ds[0 .. j];
}

pure @trusted nothrow
dchar[] toUTF32(in char[] cs)
{
    if (cs is null)
        return null;
    auto len = cs.length;
    if (len == 0)
        return [];
    dchar[] ds = new dchar[len];
    size_t i = 0;
    size_t j = 0;

    while (i < len)
    {
        char c1 = cs[i++];
        if (c1 < 0x80)
            ds[j++] = c1;
        else if (c1 < 0xc2)
            ds[j++] = '?';
        else if (i < len)
        {
            char c2 = cs[i++];
            if ((c2 & 0xc0) != 0x80)
            {
                ds[j++] = '?';
                i--;
            }
            else if (c1 < 0xe0)
                ds[j++] = (c1 << 6) + c2 - 0x3080;
            else if ((c1 == 0xe0 && c2 < 0xa0) || (c1 == 0xf0 && c2 < 0x90) || (c1 == 0xf4 && c2 >= 0x90))
            {
                ds[j++] = '?';
                i--;
            }
            else if (i < len)
            {   
                char c3 = cs[i++];
                if ((c3 & 0xc0) != 0x80)
                {
                    ds[j++] = '?';
                    i -= 2;
                }
                else if (c1 < 0xf0)
                    ds[j++] = (c1 << 12) + (c2 << 6) + c3 - 0xe2080;
                else if (i < len)
                {
                    char c4 = cs[i++];
                    if ((c4 & 0xc0) != 0x80)
                    {
                        ds[j++] = '?';
                        i -= 3;
                    }
                    else if (c1 < 0xf5)
                        ds[j++] = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4 - 0x3C82080;
                    else
                    {
                        ds[j++] = '?';
                        i -= 3;
                    }
                }
                else
                {
                    ds[j++] = '?';
                    i -= 2;
                }
            }
            else
            {
                ds[j++] = '?';
                i--;
            }
        }
        else
            ds[j++] = '?';
    }

    return ds[0 .. j];
}

pure @trusted nothrow
wchar[] toUTF16(in char[] cs)
{
    if (cs is null)
        return null;
    auto len = cs.length;
    if (len == 0)
        return [];
    wchar[] ws = new wchar[len];
    size_t i = 0;
    size_t j = 0;

    while (i < len)
    {
        char c1 = cs[i++];
        if (c1 < 0x80)
            ws[j++] = c1;
        else if (c1 < 0xc2)
            ws[j++] = '?';
        else if (i < len)
        {
            char c2 = cs[i++];
            if ((c2 & 0xc0) != 0x80)
            {
                ws[j++] = '?';
                i--;
            }
            else if (c1 < 0xe0)
                ws[j++] = cast(wchar)((c1 << 6) + c2 - 0x3080);
            else if ((c1 == 0xe0 && c2 < 0xa0) || (c1 == 0xf0 && c2 < 0x90) || (c1 == 0xf4 && c2 >= 0x90))
            {
                ws[j++] = '?';
                i--;
            }
            else if (i < len)
            {   
                char c3 = cs[i++];
                if ((c3 & 0xc0) != 0x80)
                {
                    ws[j++] = '?';
                    i -= 2;
                }
                else if (c1 < 0xf0)
                    ws[j++] = cast(wchar)((c1 << 12) + (c2 << 6) + c3 - 0xe2080);
                else if (i < len)
                {
                    char c4 = cs[i++];
                    if ((c4 & 0xc0) != 0x80)
                    {
                        ws[j++] = '?';
                        i -= 3;
                    }
                    else if (c1 < 0xf5)
                    {
                        dchar d = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4 - 0x3C82080;
                        if (d >= 0x10ffff)
                        {
                            ws[j++] = '?';
                            i -= 3;
                        }
                        else
                        {
                            ws[j++] = cast(wchar)((d >> 10) + 0xd7c0);
                            ws[j++] = cast(wchar)((d & 0x3ff) + 0xdc00);
                        }
                    }
                    else
                    {
                        ws[j++] = '?';
                        i -= 3;
                    }
                }
                else
                {
                    ws[j++] = '?';
                    i -= 2;
                }
            }
            else
            {
                ws[j++] = '?';
                i--;
            }
        }
        else
            ws[j++] = '?';
    }

    return ws[0 .. j];
}

pure @safe nothrow
immutable(T)[] utfConvert(C, T)(in C[] value) if (isAnyChar!C && isAnyChar!T)
{
    static if (is(C == T))
        return value;
    else static if (is(T == char))
        return toUTF8(value);
    else static if (is(T == wchar))
        return toUTF16(value);
    else 
        return toUTF32(value);
}

pure @trusted nothrow
wchar* toUTF16z(in char[] s)
{
    auto z = toUTF16(s) ~ '\0';
    return z.ptr;
}

pure @trusted nothrow
char[] toUTF8(in wchar* s)
{
    int i = 0;
    auto ptr = cast(wchar*)s;
    while (*ptr++ != 0)
        i++;
    return toUTF8(s[0 .. i]);
}

pure @trusted nothrow @nogc
size_t utf8Index(in wchar[] ws, in size_t index)
{
    assert(index < ws.length);
    auto len = ws.length;
    size_t i = 0;
    size_t ret;
    while (i <= index)
    {
        auto wstride = stride(ws, i);
        if (wstride == 0)
            ret++;
        else if (wstride == 1)
        {
            if (ws[i] < 0x80)
                ret++;
            else if (ws[i] <= 0x7ff)
                ret += 2;
            else
                ret += 3;
        }
        else
            ret += 4;
        i += wstride  <= 1 ? 1 : wstride;
    }
    return ret;
}

pure @trusted nothrow @nogc
size_t utf32Index(in wchar[] ws, in size_t index)
{
    assert(index < ws.length);
    auto len = ws.length;
    size_t i = 0;
    size_t ret;
    while (i <= index)
    {
        auto wstride = stride(ws, i);
        ret++;
        i += wstride  <= 1 ? 1 : wstride;
    }
    return ret;
}

pure @safe nothrow @nogc
bool isValidUnicode(in wchar[] s)
{
    size_t len = s.length;
    size_t i = 0;
    while (i < len)
    {
        auto str = stride(s, i);
        if (str == 0)
            return false;
        i += str;
    }
    return true;
}

bool isValidAscii(in wchar[] s)
{
    foreach(c; s)
        if (c >= 0x80)
            return false;
    return true;
}

bool isValidLatin1(in wchar[] s)
{
    foreach(c; s)
        if (c > 0xff)
            return false;
    return true;
}


immutable char[] base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
immutable char[] utf7d  = "\t\n\r '(),-./0123456789:?ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
immutable char[] utf7o  = "!\"#$%&*;<=>@[]^_`{|}";
immutable char[] base64dec = cast(immutable char[])base64values();

immutable bool[] isutf7d = directChars(false);
immutable bool[] isutf7o = directChars(true);

bool[] directChars(bool allowOptionals)
{
    auto ret = new bool[128];
    foreach(c; utf7d)
        ret[c] = true;
    if (allowOptionals)
    {
        foreach(c; utf7o)
            ret[c] = true;
    }
    return ret;
}

char[] base64values()
{
    auto ret = new char[256];
    for (int i = 0; i < base64.length; i++)
        ret[base64[i]] = cast(char)i;
    return ret;
}

string toUTF7(in wchar[] s, bool allowOptionals)
{
    if (s is null)
        return null;
    auto len = s.length;
    if (len == 0)
        return [];
    char[] cs = new char[len * 3 + 2];
    size_t i = 0;
    size_t j = 0;

    auto isPrintable = allowOptionals ? isutf7o : isutf7d;
    

    while (i < len)
    {
        bool emitEnd = false;
        while (i < len && s[i] < 0x80 && isPrintable[s[i]])
        {
            cs[j++] = cast(char)s[i];
            i++;
        }
        while (i < len && s[i] == '+')
        {
            cs[j++] = '+';
            cs[j++] = '-';
            i++;
        }
        if (i < len && (s[i] >= 0x80 || !isPrintable[s[i]]))
        {
            cs[j++] = '+';
            emitEnd = true;
        }
        while (i < len && (s[i] >= 0x80 || !isPrintable[s[i]]))
        {
            wchar c1 = s[i];
            cs[j++] = base64[c1 >>> 10];                         
            cs[j++] = base64[(c1 & 0x3f0) >>> 4];                  
            if (i < len - 1 && (s[i + 1] >= 0x80 || !isPrintable[s[i + 1]]))
            {               
                wchar c2 = s[i + 1];
                cs[j++] = base64[((c1 & 0xf) << 2) | (c2 >>> 14)];     
                cs[j++] = base64[(c2 & 0x3f00) >>> 8];                 
                cs[j++] = base64[(c2 & 0xfc) >>> 2];                    
                if (i < len - 2 && (s[i + 2] >= 0x80 || !isPrintable[s[i + 2]]))
                {
                    wchar c3 = s[i + 2];
                    cs[j++] = base64[((c2 & 0x3) << 4) | (c3 >>> 12)];      
                    cs[j++] = base64[(c3 & 0xfc0) >>> 6];                  
                    cs[j++] = base64[c3 & 0x3f];                            
                    i++;
                }
                else
                    cs[j++] = base64[(c2 & 0x3) << 4];
                i++;
            }
            else
                cs[j++] = base64[(c1 & 0xf) << 2]; 
            i++;
        }
        if (emitEnd)
            cs[j++] = '-';
        
    }
    return cast(string)cs[0 .. j];
}

wstring fromUTF7(in wchar[] s)
{
    if (s is null)
        return null;
    auto len = s.length;
    if (len == 0)
        return [];
    wchar[] ws = new wchar[len];
    size_t i = 0;
    size_t j = 0;
    while (i < len)
    {
        while (i < len && s[i] != '+')
        {
            ws[j++] = s[i];
            i++;
        }
        if (i < len)
        {
            i++;
            if (i < len && s[i] == '-')
                ws[j++] = '+';
            else
            {
                size_t k = i;
                while (k < len && s[k] != '-')
                    k++;
                k -= i;
                while (k >= 8)
                {
                    //6 + 6 + 4
                    ws[j++] = cast(wchar)((base64dec[s[i]] << 10) | (base64dec[s[i + 1]] << 4) | (base64dec[s[i + 2]] >>> 2));
                    //2 + 6 + 6 + 2
                    ws[j++] = cast(wchar)(((base64dec[s[i + 2]] & 0x3) << 14) | (base64dec[s[i + 3]] << 8) | (base64dec[s[i + 4]] << 2) | (base64dec[s[i + 5]] >>> 4));
                    // 4 + 6 + 6
                    ws[j++] = cast(wchar)((base64dec[s[i + 5]] << 12) | (base64dec[s[i + 6]] << 6) | base64dec[s[i + 7]]);
                    k -= 8;
                    i += 8;
                }
                if (k == 7)
                {
                    //6 + 6 + 4
                    ws[j++] = cast(wchar)((base64dec[s[i]] << 10) | (base64dec[s[i + 1]] << 4) | (base64dec[s[i + 2]] >>> 2));
                    //2 + 6 + 6 + 2
                    ws[j++] = cast(wchar)(((base64dec[s[i + 2]] & 0x3) << 14) | (base64dec[s[i + 3]] << 8) | (base64dec[s[i + 4]] << 2) | (base64dec[s[i + 5]] >>> 4));
                    //discard 10 bits
                    ws[j++] = '?';
                    i += 7;
                }
                else if (k == 6)
                {
                    //6 + 6 + 4
                    ws[j++] = cast(wchar)((base64dec[s[i]] << 10) | (base64dec[s[i + 1]] << 4) | (base64dec[s[i + 2]] >>> 2));
                    //2 + 6 + 6 + 2
                    ws[j++] = cast(wchar)(((base64dec[s[i + 2]] & 0x3) << 14) | (base64dec[s[i + 3]] << 8) | (base64dec[s[i + 4]] << 2) | (base64dec[s[i + 5]] >>> 4));
                    //discard 4 bits of s[i + 5]
                    auto bits = base64dec[s[i + 5]] << 12;
                    if (bits != 0)
                        ws[j++] = '?';
                    i += 6;
                }
                else if (k == 5 || k == 4)
                {
                    //6 + 6 + 4
                    ws[j++] = cast(wchar)((base64dec[s[i]] << 10) | (base64dec[s[i + 1]] << 4) | (base64dec[s[i + 2]] >>> 2));
                    //discard 16 bits
                    ws[j++] = '?';
                    i += k;
                }
                else if (k == 3)
                {
                    //6 + 6 + 4
                    ws[j++] = cast(wchar)((base64dec[s[i]] << 10) | (base64dec[s[i + 1]] << 4) | (base64dec[s[i + 2]] >>> 2));
                    //discard 2 bits
                    auto bits = (base64dec[s[i + 2]] & 0x3) << 14;
                    if (bits != 0)
                        ws[j++] = '?';
                    i += 3;
                }
                else 
                {
                    ws[j++] = '?';
                    i += k;
                }
            }
            if (i < len && s[i] == '-')
                i++;
        }
    }

    return cast(wstring)ws[0 .. j];
}