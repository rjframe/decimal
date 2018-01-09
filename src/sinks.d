module decimal.sinks;

private import std.format: FormatSpec;
private import std.traits: isSomeChar, Unqual;

private import decimal.integrals: prec, divrem, isAnyUnsigned;

package:

//dumps value to buffer right aligned, assumes buffer has enough space
int dumpUnsigned(C, T)(C[] buffer, auto const ref T value)
if (isSomeChar!C && isAnyUnsigned!T)
{
    assert(buffer.length >  0 && buffer.length >= prec(value));
    int i = cast(int)buffer.length;
    Unqual!T v = value;
    do
    {
        auto r = divrem(v, 10U);
        buffer[--i] = cast(C)(r + cast(uint)'0');
    } while (v);
    return buffer.length - i;
}

//dumps value to buffer right aligned, assumes buffer has enough space
int dumpUnsignedHex(C, T)(C[] buffer, auto const ref T value, const bool uppercase)
if (isSomeChar!C && isAnyUnsigned!T)
{
    assert(buffer.length >  0 && buffer.length >= prec(value));
    int i = cast(int)buffer.length;
    Unqual!T v = value;
    do
    {
        auto digit = (cast(uint)v & 0xFU);
        buffer[--i] = cast(C)(digit < 10 ? '0' + digit : 
                              (uppercase ? 'A' + (digit - 10) : 'a' + (digit - 10)));
        v >>= 4;
    } while (v);
    return buffer.length - i;
}

//repeats sinking of value count times using a default buffer size of 8
void sinkRepeat(int bufferSize = 8, C)(scope void delegate(const(C)[]) sink, const C value, const int count)
if (isSomeChar!C)
{
    if (!count)
        return;
    Unqual!C[bufferSize] buffer = value;
    int cnt = count;
    while (cnt > 0)
    {
        sink(buffer[0 .. cnt > bufferSize ? bufferSize : cnt]);
        cnt -= bufferSize;
    }
}

//sinks +/-/space
void sinkSign(C)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const bool signed)
if (isSomeChar!C)
{
    if (!signed && spec.flPlus)
        sink("+");
    else if (!signed && spec.flSpace)
        sink(" ");
    else if (signed)
        sink("-"); 
}

//pads left according to spec
void sinkPadLeft(C)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, ref int pad)
if (isSomeChar!C)
{
    if (pad > 0 && !spec.flDash && !spec.flZero)
    {
        sinkRepeat(sink, ' ', pad);
        pad = 0;
    }
}

//zero pads left according to spec
void sinkPadZero(C)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, ref int pad)
if (isSomeChar!C)
{
    if (pad > 0 && spec.flZero && !spec.flDash)
    {
        sinkRepeat(sink, '0', pad);
        pad = 0;
    }
}

//pads right according to spec
void sinkPadRight(C)(scope void delegate(const(C)[]) sink, ref int pad)
if (isSomeChar!C)
{
    if (pad > 0)
    {
        sinkRepeat(sink, ' ', pad);
        pad = 0;
    }
}

//sinks +/-(s)nan;
void sinkNaN(C)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const bool signed, 
                const bool signaling) 
if (isSomeChar!C)
{
    FormatSpec!C nanspec = spec;
    nanspec.flZero = false;
    nanspec.flHash = false;

    int w = signaling ? 4 : 3;                      
    if (nanspec.flPlus || nanspec.flSpace || signed)  
        ++w;
    int pad = nanspec.width - w;
    sinkPadLeft(nanspec, sink, pad);
    sinkSign(nanspec, sink, signed);
    if (signaling)
        sink(nanspec.spec < 'Z' ? "S" : "s");   
    sink(nanspec.spec < 'Z' ? "NAN" : "nan");  
    sinkPadRight(sink, pad);
}

//sinks +/-(s)inf;
void sinkInfinity(C)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const bool signed) 
if (isSomeChar!C)
{
    FormatSpec!C infspec = spec;
    infspec.flZero = false;
    infspec.flHash = false;

    int w = 3; 
    if (infspec.flPlus || infspec.flSpace || signed)
        ++w;
    int pad = infspec.width - w;
    sinkPadLeft(infspec, sink, pad);
    sinkSign(infspec, sink, signed);
    sink(infspec.spec < 'Z' ? "INF" : "inf");  
    sinkPadRight(sink, pad);
}

//sinks 0
void sinkZero(C)(auto const ref FormatSpec!C spec, scope void delegate(const(C)[]) sink, const bool signed, const bool skipTrailingZeros = false) 
if (isSomeChar!C)
{
    int requestedDecimals = spec.precision == spec.UNSPECIFIED || spec.precision < 0 ? 6 : spec.precision;

    if (skipTrailingZeros)
        requestedDecimals = 0;

    int w = requestedDecimals == 0 ? 1 : requestedDecimals + 2;

    if (requestedDecimals == 0 && spec.flHash)
        ++w;

    if (spec.flPlus || spec.flSpace || signed)
        ++w;
    int pad = spec.width - w;
    sinkPadLeft(spec, sink, pad);
    sinkSign(spec, sink, signed);
    sinkPadZero(spec, sink, pad);
    sink("0");
    if (requestedDecimals || spec.flHash)
    {
        sink(".");
        sinkRepeat(sink, '0', requestedDecimals);
    }
    sinkPadRight(sink, pad);
}


