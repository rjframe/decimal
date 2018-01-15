import std.stdio;
import decimal;
import std.random;
import std.traits;
import std.math;
import std.typetuple;

D rnd(D)()
if (isDecimal!D)
{
    D result = D(rndGen.front - rndGen.min) / (rndGen.max - rndGen.min);
    rndGen.popFront();
    auto exponent = uniform(D.min_10_exp, D.max_10_exp - 1);
    result = ldexp(result, exponent);
    if (uniform(0, 2) == 1)
        result = -result;
    return result;
}

F rnd(F)()
if (isFloatingPoint!F)
{
    F result = F(rndGen.front - rndGen.min) / (rndGen.max - rndGen.min);
    rndGen.popFront();
    auto exponent = uniform(F.min_exp, F.max_exp - 1);
    result = ldexp(result, exponent);
    if (uniform(0, 2) == 1)
        result = -result;
    return result;
}

enum samples = 1000;

float[samples] float1;
float[samples] float2;
float[samples] float3;

double[samples] double1;
double[samples] double2;
double[samples] double3;

real[samples] real1;
real[samples] real2;
real[samples] real3;


decimal32[samples] d32_1;
decimal32[samples] d32_2;
decimal32[samples] d32_3;

decimal64[samples] d64_1;
decimal64[samples] d64_2;
decimal64[samples] d64_3;

decimal128[samples] d128_1;
decimal128[samples] d128_2;
decimal128[samples] d128_3;


template arr1(T)
{
    static if (is(T: float))
        alias arr1 = float1;
    else static if (is(T: double))
        alias arr1 = double1;
    else static if (is(T: real))
        alias arr1 = real1;
    else static if (is(T: decimal32))
        alias arr1 = d32_1;
    else static if (is(T: decimal64))
        alias arr1 = d64_1;
    else static if (is(T: decimal128))
        alias arr1 = d128_1;
    else
        static assert(0);
}

template arr2(T)
{
    static if (is(T: float))
        alias arr2 = float2;
    else static if (is(T: double))
        alias arr2 = double2;
    else static if (is(T: real))
        alias arr2 = real2;
    else static if (is(T: decimal32))
        alias arr2 = d32_2;
    else static if (is(T: decimal64))
        alias arr2 = d64_2;
    else static if (is(T: decimal128))
        alias arr2 = d128_2;
    else
        static assert(0);
}

template arr3(T)
{
    static if (is(T: float))
        alias arr3 = float3;
    else static if (is(T: double))
        alias arr3 = double3;
    else static if (is(T: real))
        alias arr3 = real3;
    else static if (is(T: decimal32))
        alias arr3 = d32_3;
    else static if (is(T: decimal64))
        alias arr3 = d64_3;
    else static if (is(T: decimal128))
        alias arr3 = d128_3;
    else
        static assert(0);
}

void randomize(T)(T[] a)
{
    for (size_t i = 0; i < samples; ++i)
        a[i] = rnd!T;
}

import std.stdio;
import decimal;
import std.math;
import std.range;

void dump(double angle)
{
    writefln("sin(%+2.1f): %+18.17f %+8.7f %+17.16f %+35.34f", angle,
             sin(angle), 
             sin(decimal32(angle)), 
             sin(decimal64(angle)), 
             sin(decimal128(angle)));
    writefln("cos(%+2.1f): %+18.17f %+8.7f %+17.16f %+35.34f", angle,
             cos(angle), 
             cos(decimal32(angle)), 
             cos(decimal64(angle)), 
             cos(decimal128(angle)));
    writefln("tan(%+2.1f): %+18.17f %+8.7f %+17.16f %+35.34f", angle,
             tan(angle), 
             tan(decimal32(angle)), 
             tan(decimal64(angle)), 
             tan(decimal128(angle)));
}

immutable size_t N = 100;

void unity (T) ()
{
    writeln ("\n=== ", T.stringof, " ===\n");
    immutable one = T (1);
    immutable two = T (2);
    immutable π = atan (one) * 4;
    writefln!"π = <%30.24f>" (π);

    foreach (i; iota(N + 1)) {
        auto φ = two * π * i / N;
        auto sinφ = sin (φ);
        auto cosφ = cos (φ);
        auto unity = sinφ * sinφ + cosφ * cosφ;
        auto δ = one - unity;
        writeln ("φ = <", φ, ">, δ = <", δ, ">");
    }
}


int main(string[] argv)
{

    //real r;
    //for (r = 1; r < 6; r += .1L) {
    //    decimal128 d = r;
    //    auto dsin = sin (d);
    //    auto rsin = sin (r);
    //    auto delta = dsin - rsin;
    //    writefln ("%9.2f %30.24f %30.24f %12.4g", r, rsin, dsin, delta);
    //}

    //real r;
    //for (r = 1; r < 6; r += .1L) {
    //    decimal128 d = r;
    //    auto dsin = sin (d);
    //    auto rsin = sin (r);
    //    auto delta = dsin - rsin;
    //    writefln ("%9.2f %+30.24f %+35.34f %+12.4g", r, rsin, dsin, delta);
    //}
    //
    //writefln("%35.34f", sin(decimal128(1)));
    //writefln("%35.34f", sin(decimal64(1)));
    //writefln("%35.34f", sin(decimal32(1)));
    //writefln("%35.34f", sin(cast(real)1.0));
    //writefln("%35.34f", sin(cast(double)1.0));
    //writefln("%35.34f", sin(cast(float)1.0));

    //writefln("%35.34f", sin(decimal32("5.7")));
    //writefln("%35.34f", sin(decimal64("5.7")));
    //writefln("%35.34f", sin(decimal128("5.7")));
    //
    //
    //writefln("%35.34f", sin(decimal32(5.7)));
    //writefln("%35.34f", sin(decimal64(5.7)));
    //writefln("%35.34f", sin(decimal128(5.7)));
    //
    //
    //writefln("%35.34f", decimal32(5.7));
    //writefln("%35.34f", decimal64(5.7));
    //writefln("%35.34f", decimal128(5.7));

    unity!decimal64;

    //decimal32 d;
    //if (d < 0)
    //    writeln ("< 0");
    //else
    //    writeln ("not < 0");

    //decimal32 d = "1";
    //auto p = 4 * d;
    //auto q = d * 4;
    //writeln (typeof(p).stringof);
    //writeln (typeof(q).stringof);

    real r;
    for (r = 1; r < 6; r += .1L) {
        decimal128 d = r;
        auto dsin = sin (d);
        auto rsin = sin (r);
        real delta = cast(real) dsin;
        delta -= rsin;
        writefln ("%9.2f %30.24f %30.24f %12.4g", r, rsin, dsin, delta);
    }

    decimal32 a = "-0.279415498198925875720000";
    decimal32 b = cast(real)-0.279415498198925875720000;
    writefln("%+35.34f %+35.34f", a, b);

    decimal32 c = cast(real)a;
    writefln("%+35.34f %+35.34f", c, a);

    writeln(real.sizeof);

    getchar();
    return 0;
}
