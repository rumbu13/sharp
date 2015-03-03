module unitests.chars;

import system;
import system.globalization;
import internals.traits;

unittest
{

    wchar c1 = 'A';
    auto c2 = box(cast(wchar)'A');

    assert(c2.Equals(box(c1)));

    int letter = 0x0041;
    int music = 0x1D161;

    assert(Char.ConvertFromUTF32(letter) == "A"w);
    assert(Char.ConvertFromUTF32(music)[0] == 0xD834);
    assert(Char.ConvertFromUTF32(music)[1] == 0xDD61);
    assert(Char.ConvertToUTF32(Char.ConvertFromUTF32(letter), 0) == 0x0041);
    assert(Char.ConvertToUTF32(Char.ConvertFromUTF32(music), 0) == 0x1D161);
    assert(Char.ConvertToUTF32(Char.ConvertFromUTF32(music)[0], Char.ConvertFromUTF32(music)[1]) == 0x1D161);



    assert(Char.GetNumericValue('8') == 8);
    assert(Char.GetNumericValue('¼') == 1.0 / 4.0);
    assert(Char.GetNumericValue('½') == 1.0 / 2.0);
    assert(Char.GetNumericValue('¾') == 3.0 / 4.0);
    assert(Char.GetNumericValue('⅞') == 7.0 / 8.0);

    assert(Char.GetUnicodeCategory('a') == UnicodeCategory.LowercaseLetter);
    assert(Char.GetUnicodeCategory('A') == UnicodeCategory.UppercaseLetter);
    assert(Char.GetUnicodeCategory('5') == UnicodeCategory.DecimalDigitNumber);
    assert(Char.GetUnicodeCategory('\r') == UnicodeCategory.Control);

    for (wchar c = 0; c < 0xff; c++)
    {
        if (c <= 0x1f || (c >= 0x7f && c <= 0x9f))
            assert(Char.IsControl(c));
        else
            assert(!Char.IsControl(c));

        if (c >= '0' && c <= '9')
            assert(Char.IsDigit(c));
        else
            assert(!Char.IsDigit(c));
    }

    wchar cHigh = 0xd800;
    wchar cLow  = 0xdc00;
    wstring s = ['a', cHigh, cLow, 'z'];
    assert(Char.IsHighSurrogate(cHigh));
    assert(Char.IsLowSurrogate(cLow));
    assert(Char.IsHighSurrogate(s, 1));
    assert(Char.IsLowSurrogate(s, 2));
    assert(Char.IsSurrogatePair(cHigh, cLow));
    assert(Char.IsSurrogatePair(s[1], s[2]));

    //ascii
    for (wchar c = 0x41; c <= 0x5a; c++)
    {
        assert(Char.IsLetter(c));
        assert(Char.IsUpper(c));
    }

    //cyrillic
    for (wchar c = 0x400; c <= 0x42f; c++)
    {
        assert(Char.IsLetter(c));
        assert(Char.IsUpper(c));
    }

    //ascii
    for (wchar c = 0x61; c <= 0x7a; c++)
    {
        assert(Char.IsLetter(c));
        assert(Char.IsLower(c));
    }

    //greek
    for (wchar c = 0x3ac; c <= 0x3ce; c++)
    {
        assert(Char.IsLetter(c));
        assert(Char.IsLower(c));
    }

    //title case
    assert(Char.IsLetter(0x1c5));
    assert(Char.IsLetter(0x1ffc));
    
    //modifiers
    for (wchar c = 0x2b0; c <= 0x2c1; c++)
    {
        assert(Char.IsLetter(c));
    }

    for (wchar c = 0x1d2c; c <= 0x1d61; c++)
    {
        assert(Char.IsLetter(c));
    }

    //hebrew
    assert(Char.IsLetter(0x5d0));
    assert(Char.IsLetter(0x5ea));

    //arabic
    for (wchar c = 0x621; c <= 0x63a; c++)
    {
        assert(Char.IsLetter(c));
    }

    //ideographs
    for (wchar c = 0x4e00; c <= 0x9fc3; c++)
    {
        assert(Char.IsLetter(c));
    }

    assert(Char.IsLetterOrDigit('a'));
    assert(Char.IsLetterOrDigit('3'));

    s = "¹²³¼½¾⅓⅔⅛⅜⅝⅞٠١٢٣٤٥٦٧٨٩01234567890"w;
    foreach(c; s)
        assert(Char.IsNumber(c));

    assert(Char.IsPunctuation('.'));
    assert(Char.IsPunctuation(0x17d8));

    assert(Char.IsSeparator(0x20));
    assert(Char.IsSeparator(0xa0));
    assert(Char.IsSeparator(0x1680));

    for (wchar c = 0x2000; c <= 0x200a; c++)
    {
        assert(Char.IsSeparator(c));
    }

    assert(Char.IsSeparator(0x2028));
    assert(Char.IsSeparator(0x2029));
    assert(Char.IsSeparator(0x202f));
    assert(Char.IsSeparator(0x205f));
    assert(Char.IsSeparator(0x3000));

    assert(Char.IsSymbol('+'));
    assert(Char.IsSymbol('∫'));

    assert(Char.IsWhiteSpace(' '));
    assert(Char.IsWhiteSpace(0x2009));

    assert(Char.Parse("a") == 'a');

    wchar w = 10;

    assert(w.ToByte(null) == 10);
    assert(w.ToSByte(null) == 10);
    assert(w.ToInt16(null) == 10);
    assert(w.ToInt32(null) == 10);
    assert(w.ToInt64(null) == 10);
    assert(w.ToUInt16(null) == 10);
    assert(w.ToUInt32(null) == 10);
    assert(w.ToUInt64(null) == 10);
    assert(w.ToChar(null) == 10);

    assert(Char.ToLower('a') == 'a');
    assert(Char.ToLower('A') == 'a');

    assert(Char.ToLower('ș') == 'ș');
    assert(Char.ToLower('Ș') == 'ș');

    assert(Char.ToLowerInvariant('z') == 'z');
    assert(Char.ToLowerInvariant('Z') == 'z');

    assert(Char.ToLowerInvariant('ț') == 'ț');
    assert(Char.ToLowerInvariant('Ț') == 'ț');
    
    w = 'w';

    assert(w.ToString() == "w");
    assert(Char.ToString(w) == "w");
    assert(w.ToString(null) == "w");

    assert(Char.ToUpper('a') == 'A');
    assert(Char.ToUpper('A') == 'A');

    assert(Char.ToUpper('ș') == 'Ș');
    assert(Char.ToUpper('Ș') == 'Ș');

    assert(Char.ToUpperInvariant('z') == 'Z');
    assert(Char.ToUpperInvariant('Z') == 'Z');

    assert(Char.ToUpperInvariant('ț') == 'Ț');
    assert(Char.ToUpperInvariant('Ț') == 'Ț');
    
    assert(Char.TryParse("a", w));
    assert(!Char.TryParse("abc", w));

}