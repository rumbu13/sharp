module system.text;

import system;
import internals.checked;
import internals.ole32;
import system.globalization;
import system.runtime.interopservices;
import internals.utf;
import internals.kernel32;
import internals.interop;
import internals.resources;

@trusted private
extern (C) void* memcpy(void*, const void*, size_t);

final class StringBuilder : SharpObject
{
private:
	enum _defaultCapacity = 16;
	int _maxCapacity = int.max;
	int _length;
	wchar[] _buf;

    @trusted 
    void overlappedCopy(size_t copyTo, size_t copyFrom, size_t count)
    {
        wchar* dest = _buf.ptr + copyTo;
        wchar* source = _buf.ptr + copyFrom;
        memcpy(dest, source, count * wchar.sizeof);
    }

    @trusted 
    void overlappedCopy(size_t copyTo, size_t copyFrom)
    {
        overlappedCopy(copyTo, copyFrom, _buf.length - (copyTo > copyFrom ? copyFrom : copyTo));
    }

public:
    this()
    {
        this(_defaultCapacity, int.max);
    }

    this(int capacity)
    {
        this(capacity, int.max);
    }

    this(wstring value)
	{
		this(value, 0);
	}

    this(int capacity, int maxCapacity)
	{
        if (capacity > maxCapacity)
			throw new ArgumentOutOfRangeException("capacity");
		if (maxCapacity < 1)
			throw new ArgumentOutOfRangeException("maxCapacity");
		_maxCapacity = maxCapacity;
		if (capacity == 0)
			_buf.length = maxCapacity < _defaultCapacity ? maxCapacity : _defaultCapacity;
		else
			_buf.length = capacity;
	}

    this(wstring value, int capacity)
	{
		this(value, 0, value.length, capacity);
	}

    this(wstring value, int startIndex, int length, int capacity)
    {
        size_t len = value.length;
        checkIndex(value, startIndex, length, "index", "length");
        size_t cap = capacity == 0 ? _defaultCapacity : capacity;
        while (cap < length)
        {
            try
            {
                cap = checkedMul(cap, 2);
            }
            catch (OverflowException)
            {
                cap = int.max;
                break;
            }
        }
        this(cap, int.max);
        _buf[0..length] = value[startIndex .. startIndex + length];
        _length = length;
    }

    StringBuilder Append(wchar value)
	{
		EnsureCapacity(_length + 1);
		_buf[_length++] = value;
		return this;
	}

    StringBuilder Append(wstring value)
    {
        return Append(value, 0, value.length);
    }

    StringBuilder Append(wchar[] value)
	{
		return Append(value, 0, value.length);
	}

    StringBuilder Append(wchar value, int repeatCount)
	{
        if (repeatCount == 0)
            return this;
        auto newLen = _length + repeatCount;
		EnsureCapacity(newLen);
		_buf[_length .. newLen] = value;
        _length = newLen;
		return this;
	}

    StringBuilder Append(wstring value, int startIndex, int count)
	{
        checkNull(value);
		checkIndex(value, startIndex, count, "startIndex");
		if (_maxCapacity - _length < count)
			throw new ArgumentOutOfRangeException("length");
		size_t newLength = _length + count;
		EnsureCapacity(newLength);
		_buf[_length..newLength] = value[startIndex..startIndex + count];
		_length = newLength;
		return this;
	}

    StringBuilder Append(wchar[] value, int startIndex, int count)
	{
        return Append(cast(wstring)value);
	}

    StringBuilder AppendFormat(A...)(IFormatProvider provider, wstring fmt, A args) if (A.length > 0)
    {
        return Append(String.Format(provider, fmt, args));        
    }

    StringBuilder AppendFormat(A...)(wstring fmt, A args) if (A.length > 0)
    {
        return Append(String.Format(fmt, args));
    }

    StringBuilder AppendLine()
    {
        return Append(Environment.NewLine);
    }

    StringBuilder AppendLine(wstring value)
    {
        Append(value);
        return AppendLine();
    }

    @property pure @safe nothrow @nogc
    int Capacity() const
	{
		return _buf.length;
	}

    @property 
    int capacity(int value)
	{
		size_t len = _buf.length;
		if (value == len)
			return len;
        checkRange(value, _length, _maxCapacity);
		_buf.length = value;
		return _buf.length;
	}

    StringBuilder Clear()
    {
        _length = 0;
        return this;
    }

    void CopyTo(size_t sourceIndex, wchar[] destination, int destinationIndex, int count)
	{
		checkNull(destination, "destination");
        if (sourceIndex >= _length)
            throw new ArgumentOutOfRangeException("sourceIndex");
		checkIndex(destination, destinationIndex, count, "destinationIndex");
		if (sourceIndex > _length - count)
			throw new ArgumentException(null, "sourceIndex");
		if (count == 0)
			return;
		destination[destinationIndex..destinationIndex + count] = _buf[sourceIndex..sourceIndex + count];
	}

    StringBuilder Insert(size_t index, wchar value)
	{
		if (index > _length)
			throw new ArgumentOutOfRangeException("index");
		EnsureCapacity(_length + 1);
		_length++;
		overlappedCopy(index + 1, index);
		_buf[index] = value;
		return this;
	}

    StringBuilder Insert(int index, wstring value, int startIndex, int charCount)
	{
		if (index > _length)
			throw new ArgumentOutOfRangeException("index");
		checkNull(value);
		checkIndex(value, startIndex, charCount, "startIndex", "charCount");
		if (charCount == 0)
			return this;
		int newLength = _length + charCount;
		EnsureCapacity(newLength);
		overlappedCopy(index + charCount, index);
		_buf[index .. index + charCount] = value[startIndex .. startIndex + charCount];
		_length = newLength;
		return this;
	}

    StringBuilder Insert(int index, wchar[] value, int startIndex, int charCount)
	{
		return Insert(index, cast(wstring)(value), startIndex, charCount);
	}

    StringBuilder Insert(int index, wstring value)
	{
		return Insert(index, value, 0, value.length);
	}

    StringBuilder Insert(int index, wchar[] value)
	{
		return Insert(index, cast(wstring)value);
	}

    int EnsureCapacity(int capacity)
	{
		if (capacity > _maxCapacity)
			throw new ArgumentOutOfRangeException("capacity");
		if (capacity > _buf.length)
		{
			size_t cap = _buf.length;
			while (cap < capacity)
			{
				try
                {
                    cap = checkedMul(cap, 2);
                }
                catch (OverflowException)
                {
                    cap = int.max;
                }
			}
			if (cap > _maxCapacity)
				cap = _maxCapacity;
			_buf.length = cap;
		}
		return _buf.length;
	}

    @property @safe nothrow @nogc
    int Length() const
	{
		return _length;
	}

    @property 
    int Length(int value)
	{
		EnsureCapacity(value);
		if (value > _length)
			_buf[_length..value] = wchar.init;
		_length = value;
		return _length;
	}

    wstring ToString(int startIndex, int count) const
	{
		if (startIndex > _length)
			throw new ArgumentOutOfRangeException("startIndex");
		if (startIndex > _length - count)
			throw new ArgumentOutOfRangeException("count");
		return cast(wstring)_buf[startIndex..startIndex + count];
	}

    override wstring ToString() const
    {
        return ToString(0, _length);
    }


    @property pure @safe nothrow 
    int MaxCapacity() const
	{
		return _maxCapacity;
	}

    bool opEquals(StringBuilder other)
	{
		return other !is null && 
			this._length == other._length &&
            this._maxCapacity == other._maxCapacity &&
            this._buf[0.._length] == other._buf[0.._length];
	}

    override bool opEquals(Object other)
    {
        if (auto sb = cast(StringBuilder)other)
            return opEquals(sb);
        return super.opEquals(other);
    }

    wchar opIndex(size_t index) const
	{
		if (index >= _length)
			throw new ArgumentOutOfRangeException("index");
		return _buf[index];
	}

    wchar opIndexAssign(size_t index, wchar value)
	{
		if (index >= _length)
			throw new ArgumentOutOfRangeException("index");
		return _buf[index] = value;
	}

    wstring opSlice(size_t dim)(size_t from, size_t to) const if (dim == 0)
	{
		return ToString(from, to - from);
	}

    StringBuilder Remove(int startIndex, int length)
	{
		if (length > _buf.length - startIndex)
			throw new ArgumentOutOfRangeException("startIndex");
		int newLength = _length - length;
		overlappedCopy(startIndex, startIndex + length);
		_length = newLength;
		return this;
	}

    StringBuilder Replace(wchar oldItem, wchar newItem, int startIndex, int count)
	{
		if (startIndex > _length)
			throw new ArgumentOutOfRangeException("startIndex");
		if (startIndex > _length - count)
			throw new ArgumentOutOfRangeException("count");
		for(int i = startIndex; i < startIndex + count; i++)
		{
			if (_buf[i] == oldItem)
				_buf[i] = newItem;
		}
		return this;
	}

    StringBuilder Replace(wchar oldItem, wchar newItem)
	{
        
		return Replace(oldItem, newItem, 0, _length);
	}

    StringBuilder Replace(wstring oldItem, wstring newItem, int startIndex, int count)
	{
		if (startIndex > _length)
			throw new ArgumentOutOfRangeException("startIndex");
		if (startIndex > _length - count)
            throw new ArgumentOutOfRangeException("count");
		int i = startIndex;
		int cnt = startIndex + count;
		int oldLen = oldItem.length;
		int newLen = newItem.length;
		while (i < cnt && i < _length - oldLen)
		{
			if (_buf[i.. i + oldLen] == oldItem[])
			{
				if (oldLen == newLen)
					_buf[i.. i + oldLen] = newItem[];
				else if (oldLen < newLen)
				{
					_buf[i..i + oldLen] = newItem[0 .. oldLen]; 
					Insert(i + oldLen, newItem[oldLen .. newLen]);
				}
				else
				{
					_buf[i..i + newLen] = newItem[];
					Remove(i + newLen, oldLen - newLen);
				}
				i += newLen;
				cnt = cnt + newLen - oldLen;
			}
			else
				i++;
		}
		return this;
	}

    StringBuilder Replace(wstring oldItem, wstring newItem)
	{
		return Replace(oldItem, newItem, 0, _length);
	}    

    StringBuilder Append(byte value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(short value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(int value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(long value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(ubyte value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(ushort value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(uint value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(ulong value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(float value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(double value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(bool value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(decimal value)
    {
        //dbug - overload resolution not possible without cast
        return Append(value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Append(Object value)
    {
        if (value is null)
            return this;
        return Append(value.ToString());
    }


    StringBuilder Insert(int index, byte value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, short value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, int value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, long value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, ubyte value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, ushort value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, uint value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, ulong value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, float value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, double value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, bool value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, decimal value)
    {
        //dbug - overload resolution not possible without cast
        return Insert(index, value.ToString(cast(IFormatProvider)CultureInfo.CurrentCulture));
    }

    StringBuilder Insert(int index, Object value)
    {
        if (value is null)
            return this;
        return Insert(index, value.ToString());
    }    
}

final class EncodingInfo : SharpObject
{
private:
    int _codePage;
    wstring _name;
    wstring _displayName;

    this(int codePage, wstring name, wstring displayName)
    {
        _codePage = codePage;
        _name = name;
        _displayName = displayName;
    }

public:

    @property int CodePage()  
    { 
        return _codePage; 
    }

    @property wstring Name()  
    { 
        return _name; 
    }
    
    @property wstring DisplayName()  
    { 
        return _displayName; 
    }

    @safe nothrow  
    override int GetHashCode() 
    {
        return _codePage;
    }

    override bool Equals(Object o)
    {
        if (auto ei = cast(EncodingInfo)o)
            return ei._codePage == this._codePage;
        return false;
    }

    Encoding GetEncoding()
    {
        return Encoding.GetEncoding(_codePage);
    }
}

private alias MultiLanguage = COMImport!(g!"275c23e2-3747-11d0-9fea-00aa003f8646", IMultiLanguage2, true);

enum NormalizationForm
{
    FormC = 1,
    FormD = 2,
    FormKC = 5,
    FormKD = 6,
}

abstract class Encoding : SharpObject
{
private:
    int _codePage;
    bool _isReadOnly;
    bool _iscpInfoAvailable;
    .EncoderFallback _encoderFallback;
    .DecoderFallback _decoderFallback;
    EncoderFallbackBuffer _encoderBuffer;
    DecoderFallbackBuffer _decoderBuffer;

    static Encoding _ascii;
    static Encoding _utf8;
    static Encoding _unicode;
    static Encoding _utf32;
    static Encoding _default;
    static Encoding _utf7;
    static Encoding _bigEndianUnicode;
    static Encoding _latin1;

    static EncodingSystemInfo[uint] _infoMap;
    static EncodingInfo[] _encodingInfoCache;
    static bool _isSystemInfoAvailable;

    void ensureInfo()
    {
        if (_iscpInfoAvailable)
            return;

        auto p = _codePage in _infoMap;
        if (p)
        {
            _info = *p;
            _iscpInfoAvailable = true;
            return;
        }

        MIMECPINFO info;
        CPINFOEXW cpinfo;
        if (GetCPInfoExW(_codePage, 0, cpinfo) == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        auto lang = new MultiLanguage();
        scope(exit) lang.Dispose();
        lang.GetCodePageInfo(_codePage, 0, info);
        _info = EncodingSystemInfo(info, cpinfo);
        _infoMap[_codePage] = _info;
        _codePage = _info.codePage;
    }

    private static void ensureEncodingSystemInfo()
    {
        if (_isSystemInfoAvailable)
            return;
        _infoMap = null;
        auto lang = new MultiLanguage();
        scope(exit) lang.Dispose();
        IEnumCodePage enumerator;
        lang.EnumCodePages(MIMECONTF_MIME_LATEST, 0, enumerator);
        MIMECPINFO* info = cast(MIMECPINFO*)CoTaskMemAlloc(MIMECPINFO.sizeof);
        scope(exit) CoTaskMemFree(info);

        uint fetched;
        while (SUCCEEDED(enumerator.Next(1, info, fetched)))
        {
            if (fetched < 1)
                break;
            if (((*info).dwFlags & MIMECONTF_VALID) != 0)
            {
                CPINFOEXW cpInfo;
                if (GetCPInfoExW((*info).uiCodePage, 0, cpInfo) != 0)
                    _infoMap[(*info).uiCodePage] = EncodingSystemInfo(*info, cpInfo);
            }
        }
        _isSystemInfoAvailable = true;
    }

    void checkWriteable()
    {
        if (_isReadOnly)
            throw new InvalidOperationException();
    }

protected:

    EncodingSystemInfo _info;

    wchar[] getEncoderFallbackChars(wchar ch, int index)
    {
        if (_encoderBuffer !is null)
            _encoderBuffer.Reset();
        else
            _encoderBuffer = EncoderFallback.CreateFallbackBuffer();
        if (_encoderBuffer.Fallback(ch, index))
        {
            wchar[] result = new wchar[EncoderFallback.MaxCharCount];
            int i = 0;
            wchar c = _encoderBuffer.GetNextChar();
            while (c != 0 && i < result.length)
            {
                result[i++] = c;
                c = _encoderBuffer.GetNextChar();
            }
            if (_encoderBuffer.Remaining > 0)
                throw new ArgumentException("buffer");
            return result[0 .. i];
        }
        return null;
    }

    int getEncoderFallbackLength(wchar ch, int index)
    {
        if (_encoderBuffer !is null)
            _encoderBuffer.Reset();
        else
            _encoderBuffer = EncoderFallback.CreateFallbackBuffer();
        if (_encoderBuffer.Fallback(ch, index))
        {
            int i = 0;
            while (_encoderBuffer.GetNextChar() != 0)
                i++;
            return i;
        }
        return 0;
    }

    wchar[] getEncoderFallbackChars(wchar ch, wchar cl, int index)
    {
        if (_encoderBuffer !is null)
            _encoderBuffer.Reset();
        else
            _encoderBuffer = EncoderFallback.CreateFallbackBuffer();
        if (_encoderBuffer.Fallback(ch, cl, index))
        {
            wchar[] result = new wchar[EncoderFallback.MaxCharCount];
            int i = 0;
            wchar c = _encoderBuffer.GetNextChar();
            while (c != 0 && i < result.length)
            {
                result[i++] = c;
                c = _encoderBuffer.GetNextChar();
            }
            if (_encoderBuffer.Remaining > 0)
                throw new ArgumentException("buffer");
            return result[0 .. i];
        }
        return null;
    }

    size_t getEncoderFallbackLength(wchar ch, wchar cl, int index)
    {
        if (_encoderBuffer !is null)
            _encoderBuffer.Reset();
        else
            _encoderBuffer = EncoderFallback.CreateFallbackBuffer();
        if (_encoderBuffer.Fallback(ch, cl, index))
        {
            int i = 0;
            while (_encoderBuffer.GetNextChar() != 0)
                i++;
            return i;
        }
        return 0;
    }
    

    wchar[] getDecoderFallbackChars(ubyte[] sequence, size_t index)
    {
        if (_decoderBuffer !is null)
            _decoderBuffer.Reset();
        else
            _decoderBuffer = DecoderFallback.CreateFallbackBuffer();
        if (_decoderBuffer.Fallback(sequence, index))
        {
            wchar[] result = new wchar[DecoderFallback.MaxCharCount];
            int i = 0;
            wchar c = _decoderBuffer.GetNextChar();
            while (c != 0 && i < result.length)
            {
                result[i++] = c;
                c = _decoderBuffer.GetNextChar();
            }
            if (_decoderBuffer.Remaining > 0)
                throw new ArgumentException("buffer");
            return result[0 .. i];
        }
        return null;
    }

    int getDecoderFallbackLength(ubyte[] sequence, int index)
    {
        if (_decoderBuffer !is null)
            _decoderBuffer.Reset();
        else
            _decoderBuffer = DecoderFallback.CreateFallbackBuffer();
        if (_decoderBuffer.Fallback(sequence, index))
        {
            int i = 0;
            while (_decoderBuffer.GetNextChar() != 0)
                i++;
            return i;
        }
        return 0;
    }

    this(int codePage)
    {
        _codePage = codePage;
        try
        {
            ensureInfo();
        }
        catch (Exception ex)
        {
            throw new NotSupportedException(null, ex);
        }
        _encoderFallback = new EncoderReplacementFallback("\ufffd");
        _decoderFallback = new DecoderReplacementFallback("\ufffd");
    }

    this()
    {
        this(0);
    }

public:

    Object Clone()
    {
        auto r = cast(Encoding)MemberwiseClone();
        r._isReadOnly = false;
        return r;
    }

    @property final bool IsReadOnly() const
    {
        return _isReadOnly;
    }

    abstract int GetByteCount(wchar[] chars, int index, int count);
    abstract int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex);
    abstract int GetCharCount(ubyte[] bytes, int index, int count);
    abstract int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex);
    abstract int GetMaxByteCount(int charCount);
    abstract int GetMaxCharCount(int byteCount);

    int GetByteCount(wchar[] chars)
    {
        checkNull(chars, "chars");
        return GetByteCount(chars, 0, chars.length);
    }

    ubyte[] GetBytes(wchar[] chars, int index, int count)
    {
        ubyte[] buffer = new ubyte[GetByteCount(chars, index, count)];
        GetBytes(chars, index, count, buffer, 0);
        return buffer;
    }

    ubyte[] GetBytes(wchar[] chars)
    {
        checkNull(chars, "chars");
        return GetBytes(chars, 0, chars.length);
    }

    int GetCharCount(ubyte[] bytes)
    {
        checkNull(bytes, "bytes");
        return GetCharCount(bytes, 0, bytes.length);
    }

    wchar[] GetChars(ubyte[] bytes, int index, int count)
    {
        wchar[] buffer = new wchar[GetCharCount(bytes, index, count)];
        GetChars(bytes, index, count, buffer, 0);
        return buffer;
    }

    wchar[] GetChars(ubyte[] bytes)
    {
        checkNull(bytes, "bytes");
        return GetChars(bytes, 0, bytes.length);
    }

    static ubyte[] Convert(Encoding srcEncoding, Encoding dstEncoding, ubyte[] bytes, int index, int count)
    {
        checkNull(srcEncoding, "srcEncoding");
        checkNull(dstEncoding, "dstEncoding");
        checkNull(bytes, "bytes");
        return dstEncoding.GetBytes(srcEncoding.GetChars(bytes, index, count));
    }

    static ubyte[] Convert(Encoding srcEncoding, Encoding dstEncoding, ubyte[] bytes)
    {
        return Convert(srcEncoding, dstEncoding, bytes, 0, bytes.length);
    }

    int GetByteCount(wchar* chars, int count)
    {
        checkNull(chars, "chars");
        return GetByteCount(chars[0 .. count]);
    }

    int GetBytes(wchar* chars, int charCount, ubyte* bytes, size_t byteCount)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        ubyte[] buffer = new ubyte[byteCount];
        int result = GetBytes(chars[0 .. charCount], 0, charCount, buffer, 0);
        bytes[0 .. result] = buffer;
        return result;
    }

    int GetCharCount(ubyte* bytes, int count)
    {
        checkNull(bytes, "bytes");
        return GetCharCount(bytes[0 .. count]);
    }

    int GetChars(ubyte* bytes, size_t byteCount, wchar* chars, int charCount)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        wchar[] buffer = new wchar[charCount];
        int result = GetChars(bytes[0 .. byteCount], 0, byteCount, buffer, 0);
        chars[0 .. result] = buffer;
        return result;
    }

    ubyte[] GetPreamble()
    {
        return [];
    }

    wstring GetString(ubyte[] bytes, int index, int count)
    {
        return cast(wstring)GetChars(bytes, index, count);
    }

    wstring GetString(ubyte[] bytes)
    {
        checkNull(bytes, "bytes");
        return GetString(bytes, 0, bytes.length);
    }

    bool IsAlwaysNormalized(NormalizationForm form)
    {
        return false;
    }

    final bool IsAlwaysNormalized()
    {
        return IsAlwaysNormalized(NormalizationForm.FormC);
    }

    static Encoding GetEncoding(int codePage, .EncoderFallback encoderFallback, .DecoderFallback decoderFallback)
    {
        auto encoding = GetEncoding(codePage);
        encoding.EncoderFallback = encoderFallback;
        encoding.DecoderFallback = decoderFallback;
        return encoding;
    }

    static Encoding GetEncoding(int codePage)
    {
        checkRange(codePage, ushort.min, ushort.max, "codePage");
        switch(codePage)
        {
            case 0:
            case 1:
            case 2:
            case 3:
            case 42:
                throw new NotSupportedException(null);
            case 1200:
                return new UnicodeEncoding(false, true);
            case 1201:
                return new UnicodeEncoding(true, false);
            case 12000:
                return new UTF32Encoding(false, true);
            case 12001:
                return new UTF32Encoding(true, false);
            case 20127:
                return new ASCIIEncoding();
            case 28591:
                return new Latin1Encoding();
            case 65000:
                return new UTF7Encoding(true);
            case 65001:
                return new UTF8Encoding();
            default:
                return new CodePageEncoding(codePage);
        }
    }

    static Encoding GetEncoding(wstring name, .EncoderFallback encoderFallback, .DecoderFallback decoderFallback)
    {
        auto encoding = GetEncoding(name);
        encoding.EncoderFallback = encoderFallback;
        encoding.DecoderFallback = decoderFallback;
        return encoding;
    }

    static Encoding GetEncoding(wstring name)
    {
        checkNull(name, "name");
        ensureEncodingSystemInfo();
        foreach(m; _infoMap)
        {
            if (String.Equals(name, m.bodyName, StringComparison.OrdinalIgnoreCase))
                return GetEncoding(m.codePage);
            if (String.Equals(name, m.webName, StringComparison.OrdinalIgnoreCase))
                return GetEncoding(m.codePage);
            if (String.Equals(name, m.description, StringComparison.OrdinalIgnoreCase))
                return GetEncoding(m.codePage);
        }
        throw new ArgumentException("name");
    }

    static EncodingInfo[] GetEncodings()
    {
        if (_encodingInfoCache is null)
        {
            ensureEncodingSystemInfo();
            _encodingInfoCache.length = _infoMap.length;
            auto i = 0;
            foreach(m; _infoMap)
                _encodingInfoCache[i++] = new EncodingInfo(m.codePage, m.bodyName, m.description);
        }
        return _encodingInfoCache;
    }

    @property wstring BodyName()
    {
        ensureInfo();
        return _info.bodyName;
    }

    @property int CodePage()
    {
        ensureInfo();
        return _info.codePage;
    }

    @property wstring WebName()
    {
        ensureInfo();
        return _info.webName;
    }

    @property wstring EncodingName()
    {
        ensureInfo();
        return _info.description;
    }

    @property wstring HeaderName()
    {
        ensureInfo();
        return _info.headerName;
    }

    @property bool IsBrowserDisplay()
    {
        ensureInfo();
        return (_info.flags & MIMECONTF_BROWSER) != 0;
    }

    @property bool IsBrowserSave()
    {
        ensureInfo();
        return (_info.flags & MIMECONTF_SAVABLE_BROWSER) != 0;
    }

    @property bool IsMailNewsDisplay()
    {
        ensureInfo();
        return (_info.flags & MIMECONTF_MAILNEWS) != 0;
    }

    @property bool IsMailNewsSave()
    {
        ensureInfo();
        return (_info.flags & MIMECONTF_SAVABLE_MAILNEWS) != 0;
    }

    @property bool IsSingleByte()
    {
        ensureInfo();
        return _info.maxCharSize <= 1;
    }

    @property int WindowsCodePage()
    {
        ensureInfo();
        return _info.familyCodePage;
    }

    @property .EncoderFallback EncoderFallback() @safe nothrow
    {
        return _encoderFallback;
    }

    @property .EncoderFallback EncoderFallback(.EncoderFallback value)
    {
        checkWriteable();
        checkNull(value);
        _encoderBuffer = null;
        return _encoderFallback = value;
    }

    @property .DecoderFallback DecoderFallback() @safe nothrow
    {
        return _decoderFallback;
    }

    @property .DecoderFallback DecoderFallback(.DecoderFallback value)
    {
        checkWriteable();
        checkNull(value);
        _decoderBuffer = null;
        return _decoderFallback = value;
    }

    override bool Equals(Object obj)
    {
        if (auto enc = cast(Encoding)(obj))
            return  enc._codePage == this._codePage &&
                    enc._encoderFallback.Equals(this._encoderFallback) &&
                    enc._decoderFallback.Equals(this._decoderFallback);
        return false;
    }

    @safe nothrow
    override int GetHashCode()  
    {
        return _codePage + _encoderFallback.GetHashCode() + _decoderFallback.GetHashCode();
    }

    Encoder GetEncoder()
    {
        return new DefaultEncoder(this);
    }

    Decoder GetDecoder()
    {
        if (IsSingleByte)
            return new DefaultDecoder(this);
        else
        {
            return new DBCSDecoder(this);
        }
    }

    static @property Encoding ASCII()
    {
        if (_ascii is null)
            _ascii = new ASCIIEncoding();
        return _ascii;
    }

    static @property Encoding UTF8()
    {
        if (_utf8 is null)
            _utf8 = new UTF8Encoding();
        return _utf8;
    }

    static @property Encoding Unicode()
    {
        if (_unicode is null)
            _unicode = new UnicodeEncoding();
        return _unicode;
    }

    static @property Encoding UTF32()
    {
        if (_utf32 is null)
            _utf32 = new UTF32Encoding();
        return _utf32;
    }

    static @property Encoding Default()
    {
        if (_default is null)
            _default = GetEncoding(GetACP());
        return _default;
    }

    static @property Encoding UTF7()
    {
        if (_utf7 is null)
            _utf7 = new UTF7Encoding(true);
        return _utf7;
    }

    static @property Encoding BigEndianUnicode()
    {
        if (_bigEndianUnicode is null)
            _bigEndianUnicode = new UnicodeEncoding(true, true, false);
        return _bigEndianUnicode;
    }
}

private struct EncodingSystemInfo
{
    uint flags;
    uint codePage;
    uint familyCodePage;
    wstring description;
    wstring webName;
    wstring headerName;
    wstring bodyName;
    uint  maxCharSize;
    ubyte[] defaultChar;
    ubyte[] leadBytes;
    wchar defaultUTF16Char;

    this(ref MIMECPINFO mimeInfo, ref CPINFOEXW cpInfo)
    {
        flags = mimeInfo.dwFlags;
        codePage = mimeInfo.uiCodePage;
        familyCodePage = mimeInfo.uiFamilyCodePage;
        description = fromSz(mimeInfo.wszDescription.ptr, 64);
        webName = fromSz(mimeInfo.wszWebCharset.ptr, 50);
        headerName = fromSz(mimeInfo.wszHeaderCharset.ptr, 50);
        bodyName = fromSz(mimeInfo.wszBodyCharset.ptr, 50);
        maxCharSize = cpInfo.MaxCharSize;
        defaultChar = maxCharSize <= 1 ? [cpInfo.DefaultChar[0]] : cpInfo.DefaultChar.dup;
        defaultUTF16Char = cpInfo.UnicodeDefaultChar;
        leadBytes = null;
        size_t i = 0;
        while (cpInfo.LeadByte[i] != 0 && i < 11)
        {
            leadBytes ~= [cpInfo.LeadByte[i], cpInfo.LeadByte[i + 1]];
            i += 2;
        }
    }
}

final class EncoderFallbackException : ArgumentException
{
private:
    wchar _charUnknown;
    wchar _charUnknownHigh;
    wchar _charUnknownLow;
    int _index;

    this(wstring message, wchar charUnknown, int index)
    {
        super(message);
        _charUnknown = charUnknown;
        _index = index;
    }

    this(wstring message, wchar charUnknownHigh, wchar charUnknownLow, int index)
    {
        super(message);
        checkRange(charUnknownHigh, 0xd800, 0xdbff, "charUnknownHigh");
        checkRange(charUnknownLow, 0xdc00, 0xdfff, "charUnknownLow");
        _charUnknownHigh = charUnknownHigh;
        _charUnknownLow = charUnknownLow;
        _index = index;
    }

public:
    this()
    {
        super();
    }

    this(wstring message)
    {
        super(message);
    }

    this(wstring message, Throwable next)
    {
        super(message, next);
    }

    @property wchar CharUnknown() const
    {
        return _charUnknown;
    }
        
    @property wchar CharUnknownHigh() const
    {
        return _charUnknownHigh;
    }

    @property wchar CharUnknownLow() const
    {
        return _charUnknownLow;
    }

    @property int Index() const
    {
        return _index;
    }

    bool IsUnknownSurrogate() const
    {
        return _charUnknownHigh != 0;
    }
}

final class DecoderFallbackException : ArgumentException
{
private:
    ubyte[] _bytesUnknown;
    int _index;

public:

    this(wstring message, ubyte[] bytesUnknown, int index)
    {
        super(message);
        _bytesUnknown = bytesUnknown.dup;
        _index = index;
    }

    this()
    {
        super();
    }

    this(wstring message)
    {
        super(message);
    }

    this(wstring message, Throwable next)
    {
        super(message, next);
    }

    @property ubyte[] BytesUnknown()
    {
        return _bytesUnknown;
    }

    @property int Index() const
    {
        return _index;
    }
}

abstract class EncoderFallbackBuffer : SharpObject
{
    abstract bool Fallback(wchar charUnknown, int index);
    abstract bool Fallback(wchar charUnknownHigh, wchar charUnknownLow, int index);
    abstract wchar GetNextChar();
    abstract bool MovePrevious();
    abstract @property int Remaining();
    void Reset() { while (GetNextChar() != 0) { } }
}

abstract class DecoderFallbackBuffer : SharpObject
{
    abstract bool Fallback(ubyte[] bytesUnknown, int index);
    abstract wchar GetNextChar();
    abstract bool MovePrevious();
    abstract @property int Remaining();
    void Reset() { while (GetNextChar() != 0) { } }
}

private final class EncoderBestfitFallbackBuffer : EncoderFallbackBuffer
{
    override bool Fallback(wchar charUnknown, int index) { return false; }
    override bool Fallback (wchar charUnknownHigh, wchar charUnknownLow, int index) { return false; }
    override wchar GetNextChar() { return 0; }
    override bool MovePrevious() {return false; }
    override int Remaining() { return 0; }
}

private final class EncoderBestfitFallback : EncoderFallback
{
    override EncoderFallbackBuffer CreateFallbackBuffer()
    {
        return new EncoderBestfitFallbackBuffer();
    }

    @property override int MaxCharCount()
    {
        return 1;
    }
}

abstract class EncoderFallback: SharpObject
{
private:
    static EncoderFallback _replacement;
    static EncoderFallback _exception;

public:
    abstract EncoderFallbackBuffer CreateFallbackBuffer();
    abstract @property int MaxCharCount();

    @property static EncoderFallback ReplacementFallback()
    {
        if (_replacement is null)
            _replacement = new EncoderReplacementFallback();
        return _replacement;
    }

    @property static EncoderFallback ExceptionFallback()
    {
        if (_exception is null)
            _exception = new EncoderExceptionFallback();
        return _exception;
    }
}

abstract class DecoderFallback: SharpObject
{
private:
    static DecoderFallback _replacement;
    static DecoderFallback _exception;

public:
    abstract DecoderFallbackBuffer CreateFallbackBuffer();
    abstract @property int MaxCharCount();

    @property static DecoderFallback ReplacementFallback()
    {
        if (_replacement is null)
            _replacement = new DecoderReplacementFallback();
        return _replacement;
    }

    @property static DecoderFallback EexceptionFallback()
    {
        if (_exception is null)
            _exception = new DecoderExceptionFallback();
        return _exception;
    }
}

final class EncoderExceptionFallbackBuffer : EncoderFallbackBuffer
{
    override bool Fallback(wchar charUnknown, int index) const
    {
        throw new EncoderFallbackException(null, charUnknown, index);
    }

    override wchar GetNextChar() const
    {
        return 0;
    }

    override bool MovePrevious() const
    {
        return false;
    }

    @property override int Remaining() const
    {
        return 0;
    }

    override bool Fallback(wchar charUnknownHigh, wchar charUnknownLow, int index) const
    {
        if (!Char.IsHighSurrogate(charUnknownHigh))
            throw new ArgumentOutOfRangeException(null, "charUnknownHigh");
        if (!Char.IsLowSurrogate(charUnknownLow))
            throw new ArgumentOutOfRangeException(null, "charUnknownLow");
        throw new EncoderFallbackException(null, charUnknownHigh, charUnknownLow, index);
    }
}

final class DecoderExceptionFallbackBuffer : DecoderFallbackBuffer
{
    override bool Fallback(ubyte[] bytesUnknown, int index)
    {
        throw new DecoderFallbackException(null, bytesUnknown, index);
    }

    override wchar GetNextChar() const
    {
        return 0;
    }

    override bool MovePrevious() const
    {
        return false;
    }

    @property override int Remaining()
    {
        return 0;
    }
}

final class EncoderExceptionFallback : EncoderFallback
{
    override EncoderFallbackBuffer CreateFallbackBuffer()
    {
        return new EncoderExceptionFallbackBuffer();
    }

    @property override int MaxCharCount() const
    {
        return 0;
    }

    override bool opEquals(Object obj) const
    {
        return cast(EncoderExceptionFallback)obj !is null;
    }

    @safe nothrow
    override int GetHashCode()
    {
        return 240120151;
    }
}

final class DecoderExceptionFallback : DecoderFallback
{
    override DecoderFallbackBuffer CreateFallbackBuffer()
    {
        return new DecoderExceptionFallbackBuffer();
    }

    @property override int MaxCharCount()
    {
        return 0;
    }

    override bool Equals(Object obj)
    {
        return cast(DecoderExceptionFallback)obj !is null;
    }

    pure @safe nothrow @nogc
    override int GetHashCode()
    {
        return 240120152;
    }
}

private final class DecoderDropFallback : DecoderFallback
{
    override DecoderFallbackBuffer CreateFallbackBuffer()
    {
        return new DecoderDropFallbackBuffer();
    }

    @property override int MaxCharCount()
    {
        return 0;
    }
}

private final class DecoderDropFallbackBuffer : DecoderFallbackBuffer
{
    override bool Fallback(ubyte[] bytesUnknown, int index)
    {
        return false;
    }

    override wchar GetNextChar() const
    {
        return 0;
    }

    override bool MovePrevious() const
    {
        return false;
    }

    @property override int Remaining()
    {
        return 0;
    }
}

final class EncoderReplacementFallbackBuffer : EncoderFallbackBuffer
{
private:
    EncoderReplacementFallback _fallback;
    wstring _replacement;
    size_t _index = 0;
    bool _fallbackCalled;
public:

    this(EncoderReplacementFallback fallback)
    {
        _fallback = fallback;
        _replacement = fallback.DefaultString();
    }

    override bool Fallback(wchar charUnknown, int index)
    {
        _fallbackCalled = _replacement.length > 0;
        return _fallbackCalled;
    }

    override wchar GetNextChar()
    {
        if (!_fallbackCalled)
            return 0;
        bool noMoreChars = _index >= _replacement.length;
        if (noMoreChars)
        {
            _fallbackCalled = false;
            return 0;
        }
        return _replacement[_index++];  
    }

    override bool MovePrevious()
    {
        if (!_fallbackCalled)
            return false;
        return _index > 0;
    }

    override void Reset()
    {
        _index = 0;
        _fallbackCalled = false;
    }

    @property override int Remaining() const
    {
        if (!_fallbackCalled)
            return 0;
        return _index >= _replacement.length ? 0 : _replacement.length - _index;
    }

    override bool Fallback(wchar charUnknownHigh, wchar charUnknownLow, int index)
    {
        if (!Char.IsHighSurrogate(charUnknownHigh))
            throw new ArgumentOutOfRangeException(null, "charUnknownHigh");
        if (!Char.IsLowSurrogate(charUnknownLow))
            throw new ArgumentOutOfRangeException(null, "charUnknownLow");
        _fallbackCalled = _replacement.length > 0;
        return _fallbackCalled;
    }
}

final class DecoderReplacementFallbackBuffer : DecoderFallbackBuffer
{
private:
    DecoderReplacementFallback _fallback;
    wstring _replacement;
    size_t _index = 0;
    bool _fallbackCalled;

public:

    this(DecoderReplacementFallback fallback)
    {
        _fallback = fallback;
        _replacement = fallback.DefaultString();
    }

    override bool Fallback(ubyte[] bytesUnknown, int index)
    {
        _fallbackCalled = _replacement.length > 0;
        return _fallbackCalled;      
    }

    override wchar GetNextChar()
    {
        if (!_fallbackCalled)
            return 0;
        bool noMoreChars = _index >= _replacement.length;
        if (noMoreChars)
        {
            _fallbackCalled = false;
            return 0;
        }
        return _replacement[_index++];              
    }

    override bool MovePrevious() const
    {
        if (!_fallbackCalled)
            return false;
        return _index > 0;
    }

    override void Reset()
    {
        _index = 0;
        _fallbackCalled = false;
    }

    @property override int Remaining() const
    {
        if (!_fallbackCalled)
            return 0;
        return _index >= _replacement.length ? 0 : _replacement.length - _index;
    }
}

final class EncoderReplacementFallback: EncoderFallback
{
private:
    wstring _replacement;

public:
    this(wstring replacement)
    {
        checkNull(replacement, "replacement");
        if (!isValidUnicode(replacement))
            throw new ArgumentException(null, "replacement");
        _replacement = replacement;
    }

    this()
    {
        this("?");
    }

    override EncoderFallbackBuffer CreateFallbackBuffer()
    {
        return new EncoderReplacementFallbackBuffer(this);
    }

    @property override int MaxCharCount() const
    {
        return _replacement.length;
    }

    override bool Equals(Object obj)
    {
        if (auto erfb = cast(EncoderReplacementFallback)obj)
            return erfb._replacement == this._replacement;
        return false;
    }

    @safe nothrow
    override int GetHashCode() const
    {
        return .GetHashCode(_replacement);
    }

    wstring DefaultString() const
    {
        return _replacement;
    }
}

final class DecoderReplacementFallback: DecoderFallback
{
private:
    wstring _replacement;
public:
    this(wstring replacement)
    {
        checkNull(replacement, "replacement");
        if (!isValidUnicode(replacement))
            throw new ArgumentException(null, "replacement");
        _replacement = replacement;
    }

    this()
    {
        this("?");
    }

    override DecoderFallbackBuffer CreateFallbackBuffer()
    {
        return new DecoderReplacementFallbackBuffer(this);
    }

    @property override int MaxCharCount() const
    {
        return _replacement.length;
    }

    override bool Equals(Object obj)
    {
        if (auto erfb = cast(DecoderReplacementFallback)obj)
            return erfb._replacement == this._replacement;
        return false;
    }

    @safe nothrow
    override int GetHashCode()
    {
        return .GetHashCode(_replacement);
    }

    wstring DefaultString() const
    {
        return _replacement;
    }
}

abstract class Encoder
{
private:
    EncoderFallback _fallback;
    EncoderFallbackBuffer _fallbackBuffer;
protected:
    this() {}
public:
    abstract int GetByteCount(wchar[] chars, int index, int count, bool flush);
    abstract int GetBytes(wchar[] chars, int charIndex, int charCount, ubyte[] bytes, int byteIndex, bool flush);
    
    int GetByteCount(wchar* chars, int count, bool flush)
    {
        checkNull(chars, "chars");
        return GetByteCount(chars[0 .. count], 0, count, flush);
    }

    int GetBytes(wchar* chars, int charCount, ubyte* bytes, size_t byteCount, bool flush)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        ubyte[] xbytes = new ubyte[byteCount];
        size_t ret = GetBytes(chars[0 .. charCount], 0, charCount, xbytes, 0, flush);
        bytes[0 .. ret] = xbytes[0 .. ret];
        return ret;
    }

    void Reset()
    {
        if (FallbackBuffer !is null)
            FallbackBuffer.Reset();
    }

    void Convert(wchar[] chars, int charIndex, int charCount,
                ubyte[] bytes, int byteIndex, int byteCount, bool flush,
                out int charsUsed, out int bytesUsed, out bool completed)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, charIndex, charCount, "charIndex", "charCount");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        charsUsed = charCount;

        while (charsUsed > 0)
        {
            if (GetByteCount(chars, charIndex, charsUsed, flush) <= byteCount)
            {
                bytesUsed = GetBytes(chars, charIndex, charsUsed, bytes, byteIndex, flush);
                completed = (charsUsed == charCount &&
                             (_fallbackBuffer is null || _fallbackBuffer.Remaining == 0));
                return;
            }
            flush = false;
            charsUsed /= 2;
        }
        throw new ArgumentException();
    }

    void Convert(wchar* chars, int charCount,
                ubyte* bytes, int byteCount, bool flush,
                out int charsUsed, out int bytesUsed, out bool completed)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        charsUsed = charCount;

        while (charsUsed > 0)
        {
            if (GetByteCount(chars, charsUsed, flush) <= byteCount)
            {
                bytesUsed = GetBytes(chars, charsUsed, bytes, byteCount, flush);
                completed = (charsUsed == charCount &&
                             (_fallbackBuffer is null || _fallbackBuffer.Remaining == 0));
                return;
            }
            flush = false;
            charsUsed /= 2;
        }
        throw new ArgumentException();
    }

    @property EncoderFallback Fallback()
    {
        return _fallback;
    }

    @property EncoderFallback Fallback(EncoderFallback value)
    {
        checkNull(value);
        if (_fallbackBuffer !is null && _fallbackBuffer.Remaining > 0)
            throw new ArgumentException(null, "value");
        _fallbackBuffer = null;
        return _fallback = value;
    }

    @property EncoderFallbackBuffer FallbackBuffer()
    {
        if (_fallbackBuffer is null)
        {
            if (_fallback !is null)
                _fallbackBuffer = _fallback.CreateFallbackBuffer();
            else
                _fallbackBuffer = EncoderFallback.ReplacementFallback.CreateFallbackBuffer();
        }
        return _fallbackBuffer;
    }
}

private final class DefaultEncoder : Encoder
{
private:
    Encoding _encoding;
    wchar lastChar;
    bool leftOver;
public:
    this(Encoding encoding)
    {
        _encoding = encoding;
    }

    override int GetByteCount(wchar[] chars, int index, int count, bool flush)
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);
        wchar[] buffer;
        if (leftOver)
        {
            buffer = new wchar[count + 1];
            buffer[0] = lastChar;
            buffer[1 .. $] = chars[0 .. count];
        }
        else
            buffer = chars[index .. index + count];

        if (Char.IsHighSurrogate(buffer[$ - 1]))
            count--;

        return _encoding.GetByteCount(buffer, 0, count);
    }

    override int GetBytes(wchar[] chars, int charIndex, int charCount, ubyte[] bytes, int byteIndex, bool flush)
    {
        checkNull(chars, "chars");
        checkIndex(chars, charIndex, charCount, "charIndex", "charCount");
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, "byteIndex");

        wchar[] buffer;
        if (leftOver)
        {
            buffer = new wchar[charCount + 1];
            buffer[0] = lastChar;
            buffer[1 .. $] = chars[0 .. charCount];
            leftOver = false;
        }
        else
            buffer = chars[charIndex .. charIndex + charCount];

        if (!flush && Char.IsHighSurrogate(buffer[$ - 1]))
        {
            lastChar = buffer[$ - 1];
            leftOver = true;
            charCount--;
        }
        return _encoding.GetBytes(buffer, 0, charCount, bytes, byteIndex);
    }

    override public void Reset() 
    {
        super.Reset();
        leftOver = false;
    }
    
}

abstract class Decoder
{
private:
    DecoderFallback _fallback;
    DecoderFallbackBuffer _fallbackBuffer;

protected:
    this() {}

public:
    abstract int GetCharCount(ubyte[] bytes, int index, int count, bool flush);
    abstract int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush);

    int GetCharCount(ubyte* bytes, int count, bool flush)
    {
        checkNull(bytes, "bytes");
        return GetCharCount(bytes[0 .. count], 0, count, flush);
    }

    int GetChars(ubyte* bytes, int byteCount, wchar* chars, int charCount, bool flush)
    {
        checkNull(bytes, "bytes");
        checkNull(chars, "chars");
        wchar[] xchars = new wchar[charCount];
        int ret = GetChars(bytes[0 .. byteCount], 0, byteCount, xchars, 0, flush);
        chars[0 .. ret] = xchars[0 .. ret];
        return ret;
    }

    void Reset()
    {
        if (FallbackBuffer !is null)
            FallbackBuffer.Reset();
    }

    void Convert(ubyte[] bytes, int byteIndex, int byteCount,
                wchar[] chars, int charIndex, int charCount, bool flush,
                out int bytesUsed, out int charsUsed, out bool completed)
    {
        checkNull(bytes, "bytes");
        checkNull(chars, "chars");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        checkIndex(chars, charIndex, charCount, "charIndex", "charCount");
        bytesUsed = byteCount;

        while (bytesUsed > 0)
        {
            if (GetCharCount(bytes, byteIndex, bytesUsed, flush) <= charCount)
            {
                charsUsed = GetChars(bytes, byteIndex, bytesUsed, chars, charIndex, flush);
                completed = (bytesUsed == byteCount &&
                             (_fallbackBuffer is null || _fallbackBuffer.Remaining == 0));
                return;
            }
            flush = false;
            bytesUsed /= 2;
        }
        throw new ArgumentException();
    }

    void Convert(ubyte* bytes, int byteCount,
                wchar* chars, int charCount, bool flush,
                out int bytesUsed, out int charsUsed, out bool completed)
    {
        checkNull(bytes, "bytes");
        checkNull(chars, "chars");
        bytesUsed = byteCount;

        while (bytesUsed > 0)
        {
            if (GetCharCount(bytes, bytesUsed, flush) <= charCount)
            {
                charsUsed = GetChars(bytes, bytesUsed, chars, charCount, flush);
                completed = (bytesUsed == byteCount &&
                             (_fallbackBuffer is null || _fallbackBuffer.Remaining == 0));
                return;
            }
            flush = false;
            bytesUsed /= 2;
        }
        throw new ArgumentException();
    }

    @property DecoderFallback Fallback()
    {
        return _fallback;
    }

    @property DecoderFallback Fallback(DecoderFallback value)
    {
        checkNull(value);
        if (_fallbackBuffer !is null && _fallbackBuffer.Remaining > 0)
            throw new ArgumentException(null, "value");
        _fallbackBuffer = null;
        return _fallback = value;
    }

    @property DecoderFallbackBuffer FallbackBuffer()
    {
        if (_fallbackBuffer is null)
        {
            if (_fallback !is null)
                _fallbackBuffer = _fallback.CreateFallbackBuffer();
            else
                _fallbackBuffer = DecoderFallback.ReplacementFallback.CreateFallbackBuffer();
        }
        return _fallbackBuffer;
    }
}

private final class DefaultDecoder: Decoder
{
private:
    Encoding _encoding;
    
public:

    this(Encoding encoding)
    {
        _encoding = encoding;
        
    }

    override int GetCharCount(ubyte[] bytes, int index, int count, bool flush)
    {
        
        return _encoding.GetCharCount(bytes, index, count);
    }

    override int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush)
    {        
        return _encoding.GetChars(bytes, byteIndex, byteCount, chars, charIndex);
    }
}

class UnicodeEncoding: Encoding 
{
private:
    bool _bigEndian;
    bool _byteOrderMark;

public:
    this(bool bigEndian, bool byteOrderMark, bool throwOnErrors)
    {
        super(_bigEndian ? 1200: 1201);
        _bigEndian = _bigEndian;
        _byteOrderMark = byteOrderMark;
        EncoderFallback = throwOnErrors ? new EncoderExceptionFallback() : new EncoderReplacementFallback("\ufffd");
        DecoderFallback = throwOnErrors ? new DecoderExceptionFallback() : new DecoderReplacementFallback("\ufffd");
    }

    this(bool bigEndian, bool byteOrderMark)
    {
        this(bigEndian, byteOrderMark, false);
    }

    this()
    {
        this(false, true, false);
    }

    override ubyte[] GetPreamble()
    {
        if (!_byteOrderMark)
            return [];
        return _bigEndian ? [cast(ubyte)0xfe, cast(ubyte)0xff] : [cast(ubyte)0xff, cast(ubyte)0xfe] ;
    }

    override bool Equals(Object other)
    {
        UnicodeEncoding enc = cast(UnicodeEncoding)other;
        if (enc !is null)
        {
            return this._byteOrderMark == enc._byteOrderMark &&
                   this._bigEndian == enc._bigEndian &&
                   this.EncoderFallback.Equals(enc.EncoderFallback) &&
                   this.DecoderFallback.Equals(enc.DecoderFallback);
        }
        return false;
    }

    override int GetHashCode() @trusted nothrow
    {
        return EncoderFallback.GetHashCode() + DecoderFallback.GetHashCode() + cast(size_t)_bigEndian +
            cast(size_t)(_byteOrderMark) * 2 + 1200;
    }

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, index, count, "chars");
        checkIndex(bytes, byteIndex);

        int len = index + count;
        int ret;
        while (index < count)
        {
            int cpLen = stride(chars, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    if (byteIndex + fbchars.length * 2 >= bytes.length)
                        throw new ArgumentOutOfRangeException("bytes");                   
                    for (int i = 0; i < fbchars.length; i++)
                    {
                        bytes[byteIndex++] = _bigEndian ? cast(ubyte)(fbchars[i] >>> 8) : cast(ubyte)(fbchars[i]);
                        bytes[byteIndex++] = _bigEndian ? cast(ubyte)(fbchars[i]) : cast(ubyte)(fbchars[i] >>> 8);
                    }
                    ret += fbchars.length * 2;
                }
                cpLen = 1;   
            }
            else
            {
                auto bits = chars[index .. index + cpLen];
                if (byteIndex + bits.length * 2 >= bytes.length)
                    throw new ArgumentOutOfRangeException("bytes");
                for (int i = 0; i < bits.length; i++)
                {
                    bytes[byteIndex++] = !_bigEndian ? cast(ubyte)(bits[i]) : cast(ubyte)(bits[i] >>> 8);
                    bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[i]) : cast(ubyte)(bits[i] >>> 8);
                }
                ret += bits.length * 2;
            }

            index += cpLen;
        }   
        return ret;
    }

    override int GetByteCount(wchar[] chars, int index, int count)
    {
        checkIndex(chars, index, count, "chars");

        int len = index + count;
        int ret;
        while (index < count)
        {
            int cpLen = stride(chars, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    ret += fbchars.length * 2;
                }
                cpLen = 1;   
            }
            else
            {
                ret += cpLen * 2;
            }

            index += cpLen;
        }   
        return ret;
    }

    private union U16
    {
        ubyte[2] b;
        wchar w;
    }


    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, charIndex);
        checkIndex(bytes, index, count);

        int len = index + count;
        int ret;
        while (index < len)
        {
            U16 u;
            if (index == len - 1)
                goto fail;            
            u.b[0] = _bigEndian ? bytes[index] : bytes[index + 1];
            u.b[1] = !_bigEndian ? bytes[index] : bytes[index + 1];
            if (u.w < 0xd800 || u.w > 0xdbff)
            {
                if (charIndex + 1 >= chars.length)
                    throw new ArgumentOutOfRangeException("chars");
                chars[charIndex++] = u.w;
                index += 2;
                ret++;
                continue;
            }
            else
            {
                index += 2;
                U16 v;
                if (index < len - 2)
                {
                    v.b[0] = _bigEndian ? bytes[index] : bytes[index + 1];
                    v.b[1] = !_bigEndian ? bytes[index] : bytes[index + 1];
                    if (v.w >= 0xdc00 && v.w <= 0xdfff)
                    {
                        dchar d = cast(dchar)((u.w << 10) + v.w) - 0x35FD00;
                        if (d < 0x10ffff)
                        {
                            if (charIndex + 2 >= chars.length)
                                throw new ArgumentOutOfRangeException("chars");
                            chars[charIndex++] = u.w;
                            chars[charIndex++] = v.w;
                            index += 2;
                            ret += 2;
                            continue;
                        }
                    }
                }
                index -= 2;
            }
        fail:
            wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
            if (fbchars.length > 0)
            {
                if (!isValidUnicode(fbchars))
                    throw new ArgumentException("fallback");   
                checkIndex(chars, charIndex);
                chars[charIndex .. charIndex + fbchars.length] = fbchars;
                charIndex += fbchars.length;
                ret += fbchars.length;
            }
            index += 2;
        }   
        return ret;      
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        checkIndex(bytes, index, count, "bytes");

        int len = index + count;
        int ret;
        while (index < len)
        {
            U16 u;
            if (index == count - 1)
                goto fail;            
            u.b[0] = _bigEndian ? bytes[index] : bytes[index + 1];
            u.b[1] = !_bigEndian ? bytes[index] : bytes[index + 1];
            if (u.w < 0xd800 || u.w > 0xdbff)
            {
                index += 2;
                ret++;
                continue;
            }
            else
            {
                index += 2;
                U16 v;
                if (index < len - 2)
                {
                    v.b[0] = _bigEndian ? bytes[index] : bytes[index + 1];
                    v.b[1] = !_bigEndian ? bytes[index] : bytes[index + 1];
                    if (v.w >= 0xdc00 && v.w <= 0xdfff)
                    {
                        dchar d = cast(dchar)((u.w << 10) + v.w) - 0x35FD00;
                        if (d < 0x10ffff)
                        {                    
                            index += 2;
                            ret += 2;
                            continue;
                        }
                    }
                }
                index -= 2;
            }
        fail:
            wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
            if (fbchars.length > 0)
            {
                if (!isValidUnicode(fbchars))
                    throw new ArgumentException("fallback");                   
                ret += fbchars.length;
            }
            index += 2;
        }   
        return ret;     
    }

    override int GetMaxByteCount(int charCount)
    {
        auto errorCount = EncoderFallback.MaxCharCount * 2;
        return charCount * (errorCount <= 2 ? 2 : errorCount);    
    }

    override int GetMaxCharCount(int byteCount)
    {
        auto errorCount = DecoderFallback.MaxCharCount;
        return byteCount * (errorCount <= 1 ? 1 : errorCount);       
    }

    override Decoder GetDecoder() 
    {
        return new UnicodeDecoder(this);
    }
    
}

class UTF32Encoding : Encoding
{
private:
    bool _bigEndian;
    bool _byteOrderMark;

public:
    this(bool bigEndian, bool byteOrderMark, bool throwOnErrors)
    {
        super(_bigEndian ? 12000: 12001);
        _bigEndian = _bigEndian;
        _byteOrderMark = byteOrderMark;
        EncoderFallback = throwOnErrors ? new EncoderExceptionFallback() : new EncoderReplacementFallback("\ufffd");
        DecoderFallback = throwOnErrors ? new DecoderExceptionFallback() : new DecoderReplacementFallback("\ufffd");
    }

    this(bool bigEndian, bool byteOrderMark)
    {
        this(bigEndian, byteOrderMark, false);
    }

    this()
    {
        this(false, true, false);
    }

    override ubyte[] GetPreamble()
    {
        if (!_byteOrderMark)
            return [];
        return _bigEndian ? [cast(ubyte)0, cast(ubyte)0, cast(ubyte)0xfe, cast(ubyte)0xff] : 
                            [cast(ubyte)0xff, cast(ubyte)0xfe, cast(ubyte)0, cast(ubyte)0] ;
    }

    override bool Equals(Object other)
    {
        UTF32Encoding enc = cast(UTF32Encoding)other;
        if (enc !is null)
        {
            return this._byteOrderMark == enc._byteOrderMark &&
                   this._bigEndian == enc._bigEndian &&
                   this.EncoderFallback.Equals(enc.EncoderFallback) &&
                   this.DecoderFallback.Equals(enc.DecoderFallback);
        }
        return false;
    }

    @trusted nothrow
    override int GetHashCode() 
    {
        return EncoderFallback.GetHashCode() + 
               DecoderFallback.GetHashCode() + 
                cast(int)_bigEndian +
                cast(int)(_byteOrderMark) * 2 + 12000;
    }

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, index, count, "chars");
        checkIndex(bytes, byteIndex, "byteIndex");
      
        int len = index + count;
        int ret;
        while (index < count)
        {
            int cpLen = stride(chars, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    auto bits = toUTF32(fbchars);
                    checkIndex(bytes, byteIndex + bits.length * 4, "bytes");             
                    for (int i = 0; i < bits.length; i++)
                    {
                        bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[i] >>> 24) :  cast(ubyte)(bits[i]);
                        bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[i] >>> 16) : cast(ubyte)(bits[i] >>> 8);
                        bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[i] >>> 8) : cast(ubyte)(bits[i] >>> 16);
                        bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[i]) : cast(ubyte)(bits[i] >>> 24);
                    }
                    ret += bits.length * 4;
                }
                cpLen = 1;   
            }
            else
            {
                auto bits = toUTF32(chars[index .. index + cpLen]);
                checkIndex(bytes, byteIndex + 4, "bytes");
                bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[0] >>> 24) :  cast(ubyte)(bits[0]);
                bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[0] >>> 16) : cast(ubyte)(bits[0] >>> 8);
                bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[0] >>> 8) : cast(ubyte)(bits[0] >>> 16);
                bytes[byteIndex++] = _bigEndian ? cast(ubyte)(bits[0]) : cast(ubyte)(bits[0] >>> 24);
                ret += 4;
            }

            index += cpLen;
        }   
        return ret;
    }

    override int GetByteCount(wchar[] chars, int index, int count)
    {
        checkIndex(chars, index, count);
        int len = index + count;
        int ret;
        while (index < count)
        {
            int cpLen = stride(chars, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    auto bits = toUTF32(fbchars);
                    ret += bits.length * 4;
                }
                cpLen = 1;   
            }
            else      
                ret += 4;
            index += cpLen;
        }   
        return ret;
    }

    union U32
    {
        ubyte[4] b;
        dchar d;
    }

    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(bytes, index, count, "bytes");

        int len = index + count;
        int ret;
        while (index < len)
        {
            U32 u;
            if (index >= len - 3)
                goto fail;            
            u.b[0] = _bigEndian ? bytes[index] : bytes[index + 3];
            u.b[1] = _bigEndian ? bytes[index + 1] : bytes[index + 2];
            u.b[2] = _bigEndian ? bytes[index + 2] : bytes[index + 1];
            u.b[3] = _bigEndian ? bytes[index + 3] : bytes[index];
            if (u.d < 0x10ffff)
            {
                auto bits = toUTF16([u.d]);
                checkIndex(chars, charIndex + bits.length, "chars");
                chars[charIndex .. charIndex + bits.length] = bits;
                index += 4;
                ret += bits.length;
                charIndex += bits.length;
                continue;
            }

        fail:
            wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
            if (fbchars.length > 0)
            {
                if (!isValidUnicode(fbchars))
                    throw new ArgumentException("fallback");     
                checkIndex(chars, charIndex + fbchars.length, "chars");
                chars[charIndex .. charIndex + fbchars.length] = fbchars;
                charIndex += fbchars.length;
                ret += fbchars.length;
            }
            index += 4;
        }   
        return ret;      
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        checkNull(bytes, "bytes");
        checkIndex(bytes, index, count, "bytes");

        int len = index + count;
        int ret;
        while (index < len)
        {
            U32 u;
            if (index >= len - 3)
                goto fail;            
            u.b[0] = _bigEndian ? bytes[index] : bytes[index + 3];
            u.b[1] = _bigEndian ? bytes[index + 1] : bytes[index + 2];
            u.b[2] = _bigEndian ? bytes[index + 2] : bytes[index + 1];
            u.b[3] = _bigEndian ? bytes[index + 3] : bytes[index];
            if (u.d < 0x10ffff)
            {
                auto bits = toUTF16([u.d]);
                index += 4;
                ret += bits.length;
                continue;
            }

        fail:
            wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
            if (fbchars.length > 0)
            {
                if (!isValidUnicode(fbchars))
                    throw new ArgumentException("fallback");                   
                ret += fbchars.length;
            }
            index += 4;
        }   
        return ret;      
    }

    override int GetMaxByteCount(int charCount)
    {
        auto errorCount = EncoderFallback.MaxCharCount * 4;
        return charCount * (errorCount <= 4 ? 4 : errorCount);    
    }

    override int GetMaxCharCount(int byteCount)
    {
        auto errorCount = DecoderFallback.MaxCharCount;
        return byteCount / 4 * (errorCount <= 1 ? 1 : errorCount);       
    }

    override Decoder GetDecoder() 
    {
        return new UTF32Decoder(this);
    }
}

class UTF8Encoding : Encoding
{
private:
    bool _encoderShouldEmitUTF8Identifier;
public:
    this(bool encoderShouldEmitUTF8Identifier, bool throwOnErrors)
    {
        super(65001);
        _encoderShouldEmitUTF8Identifier = encoderShouldEmitUTF8Identifier;
        EncoderFallback = throwOnErrors ? new EncoderExceptionFallback() : new EncoderReplacementFallback("\ufffd");
        DecoderFallback = throwOnErrors ? new DecoderExceptionFallback() : new DecoderReplacementFallback("\ufffd");
    }

    this(bool encoderShouldEmitUTF8Identifier)
    {
        this(encoderShouldEmitUTF8Identifier, false);
    }

    this()
    {
        this(false, false);
    }

    override ubyte[] GetPreamble()
    {
        return _encoderShouldEmitUTF8Identifier ? [cast(ubyte)0xEF, cast(ubyte)0xBB, cast(ubyte)0xBF] : [];
    }

    override bool Equals(Object other)
    {
        if (auto enc = cast(UTF8Encoding)other)
        {
            return this._encoderShouldEmitUTF8Identifier == enc._encoderShouldEmitUTF8Identifier &&
                    this.EncoderFallback.Equals(enc.EncoderFallback) &&
                    this.DecoderFallback.Equals(enc.DecoderFallback);
        }
        return false;
    }

    override int GetHashCode() @safe nothrow
    {
        return EncoderFallback.GetHashCode() + 
               DecoderFallback.GetHashCode() + 
               cast(int)_encoderShouldEmitUTF8Identifier +
               65001;
    }

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, index, count);
        checkIndex(bytes, byteIndex, "byteIndex");
        
        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(chars, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    auto bits = toUTF8(fbchars);
                    checkIndex(bytes, byteIndex + bits.length, "bytes");
                    bytes[byteIndex .. byteIndex + bits.length] = cast(ubyte[])bits;
                    byteIndex += bits.length;
                    ret += bits.length;
                }
                cpLen = 1;   
            }
            else
            {
                auto bits = toUTF8(chars[index .. index + cpLen]);
                checkIndex(bytes, byteIndex + bits.length, "bytes");
                bytes[byteIndex .. byteIndex + bits.length] = cast(ubyte[])bits;
                byteIndex += bits.length;
                ret += bits.length;
            }

            index += cpLen;
        }   
        return ret;
    }

    override int GetByteCount(wchar[] chars, int index, int count)
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);

        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(chars, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    auto bits = toUTF8(fbchars);
                    ret += bits.length;
                }
                cpLen = 1;   
            }
            else
            {
                auto bits = toUTF8(chars[index .. index + cpLen]);
                ret += bits.length;
            }

            index += cpLen;
        }   
        return ret;
    }

    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        checkNull(chars);
        checkNull(bytes);
        checkIndex(bytes, index, count);
        checkIndex(chars, charIndex, "charIndex");
        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(cast(char[])bytes, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");    
                    checkIndex(chars, charIndex + fbchars.length, "chars");
                    chars[charIndex .. charIndex + fbchars.length] = fbchars;
                    charIndex += fbchars.length;
                    ret += fbchars.length;
                }
                cpLen = 1;   
            }
            else
            {
                auto bits = toUTF16(cast(char[])bytes[index .. index + cpLen]);
                checkIndex(chars, charIndex + bits.length, "chars");
                chars[charIndex .. charIndex + bits.length] = bits;
                charIndex += bits.length;
                ret += bits.length;
            }

            index += cpLen;
        }   
        return ret;      
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        checkNull(bytes);
        checkIndex(bytes, index, count);

        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(cast(char[])bytes, index);
            if (cpLen == 0)
            {
                wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");                   
                    ret += fbchars.length;
                }
                cpLen = 1;   
            }
            else
            {
                auto bits = toUTF16(cast(char[])bytes[index .. index + cpLen]);
                ret += bits.length;
            }

            index += cpLen;
        }   
        return ret;      
    }

    override int GetMaxByteCount(int charCount)
    {
        auto errorCount = EncoderFallback.MaxCharCount;
        return charCount * (errorCount <= 3 ? 3 : errorCount);    
    }

    override int GetMaxCharCount(int byteCount)
    {
        auto errorCount = DecoderFallback.MaxCharCount;
        return byteCount * (errorCount <= 1 ? 1 : errorCount);       
    }

    override Decoder GetDecoder() 
    {
        return new UTF8Decoder(this);
    }
}

class ASCIIEncoding : Encoding
{
    this()
    {
        super(20127);
        EncoderFallback = new EncoderReplacementFallback("?");
        DecoderFallback = new DecoderReplacementFallback("?");
    }

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, index, count);
        checkIndex(bytes, byteIndex, "byteIndex");

        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(chars, index);
            if (cpLen != 1 || (cpLen == 1 && chars[index] >= 0x80))
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidAscii(fbchars))
                        throw new ArgumentException("fallback");       
                    checkIndex(bytes, byteIndex + fbchars.length, "bytes");
                    foreach(c; fbchars)
                        bytes[byteIndex++] = cast(ubyte)c;
                    ret += fbchars.length;
                }
                if (cpLen == 0) cpLen = 1;
            }
            else
            {
                checkIndex(bytes, byteIndex + 1, "bytes");
                bytes[byteIndex++] = cast(ubyte)chars[index];
                ret++;
            }
            index += cpLen;
        }   
        return ret;
    }

    override int GetByteCount(wchar[] chars, int index, int count)
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);

        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(chars, index);
            if (cpLen != 1 || (cpLen == 1 && chars[index] >= 0x80))
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidAscii(fbchars))
                        throw new ArgumentException("fallback");       
                    ret += fbchars.length;
                }
                if (cpLen == 0) cpLen = 1;
            }
            else
                ret++;
            index += cpLen;
        }   
        return ret;
    }

    

    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        checkNull(chars);
        checkNull(bytes);
        checkIndex(bytes, index, count);
        checkIndex(chars, charIndex, "charIndex");
        int len = index + count;
        int ret;
        while (index < len)
        {
            if (bytes[index] >= 0x80)
            {
                wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");    
                    checkIndex(chars, charIndex + fbchars.length, "chars");
                    chars[charIndex .. charIndex + fbchars.length] = fbchars;
                    charIndex += fbchars.length;
                    ret += fbchars.length;
                }  
            }
            else
            {
                checkIndex(chars, charIndex + 1, "chars");
                chars[charIndex++] = bytes[index];
                ret++;
            }
            index++;
        }   
        return ret;      
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        checkNull(bytes);
        checkIndex(bytes, index, count);
        int len = index + count;
        int ret;
        while (index < len)
        {
            if (bytes[index] >= 0x80)
            {
                wchar[] fbchars = getDecoderFallbackChars(bytes[index .. index + 1], index);
                if (fbchars.length > 0)
                {
                    if (!isValidUnicode(fbchars))
                        throw new ArgumentException("fallback");    
                    ret += fbchars.length;
                }  
            }
            else
                ret++;
            index++;
        }   
        return ret;      
    }

    override int GetMaxByteCount(int charCount)
    {
        auto errorCount = EncoderFallback.MaxCharCount;
        return charCount * (errorCount <= 1 ? 1 : errorCount);    
    }

    override int GetMaxCharCount(int byteCount)
    {
        auto errorCount = DecoderFallback.MaxCharCount;
        return byteCount * (errorCount <= 1 ? 1 : errorCount);       
    }
}

private class Latin1Encoding : Encoding
{
    this()
    {
        super(28591);
        EncoderFallback = new EncoderReplacementFallback("?");
        DecoderFallback = new DecoderReplacementFallback("?");
    }

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, index, count);
        checkIndex(bytes, byteIndex, "byteIndex");

        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(chars, index);
            if (cpLen != 1 || (cpLen == 1 && chars[index] > 0xff))
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidLatin1(fbchars))
                        throw new ArgumentException("fallback");       
                    checkIndex(bytes, byteIndex + fbchars.length, "bytes");
                    foreach(c; fbchars)
                        bytes[byteIndex++] = cast(ubyte)c;
                    ret += fbchars.length;
                }
                if (cpLen == 0) cpLen = 1;
            }
            else
            {
                checkIndex(bytes, byteIndex + 1, "bytes");
                bytes[byteIndex++] = cast(ubyte)chars[index];
                ret++;
            }
            index += cpLen;
        }   
        return ret;
    }

    override int GetByteCount(wchar[] chars, int index, int count)
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);

        int len = index + count;
        int ret;
        while (index < len)
        {
            int cpLen = stride(chars, index);
            if (cpLen != 1 || (cpLen == 1 && chars[index] > 0xff))
            {
                wchar[] fbchars = getEncoderFallbackChars(chars[index], index);
                if (fbchars.length > 0)
                {
                    if (!isValidLatin1(fbchars))
                        throw new ArgumentException("fallback");       
                    ret += fbchars.length;
                }
                if (cpLen == 0) cpLen = 1;
            }
            else
                ret++;
            index += cpLen;
        }   
        return ret;
    }

    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        checkNull(chars);
        checkNull(bytes);
        checkIndex(bytes, index, count);
        checkIndex(chars, charIndex, count, "charIndex");
       
        foreach(b; bytes)
            chars[charIndex++] = b;
        return count;      
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        checkNull(bytes);
        checkIndex(bytes, index, count);
        return count;      
    }

    override int GetMaxByteCount(int charCount)
    {
        auto errorCount = EncoderFallback.MaxCharCount;
        return charCount * (errorCount <= 1 ? 1 : errorCount);    
    }

    override int GetMaxCharCount(int byteCount)
    {
        auto errorCount = DecoderFallback.MaxCharCount;
        return byteCount * (errorCount <= 1 ? 1 : errorCount);       
    }
}

private class CodePageEncoding : Encoding
{
    bool hasZeroFlags()
    {
        return  _codePage == 42 ||
               (_codePage >= 50220 && _codePage <= 50222) ||
                _codePage == 50225 ||
                _codePage == 50227 ||
                _codePage == 50229 ||
               (_codePage >= 57002 && _codePage <= 57011) ||
                _codePage == 65000;      
    }

    bool allowsOnlyError()
    {
        return (_codePage == 65001 || _codePage == 54936 || _codePage == 52936) && isWindowsVistaOrGreater();
    }

    this(int codePage)
    {
        super(codePage);
        EncoderFallback = new EncoderBestfitFallback();
        DecoderFallback = new DecoderDropFallback();
        
    }

    alias EncoderFallback = Encoding.EncoderFallback;
    alias DecoderFallback = Encoding.DecoderFallback;

    override @property .EncoderFallback EncoderFallback(.EncoderFallback value)
    {
        if (cast(EncoderExceptionFallback)value || cast(EncoderBestfitFallback)value) 
            return super.EncoderFallback(value);
        if (auto repl = cast(EncoderReplacementFallback)value)
        {
            if (repl.DefaultString().length != 1 || repl.DefaultString()[0] > 0xff)
                throw new NotSupportedException(SharpResources.GetString("ArgumentFallbackNotSupported"));

            return super.EncoderFallback(value);
        }
        throw new NotSupportedException(SharpResources.GetString("ArgumentFallbackNotSupported"));
    }

    override @property .DecoderFallback DecoderFallback(.DecoderFallback value)
    {
        if (cast(DecoderExceptionFallback)value || cast(DecoderDropFallback)value) 
            return super.DecoderFallback(value);
        throw new NotSupportedException(SharpResources.GetString("ArgumentFallbackNotSupported"));
    }
    

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex) 
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);
        checkIndex(bytes, byteIndex, "byteIndex");
        
        bool hasExceptionFallback = cast(EncoderExceptionFallback)(this.EncoderFallback) !is null;
        bool hasReplacementFallback = cast(EncoderReplacementFallback)EncoderFallback !is null;
        bool hasBestfitFallback = cast(EncoderBestfitFallback)EncoderFallback !is null;

        uint encodingFlags;

        
        char* lpRepl;

        if (hasExceptionFallback)
            encodingFlags = hasZeroFlags() || !isWindowsVistaOrGreater() ? 0 : WC_ERR_INVALID_CHARS; 
        else if (hasReplacementFallback)
            encodingFlags = hasZeroFlags() || allowsOnlyError() ? 0 : WC_NO_BEST_FIT_CHARS;
        if (!hasZeroFlags() && !allowsOnlyError())
            encodingFlags |= WC_COMPOSITECHECK;

        if (hasReplacementFallback)
        {
            char repl =  cast(char)((cast(EncoderReplacementFallback)EncoderFallback).DefaultString()[0]);
            lpRepl = _codePage == CP_UTF7 || _codePage == CP_UTF8 ? null : &repl;
            
        }

        auto ws = chars[index .. index + count];

        int ret = WideCharToMultiByte(_codePage, encodingFlags, ws.ptr, ws.length, null, 0, lpRepl, null);
        if (ret == 0)
        {
            auto lastErr = Marshal.GetLastWin32Error();
            if (lastErr == 0x459 && hasExceptionFallback)
                throw new EncoderFallbackException(null, cast(wchar)'\0', 0);
            Marshal.ThrowExceptionForHR(lastErr);
        }

        checkIndex(bytes, index, ret, "bytes", "bytes");
        ret = WideCharToMultiByte(_codePage, encodingFlags, ws.ptr, ws.length, cast(char*)bytes.ptr + index, bytes.length - byteIndex, lpRepl, null);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetLastWin32Error());
        return ret;

    }
    

    override int GetByteCount(wchar[] chars, int index, int count) 
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);

        bool hasExceptionFallback = cast(EncoderExceptionFallback)EncoderFallback !is null;
        bool hasReplacementFallback = cast(EncoderReplacementFallback)EncoderFallback !is null;
        bool hasBestfitFallback = cast(EncoderBestfitFallback)EncoderFallback !is null;

        uint encodingFlags;

        char* lpRepl;

        if (hasExceptionFallback)
            encodingFlags = hasZeroFlags() || !isWindowsVistaOrGreater() ? 0 : WC_ERR_INVALID_CHARS; 
        else if (hasReplacementFallback)
            encodingFlags = hasZeroFlags() || allowsOnlyError() ? 0 : WC_NO_BEST_FIT_CHARS;
        if (!hasZeroFlags() && !allowsOnlyError())
            encodingFlags |= WC_COMPOSITECHECK;

        if (hasReplacementFallback)
        {
            char repl =  cast(char)((cast(EncoderReplacementFallback)EncoderFallback).DefaultString()[0]);
            lpRepl = _codePage == CP_UTF7 || _codePage == CP_UTF8 ? null : &repl;

        }

        auto ws = chars[index .. index + count];

        int ret = WideCharToMultiByte(_codePage, encodingFlags, ws.ptr, ws.length, null, 0, lpRepl, null);
        if (ret == 0)
        {
            auto lastErr = Marshal.GetLastWin32Error();
            if (lastErr == 0x459 && hasExceptionFallback)
                throw new EncoderFallbackException(null, cast(wchar)'\0', 0);
            Marshal.ThrowExceptionForHR(lastErr);
        }
        return ret;
    }


    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        checkNull(chars);
        checkNull(bytes);
        checkIndex(bytes, index, count);
        checkIndex(chars, charIndex, "charIndex");

        bool hasExceptionFallback = cast(DecoderExceptionFallback)(this.DecoderFallback) !is null;
        bool hasDropFallback = cast(DecoderDropFallback)DecoderFallback !is null;
        
        uint encodingFlags;

        if (hasExceptionFallback)
            encodingFlags = hasZeroFlags() ? 0 : MB_ERR_INVALID_CHARS; 

        auto bits = bytes[index .. index + count];
        int ret = MultiByteToWideChar(_codePage, encodingFlags, cast(char*)bits, bits.length, null, 0);
        if (ret == 0)
        {
            auto lastErr = Marshal.GetLastWin32Error();
            if (lastErr == 0x459 && hasExceptionFallback)
                throw new DecoderFallbackException(null, null, 0);
            Marshal.ThrowExceptionForHR(lastErr);
        }
        checkIndex(chars, charIndex, ret, "chars", "chars");
        ret = MultiByteToWideChar(_codePage, encodingFlags, cast(char*)bits, bits.length, chars.ptr + charIndex, chars.length - charIndex);
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return ret;
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        checkNull(bytes);
        checkIndex(bytes, index, count);

        bool hasExceptionFallback = cast(DecoderExceptionFallback)(this.DecoderFallback) !is null;
        bool hasDropFallback = cast(DecoderDropFallback)DecoderFallback !is null;

        uint encodingFlags;

        if (hasExceptionFallback)
            encodingFlags = hasZeroFlags() ? 0 : MB_ERR_INVALID_CHARS; 

        auto bits = bytes[index .. index + count];
        int ret = MultiByteToWideChar(_codePage, encodingFlags, cast(char*)bits, bits.length, null, 0);
        if (ret == 0)
        {
            auto lastErr = Marshal.GetLastWin32Error();
            if (lastErr == 0x459 && hasExceptionFallback)
                throw new DecoderFallbackException(null, null, 0);
            Marshal.ThrowExceptionForHR(lastErr);
        }
        if (ret == 0)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        return ret;
    }

    override int GetMaxByteCount(int charCount)
    {
        return charCount * 3 + 2;
    }

    override int GetMaxCharCount(int byteCount)
    {
        return byteCount <= 1 ? 1: byteCount;    
    }
        
}

class UTF7Encoding: Encoding
{
private:
    bool allowOptionals;
public:
    this(bool allowOptionals)
    {
        super(65000);
    }

    override int GetMaxByteCount(int charCount)
    {
        auto errorCount = EncoderFallback.MaxCharCount;
        return (charCount * (errorCount <= 1 ? 1 : errorCount)) * 3 + 2;    
    }

    override int GetMaxCharCount(int byteCount)
    {
        auto errorCount = DecoderFallback.MaxCharCount;
        return byteCount * (errorCount <= 1 ? 1 : errorCount);       
    }

    override int GetBytes(wchar[] chars, int index, int count, ubyte[] bytes, int byteIndex)
    {
        checkNull(chars, "chars");
        checkNull(bytes, "bytes");
        checkIndex(chars, index, count);
        checkIndex(bytes, byteIndex, "byteIndex");

        auto isPrintable = allowOptionals ? isutf7o : isutf7d;

        int len = index + count;
        int ret;
        while (index < len)
        {
            bool emitEnd = false;
            while (index < len && chars[index] < 0x80 && isPrintable[chars[index]])
            {
                checkIndex(bytes, byteIndex, "bytes");
                bytes[byteIndex++] = cast(ubyte)chars[index++];
                ret++;
            }
            while (index < len && chars[index] == '+')
            {
                checkIndex(bytes, byteIndex + 1, "bytes");
                bytes[byteIndex++] = '+';
                bytes[byteIndex++] = '-';
                index++;
                ret += 2;
            }
            if (index < len && (chars[index] >= 0x80 || !isPrintable[chars[index]]))
            {
                checkIndex(bytes, byteIndex, "bytes");
                bytes[byteIndex++] = '+';
                ret++;
                emitEnd = true;
            }

            while (index < len && (chars[index] >= 0x80 || !isPrintable[chars[index]]))
            {
                wchar c1 = chars[index];
                checkIndex(bytes, byteIndex + 1, "bytes");
                bytes[byteIndex++] = base64[c1 >>> 10];                         
                bytes[byteIndex++] = base64[(c1 & 0x3f0) >>> 4];    
                ret += 2;
                if (index < len - 1 && (chars[index + 1] >= 0x80 || !isPrintable[chars[index + 1]]))
                {               
                    wchar c2 = chars[index + 1];
                    checkIndex(bytes, byteIndex + 2, "bytes");
                    bytes[byteIndex++] = base64[((c1 & 0xf) << 2) | (c2 >>> 14)];     
                    bytes[byteIndex++] = base64[(c2 & 0x3f00) >>> 8];                 
                    bytes[byteIndex++] = base64[(c2 & 0xfc) >>> 2];        
                    ret += 3;
                    if (index < len - 2 && (chars[index + 2] >= 0x80 || !isPrintable[chars[index + 2]]))
                    {
                        wchar c3 = chars[index + 2];
                        checkIndex(bytes, byteIndex + 2, "bytes");
                        bytes[byteIndex++] = base64[((c2 & 0x3) << 4) | (c3 >>> 12)];      
                        bytes[byteIndex++] = base64[(c3 & 0xfc0) >>> 6];                  
                        bytes[byteIndex++] = base64[c3 & 0x3f];     
                        ret += 3;
                        index++;
                    }
                    else
                    {
                        checkIndex(bytes, byteIndex, "bytes");
                        bytes[byteIndex++] = base64[(c2 & 0x3) << 4];
                        ret++;
                    }
                    index++;
                }
                else
                {
                    checkIndex(bytes, byteIndex, "bytes");
                    bytes[byteIndex++] = base64[(c1 & 0xf) << 2]; 
                    ret++;
                }
                index++;
            }

            if (emitEnd)
            {
                checkIndex(bytes, byteIndex, "bytes");
                bytes[byteIndex++] = '-';
                ret++;
            }
        }   
        return ret;
    }

    override int GetByteCount(wchar[] chars, int index, int count)
    {
        checkNull(chars, "chars");
        checkIndex(chars, index, count);

        auto isPrintable = allowOptionals ? isutf7o : isutf7d;

        int len = index + count;
        int ret;
        while (index < len)
        {
            bool emitEnd = false;
            while (index < len && chars[index] < 0x80 && isPrintable[chars[index]])
            {
                index++;
                ret++;
            }
            while (index < len && chars[index] == '+')
            {
                index++;
                ret += 2;
            }
            if (index < len && (chars[index] >= 0x80 || !isPrintable[chars[index]]))
            {
                ret++;
                emitEnd = true;
            }

            while (index < len && (chars[index] >= 0x80 || !isPrintable[chars[index]]))
            {
                ret += 2;
                if (index < len - 1 && (chars[index + 1] >= 0x80 || !isPrintable[chars[index + 1]]))
                {               
                    ret += 3;
                    if (index < len - 2 && (chars[index + 2] >= 0x80 || !isPrintable[chars[index + 2]]))
                    { 
                        ret += 3;
                        index++;
                    }
                    else
                        ret++;
                    index++;
                }
                else
                    ret++;
                index++;
            }

            if (emitEnd)
                ret++;
        }   
        return ret;
    }

    override int GetChars(ubyte[] bytes, int index, int count, wchar[] chars, int charIndex)
    {
        int doFallback(ubyte[] wrong, int idx)
        {
            wchar[] fbchars = getDecoderFallbackChars(wrong, idx);
            if (fbchars.length > 0)
            {
                if (!isValidUnicode(fbchars))
                    throw new ArgumentException("fallback");    
                checkIndex(chars, charIndex + fbchars.length, "chars");
                chars[charIndex .. charIndex + fbchars.length] = fbchars;
                charIndex += fbchars.length;
                return fbchars.length;
            } 
            return 0;
        }

        checkNull(chars);
        checkNull(bytes);
        checkIndex(bytes, index, count);
        checkIndex(chars, charIndex, "charIndex");

        int len = index + count;
        int ret;
        while (index < len)
        {
            while (index < len && bytes[index] != '+')
            {
                checkIndex(chars, charIndex, "chars");
                chars[charIndex++] = bytes[index];
                index++;
                ret++;
            }
            if (index >= len)
                break;

            index++; //skip +

            if (index < len && bytes[index] == '-')
            {
                checkIndex(chars, charIndex, "chars");
                chars[charIndex++] = '+';
                ret++;
            }
            else if (index >= len)
                ret += doFallback(bytes[index - 1 .. index], index - 1);
            else
            {
                size_t k = index;
                while (k < len && bytes[k] != '-' && base64dec[bytes[k]] != 0xff)
                    k++;
                k -= index;
                while (k >= 8)
                {

                    checkIndex(chars, charIndex, "chars");
                    chars[charIndex++] = cast(wchar)((base64dec[bytes[index]] << 10) | 
                                                        (base64dec[bytes[index + 1]] << 4) | 
                                                        (base64dec[bytes[index + 2]] >>> 2));
                    chars[charIndex++] = cast(wchar)(((base64dec[bytes[index + 2]] & 0x3) << 14) | 
                                                     (base64dec[bytes[index + 3]] << 8) | 
                                                     (base64dec[bytes[index + 4]] << 2) | 
                                                     (base64dec[bytes[index + 5]] >>> 4));
                    chars[charIndex++] = cast(wchar)((base64dec[bytes[index + 5]] << 12) | 
                                                     (base64dec[bytes[index + 6]] << 6) | 
                                                     base64dec[bytes[index + 7]]);
                    k -= 8;
                    index += 8;
                    ret +=3;
                }
                if (k >= 6)
                {
                    checkIndex(chars, charIndex + 1, "chars");
                    chars[charIndex++] = cast(wchar)((base64dec[bytes[index]] << 10) | 
                                                     (base64dec[bytes[index + 1]] << 4) | 
                                                     (base64dec[bytes[index + 2]] >>> 2));
                    chars[charIndex++] = cast(wchar)(((base64dec[bytes[index + 2]] & 0x3) << 14) | 
                                                     (base64dec[bytes[index + 3]] << 8) | 
                                                     (base64dec[bytes[index + 4]] << 2) | 
                                                     (base64dec[bytes[index + 5]] >>> 4));
                    ret += 2;
                    auto bits = base64dec[bytes[index + 5]] << 12;
                    if (k > 6 || bits != 0)
                        ret += doFallback(bytes[index + 5 .. index + k], index + 5);
                    index += k;
                }
                else if (k >= 3)
                {
                    checkIndex(chars, charIndex + 1, "chars");
                    chars[charIndex++] = cast(wchar)((base64dec[bytes[index]] << 10) | 
                                                     (base64dec[bytes[index + 1]] << 4) | 
                                                     (base64dec[bytes[index + 2]] >>> 2));
                    ret++;
                    auto bits = (base64dec[bytes[index + 2]] & 0x3) << 14;
                    if (k > 3 || bits != 0)
                        ret += doFallback(bytes[index + 2 .. index + k], index + 2);
                    index += k;
                }
                else
                {
                    ret += doFallback(bytes[index .. index + k], index);
                    index += k;
                }
                if (index < len)
                {
                    if (bytes[index] == '-')
                        index++; //skip -
                    else
                    {
                        k = index;
                        while(k < len && bytes[k] != '-')
                            k++;
                        ret += doFallback(bytes[index .. k + 1], index);
                        index = k + 1; //skip -
                    }
                }
            }
        }   
        return ret;      
    }

    override int GetCharCount(ubyte[] bytes, int index, int count)
    {
        int doFallback(ubyte[] wrong, int idx)
        {
            wchar[] fbchars = getDecoderFallbackChars(wrong, idx);
            return fbchars.length;
        }

        checkNull(bytes);
        checkIndex(bytes, index, count);

        int len = index + count;
        int ret;
        while (index < len)
        {
            while (index < len && bytes[index] != '+')
            {
                index++;
                ret++;
            }
            if (index >= len)
                break;

            index++; //skip +

            if (index < len && bytes[index] == '-')
                ret++;
            else if (index >= len)
                ret += doFallback(bytes[index - 1 .. index], index - 1);
            else
            {
                size_t k = index;
                while (k < len && bytes[k] != '-' && base64dec[bytes[k]] != 0xff)
                    k++;
                k -= index;
                while (k >= 8)
                {
                    k -= 8;
                    index += 8;
                    ret +=3;
                }
                if (k >= 6)
                {
                    ret += 2;
                    auto bits = base64dec[bytes[index + 5]] << 12;
                    if (k > 6 || bits != 0)
                        ret += doFallback(bytes[index + 5 .. index + k], index + 5);
                    index += k;
                }
                else if (k >= 3)
                {
                    ret++;
                    auto bits = (base64dec[bytes[index + 2]] & 0x3) << 14;
                    if (k > 3 || bits != 0)
                        ret += doFallback(bytes[index + 2 .. index + k], index + 2);
                    index += k;
                }
                else
                {
                    ret += doFallback(bytes[index .. index + k], index);
                    index += k;
                }
                if (index < len)
                {
                    if (bytes[index] == '-')
                        index++; //skip -
                    else
                    {
                        k = index;
                        while(k < len && bytes[k] != '-')
                            k++;
                        ret += doFallback(bytes[index .. k + 1], index);
                        index = k + 1; //skip -
                    }
                }
            }
        }   
        return ret;      
    }

    override Decoder GetDecoder()
    {
        return new UTF7Decoder(this);
    }
    
}

private final class UTF32Decoder: Decoder
{
private:
    Encoding _encoding;
    ubyte[] lastBytes;
public:

    this(Encoding encoding)
    {
        _encoding = encoding;

    }

    override public void Reset() 
    {
        super.Reset();
        lastBytes = null;
    }
    
    override int GetCharCount(ubyte[] bytes, int byteIndex, int byteCount, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        auto remaining = byteCount % 4;
        if (!flush && remaining != 0)
        {
            byteCount -= remaining;
        }
        return _encoding.GetCharCount(buffer, 0, byteCount);
    }

    override int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        checkNull(chars, "chars");
        checkIndex(chars, charIndex, "charIndex");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
            lastBytes = null;
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        auto remaining = byteCount % 4;
        if (!flush && remaining != 0)
        {
            lastBytes = buffer[$ - remaining .. $];
            byteCount -= remaining;
        }
        return _encoding.GetChars(buffer, 0, byteCount, chars, charIndex);
    }
}

private final class UnicodeDecoder: Decoder
{
private:
    UnicodeEncoding _encoding;
    ubyte[] lastBytes;
public:

    this(UnicodeEncoding encoding)
    {
        _encoding = encoding;

    }

    override public void Reset() 
    {
        super.Reset();
        lastBytes = null;
    }

    override int GetCharCount(ubyte[] bytes, int byteIndex, int byteCount, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        auto remaining = byteCount % 2;
        if (!flush)
        {
            buffer = buffer[0 .. byteCount - remaining];
            if (buffer.length > 0)
            {
                auto ending = buffer[$ - 2 .. $];
                UnicodeEncoding.U16 u;        
                u.b[0] = _encoding._bigEndian ? ending[0] : ending[1];
                u.b[1] = !_encoding._bigEndian ? ending[0] : ending[1];
                if (Char.IsHighSurrogate(u.w))
                    remaining += 2;
            }
        }
        if (!flush && remaining != 0)
        {
            byteCount -= remaining;
        }
        return _encoding.GetCharCount(buffer, 0, byteCount);
    }

    override int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        checkNull(chars, "chars");
        checkIndex(chars, charIndex, "charIndex");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
            lastBytes = null;
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        auto remaining = byteCount % 2;
        if (!flush)
        {
            buffer = buffer[0 .. byteCount - remaining];
            if (buffer.length > 0)
            {
                auto ending = buffer[$ - 2 .. $];
                UnicodeEncoding.U16 u;        
                u.b[0] = _encoding._bigEndian ? ending[0] : ending[1];
                u.b[1] = !_encoding._bigEndian ? ending[0] : ending[1];
                if (Char.IsHighSurrogate(u.w))
                    remaining += 2;
            }
        }
        if (!flush && remaining != 0)
        {
            lastBytes = buffer[$ - remaining .. $];
            byteCount -= remaining;
        }
        return _encoding.GetChars(buffer, 0, byteCount, chars, charIndex);
    }
}

private final class UTF8Decoder: Decoder
{
private:
    Encoding _encoding;
    ubyte[] lastBytes;
public:

    this(Encoding encoding)
    {
        _encoding = encoding;

    }

    override public void Reset() 
    {
        super.Reset();
        lastBytes = null;
    }

    override int GetCharCount(ubyte[] bytes, int byteIndex, int byteCount, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        if (!flush)
        {
            size_t i = 0;
            while (i < buffer.length)
            {
                auto cpLen = stride(cast(char[])buffer, i);
                if (cpLen == 0 && i < buffer.length - 4)
                {
                    buffer = buffer[0 .. i];
                    byteCount -= buffer.length - i;
                    break;
                }
                else
                    cpLen = 1;
                i += cpLen;
            }
        }
        return _encoding.GetCharCount(buffer, 0, byteCount);
    }

    override int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        checkNull(chars, "chars");
        checkIndex(chars, charIndex, "charIndex");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
            lastBytes = null;
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        if (!flush)
        {
            size_t i = 0;
            while (i < buffer.length)
            {
                auto cpLen = stride(cast(char[])buffer, i);
                if (cpLen == 0 && i < buffer.length - 4)
                {
                    buffer = buffer[0 .. i];
                    lastBytes = buffer[i .. $];
                    byteCount -= buffer.length - i;
                    break;
                }
                else
                    cpLen = 1;
                i += cpLen;
            }
        }
        return _encoding.GetChars(buffer, 0, byteCount, chars, charIndex);
    }
}

private final class UTF7Decoder: Decoder
{
private:
    enum State { Direct, ExpectingBase64, Base64, Terminated }
    State state = State.Direct;
    Encoding _encoding;
    ubyte[] lastBytes;
public:
    this(Encoding encoding)
    {
        this._encoding = encoding;

    }

    override public void Reset() 
    {
        super.Reset();
        lastBytes = null;
        state = State.Direct;
    }

    override int GetCharCount(ubyte[] bytes, int byteIndex, int byteCount, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        State save = state;
        if (!flush)
        {
            size_t len = buffer.length;
            size_t i = 0;
            while (i < len)
            {
                if (state == State.Direct)
                {
                    while (i < len && buffer[i] != '+')
                        i++;
                    state = i < len ? State.ExpectingBase64 : State.Terminated;
                    i++;
                }

                if (state == State.ExpectingBase64)
                {
                    if (i >= len)
                    {
                        byteCount = i - 2;
                        state = State.Direct;
                        break;
                    }

                    if (buffer[i] == '-')
                    {
                        i++;
                        state = State.Direct;
                        continue;
                    }

                    state = State.Base64;
                }

                if (state == State.Base64)
                {
                    int j = i;
                    while (i < len && buffer[i] != '-')
                        i++;
                    if (i >= len)
                    {
                        auto remainder = (i - j) % 8;
                        byteCount = i - remainder;
                        break;
                    }
                    i++;
                    state = State.Direct;
                }
            }
        }

        state = save;

        return _encoding.GetCharCount(buffer, 0, byteCount);
    }

    override int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        checkNull(chars, "chars");
        checkIndex(chars, charIndex, "charIndex");

        ubyte[] buffer;
        if (lastBytes !is null)
        {
            buffer = new ubyte[byteCount + lastBytes.length];
            buffer[0 .. lastBytes.length] = lastBytes;
            buffer[lastBytes.length .. $] = bytes[byteIndex .. byteIndex + byteCount];
            lastBytes = null;
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        if (!flush)
        {
            size_t len = buffer.length;
            size_t i = 0;
            while (i < len)
            {
                if (state == State.Direct)
                {
                    while (i < len && buffer[i] != '+')
                        i++;
                    state = i < len ? State.ExpectingBase64 : State.Terminated;
                    i++;
                }

                if (state == State.ExpectingBase64)
                {
                    if (i >= len)
                    {
                        byteCount = i - 2;
                        state = State.Direct;
                        lastBytes = [cast(ubyte)'+'];
                        break;
                    }

                    if (buffer[i] == '-')
                    {
                        i++;
                        state = State.Direct;
                        continue;
                    }

                    state = State.Base64;
                }

                if (state == State.Base64)
                {
                    int j = i;
                    while (i < len && buffer[i] != '-')
                        i++;
                    if (i >= len)
                    {
                        auto remainder = (i - j) % 8;
                        byteCount = i - remainder;
                        lastBytes = buffer[$ - remainder .. $];
                        break;
                    }
                    i++;
                    state = State.Direct;
                }
            }
        }

        return _encoding.GetChars(buffer, 0, byteCount, chars, charIndex);
    }
}

private final class DBCSDecoder: Decoder
{
private:
    Encoding _encoding;
    ubyte lastByte;
    bool leftOver;
public:

    this(Encoding encoding)
    {
        _encoding = encoding;

    }

    override public void Reset() 
    {
        super.Reset();
        leftOver = false;
    }

    override int GetCharCount(ubyte[] bytes, int byteIndex, int byteCount, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");

        ubyte[] buffer;
        if (leftOver)
        {
            buffer = new ubyte[byteCount + 1];
            buffer[0] = lastByte;
            buffer[1 .. $] = bytes[byteIndex .. byteIndex + byteCount];
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        if (!flush && byteCount % 2 != 0)
            byteCount--;

        return _encoding.GetCharCount(buffer, 0, byteCount);
    }

    override int GetChars(ubyte[] bytes, int byteIndex, int byteCount, wchar[] chars, int charIndex, bool flush)
    {      
        checkNull(bytes, "bytes");
        checkIndex(bytes, byteIndex, byteCount, "byteIndex", "byteCount");
        checkNull(chars, "chars");
        checkIndex(chars, charIndex, "charIndex");

        ubyte[] buffer;
        if (leftOver)
        {
            buffer = new ubyte[byteCount + 1];
            buffer[0] = lastByte;
            buffer[1 .. $] = bytes[byteIndex .. byteIndex + byteCount];
            leftOver = false;
        }
        else
            buffer = bytes[byteIndex .. byteIndex + byteCount];

        byteCount = buffer.length;

        if (!flush && byteCount % 2 != 0)
        {
            byteCount--;
            leftOver = true;
            lastByte = buffer[byteCount];
        }
        return _encoding.GetChars(buffer, 0, byteCount, chars, charIndex);
    }
}