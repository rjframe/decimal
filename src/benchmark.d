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

int main(string[] argv)
{
    foreach(T; TypeTuple!(float, double, real, decimal32, decimal64, decimal128))
    {
        randomize(arr1!T);
        randomize(arr2!T);
    }

    getchar();
    return 0;
}
