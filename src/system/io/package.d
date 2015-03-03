module system.io;

import system;
import system.globalization;
import system.text;


import internals.checked;
import internals.core;
import internals.resources;
import internals.hresults;

// =====================================================================================================================
// IOException
// =====================================================================================================================

class IOException : SystemException
{
    this()
    {
        super(SharpResources.GetString("ExceptionIO"));
        HResult = COR_E_IO;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = COR_E_IO;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = COR_E_IO;
    }
}

// =====================================================================================================================
// FileNotFoundException
// =====================================================================================================================

class FileNotFoundException : IOException
{
private:
    wstring fileName;
    wstring fusionLog;
public:
    this()
    {
        super(SharpResources.GetString("ExceptionFileNotFound"));
        HResult = COR_E_FILENOTFOUND;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = COR_E_FILENOTFOUND;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = COR_E_FILENOTFOUND;
    }

    this(wstring msg, wstring fileName)
    {
        super(msg);
        this.fileName = fileName;
        HResult = COR_E_FILENOTFOUND;
    }

    this(wstring msg, wstring fileName, Throwable next)
    {
        super(msg, next);
        this.fileName = fileName;
        HResult = COR_E_FILENOTFOUND;
    }

    @property wstring FileName()
    {
        return fileName;
    }

    @property wstring FusionLog()
    {
        return fusionLog;
    }

    override wstring ToString()
    {
        wstring ret = this.classinfo.ToString() ~ ": " ~ Message;
        if (fileName.length > 0)
            ret ~= Environment.NewLine ~ SharpResources.GetString("ArgumentFileName", fileName);
        if (next)
            ret ~= "--->" ~ next.ToString();
        if (StackTrace.length > 0)
            ret ~= Environment.NewLine ~ StackTrace;
        if (fusionLog.length > 0)
            ret ~= Environment.NewLine ~ Environment.NewLine ~ fusionLog;
        return ret;
    }
    //todo fusionLog constructor
}

// =====================================================================================================================
// DirectoryNotFoundException
// =====================================================================================================================

class DirectoryNotFoundException : IOException
{
    this()
    {
        super(SharpResources.GetString("ExceptionDirectoryNotFound"));
        HResult = COR_E_DIRECTORYNOTFOUND;
    }

    this(wstring msg)
    {
        super(msg);
        HResult = COR_E_DIRECTORYNOTFOUND;
    }

    this(wstring msg, Throwable next)
    {
        super(msg, next);
        HResult = COR_E_DIRECTORYNOTFOUND;
    }
}

// =====================================================================================================================
// TextWriter
// =====================================================================================================================

abstract class TextWriter : SharpObject, IDisposable
{
private:
    IFormatProvider formatProvider;
    enum wstring defaultNewLine = "\r\n";
    static TextWriter _null;
protected:
    wchar[] newLine = ['\r', '\n'];

    pure @safe nothrow
    this()
    {
        formatProvider = null;
    }

    pure @safe nothrow
    this(IFormatProvider provider)
    {
        this.formatProvider = provider;
    }

    void Dispose(bool disposing) { }

public:

    @property
    static TextWriter Null()
    {
        if (_null is null)
            _null = new NullTextWriter();
        return _null;
    }

    @property 
    IFormatProvider FormatProvider()
    {
        return formatProvider is null ? CultureInfo.CurrentCulture : formatProvider;
    }

    @property 
    wstring NewLine()
    {
        return newLine.idup;
    }

    @property 
    wstring NewLine(wstring value)
    {
        if (value is null)
            newLine = defaultNewLine.dup;
        else
            newLine = value.dup;
        return newLine.idup;
    }

    void Close()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    void Flush() {}

    ~this()
    {
        Dispose(false);
    }

    @property
    abstract .Encoding Encoding();

    void Write(wchar value) { }

    void Write(wchar[] buffer, int index, int count)
    {
        checkNull(buffer, "buffer");
        checkIndex(buffer, index, count);
        for (auto i = 0; i < count; i++) 
            Write(buffer[index + i]);
    }

    void Write(wchar[] buffer)
    {
        Write(buffer, 0, buffer.length);
    }

    void Write(bool value) 
    {
        Write(value ? Boolean.TrueString : Boolean.FalseString);
    }

    void Write(byte value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(ubyte value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(short value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(ushort value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(int value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(uint value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(long value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(ulong value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(float value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(double value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(decimal value) 
    {
        Write(value.ToString(FormatProvider));
    }

    void Write(Object value)
    {
        if (value is null)
            return;
        if (auto formattable = cast(IFormattable)value)
            Write(formattable.ToString(null, FormatProvider));
        else
            Write(value.ToString());
    }

    void Write(T)(T value)
    {
        Write(defaultToString(value, FormatProvider));
    }

    void Write(T...)(wstring fmt, T args) if (T.length > 0)
    {
        Write(String.Format(FormatProvider, fmt, args));
    }

    void Write(wstring value)
    {
        if (value)
            Write(cast(wchar[])value);
    }

    void WriteLine(wchar value) 
    {
        Write(value);
        WriteLine(value);
    }

    void WriteLine(wchar[] buffer, int index, int count)
    {
        Write(buffer, index, count);
        WriteLine();
    }

    void WriteLine(wchar[] buffer)
    {
        Write(buffer);
        WriteLine();
    }

    void WriteLine(bool value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine()
    {
        Write(newLine);
    }

    void WriteLine(byte value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(ubyte value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(short value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(ushort value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(int value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(uint value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(long value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(ulong value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(float value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(double value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(decimal value) 
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(Object value)
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(T)(T value)
    {
        Write(value);
        WriteLine();
    }

    void WriteLine(T...)(wstring fmt, T args) if (T.length > 0)
    {
        Write(fmt, args);
        WriteLine();
    }

    void WriteLine(wstring value)
    {
        Write(value);
        WriteLine();
    }

    static TextWriter Synchronized(TextWriter writer)
    {
        checkNull(writer);
        if (cast(SynchronizedTextWriter)writer)
            return writer;
        return new SynchronizedTextWriter(writer);
    }
}

private final class NullTextWriter : TextWriter
{
    this()
    {
        super(CultureInfo.CurrentCulture);
    }

    override @property .Encoding Encoding() 
    {
        return .Encoding.Default;
    }

    alias Write = TextWriter.Write;
    alias WriteLine = TextWriter.WriteLine;
    override void Write(wchar[] buffer, int index, int count) { }
    override void Write(wstring value) { }
    override void Write(Object value) { }
    override void WriteLine() { }
    override void WriteLine(wstring value) { }
    override void WriteLine(Object value) { }
    override void Write(T)(T value) { }
    override void WriteLine(T)(T value) { }
    
}

private final class SynchronizedTextWriter : TextWriter
{
    alias Write = TextWriter.Write;
    alias WriteLine = TextWriter.WriteLine;
    TextWriter writer;

    this(TextWriter writer)
    {
        super(writer.FormatProvider);
        this.writer = writer;
    }

    override @property .Encoding Encoding()             { return writer.Encoding; }
    override @property IFormatProvider FormatProvider() { return writer.FormatProvider; } 
    override @property wstring NewLine()                { synchronized { return writer.NewLine; } }
    override @property wstring NewLine(wstring value)   { synchronized { return writer.NewLine(value); } }
    override void Close()                               { synchronized { writer.Close(); } }
    override void Dispose(bool disposing)               { synchronized { if (disposing) writer.Dispose(); } }
    override void Flush()                               { synchronized { writer.Flush(); } }
    override void Write(wchar[] buffer)                 { synchronized { writer.Write(buffer); } }
    override void Write(wchar value)                    { synchronized { writer.Write(value); } }
    override void Write(bool value)                     { synchronized { writer.Write(value); } }
    override void Write(byte value)                     { synchronized { writer.Write(value); } }
    override void Write(ubyte value)                    { synchronized { writer.Write(value); } }
    override void Write(short value)                    { synchronized { writer.Write(value); } }
    override void Write(ushort value)                   { synchronized { writer.Write(value); } }
    override void Write(int value)                      { synchronized { writer.Write(value); } }
    override void Write(uint value)                     { synchronized { writer.Write(value); } }
    override void Write(long value)                     { synchronized { writer.Write(value); } }
    override void Write(ulong value)                    { synchronized { writer.Write(value); } }
    override void Write(float value)                    { synchronized { writer.Write(value); } }
    override void Write(double value)                   { synchronized { writer.Write(value); } }
    override void Write(decimal value)                  { synchronized { writer.Write(value); } }
    override void Write(Object value)                   { synchronized { writer.Write(value); } }
    override void Write(T)(T value)                     { synchronized { writer.Write(value); } }
    override void Write(wstring value)                  { synchronized { writer.Write(value); } }
    override void Write(wchar[] buffer, int index, int count) { synchronized { writer.Write(buffer, index , count); } }
    override void Write(T...)(wstring fmt, T args) if (T.length > 0) { synchronized { writer.Write(fmt, args); } }

    override void WriteLine()                           { synchronized { writer.WriteLine(); } }
    override void WriteLine(wchar[] buffer)             { synchronized { writer.WriteLine(buffer); } }
    override void WriteLine(wchar value)                { synchronized { writer.WriteLine(value); } }
    override void WriteLine(bool value)                 { synchronized { writer.WriteLine(value); } }
    override void WriteLine(byte value)                 { synchronized { writer.WriteLine(value); } }
    override void WriteLine(ubyte value)                { synchronized { writer.WriteLine(value); } }
    override void WriteLine(short value)                { synchronized { writer.WriteLine(value); } }
    override void WriteLine(ushort value)               { synchronized { writer.WriteLine(value); } }
    override void WriteLine(int value)                  { synchronized { writer.WriteLine(value); } }
    override void WriteLine(uint value)                 { synchronized { writer.WriteLine(value); } }
    override void WriteLine(long value)                 { synchronized { writer.WriteLine(value); } }
    override void WriteLine(ulong value)                { synchronized { writer.WriteLine(value); } }
    override void WriteLine(float value)                { synchronized { writer.WriteLine(value); } }
    override void WriteLine(double value)               { synchronized { writer.WriteLine(value); } }
    override void WriteLine(decimal value)              { synchronized { writer.WriteLine(value); } }
    override void WriteLine(Object value)               { synchronized { writer.WriteLine(value); } }
    override void WriteLine(T)(T value)                 { synchronized { writer.WriteLine(value); } }
    override void WriteLine(wstring value)              { synchronized { writer.WriteLine(value); } }
    override void WriteLine(wchar[] buffer, int index, int count) { synchronized { writer.WriteLine(buffer, index , count); } }
    override void WriteLine(T...)(wstring fmt, T args) if (T.length > 0) { synchronized { writer.WriteLine(fmt, args); } }
}

// =====================================================================================================================
// TextReader
// =====================================================================================================================

abstract class TextReader: SharpObject, IDisposable
{
private:
    static TextReader _null;
protected:
    this() { }
    void Dispose(bool disposing) { }

public:
    void Close()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    int Peek()
    {
        return -1;
    }

    int Read()
    {
        return -1;
    }

    int Read(wchar[] buffer, int index, int count)
    {
        checkNull(buffer);
        checkIndex(buffer, index, count);
        int read = 0;
        do {
            int ch = Read();
            if (ch < 0) break;
            buffer[index + read++] = cast(wchar)ch;
        } while (read < count);
        return read;
    }

    wstring ReadToEnd()
    {
        wchar[] buffer = new wchar[Stream._defaultBufferSize];
        StringBuilder sb = new StringBuilder(Stream._defaultBufferSize);
        int read = Read(buffer, 0, buffer.Length);
        while (read > 0)
        {
            sb.Append(buffer, 0, read);
            read = Read(buffer, 0, buffer.Length);
        }
        return sb.ToString();
    }

    int ReadBlock(wchar[] buffer, int index, int count)
    {
        int len;
        int read;
        do {
            len = Read(buffer, index + read, count - read);
            read += len;
        } while (len > 0 && read < count);
        return read;
    }

    wstring ReadLine()
    {
        StringBuilder sb = new StringBuilder();
        int ch = Read();
        while (ch >= 0)
        {
            if (ch == '\n')
                return sb.ToString();
            if (ch == '\r')
            {
                int ch2 = Peek();
                if (ch2 == '\n')
                    Read();
                return sb.ToString();
            }
            sb.Append(cast(wchar)ch);
            ch = Read();
        }
        return sb.Length > 0 ? sb.ToString() : null;

    }

    @property static TextReader Null()
    {
        if (_null is null)
            _null = new NullTextReader();
        return _null;
    }

    static Synchronized(TextReader reader)
    {
        checkNull(reader, "reader");
        if (cast(SynchronizedTextReader)reader)
            return reader;
        return new SynchronizedTextReader(reader);

    }
}

private final class NullTextReader : TextReader
{
    override int Read(wchar[] buffer, int index, int count) { return 0; }
    override wstring ReadLine() { return null; }
}

private final class SynchronizedTextReader: TextReader
{
    TextReader reader;

    this(TextReader reader)
    {
        this.reader = reader;
    }

    override void Close()                                           { synchronized { reader.Close(); } }
    override void Dispose(bool diposing)                            { synchronized { reader.Dispose(); } }
    override int Peek()                                             { synchronized { return reader.Peek(); } }
    override int Read()                                             { synchronized { return reader.Read(); } }
    override int Read(wchar[] buffer, int index, int count)         { synchronized { return reader.Read(buffer, index, count); } }
    override int ReadBlock(wchar[] buffer, int index, int count)    { synchronized { return reader.ReadBlock(buffer, index, count); } }
    override wstring ReadLine()                                     { synchronized { return reader.ReadLine(); } }
    override wstring ReadToEnd()                                    { synchronized { return reader.ReadToEnd(); } }
}

// =====================================================================================================================
// Stream
// =====================================================================================================================

enum SeekOrigin
{
    Begin,
    Current,
    End,
}

abstract class Stream: SharpObject, IDisposable
{
private:
    static Stream _nullStream;
    enum _defaultBufferSize = 4096;

protected:
    void Dispose(bool disposing) {}

public:

    @property static Stream Null()
    {
        if (_nullStream is null)
            _nullStream = new NullStream();
        return _nullStream;
    }

    abstract @property bool CanRead();
    abstract @property bool CanSeek();
    abstract @property bool CanWrite();
    abstract @property long Length();
    abstract @property long Position();
    abstract @property long Position(long value);
    abstract long Seek(long offset, SeekOrigin origin);
    abstract void SetLength(long value);
    abstract int Read(ubyte[] buffer, int offset, int count);
    abstract void Write(ubyte[] buffer, int offset, int count);
    abstract void Flush();

    @property bool CanTimeout()
    {
        return false;
    }

    @property int ReadTimeout()
    {
        throw new InvalidOperationException(SharpResources.GetString("InvalidOperationTimeouts"));
    }

    @property int ReadTimeout(int value)
    {
        throw new InvalidOperationException(SharpResources.GetString("InvalidOperationTimeouts"));
    }

    @property int WriteTimeout()
    {
        throw new InvalidOperationException(SharpResources.GetString("InvalidOperationTimeouts"));
    }

    @property int WriteTimeout(int value)
    {
        throw new InvalidOperationException(SharpResources.GetString("InvalidOperationTimeouts"));
    }

    final void CopyTo(Stream destination, int bufferSize)
    {
        checkNull(destination, "destination");
        if (bufferSize <= 0)
            throw new ArgumentOutOfRangeException("bufferSize");
        if (!CanRead && !CanWrite)
            throw new ObjectDisposedException("source");
        if (!destination.CanRead && !destination.CanWrite)
            throw new ObjectDisposedException("destination");
        if (!CanRead || !destination.CanWrite)
            throw new NotSupportedException();    
        ubyte[] buffer = new ubyte[bufferSize];

        int r;
        while ((r = Read(buffer, 0, bufferSize)) > 0)
            destination.Write(buffer, 0, r);
    }

    final void CopyTo(Stream destination)
    {
        CopyTo(destination, _defaultBufferSize);
    }

    void Close()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    final void Dispose()
    {
        Close();
    }

    int ReadByte()
    {
        ubyte[] buffer = new ubyte[1];
        int r = Read(buffer, 0, 1);
        return r <= 0 ? -1: buffer[0];
    }

    void WriteByte(ubyte value)
    {
        Write([value], 0, 1);
    }

    ~this()
    {
        Dispose(false);
    }
}

private final class NullStream : Stream
{

public:
    override @property bool CanRead() { return true; }
    override @property bool CanSeek() { return true; }
    override @property bool CanWrite() { return true; }
    override @property long Length() { return 0; }
    override @property long Position() { return 0; }
    override @property long Position(long value) { return 0; }
    override long Seek(long offset, SeekOrigin origin) { return 0; }
    override void SetLength(long value) { }
    override int Read(ubyte[] buffer, int offset, int count) { return 0; }
    override int ReadByte() { return -1; }
    override void Write(ubyte[] buffer, int offset, int count) { }
    override void WriteByte(ubyte value) { }
    override void Flush() { }
}

@Flags()
enum FileAccess
{
    Read = 1,
    Write = 2,
    ReadWrite = Write | Read,
}

// =====================================================================================================================
// StreamReader
// =====================================================================================================================

class StreamReader : TextReader
{
private:
    Stream stream;
    Encoding encoding;
    Decoder decoder;
    bool leaveOpen;
    bool detectEncoding;
    int bufferSize;
    ubyte[] buffer;
    int bufferLen;
    int bufferPos;
    wchar[] charBuffer;
    int charBufferLen;
    int charBufferPos;
    static Encoding[] encodingsWithPreamble;
    static int maxPreambleLength = -1;
    static StreamReader nullReader;

    enum minBufferSize = 128;
    enum defaultBufferSize = Stream._defaultBufferSize;

    static Encoding[] getEncodingsWithPreamble()
    {
        if (encodingsWithPreamble is null)
        {
            auto infos = Encoding.GetEncodings();
            foreach(info;infos)
            {
                try
                {
                    auto enc = Encoding.GetEncoding(info.CodePage);
                    auto preamble = enc.GetPreamble();
                    if (preamble.length > 0)
                    {
                        encodingsWithPreamble ~= enc;
                        if (preamble.length > maxPreambleLength)
                            maxPreambleLength = preamble.Length;
                    }
                }
                catch {}
            }
        }
        return encodingsWithPreamble;
    }

    static int getMaxPreambleLength()
    {
        if (maxPreambleLength < 0)
            getEncodingsWithPreamble();
        return maxPreambleLength;
    }

    Encoding autoDetect(Encoding defaultEncoding)
    {
        foreach(enc; getEncodingsWithPreamble())
        {
            auto preamble = enc.GetPreamble();
            if (preamble.length <= bufferLen && preamble == buffer[0 .. preamble.length])
            {
                bufferPos += preamble.length;
                return enc;
            }
        }
        return defaultEncoding;
    }

    protected int fillBuffers()
    {
        bool eof = false;
        int bytesRead = stream.Read(buffer, 0, bufferSize);
        eof = bytesRead == 0;
        bufferLen = 0;
        bufferPos = 0;
        while (bytesRead > 0)
        {
            bufferLen += bytesRead;
            if (bufferLen < bufferSize)
            {
                bytesRead = stream.Read(buffer, bufferLen, bufferSize - bufferLen);
                eof = bytesRead == 0;
            }
            else
                bytesRead = 0;
        }
        
        bufferPos = 0;

        if (bufferLen > 0 && detectEncoding)
        {
            encoding = autoDetect(encoding);
            detectEncoding = false;
        }

        
        charBufferLen = 0;
        charBufferPos = 0;
        if (bufferLen - bufferPos > 0)
        {
            if (decoder is null)
                decoder = encoding.GetDecoder();
            charBufferLen = decoder.GetChars(buffer, bufferPos, bufferLen - bufferPos, charBuffer, 0, eof);
            eof = false;
        }
        else if (eof) 
            charBufferLen = decoder.GetChars(buffer, 0, 0, charBuffer, 0, true);

        return charBufferLen;
    }

    void checkStream()
    {
        if (stream is null)
            throw new ObjectDisposedException(SharpResources.GetString("ObjectDisposedStreamClosed"));
    }

public:
    this(Stream stream, Encoding encoding, bool detectEncoding, int bufferSize, bool leaveOpen)
    {
        checkNull(stream, "stream");
        checkNull(encoding, "encoding");
        checkPositive(bufferSize, true, "bufferSize");
        if (!stream.CanRead)
            throw new ArgumentException(SharpResources.GetString("ArgumentStreamNotReadable"));
        this.stream = stream;
        this.encoding = encoding;
        this.leaveOpen = leaveOpen;
        this.detectEncoding = detectEncoding;
        this.bufferSize = bufferSize < minBufferSize ? minBufferSize : bufferSize;
        buffer = new ubyte[bufferSize];
        charBuffer = new wchar[encoding.GetMaxCharCount(bufferSize)];
    }

    this(Stream stream)
    {
        this(stream, Encoding.UTF8, true, defaultBufferSize, false); 
    }

    this(Stream stream, Encoding encoding, bool detectEncoding, int bufferSize)
    {
        this(stream, encoding, detectEncoding, bufferSize, false);
    }

    this(Stream stream, Encoding encoding, bool detectEncoding)
    {
        this(stream, encoding, detectEncoding, defaultBufferSize, false);
    }

    this(Stream stream, bool detectEncoding)
    {
        this(stream, Encoding.UTF8, detectEncoding, defaultBufferSize, false);
    }

    this(Stream stream, Encoding encoding)
    {
        this(stream, encoding, true, defaultBufferSize, false);
    }

    override void Close()
    {
        Dispose(true);
    }

    @property Encoding CurrentEncoding()
    {
        return encoding;
    }

    @property Stream BaseStream()
    {
        return stream;
    }

    override int Read()
    {
        checkStream();
        if (charBufferPos >= charBufferLen)
        {
            if (fillBuffers() == 0)
                return -1;
        }
        return charBuffer[charBufferPos++];
    }

    override int Peek()
    {
        checkStream();
        if (charBufferPos >= charBufferLen)
        {
            if (fillBuffers() == 0)
                return -1;
        }
        return charBuffer[charBufferPos];
    }

    override int Read(wchar[] buffer, int index, int count)
    {
        checkNull(buffer, "buffer");
        checkIndex(buffer, index, count);
        checkStream();

        int ret = 0;
        while (count > 0)
        {
            int charsAvailable = charBufferLen - charBufferPos;
            if (charsAvailable == 0)
                charsAvailable = fillBuffers();
            if (charsAvailable == 0)
                return ret;
            if (charsAvailable > count)
                charsAvailable = count;
            buffer[index .. index + charsAvailable] = charBuffer[charBufferPos .. charBufferPos + charsAvailable];
            charBufferPos += charsAvailable;
            ret += charsAvailable;
            count -= charsAvailable;
            index += charsAvailable;
        }
        return ret;
    }

    override wstring ReadToEnd()
    {
        checkStream();
        StringBuilder sb = new StringBuilder();
        if (bufferPos < bufferLen)
            sb.Append(charBuffer, bufferPos, bufferLen - bufferPos);
        while (fillBuffers() > 0)
        {
            sb.Append(charBuffer, bufferPos, bufferLen - bufferPos);
        }

        return sb.ToString();
    }

    override int ReadBlock(wchar[] buffer, int index, int count) 
    {
        checkStream();
        return super.ReadBlock(buffer, index, count);
    }

    override wstring ReadLine() 
    {
        checkStream();
        return super.ReadLine();
    }

    @property bool EndOfStream()
    {
        if (charBufferPos < charBufferLen)
            return false;
        return fillBuffers() == 0;
    }

    static @property StreamReader Null()
    {
        if (nullReader is null)
            nullReader = new NullStreamReader();
        return nullReader;
    }

    override void Dispose(bool disposing)
    {
        if (disposing && !leaveOpen && stream !is null)
            stream.Close();
       

        if (!leaveOpen && stream !is null)
        {
            stream = null;
            encoding = null;
            decoder = null;
            buffer = null;
            charBuffer = null;
            bufferPos = 0;
            bufferLen = 0;
            charBufferPos = 0;
            charBufferLen = 0;
            super.Dispose(disposing);
        }

    }

    //todo add filestream

}

private class NullStreamReader : StreamReader
{

    this() 
    {
        super(Stream.Null, Encoding.Unicode, false);
    }

    override Stream BaseStream()
    {
        return Stream.Null;
    }

    override Encoding CurrentEncoding()
    {
        return Encoding.Unicode;
    }

    override void Dispose(bool disposing)
    {
        //
    }

    override int Peek()
    {
        return -1;
    }

    override int Read()
    {
        return -1;
    }

    override int Read(wchar[] buffer, int index, int count) 
    {
        return 0;
    }

    public override wstring ReadLine()
    {
        return null;
    }

    override wstring ReadToEnd()
    {
        return String.Empty;
    }

    override int fillBuffers() 
    {
        return 0;
 
    }
}

// =====================================================================================================================
// StreamWriter
// =====================================================================================================================

class StreamWriter : TextWriter
{
private:
    Stream stream;
    .Encoding encoding;
    Encoder encoder;
    int bufferSize;
    bool leaveOpen;
    ubyte[] byteBuffer;
    wchar[] charBuffer;
    int charBufferPos;
    bool writePreamble = true;
    bool autoFlush;

    enum minBufferSize = StreamReader.minBufferSize / 2;
    enum defaultBufferSize = StreamReader.defaultBufferSize / 2;

    void checkStream()
    {
        if (stream is null)
            throw new ObjectDisposedException(SharpResources.GetString("ObjectDisposedStreamClosed"));
    }

    void dump(bool flushStream, bool flushEncoder)
    {
        if (writePreamble)
        {
            auto preamble = encoding.GetPreamble();
            if (preamble.length > 0)
                stream.Write(preamble, 0, preamble.length);
            writePreamble = false;
        }

        if (encoder is null)
            encoder = encoding.GetEncoder();
        
        if (charBufferPos > 0)
        {
            auto bytesToWrite = encoder.GetBytes(charBuffer, 0, charBufferPos, byteBuffer, 0, flushEncoder);
            if (bytesToWrite > 0)
                stream.Write(byteBuffer, 0, bytesToWrite);
        }
        else if (flushEncoder)
        {
            auto bytesToWrite = encoder.GetBytes(charBuffer, 0, 0, byteBuffer, 0, true);
            if (bytesToWrite > 0)
                stream.Write(byteBuffer, 0, bytesToWrite);
        }

        charBufferPos = 0;
        if (flushStream) 
            stream.Flush();
    }

public:
    this(Stream stream, .Encoding encoding, int bufferSize, bool leaveOpen)
    {
        checkNull(stream, "stream");
        checkNull(encoding, "encoding");
        checkPositive(bufferSize, true, "bufferSize");
        if (!stream.CanWrite)
            throw new ArgumentException(SharpResources.GetString("ArgumentStreamNotWriteable"));
        this.stream = stream;
        this.bufferSize = bufferSize < minBufferSize ? minBufferSize : bufferSize;
        this.leaveOpen = leaveOpen;
        this.encoding = encoding;
        charBuffer = new wchar[bufferSize];
        byteBuffer = new ubyte[encoding.GetMaxByteCount(bufferSize)];
    }

    this(Stream stream, .Encoding encoding, int bufferSize)
    {
        this(stream, encoding, bufferSize, false);
    }

    this(Stream stream, .Encoding encoding) 
    {
        this(stream, encoding, defaultBufferSize, false);
    }

    this(Stream stream)
    {
        this(stream, .Encoding.UTF8, defaultBufferSize, false);
    }

    override void Flush()
    {
        dump(true, false);
    }

    alias Write = TextWriter.Write;

    override void Write(wchar value)
    {
        checkStream();
        if (charBufferPos == bufferSize)
            dump(false, false);
        charBuffer[charBufferPos++] = value;
        if (autoFlush)
            dump(true, false);
    }

    @property bool AutoFlush()
    {
        return autoFlush;
    }

    @property bool AutoFlush(bool value)
    { 
        if (value)
            dump(true, false);
        return autoFlush = value;
    }

    override void Close()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    override void Dispose(bool disposing)
    {
        try
        {
            if (stream !is null && disposing)
                dump(true, true);
        }
        finally
        {
            if (!leaveOpen && stream !is null)
            {
                try
                {
                    if (disposing)
                        stream.Close();
                }
                finally
                {
                    stream = null;
                    byteBuffer = null;
                    charBuffer = null;
                    encoding = null;
                    encoder = null;
                    charBufferPos = 0;
                    super.Dispose(disposing);
                }
            }
        }
    }

    @property Stream BaseStream()
    {
        return stream;
    }

    override .Encoding Encoding()
    {
        return encoding;
    }

    override void Write(wchar[] buffer, int index, int count)
    {
        checkNull(buffer, "buffer");
        checkIndex(buffer, index, count);
        checkStream();
        while (count > 0)
        {
            if (charBufferPos == bufferSize)
                dump(false, false);
            auto charsAvailable = bufferSize - charBufferPos;
            if (charsAvailable > count)
                charsAvailable = count;
            charBuffer[charBufferPos .. charBufferPos + charsAvailable] = buffer[index .. index + charsAvailable];
            count -= charsAvailable;
            index += charsAvailable;
            charBufferPos += charsAvailable;
        }
        if (autoFlush)
            dump(true, false);
    }

    static @property Null()
    {
        return new StreamWriter(Stream.Null, new UTF8Encoding(false, true), minBufferSize, true);
    }
}