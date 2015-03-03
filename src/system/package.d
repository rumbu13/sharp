module system;

import system.globalization;
import system.runtime.interopservices;
import system.io;
import system.text;

import internals.resources;
import internals.hresults;
import internals.utf;
import internals.number;
import internals.interop;
import internals.ole32;
import internals.oleauto32;
import internals.checked;
import internals.traits;
import internals.format;
import internals.datetime;
import internals.kernel32;
import internals.registry;
import internals.advapi32;
import internals.user32;
import internals.generics;
import internals.core;
import system.collections.generic;
import system.collections.objectmodel;

import core.stdc.math;
//import core.stdc.string;


// =====================================================================================================================
// SharpObject
// =====================================================================================================================

private extern (C) Object _d_newclass(TypeInfo_Class ci);
private extern (C) void* memcpy(void*, const void*, size_t);

wstring ToString(Object obj)
{
    if (auto sharpObject = cast(SharpObject)obj)
        return sharpObject.ToString();
    return obj.toString().toUTF16();
}

Object MemberwiseClone(Object obj)
{
    if (auto sharpObject = cast(SharpObject)obj)
        return sharpObject.MemberwiseClone();
    if (obj is null)
        return null;
    ClassInfo ci = obj.classinfo;
    size_t start = Object.classinfo.init.length;
    size_t end = ci.init.length;
    Object clone = _d_newclass(ci);
    (cast(void*)clone)[start .. end] = (cast(void*)obj)[start .. end];
    return clone;
}

bool Equals(Object obj, Object other)
{
    if (auto sharpObject = cast(SharpObject)obj)
        return sharpObject.Equals(other);
    return obj is other;
}

int GetHashCode(Object obj)
{
    if (auto sharpObject = cast(SharpObject)obj)
        return sharpObject.GetHashCode();
    return obj is null ? 0 : cast(int)obj.toHash();
}

TypeInfo GetType(Object obj)
{
    if (auto sharpObject = cast(SharpObject)obj)
        return sharpObject.GetType();
    return obj.classinfo;
}

class SharpObject
{
    protected final Object MemberwiseClone()
    {
        return system.MemberwiseClone(this);
    }

    static bool Equals(Object objA, Object objB)
    {
        return object.opEquals(objA, objB);
    }

    static bool ReferenceEquals(Object objA, Object objB) 
    {
        return objA is objB;
    }

    wstring ToString()
    {
        return super.toString().toUTF16();
    }

    final override string toString()
    {
        return ToString().toUTF8();
    }   

    bool Equals(Object other)
    {
        return this is other;
    }

    nothrow @safe
    int GetHashCode()
    {
        return cast(int)super.toHash();
    }

    nothrow @trusted
    final override size_t toHash()
    {
        return GetHashCode();
    }

    final TypeInfo GetType()
    {
        return this.classinfo;
    }
}

// =====================================================================================================================
// SharpException
// =====================================================================================================================

 
@property wstring Message(Throwable t)
{
    if (t is null)
        return null;
    if (t.msg)
        return t.msg.toUTF16();
    return SharpResources.GetString("ExceptionWasThrown", typeid(t).toString());
}

public Throwable GetBaseException(Throwable t)
{
    if (t is null)
        return null;
    Throwable current = t;
    Throwable next = current.next;
    while (next !is null)
    {
        current = next;
        next = current;
    }
    return current;
}

@property Throwable InnerException(Throwable t)
{
    if (t is null)
        return null;
    return t.next;
}

@property wstring StackTrace(Throwable t)
{
    if (t is null)
        return null;
    return t.info is null ? null : t.info.toString().toUTF16();
}

wstring ToString(Throwable t)
{
    if (t is null)
        return null;
    auto e = cast(SharpException)t;
    wstring em = e ? e.Message : system.Message(t);
    wstring en = t.classinfo.name.toUTF16();
    wstring m = String.IsNullOrEmpty(em) ? en: en ~ ": " ~ em;
    if (t.next !is null)
    {
        m ~= " ---> ";
        auto se = cast(SharpException)t.next;
        m ~= se ? se.ToString() : ToString(t.next);
        m ~= Environment.NewLine;
        m ~= "   ";
        m ~= SharpResources.GetString("ExceptionEndOfInnerStackTrace");
    }

    wstring s = e ? e.StackTrace : system.StackTrace(t);
    if (!String.IsNullOrEmpty(s))
    {
        m ~= Environment.NewLine;
        m ~= s;
    }

    return m;
}

@property int HResult(Throwable t) 
{ 
    if (auto sharpException = cast(SharpException)t)
        return sharpException.HResult;
    return E_FAIL; 
}

@property wstring HelpLink(Throwable t) 
{
    if (auto sharpException = cast(SharpException)t)
        return sharpException.HelpLink;
    return null; 
}

@property wstring Source(Throwable t) 
{
    if (auto sharpException = cast(SharpException)t)
        return sharpException.Source;
    return null; 
}


class SharpException : Exception
{
private:
    int hResult;
    wstring helpLink;
    wstring source;

public:
    final protected Object MemberwiseClone()
    {
        return system.MemberwiseClone(this);
    }

    this()
    {
        super(null);
        hResult = COR_E_EXCEPTION;
    }

    this(wstring message)
    {
        super(message.toUTF8());
        hResult = COR_E_EXCEPTION;
    }

    this(wstring message, Throwable next)
    {
        super(message.toUTF8(), next);
        hResult = COR_E_EXCEPTION;
    }
 
    @property wstring HelpLink()
    {
        return helpLink;
    }

    @property wstring HelpLink(wstring value)
    {
        return helpLink = value;
    }

    @property wstring Source()
    {
        return source;
    }

    @property wstring Source(wstring value)
    {
        return source = value;
    }

    @property final int HResult()
    {
        return hResult;
    }

    @property HResult(int value)
    {
        return hResult = value;
    }

    @property wstring StackTrace()
    {
        return system.StackTrace(this);
    }

    @property wstring Message()
    {
        return system.Message(this);
    }

    @property final InnerException()
    {
        return system.InnerException(this);
    }

    final override string toString()
    {
        return ToString().toUTF8();
    }   

    bool Equals(Object other)
    {
        return this is other;
    }

    nothrow @safe
    int GetHashCode()
    {
        return cast(int)super.toHash();
    }

    nothrow @trusted
    final override size_t toHash()
    {
        return GetHashCode();
    }

    final TypeInfo GetType()
    {
        return this.classinfo;
    }

    wstring ToString()
    {
        return system.ToString(this);
    }

}

// =====================================================================================================================
// SystemException
// =====================================================================================================================

class SystemException: SharpException
{
    this()
    {
        super(SharpResources.GetString("ExceptionSystem"));
        hResult = COR_E_SYSTEM;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_SYSTEM;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_SYSTEM;
    }
}

// =====================================================================================================================
// ArgumentException
// =====================================================================================================================

class ArgumentException : SystemException
{
private:
    wstring paramName;

public:
    this()
	{
        super(SharpResources.GetString("ExceptionArgument"));
        hResult = COR_E_ARGUMENT;
	}

    this(wstring msg)
	{
        super(msg);
        hResult = COR_E_ARGUMENT;
	}

    this(wstring msg, Throwable next)
	{
        super(msg, next);
        hResult = COR_E_ARGUMENT;
	}

    this(wstring msg, wstring paramName)
	{
        super(msg);
        hResult = COR_E_ARGUMENT;
        this.paramName = paramName;
	}

    this(wstring msg, wstring paramName, Throwable next)
	{
        super(msg, next);
        hResult = COR_E_ARGUMENT;
        this.paramName = paramName;
	}

    @property wstring ParamName()
    {
        return paramName;
    }

    @property override wstring Message()
    {
        if (String.IsNullOrEmpty(paramName))
            return super.Message;
        else 
            return super.Message ~ Environment.NewLine ~ SharpResources.GetString("ParameterName", paramName);
    }
}

// =====================================================================================================================
// ArgumentNullException
// =====================================================================================================================

class ArgumentNullException : ArgumentException
{
    this()
	{
        super(SharpResources.GetString("ExceptionArgumentNull"));
        hResult = E_POINTER;
	}

    this(wstring paramName)
	{
        super(SharpResources.GetString("ExceptionArgumentNull"), paramName);
        hResult = E_POINTER;
	}

    this(wstring msg, Throwable next)
	{
        super(msg, next);
        hResult = E_POINTER;
	}

    this(wstring paramName, wstring msg)
	{
        super(msg, paramName);
        hResult = E_POINTER;
	}
}

// =====================================================================================================================
// ArgumentOutOfRangeException
// =====================================================================================================================

class ArgumentOutOfRangeException: ArgumentException
{
private:
    Object actualValue;

public:
	this()
	{
        super(SharpResources.GetString("ExceptionArgumentOutOfRange"));
        hResult = COR_E_ARGUMENTOUTOFRANGE;
	}

    this(wstring paramName)
	{
        super(SharpResources.GetString("ExceptionArgumentOutOfRange"), paramName);
        hResult = COR_E_ARGUMENTOUTOFRANGE;
	}

    this(wstring msg, Throwable next)
	{
        super(msg, next);
        hResult = COR_E_ARGUMENTOUTOFRANGE;
	}

    this(wstring paramName, Object actualValue, wstring msg)
    {
        super(msg, paramName);
        this.actualValue = actualValue;
        hResult = COR_E_ARGUMENTOUTOFRANGE;
    }

    this(T)(wstring paramName, T actualValue, wstring msg)
    {
        super(msg, paramName);
        this.actualValue = box(actualValue);
        hResult = COR_E_ARGUMENTOUTOFRANGE;
    }

    this(wstring paramName, wstring msg)
	{
        super(msg, paramName);
        hResult = COR_E_ARGUMENTOUTOFRANGE;
	}

    @property Object ActualValue()
    {
        return actualValue;
    }

    @property override wstring Message()
    {
        wstring m = super.Message;
        if (actualValue !is null)
        {
            wstring v = SharpResources.GetString("ExceptionArgumentOutOfRangeActualValue", actualValue);
            return String.IsNullOrEmpty(m) ? v : m ~ Environment.NewLine ~ v;
        }
        return m;
    }
}

// =====================================================================================================================
// FormatException
// =====================================================================================================================

class FormatException: SharpException
{
    this()
    {
        super(SharpResources.GetString("ExceptionFormat"));
        hResult = COR_E_FORMAT;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_FORMAT;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_FORMAT;
    }
}

// =====================================================================================================================
// NotImplementedException
// =====================================================================================================================

class NotImplementedException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionNotImplemented"));
        hResult = E_NOTIMPL;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = E_NOTIMPL;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = E_NOTIMPL;
    }
}

// =====================================================================================================================
// InvalidCastException
// =====================================================================================================================

class InvalidCastException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionInvalidCast"));
        hResult = COR_E_INVALIDCAST;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_INVALIDCAST;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_INVALIDCAST;
    }
}

// =====================================================================================================================
// TypeLoadException
// =====================================================================================================================

class TypeLoadException : SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionTypeLoad"));
        hResult = COR_E_TYPELOAD;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_TYPELOAD;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_TYPELOAD;
    }
}

// =====================================================================================================================
// EntryPointNotFoundException
// =====================================================================================================================

class EntryPointNotFoundException : TypeLoadException
{
    this()
    {
        super(SharpResources.GetString("ExceptionEntryPointNotFound"));
        hResult = COR_E_ENTRYPOINTNOTFOUND;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_ENTRYPOINTNOTFOUND;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_ENTRYPOINTNOTFOUND;
    }
}

// =====================================================================================================================
// DLLNotFoundException
// =====================================================================================================================

class DLLNotFoundException : TypeLoadException
{
    this()
    {
        super(SharpResources.GetString("ExceptionDllNotFound"));
        hResult = COR_E_DLLNOTFOUND;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_DLLNOTFOUND;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_DLLNOTFOUND;
    }
}

// =====================================================================================================================
// ArithmeticException
// =====================================================================================================================

class ArithmeticException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionArithmetic"));
        hResult = COR_E_ARITHMETIC;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_ARITHMETIC;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_ARITHMETIC;
    }
}

// =====================================================================================================================
// InvalidOperationException
// =====================================================================================================================

class InvalidOperationException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionInvalidOperation"));
        hResult = COR_E_INVALIDOPERATION;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_INVALIDOPERATION;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_INVALIDOPERATION;
    }
}

// =====================================================================================================================
// NotSupportedException
// =====================================================================================================================

class NotSupportedException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionNotSupported"));
        hResult = COR_E_NOTSUPPORTED;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_NOTSUPPORTED;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_NOTSUPPORTED;
    }
}

// =====================================================================================================================
// ObjectDisposedException
// =====================================================================================================================

class ObjectDisposedException: InvalidOperationException
{
private:
    wstring objectName;

public:
    this()
    {
        super(SharpResources.GetString("ExceptionObjectDisposed"));
        hResult = COR_E_OBJECTDISPOSED;
    }

    this(wstring objectName)
    {
        this();
        this.objectName = objectName;
    }

    this(wstring objectName, wstring msg)
    {
        super(msg);
        this.objectName = objectName;
        hResult = COR_E_OBJECTDISPOSED;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_OBJECTDISPOSED;
    }

    wstring ObjectName()
    {
        return objectName;
    }

    override @property wstring Message()
    {
        if (objectName.length == 0)
            return super.Message;
        return super.Message ~ Environment.NewLine ~ SharpResources.GetString("ObjectName", objectName);
    }
}

// =====================================================================================================================
// OutOfMemoryException
// =====================================================================================================================

class OutOfMemoryException: SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionOutOfMemory"));
        hResult = COR_E_OUTOFMEMORY;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_OUTOFMEMORY;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_OUTOFMEMORY;
    }
}

// =====================================================================================================================
// OverflowException
// =====================================================================================================================

class OverflowException : ArithmeticException
{
    this()
    {
        super(SharpResources.GetString("ExceptionOverflow"));
        hResult = COR_E_OVERFLOW;
    }

    this(wstring msg)
    {
        super(msg);
        hResult = COR_E_OVERFLOW;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        hResult = COR_E_OVERFLOW;
    }
}

// =====================================================================================================================
// InvalidTimeZoneException
// =====================================================================================================================

class InvalidTimeZoneException : SharpException
{
    this()
    {

    }

    this(wstring msg)
    {
        super(msg);
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
    }
}

// =====================================================================================================================
// TimeZoneNotFoundException
// =====================================================================================================================

class TimeZoneNotFoundException : SharpException 
{
    this()
    {

    }

    this(wstring msg)
    {
        super(msg);
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
    }
}

// =====================================================================================================================
// UnauthorizedAccessException
// =====================================================================================================================

class UnauthorizedAccessException : IOException
{
    this()
    {
        super(SharpResources.GetString("ExceptionUnauthorizedAccess"));
        HResult = COR_E_UNAUTHORIZEDACCESS;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = COR_E_UNAUTHORIZEDACCESS;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = COR_E_UNAUTHORIZEDACCESS;
    }
}

struct Attribute {}

struct Flags
{
    Attribute attribute;
    alias attribute this;
}

struct Serializable
{
    Attribute attribute;
    alias attribute this;
}

struct NonSerialized
{
    Attribute attribute;
    alias attribute this;
}

// =====================================================================================================================
// Boolean
// =====================================================================================================================

struct Boolean
{
    static bool opCall() { return false; }
    @property static wstring TrueString() { return "True"; }
    @property static wstring FalseString() { return "False"; }

    static bool TryParse(wstring s, out bool result)
    {
        if (String.IsNullOrEmpty(s))
            return false;

        auto i = 0;
        while (i < s.length && (Char.IsWhiteSpace(s[i]) || s[i] == 0))
            i++;
        auto j = s.length - 1;
        while (j >= i && (Char.IsWhiteSpace(s[j]) || s[j] == 0))
            j--;

        s = s[i .. j + 1];

        if (String.Equals(s, TrueString, StringComparison.OrdinalIgnoreCase))
        {
            result = true;
            return true;
        }

        if (String.Equals(s, FalseString, StringComparison.OrdinalIgnoreCase))
        {
            result = false;
            return true;
        }
        return false;
    }

    static bool Parse(wstring s)
    {
        checkNull(s, "s");
        bool result;
        if (!TryParse(s, result))
            throw new FormatException();
        return result;
    }
}

@safe nothrow
int GetHashCode(bool b)
{
    return b ? 1 : 0;
}

TypeCode GetTypeCode(bool b)
{
    return TypeCode.Boolean;
}

wstring ToString(bool b)
{
    return b ? Boolean.TrueString : Boolean.FalseString;
}

wstring ToString(bool b, IFormatProvider provider)
{
    return b ? Boolean.TrueString : Boolean.FalseString;
}

bool Equals(bool b, Object obj)
{
    if (auto ob = cast(ValueType!bool)obj)
       return b == ob.value;
    return false;
}

int CompareTo(bool b, Object obj)
{
    if (auto ob = cast(ValueType!bool)obj)
    {
        if (b == ob.value)
            return 0;
        if (b == false)
            return -1;
        return 1;
    }
    throw new ArgumentException();
}

wchar ToChar(bool b, IFormatProvider provider) { return invalidCast!(bool, wchar)(); }
byte ToSByte(bool b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(bool b, IFormatProvider provider) { return Convert.ToByte(b); }
short ToInt16(bool b, IFormatProvider provider) { return Convert.ToInt16(b); }
ushort ToUInt16(bool b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(bool b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(bool b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(bool b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(bool b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(bool b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(bool b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(bool b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(bool b, IFormatProvider provider) { return invalidCast!(bool, DateTime)(); }

// =====================================================================================================================
// Char
// =====================================================================================================================

struct Char
{
    static wchar opCall() { return wchar.init; }

    enum MinValue = wchar.min;
    enum MaxValue = wchar.max;

    static UnicodeCategory GetUnicodeCategory(wchar c)
    {
        return CharUnicodeInfo.GetUnicodeCategory(c);
    }

    static UnicodeCategory GetUnicodeCategory(C)(wstring s, int index)
    {
        return CharUnicodeInfo.GetUnicodeCategory(s, index);
    }

    static double GetNumericValue(wchar c)
    {
        return CharUnicodeInfo.GetNumericValue(c);
    }

    static double GetNumericValue(wstring s, int index)
    {
        return CharUnicodeInfo.GetNumericValue(s, index);
    }

    static bool IsControl(wchar ch)
    {
        return CharUnicodeInfo.GetUnicodeCategory(ch) == UnicodeCategory.Control;
    }

    static bool IsControl(wstring s, int index)
    {
        return CharUnicodeInfo.GetUnicodeCategory(s, index) == UnicodeCategory.Control;
    }

    static bool IsDigit(wchar ch)
    {
        return CharUnicodeInfo.GetUnicodeCategory(ch) == UnicodeCategory.DecimalDigitNumber;
    }

    static bool IsDigit(wstring s, int index)
    {
        return CharUnicodeInfo.GetUnicodeCategory(s, index) == UnicodeCategory.DecimalDigitNumber;
    }

    static bool IsLetter(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.UppercaseLetter ||
                c == UnicodeCategory.LowercaseLetter ||
                c == UnicodeCategory.TitlecaseLetter ||
                c == UnicodeCategory.ModifierLetter ||
                c == UnicodeCategory.OtherLetter;
    }

    static bool IsLetter(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.UppercaseLetter ||
                c == UnicodeCategory.LowercaseLetter ||
                c == UnicodeCategory.TitlecaseLetter ||
                c == UnicodeCategory.ModifierLetter ||
                c == UnicodeCategory.OtherLetter;
    }

    static bool IsLetterOrDigit(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.UppercaseLetter ||
                c == UnicodeCategory.LowercaseLetter ||
                c == UnicodeCategory.TitlecaseLetter ||
                c == UnicodeCategory.ModifierLetter ||
                c == UnicodeCategory.OtherLetter ||
                c == UnicodeCategory.DecimalDigitNumber;
    }

    static bool IsLetterOrDigit(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.UppercaseLetter ||
                c == UnicodeCategory.LowercaseLetter ||
                c == UnicodeCategory.TitlecaseLetter ||
                c == UnicodeCategory.ModifierLetter ||
                c == UnicodeCategory.OtherLetter ||
                c == UnicodeCategory.DecimalDigitNumber;
    }

    static bool IsLower(wchar ch)
    {
        return CharUnicodeInfo.GetUnicodeCategory(ch) == UnicodeCategory.LowercaseLetter;
    }

    static bool IsLower(wstring s, int index)
    {
        return CharUnicodeInfo.GetUnicodeCategory(s, index) == UnicodeCategory.LowercaseLetter;
    }

    static bool IsNumber(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.DecimalDigitNumber ||
                c == UnicodeCategory.LetterNumber ||
                c == UnicodeCategory.OtherNumber;
    }

    static bool IsNumber(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.DecimalDigitNumber ||
                c == UnicodeCategory.LetterNumber ||
                c == UnicodeCategory.OtherNumber;
    }

    static bool IsSymbol(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.MathSymbol ||
                c == UnicodeCategory.CurrencySymbol ||
                c == UnicodeCategory.ModifierSymbol ||
                c == UnicodeCategory.OtherSymbol;
    }

    static bool IsSymbol(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.MathSymbol ||
                c == UnicodeCategory.CurrencySymbol ||
                c == UnicodeCategory.ModifierSymbol ||
                c == UnicodeCategory.OtherSymbol;
    }

    static bool IsUpper(wchar ch)
    {
        return CharUnicodeInfo.GetUnicodeCategory(ch) == UnicodeCategory.UppercaseLetter;
    }

    static bool IsUpper(wstring s, int index)
    {
        return CharUnicodeInfo.GetUnicodeCategory(s, index) == UnicodeCategory.UppercaseLetter;
    }

    static bool IsWhiteSpace(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.SpaceSeparator ||
                c == UnicodeCategory.LineSeparator ||
                c == UnicodeCategory.ParagraphSeparator;
    }

    static bool IsWhiteSpace(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.SpaceSeparator ||
                c == UnicodeCategory.LineSeparator ||
                c == UnicodeCategory.ParagraphSeparator;
    }

    static bool IsPunctuation(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.ConnectorPunctuation ||
                c == UnicodeCategory.DashPunctuation ||
                c == UnicodeCategory.OpenPunctuation ||
                c == UnicodeCategory.ClosePunctuation ||
                c == UnicodeCategory.InitialQuotePunctuation ||
                c == UnicodeCategory.FinalQuotePunctuation ||
                c == UnicodeCategory.OtherPunctuation;
    }

    static bool IsPunctuation(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.ConnectorPunctuation ||
                c == UnicodeCategory.DashPunctuation ||
                c == UnicodeCategory.OpenPunctuation ||
                c == UnicodeCategory.ClosePunctuation ||
                c == UnicodeCategory.InitialQuotePunctuation ||
                c == UnicodeCategory.FinalQuotePunctuation ||
                c == UnicodeCategory.OtherPunctuation;
    }

    static bool IsSeparator(wchar ch)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(ch);
        return  c == UnicodeCategory.SpaceSeparator ||
                c == UnicodeCategory.LineSeparator ||
                c == UnicodeCategory.ParagraphSeparator;
    }

    static bool IsSeparator(wstring s, int index)
    {
        UnicodeCategory c = CharUnicodeInfo.GetUnicodeCategory(s, index);
        return  c == UnicodeCategory.SpaceSeparator ||
                c == UnicodeCategory.LineSeparator ||
                c == UnicodeCategory.ParagraphSeparator;
    }

    static bool IsHighSurrogate(wchar ch)
    {
        return ch >= 0xd800 && ch <= 0xdbff; 
    }

    static bool IsHighSurrogate(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index); 
        return s[index] >= 0xd800 && s[index] <= 0xd800; 
    }

    static bool IsLowSurrogate(wchar ch)
    {
        return ch >= 0xdc00 && ch <= 0xdfff; 
    }

    static bool IsLowSurrogate(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index); 
        return s[index] >= 0xdc00 && s[index] <= 0xdfff; 
    }

    static bool IsSurrogatePair(wchar high, wchar low)
    {
        return IsHighSurrogate(high) && IsLowSurrogate(low);
    }

    static bool IsSurrogate(wchar ch)
    {
        return IsHighSurrogate(ch) || IsLowSurrogate(ch);
    }

    static bool IsSurrogatePair(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index); 
        return index < s.length - 1 && IsHighSurrogate(s[index]) && IsLowSurrogate(s[index + 1]);
    }

    static wstring ConvertFromUTF32(int ch)
    {
        if ((ch < 0x10000 && IsSurrogate(cast(wchar)ch)) || ch >= 0x10ffff)
            throw new ArgumentOutOfRangeException("ch", SharpResources.GetString("ArgumentInvalidUTF32"));
        if (ch < 0x10000)
            return [cast(wchar)ch];
        else
            return [cast(wchar)((ch >> 10) + 0xd7c0), cast(wchar)((ch & 0x3ff) + 0xdc00)];   
    }

    static int ConvertToUTF32(wchar high, wchar low)
    {
        if (!IsHighSurrogate(high))
            throw new ArgumentOutOfRangeException("high", SharpResources.GetString("ArgumentInvalidHighSurrogate"));
        if (!IsLowSurrogate(low))
            throw new ArgumentOutOfRangeException("low", SharpResources.GetString("ArgumentInvalidLowSurrogate"));
        return cast(dchar)((high << 10) + low) - 0x35FDC00;
    }

    static int ConvertToUTF32(wstring s, int index)
    {
        checkNull(s, "s");
        checkIndex(s, index);
        if (IsHighSurrogate(s[index]) && index < s.length - 1 && IsLowSurrogate(s[index + 1]))
            return ConvertToUTF32(s[index], s[index + 1]);
        if (!IsSurrogate(s[index]))
            return s[index];
        if ((IsHighSurrogate(s[index]) && index == s.length - 1) || IsLowSurrogate(s[index]))
            throw new ArgumentOutOfRangeException("s", SharpResources.GetString("ArgumentInvalidHighSurrogate"));    
        throw new ArgumentOutOfRangeException("s", SharpResources.GetString("ArgumentInvalidLowSurrogate"));
    }

    static bool TryParse(wstring s, out wchar result)
    {
        if (s.length != 1)
            return false;
        result = s[0];
        return true;
    }

    static wchar Parse(wstring s)
    {
        wchar ret;
        if (!TryParse(s, ret))
            throw new FormatException(SharpResources.GetString("ArgumentStringOneChar"));
        return ret;
    }

    static wstring ToString(wchar ch)
    {
        return [ch];
    }    

    static wchar ToUpperInvariant(wchar ch)
    {
        return CharUnicodeInfo.getUppercaseChar(ch);
    }

    static wchar ToLowerInvariant(wchar ch)
    {
        return CharUnicodeInfo.getLowercaseChar(ch);
    }

    static wchar ToLower(wchar ch, CultureInfo culture)
    {
        checkNull(culture, "culture");
        return culture.TextInfo.ToLower(ch);
    }

    static wchar ToLower(wchar ch)
    {
        return CultureInfo.CurrentCulture.TextInfo.ToLower(ch);
    }

    static wchar ToUpper(wchar ch, CultureInfo culture)
    {
        checkNull(culture, "culture");
        return culture.TextInfo.ToUpper(ch);
    }

    static wchar ToUpper(wchar ch)
    {
        return CultureInfo.CurrentCulture.TextInfo.ToUpper(ch);
    }
}

wchar ToChar(wchar b, IFormatProvider provider) { return b; }
byte ToSByte(wchar b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(wchar b, IFormatProvider provider) { return Convert.ToByte(b); }
short ToInt16(wchar b, IFormatProvider provider) {return Convert.ToInt16(b); }
wchar ToUInt16(wchar b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(wchar b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(wchar b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(wchar b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(wchar b, IFormatProvider provider) { return Convert.ToUInt64(b); }
DateTime ToDateTime(wchar b, IFormatProvider provider) { return invalidCast!(wchar, DateTime)(); }

wstring ToString(wchar ch)
{
    return [ch];
}

wstring ToString(wchar ch, IFormatProvider provider)
{
    return ToString(ch);
}

bool Equals(wchar ch, Object obj)
{
    if (auto vt = cast(ValueType!wchar)obj)
        return vt.value == ch;
    return false;
}

int CompareTo(wchar ch, Object obj)
{
    if (auto vt = cast(ValueType!wchar)obj)
        return vt.CompareTo(ch);
    throw new ArgumentException(SharpResources.GetString("ArgumentMustBeType", "wchar"));
}

@safe nothrow
int GetHashCode(wchar ch)
{
    return ch;
}

bool ToBoolean(wchar ch, IFormatProvider provider)
{
    return invalidCast!(wchar, bool)();
}

float ToSingle(wchar ch, IFormatProvider provider)
{
    
    return invalidCast!(wchar, float)();
}

double ToDouble(wchar ch, IFormatProvider provider)
{
    return invalidCast!(wchar, double)();
}

decimal ToDecimal(wchar ch, IFormatProvider provider)
{
    return invalidCast!(wchar, decimal)();
}

TypeCode GetTypeCode(wchar c)
{
    return TypeCode.Char;
}

// =====================================================================================================================
// String
// =====================================================================================================================

struct String
{
    static wstring opCall()
    {
        return null;
    }

    enum Empty = ""w;

    static wstring opCall(wchar* sz)
    {
        checkNull(sz);
        if (*sz == 0)
            return [];
        wchar* ptr = sz;
        size_t len = 0;
        while(*ptr++ != 0 && len <= ushort.max)
            len++;
        if (len > ushort.max)
            throw new ArgumentOutOfRangeException();
        return sz[0 .. len].idup;
    }

    static wstring opCall(wchar* sz, int startIndex, int length)
    {

        checkNull(sz);
        if (startIndex < 0)
            throw new ArgumentOutOfRangeException("startIndex");
        if (length < 0 || length > ushort.max)
            throw new ArgumentOutOfRangeException("length");
        return sz[startIndex .. startIndex + length].idup;
    }

    static wstring opCall(byte* sz)
    {
        checkNull(sz);
        if (*sz == 0)
            return [];
        byte* ptr = sz;
        size_t len = 0;
        while(*ptr++ != 0 && len <= ushort.max)
            len++;
        if (len > ushort.max)
            throw new ArgumentOutOfRangeException();
        wchar[] ret = new wchar[len];
        for(size_t i = 0; i < len; i++)
            ret[i] = sz[i];
        return cast(wstring)ret;
    }

    static wstring opCall(byte* sz, int startIndex, int length)
    {

        checkNull(sz);
        if (startIndex < 0)
            throw new ArgumentOutOfRangeException("startIndex");
        if (length < 0 || length > ushort.max)
            throw new ArgumentOutOfRangeException("length");
        wchar[] ret = new wchar[length];
        for (auto i = 0; i < length; i++)
            ret[i] = sz[startIndex + i];
        return cast(wstring)ret;
    }

    static opCall(wchar[] value)
    {
        checkNull(value);
        return value.idup;
    }

    static opCall(wchar[] value, int startIndex, int length)
    {
        checkNull(value);
        checkIndex(value, startIndex, length, "startIndex", "length");
    }

    static opCall(wchar c, int count)
    {
        if (count < 0)
            throw new ArgumentOutOfRangeException("count");
        wchar[] ret = new wchar[count];
        ret[] = c;
        return cast(wstring)ret;
    }

    //todo sbyte* with encoding

    static wstring Format(A...)(wstring fmt, A args) if (A.length > 0)
    {
        return compositeFormat(fmt, CultureInfo.CurrentCulture, args);
    }

    static wstring Format(A...)(IFormatProvider provider, wstring fmt, A args) if (A.length > 0)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        return compositeFormat(fmt, provider, args);
    }

    static bool IsNullOrEmpty(wstring s)
    {
        return s.length == 0;   
    }

    static int Compare(wstring strA, int indexA, wstring strB, int indexB, int length, CultureInfo culture, CompareOptions options)
    {        
        checkNull(culture, "culture");
        auto l1 = length;
        auto l2 = length;
        if (strA !is null) 
        {
            if (strA.length - indexA < l1) 
                l1 = strA.length - indexA;
        }
        if (strB !is null) 
        {
            if (strB.length - indexB < l2) 
                l2 = strB.length - indexB;
        }
        return culture.CompareInfo.Compare(strA, indexA, l1, strB, indexB, l2, options);
    }

    static int Compare(wstring strA, wstring strB, bool ignoreCase)
    {
        return CultureInfo.CurrentCulture.CompareInfo.Compare(
                    strA, strB, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
    }

    static int Compare(wstring strA, wstring strB)
    {
        return CultureInfo.CurrentCulture.CompareInfo.Compare(strA, strB);
    }

    static int Compare(wstring strA, int indexA, wstring strB, int indexB, int length, bool ignoreCase)
    {
        return Compare(strA, indexA, strB, indexB, length, 
                       CultureInfo.CurrentCulture, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
    }

    static int Compare(wstring strA, int indexA, wstring strB, int indexB, bool ignoreCase)
    {
        return Compare(strA, indexA, strB, indexB, 
                       strA.length - indexA <= strB.length - indexB ? strA.length - indexA : strB.length - indexB, 
                       CultureInfo.CurrentCulture, ignoreCase ? CompareOptions.IgnoreCase : CompareOptions.None);
    }

    static int Compare(wstring strA, wstring strB, CultureInfo culture)
    {
        checkNull(culture);
        return CultureInfo.CurrentCulture.CompareInfo.Compare(strA, strB);
    }

    static int Compare(wstring strA, int indexA, wstring strB, int indexB, int length)
    {
        return Compare(strA, indexA, strB, indexB, length, CultureInfo.CurrentCulture, CompareOptions.None);
    }

    static int Compare(wstring strA, wstring strB, StringComparison comparison)
    {
        if (strA is strB)
            return 0;
        if (strA is null)
            return -1;
        if (strB is null)
            return 1;
        final switch(comparison)
        {
            case StringComparison.CurrentCulture:
                return Compare(strA, 0, strB, 0, 
                               strA.length <= strB.length ? strA.length : strB.length, 
                               CultureInfo.CurrentCulture, CompareOptions.None);
            case StringComparison.CurrentCultureIgnorecase:
                return Compare(strA, 0, strB, 0, 
                               strA.length <= strB.length ? strA.length : strB.length, 
                               CultureInfo.CurrentCulture, CompareOptions.IgnoreCase);
            case StringComparison.InvariantCulture:
                return Compare(strA, 0, strB, 0, 
                               strA.length <= strB.length ? strA.length : strB.length, 
                               CultureInfo.InvariantCulture, CompareOptions.None);
            case StringComparison.InvariantCultureIgnorecase:
                return Compare(strA, 0, strB, 0, 
                               strA.length <= strB.length ? strA.length : strB.length, 
                               CultureInfo.CurrentCulture, CompareOptions.IgnoreCase);
            case StringComparison.Ordinal:
                return Compare(strA, 0, strB, 0, 
                               strA.length <= strB.length ? strA.length : strB.length, 
                               CultureInfo.InvariantCulture, CompareOptions.OrdinalIgnoreCase);
            case StringComparison.OrdinalIgnoreCase:
                return Compare(strA, 0, strB, 0, 
                               strA.length <= strB.length ? strA.length : strB.length, 
                               CultureInfo.InvariantCulture, CompareOptions.OrdinalIgnoreCase);
        }
    }

    static int Compare(wstring strA, wstring strB, CultureInfo culture, CompareOptions options)
    {
        checkNull(culture, "culture");
        return culture.CompareInfo.Compare(strA, strB, options);
    }
    
    static int Compare(wstring strA, int indexA, wstring strB, int indexB, int length, StringComparison comparison)
    {
        final switch(comparison)
        {
            case StringComparison.CurrentCulture:
                return Compare(strA, indexA, strB, indexB, length, CultureInfo.CurrentCulture, CompareOptions.None);
            case StringComparison.CurrentCultureIgnorecase:
                return Compare(strA, indexA, strB, indexB, length, CultureInfo.CurrentCulture, CompareOptions.IgnoreCase);
            case StringComparison.InvariantCulture:
                return Compare(strA, indexA, strB, indexB, length, CultureInfo.InvariantCulture, CompareOptions.None);
            case StringComparison.InvariantCultureIgnorecase:
                return Compare(strA, indexA, strB, indexB, length, CultureInfo.InvariantCulture, CompareOptions.IgnoreCase);
            case StringComparison.Ordinal:
                return Compare(strA, indexA, strB, indexB, length, CultureInfo.InvariantCulture, CompareOptions.Ordinal);
            case StringComparison.OrdinalIgnoreCase:
                return Compare(strA, indexA, strB, indexB, length, CultureInfo.InvariantCulture, CompareOptions.OrdinalIgnoreCase);
        }
    }

    static int CompareOrdinal(wstring strA, wstring strB)
    {
        if (strA is strB)
            return 0;
        if (strA is null)
            return -1;
        if (strB is null)
            return 0;
        if (strA.length == 0 && strB.length == 0)
            return 0;
        if (strA.length == 0)
            return -1;
        if (strB.length == 0)
            return 1;
        if (strA[0] > strB[0])
            return 1;
        if (strA[0] < strB[0])
            return - 1;
        return Compare(strA, strB, StringComparison.Ordinal);
    }

    static int CompareOrdinal(wstring strA, int indexA, wstring strB, int indexB, int length)
    {
        if (strA is strB)
            return 0;
        if (strA is null)
            return -1;
        if (strB is null)
            return 0;
        if (strA.length == 0 && strB.length == 0)
            return 0;
        if (strA.length == 0)
            return -1;
        if (strB.length == 0)
            return 1;
        if (strA[0] > strB[0])
            return 1;
        if (strA[0] < strB[0])
            return - 1;
        return Compare(strA, strB, StringComparison.Ordinal);
    }

    static wstring Concat(T)(T enumerable) if (isEnumerable!(T, wstring))
    {
        wstring ret;
        foreach(w; enumerable)
            ret ~= w;
        return ret;
    }

    static wstring Concat(T, U)(T enumerable) if (isEnumerable!(T, U))
    {
        wstring ret;
        foreach(a; enumerable)
            ret ~= argumentFormat!U(null, &a, CultureInfo.CurrentCulture, null);
        return ret;
    }

    static wstring Concat(T...)(T args)
    {
        wstring ret;
        foreach(i, U; T)
            ret ~= argumentFormat!U(null, &args[i], CultureInfo.CurrentCulture, null);
        return ret;
    }

    static bool Equals(wstring str1, wstring str2, StringComparison comparison)
    {
        wstring s = String.Concat(str1, str2);
        checkEnum(comparison, "comparison");

        if (str1 is str2)
            return true;
        if (str1 is null || str2 is null)
            return false;
        final switch(comparison)
        {
            case StringComparison.CurrentCulture:
                return CultureInfo.CurrentCulture.CompareInfo.Compare(str1, str2) == 0;
            case StringComparison.CurrentCultureIgnorecase:
                return CultureInfo.CurrentCulture.CompareInfo.Compare(str1, str2, CompareOptions.IgnoreCase) == 0;
            case StringComparison.InvariantCulture:
                return CultureInfo.InvariantCulture.CompareInfo.Compare(str1, str2) == 0;
            case StringComparison.InvariantCultureIgnorecase:
                return CultureInfo.InvariantCulture.CompareInfo.Compare(str1, str2, CompareOptions.IgnoreCase) == 0;
            case StringComparison.Ordinal:
                return CultureInfo.InvariantCulture.CompareInfo.Compare(str1, str2) == 0;
            case StringComparison.OrdinalIgnoreCase:
                return CultureInfo.InvariantCulture.CompareInfo.Compare(str1, str2, CompareOptions.IgnoreCase) == 0;
        }
    }

    static bool Equals(wstring str1, wstring str2)
    {
        return Equals(str1, str2, StringComparison.CurrentCulture);
    }
}

wstring Clone(wstring s)
{
    return s.idup;
}

enum StringComparison
{
    CurrentCulture,
    CurrentCultureIgnorecase,
    InvariantCulture,
    InvariantCultureIgnorecase,
    Ordinal,
    OrdinalIgnoreCase,
}

int IndexOf(wstring s, wstring value, int index, int count, StringComparison comparisonType)
{
    checkNull(value);
    if (value.length == 0)
        return 0;
    checkIndex(s, index, count);
    checkEnum(comparisonType, "comparisonType");
    final switch (comparisonType)
    {
        case StringComparison.CurrentCulture:
            return CultureInfo.CurrentCulture.CompareInfo.IndexOf(s, value, index, count, CompareOptions.None);
        case StringComparison.CurrentCultureIgnorecase:
            return CultureInfo.CurrentCulture.CompareInfo.IndexOf(s, value, index, count, CompareOptions.IgnoreCase);
        case StringComparison.InvariantCulture:
            return CultureInfo.InvariantCulture.CompareInfo.IndexOf(s, value, index, count, CompareOptions.None);
        case StringComparison.InvariantCultureIgnorecase:
            return CultureInfo.InvariantCulture.CompareInfo.IndexOf(s, value, index, count, CompareOptions.IgnoreCase);
        case StringComparison.Ordinal:
            return CultureInfo.InvariantCulture.CompareInfo.IndexOf(s, value, index, count, CompareOptions.Ordinal);
        case StringComparison.OrdinalIgnoreCase:
            return CultureInfo.InvariantCulture.CompareInfo.IndexOf(s, value, index, count, CompareOptions.OrdinalIgnoreCase);
    }
}

int IndexOf(wstring s, wstring value, int index, StringComparison comparisonType)
{
    return IndexOf(s, value, index, s.length - index, comparisonType);
}

int IndexOf(wstring s, wstring value, StringComparison comparisonType)
{
    return IndexOf(s, value, 0, s.length, comparisonType);
}

int IndexOf(wstring s, wstring value)
{
    return IndexOf(s, value, 0, s.length, StringComparison.CurrentCulture);
}

int IndexOf(wstring s, wchar value)
{
    return IndexOf(s, [value], 0, s.length, StringComparison.CurrentCulture);
}

bool Contains(wstring s, wstring value)
{
    return s.IndexOf(value, StringComparison.Ordinal) >= 0;
}

bool StartsWith(wstring s, wstring value, StringComparison comparisonType)
{
    checkNull(value);
    checkEnum(comparisonType, "comparisonType");
    final switch (comparisonType)
    {
        case StringComparison.CurrentCulture:
            return CultureInfo.CurrentCulture.CompareInfo.IsPrefix(s, value, CompareOptions.None);
        case StringComparison.CurrentCultureIgnorecase:
            return CultureInfo.CurrentCulture.CompareInfo.IsPrefix(s, value, CompareOptions.IgnoreCase);
        case StringComparison.InvariantCulture:
            return CultureInfo.InvariantCulture.CompareInfo.IsPrefix(s, value, CompareOptions.None);
        case StringComparison.InvariantCultureIgnorecase:
            return CultureInfo.CurrentCulture.CompareInfo.IsPrefix(s, value, CompareOptions.IgnoreCase);
        case StringComparison.OrdinalIgnoreCase:
            return CultureInfo.InvariantCulture.CompareInfo.IsPrefix(s, value, CompareOptions.OrdinalIgnoreCase);
        case StringComparison.Ordinal:
            return value.length <= s.length && s[0 .. value.length] == value;    
    }
    assert(0);
}

bool StartsWith(wstring s, wstring value)
{
    return StartsWith(s, value, StringComparison.CurrentCulture);
}


wstring Substring(wstring s, int index, int count)
{
    checkIndex(s, index, count);
    return s[index .. index + count];
}


wstring Substring(wstring s, int index)
{
    checkIndex(s, index);
    return s[index .. $];
}


wstring ToLowerInvariant(wstring s)
{
    return CultureInfo.InvariantCulture.TextInfo.ToLower(s);
}

@safe nothrow 
int GetHashCode(wstring s)
{
    auto len = s.length;
    size_t i = 0;
    size_t result;
    while (i < len)
        result = s[i++] + (result << 6) + result << 16 - result;
    return result;
}


interface IEquatable(T)
{
    bool Equals(T t);
}

interface IComparable(T)
{
    int CompareTo(T t);
}

interface ICloneable
{
    Object Clone();
}

// =====================================================================================================================
// ValueType
// =====================================================================================================================

final class ValueType(T) : SharpObject, IEquatable!T, IComparable!T, IEquatable!Object, IComparable!Object if(!is(T == class))
{
private:
    T value;
public:
    pure @safe nothrow
    this(T value)   
    {
        this.value = value;
    }

    override bool Equals(T other)
    {
        return defaultEquals(this.value, other);
    }

    int CompareTo(T other)
    {
        return defaultCompare(this.value, other);
    }

    U opCast(U)()
    {
        static if (is(U : T))
            return value;
        else 
            throw new InvalidCastException();
    }

    override bool Equals(Object obj)
    {
        ValueType!T vt = cast(ValueType!T)obj;
        return vt !is null && Equals(vt.value);
    }

    override int CompareTo(Object obj)
    {
        ValueType!T vt = cast(ValueType!T)obj;
        return vt !is null ? CompareTo(vt.value) : CompareTo(T.init);
    }

    override wstring ToString() 
    {
        return defaultToString(value);
    }

    nothrow @trusted
    override int GetHashCode()  
    {
        return defaultHash(value);
    }   

    @property pure @safe nothrow @nogc
    T Value()    
    {
        return value;
    }

    @property pure @safe nothrow @nogc
    T Value(T val)    
    {
        return value = val;
    }

}

// =====================================================================================================================
// IFormatProvider
// =====================================================================================================================

interface IFormatProvider
{
    Object GetFormat(TypeInfo formatType);
}

// =====================================================================================================================
// Environment
// =====================================================================================================================

struct Environment
{
    @property static wstring NewLine() { return "\r\n"w; }
}

// =====================================================================================================================
// Array
// =====================================================================================================================

struct Array
{
    @disable this();

public:
    static int BinarySearch(T)(T[] array, T element)
    {
        return binarySearch(array, element);
    }
}

// =====================================================================================================================
// Guid
// =====================================================================================================================

struct Guid
{
private:
    uint data1;
    ushort data2;
    ushort data3;
    ubyte data4[8];

    static bool Parse(wstring s, wstring fmt, out Guid guid, out Throwable exc, bool throwExceptions)
    {
        wstring ws;
        bool hasBrackets, hasParantheses, hasDashes, hasHex, hasomma;

        if (fmt.length > 1)
        {
            exc = new ArgumentException(null, "fmt");
            if (throwExceptions)
                throw exc;
            return false;
        }

        if (fmt.length == 1 && fmt[0] != 'd' && fmt[0] != 'D'
            && fmt[0] != 'n' && fmt[0] != 'N'
            && fmt[0] != 'p' && fmt[0] != 'P'
            && fmt[0] != 'x' && fmt[0] != 'X'
            && fmt[0] != 'b' && fmt[0] != 'B')
        {
            exc = new ArgumentException(null, "fmt");
            if (throwExceptions)
                throw exc;
            return false;
        }

        for(auto i = 0; i < s.length; i++)
        {
            if (!Char.IsWhiteSpace(s[i]))
            {
                if (!hasBrackets && (s[i] == '{' || s[i] == '}'))
                    hasBrackets = true;
                if (!hasParantheses && (s[i] == '(' || s[i] == ')'))
                    hasParantheses = true;
                if (!hasDashes && s[i] == '-')
                    hasDashes = true;
                if (!hasHex && (s[i] == 'x' || s[i] == 'X'))
                    hasHex = true;
                if (!hasomma && s[i] == ',')
                    hasomma = true;
                ws ~= s[i] == 'X' ? 'x' : s[i];
            }
        }

        char f;

        if (String.IsNullOrEmpty(fmt))
        {
            if (hasHex)
                f = 'x';
            else if (hasParantheses)
                f = 'p';
            else if (!hasDashes)
                f = 'n';
            else if (hasBrackets)
                f = 'b';
            else
                f = 'd';
        }

        exc = null;
        if ((f == 'n' || f == 'N') && (hasDashes || hasBrackets || hasHex || hasParantheses || hasomma))
            exc = new FormatException();
        if ((f == 'd' || f == 'D') && (hasBrackets || hasHex || hasParantheses || hasomma))
            exc = new FormatException();
        if ((f == 'b' || f == 'B') && (hasHex || hasParantheses || hasomma))
            exc = new FormatException();
        if ((f == 'p' || f == 'P') && (hasHex || hasBrackets || hasomma))
            exc = new FormatException();
        if ((f == 'x' || f == 'X') && (hasParantheses || hasDashes))
            exc = new FormatException();

        if (exc !is null)
        {
            if (throwExceptions)
                throw exc;
            return false;
        }

        if (f == 'n' || f == 'N')
        {
            if (s.length != 32)
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }
            if (!parseHex(s[0 .. 8], guid.data1, throwExceptions, exc))
                return false;
            if (!parseHex(s[8 .. 12], guid.data2, throwExceptions, exc))
                return false;
            if (!parseHex(s[12 .. 16], guid.data3, throwExceptions, exc))
                return false;
            int j = 0;
            for (auto i = 16; i < 32; i += 2)
                if (!parseHex(s[i .. i + 2], guid.data4[j++], throwExceptions, exc))
                    return false;
        }
        else if (f == 'd' || f == 'D')
        {
            if (s.length != 36)
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }
            if (s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-')
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }

            if (!parseHex(s[0 .. 8], guid.data1, throwExceptions, exc))
                return false;
            if (!parseHex(s[9 .. 13], guid.data2, throwExceptions, exc))
                return false;
            if (!parseHex(s[14 .. 18], guid.data3, throwExceptions, exc))
                return false;
            if (!parseHex(s[19 .. 21], guid.data4[0], throwExceptions, exc))
                return false;
            if (!parseHex(s[21 .. 23], guid.data4[1], throwExceptions, exc))
                return false;
            int j = 2;
            for (auto i = 24; i < 36; i += 2)
                if (!parseHex(s[i .. i + 2], guid.data4[j++], throwExceptions, exc))
                    return false;
        }
        else if (f == 'b' || f == 'B')
        {
            if (s.length != 38)
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }
            if (s[0] != '{' || s[9] != '-' || s[14] != '-' || s[19] != '-' || s[24] != '-' || s[37] != '}' )
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }

            if (!parseHex(s[1 .. 9], guid.data1, throwExceptions, exc))
                return false;
            if (!parseHex(s[10 .. 14], guid.data2, throwExceptions, exc))
                return false;
            if (!parseHex(s[15 .. 19], guid.data3, throwExceptions, exc))
                return false;
            if (!parseHex(s[20 .. 22], guid.data4[0], throwExceptions, exc))
                return false;
            if (!parseHex(s[23 .. 25], guid.data4[0], throwExceptions, exc))
                return false;
            int j = 2;
            for (auto i = 26; i < 37; i += 2)
                if (!parseHex(s[i .. i + 2], guid.data4[j++], throwExceptions, exc))
                    return false;
        }
        else if (f == 'p' || f == 'P')
        {
            if (s.length != 38)
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }
            if (s[0] != '(' || s[9] != '-' || s[14] != '-' || s[19] != '-' || s[24] != '-' || s[37] != ')' )
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }

            if (!parseHex(s[1 .. 9], guid.data1, throwExceptions, exc))
                return false;
            if (!parseHex(s[10 .. 14], guid.data2, throwExceptions, exc))
                return false;
            if (!parseHex(s[15 .. 19], guid.data3, throwExceptions, exc))
                return false;
            if (!parseHex(s[20 .. 22], guid.data4[0], throwExceptions, exc))
                return false;
            if (!parseHex(s[23 .. 25], guid.data4[1], throwExceptions, exc))
                return false;
            int j = 2;
            for (auto i = 26; i < 37; i += 2)
                if (!parseHex(s[i .. i + 2], guid.data4[j++], throwExceptions, exc))
                    return false;
        }
        else
        {
            if (s.length != 68)
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }
            if (s[0 .. 3] != "{0x" || 
                s[11 .. 14] != ",0x" ||
                s[18 .. 21] != ",0x" || 
                s[25 .. 29] != ",{0x" ||
                s[31 .. 34] != ",0x" ||
                s[36 .. 39] != ",0x" ||
                s[41 .. 44] != ",0x" ||
                s[46 .. 49] != ",0x" ||
                s[51 .. 54] != ",0x" ||
                s[56 .. 59] != ",0x" ||
                s[61 .. 64] != ",0x" ||
                s[66 .. $] != "}}")
            {
                exc = new FormatException();
                if (throwExceptions)
                    throw exc;
                return false;
            }

            if (!parseHex(s[3 .. 11], guid.data1, throwExceptions, exc))
                return false;
            if (!parseHex(s[14 .. 18], guid.data2, throwExceptions, exc))
                return false;
            if (!parseHex(s[21 .. 25], guid.data3, throwExceptions, exc))
                return false;
            int j = 0;
            for (auto i = 29; i < 66; i += 5)
                if (!parseHex(s[i .. i + 2], guid.data4[j++], throwExceptions, exc))
                    return false;
        }

        return true;
    }

public:
    enum Guid Empty = Guid(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    this(ubyte[] b)  
    {
        if (b is null)
            throw new ArgumentNullException("b");
        if (b.length != 16)
            throw new ArgumentException(null, "b");
        data1 = cast(uint)b[3] << 24 | cast(uint)b[2] << 16 | cast(uint)b[1] << 8 | cast(uint)b[0];
        data2 = cast(ushort)b[5] << 8 | cast(ushort)b[4];
        data3 = cast(ushort)b[7] << 8 | cast(ushort)b[6];
        data4 = b[8 .. $];
    }

    this(uint a, ushort b, ushort c, ubyte d, ubyte e, ubyte f, ubyte g, ubyte h, ubyte i, ubyte j, ubyte k)    
    {
        data1 = a;
        data2 = b;
        data3 = c;
        data4[0] = d;
        data4[1] = e;
        data4[2] = f;
        data4[3] = g;
        data4[4] = h;
        data4[5] = i;
        data4[6] = j;
        data4[7] = k;
    }

    this(uint a, ushort b, ushort c, ubyte[] d)  
    {
        if (d is null)
            throw new ArgumentNullException("d");
        if (d.length != 8)
            throw new ArgumentException(null, "d");
        data1 = a;
        data2 = b;
        data3 = c;
        data4 = d;
    }

    ubyte[] ToByteArray()   
    {
        ubyte[] a = new ubyte[16];
        a[0] = cast(ubyte)data1;
        a[1] = cast(ubyte)(data1 >> 8);
        a[2] = cast(ubyte)(data1 >> 16);
        a[3] = cast(ubyte)(data1 >> 24);
        a[4] = cast(ubyte)(data2);
        a[5] = cast(ubyte)(data2 >> 8);
        a[6] = cast(ubyte)(data3);
        a[7] = cast(ubyte)(data3 >> 8);
        a[8 .. $] = data4;
        return a;
    }

    bool Equals(Guid other)     
    {
        return  this.data1 == other.data1 && 
                this.data2 == other.data2 && 
                this.data3 == other.data3 && 
                this.data4 == other.data4;
    }

    bool opEquals(Guid other)
    {
        return Equals(other);
    }

    int CompareTo(Guid other)     
    {
        if (data1 > other.data1)
            return 1;
        else if (data1 < other.data1)
            return -1;
        else if (data2 > other.data2)
            return 1;
        else if (data2 < other.data2)
            return -1;
        else if (data3 > other.data3)
            return 1;
        else if (data3 < other.data3)
            return -1;
        else
        {
            for(auto i = 0; i < 8; i++)
                if (data4[i] > other.data4[i])
                    return 1;
                else if (data4[i] < other.data4[i])
                    return -1;
        }
        return 0;
    }

    @safe nothrow
    int GetHashCode() 
    {
        uint h1 = cast(uint)data4[3] | cast(uint)(data4[2]) << 8 | cast(uint)data4[1] << 16 | cast(uint)data4[0] << 24;
        uint h2 = cast(uint)data4[7] | cast(uint)(data4[6]) << 8 | cast(uint)data4[5] << 16 | cast(uint)data4[4] << 24;
        uint h3 = cast(uint)data3 | cast(uint)data3 << 16;
        uint h4 = cast(uint)data2 | cast(uint)data2 << 16;
        static if (size_t.sizeof == 8)
            return cast(size_t)(data1 ^ h1) | cast(size_t)(h2 ^ h3) << 32 | h4;
        else
            return data1 ^ h1 ^ h2 ^ h3 ^ h4;
    }

    static Guid NewGuid()
    {
        Guid g;
        Marshal.ThrowExceptionForHR(CoCreateGuid(g));
        return g;
    }

    wstring ToString(wstring fmt, IFormatProvider provider)
    {
        wstring f = String.IsNullOrEmpty(fmt) ? "D" : fmt;
        if (f.length != 1)
            throw new FormatException();
        wchar[] buf;
        int i = 0;
        bool hex = false;
        bool dash = false;
        switch(fmt[0])
        {
            case 'b':
            case 'B':
                buf = new wchar[38];
                buf[0] = '{';
                buf[37] = '}';
                i = 1;
                dash = true;
                break;
            case 'p':
            case 'P':
                buf = new wchar[38];
                buf[0] = '(';
                buf[37] = ')';
                i = 1;
                dash = true;
                break;
            case 'd':
            case 'D':
                buf = new wchar[36];
                dash = true;
                break;
            case 'n':
            case 'N':
                buf = new wchar[32];
                break;
            case 'x':
            case 'X':
                buf = new wchar[68];
                buf[0 .. 3] = "{0x"w;
                buf[66 .. 67] = '}';
                i = 3;
                hex = true;
                break;
            default:
                throw new FormatException();
        }

        bool upper = !(fmt[0] >= 'a');

        auto hex1 = intToHex!(uint)(data1, 8, upper);
        auto hex2 = intToHex!(ushort)(data2, 4, upper);
        auto hex3 = intToHex!(ushort)(data3, 4, upper);
        auto hex4 = new wstring[8];
        for(auto j = 0; j < 8; j++)
            hex4[j] = intToHex!(ubyte)(data4[j], 2, upper);

        buf[i .. i + 8] = hex1; i += 8;
        if (hex)
        {
            buf[i .. i + 3] = ",0x"w; i += 3;
        }
        else if (dash)
            buf[i++] = '-';
        buf[i .. i + 4] = hex2; i += 4;
        if (hex)
        {
            buf[i .. i + 3] = ",0x"w; i += 3;
        }
        else if (dash)
            buf[i++] = '-';
        buf[i .. i + 4] = hex3; i += 4;
        if (hex)
        {
            buf[i .. i + 4] = ",{0x"w; i += 4;
        }
        else if (dash)
            buf[i++] = '-';
        int k = 0;
        if (!hex && dash)
        {
            buf[i .. i + 2] = hex4[0];
            buf[i + 2 .. i + 4] = hex4[1];
            i += 4;
            buf[i++] = '-';
            k = 2;
        }

        for (auto j = k; j < 8; j++)
        {
            buf[i .. i + 2] = hex4[j];
            if (hex && j < 7)
            {
                buf[i .. i + 3] = ",0x"w; i += 3;
            }
        }
        return cast(wstring)buf;
    }

    wstring ToString()
    {
        return ToString("D", null);
    }

    wstring ToString(wstring fmt)
    {
        return ToString(fmt, null);
    }

    static Guid Parse(wstring input)
    {
        Guid guid;
        Throwable exc;
        Parse(input, null, guid, exc, true);
        return guid;
    }

    static Guid ParseExact(wstring input, wstring fmt)
    {
        Guid guid;
        Throwable exc;
        Parse(input, fmt, guid, exc, true);
        return guid;
    }

    static bool TryParse(wstring input, out Guid guid)
    {
        Throwable exc;
        return Parse(input, null, guid, exc, false);
    }
}


template g(string s)
{
    enum g = func();
    private Guid func()
    {
        Guid guid;
        assert(s.length == 36, "Guid length must be 36.");
        assert(s[8] == '-', "Invalid format.");
        assert(s[13] == '-', "Invalid format.");
        assert(s[18] == '-', "Invalid format.");
        assert(s[23] == '-', "invalid format.");
        guid.data1 = htoi!(uint)(s[0 .. 8]);
        guid.data2 = htoi!(ushort)(s[9 .. 13]);
        guid.data3 = htoi!(ushort)(s[14 .. 18]);
        guid.data4[0] = htoi!(ubyte)(s[19 .. 21]);
        guid.data4[1] = htoi!(ubyte)(s[21 .. 23]);
        guid.data4[2] = htoi!(ubyte)(s[24 .. 26]);
        guid.data4[3] = htoi!(ubyte)(s[26 .. 28]);
        guid.data4[4] = htoi!(ubyte)(s[28 .. 30]);
        guid.data4[5] = htoi!(ubyte)(s[30 .. 32]);
        guid.data4[6] = htoi!(ubyte)(s[32 .. 34]);
        guid.data4[7] = htoi!(ubyte)(s[34 .. 36]);
        return guid;
    }
}

// =====================================================================================================================
// Decimal
// =====================================================================================================================

struct decimal
{
private:
    ushort reserved;
    union
    {
        struct
        {
            ubyte scale;
            ubyte sign;
        }
        ushort signscale;
    }
    uint hi32;
    union
    {
        struct
        {
            uint lo32;
            uint mi32;
        }
        ulong lo64;
    }
    enum scaleMax = 28;

    static void check(int result)
    {
        if (result != 0)
            Marshal.ThrowExceptionForHR(result);
    }

    enum scaleMaxInt = 9;

    static uint[] pow10 = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000];

    static uint addc(uint u1, uint u2, ref uint carry)
    {
        ulong r = cast(ulong)(u1) + cast(ulong)u2 + cast(ulong)carry;
        carry = r >> 32 & 0x00000001;
        return cast(uint)r;
    }

    static uint mulc(uint u1, uint u2, ref uint carry)
    {
        ulong r = cast(ulong)(u1) * cast(ulong)u2 + cast(ulong)carry;
        carry = r >> 32;
        return cast(uint)r;
    }

    void imul(uint u)
    {
        uint carry = 0;
        lo32 = mulc(lo32, u, carry);
        mi32 = mulc(mi32, u, carry);
        hi32 = mulc(hi32, u, carry);
        assert(carry == 0, "Overflow.");
    }

    void iadd(uint u)
    {
        uint carry = 0;
        lo32 = addc(lo32, u, carry);
        mi32 = addc(mi32, 0, carry);
        hi32 = addc(hi32, 0, carry);
        assert(carry == 0, "Overflow.");
    }

    uint div(uint divisor)
    {
        uint Remainder;
        if (hi32 != 0)
        {
            Remainder = hi32 % divisor;
            hi32 = hi32 / divisor;            
        }

        if (mi32 != 0 || Remainder != 0)
        {
            ulong n = (cast(ulong)Remainder << 32) | mi32;
            Remainder = n % divisor;
            mi32 = cast(uint)(n / divisor);
        }
        if (lo32 != 0 || Remainder != 0)
        {
            ulong n = (cast(ulong)Remainder << 32) | lo32;
            Remainder = n % divisor;
            lo32 = cast(uint)(n / divisor);
        }
        return Remainder;
    }

    void add(uint i)
    {
        uint v = lo32;
        uint sum = v + i;
        lo32 = sum;
        if (sum < v || sum < i)
        {
            v = mi32;
            sum = v + 1;
            mi32 = sum;
            if (sum < v || sum < i)
                hi32++;
        }
    }

    static decimal abs(ref decimal d)
    {
        decimal ret = d;
        ret.sign = 0;
        return ret;
    }

    enum decimal nearPositiveZero = decimal(1, 0, 0, false, scaleMax - 1);
    enum decimal nearNegativeZero = decimal(1, 0, 0, true, scaleMax - 1);

public:

    enum decimal Zero = decimal(0, 0, 0, 0);
    enum decimal One = decimal(1);
    enum decimal MinusOne = decimal(-1);
    enum decimal MaxValue = decimal(uint.max, uint.max, uint.max, false, 0);
    enum decimal MinValue = decimal(uint.max, uint.max, uint.max, true, 0);

    this(byte value)
    {
        if (value < 0)
        {
            sign = 0x80;
            lo32 = -value;
        }
        else
            lo32 = value;
    }

    this(short value)
    {
        if (value < 0)
        {
            sign = 0x80;
            lo32 = -value;
        }
        else
            lo32 = value;
    }

    this(int value)
    {
        if (value < 0)
        {
            sign = 0x80;
            lo32 = -value;
        }
        else
            lo32 = value;
    }

    this(ubyte value)
    {
        lo32 = value;
    }

    this(ushort value)
    {
        lo32 = value;
    }

    this(uint value)
    {
        lo32 = value;
    }

    this(long value)
    {
        if (value < 0)
        {
            sign = 0x80;
            lo64 = -value;
        }
        else
            lo64 = value;
    }

    this(ulong value)
    {
        lo64 = value;
    }

    this(int[] bits)
    {
        checkNull(bits, "bits");
        if (bits.length != 4)
            throw new ArgumentException(null, "bits");
        signscale = cast(ushort)(bits[3] >> 16);
        if (scale > scaleMax)
            throw new ArgumentException(null, "bits");
        if (sign != 0 && sign != 0x80)
            throw new ArgumentException(null, "bits");
        lo32 = bits[0];
        mi32 = bits[1];
        hi32 = bits[2];
    }

    this(int lo, int mid, int hi, bool isNegative, ubyte scale) 
    {
        checkRange(scale, 0, scaleMax);
        lo32 = lo;
        mi32 = mid;
        hi32 = hi;
        this.scale = scale;
        if (isNegative)
            sign = 0x80;
    }

    this(int lo, int mid, int hi, int flags) 
    {
        signscale = cast(ushort)flags;
        if (scale > scaleMax)
            throw new ArgumentException(null, "scale");
        if (sign > 1)
            throw new ArgumentException(null, "sign");
        lo32 = lo;
        mi32 = mid;
        hi32 = hi;
    }

    this(float f)
    {
        check(VarDecFromR4(f, this));

    }

    this(double d)
    {
        check(VarDecFromR8(d, this));
    }

    static decimal Add(decimal d1, decimal d2)
    {
        return d1 + d2;
    }

    static decimal Ceiling(decimal d)
    {
        return -decimal.Floor(-d);
    }

    static int Compare(decimal d1, decimal d2)
    {
        return d1.opCmp(d2);
    }

    static decimal Divide(decimal d1, decimal d2)
    {
        return d1 / d2;
    }

    static bool Equals(decimal d1, decimal d2)
    {
        return d1 == d2;
    }

    bool Equals(decimal d)
    {
        return this == d;
    }

    int CompareTo(decimal d)
    {
        return this.opCmp(d);
    }

    static decimal Floor(decimal d)
    {
        decimal result;
        check(VarDecInt(d, result));
        return result;
    }

    static decimal FromOACurrency(long cy)
    {
        decimal result;
        check(VarDecFromCy(cy, result));
        return result;
    }

    static long ToOACurrency(decimal d)
    {
        long result;
        check(VarCyFromDec(d, result));
        return result;
    }

    static int[] GetBits(decimal d)
    {
        return [d.lo32, d.mi32, d.hi32, d.signscale << 16];
    }

    static decimal Multiply(decimal d1, decimal d2)
    {
        return d1 * d2;
    }

    static decimal Negate(decimal d)
    {
        return -d;
    }

    decimal opUnary(string op)() if (op == "-")
    {
        decimal result = this;
        result.sign = result.lo64 == 0 && result.hi32 == 0 ? 0 : cast(ubyte)(0x80 - sign);
        return result;
    }

    decimal opUnary(string op)() if (op == "+")
    {
        return this;
    }

    decimal opUnary(string op)() if (op == "++")
    {
        decimal result;
        check(VarDecAdd(this, one, result));
        return result;
    }

    decimal opUnary(string op)() if (op == "--")
    {
        decimal result;
        check(VarDecSub(this, one, result));
        return result;
    }

    T opCast(T)() if (is(T == bool))
    {
        short result;
        check(VarBoolFromDec(this, result));
        return result == 0xffff;
    }

    T opCast(T)() if (is(T == byte))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarI1FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == ubyte))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarUI1FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == short))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarI2FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == ushort))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarUI2FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == int))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarI4FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == uint))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarUI4FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == long))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarI8FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == ulong))
    {
        T result;
        decimal d = decimal.Truncate(this);
        check(VarUI8FromDec(d, result));
        return result;
    }

    T opCast(T)() if (is(T == float))
    {
        T result;
        check(VarR4FromDec(this, result));
        return result;
    }

    T opCast(T)() if (is(T == double) || is(T == real))
    {
        double result;
        check(VarR8FromDec(this, result));
        return result;
    }

    decimal opBinary(string op)(decimal d) if (op == "+")
    {
        decimal result;
        check(VarDecAdd(this, d, result));
        return result;
    }

    decimal opBinary(string op)(decimal d) if (op == "-")
    {
        decimal result;
        check(VarDecSub(this, d, result));
        return result;
    }

    decimal opBinary(string op)(decimal d) if (op == "*")
    {
        decimal result;
        check(VarDecMul(this, d, result));
        return result;
    }

    decimal opBinary(string op)(decimal d) if (op == "/")
    {
        decimal result;
        check(VarDecDiv(this, d, result));
        return result;
    }

    decimal opBinary(string op)(decimal d) if (op == "%")
    {
        if (abs(this) < abs(d))
            return this;
        decimal d1 = this - d;
        if (d1 == Zero)
        {
            d1.sign = 0;
        }
        decimal div = Truncate(d1 / d);
        decimal mul = div * d;
        decimal ret = d1 - mul;

        if (d1.sign != ret.sign)
        {
            if (nearNegativeZero <= ret && ret <= nearPositiveZero)
                ret.sign = 0;
            else
                ret = ret + d;
        }

        return ret;
    }

     void opAssign(T)(T b) if (is(Unqual!T == ubyte) || is(Unqual!T == ushort) || 
                               is(Unqual!T == uint) || is(Unqual!T == ulong))
    {
        lo64 = b;
        hi32 = 0;
        signscale = 0;
    }

    void opAssign(T)(T b) if (is(Unqual!T == byte) || is(Unqual!T == short) || 
                                 is(Unqual!T == int) || is(Unqual!T == long))
    {
        lo64 = b < 0 ? -b : b;
        hi32 = 0;
        sign = b < 0 ? 0x80 : 0;
        scale = 0;
    }

    void opAssign(T)(T f) if (is(Unqual!T == float))
    {
        check(VarDecFromR4(f, this));
    }

    void opAssign(T)(T f) if (is(Unqual!T == double) || is(Unqual!T == real))
    {
        double d = cast(double)f;
        check(VarDecFromR8(d, this));
    }

    bool opEquals(decimal d) 
    {
        return VarDecCmp(this, d) == 1;
    }

    bool opEquals(T)(T i) if (isAnyIntegral!T)
    {
        return opEquals(decimal(i));
    }

    bool opEquals(T)(T f) if (isAnyFloat!T)
    {
        double d = cast(double)f;
        return VarDecmpR8(this, d) == 1;
    }

    int opCmp(decimal d) 
    {
        int ret = VarDecCmp(this, d);
        if (ret == 0)
            return -1;
        if (ret == 1)
            return 0;
        return 1;
    }

    int opCmp(T)( T f) if (isAnyFloat!T)
    {
        double d = cast(double)f;
        int ret = VarDecCmpR8(this, d);
        if (ret == 0)
            return -1;
        if (ret == 1)
            return 0;
        return 1;
    }

    int opCmp(T)(T i) if (isAnyIntegral!T)
    {
        return opCmp(decimal(i));
    }

    static decimal Remainder(decimal d1, decimal d2)
    {
        return d1 % d2;
    }

    static decimal Round(decimal d, int decimals)
    {
        decimal result;
        check(VarDecRound(d, decimals, result));
        return result;
    }

    static decimal Round(decimal d)
    {
        return Round(d, 0);
    }

    static decimal Round(decimal d, int decimals, MidpointRounding mode)
    {
        checkRange(decimals, 0, scaleMax, "decimals");
        if (mode == MidpointRounding.ToEven)
            return Round(d, decimals);
        int scaleDifference = d.scale - decimals;
        if (scaleDifference <= 0)
            return d;

        decimal ret = d;
        uint Remainder;
        uint divisor;

        do 
        {
            int diff = scaleDifference > scaleMaxInt ? scaleMaxInt : scaleDifference;      
            divisor = pow10[diff];
            Remainder = ret.div(divisor);
        } while (scaleDifference > 0);

        if (Remainder >= (divisor >> 2))
            ret.add(1);
        ret.scale = cast(ubyte)decimals;
        return ret;
    }

    static decimal Round(decimal d, MidpointRounding mode)
    {
        return Round(d, 0, mode);
    }

    static decimal Substract(decimal d1, decimal d2)
    {
        return d1 - d2;
    }

    static decimal Truncate(decimal d)
    {
        decimal ret;
        check(VarDecFix(d, ret));
        return ret;
    }

    static decimal Truncate(T)(T f) if (isAnyFloat!T)
    {
        decimal ret;
        decimal d = decimal(f);
        check(VarDecFix(d, ret));
        return ret;
    }

    static byte ToSByte(decimal d)
    {
        return cast(byte)d;
    }

    static ubyte ToByte(decimal d) 
    {
        return cast(ubyte)d;
    }

    static short ToInt16(decimal d) 
    {
        return cast(short)d;
    }

    static ushort ToUInt16(decimal d) 
    {
        return cast(ushort)d;
    }

    static int ToInt32(decimal d) 
    {
        return cast(int)d;
    }

    static uint ToUInt32(decimal d) 
    {
        return cast(uint)d;
    }

    static long ToInt64(decimal d) 
    {
        return cast(long)d;
    }

    static ulong ToUInt64(decimal d) 
    {
        return cast(ulong)d;
    }

    static float ToSingle(decimal d) 
    {
        return cast(float)d;
    }

    static double ToDouble(decimal d) 
    {
        return cast(double)d;
    }

    wchar ToChar(IFormatProvider provider)
    {
        return invalidCast!(decimal, wchar)();
    }

    DateTime ToDateTime(IFormatProvider provider)
    {
        return invalidCast!(decimal, DateTime)();
    }

    @safe nothrow
    int GetHashCode()
    {
         return lo32 ^ mi32 ^ hi32 ^ signscale;
    }

    wstring ToString(wstring fmt, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        NumberFormatInfo nfi = NumberFormatInfo.GetInstance(provider);
        return formatDecimal(this, fmt, nfi, false);
    }

    wstring ToString(wstring fmt)
    {
        return ToString(fmt, cast(IFormatProvider)null);
    }

    wstring ToString(IFormatProvider provider)
    {
        return ToString("G", provider);
    }

    wstring ToString()
    {
        return ToString("G", null);
    }

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out decimal result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out decimal result)
    {
        return TryParse(s, NumberStyles.Number, null, result);
    }

    static decimal Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        decimal result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static decimal Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Number, provider);
    }

    static decimal Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, null);
    }

    static decimal Parse(wstring s)
    {
        return Parse(s, NumberStyles.Number, null);
    }

    TypeCode GetTypeCode()
    {
        return TypeCode.Decimal;
    }
}

template m(string s)
{
    enum m = func();
    decimal func()
    {
        decimal d;
        assert(s.length > 0, "Invalid format.");
        size_t len = s.length;
        size_t i = 0;
        if (s[0] == '-')
        {
            assert(s.length > 1, "Invalid format.");
            d.sign = 0x80;
            i++;
        }
        while (i < len && s[i] == '0')
            i++;


        int decimalPos = -1;
        while (i < len)
        {
            char c = s[i++];
            if (c == '.')
            {
                assert(i < len && s[i] >= '0' && s[i] <= '9', "Invalid format. Digit expected.");
                decimalPos = i;
                while (len > 0 && s[len - 1] == '0')
                    len--;
            }
            else if (c == 'e' || c == 'E')
            {
                assert(i < len, "Invalid format. Exponent expected.");
                len = i - 1;
                bool negExp = s[i] == '-';
                if (negExp || s[i] == '+')
                    i++;
                ulong exp = dtoi!(char, ulong)(s[i .. $]);
                assert(exp <= d.scaleMax, "Overflow. Exponent is too big");
                if (negExp)
                    d.scale = cast(ubyte)exp;
                else
                    while(exp-- > 0)
                        d.imul(10);

                break;
            }
            else
            {
                assert(c >= '0' && c <= '9', "Invalid format, accepting only digits");
                d.imul(10);
                d.iadd(c - '0');

            }
        }

        if (decimalPos >= 0)
        {
            auto xscale = len - decimalPos;
            assert(xscale <= decimal.scaleMax - d.scale, "Overflow. annot scale.");
            d.scale += cast(ubyte)xscale;
        }
        return d;
    }
}

alias Decimal = decimal;

// =====================================================================================================================
// NumberStyles
// =====================================================================================================================

enum NumberStyles
{
    None                = 0x0000,
    AllowLeadingWhite   = 0x0001,
    AllowTrailingWhite  = 0x0002,
    AllowLeadingSign    = 0x0004,
    AllowTrailingSign   = 0x0008,
    AllowParantheses    = 0x0010,
    AllowDecimalPoint   = 0x0020,
    AllowThousands      = 0x0040,
    AllowExponent       = 0x0080,
    AllowCurrencySymbol = 0x0100,
    AllowHexSpecifier   = 0x0200,
    Integer             = AllowLeadingWhite | AllowTrailingWhite | AllowLeadingSign,
    HexNumber           = AllowLeadingWhite | AllowTrailingWhite | AllowHexSpecifier,
    Number              = Integer | AllowTrailingSign | AllowDecimalPoint | AllowThousands,
    Float               = Integer | AllowDecimalPoint | AllowExponent,
    Currency            = Number | AllowParantheses | AllowCurrencySymbol,
    Any                 = Currency | AllowExponent,
}

// =====================================================================================================================
// TypeCode
// =====================================================================================================================

enum TypeCode
{
    Boolean,
    Char,
    SByte,
    Byte,
    Int16,
    UInt16,
    Int32,
    UInt32,
    Int64,
    UInt64,
    Double,
    Single,
    String,
    Decimal,
    DateTime,
    Object,
    DBNull,
    Empty,
}

// =====================================================================================================================
// IFormattable
// =====================================================================================================================

interface IFormattable
{
    wstring ToString(wstring fmt, IFormatProvider provider);
}

// =====================================================================================================================
// ICustomFormatter
// =====================================================================================================================

interface ICustomFormatter
{
    wstring Format(wstring fmt, Object arg, IFormatProvider provider);
}

// =====================================================================================================================
// DateTimeKind
// =====================================================================================================================

enum DateTimeKind
{
    Unspecified,
    Utc,
    Local,
}

// =====================================================================================================================
// DayOfWeek
// =====================================================================================================================

enum DayOfWeek
{
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
}

// =====================================================================================================================
// DateTime
// =====================================================================================================================

struct DateTime
{
private: 
    ulong _data;

    enum ticksMask             = 0x3FFFFFFFFFFFFFFF;
    enum flagsMask             = 0x0000000000000000;
    enum localMask             = 0x8000000000000000;
    enum ticksCeiling          = 0x4000000000000000;
    enum kindUnspecified       = 0x0000000000000000;
    enum kindUtc               = 0x4000000000000000;
    enum kindLocal             = 0x8000000000000000;
    enum kindLocalAmbiguousDst = 0xC000000000000000;
    enum kindShift = 62;

    this(long ticks, DateTimeKind kind, bool isAmbiguousDst)
    {
        _data = cast(ulong)ticks | (isAmbiguousDst ? kindLocalAmbiguousDst : kindLocal);
    }

    static int daysToMonth(int year, int month)  
    {
        return IsLeapYear(year) ? daysToPerMonthLeap[month - 1] : daysToPerMonth[month - 1];
    }

    static ulong getDateTicks(int year, int month, int day)  
    {
        immutable int y = year - 1;
        return (y * 365 + y / 4 - y / 100 + y / 400 + daysToMonth(year, month) + day - 1) * ticksPerDay;       
    }

    pure @safe nothrow @nogc
    static ulong getTimeTicks(int hour, int minute, int second, int millisecond)    
    {
        return cast(ulong)hour * ticksPerHour + 
               cast(ulong)minute * ticksPerMinute + 
               cast(ulong)second * ticksPerSecond +
               cast(ulong)millisecond * ticksPerMillisecond;
    }

    DateTime add(double value, int scale)
    {
        return AddTicks(getTicks(value, scale));
    }

    void getComponents(ref int year, ref int dayOfYear, ref int month, ref int day)     
    {
        int d = Ticks / ticksPerDay;
        auto y400 = d / daysPer400Years;
        d -= y400 * daysPer400Years;
        auto y100 = d / daysPer100Years;
        if (y100 == 4)
            y100 = 3;
        d -= y100 * daysPer100Years;
        auto y4 = d / daysPer4Years;
        d -= y4 * daysPer4Years;
        auto y = d / daysPerYear;
        if (y == 4)
            y = 3;
        year = cast(int)(y400 * 400 + y100 * 100 + y4 * 4 + y + 1);
        if (dayOfYear < 0)
            return;
        d -= y * daysPerYear;
        dayOfYear = cast(int)(d + 1);
        if (month < 0)
            return;
        bool isLeap = y == 3 && (y4 != 24 || y100 == 3);
        auto days = isLeap ? daysToPerMonthLeap : daysToPerMonth;
        auto m = d / 32 + 1;
        while (d >= days[m])
            m++;
        month = m;
        if (day < 0)
            return;
        day = d - days[m - 1] + 1;
    }

    SYSTEMTIME toSystemTime() 
    {
        int y, dy, m, d;
        getComponents(y, dy, m, d);
        return SYSTEMTIME(cast(ushort)y, cast(ushort)m, cast(ushort)d, cast(ushort)DayOfWeek, 
                          cast(ushort)Hour, cast(ushort)Minute, cast(ushort)Second, cast(ushort)Millisecond);
    }

    static DateTime fromSystemTime(SYSTEMTIME st)
    {
        return DateTime(st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    }

    this(bool max)
    {
        _data = (max ? minTicks : maxTicks) | cast(ulong)DateTimeKind.Unspecified << kindShift;
    }

public:

    enum DateTime MinValue = DateTime(minTicks, DateTimeKind.Unspecified);
    enum DateTime MaxValue = DateTime(maxTicks, DateTimeKind.Unspecified);


    this(long ticks)
    {
        checkRange(ticks, minTicks, maxTicks, "ticks");
        _data = cast(ulong)ticks;
    }

    this(long ticks, DateTimeKind kind)  
    {
        checkRange(ticks, minTicks, maxTicks, "ticks");
        checkEnum(kind, "kind");
        _data = ticks | cast(ulong)kind << kindShift;
    }

    this(int year, int month, int day, int hour, int minute, int second, int millisecond, DateTimeKind kind)  
    {
        checkRange(year, 1, 9999, "year");
        checkRange(month, 1, 12, "month");
        checkRange(day, 1, (IsLeapYear(year) ? daysPerMonthLeap[month - 1] : daysPerMonth[month -1]), "day");
        checkRange(hour, 0, hoursPerDay - 1, "hour");
        checkRange(minute, 0, minutesPerHour - 1, "minute");
        checkRange(second, 0, secondsPerMinute - 1, "second");
        checkRange(millisecond, 0, millisecondsPerSecond - 1, "millisecond");
        checkEnum(kind, "kind");
        _data = getDateTicks(year, month, day) + getTimeTicks(hour, minute, second, millisecond);
        _data |= cast(ulong)kind << kindShift;
    }

    this(int year, int month, int day, int hour, int minute, int second, int millisecond, Calendar calendar) 
    {
        checkNull(calendar, "calendar");
        _data = calendar.ToDateTime(year, month, day, hour, minute, second, millisecond).Ticks;
    }

    this(int year, int month, int day, int hour, int minute, int second, int millisecond, Calendar calendar, DateTimeKind kind) 
    {
        checkNull(calendar, "calendar");
        checkEnum(kind, "kind");
        _data = calendar.ToDateTime(year, month, day, hour, minute, second, millisecond).Ticks;
        _data |= cast(ulong)kind << kindShift;
    }

    this(int year, int month, int day, int hour, int minute, int second, int millisecond)  
    {
        this(year, month, day, hour, minute, second, millisecond, DateTimeKind.Unspecified);
    }

    this(int year, int month, int day, int hour, int minute, int second)  
    {
        this(year, month, day, hour, minute, second, 0, DateTimeKind.Unspecified);
    }

    this(int year, int month, int day, int hour, int minute, int second, DateTimeKind kind)
    {
        this(year, month, day, hour, minute, second, 0, kind);
    }

    this(int year, int month, int day, int hour, int minute, int second, Calendar calendar)
    {
        this(year, month, day, hour, minute, second, 0, calendar);
    }

    this(int year, int month, int day)  
    {
        this(year, month, day, 0, 0, 0, 0, DateTimeKind.Unspecified);
    }

    this(int year, int month, int day, Calendar calendar) 
    {
        this(year, month, day, 0, 0, 0, 0, calendar);
    }

    DateTime AddTicks(long value) 
    {
        ulong t = this.Ticks;
        checkRange(value, minTicks - t, maxTicks - t, "ticks");
        return DateTime((t + Ticks) | (_data & flagsMask));
    }

    DateTime AddMilliseconds(double value)
    {
        return add(value, 1);
    }

    DateTime AddSeconds(double value)
    {
        return add(value, millisecondsPerSecond);
    }

    DateTime AddMinutes(double value)
    {
        return add(value, millisecondsPerMinute);
    }

    DateTime AddHours(double value)
    {
        return add(value, millisecondsPerHour);
    }

    DateTime AddDays(double value)
    {
        return add(value, millisecondsPerDay);
    }

    DateTime AddMonths(int value)
    {
        checkRange(value, -12000, 12000, "months");
        int y, yd, m, d;
        getComponents(y, yd, m, d);
        auto i = m - 1 + value;
        if (i >= 0) 
        {
            m = i % 12 + 1;
            y = y + i / 12;
        }
        else 
        {
            m = 12 + (i + 1) % 12;
            y = y + (i - 11) / 12;
        }
        checkRange(y, 1, 9999, "year");
        auto days = DaysInMonth(y, m);
        if (d > days) d = days;
        return DateTime((getDateTicks(y, m, d) + Ticks % ticksPerDay) | (_data & flagsMask));
    }

    DateTime AddYears(int value) 
    {
        return AddMonths(value * 12);
    }

    DateTime Add(TimeSpan value) 
    {
        return AddTicks(value.Ticks);
    }

    static int Compare(DateTime d1, DateTime d2)    
    {
        return d1.opCmp(d2);
    }

    int CompareTo(DateTime other)    
    {
        return this.opCmp(other);
    }

    static int Equals(DateTime d1, DateTime d2)    
    {
        return d1.opEquals(d2);
    }

    @safe nothrow
    int GetHashCode()    
    {
        return _data.toHash();
    }

    TypeCode GetTypeCode()
    {
        return TypeCode.DateTime;
    }

    @property ulong Ticks()    
    {
        return _data & ticksMask;
    }

    static bool IsLeapYear(int year)  
    {
        checkRange(year, 1, 9999, "year");
        return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    }

    static int DaysInMonth(int year, int month)  
    {
        checkRange(month, 1, 12, "month");
        return IsLeapYear(year) ? daysPerMonthLeap[month - 1] : daysPerMonth[month - 1];
    }

    @property int Day()
    {
        int y, yd, m, d;
        getComponents(y, yd, m, d);
        return d;
    }

    @property int Month() 
    {
        int y, yd, m, d = -1;
        getComponents(y, yd, m, d);
        return m;
    }

    @property int Year() 
    {
        int y, yd = -1, m = -1, d = -1;
        getComponents(y, yd, m, d);
        return y;
    }

    @property int DayOfYear() 
    {
        int y, yd, m = -1, d = -1;
        getComponents(y, yd, m, d);
        return yd;
    }

    @property .DayOfWeek DayOfWeek() 
    {
        return cast(.DayOfWeek)((Ticks / ticksPerDay + 1) % 7);
    }

    @property int Hour() 
    {
        return Ticks / ticksPerHour % hoursPerDay;
    }

    @property int Minute() 
    {
        return Ticks / ticksPerMinute % minutesPerHour;
    }

    @property int Second() 
    {
        return Ticks / ticksPerSecond % secondsPerMinute;
    }

    @property int Millisecond() 
    {
        return Ticks / ticksPerMillisecond % millisecondsPerSecond;
    }

    @property DateTime Date() 
    {
        return DateTime((Ticks - Ticks % ticksPerDay) | (_data & flagsMask));
    }

    @property DateTimeKind Kind() 
    {
        switch(_data & flagsMask)
        {
            case kindUnspecified:
                return DateTimeKind.Unspecified;
            case kindUtc:
                return DateTimeKind.Utc;
            default:
                return DateTimeKind.Local;
        }
    }

    @property TimeSpan TimeOfDay()
    {
        return TimeSpan((_data & ticksMask) % ticksPerDay);
    }

    DateTime opBinary(string op)(TimeSpan ts) if (op == "+")
    {
        long ticks = checkedAdd(_data & ticksMask, ts._ticks);
        checkRange(ticks, minTicks, maxTicks);
        return DateTime(ticks | (_data & flagsMask));
    }

    DateTime opBinary(string op)(TimeSpan ts) if (op == "-")
    {
        long ticks = checkedAdd(_data & ticksMask, -ts._ticks);
        checkRange(ticks, minTicks, maxTicks);
        return DateTime(ticks | (_data & flagsMask));
    }

    bool opEquals(DateTime other)
    {
        return (_data & ticksMask) == (other._data & ticksMask);
    }

    int opCmp(DateTime other)
    {
        auto t1 = _data & ticksMask;
        auto t2 = other._data & ticksMask;
        if (t1 > t2)
            return 1;
        if (t1 < t2)
            return -1;
        return 0;
    }

    TimeSpan opBinary(string op)(DateTime other) if (op == "-")
    {
        long ticks = checkedAdd(_data & ticksMask, -(other._data & ticksMask));
        checkRange(ticks, minTicks, maxTicks);
        return TimeSpan(ticks);
    }

    DateTime ToLocalTime() 
    {
        if (Kind == DateTimeKind.Local)
            return this;
        auto universal = toSystemTime();
        auto local = universal;
        SystemTimeToTzSpecificLocalTime(null, universal, local);
        return fromSystemTime(local);
    }

    DateTime ToUniversalTime() 
    {
        if (Kind == DateTimeKind.Utc)
            return this;
        auto local = toSystemTime();
        auto universal = local;
        TzSpecificLocalTimeToSystemTime(null, local, universal);
        return fromSystemTime(universal);
    }

    long ToFileTimeUtc() 
    {
        long ticks = Kind == DateTimeKind.Local ? ToUniversalTime().Ticks : Ticks;
        ticks -= days1601 * ticksPerDay;
        if (ticks < 0)
            throw new ArgumentOutOfRangeException();
        return ticks;
    }

    static DateTime FromFileTimeUtc(long fileTime)
    {
        checkRange(fileTime, 0, maxTicks - days1601 * ticksPerDay, "fileTime");
        long universalTicks = fileTime + days1601 * ticksPerDay;            
        return DateTime(universalTicks, DateTimeKind.Utc);
    }

    static DateTime FromFileTime(long fileTime)
    {
        return FromFileTimeUtc(fileTime).ToLocalTime();
    }

    long ToFileTime() 
    {
        return ToUniversalTime().ToFileTimeUtc();
    }

    double ToOADate() 
    {
        enum offset = days1899 * ticksPerDay;
        enum minOATicks = (daysPer100Years - daysPerYear) * ticksPerDay;

        long ticks = Ticks;
        if (ticks == 0)
            return 0;
        if (ticks < ticksPerDay)
            ticks += offset;
        if (ticks < minOATicks)
            throw new OverflowException();
        auto m = (ticks  - offset) / ticksPerMillisecond;
        if (m < 0) 
        {
            auto f = m % millisecondsPerDay;
            if (f != 0) 
                m -= (millisecondsPerDay + f) * 2;
        }
        return cast(double)m / millisecondsPerDay;
    }

    static DateTime FromOADate(double date)
    {
        checkRange(date, -657435, 958466, "date");
        auto m = cast(long)(date * millisecondsPerDay + (date >= 0 ? 0.5 : -0.5));
        if (m < 0)
            m -= (m % millisecondsPerDay) * 2;
        m += days1899 * ticksPerDay / ticksPerMillisecond;
        checkRange(m, 0, maxMilliseconds, "milliseconds");
        return DateTime(m * ticksPerMillisecond, DateTimeKind.Unspecified);
    }

    @property static DateTime Now()
    {
        SYSTEMTIME st;
        GetLocalTime(st);
        return fromSystemTime(st);
    }

    @property static DateTime UtcNow()
    {
        SYSTEMTIME st;
        GetSystemTime(st);
        return fromSystemTime(st);
    }

    @property static DateTime Today()
    {
        return Now.Date;
    }

    long ToBinary()
    {
        return _data;
    }

    static DateTime FromBinary(long data)
    {
        long ticks = data & ticksMask;
        checkRange(ticks, minTicks, maxTicks, "ticks");
        return DateTime(data);
    }

    bool ToBoolean(IFormatProvider provider)
    {
        return invalidCast!(DateTime, bool)();
    }

    wchar ToChar(IFormatProvider provider)
    {
        return invalidCast!(DateTime, wchar)();
    }

    byte ToSByte(IFormatProvider provider)
    {
        return invalidCast!(DateTime, byte)();
    }

    byte ToByte(IFormatProvider provider)
    {
        return invalidCast!(DateTime, ubyte)();
    }

    short ToInt16(IFormatProvider provider)
    {
        return invalidCast!(DateTime, short)();
    }

    ushort ToUInt16(IFormatProvider provider)
    {
        return invalidCast!(DateTime, ushort)();
    }

    int ToInt32(IFormatProvider provider)
    {
        return invalidCast!(DateTime, int)();
    }

    uint ToUInt32(IFormatProvider provider)
    {
        return invalidCast!(DateTime, uint)();
    }

    long ToInt64(IFormatProvider provider)
    {
        return invalidCast!(DateTime, long)();
    }

    ulong ToUInt64(IFormatProvider provider)
    {
        return invalidCast!(DateTime, ulong)();
    }

    decimal ToDecimal(IFormatProvider provider)
    {
        return invalidCast!(DateTime, decimal)();
    }

    float ToSingle(IFormatProvider provider)
    {
        return invalidCast!(DateTime, float)();
    }

    double ToDouble(IFormatProvider provider)
    {
        return invalidCast!(DateTime, double)();
    }

    DateTime ToDateTime(IFormatProvider provider)
    {
        return this;
    }

    wstring ToString(IFormatProvider provider)
    {
        return null;
        //todo
    }

    static DateTime Parse(wstring s, IFormatProvider provider)
    {
        //todo
        return DateTime.MinValue;
    }
}

// =====================================================================================================================
// TimeSpan
// =====================================================================================================================


struct TimeSpan
{
private:
    long _ticks;

    enum maxSeconds = long.max / ticksPerSecond;
    enum minSeconds = long.min / ticksPerSecond;

    enum maxMilliseconds = long.max / ticksPerMillisecond;
    enum minMilliseconds = long.min / ticksPerMillisecond;

    static long timeToTicks(int hour, int minute, int second) 
    {
        long seconds = hour * secondsPerHour + minute * secondsPerMinute + second;
        checkRange(seconds, minSeconds, maxSeconds, "seconds");
        return seconds * ticksPerSecond;
    }

    static long timeToTicks(int hour, int minute, int second, int millisecond) 
    {
        long milliseconds = hour * millisecondsPerHour + minute * millisecondsPerMinute + second * millisecondsPerSecond + millisecond;
        checkRange(milliseconds, minMilliseconds, maxMilliseconds, "milliseconds");
        return milliseconds * ticksPerMillisecond;
    }

    static TimeSpan from(double value, int scale)
    {
        if (isnan(value))
            throw new ArgumentException();
        double milliseconds = value * scale;
        try
        {
            checkRange(milliseconds, minMilliseconds, maxMilliseconds, "milliseconds");
        }
        catch(ArgumentOutOfRangeException ex)
        {
            throw new OverflowException(ex.Message, ex);
        }
        
        return TimeSpan(cast(long)(milliseconds) * ticksPerMillisecond);
    }

public:
    enum TimeSpan MinValue = TimeSpan(long.min);
    enum TimeSpan MaxValue = TimeSpan(long.max);
    enum TimeSpan Zero = TimeSpan(0);

    this(long ticks)
    {
        _ticks = ticks;
    }

    public this(int hours, int minutes, int seconds) 
    {
        _ticks = timeToTicks(hours, minutes, seconds);
    }

    public this(int hours, int minutes, int seconds, int milliseconds) 
    {
        _ticks = timeToTicks(hours, minutes, seconds, milliseconds);
    }

    @property long Ticks()    
    {
        return _ticks;
    }

    @property int Days()
    {
        return cast(int)(_ticks / ticksPerDay);
    }

    @property int Hours()
    {
        return _ticks / ticksPerHour % hoursPerDay;
    }

    @property int Minutes()
    {
        return _ticks / ticksPerMinute % minutesPerHour;
    }

    @property int Seconds()
    {
        return _ticks / ticksPerSecond % secondsPerMinute;
    }

    @property int Milliseconds()
    {
        return _ticks / ticksPerMillisecond % millisecondsPerSecond;
    }

    @property double TotalDays()
    {
        return cast(double)_ticks / ticksPerDay;
    }

    @property double TotalHours()
    {
        return cast(double)_ticks / ticksPerHour;
    }

    @property double TotalMinutes()
    {
        return cast(double)_ticks / ticksPerMinute;
    }

    @property double TotalSeconds()
    {
        return cast(double)_ticks / ticksPerSecond;
    }

    @property double TotalMilliseconds()
    {
        return cast(double)_ticks / ticksPerMillisecond;
    }

    static int Compare(TimeSpan ts1, TimeSpan ts2)
    {
        return ts1.opCmp(ts2);
    }

    int CompareTo(TimeSpan other)
    {
        return opCmp(other);
    }

    int CompareTo(Object other)
    {
        return opCmp(other);
    }

    static TimeSpan FromDays(double value)
    {
        return from(value, millisecondsPerDay);
    }

    static TimeSpan FromHours(double value)
    {
        return from(value, millisecondsPerHour);
    }

    static TimeSpan FromMinutes(double value)
    {
        return from(value, millisecondsPerMinute);
    }

    static TimeSpan FromSeconds(double value)
    {
        return from(value, millisecondsPerSecond);
    }

    static TimeSpan FromMilliseconds(double value)
    {
        return from(value, 1);
    }

    static TimeSpan FromTicks(long value)
    {
        return TimeSpan(value);
    }

    TimeSpan Duration()
    {
        if (_ticks == ulong.min)
            throw new OverflowException();
        else
            return _ticks >= 0 ? this : TimeSpan(-_ticks);
    }

    static bool Equals(TimeSpan ts1, TimeSpan ts2)
    {
        return ts1 == ts2;
    }

    bool Equals(TimeSpan other)
    {
        return this == other;
    }

    bool Equals(Object other)
    {
        return this == other;
    }

    @safe nothrow
    int GetHashCode()
    {
        return _ticks.GetHashCode();
    }

    TimeSpan Negate()
    {
        return -this;
    }

    TimeSpan Substract(TimeSpan value)
    {
        return this - value;
    }

    TimeSpan Add(TimeSpan ts)
    {
        return this + ts;
    }

    TimeSpan opBinary(string op)(TimeSpan other) if (op == "+")
    {
        return TimeSpan(checkedAdd(_ticks, other._ticks));
    }

    TimeSpan opBinary(string op)(TimeSpan other) if (op == "-")
    {
        return TimeSpan(checkedAdd(_ticks, -other._ticks));
    }

    TimeSpan opUnary(string op)() if (op == "-")
    {
        return TimeSpan(-_ticks);
    }

    TimeSpan opUnary(string op)() if (op == "+")
    {
        return this;
    }

    int opCmp(TimeSpan other)
    {
        if (this._ticks > other._ticks)
            return 1;
        if (this._ticks < other._ticks)
            return -1;
        return 0;
    }

    int opCmp(Object other)
    {
        if (auto vt = cast(ValueType!TimeSpan)other)
            return opCmp(vt.Value);
        if (auto vt = cast(ValueType!(Nullable!TimeSpan))other)
            return vt.Value.HasValue ? opCmp(vt.Value.Value) : 1;
        throw new ArgumentException();
    }

    bool opEquals(TimeSpan other)
    {
        return this._ticks == other._ticks;
    }

    bool opEquals(Object other)
    {
        if (auto vt = cast(ValueType!TimeSpan)other)
            return opEquals(vt.Value);
        if (auto vt = cast(ValueType!(Nullable!TimeSpan))other)
            return vt.Value.HasValue ? opEquals(vt.Value.Value) : false;
        return false;
    }

    TimeSpan opOpAssign(string op)(TimeSpan other) if (op == "+")
    {
        _ticks = checkedAdd(_ticks, other._ticks);
        return this;
    }

    TimeSpan opOpAssign(string op)(TimeSpan other) if (op == "-")
    {
        _ticks = checkedAdd(_ticks, -other._ticks);
        return this;
    }

}

struct Nullable(T) if (isAnyChar!T || isAnyIntegral!T || isAnyFloat!T || is(T == struct) || is(T == bool))
{
private:
    bool _hasValue;
    T _value;
public:
    pure @safe nothrow
    this(T value)
    {
        _value = value;
        _hasValue = true;
    }

    @property pure @safe nothrow @nogc
    bool HasValue()
    {
        return _hasValue;
    }

    @property 
    T Value()
    {
        if (!_hasValue)
            throw new InvalidOperationException();
        return _value;
    }

    pure @safe nothrow @nogc
    T GetValueOrDefault()
    {
        return _hasValue ? _value : T.init;
    }

    pure @safe nothrow @nogc
    T GetValueOrDefault(T defaultValue)
    {
        return _hasValue ? _value : defaultValue;
    }

    bool opEquals(T other)
    {
        return _hasValue && _value == other;
    }

    bool opEquals(Nullable!T other)
    {
        return (!_hasValue && !other._hasValue) ||
            (_hasValue && other._hasValue && _value == other._value);
    }
    bool opEquals(Object obj)
    {
        if (!_hasValue && obj is null)
            return true;
        if (auto vt = cast(ValueType!T)obj)
            return _hasValue && _value == vt.value;
        return false;
    }

    bool opEquals(ValueType!T other)
    {
        if (!_hasValue && other is null)
            return true;
        if (!_hasValue && other !is null)
            return _value == other.value;
        return false;
    }

    pure @safe nothrow @nogc
    bool opEquals(U)(U value) if (is(U == typeof(null))) 
    {
        return _hasValue;
    }

    size_t toHash()
    {
        return _hasValue ? typeid(T).getHash(&_value) : 0;
    }

    wstring ToString() 
    {
        if (!_hasValue)
            return ""w;
        static if (is(typeof(_value.ToString()): wstring))
            return _value.ToString();
        else static if (is(typeof(_value.toString()): string))
            return _value.toString().toUTF16();
        else
            return T.stringof.toUTF16();
    }

    pure @safe nothrow @nogc
    Nullable!T opAssign(T other)
    {
        _value = other;
        _hasValue = true;
        return this;
    }

    pure @safe nothrow @nogc
    Nullable!T opAssign(U)(U other) if (is(U == typeof(null)))
    {
        _hasValue = false;
        return this;
    }

    pure @safe nothrow @nogc
    Nullable!T opAssign(U)(Nullable!U other) if (is(U : T))
    {
        _hasValue = other._hasValue;
        if(_hasValue)
            _value = other._value;
        return this;
    }

    pure @safe
    Nullable!T opUnary(string op)() if (is(typeof(mixin(op ~ "_value")) : T))
    {
        if (!_hasValue)
            throw new InvalidOperationException();
        mixin("T temp = " ~ op ~ "_value;");
        return Nullable(temp);
    }

    pure @safe
    Nullable!T opBinary(string op)(T other) if (is(typeof(mixin("_value " ~ op ~ " other")) : T))
    {
        if (!_hasValue)
            throw new InvalidOperationException();
        return Nullable!T(mixin("_value" ~ op ~ " other"));       
    }

    pure @safe
    Nullable!T opBinary(string op)(Nullable!T other) if (is(typeof(mixin("this._value " ~ op ~ " other._value")) : T))
    {
        if (!_hasValue || !other._hasValue)
            throw new InvalidOperationException();
        return Nullable!T(mixin("this._value" ~ op ~ " other._value"));       
    }

    pure @safe
    Nullable!T opOpAssign(string op)(T other) if (is(typeof(mixin("_value " ~ op ~ " other"))))
    {
        if (!_hasValue)
            throw new InvalidOperationException();
        mixin("_value = _value" ~ op ~ " other;");
        return this;
    }

    pure @safe
    Nullable!T opOpAssign(string op)(Nullable!T other) if (is(typeof(mixin("_value " ~ op ~ "other._value"))))
    {
        if (!_hasValue || !other._hasValue)
            throw new InvalidOperationException();
        mixin("_value = _value" ~ op ~ " other._value;");
        return this;
    }

    U opCast(U)() if (is(typeof(mixin("cast(" ~ U.stringof ~ ")_value")) : U))
    {
        if (!_hasValue)
            throw new InvalidOperationException();
        return mixin("cast(" ~ U.stringof ~ ")_value");
    }

    static if (is(typeof(T.init < T.init) : bool))
    {
        int opCmp(T other)
        {
            static if (is(typeof(T.init < T.init) : bool))
            {
                if (_hasValue)
                    return -1;
                if (_value < other)
                    return -1;
                if (_value > other)
                    return 1;
                return 0;
            }
            else
                throw new NotImplementedException(); 
        }

        int opCmp(Nullable!T other)
        {
            static if (is(typeof(T.init < T.init) : bool))
            {
                if (!_hasValue)
                    return other._hasValue ? -1 : 0;
                if (!other._hasValue)
                    return 1;
                if (_value < other._value)
                    return -1;
                if (_value > other._value)
                    return 1;
                return 0;    
            }
            else
                throw new NotImplementedException(); 
        }

        int opCmp(Object obj)
        {
            static if (is(typeof(T.init < T.init) : bool))
            {
                if (!_hasValue && obj is null)
                    return 0;
                if (auto vt = cast(ValueType!T)obj)
                {
                    if (!_hasValue)
                        return -1;
                    if (_value > vt.value)
                        return 1;
                    if (_value < vt.value)
                        return -1;
                    return 0;
                }
                throw new NotImplementedException(); 
            }
            else
                throw new NotImplementedException(); 

        }

        int opCmp(ValueType!T obj)
        {
            static if (is(typeof(T.init < T.init) : bool))
            {
                if (!_hasValue && obj is null)
                    return 0;
                if (!_hasValue)
                    return -1;
                if (_value > obj.value)
                    return 1;
                if (_value < obj.value)
                    return -1;
                return 0;
            }
            else
                throw new NotImplementedException(); 

        }

        pure @safe nothrow @nogc
        int opCmp(U)(U value) if (is(U == typeof(null)))
        {
            return _hasValue ? 1 : 0;
        }
    }

    static if (is(typeof(_value.ToString(""w, cast(IFormatProvider)null)): wstring))
    {
        wstring ToString(wstring fmt, IFormatProvider provider)
        {
            if (!_hasValue)
                return ""w;
            return _value.ToString(fmt, provider);
        }
    }  
}

// =====================================================================================================================
// IConvertible
// =====================================================================================================================

interface IConvertible
{
    TypeCode GetTypeCode();
    bool ToBoolean(IFormatProvider provider);
    wchar ToChar(IFormatProvider provider);
    byte ToSByte(IFormatProvider provider);
    ubyte ToByte(IFormatProvider provider);
    short ToInt16(IFormatProvider provider);
    ushort ToUInt16(IFormatProvider provider);
    int ToInt32(IFormatProvider provider);
    uint ToUInt32(IFormatProvider provider);
    long ToInt64(IFormatProvider provider);
    ulong ToUInt64(IFormatProvider provider);
    float ToSingle(IFormatProvider provider);
    double ToDouble(IFormatProvider provider);
    decimal ToDecimal(IFormatProvider provider);
    DateTime ToDateTime(IFormatProvider provider);
    wstring ToString(IFormatProvider provider);
    Object ToType(TypeInfo convType, IFormatProvider provider);
}

// =====================================================================================================================
// DBNull
// =====================================================================================================================

final class DBNull: SharpObject, IConvertible
{
    private this() {}
    private void invalidCast() { throw new InvalidCastException(SharpResources.GetString("InvalidCastDBNull")); }
    static immutable Value = new DBNull();
    override wstring ToString() { return ""w; }
    TypeCode GetTypeCode() { return TypeCode.DBNull; }
    bool ToBoolean(IFormatProvider provider) { invalidCast(); assert(false); }
    wchar ToChar(IFormatProvider provider) { invalidCast(); assert(false); }
    byte ToSByte(IFormatProvider provider) { invalidCast(); assert(false); }
    ubyte ToByte(IFormatProvider provider) { invalidCast(); assert(false); }
    short ToInt16(IFormatProvider provider) { invalidCast(); assert(false); }
    ushort ToUInt16(IFormatProvider provider) { invalidCast(); assert(false); }
    int ToInt32(IFormatProvider provider) { invalidCast(); assert(false); }
    uint ToUInt32(IFormatProvider provider) { invalidCast(); assert(false); }
    long ToInt64(IFormatProvider provider) { invalidCast(); assert(false); }
    ulong ToUInt64(IFormatProvider provider) { invalidCast(); assert(false); }
    float ToSingle(IFormatProvider provider) { invalidCast(); assert(false); }
    double ToDouble(IFormatProvider provider) { invalidCast(); assert(false); }
    decimal ToDecimal(IFormatProvider provider) { invalidCast(); assert(false); }
    DateTime ToDateTime(IFormatProvider provider) { invalidCast(); assert(false); }
    wstring ToString(IFormatProvider provider) { return ""w; }
    Object ToType(TypeInfo convType, IFormatProvider provider) { return Convert.toType(this, convType, provider); }
}

// =====================================================================================================================
// Convert
// =====================================================================================================================

struct Convert
{
    @disable this();
    static private Object toType(IConvertible value, TypeInfo targetType, IFormatProvider provider)
    {
        return null;
    }

    private static T cvto(T)(IConvertible cvt, IFormatProvider provider)
    {
        static if (is(T == bool))
            return cvt.ToBoolean(provider);
        else static if (is(T == wchar))
            return cvt.ToChar(provider);
        else static if (is(T == ubyte))
            return cvt.ToByte(provider);
        else static if (is(T == byte))
            return cvt.ToSByte(provider);
        else static if (is(T == ushort))
            return cvt.ToUInt16(provider);
        else static if (is(T == short))
            return cvt.ToInt16(provider);
        else static if (is(T == uint))
            return cvt.ToUInt32(provider);
        else static if (is(T == int))
            return cvt.ToInt32(provider);
        else static if (is(T == ulong))
            return cvt.ToUInt64(provider);
        else static if (is(T == long))
            return cvt.ToInt64(provider);
        else static if (is(T == float))
            return cvt.ToSingle(provider);
        else static if (is(T == double))
            return cvt.ToDouble(provider);
        else static if (is(T == wstring))
            return cvt.ToString(provider);
        else static if (is(T == decimal))
            return cvt.ToDecimal(provider);
        else static if (is(T == DateTime))
            return cvt.ToDateTime(provider);
        else
            static assert("Inconvertible type " ~ T.stringof);
    }
        
    private static T to(T)(Object value, IFormatProvider provider, T def)
    {
        if (value is null) return def;
        if (auto cvt = cast(IConvertible)value) return cvto!T(cvt, provider);
        if (auto vt = cast(ValueType!T)value) return vt.Value;
        static if (is(typeof(Nullable!T)))
        {
            if (auto nt = cast(ValueType!(Nullable!T))value) return nt.Value.GetValueOrDefault();
        }
        return def;
    }

    static bool ToBoolean(Object value) { return to!bool(value, null, false); }
    static bool ToBoolean(Object value, IFormatProvider provider) { return to!bool(value, provider, false); }
    static bool ToBoolean(bool value) { return value; }
    static bool ToBoolean(ubyte value) { return value != 0; }
    static bool ToBoolean(byte value) { return value != 0; }
    static bool ToBoolean(ushort value) { return value != 0; }
    static bool ToBoolean(short value) { return value != 0; }
    static bool ToBoolean(uint value) { return value != 0; }
    static bool ToBoolean(int value) { return value != 0; }
    static bool ToBoolean(ulong value) { return value != 0; }
    static bool ToBoolean(long value) { return value != 0; }
    static bool ToBoolean(float value) { return value != 0; }
    static bool ToBoolean(double value) { return value != 0; }
    static bool ToBoolean(decimal value) { return value != 0; }
    static bool ToBoolean(wchar value) { return value.ToBoolean(null); }
    static bool ToBoolean(DateTime value) { return value.ToBoolean(null); }
    static bool ToBoolean(wstring value) { return value is null ? false : Boolean.Parse(value); }
    static bool ToBoolean(wstring value, IFormatProvider provider) { return value is null ? false : Boolean.Parse(value); }

    static wchar ToChar(Object value) { return to!wchar(value, null, 0); }
    static wchar ToChar(Object value, IFormatProvider provider) { return to!wchar(value, provider, 0); }
    static wchar ToChar(bool value) { return value.ToChar(null); }
    static wchar ToChar(ubyte value) { return cast(wchar)value; }
    static wchar ToChar(byte value) { if (value < 0) throw new OverflowException(); return cast(wchar)value; }
    static wchar ToChar(ushort value) { return cast(wchar)value; }
    static wchar ToChar(short value) { if (value < 0) throw new OverflowException(); return cast(wchar)value; }
    static wchar ToChar(uint value) { return cast(wchar)value; }
    static wchar ToChar(int value) { if (value < 0) throw new OverflowException(); return cast(wchar)value; }
    static wchar ToChar(ulong value) { return cast(wchar)value; }
    static wchar ToChar(long value) { if (value < 0) throw new OverflowException(); return cast(wchar)value; }
    static wchar ToChar(float value) { return value.ToChar(null); }
    static wchar ToChar(double value) { return value.ToChar(null); }
    static wchar ToChar(decimal value) { return value.ToChar(null); }
    static wchar ToChar(wchar value) { return value; }
    static wchar ToChar(DateTime value) { return value.ToChar(null); }
    static wchar ToChar(wstring value) { return ToChar(value, null); }
    static wchar ToChar(wstring value, IFormatProvider provider) { if (value is null) throw new ArgumentNullException(); return Char.Parse(value); }

    static byte ToSByte(Object value) { return to!byte(value, null, 0); }
    static byte ToSByte(Object value, IFormatProvider provider) { return to!byte(value, provider, 0); }
    static byte ToSByte(bool value) { return value ? 1: 0; }
    static byte ToSByte(ubyte value) { if (value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(byte value) { return value; }
    static byte ToSByte(ushort value) { if (value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(short value) { if (value < byte.min || value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(uint value) { if (value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(int value) { if (value < byte.min || value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(ulong value) { if (value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(long value) { if (value < byte.min || value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(float value) { if (value < byte.min || value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(double value) { if (value < byte.min || value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(decimal value) { return Decimal.ToSByte(Decimal.Round(value, 0)); }
    static byte ToSByte(wchar value) { if (value > byte.max) throw new OverflowException(); return cast(byte)value; }
    static byte ToSByte(DateTime value) { return value.ToSByte(null); }
    static byte ToSByte(wstring value) { return ToSByte(value, null); }
    static byte ToSByte(wstring value, IFormatProvider provider) { if (value is null) return 0; return SByte.Parse(value, provider); }

    static short ToInt16(Object value) { return to!short(value, null, 0); }
    static short ToInt16(Object value, IFormatProvider provider) { return to!short(value, provider, 0); }
    static short ToInt16(bool value) { return value ? 1: 0; }
    static short ToInt16(ubyte value) { return value; }
    static short ToInt16(byte value) { return value; }
    static short ToInt16(ushort value) { if (value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(short value) { return value; }
    static short ToInt16(uint value) { if (value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(int value) { if (value < short.min || value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(ulong value) { if (value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(long value) { if (value < short.min || value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(float value) { if (value < short.min || value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(double value) { if (value < short.min || value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(decimal value) { return Decimal.ToInt16(Decimal.Round(value, 0)); }
    static short ToInt16(wchar value) { if (value > short.max) throw new OverflowException(); return cast(short)value; }
    static short ToInt16(DateTime value) { return value.ToInt16(null); }
    static short ToInt16(wstring value) { return ToInt16(value, null); }
    static short ToInt16(wstring value, IFormatProvider provider) { if (value is null) return 0; return Int16.Parse(value, provider); }

    static int ToInt32(Object value) { return to!int(value, null, 0); }
    static int ToInt32(Object value, IFormatProvider provider) { return to!int(value, provider, 0); }
    static int ToInt32(bool value) { return value ? 1: 0; }
    static int ToInt32(ubyte value) { return value; }
    static int ToInt32(byte value) { return value; }
    static int ToInt32(ushort value) { return value; }
    static int ToInt32(short value) { return value; }
    static int ToInt32(uint value) { if (value > int.max) throw new OverflowException(); return cast(int)value; }
    static int ToInt32(int value) { return value; }
    static int ToInt32(ulong value) { if (value > int.max) throw new OverflowException(); return cast(int)value; }
    static int ToInt32(long value) { if (value < int.min || value > int.max) throw new OverflowException(); return cast(int)value; }
    static int ToInt32(float value) { if (value < int.min || value > int.max) throw new OverflowException(); return cast(int)value; }
    static int ToInt32(double value) { if (value < int.min || value > int.max) throw new OverflowException(); return cast(int)value; }
    static int ToInt32(decimal value) { return Decimal.ToInt32(Decimal.Round(value, 0)); }
    static int ToInt32(wchar value) { return cast(int)value; }
    static int ToInt32(DateTime value) { return value.ToInt32(null); }
    static int ToInt32(wstring value) { return ToInt32(value, null); }
    static int ToInt32(wstring value, IFormatProvider provider) { if (value is null) return 0; return Int32.Parse(value, provider); }

    static long ToInt64(Object value) { return to!long(value, null, 0); }
    static long ToInt64(Object value, IFormatProvider provider) { return to!long(value, provider, 0); }
    static long ToInt64(bool value) { return value ? 1: 0; }
    static long ToInt64(ubyte value) { return value; }
    static long ToInt64(byte value) { return value; }
    static long ToInt64(ushort value) { return value; }
    static long ToInt64(short value) { return value; }
    static long ToInt64(uint value) { return value; }
    static long ToInt64(int value) { return value; }
    static long ToInt64(ulong value) { if (value > long.max) throw new OverflowException(); return cast(long)value; }
    static long ToInt64(long value) { return value; }
    static long ToInt64(float value) { if (value < long.min || value > long.max) throw new OverflowException(); return cast(long)value; }
    static long ToInt64(double value) { if (value < long.min || value > long.max) throw new OverflowException(); return cast(long)value; }
    static long ToInt64(decimal value) { return Decimal.ToInt64(Decimal.Round(value, 0)); }
    static long ToInt64(wchar value) { return cast(long)value; }
    static long ToInt64(DateTime value) { return value.ToInt64(null); }
    static long ToInt64(wstring value) { return ToInt64(value, null); }
    static long ToInt64(wstring value, IFormatProvider provider) { if (value is null) return 0; return Int64.Parse(value, provider); }

    static ubyte ToByte(Object value) { return to!ubyte(value, null, 0); }
    static ubyte ToByte(Object value, IFormatProvider provider) { return to!ubyte(value, provider, 0); }
    static ubyte ToByte(bool value) { return value ? 1: 0; }
    static ubyte ToByte(ubyte value) { return value; }
    static ubyte ToByte(byte value) { if (value < 0) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(ushort value) { if (value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(short value) { if (value < 0 || value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(uint value) { if (value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(int value) { if (value < 0 || value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(ulong value) { if (value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(long value) { if (value < 0 || value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(float value) { if (value < ubyte.min || value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(double value) { if (value < ubyte.min || value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(decimal value) { return Decimal.ToByte(Decimal.Round(value, 0)); }
    static ubyte ToByte(wchar value) { if (value > ubyte.max) throw new OverflowException(); return cast(ubyte)value; }
    static ubyte ToByte(DateTime value) { return value.ToByte(null); }
    static ubyte ToByte(wstring value) { return ToByte(value, null); }
    static ubyte ToByte(wstring value, IFormatProvider provider) { if (value is null) return 0; return Byte.Parse(value, provider); }

    static ushort ToUInt16(Object value) { return to!ushort(value, null, 0); }
    static ushort ToUInt16(Object value, IFormatProvider provider) { return to!ushort(value, provider, 0); }
    static ushort ToUInt16(bool value) { return value ? 1: 0; }
    static ushort ToUInt16(ubyte value) { return value; }
    static ushort ToUInt16(byte value) { if (value < 0) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(ushort value) { return value; }
    static ushort ToUInt16(short value) { if (value < 0) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(uint value) { if (value > ushort.max) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(int value) { if (value < 0 || value > ushort.max) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(ulong value) { if (value > ushort.max) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(long value) { if (value < 0 || value > ushort.max) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(float value) { if (value < ushort.min || value > ushort.max) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(double value) { if (value < ushort.min || value > ushort.max) throw new OverflowException(); return cast(ushort)value; }
    static ushort ToUInt16(decimal value) { return Decimal.ToUInt16(Decimal.Round(value, 0)); }
    static ushort ToUInt16(wchar value) { return value; }
    static ushort ToUInt16(DateTime value) { return value.ToUInt16(null); }
    static ushort ToUInt16(wstring value) { return ToUInt16(value, null); }
    static ushort ToUInt16(wstring value, IFormatProvider provider) { if (value is null) return 0; return UInt16.Parse(value, provider); }

    static uint ToUInt32(Object value) { return to!uint(value, null, 0); }
    static uint ToUInt32(Object value, IFormatProvider provider) { return to!uint(value, provider, 0); }
    static uint ToUInt32(bool value) { return value ? 1: 0; }
    static uint ToUInt32(ubyte value) { return value; }
    static uint ToUInt32(byte value) { if (value < 0) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(ushort value) { return value; }
    static uint ToUInt32(short value) { if (value < 0) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(uint value) { return value; }
    static uint ToUInt32(int value) { if (value < 0) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(ulong value) { if (value > uint.max) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(long value) { if (value < 0 || value > uint.max) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(float value) { if (value < uint.min || value > uint.max) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(double value) { if (value < uint.min || value > uint.max) throw new OverflowException(); return cast(uint)value; }
    static uint ToUInt32(decimal value) { return Decimal.ToUInt32(Decimal.Round(value, 0)); }
    static uint ToUInt32(wchar value) { return value; }
    static uint ToUInt32(DateTime value) { return value.ToUInt32(null); }
    static uint ToUInt32(wstring value) { return ToUInt32(value, null); }
    static uint ToUInt32(wstring value, IFormatProvider provider) { if (value is null) return 0; return UInt32.Parse(value, provider); }

    static ulong ToUInt64(Object value) { return to!ulong(value, null, 0); }
    static ulong ToUInt64(Object value, IFormatProvider provider) { return to!ulong(value, provider, 0); }
    static ulong ToUInt64(bool value) { return value ? 1: 0; }
    static ulong ToUInt64(ubyte value) { return value; }
    static ulong ToUInt64(byte value) { if (value < 0) throw new OverflowException(); return cast(ulong)value; }
    static ulong ToUInt64(ushort value) { return value; }
    static ulong ToUInt64(short value) { if (value < 0) throw new OverflowException(); return cast(ulong)value; }
    static ulong ToUInt64(ulong value) { return value; }
    static ulong ToUInt64(int value) { if (value < 0) throw new OverflowException(); return cast(ulong)value; }
    static ulong ToUInt64(uint value) { return value; }
    static ulong ToUInt64(long value) { if (value < 0) throw new OverflowException(); return cast(ulong)value; }
    static ulong ToUInt64(float value) { if (value < ulong.min || value > ulong.max) throw new OverflowException(); return cast(ulong)value; }
    static ulong ToUInt64(double value) { if (value < ulong.min || value > ulong.max) throw new OverflowException(); return cast(ulong)value; }
    static ulong ToUInt64(decimal value) { return Decimal.ToUInt64(Decimal.Round(value, 0)); }
    static ulong ToUInt64(wchar value) { return value; }
    static ulong ToUInt64(DateTime value) { return value.ToUInt64(null); }
    static ulong ToUInt64(wstring value) { return ToUInt64(value, null); }
    static ulong ToUInt64(wstring value, IFormatProvider provider) { if (value is null) return 0; return UInt64.Parse(value, provider); }

    static decimal ToDecimal(Object value) { return to!decimal(value, null, decimal.Zero); }
    static decimal ToDecimal(Object value, IFormatProvider provider) { return to!decimal(value, provider, decimal.Zero); }
    static decimal ToDecimal(bool value) { return value ? decimal.One: decimal.Zero; }
    static decimal ToDecimal(ubyte value) { return decimal(value); }
    static decimal ToDecimal(byte value) { return decimal(value); }
    static decimal ToDecimal(ushort value) { return decimal(value); }
    static decimal ToDecimal(short value) { return decimal(value); }
    static decimal ToDecimal(uint value) { return decimal(value); }
    static decimal ToDecimal(int value) { return decimal(value); }
    static decimal ToDecimal(ulong value) { return decimal(value); }
    static decimal ToDecimal(long value) { return decimal(value); }
    static decimal ToDecimal(float value) { if (value < decimal.MaxValue || value > decimal.MinValue) throw new OverflowException(); return decimal(value); }
    static decimal ToDecimal(double value) { if (value < decimal.MinValue || value > decimal.MaxValue) throw new OverflowException(); return decimal(value); }
    static decimal ToDecimal(decimal value) { return value; }
    static decimal ToDecimal(wchar value) { return value.ToDecimal(null); }
    static decimal ToDecimal(DateTime value) { return value.ToDecimal(null); }
    static decimal ToDecimal(wstring value) { return ToDecimal(value, null); }
    static decimal ToDecimal(wstring value, IFormatProvider provider) { if (value is null) return decimal.Zero; return Decimal.Parse(value, provider); }

    static float ToSingle(Object value) { return to!float(value, null, 0); }
    static float ToSingle(Object value, IFormatProvider provider) { return to!float(value, provider, 0); }
    static float ToSingle(bool value) { return value ? 1: 0; }
    static float ToSingle(ubyte value) { return value; }
    static float ToSingle(byte value) { return value; }
    static float ToSingle(ushort value) { return value; }
    static float ToSingle(short value) { return value; }
    static float ToSingle(uint value) { return value; }
    static float ToSingle(int value) { return value; }
    static float ToSingle(ulong value) { return value; }
    static float ToSingle(long value) { return value; }
    static float ToSingle(float value) { return value; }
    static float ToSingle(double value) { return value; }
    static float ToSingle(decimal value) { return Decimal.ToSingle(value); }
    static float ToSingle(wchar value) { return value.ToSingle(null); }
    static float ToSingle(DateTime value) { return value.ToSingle(null); }
    static float ToSingle(wstring value) { return ToSingle(value, null); }
    static float ToSingle(wstring value, IFormatProvider provider) { if (value is null) return 0; return Single.Parse(value, provider); }

    static double ToDouble(Object value) { return to!double(value, null, 0); }
    static double ToDouble(Object value, IFormatProvider provider) { return to!double(value, provider, 0); }
    static double ToDouble(bool value) { return value ? 1: 0; }
    static double ToDouble(ubyte value) { return value; }
    static double ToDouble(byte value) { return value; }
    static double ToDouble(ushort value) { return value; }
    static double ToDouble(short value) { return value; }
    static double ToDouble(uint value) { return value; }
    static double ToDouble(int value) { return value; }
    static double ToDouble(ulong value) { return value; }
    static double ToDouble(long value) { return value; }
    static double ToDouble(float value) { return value; }
    static double ToDouble(double value) { return value; }
    static double ToDouble(decimal value) { return Decimal.ToDouble(value); }
    static double ToDouble(wchar value) { return value.ToDouble(null); }
    static double ToDouble(DateTime value) { return value.ToDouble(null); }
    static double ToDouble(wstring value) { return ToDouble(value, null); }
    static double ToDouble(wstring value, IFormatProvider provider) { if (value is null) return 0; return Double.Parse(value, provider); }

    static DateTime ToDateTime(Object value) { return to!DateTime(value, null, DateTime.MinValue); }
    static DateTime ToDateTime(Object value, IFormatProvider provider) { return to!DateTime(value, provider, DateTime.MinValue); }
    static DateTime ToDateTime(bool value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(ubyte value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(byte value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(ushort value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(short value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(uint value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(int value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(ulong value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(long value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(float value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(double value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(decimal value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(wchar value) { return value.ToDateTime(null); }
    static DateTime ToDateTime(DateTime value) { return value; }
    static DateTime ToDateTime(wstring value) { return ToDateTime(value, null); }
    static DateTime ToDateTime(wstring value, IFormatProvider provider) { if (value is null) return DateTime.MinValue; return DateTime.Parse(value, provider); }

    static wstring ToString(Object value) { return to!wstring(value, null, null); }
    static wstring ToString(Object value, IFormatProvider provider) { return to!wstring(value, provider, null); }
    static wstring ToString(bool value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(ubyte value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(byte value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(ushort value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(short value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(uint value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(int value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(ulong value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(long value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(float value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(double value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(decimal value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(wchar value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(DateTime value, IFormatProvider provider) { return value.ToString(provider); }
    static wstring ToString(wstring value, IFormatProvider provider) { return value; }
    static wstring ToString(bool value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(ubyte value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(byte value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(ushort value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(short value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(uint value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(int value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(ulong value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(long value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(float value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(double value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(decimal value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(wchar value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(DateTime value) { return value.ToString(cast(IFormatProvider)null); }
    static wstring ToString(wstring value) { return value; }
    //todo
}

// =====================================================================================================================
// SByte
// =====================================================================================================================

struct SByte
{
    @disable this();
    enum MaxValue = byte.max;
    enum MinValue = byte.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out byte result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out byte result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static byte Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        byte result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static byte Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static byte Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static byte Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

wchar ToChar(byte b, IFormatProvider provider) { return invalidCast!(byte, wchar)(); }
bool ToBoolean(byte b, IFormatProvider provider) { return Convert.ToBoolean(b); }
byte ToSByte(byte b, IFormatProvider provider) {return Convert.ToSByte(b); }
ubyte ToByte(byte b, IFormatProvider provider) { return Convert.ToByte(b); }
short ToInt16(byte b, IFormatProvider provider) { return Convert.ToInt16(b); }
ushort ToUInt16(byte b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(byte b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(byte b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(byte b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(byte b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(byte b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(byte b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(byte b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(byte b, IFormatProvider provider) { return invalidCast!(byte, DateTime)(); }

pure @safe nothrow @nogc
size_t toHash(byte b)
{
    return b;
}

wstring ToString(byte b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(byte b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(byte b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(byte b)
{
    return ToString(b, null, null);
}

// =====================================================================================================================
// Byte
// =====================================================================================================================

struct Byte
{
    @disable this();
    enum MaxValue = ubyte.max;
    enum MinValue = ubyte.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out ubyte result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out ubyte result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static ubyte Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        ubyte result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static ubyte Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static ubyte Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static ubyte Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

wchar ToChar(ubyte b, IFormatProvider provider) { return invalidCast!(ubyte, wchar)(); }
byte ToSByte(ubyte b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(ubyte b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(ubyte b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(ubyte b, IFormatProvider provider) { return Convert.ToInt16(b); }
ushort ToUInt16(ubyte b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(ubyte b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(ubyte b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(ubyte b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(ubyte b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(ubyte b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(ubyte b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(ubyte b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(ubyte b, IFormatProvider provider) { return invalidCast!(ubyte, DateTime)(); }

pure @safe nothrow @nogc
size_t toHash(ubyte b)
{
    return b;
}

pure @safe nothrow @nogc
TypeCode GetTypeCode(ubyte b)
{
    return TypeCode.Byte;
}

wstring ToString(ubyte b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(ubyte b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(ubyte b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(ubyte b)
{
    return ToString(b, null, null);
}

// =====================================================================================================================
// Int16
// =====================================================================================================================

struct Int16
{
    @disable this();
    enum MaxValue = short.max;
    enum MinValue = short.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out short result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out short result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static short Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        short result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static short Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static short Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static short Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

wchar ToChar(short b, IFormatProvider provider) { return invalidCast!(short, wchar)(); }
byte ToSByte(short b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(short b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(short b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(short b, IFormatProvider provider) { return Convert.ToInt16(b); }
ushort ToUInt16(short b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(short b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(short b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(short b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(short b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(short b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(short b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(short b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(short b, IFormatProvider provider) { return invalidCast!(short, DateTime)(); }

pure @safe nothrow @nogc
TypeCode GetTypeCode(short b)
{
    return TypeCode.Int16;
}

wstring ToString(short b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(short b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(short b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(short b)
{
    return ToString(b, null, null);
}

pure @safe nothrow @nogc
size_t toHash(short s)
{
    return s;
}

// =====================================================================================================================
// UInt16
// =====================================================================================================================

struct UInt16
{
    @disable this();
    enum MaxValue = ushort.max;
    enum MinValue = ushort.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out ushort result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out ushort result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static short Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        ushort result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static ushort Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static ushort Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static ushort Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

wchar ToChar(ushort b, IFormatProvider provider) { return invalidCast!(ushort, wchar)(); }
byte ToSByte(ushort b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(ushort b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(ushort b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(ushort b, IFormatProvider provider) {return Convert.ToInt16(b); }
ushort ToUInt16(ushort b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(ushort b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(ushort b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(ushort b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(ushort b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(ushort b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(ushort b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(ushort b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(ushort b, IFormatProvider provider) { return invalidCast!(ushort, DateTime)(); }

pure @safe nothrow @nogc
TypeCode GetTypeCode(ushort b)
{
    return TypeCode.UInt16;
}

wstring ToString(ushort b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(ushort b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(ushort b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(ushort b)
{
    return ToString(b, null, null);
}

pure @safe nothrow @nogc
size_t toHash(ushort u)
{
    return u;
}

// =====================================================================================================================
// Int32
// =====================================================================================================================

struct Int32
{
    @disable this();
    enum MaxValue = int.max;
    enum MinValue = int.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out int result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out int result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static int Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        int result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static int Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static int Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static int Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

pure @safe nothrow @nogc
size_t toHash(int i)
{
    return i;
}

wchar ToChar(int b, IFormatProvider provider) { return invalidCast!(int, wchar)(); }
byte ToSByte(int b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(int b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(int b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(int b, IFormatProvider provider) {return Convert.ToInt16(b); }
ushort ToUInt16(int b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(int b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(int b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(int b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(int b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(int b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(int b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(int b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(int b, IFormatProvider provider) { return invalidCast!(int, DateTime)(); }

pure @safe nothrow @nogc
TypeCode GetTypeCode(int b)
{
    return TypeCode.Int32;
}

wstring ToString(int b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(int b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(int b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(int b)
{
    return ToString(b, null, null);
}

// =====================================================================================================================
// UInt32
// =====================================================================================================================

struct UInt32
{
    @disable this();
    enum MaxValue = uint.max;
    enum MinValue = uint.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out uint result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out uint result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static uint Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        uint result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static uint Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static uint Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static uint Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}


wchar ToChar(uint b, IFormatProvider provider) { return invalidCast!(uint, wchar)(); }
byte ToSByte(uint b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(uint b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(uint b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(uint b, IFormatProvider provider) {return Convert.ToInt16(b); }
uint ToUInt16(uint b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(uint b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(uint b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(uint b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(uint b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(uint b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(uint b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(uint b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(uint b, IFormatProvider provider) { return invalidCast!(uint, DateTime)(); }

pure @safe nothrow @nogc
size_t toHash(uint u)
{
    return u;
}

pure @safe nothrow @nogc
TypeCode GetTypeCode(uint b)
{
    return TypeCode.UInt32;
}

wstring ToString(uint b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(uint b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(uint b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(uint b)
{
    return ToString(b, null, null);
}

// =====================================================================================================================
// Int64
// =====================================================================================================================

struct Int64
{
    @disable this();
    enum MaxValue = long.max;
    enum MinValue = long.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out long result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out long result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static long Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        long result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static long Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static long Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static long Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

wchar ToChar(long b, IFormatProvider provider) { return invalidCast!(long, wchar)(); }
byte ToSByte(long b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(long b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(long b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(long b, IFormatProvider provider) {return Convert.ToInt16(b); }
long ToUInt16(long b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(long b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(long b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(long b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(long b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(long b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(long b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(long b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(long b, IFormatProvider provider) { return invalidCast!(long, DateTime)(); }

pure @safe nothrow @nogc
int GetHashCode(long l)
{
    return cast(int)l;
}


pure @safe nothrow @nogc
TypeCode GetTypeCode(long b)
{
    return TypeCode.Int64;
}

wstring ToString(long b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(long b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(long b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(long b)
{
    return ToString(b, null, null);
}

// =====================================================================================================================
// UInt64
// =====================================================================================================================

struct UInt64
{
    @disable this();
    enum MaxValue = ulong.max;
    enum MinValue = ulong.min;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out ulong result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out ulong result)
    {
        return TryParse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo, result);
    }

    static ulong Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        ulong result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static ulong Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static ulong Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Integer, provider);
    }

    static ulong Parse(wstring s)
    {
        return Parse(s, NumberStyles.Integer, NumberFormatInfo.CurrentInfo);
    }
}

wchar ToChar(ulong b, IFormatProvider provider) { return invalidCast!(ulong, wchar)(); }
byte ToSByte(ulong b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(ulong b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(ulong b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(ulong b, IFormatProvider provider) {return Convert.ToInt16(b); }
ulong ToUInt16(ulong b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(ulong b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(ulong b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(ulong b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(ulong b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(ulong b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(ulong b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(ulong b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(ulong b, IFormatProvider provider) { return invalidCast!(ulong, DateTime)(); }

pure @safe nothrow @nogc
size_t toHash(ulong u)
{
    static if (size_t.sizeof == 8)
        return u;
    else
        return cast(size_t)u | cast(size_t)(u >> 32);
}

pure @safe nothrow @nogc
TypeCode GetTypeCode(ulong b)
{
    return TypeCode.UInt64;
}

wstring ToString(ulong b, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatIntegral(b, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(ulong b, IFormatProvider provider)
{
    return ToString(b, null, provider);
}

wstring ToString(ulong b, wstring fmt)
{
    return ToString(b, fmt, null);
}

wstring ToString(ulong b)
{
    return ToString(b, null, null);
}

// =====================================================================================================================
// Single
// =====================================================================================================================

struct Single
{
    @disable this();
    enum MaxValue = float.max;
    enum MinValue = float.min_normal;
    enum Epsilon = float.epsilon;
    enum NaN = float.nan;
    enum NegativeInfinity = -float.infinity;
    enum PositiveInfinity = float.infinity;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out float result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out float result)
    {
        return TryParse(s, NumberStyles.Float, NumberFormatInfo.CurrentInfo, result);
    }

    static float Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        float result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static float Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static float Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Float, provider);
    }

    static float Parse(wstring s)
    {
        return Parse(s, NumberStyles.Float, NumberFormatInfo.CurrentInfo);
    }

    bool IsInfinity(float d)
    {
        return (*cast(uint*)(&d) & 0x7FFFFFFF) == 0x7F800000;
    }

    bool IsNaN(float d)
    {
        return (*cast(uint*)(&d) & 0x7FFFFFFF) > 0x7F800000;
    }

    bool IsPositiveInfinity(float d)
    {
        return d == float.infinity;
    }

    bool IsNegativeInfinity(float d)
    {
        return d == -float.infinity;
    }
}

byte ToSByte(float b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(float b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(float b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(float b, IFormatProvider provider) {return Convert.ToInt16(b); }
float ToUInt16(float b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(float b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(float b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(float b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(float b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(float b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(float b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(float b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(float b, IFormatProvider provider) { return invalidCast!(float, DateTime)(); }

pure @trusted nothrow @nogc
size_t toHash(float f)
{
    return *cast(uint*)(&f);
}

pure @safe nothrow @nogc
TypeCode GetTypeCode(float f)
{
    return TypeCode.Single;
}

wstring ToString(float f, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatFloat(f, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(float f, IFormatProvider provider)
{
    return ToString(f, null, provider);
}

wstring ToString(float f, wstring fmt)
{
    return ToString(f, fmt, null);
}

wstring ToString(float f)
{
    return ToString(f, null, null);
}

wchar ToChar(float f, IFormatProvider provider)
{
    return invalidCast!(float, wchar)();
}

// =====================================================================================================================
// Double
// =====================================================================================================================

struct Double
{
    @disable this();
    enum MaxValue = double.max;
    enum MinValue = double.min_normal;
    enum Epsilon = double.epsilon;
    enum NaN = double.nan;
    enum NegativeInfinity = -double.infinity;
    enum PositiveInfinity = double.infinity;

    static bool TryParse(wstring s, NumberStyles style, IFormatProvider provider, out double result)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        return parse(s, NumberFormatInfo.GetInstance(provider), style, result, false, t, false);
    }

    static bool TryParse(wstring s, out double result)
    {
        return TryParse(s, NumberStyles.Float, NumberFormatInfo.CurrentInfo, result);
    }

    static double Parse(wstring s, NumberStyles style, IFormatProvider provider)
    {
        if (provider is null)
            provider = CultureInfo.CurrentCulture;
        Throwable t;
        double result;
        if (!parse(s, NumberFormatInfo.GetInstance(provider), style, result, true, t, false))
            throw t;
        return result;
    }

    static double Parse(wstring s, NumberStyles style)
    {
        return Parse(s, style, NumberFormatInfo.CurrentInfo);
    }

    static double Parse(wstring s, IFormatProvider provider)
    {
        return Parse(s, NumberStyles.Float, provider);
    }

    static float Parse(wstring s)
    {
        return Parse(s, NumberStyles.Float, NumberFormatInfo.CurrentInfo);
    }

    bool IsInfinity(double d)
    {
        return (*cast(ulong*)(&d) & 0x7FFFFFFFFFFFFFFF) == 0x7FF0000000000000;
    }

    bool IsNaN(double d)
    {
        return (*cast(ulong*)(&d) & 0x7FFFFFFFFFFFFFFF) > 0x7FF0000000000000;
    }

    bool IsPositiveInfinity(double d)
    {
        return d == double.infinity;
    }

    bool IsNegativeInfinity(double d)
    {
        return d == -double.infinity;
    }

}

byte ToSByte(double b, IFormatProvider provider) { return Convert.ToSByte(b); }
ubyte ToByte(double b, IFormatProvider provider) { return Convert.ToByte(b); }
bool ToBoolean(double b, IFormatProvider provider) { return Convert.ToBoolean(b); }
short ToInt16(double b, IFormatProvider provider) {return Convert.ToInt16(b); }
double ToUInt16(double b, IFormatProvider provider) { return Convert.ToUInt16(b); }
int ToInt32(double b, IFormatProvider provider) { return Convert.ToInt32(b); }
uint ToUInt32(double b, IFormatProvider provider) { return Convert.ToUInt32(b); }
long ToInt64(double b, IFormatProvider provider) { return Convert.ToInt64(b); }
ulong ToUInt64(double b, IFormatProvider provider) { return Convert.ToUInt64(b); }
decimal ToDecimal(double b, IFormatProvider provider) { return Convert.ToDecimal(b); }
float ToSingle(double b, IFormatProvider provider) { return Convert.ToSingle(b); }
double ToDouble(double b, IFormatProvider provider) { return Convert.ToDouble(b); }
DateTime ToDateTime(double b, IFormatProvider provider) { return invalidCast!(double, DateTime)(); }

pure @trusted nothrow @nogc
size_t toHash(double d)
{
    return toHash(*cast(ulong*)(&d));
}

pure @safe nothrow @nogc
TypeCode GetTypeCode(double f)
{
    return TypeCode.Double;
}

wstring ToString(double d, wstring fmt, IFormatProvider provider)
{
    if (provider is null)
        provider = NumberFormatInfo.CurrentInfo;
    return formatFloat(d, fmt, NumberFormatInfo.GetInstance(provider), false); 
}

wstring ToString(double d, IFormatProvider provider)
{
    return ToString(d, null, provider);
}

wstring ToString(double d, wstring fmt)
{
    return ToString(d, fmt, null);
}

wstring ToString(double d)
{
    return ToString(d, null, null);
}

wchar ToChar(double d, IFormatProvider provider)
{
    return invalidCast!(float, wchar)();
}

// =====================================================================================================================
// DateTimeOffset
// =====================================================================================================================

struct DateTimeOffset
{
private:
    enum long maxOffset = ticksPerHour * 14;
    enum long minOffset = -maxOffset;

    DateTime dateTime;
    short offsetMinutes;

    static short check(TimeSpan offset)
    {
        auto ticks = offset.Ticks;
        if (ticks % ticksPerMinute != 0)
            throw new ArgumentException(SharpResources.GetString("ArgumentOffsetMinutes"), "offset");
        if (ticks < minOffset || ticks > maxOffset)
            throw new ArgumentOutOfRangeException("offset", SharpResources.GetString("ArgumentOffsetRange"));
        return cast(short)(ticks / ticksPerMinute);
    }

    static DateTime check(DateTime dateTime, TimeSpan offset)
    {
        auto ticks = dateTime.Ticks - offset.Ticks;
        if (ticks < minTicks || ticks > maxTicks)
            throw new ArgumentOutOfRangeException("offset", SharpResources.GetString("ArgumentUTCOutOfRange"));
        return DateTime(ticks, DateTimeKind.Unspecified);
    }

    this(long ticks, short minutes)
    {
        dateTime = DateTime(ticks, DateTimeKind.Unspecified);
        offsetMinutes = minutes;
    }


public:
    
    enum DateTimeOffset MinValue = DateTimeOffset(minTicks, 0);
    enum DateTimeOffset MaxValue = DateTimeOffset(maxTicks, 0);

    this(long ticks, TimeSpan offset)
    {
        offsetMinutes = check(offset);
        dateTime = check(DateTime(ticks), offset);
    }

    this(int year, int month, int day, int hour, int minute, int second, TimeSpan offset) 
    {
        offsetMinutes = check(offset);
        dateTime = check(DateTime(year, month, day, hour, minute, second), offset);
    }

    this(int year, int month, int day, int hour, int minute, int second, int millisecond, TimeSpan offset) 
    {
        offsetMinutes = check(offset);
        dateTime = check(DateTime(year, month, day, hour, minute, second, millisecond), offset);
    }

    this(int year, int month, int day, int hour, int minute, int second, int millisecond, Calendar calendar, TimeSpan offset)
    {
        offsetMinutes = check(offset);
        dateTime = check(DateTime(year, month, day, hour, minute, second, millisecond, calendar), offset);
    }

    @property
    DateTime UtcDateTime()
    {
        //todo
        return DateTime.MinValue;
    }

    @property long Ticks()
    {
        //todo
        return 0;
    }
}

// =====================================================================================================================
// TimeZoneInfo
// =====================================================================================================================

final class TimeZoneInfo : SharpObject
{
    //todo
private:
    wstring id;
    wstring displayName;
    wstring standardName;
    wstring daylightName;
    TimeSpan baseUtcOffset;
    bool supportsDaylightSavingTime;
    AdjustmentRule[] adjustmentRules;

    static TimeZoneInfo localTimeZone;
    static TimeZoneInfo utcTimeZone;

    

    pure @safe nothrow @nogc
    REG_TZI_FORMAT createRegTziFormat(ref TIME_ZONE_INFORMATION tzi)
    {
        return REG_TZI_FORMAT(tzi.Bias, tzi.StandardBias, tzi.DaylightBias, tzi.StandardDate, tzi.DaylightDate);
    }

    pure @safe nothrow @nogc
    REG_TZI_FORMAT createRegTziFormat(ref DYNAMIC_TIME_ZONE_INFORMATION tzi)
    {
        return REG_TZI_FORMAT(tzi.Bias, tzi.StandardBias, tzi.DaylightBias, tzi.StandardDate, tzi.DaylightDate);
    }

    bool check(wstring id, TimeSpan baseUtcOffset, AdjustmentRule[] rules)
    {
        checkNull(id, "id");
        if (id.length == 0)
            throw new ArgumentException(null, "id");
        checkRange(baseUtcOffset.TotalHours, -14, 14, "baseUtcOffset");
        if (baseUtcOffset.Ticks % ticksPerMinute != 0)
            throw new ArgumentException(null, "baseUtcOffset");

        if (rules.length != 0)
        {
            AdjustmentRule previous = null;
            AdjustmentRule current = null;
            foreach(i, rule; rules)
            {
                previous = current;
                current = rule;
                if (current is null)
                    throw new InvalidTimeZoneException();
                TimeSpan ts = baseUtcOffset + current._daylightDelta;
                if (ts.TotalHours < -14 || ts.TotalHours > 14)
                    throw new InvalidTimeZoneException();
                if (previous !is null && current._dateStart <= previous._dateEnd)
                    throw new InvalidTimeZoneException();
            }
            return true;
        }
        return false;
    }

    this(TIME_ZONE_INFORMATION tzi, bool dstDisabled)
    {
        id = fromSz(tzi.StandardName.ptr, tzi.StandardName.length);
        if (String.IsNullOrEmpty(id))
            id = "Local";

        if (!dstDisabled)
        {
            auto fmt = createRegTziFormat(tzi);
            auto rule = AdjustmentRule.create(fmt, DateTime.MinValue.Date, DateTime.MaxValue.Date);
            if (rule !is null)
                adjustmentRules = [rule];
        }
        
        baseUtcOffset = TimeSpan(0, -tzi.Bias, 0);
        supportsDaylightSavingTime = check(id, baseUtcOffset, adjustmentRules);
        displayName = String(tzi.StandardName.ptr);
        standardName = displayName;
        daylightName = String(tzi.DaylightName.ptr);
    }

    this(DYNAMIC_TIME_ZONE_INFORMATION tzi)
    {
        id = fromSz(tzi.TimeZoneKeyName.ptr, tzi.TimeZoneKeyName.length);
        if (String.IsNullOrEmpty(id))
            id = "Local";

        if (tzi.DynamicDaylightTimeDisabled == 0)
        {
            auto fmt = createRegTziFormat(tzi);
            auto rule = AdjustmentRule.create(fmt, DateTime.MinValue.Date, DateTime.MaxValue.Date);
            if (rule !is null)
                adjustmentRules = [rule];
        }

        baseUtcOffset = TimeSpan(0, -tzi.Bias, 0);
        supportsDaylightSavingTime = check(id, baseUtcOffset, adjustmentRules);
        displayName = String(tzi.StandardName.ptr);
        standardName = displayName;
        daylightName = String(tzi.DaylightName.ptr);
    }

    static TimeZoneInfo getLocal(TIME_ZONE_INFORMATION tzi, bool dstDisabled)
    {
        try
        {
            return new TimeZoneInfo(tzi, dstDisabled);
        }
        catch(ArgumentException) { }
        catch(InvalidTimeZoneException) { }

        if (!dstDisabled)
        {
            try
            {
                return new TimeZoneInfo(tzi, true);
            }
            catch(ArgumentException) { }
            catch(InvalidTimeZoneException) { }
        }

        return getCustom("Local", TimeSpan.Zero, "Local", "Local");
    }
  
    static TimeZoneInfo getLocal()
    {
        wstring id;
        TIME_ZONE_INFORMATION tzi;
        uint dstDisabled = 1;
        if (isWindowsVistaOrGreater())
        {           
            DYNAMIC_TIME_ZONE_INFORMATION dtzi;
            auto ret = GetDynamicTimeZoneInformation(dtzi);
            if (ret == TIME_ZONE_ID_INVALID)
                return getCustom("Local", TimeSpan.Zero, "Local", "Local");
            id = fromSz(dtzi.TimeZoneKeyName.ptr, dtzi.TimeZoneKeyName.length);
            if (String.IsNullOrEmpty(id))
            {            
                memcpy(&tzi, &dtzi, tzi.sizeof);
                id = findInRegistry(tzi, dtzi.DynamicDaylightTimeDisabled != 0);
                dstDisabled = dtzi.DynamicDaylightTimeDisabled;
            }      
        }
        else
        {
            auto ret = GetTimeZoneInformation(tzi);
            if (ret == TIME_ZONE_ID_INVALID)
                return getCustom("Local", TimeSpan.Zero, "Local", "Local");
            void* key;
            
            if (registryOpenKeyReadOnly(HKEY_LOCAL_MACHINE, 
                                        "SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation", key))
            {
                scope(exit) RegCloseKey(key);               
                registryRead(key, "DynamicDaylightTimeDisabled", dstDisabled);
            }
            id = findInRegistry(tzi, dstDisabled != 0); 
        }
        if (!String.IsNullOrEmpty(id))
        {
            TimeZoneInfo zone;
            auto error = getFromRegistry(id, zone);
            if (error is null)
                return zone;
        }
        return new TimeZoneInfo(tzi, dstDisabled != 0);
    }

    static TimeZoneInfo getCustom(wstring id, TimeSpan baseUtcOffset, wstring displayName, wstring standardName)
    {
        return new TimeZoneInfo(id, baseUtcOffset, displayName, standardName, standardName, null, false);
    }

    this(wstring id, TimeSpan baseUtcOffset, wstring displayName, wstring standardDisplayName, 
         wstring daylightDisplayName, AdjustmentRule [] adjustmentRules, bool disableDaylightSavingTime)
    {
        this.supportsDaylightSavingTime = check(id, baseUtcOffset, adjustmentRules);
        if (!disableDaylightSavingTime && adjustmentRules != null && adjustmentRules.length > 0)
            this.adjustmentRules = adjustmentRules.dup;
        this.id = id;
        this.baseUtcOffset = baseUtcOffset;
        this.displayName = displayName;
        this.standardName = standardDisplayName;
        this.daylightName = disableDaylightSavingTime ? null : daylightDisplayName;
        this.supportsDaylightSavingTime = this.supportsDaylightSavingTime && !disableDaylightSavingTime;
    }

    static wstring findInRegistry(TIME_ZONE_INFORMATION tzi, bool dstDisabled)
    {
        void *key;
        if (registryOpenKeyReadOnly(HKEY_LOCAL_MACHINE, 
                                    "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones", key))
        {
            scope(exit) RegCloseKey(key);
            foreach(k; RegistryKeyEnumerator(key))
            {
                void* subkey;
                if (registryOpenKeyReadOnly(key, k, subkey))
                {
                    scope(exit) RegCloseKey(subkey);
                    REG_TZI_FORMAT fmt;
                    if (registryRead(subkey, "TZI", fmt))
                    {
                        if (fmt.Bias != tzi.Bias)
                            continue;
                        if (fmt.StandardBias != tzi.StandardBias)
                            continue;
                        if (fmt.StandardDate != tzi.StandardDate)
                            continue;
                        if (!dstDisabled && fmt.StandardDate != fmt.DaylightDate)
                        {   
                            if (fmt.DaylightBias != tzi.DaylightBias)
                                continue;
                            if (fmt.DaylightDate != tzi.DaylightDate)
                                continue;
                        }
                        wstring fstd;
                        if (registryRead(subkey, "MUI_Std", fstd))
                        {
                            wstring tstd = fromSz(tzi.StandardName.ptr, tzi.StandardName.length);
                            if (fstd == tstd)
                               return k.idup;
                        }
                        
                    }
                }
            }
        }
        return null;
    }

    static Throwable getAdjustmentRulesFromRegistry(wstring id, REG_TZI_FORMAT fmt, out AdjustmentRule[] rules)
    {
        void *key;
        if (registryOpenKeyReadOnly(HKEY_LOCAL_MACHINE, 
                                    "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones\\" ~ 
                                    id ~ "\\Dynamic DST", key))
        {
            rules = null;
            scope(exit) RegCloseKey(key);
            uint first, last;
            if (registryRead(key, "FirstEntry", first) && registryRead(key, "LastEntry", last) && first <= last)
            {
                REG_TZI_FORMAT tzi;
                if (registryRead(key, itod!(wchar, uint)(first), tzi))
                {
                    if (first == last)
                    {
                        auto rule = AdjustmentRule.create(tzi, DateTime.MinValue.Date, DateTime.MaxValue.Date);
                        rules = rule is null ? null : [rule];
                        return null;
                    }
                    AdjustmentRule firstRule = AdjustmentRule.create(tzi, DateTime.MinValue.Date, DateTime(first, 12, 31));
                    if (firstRule)
                        rules ~= firstRule;
                    for (auto i = first + 1; i < last; i++)
                    {
                        if (!registryRead(key, itod!(wchar, uint)(i), tzi))
                        {
                            rules = null;
                            return new InvalidTimeZoneException();
                        }
                        auto rule = AdjustmentRule.create(tzi, DateTime(i, 1, 1), DateTime(i, 12, 31));
                        if (rule !is null)
                            rules ~= rule;
                    }
                    if (!registryRead(key, itod!(wchar, uint)(last), tzi))
                    {
                        rules = null;
                        return new InvalidTimeZoneException();
                    }
                    AdjustmentRule lastRule = AdjustmentRule.create(tzi, DateTime(last, 1, 1), DateTime.MaxValue.Date);
                    if (lastRule)
                        rules ~= lastRule;
                    return null;
                }
            }
            return new InvalidTimeZoneException();
        }
        
        auto rule = AdjustmentRule.create(fmt, DateTime.MinValue.Date, DateTime.MaxValue.Date);
        rules = rule is null ? null : [rule];
        return null;
    }

    static Throwable getFromRegistry(wstring id, out TimeZoneInfo info)
    {
        void* key;
        if (registryOpenKeyReadOnly(HKEY_LOCAL_MACHINE, 
                                    "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones\\" ~ id, key))
        {
            scope(exit) RegCloseKey(key);
            REG_TZI_FORMAT fmt;
            if (registryRead(key, "TZI", fmt))
            {
                wstring display, standard, daylight;
                if (registryRead(key, "MUI_Display", display) || registryRead(key, "Display", display))
                {
                    if (registryRead(key, "MUI_Std", standard) || registryRead(key, "Std", standard))
                    {
                        if (registryRead(key, "MUI_Dlt", daylight) || registryRead(key, "Dlt", daylight))
                        {
                            AdjustmentRule[] rules;
                            auto ex = getAdjustmentRulesFromRegistry(id, fmt, rules);
                            if (ex)
                                return ex;
                            try
                            {
                                info = new TimeZoneInfo(id,
                                                        TimeSpan(0, -fmt.Bias, 0),
                                                        display,
                                                        standard,
                                                        daylight,
                                                        rules,
                                                        false);
                            }
                            catch (SharpException t)
                            {
                                if (cast(ArgumentException)t || cast(InvalidTimeZoneException)t)
                                    return t;
                                else
                                    throw t;
                            }
                        }
                    }
                }
            }
            return new InvalidTimeZoneException();
        }
        return new TimeZoneNotFoundException();
    }

    DateTimeKind getKind()
    {
        if (this == Local)
            return DateTimeKind.Local;
        if (this == Utc)
            return DateTimeKind.Utc;
        return DateTimeKind.Unspecified;
    }

    AdjustmentRule getRule(DateTime dateTime)
    {
        if (adjustmentRules.length == 0)
            return null;
        DateTime date = dateTime.Date;
        foreach(rule; adjustmentRules)
        {
            if (rule.DateStart <= date && date <= rule.DateEnd)
                return rule;
        }
        return null;
    }

    static bool isInvalid(DateTime time, AdjustmentRule rule, DaylightTime daylight)
    {
        if (rule is null || daylight.Delta == TimeSpan.Zero)
            return true;
        DateTime start, end;
        if (rule.DaylightDelta < TimeSpan.Zero) 
        {
            start = daylight.End;
            end = daylight.End - rule.DaylightDelta;
        }
        else 
        {
            start = daylight.Start;
            end = daylight.Start + rule.DaylightDelta;
        }
        if (time >= start && time < end)
            return true;

        if (start.Year != end.Year)
        {
            DateTime startMod, endMod;
            try 
            {
                startMod = start.AddYears(1);
                endMod   = end.AddYears(1);
                if (time >= startMod && time < endMod)
                    return true;
            }
            catch (ArgumentOutOfRangeException) {}
            try 
            {
                startMod = start.AddYears(-1);
                endMod  = end.AddYears(-1);
                if (time >= startMod && time < endMod)
                    return true;
            }
            catch (ArgumentOutOfRangeException) {}
        }
        return false;
    }

    static DaylightTime getDaylightTime(int year, AdjustmentRule rule) 
    {
        TimeSpan delta = rule.DaylightDelta;
        DateTime startTime = rule.DaylightTransitionStart.toDateTime(year);
        DateTime endTime = rule.DaylightTransitionEnd.toDateTime(year);
        return new DaylightTime(startTime, endTime, delta);
    }

    static bool isDst(DateTime startTime, DateTime time, DateTime endTime)
    {
        auto startYear = startTime.Year;
        auto endYear = endTime.Year;
        if (startYear != endYear)
            endTime = endTime.AddYears(startYear - endYear);
        auto year = time.Year;
        if (startYear != year)
            time = time.AddYears(startYear - year);
        if (startTime > endTime)
            return time < endTime || time >= startTime;
        else
            return time >= startTime && time < endTime;
    }

    static bool isAmbiguous(DateTime time, AdjustmentRule rule, DaylightTime daylightTime)
    {
        if (rule is null || rule.DaylightDelta == TimeSpan.Zero)
            return false;
        DateTime start, end;
        if (rule.DaylightDelta > TimeSpan.Zero)
        {
            start = daylightTime.End;
            end = daylightTime.End - rule.DaylightDelta;
        }
        else {
            start = daylightTime.Start;
            end = daylightTime.Start + rule.DaylightDelta;
        }

        if (time >= end && time < start)
            return true;

        if (start.Year != end.Year) 
        {

            DateTime startMod;
            DateTime endMod;
            try 
            {
                startMod = start.AddYears(1);
                endMod   = end.AddYears(1);
                if (time >= endMod && time < startMod)
                    return true;
            }
            catch (ArgumentOutOfRangeException) {}

            try 
            {
                startMod = start.AddYears(-1);
                endMod  = end.AddYears(-1);
                if (time >= endMod && time < startMod)
                    return true;
            }
            catch (ArgumentOutOfRangeException) {}
        }
        return false;  
    }

    static bool isDaylight(DateTime time, AdjustmentRule rule, DaylightTime daylight)
    {
        if (rule is null)
            return false;
        DateTime startTime, endTime;
        if (time.Kind == DateTimeKind.Local)
        {
            startTime = daylight.Start + daylight.Delta;
            endTime = daylight.End;
        }
        else
        {
            auto invalid = rule.DaylightDelta > TimeSpan.Zero;
            startTime = daylight.Start + (invalid ? rule.DaylightDelta : TimeSpan.Zero);
            endTime = daylight.End + (invalid ? -rule.DaylightDelta : TimeSpan.Zero);
        }
        if (isDst(startTime, time, endTime) && time.Kind == DateTimeKind.Local)
        {
            if (isAmbiguous(time, rule, daylight))
                return (time._data & DateTime.flagsMask) == DateTime.kindLocalAmbiguousDst;
            return true;
        }
        return false;
    }

    static bool utcIsDaylight(DateTime time, int year, TimeSpan utc, AdjustmentRule rule, out bool isAmbiguousLocalDst)
    {
        isAmbiguousLocalDst = false;
        if (rule is null)
            return false;
        DaylightTime daylightTime = getDaylightTime(year, rule);
        DateTime startTime = daylightTime.Start - utc;
        DateTime endTime = daylightTime.End - utc - rule.DaylightDelta;
        DateTime ambiguousStart, ambiguousEnd;
        if (daylightTime.Delta.Ticks > 0) 
        {
            ambiguousStart = endTime - daylightTime.Delta;
            ambiguousEnd = endTime;
        } 
        else 
        {
            ambiguousStart = startTime;
            ambiguousEnd = startTime - daylightTime.Delta;
        }

        if (isDst(startTime, time, endTime))
        {
            isAmbiguousLocalDst = time >= ambiguousStart && time < ambiguousEnd;
            if (!isAmbiguousLocalDst && ambiguousStart.Year != ambiguousEnd.Year)
            {
                DateTime ambiguousStartModified;
                DateTime ambiguousEndModified;
                try 
                {
                    ambiguousStartModified = ambiguousStart.AddYears(1);
                    ambiguousEndModified   = ambiguousEnd.AddYears(1);
                    isAmbiguousLocalDst = (time >= ambiguousStart && time < ambiguousEnd); 
                }
                catch (ArgumentOutOfRangeException) {}

                if (!isAmbiguousLocalDst) 
                {
                    try 
                    {
                        ambiguousStartModified = ambiguousStart.AddYears(-1);
                        ambiguousEndModified   = ambiguousEnd.AddYears(-1);
                        isAmbiguousLocalDst = (time >= ambiguousStart && time < ambiguousEnd);
                    }
                    catch (ArgumentOutOfRangeException) {}
                }
            }
            return true;
        }
        return false;
    }

    static TimeSpan utcOffsetFromUtc(DateTime time, TimeZoneInfo zone, out bool isDaylightSavings, out bool isAmbiguousLocalDst)
    {
        isDaylightSavings = false;
        isAmbiguousLocalDst = false;

        int year;
        AdjustmentRule rule;
        if (time > DateTime.MaxValue.Date)
        {
            year = 9999;
            rule = zone.getRule(DateTime.MaxValue);
        }
        else if (time < DateTime.MinValue.Date)
        {
            year = 1;
            rule = zone.getRule(DateTime.MinValue);
        }
        else
        {
            DateTime targetTime = time + zone.baseUtcOffset;
            year = time.Year;
            rule = zone.getRule(targetTime);
        }
        if (rule)
        {
            isDaylightSavings = utcIsDaylight(time, year, zone.baseUtcOffset, rule, isAmbiguousLocalDst);
            return zone.baseUtcOffset + (isDaylightSavings ? rule.DaylightDelta : TimeSpan.Zero);
        }

        return zone.baseUtcOffset;

    }

    static TimeSpan utcOffsetFromUtc(DateTime time, TimeZoneInfo zone, out bool isDaylightSavings)
    {
        bool dummy;
        return utcOffsetFromUtc(time, zone, isDaylightSavings, dummy);
    }

    static TimeSpan utcOffsetFromUtc(DateTime time, TimeZoneInfo zone)
    {
        bool b1, b2;
        return utcOffsetFromUtc(time, zone, b1, b2);
    }

    static DateTime utcToTimeZone(long ticks, TimeZoneInfo destinationTimeZone, out bool isAmbiguousLocalDst) 
    {
        DateTime utc;
        if (ticks > DateTime.MaxValue.Ticks)
            utc = DateTime.MaxValue;
        else if (ticks < DateTime.MinValue.Ticks)
            utc = DateTime.MinValue;
        else
            utc = DateTime(ticks);

        TimeSpan offset = utcOffsetFromUtc(utc, destinationTimeZone, isAmbiguousLocalDst);
        ticks += offset.Ticks;

        if (ticks > DateTime.MaxValue.Ticks)
            return DateTime.MaxValue;
        else if (ticks < DateTime.MinValue.Ticks) 
            return DateTime.MinValue;
        else
            return DateTime(ticks);           
    }

    static DateTime convertTime(DateTime dateTime, TimeZoneInfo source, TimeZoneInfo destination, bool throwOnError)
    {
        checkNull(source);
        checkNull(destination);

        auto sourceKind = source.getKind();
        if (throwOnError && dateTime.Kind != DateTimeKind.Unspecified && dateTime.Kind != sourceKind)
            throw new ArgumentException(SharpResources.GetString("ArgumentTimeZoneMismatch"), "dateTime");
        auto sourceRule = source.getRule(dateTime);
        auto sourceOffset = source.baseUtcOffset;
        if (sourceRule !is null)
        {
            auto sourceDaylight = getDaylightTime(dateTime.Year, sourceRule);
            if (throwOnError && isInvalid(dateTime, sourceRule, sourceDaylight))
                throw new ArgumentException(SharpResources.GetString("ArgumentInvalidDateTime"), "dateTime");
            sourceOffset += isDaylight(dateTime, sourceRule, sourceDaylight) ? 
                sourceRule.DaylightDelta : TimeSpan.Zero; 
        }

        auto destinationKind = destination.getKind();
        if (dateTime.Kind != DateTimeKind.Unspecified && 
            sourceKind != DateTimeKind.Unspecified && sourceKind == destinationKind)
            return dateTime;
        auto ticks = dateTime.Ticks - sourceOffset.Ticks;

        bool isAmbiguousLocalDst = false;
        auto destinationTime = utcToTimeZone(ticks, destination, isAmbiguousLocalDst);

        if (destinationKind == DateTimeKind.Local)
            return DateTime(destinationTime.Ticks, DateTimeKind.Local, isAmbiguousLocalDst); 
        else 
            return DateTime(destinationTime.Ticks, destinationKind);
    }


public:

    static struct TransitionTime
    {
    private:
        DateTime timeOfDay;
        ubyte month;
        ubyte week;
        ubyte day;
        DayOfWeek dayOfWeek;
        bool isFixedDateRule;
        this(DateTime timeOfDay, int month, int week, int day, DayOfWeek dayOfWeek, bool isFixedDateRule)
        {
            if (timeOfDay.Kind != DateTimeKind.Unspecified)
                throw new ArgumentException(null, "kind");
            checkRange(month, 1, 12, "month");
            checkRange(day, 1, 31, "day");
            checkRange(week, 1, 5, "week");
            checkEnum(dayOfWeek, "dayOfWeek");
            if (timeOfDay.Year != 1 || timeOfDay.Month != 1 || timeOfDay.Day != 1 || (timeOfDay.Ticks % ticksPerMillisecond != 0))
                throw new ArgumentException(null, "timeOfDay");
            this.timeOfDay = timeOfDay;
            this.month = cast(ubyte)month;
            this.week = cast(ubyte)week;
            this.day = cast(ubyte)day;
            this.dayOfWeek = dayOfWeek;
            this.isFixedDateRule = isFixedDateRule;
        }

        static bool create(ref REG_TZI_FORMAT fmt, ref TransitionTime tt, bool readDateStart)
        {
            if (fmt.StandardDate.wMonth == 0)
                return false;
            if (readDateStart)
            {
                if (fmt.DaylightDate.wYear == 0)
                {
                    tt = CreateFloatingDateRule(DateTime(1, 1, 1, 
                                                         fmt.DaylightDate.wHour, 
                                                         fmt.DaylightDate.wMinute, 
                                                         fmt.DaylightDate.wSecond,
                                                         fmt.DaylightDate.wMilliseconds),
                                                fmt.DaylightDate.wMonth, 
                                                fmt.DaylightDate.wDay, 
                                                cast(DayOfWeek)fmt.DaylightDate.wDayOfWeek);
                }
                else
                {
                    tt = CreateFixedDateRule(DateTime(1, 1, 1, 
                                                         fmt.DaylightDate.wHour, 
                                                         fmt.DaylightDate.wMinute, 
                                                         fmt.DaylightDate.wSecond,
                                                         fmt.DaylightDate.wMilliseconds),
                                                fmt.DaylightDate.wMonth, 
                                                fmt.DaylightDate.wDay);
                }
            }
            else
            {
                if (fmt.DaylightDate.wYear == 0)
                {
                    tt = CreateFloatingDateRule(DateTime(1, 1, 1, 
                                                         fmt.StandardDate.wHour, 
                                                         fmt.StandardDate.wMinute, 
                                                         fmt.StandardDate.wSecond,
                                                         fmt.StandardDate.wMilliseconds),
                                                fmt.StandardDate.wMonth, 
                                                fmt.StandardDate.wDay, 
                                                cast(DayOfWeek)fmt.StandardDate.wDayOfWeek);
                }
                else
                {
                    tt = CreateFixedDateRule(DateTime(1, 1, 1, 
                                                      fmt.StandardDate.wHour, 
                                                      fmt.StandardDate.wMinute, 
                                                      fmt.StandardDate.wSecond,
                                                      fmt.StandardDate.wMilliseconds),
                                                fmt.StandardDate.wMonth, 
                                                fmt.StandardDate.wDay);
                }
            }
            return true;
        }

        DateTime toDateTime(int year)
        {
            auto lastDay = DateTime.DaysInMonth(year, month);
            if (isFixedDateRule)
                return DateTime(year, month, lastDay < day ? lastDay : day,
                                timeOfDay.Hour, timeOfDay.Minute, timeOfDay.Second, timeOfDay.Millisecond);
            else
            {
                auto result = DateTime(year, month, week <= 4 ? 1 : DateTime.DaysInMonth(year, month),
                                     timeOfDay.Hour, timeOfDay.Minute, timeOfDay.Second, timeOfDay.Millisecond);
                auto delta = week <= 4  ? result.DayOfWeek - dayOfWeek : dayOfWeek - result.DayOfWeek;
                if (delta < 0)
                    delta += 7;
                if (week <= 4)
                    delta += 7 * (week - 1);
                return delta <= 0 ? result : result.AddDays(week <= 4 ? delta : -delta);
            }
        }
    public:
        @property pure @safe nothrow @nogc
        DateTime TimeOfDay() { return timeOfDay; }
        
        @property pure @safe nothrow @nogc
        int Month() { return month; }

        @property pure @safe nothrow @nogc
        int Week() { return week; }

        @property pure @safe nothrow @nogc
        int Day() { return day; }

        @property pure @safe nothrow @nogc
        DayOfWeek DayOfWeek_() { return dayOfWeek; }

        @property pure @safe nothrow @nogc
        bool IsFixedDateRule() { return isFixedDateRule; }

        bool opEquals(TransitionTime other)
        {
            bool ret = this.isFixedDateRule == other.isFixedDateRule &&
                       this.timeOfDay == other.timeOfDay &&
                       this.month == other.month;
            return ret && (other.isFixedDateRule ? this.day == other.day : this.dayOfWeek == other.dayOfWeek);
        }

        pure @safe nothrow @nogc
        size_t toHash()
        {
            return month << 8 | week;
        }

        static TransitionTime CreateFixedDateRule(DateTime timeOfDay, int month, int day)
        {
            return TransitionTime(timeOfDay, month, 1, day, DayOfWeek.Sunday, true);
        }

        static TransitionTime CreateFloatingDateRule(DateTime timeOfDay, int month, int week, DayOfWeek dayOfWeek)
        {
            return TransitionTime(timeOfDay, month, week, 1, dayOfWeek, false);
        }
    }

    final static class AdjustmentRule: SharpObject//, IEquatable!AdjustmentRule
    {
    private:
        DateTime _dateStart;
        DateTime _dateEnd;
        TimeSpan _daylightDelta;
        TransitionTime _daylightTransitionStart;
        TransitionTime _daylightTransitionEnd;

        this(DateTime dateStart, DateTime dateEnd, TimeSpan daylightDelta, TransitionTime daylightTransitionStart, TransitionTime daylightTransitionEnd)
        {
            if (dateStart.Kind != DateTimeKind.Unspecified)
                throw new ArgumentException(null, "dateStart");
            if (dateEnd.Kind != DateTimeKind.Unspecified)
                throw new ArgumentException(null, "dateStart");
            if (daylightTransitionStart == daylightTransitionEnd)
                throw new ArgumentException(null, "daylightTransitionEnd");
            if (dateStart > dateEnd)
                throw new ArgumentException(null, "dateEnd");
            if (dateStart.TimeOfDay != TimeSpan.Zero)
                throw new ArgumentException(null, "dateStart");
            if (dateEnd.TimeOfDay != TimeSpan.Zero)
                throw new ArgumentException(null, "dateEnd");
            if (daylightDelta.Ticks % ticksPerMinute != 0)
                throw new ArgumentException(null, "daylightDelta");
            checkRange(daylightDelta.TotalHours, -14, 14, "daylightDelta");
            
            this._dateStart = dateStart;
            this._dateEnd = dateEnd;
            this._daylightDelta = daylightDelta;
            this._daylightTransitionStart = daylightTransitionStart;
            this._daylightTransitionEnd = daylightTransitionEnd;
        }

        static create(ref REG_TZI_FORMAT fmt, DateTime startDate, DateTime endDate)
        {
            if (fmt.StandardDate.wMonth == 0)
                return null;
            TransitionTime start;
            if (!TransitionTime.create(fmt, start, true))
                return null;
            TransitionTime end;
            if (!TransitionTime.create(fmt, end, false))
                return null;
            if (start == end)
                return null;
            return CreateAdjustmentRule(startDate, endDate, TimeSpan(0, -fmt.DaylightBias, 0), start, end);
        }
    public:
        
        static AdjustmentRule CreateAdjustmentRule(DateTime dateStart, DateTime dateEnd, TimeSpan daylightDelta, TransitionTime daylightTransitionStart, TransitionTime daylightTransitionEnd)
        {
            return new AdjustmentRule(dateStart, dateEnd, daylightDelta, daylightTransitionStart, daylightTransitionEnd);
        }

        @property pure @safe nothrow @nogc
        DateTime DateStart() { return _dateStart; }
        
        @property pure @safe nothrow @nogc
        DateTime DateEnd() { return _dateEnd; }

        @property pure @safe nothrow @nogc
        TimeSpan DaylightDelta() { return _daylightDelta; }

        @property pure @safe nothrow @nogc
        TransitionTime DaylightTransitionStart() { return _daylightTransitionStart; }

        @property pure @safe nothrow @nogc
        TransitionTime DaylightTransitionEnd() { return _daylightTransitionEnd; }


        bool opEquals(AdjustmentRule other) 
        {
            return (other !is null) && 
                this._dateStart == other._dateStart &&
                this._dateEnd == other._dateEnd &&
                this._daylightDelta == other._daylightDelta &&
                this._daylightTransitionStart == other._daylightTransitionStart &&
                this._daylightTransitionEnd == other._daylightTransitionEnd;
        }
    }

    static void ClearCachedData()
    {
        localTimeZone = null;
        utcTimeZone = null;
    }

    static TimeZoneInfo CreateCustomTimeZone(wstring id, TimeSpan baseUtcOffset, wstring displayName, 
                                             wstring standardName) 
    {
        return new TimeZoneInfo(id, baseUtcOffset, displayName, standardName, standardName, null, false);
    }

    static TimeZoneInfo CreateCustomTimeZone(wstring id, TimeSpan baseUtcOffset, wstring displayName, 
                                             wstring standardName, AdjustmentRule[] rules) 
    {
        return new TimeZoneInfo(id, baseUtcOffset, displayName, standardName, standardName, rules, false);
    }

    static TimeZoneInfo CreateCustomTimeZone(wstring id, TimeSpan baseUtcOffset, wstring displayName, 
                                             wstring standardName, AdjustmentRule[] rules, bool dstDisabled) 
    {
        return new TimeZoneInfo(id, baseUtcOffset, displayName, standardName, standardName, rules, dstDisabled);
    }

    override bool opEquals(Object obj)
    {
        if (auto tzi = cast(TimeZoneInfo)obj)
            return tzi == this;
        return false;
    }

    bool opEquals(TimeZoneInfo tzi)
    {
        return (tzi !is null && tzi.id == this.id);
    }

    bool HasSameRules(TimeZoneInfo other)
    {
        checkNull(other);
        if (this.baseUtcOffset != other.baseUtcOffset)
            return false;
        if (this.supportsDaylightSavingTime != other.supportsDaylightSavingTime)
            return false;
        if (this.adjustmentRules.length != other.adjustmentRules.length)
            return false;
        for (int i = 0; i < this.adjustmentRules.length; i++)
            if (this.adjustmentRules[i] != other.adjustmentRules[i])
                return false;
        return true;
    }

    static TimeZoneInfo FindSystemTimeZoneById(wstring id)
    {
        if (id == "UTC")
            return Utc;
        checkNull(id, "id");
        if (id.length == 0 || id.length > 128 || id.Contains("\0")) 
            throw new TimeZoneNotFoundException();
        TimeZoneInfo tz;
        auto error = getFromRegistry(id, tz);
        if (error !is null)
            throw error;
        return tz;
    }

    static DateTime ConvertTime(DateTime dateTime, TimeZoneInfo destination)
    {
        checkNull(destination);
        if (dateTime.Kind == DateTimeKind.Utc)
            return convertTime(dateTime, Utc, destination, true);
        return convertTime(dateTime, Local, destination, true);
    }

    static DateTime ConvertTime(DateTime dateTime, TimeZoneInfo source, TimeZoneInfo destination)
    {
        return convertTime(dateTime, source, destination, true);
    }

    static DateTimeOffset ConvertTime(DateTimeOffset dateTimeOffset, TimeZoneInfo destination)
    {
        checkNull(destination);
        auto dateTime = dateTimeOffset.UtcDateTime;
        auto offset = utcOffsetFromUtc(dateTime, destination);
        auto ticks = dateTime.Ticks + offset.Ticks;
        if (ticks > DateTimeOffset.MaxValue.Ticks) 
            return DateTimeOffset.MaxValue;
        else if (ticks < DateTimeOffset.MinValue.Ticks)
            return DateTimeOffset.MinValue;
        return DateTimeOffset(ticks, offset);
    }

    static DateTimeOffset ConvertTimeBySystemTimeZoneId(DateTimeOffset dateTimeOffset, wstring destinationTimeZoneId) 
    {
        return ConvertTime(dateTimeOffset, FindSystemTimeZoneById(destinationTimeZoneId));
    }

    static DateTime ConvertTimeBySystemTimeZoneId(DateTime dateTime, wstring destinationTimeZoneId) 
    {
        return ConvertTime(dateTime, FindSystemTimeZoneById(destinationTimeZoneId));
    }

    static DateTime ConvertTimeBySystemTimeZoneId(DateTime dateTime, wstring sourceTimeZoneId, wstring destinationTimeZoneId) 
    {
        if (dateTime.Kind == DateTimeKind.Local && String.Compare(sourceTimeZoneId, TimeZoneInfo.Local.Id, StringComparison.OrdinalIgnoreCase) == 0) 
            return convertTime(dateTime, Local, FindSystemTimeZoneById(destinationTimeZoneId), true);    
        else if (dateTime.Kind == DateTimeKind.Utc && String.Compare(sourceTimeZoneId, TimeZoneInfo.Utc.Id, StringComparison.OrdinalIgnoreCase) == 0)
            return convertTime(dateTime, Utc, FindSystemTimeZoneById(destinationTimeZoneId), true);
        else
            return ConvertTime(dateTime, FindSystemTimeZoneById(sourceTimeZoneId), FindSystemTimeZoneById(destinationTimeZoneId));
    }

    static DateTime ConvertTimeFromUtc(DateTime dateTime, TimeZoneInfo destinationTimeZone) 
    {
        return convertTime(dateTime, Utc, destinationTimeZone, true);
    }

    static DateTime ConvertTimeToUtc(DateTime dateTime, TimeZoneInfo sourceTimeZone) 
    {
        return convertTime(dateTime, sourceTimeZone, Utc, true);
    }

    static DateTime ConvertTimeToUtc(DateTime dateTime) 
    {
        if (dateTime.Kind == DateTimeKind.Utc)
            return dateTime;
        return convertTime(dateTime, Local, Utc, true);
    }
    
    TimeSpan[] GetAmbiguousTimeOffsets(DateTime dateTime) 
    {
        if (!SupportsDaylightSavingTime) 
            throw new ArgumentException(SharpResources.GetString("ArgumentNotAmbiguous"), "dateTime");
        DateTime adjustedTime;
        if (dateTime.Kind == DateTimeKind.Local)
            adjustedTime = convertTime(dateTime, Local, this, true);
        else if (dateTime.Kind == DateTimeKind.Utc)
            adjustedTime = convertTime(dateTime, Utc, this, true);
        else
            adjustedTime = dateTime;

        bool isAmbiguous = false;
        auto rule = getRule(adjustedTime);
        if (rule)
        {
            auto daylightTime = getDaylightTime(adjustedTime.Year, rule);
            isAmbiguous = TimeZoneInfo.isAmbiguous(adjustedTime, rule, daylightTime);
        }

        if (!isAmbiguous)
            throw new ArgumentException(SharpResources.GetString("ArgumentNotAmbiguous"), "dateTime");
        TimeSpan[] timeSpans = new TimeSpan[2];

        if (rule.DaylightDelta > TimeSpan.Zero) 
        {
            timeSpans[0] = baseUtcOffset; 
            timeSpans[1] = baseUtcOffset + rule.DaylightDelta;
        } 
        else 
        {
            timeSpans[0] = baseUtcOffset + rule.DaylightDelta;
            timeSpans[1] = baseUtcOffset; 
        }
        return timeSpans;
    }

    TimeSpan[] GetAmbiguousTimeOffsets(DateTimeOffset dateTimeOffset)
    {
        if (!SupportsDaylightSavingTime) 
            throw new ArgumentException(SharpResources.GetString("ArgumentNotAmbiguous"), "dateTimeOffset");
        DateTime adjustedTime = (ConvertTime(dateTimeOffset, this)).dateTime;
        bool isAmbiguous = false;
        auto rule = getRule(adjustedTime);
        if (rule)
        {
            auto daylightTime = getDaylightTime(adjustedTime.Year, rule);
            isAmbiguous = TimeZoneInfo.isAmbiguous(adjustedTime, rule, daylightTime);
        }

        if (!isAmbiguous)
            throw new ArgumentException(SharpResources.GetString("ArgumentNotAmbiguous"), "dateTimeOffset");
        TimeSpan[] timeSpans = new TimeSpan[2];

        if (rule.DaylightDelta > TimeSpan.Zero) 
        {
            timeSpans[0] = baseUtcOffset; 
            timeSpans[1] = baseUtcOffset + rule.DaylightDelta;
        } 
        else 
        {
            timeSpans[0] = baseUtcOffset + rule.DaylightDelta;
            timeSpans[1] = baseUtcOffset; 
        }
        return timeSpans;
    }

    @property 
    static TimeZoneInfo Local()
    {
        if (localTimeZone is null)
            localTimeZone = getLocal();
        return localTimeZone;
    }

    @property 
    static TimeZoneInfo Utc()
    {
        if (utcTimeZone is null)
            utcTimeZone = CreateCustomTimeZone("UTC", TimeSpan.Zero, "UTC", "UTC");
        return utcTimeZone;
    }

    @property @safe nothrow @nogc
    TimeSpan BaseUtcOffset()
    {
        return baseUtcOffset;
    }

    @property @safe nothrow @nogc
    wstring DisplayName()
    {
        return displayName is null ? String.Empty : displayName;
    }

    @property @safe nothrow @nogc
    wstring DaylightName()
    {
        return daylightName is null ? String.Empty : daylightName;
    }

    @property @safe nothrow @nogc
    wstring StandardName()
    {
        return standardName is null ? String.Empty : standardName;
    }

    @property @safe nothrow @nogc
    wstring Id()
    {
        return id;
    }

    @property @safe nothrow @nogc
    bool SupportsDaylightSavingTime()
    {
        return supportsDaylightSavingTime;
    }

    @safe nothrow @nogc
    override wstring ToString()
    {
        return DisplayName;
    }

    nothrow
    override int GetHashCode() 
    {
        return id.GetHashCode();
    }

    pure @safe nothrow
    AdjustmentRule[] GetAdjustmentRules()
    {
        return adjustmentRules is null ? [] : adjustmentRules.dup;
    }

    static ReadOnlyCollection!TimeZoneInfo GetSystemTimeZones()
    {
        TimeZoneInfo[] zones;

        void *key;
        if (registryOpenKeyReadOnly(HKEY_LOCAL_MACHINE, 
                                    "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones", key))
        {
            scope(exit) RegCloseKey(key);
            foreach(k; RegistryKeyEnumerator(key))
            {
                TimeZoneInfo zone;
                auto error = getFromRegistry(k, zone);
                if (!error)
                    zones ~= zone;

            }
        }

        return new ReadOnlyCollection!TimeZoneInfo(new ArrayAsList!TimeZoneInfo(zones));
    }
    
}

// =====================================================================================================================
// IDisposable
// =====================================================================================================================

interface IDisposable
{
    void Dispose();
}

// =====================================================================================================================
// Weakreference
// =====================================================================================================================

//todo
class WeakReference
{
//todo
}

// =====================================================================================================================
// GC
// =====================================================================================================================


enum GCNotificationStatus
{
    Succeeded,
    Failed,
    Canceled,
    Timeout,
    NotApplicable,
}

enum GCCollectionMode
{
    Default,
    Forced,
    Optimized,
}

private struct GCStats
{
    size_t poolsize;
    size_t usedsize;
    size_t freeblocks;   
    size_t freelistsize; 
    size_t pageblocks; 
}

private extern(C) GCStats gc_stats() ;

struct GC
{
    @disable this();

private:
    alias gc = core.memory.GC;
    enum generationCount = 1;

public:

    static void SuppressFinalize(Object obj)
    {
        checkNull(obj);
        gc.clrAttr(cast(void*)obj, gc.BlkAttr.FINALIZE);
    }

    static void ReregisterForFinalize(Object obj)
    {
        checkNull(obj);
        gc.setAttr(cast(void*)obj, gc.BlkAttr.FINALIZE);
    }

    static void Collect(int generation, GCCollectionMode mode, bool blocking)
    {
        checkRange(generation, 0, generationCount - 1, "generation");
        checkEnum(mode, "mode");
        gc.collect();
    }

    static void Collect(int generation, GCCollectionMode mode)
    {
        Collect(generation, mode, true);
    }

    static void Collect(int generation)
    {
        Collect(generation, GCCollectionMode.Default, true);
    }

    static void Collect()
    {
        gc.collect();
    }

    static int GetGeneration(Object obj)
    {
        return 0;
    }

    static int GetGeneration(WeakReference wr)
    {
        return 0;
    }

    static void KeepAlive(Object obj)
    {
        gc.addRoot(cast(void*)obj);
    }

    @property 
    static int MaxGeneration()
    {
        return generationCount - 1;
    }

    @property 
    static size_t GetTotalMemory(bool forceFullCollection)
    {
        if (forceFullCollection)
            gc.collect();
        GCStats stats = gc_stats();
        return stats.usedsize;
    }

    static void WaitForPendingFinalizers()
    {
        //nop;
    }

    static void RegisterForFullGCNotification(int maxGenerationThreshold, int largeObjectHeapThreshold)
    {
        checkRange(maxGenerationThreshold, 1, 99, "maxGenerationThreshold");
        checkRange(maxGenerationThreshold, 1, 99, "largeObjectHeapThreshold");
        throw new InvalidOperationException();
    }

    static void CancelFullGCNotification()
    {
        throw new InvalidOperationException();
    }

    static GCNotificationStatus WaitForFullGCApproach()
    {
        return GCNotificationStatus.NotApplicable;
    }

    static GCNotificationStatus WaitForFullGCApproach(int milliseconds)
    {
        return GCNotificationStatus.NotApplicable;
    }

    static GCNotificationStatus WaitForFullGCComplete()
    {
        return GCNotificationStatus.Succeeded;
    }

    static GCNotificationStatus WaitForFullGCComplete(int milliseconds)
    {
        return GCNotificationStatus.Succeeded;
    }

    static void AddMemoryPresure(long pressure)
    {
        checkRange(pressure, 1, ptrdiff_t.max, "pressure");
        MEMORYSTATUSEX ms;
        GlobalMemoryStatusEx(ms);
        if (ms.ullAvailPhys + ms.ullAvailVirtual < pressure)
            gc.minimize();
        else
            return;
        GlobalMemoryStatusEx(ms);
        if (ms.ullAvailPhys + ms.ullAvailVirtual < pressure)
            gc.collect();
        else
            return;
        GlobalMemoryStatusEx(ms);
        if (ms.ullAvailPhys + ms.ullAvailVirtual < pressure)
            gc.minimize();
    }

    static void RemoveMemoryPresure(long pressure)
    {
        checkRange(pressure, 1, ptrdiff_t.max, "pressure");
    }
}

// =====================================================================================================================
// EventArgs
// =====================================================================================================================

class EventArgs : SharpObject
{
private:
    static EventArgs _empty;
public:
    @property static EventArgs Empty()
    {
        if (_empty is null)
            _empty = new EventArgs();
        return _empty;
    }
}


// =====================================================================================================================
// Console
// =====================================================================================================================

final class ConsoleCancelEventArgs : EventArgs
{
private:
    ConsoleSpecialKey specialKey;
    bool cancel;
public:
    this(ConsoleSpecialKey specialKey)
    {
        this.specialKey = specialKey;
        cancel = false;
    }

    @property bool Cancel() { return cancel; }
    @property bool Cancel(bool value) { return cancel = value; }
    @property ConsoleSpecialKey SpecialKey() { return specialKey; }
}

alias ConsoleCancelEventHandler = void delegate(Object sender, ConsoleCancelEventArgs e);

enum ConsoleColor
{
    Black,
    DarkBlue,
    DarkGreen,
    DarkCyan,
    DarkRed,
    DarkMagenta,
    DarkYellow,
    Gray,
    DarkGray,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Yellow,
    White,
}

enum ConsoleKey
{
    Backspace = 8,
    Tab = 9,
    Clear = 12,
    Enter = 13,
    Pause = 19,
    Escape = 27,
    Spacebar = 32,
    PageUp = 33,
    PageDown = 34,
    End = 35,
    Home = 36,
    LeftArrow = 37,
    UpArrow = 38,
    RightArrow = 39,
    DownArrow = 40,
    Select = 41,
    Print = 42,
    Execute = 43,
    PrintScreen = 44,
    Insert = 45,
    Delete = 46,
    Help = 47,
    D0 = 48,
    D1 = 49,
    D2 = 50,
    D3 = 51,
    D4 = 52,
    D5 = 53,
    D6 = 54,
    D7 = 55,
    D8 = 56,
    D9 = 57,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LeftWindows = 91,
    RightWindows = 92,
    Applications = 93,
    Sleep = 95,
    NumPad0 = 96,
    NumPad1 = 97,
    NumPad2 = 98,
    NumPad3 = 99,
    NumPad4 = 100,
    NumPad5 = 101,
    NumPad6 = 102,
    NumPad7 = 103,
    NumPad8 = 104,
    NumPad9 = 105,
    Multiply = 106,
    Add = 107,
    Separator = 108,
    Subtract = 109,
    Decimal = 110,
    Divide = 111,
    F1 = 112,
    F2 = 113,
    F3 = 114,
    F4 = 115,
    F5 = 116,
    F6 = 117,
    F7 = 118,
    F8 = 119,
    F9 = 120,
    F10 = 121,
    F11 = 122,
    F12 = 123,
    F13 = 124,
    F14 = 125,
    F15 = 126,
    F16 = 127,
    F17 = 128,
    F18 = 129,
    F19 = 130,
    F20 = 131,
    F21 = 132,
    F22 = 133,
    F23 = 134,
    F24 = 135,
    BrowserBack = 166,
    BrowserForward = 167,
    BrowserRefresh = 168,
    BrowserStop = 169,
    BrowserSearch = 170,
    BrowserFavorites = 171,
    BrowserHome = 172,
    VolumeMute = 173,
    VolumeDown = 174,
    VolumeUp = 175,
    MediaNext = 176,
    MediaPrevious = 177,
    MediaStop = 178,
    MediaPlay = 179,
    LaunchMail = 180,
    LaunchMediaSelect = 181,
    LaunchApp1 = 182,
    LaunchApp2 = 183,
    Oem1 = 186,
    OemPlus = 187,
    OemComma = 188,
    OemMinus = 189,
    OemPeriod = 190,
    Oem2 = 191,
    Oem3 = 192,
    Oem4 = 219,
    Oem5 = 220,
    Oem6 = 221,
    Oem7 = 222,
    Oem8 = 223,
    Oem102 = 226,
    Process = 229,
    Packet = 231,
    Attention = 246,
    CrSel = 247,
    ExSel = 248,
    EraseEndOfFile = 249,
    Play = 250,
    Zoom = 251,
    NoName = 252,
    Pa1 = 253,
    OemClear = 254,
}

@Flags()
enum ConsoleModifiers
{
    Alt = 1,
    Shift = 2,
    Control = 4,
}

enum ConsoleSpecialKey
{
    ControlC,
    ControlBreak,
}

struct Console
{
private:
    @disable this();
    static TextReader consoleIn;
    static TextWriter consoleOut;
    static TextWriter consoleErr;
    static void* inputHandle;
    static void* outputHandle;
    static void* errorHandle;
    static Encoding inputEncoding;
    static Encoding outputEncoding;
    static bool isConsoleOutRedirected;
    static bool isConsoleErrRedirected;
    static ushort defaultAttributes;
    static bool areDefaultAttributesRead;
    enum defaultBufferSize = 256;

    static void readDefaultAttributtes()
    {
        if (areDefaultAttributesRead)
            return;
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(getInputHandle(), csbi) != 0)
        {
            defaultAttributes = csbi.wAttributes;
            areDefaultAttributesRead = true;
        }
    }

    static void* getInputHandle()
    {
        if (!inputHandle)
        {
            inputHandle = GetStdHandle(STD_INPUT_HANDLE);
            if (!inputHandle)
                Marshal.ThrowExceptionForHR(Marshal.GetLastWin32Error());
        }
        return inputHandle;
    }

    static void* getOutputHandle()
    {
        if (!outputHandle)
        {
            outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
            if (!outputHandle)
                Marshal.ThrowExceptionForHR(Marshal.GetLastWin32Error());
        }
        return outputHandle;
    }

    static void* getErrorHandle()
    {
        if (!errorHandle)
        {
            errorHandle = GetStdHandle(STD_ERROR_HANDLE);
            if (!errorHandle)
                Marshal.ThrowExceptionForHR(Marshal.GetLastWin32Error());
        }
        return errorHandle;
    }

    static bool isHandleRedirected(void* handle)
    {
        auto fileType = GetFileType(handle);
        if ((fileType & FILE_TYPE_CHAR) != FILE_TYPE_CHAR)
            return true;
        uint mode;
        return GetConsoleMode(handle, mode) == 0;
    }

    static bool isWriteable(void* handle)
    {
        ubyte junk;
        return WriteFile(handle, &junk, 0, null, null) != 0;
    }

    static bool isUnicode(Encoding encoding)
    {
        if (auto ue = cast(UnicodeEncoding)encoding)
            return ue.CodePage == Encoding.Unicode.CodePage;
        return false;
    }

    static Stream getStream(int std, FileAccess access, int bufferSize)
    {
        auto handle = GetStdHandle(std);
        if (handle is null)
            return Stream.Null;
        if (std != STD_INPUT_HANDLE && !isWriteable(handle))
            return Stream.Null;
        bool useFile;
        switch(std)
        {
            case STD_INPUT_HANDLE:
                useFile = !isUnicode(InputEncoding) || IsInputRedirected;
                break;
            case STD_OUTPUT_HANDLE:
                useFile = !isUnicode(OutputEncoding) || IsOutputRedirected;
                break;
            case STD_ERROR_HANDLE:
                useFile = !isUnicode(OutputEncoding) || IsErrorRedirected;
                break;
            default:
                useFile = true;
                break;
        }
        return new ConsoleStream(handle, access, useFile);
    }


public:
    static void Beep(int frequency, int duration)
    {
        checkRange(frequency, 37, 32767, "frequency");
        internals.kernel32.Beep(frequency, duration);
    }

    static void Beep()
    {
        Beep(800, 200);
    }

    static void Clear()
    {
        auto handle = getOutputHandle();
        CONSOLE_SCREEN_BUFFER_INFO info;
        if (GetConsoleScreenBufferInfo(handle, info) == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        auto size = info.dwSize.X * info.dwSize.Y;
        uint written;
        if (FillConsoleOutputCharacterW(handle, ' ', size, COORD(), written) == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        if (SetConsoleCursorPosition(handle, COORD()) == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
    }

    static @property IsInputRedirected()
    {
        return isHandleRedirected(getInputHandle());
    }

    static @property IsOutputRedirected()
    {
        return isHandleRedirected(getOutputHandle());
    }

    static @property IsErrorRedirected()
    {
        return isHandleRedirected(getErrorHandle());
    }

    static @property Encoding InputEncoding()
    {
        if (inputEncoding is null)
            inputEncoding = Encoding.GetEncoding(GetConsoleCP());
        return inputEncoding;
    }

    static @property Encoding InputEncoding(Encoding value)
    {
        checkNull(value);
        if (!isUnicode(value))
        {
            if (SetConsoleCP(value.CodePage) == 0)
                Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        }
        consoleIn = null;
        return inputEncoding = cast(Encoding)value.Clone();
    }

    static @property Encoding OutputEncoding()
    {
        if (outputEncoding is null)
            outputEncoding = Encoding.GetEncoding(GetConsoleOutputCP());
        return outputEncoding;
    }

    static @property Encoding OutputEncoding(Encoding value)
    {
        checkNull(value);
        if (consoleOut && !isConsoleOutRedirected)
            consoleOut.Flush();
        if (consoleErr && !isConsoleErrRedirected)
            consoleErr.Flush();
        if (!isUnicode(value))
        {
            if (SetConsoleOutputCP(value.CodePage) == 0)
                Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        }      
        consoleOut = null;
        consoleErr = null;
        return outputEncoding = cast(Encoding)value.Clone();
    }

    static Stream OpenStandardInput(int bufferSize)
    {
        if (bufferSize < 0)
            throw new ArgumentOutOfRangeException("bufferSize");
        return getStream(STD_INPUT_HANDLE, FileAccess.Read, bufferSize);
    }

    static Stream OpenStandardInput()
    {
        return OpenStandardInput(defaultBufferSize);
    }

    static Stream OpenStandardOutput(int bufferSize)
    {
        if (bufferSize < 0)
            throw new ArgumentOutOfRangeException("bufferSize");
        return getStream(STD_OUTPUT_HANDLE, FileAccess.Write, bufferSize);
    }

    static Stream OpenStandardOutput()
    {
        return OpenStandardOutput(defaultBufferSize);
    }

    static Stream OpenStandardError(int bufferSize)
    {
        if (bufferSize < 0)
            throw new ArgumentOutOfRangeException("bufferSize");
        return getStream(STD_ERROR_HANDLE, FileAccess.Write, bufferSize);
    }

    static Stream OpenStandardError()
    {
        return OpenStandardError(defaultBufferSize);
    }

    static @property TextReader In()
    {
        if (consoleIn is null)
        {
            Stream stream = OpenStandardInput(defaultBufferSize);
            if (stream == Stream.Null)
                consoleIn = StreamReader.Null;
            else
                consoleIn = TextReader.Synchronized(new StreamReader(stream, InputEncoding, false, defaultBufferSize, true)); 
        }
        return consoleIn;
    }

    static @property TextWriter Out()
    {
        if (consoleOut is null)
        {
            Stream stream = OpenStandardOutput(defaultBufferSize);
            if (stream == Stream.Null)
                consoleOut = StreamWriter.Null;
            else
            {
                auto writer = new StreamWriter(stream, OutputEncoding, defaultBufferSize, true);
                writer.AutoFlush = true;
                consoleOut = TextWriter.Synchronized(writer); 
            }
        }
        return consoleOut;
    }

    static @property TextWriter Error()
    {
        if (consoleErr is null)
        {
            Stream stream = OpenStandardError(defaultBufferSize);
            if (stream == Stream.Null)
                consoleErr = StreamWriter.Null;
            else
            {
                auto writer = new StreamWriter(stream, OutputEncoding, defaultBufferSize, true);
                writer.AutoFlush = true;
                consoleErr = TextWriter.Synchronized(writer); 
            }
        }
        return consoleErr;
    }

    static void Write(wstring value)
    {
        Out.Write(value);
    }

    static void Write(wchar value)
    {
        Out.Write(value);
    }

    static void Write(bool value)
    {
        Out.Write(value);
    }

    static void Write(byte value)
    {
        Out.Write(value);
    }

    static void Write(ubyte value)
    {
        Out.Write(value);
    }

    static void Write(short value)
    {
        Out.Write(value);
    }

    static void Write(ushort value)
    {
        Out.Write(value);
    }

    static void Write(int value)
    {
        Out.Write(value);
    }

    static void Write(uint value)
    {
        Out.Write(value);
    }

    static void Write(long value)
    {
        Out.Write(value);
    }

    static void Write(ulong value)
    {
        Out.Write(value);
    }

    static void Write(float value)
    {
        Out.Write(value);
    }

    static void Write(double value)
    {
        Out.Write(value);
    }

    static void Write(decimal value)
    {
        Out.Write(value);
    }

    static void Write(T...)(wstring fmt, T args) if (T.length > 0)
    {
        Out.Write(fmt, args);
    }

    static void Write(wchar[] buffer, int index, int count)
    {
        Out.Write(buffer, index, count);
    }

    static void Write(wchar[] buffer)
    {
        Out.Write(buffer);
    }

    static void WriteLine(wstring value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(wchar value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(bool value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(byte value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(ubyte value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(short value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(ushort value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(int value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(uint value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(long value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(ulong value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(float value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(double value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(decimal value)
    {
        Out.WriteLine(value);
    }

    static void WriteLine(T...)(wstring fmt, T args) if (T.length > 0)
    {
        Out.WriteLine(fmt, args);
    }

    static void WriteLine(wchar[] buffer, int index, int count)
    {
        Out.WriteLine(buffer, index, count);
    }

    static void WriteLine(wchar[] buffer)
    {
        Out.WriteLine(buffer);
    }

    static int Read()
    {
        return In.Read();
    }

    static wstring ReadLine()
    {
        return In.ReadLine();
    }

    static void SetIn(TextReader newIn)
    {
        checkNull(newIn, "newIn");
        consoleIn = TextReader.Synchronized(newIn);
    }

    static void SetOut(TextWriter newOut)
    {
        checkNull(newOut, "newOut");
        consoleOut = TextWriter.Synchronized(newOut);
        isConsoleOutRedirected = true;
    }

    static void SetError(TextWriter newError)
    {
        checkNull(newError, "newError");
        consoleErr = TextWriter.Synchronized(newError);
        isConsoleErrRedirected = true;
    }

    static @property bool CapsLock()
    {
        return (GetKeyState(0x14) & 1) == 1;
    }

    static @property bool NumberLock()
    {
        return (GetKeyState(0x90) & 1) == 1;
    }

    static @property ConsoleColor BackgroundColor()
    {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(getOutputHandle(), csbi) != 0)
            return cast(ConsoleColor)(csbi.wAttributes & 0xf0 >> 4);
        return ConsoleColor.Black;
    }

    static @property ConsoleColor BackgroundColor(ConsoleColor value)
    {
        readDefaultAttributtes();
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(getOutputHandle(), csbi) != 0)
        {
            csbi.wAttributes &= ~0xf0;
            csbi.wAttributes |= value << 4;
            SetConsoleTextAttribute(getOutputHandle(), csbi.wAttributes);
        }
        return value;
    }

    static @property ConsoleColor ForegroundColor(ConsoleColor value)
    {
        readDefaultAttributtes();
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(getOutputHandle(), csbi) != 0)
        {
            csbi.wAttributes &= ~0xf;
            csbi.wAttributes |= value;
            SetConsoleTextAttribute(getOutputHandle(), csbi.wAttributes);
        }
        return value;
    }

    static @property ConsoleColor ForegroundColor()
    {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(getOutputHandle(), csbi) != 0)
            return cast(ConsoleColor)(csbi.wAttributes & 0xf);
        return ConsoleColor.Gray;
    }

    static void ResetColor()
    {
        if (areDefaultAttributesRead)
            SetConsoleTextAttribute(getInputHandle(), defaultAttributes);
    }
}

final private class ConsoleStream: Stream
{
    void* handle;
    FileAccess access;
    bool useFile;

    this(void* handle, FileAccess access, bool useFile)
    {
        this.handle = handle;
        this.access = access;
        this.useFile = useFile;
    }

    override @property bool CanRead()
    {
        return (access & FileAccess.Read) == FileAccess.Read;
    }

    override @property bool CanWrite() 
    {
        return (access & FileAccess.Write) == FileAccess.Write;
    }

    override @property bool CanSeek()
    {
        return false;
    }

    override long Length()
    {
        throw new NotSupportedException();
    }

    override @property long Position() 
    {
        throw new NotSupportedException();
    }

    override @property long Position(long value) 
    {
        throw new NotSupportedException();
    }

    override void Dispose(bool disposing) 
    {
        access = cast(FileAccess)0;
        handle = null;
        super.Dispose(disposing);
    }

    override void Flush() 
    {
        if (!handle)
            throw new ObjectDisposedException(SharpResources.GetString("ObjectDisposedFileClosed"));
        if (!CanWrite)
            throw new NotSupportedException();
    }

    override void SetLength(long value) 
    {
        throw new NotSupportedException();
    }

    override long Seek(long offset, SeekOrigin origin) 
    {
        throw new NotSupportedException();
    }

    override int Read(ubyte[] buffer, int offset, int count)
    {
        checkNull(buffer, "buffer");
        checkIndex(buffer, offset, count, "offset");
        if (!CanRead)
            throw new NotSupportedException();
        bool success;
        uint bytesRead;
        if (useFile)
            success = ReadFile(handle, buffer.ptr + offset, count, &bytesRead, null) != 0;
        else
        {
            success = ReadConsoleW(handle, buffer.ptr + offset, count / 2, &bytesRead, null) != 0;
            bytesRead *= 2;
        }

        if (!success)
        {
            auto err = Marshal.GetLastWin32Error();
            if (err == 0xe8 || err == 0x6d)
                return 0;
            Marshal.ThrowExceptionForHR(Marshal.GetHRForWin32Error(err));
        }
        return bytesRead;           
    }

    override void Write(ubyte[] buffer, int offset, int count) 
    {
        checkNull(buffer, "buffer");
        checkIndex(buffer, offset, count, "offset");
        if (!CanWrite)
            throw new NotSupportedException();

        bool success;
        if (useFile)
            success = WriteFile(handle, buffer.ptr + offset, count, null, null) != 0;
        else
            success = WriteConsoleW(handle, buffer.ptr + offset, count / 2, null, null) != 0;

        if (!success)
        {
            auto err = Marshal.GetLastWin32Error();
            if (err == 0xe8 || err == 0x6d)
                return;
            Marshal.ThrowExceptionForHR(Marshal.GetHRForWin32Error(err));
        }
    }

    
}

// =====================================================================================================================
// MulticastDelegate
// =====================================================================================================================

struct MulticastDelegate(R, T...)
{
private:
    alias D = R delegate(T);
    alias F = R function(T);
    enum voidReturn = is(R == void);

    D[] delegates;
    F[] functions;
public:

    this(D dg)
    {
        if (dg)
            delegates = [dg];
    }
    
    R opCall(T args)
    {
        static if (!voidReturn) { R ret; }
        if (delegates)
        {
            foreach(d; delegates)
            {
                if (d)
                {
                    static if (voidReturn)
                        d(args);
                    else
                        ret = d(args);
                }
            }
        }

        if (functions)
        {
            foreach(f; functions)
            {
                if (f)
                {
                    static if (voidReturn)
                        f(args);
                    else
                        ret = f(args);
                }
            }
        }

        static if (!voidReturn) { return ret; }       
    }

    void opOpAssign(string op)(D dg) if (op == '+' || op == '~')
    {
        if (dg)
            delegates ~= dg;
    }

    void opOpAssign(string op)(F func) if (op == '+' || op == '~')
    {
        if (func)
            functions ~= func;
    }

    void opOpAssign(string op)(D dg) if (op == '-')
    {
        if (dg)
        {
            for(size_t i = 0; i < delegates.length; i--)
            {
                if (delegates[i] is dg)
                {
                    delegates = delegates[0 .. i] ~ delegates[i + 1 .. $];
                    return;
                }
            }
        }
    }

    void opOpAssign(string op)(F func) if (op == '-')
    {
        if (functions)
        {
            for(size_t i = 0; i < functions.length; i--)
            {
                if (functions[i] is dg)
                {
                    functions = functions[0 .. i] ~ functions[i + 1 .. $];
                    return;
                }
            }
        }
    }

    auto opBinary(string op)(D dg) if (op == "+")
    {
        typeof(this) mc;
        mc.delegates = delegates.dup ~ dg;
        mc.functions = functions.dup;
        return mc;
    }

    auto opBinary(string op)(F func) if (op == "+")
    {
        typeof(this) mc;
        mc.delegates = delegates.dup;
        mc.functions = functions.dup ~ func;
        return mc;
    }

    MulticastDelegate!(R, T) opBinary(string op)(MulticastDelegate!(R, T) mc) if (op == "+")
    {
        MulticastDelegate!(R, T) ret;
        ret.delegates = delegates ~ mc.delegates;
        ret.functions = functions ~ mc.functions;
        return mc;
    }

    D[] GetDelegateList()
    {
        return delegates.dup;
    }

    F[] GetFunctionList()
    {
        return functions.dup;
    }

    
}

alias EventHandler(A) = MulticastDelegate!(void, Object, A);


