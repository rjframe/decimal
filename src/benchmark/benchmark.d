import std.stdio;
import std.math;
import decimal;
import std.random;
import std.traits;
import std.typetuple;
import std.conv;
import std.datetime.stopwatch : benchmark, Duration;

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

T rnd(T)()
if (isIntegral!T)
{
    return uniform!"[]"(T.min, T.max);
}

string prettyName(T)()
{
    static if (is(T: decimal32))
        return "decimal32";
    else static if (is(T: decimal64))
        return "decimal64";
    else static if (is(T: decimal128))
        return "decimal128";
    else return T.stringof;
}

alias BinaryFloats = TypeTuple!(float, double, real);
alias DecimalFloats = TypeTuple!(decimal32, decimal64, decimal128);
alias AllFloats = TypeTuple!(DecimalFloats, BinaryFloats);

alias Integrals = TypeTuple!(byte, short, int, long, ubyte, ushort, uint, ulong);

string arraystr(T, int a)()
{
    return prettyName!T ~ "_" ~ to!string(a);
}

enum samples = 1000;

static foreach(T; AllFloats)
{
    mixin(prettyName!T ~ "[samples] " ~ arraystr!(T, 1) ~ ";");
    mixin(prettyName!T ~ "[samples] " ~ arraystr!(T, 2) ~ ";");
    mixin(prettyName!T ~ "[samples] " ~ arraystr!(T, 3) ~ ";");
}

mixin(prettyName!bool ~ "[samples] " ~ arraystr!(bool, 1) ~ ";");

static foreach(T; Integrals)
{
    mixin(prettyName!T ~ "[samples] " ~ arraystr!(T, 1) ~ ";");
}

template arr(T, int a)
{
    mixin("alias arr = " ~ arraystr!(T, a) ~ ";");
}


void bench1(R, I, string func)()
{
    for (int i = 0; i < samples; ++i)
        mixin(arraystr!(R, 1)() ~ "[i] = " ~ func ~ "(" ~ arraystr!(I, 2)() ~ "[i]);");
}

void benchbinop(R, I, string op)()
{
    for (int i = 0; i < samples; ++i)
        mixin(arraystr!(R, 1)() ~ "[i] = " ~ arraystr!(I, 2)() ~ "[i] " ~ op ~ arraystr!(I, 3)() ~ "[i];");
}

void benchconstructor(R, I)()
{
    for (int i = 0; i < samples; ++i)
        mixin(arraystr!(R, 1)() ~ "[i] = " ~ R.stringof ~ "(" ~ arraystr!(I, 1)() ~ "[i]);");
}

auto benchx1(R, string func)()
{
    randomize!(decimal32, 2)();
    randomize!(decimal64, 2)();
    randomize!(decimal128, 2)();
    randomize!(float, 2)();
    randomize!(double, 2)();
    randomize!(real, 2)();

    static if (is(R == void))
    {
        return benchmark!(bench1!(decimal32, decimal32, func), 
                          bench1!(decimal64, decimal64, func),
                          bench1!(decimal128, decimal128, func),
                          bench1!(float, float, func),
                          bench1!(double, double, func),
                          bench1!(real, real, func))(10);
    }
    else
    {

        return benchmark!(bench1!(R, decimal32, func), 
                            bench1!(R, decimal64, func),
                            bench1!(R, decimal128, func),
                            bench1!(R, float, func),
                            bench1!(R, double, func),
                            bench1!(R, real, func))(10);
    }    
}

auto benchxconstructor(I)()
{
    randomize!(I, 1)();

    return benchmark!(benchconstructor!(decimal32, I), 
                      benchconstructor!(decimal64, I), 
                      benchconstructor!(decimal128, I), 
                      benchconstructor!(float, I), 
                      benchconstructor!(double, I),
                      benchconstructor!(real, I))(10);
  
}


auto benchxbinop(R, string op)()
{
    randomize!(decimal32, 2)();
    randomize!(decimal64, 2)();
    randomize!(decimal128, 2)();
    randomize!(float, 2)();
    randomize!(double, 2)();
    randomize!(real, 2)();

    randomize!(decimal32, 3)();
    randomize!(decimal64, 3)();
    randomize!(decimal128, 3)();
    randomize!(float, 3)();
    randomize!(double, 3)();
    randomize!(real, 3)();

    static if (is(R == void))
    {
        return benchmark!(benchbinop!(decimal32, decimal32, op), 
                          benchbinop!(decimal64, decimal64, op),
                          benchbinop!(decimal128, decimal128, op),
                          benchbinop!(float, float, op),
                          benchbinop!(double, double, op),
                          benchbinop!(real, real, op))(10);
    }
    else
    {

        return benchmark!(benchbinop!(R, decimal32, op), 
                          benchbinop!(R, decimal64, op),
                          benchbinop!(R, decimal128, op),
                          benchbinop!(R, float, op),
                          benchbinop!(R, double, op),
                          benchbinop!(R, real, op))(10);
    }


}

void randomize(T, int a)()
{
    for (int i = 0; i < samples; ++i)
        mixin(arraystr!(T, a)() ~ "[i] = rnd!T();");    
}

void dumpHeader(string title)
{
    writef("%-17s", title);
    foreach(T; AllFloats)
        writef("%17s", prettyName!T);
    writeln();
}

void dumpResults(string title, Duration[] results)
{
    auto min = results[0].total!"hnsecs";
    foreach (r; results)
        if (r.total!"hnsecs" < min)
            min = r.total!"hnsecs";

    writef("%-17s", title);

    for (int i = 0; i < results.length; ++i)
        writef("%17.2f", results[i].total!"hnsecs" / cast(double)min);

    writeln();
}

int main(string[] argv)
{
    dumpHeader("Non-computational");

    //dumpResults("fabs", benchx1!(void, "fabs"));
    //dumpResults("negate", benchx1!(void, "-"));
   // dumpResults("isNaN", benchx1!(bool, "isNaN"));
//    dumpResults("isFinite", benchx1!(bool, "isFinite"));
    //dumpResults("isInfinity", benchx1!(bool, "isInfinity"));
    //dumpResults("isNormal", benchx1!(bool, "isNormal"));
    //dumpResults("isSubnormal", benchx1!(bool, "isSubnormal"));
    //dumpResults("increment", benchx1!(void, "++"));
    //dumpResults("decrement", benchx1!(void, "--"));
    //dumpResults("sgn", benchx1!(void, "sgn"));

    writeln();
    dumpHeader("Basic operations");
    dumpResults("comparison", benchxbinop!(bool, "<"));
    dumpResults("equality", benchxbinop!(bool, "=="));
    dumpResults("increment", benchx1!(void, "++"));
    dumpResults("decrement", benchx1!(void, "--"));
    dumpResults("addition", benchxbinop!(void, "+"));
    dumpResults("substraction", benchxbinop!(void, "-"));
    dumpResults("multiplication", benchxbinop!(void, "*"));
    dumpResults("division", benchxbinop!(void, "/"));
    dumpResults("modulo", benchxbinop!(void, "%"));

    //writeln();
    //dumpHeader("Constructors");
    //dumpResults("from int", benchxconstructor!int);
    //dumpResults("from uint", benchxconstructor!uint);
    //dumpResults("from long", benchxconstructor!long);
    //dumpResults("from ulong", benchxconstructor!ulong);
    //
    //
    //writeln();
    //dumpHeader("Rounding");
    //dumpResults("ceil", benchx1!(void, "ceil"));
    //dumpResults("floor", benchx1!(void, "floor"));
    //dumpResults("round", benchx1!(void, "round"));
    //dumpResults("trunc", benchx1!(void, "trunc"));
    //dumpResults("rint", benchx1!(void, "rint"));
    ////dumpResults("nearbyint", benchx1!(void, "nearbyint"));
    //dumpResults("lrint", benchx1!(long, "lrint"));
    ////dumpResults("rndtonl", benchx1!(void, "rndtonl"));
    //
    //writeln();
    //dumpHeader("Trigonometry");
    //dumpResults("sin", benchx1!(void, "sin"));
    //dumpResults("cos", benchx1!(void, "cos"));
    //dumpResults("tan", benchx1!(void, "tan"));
    //dumpResults("asin", benchx1!(void, "asin"));
    //dumpResults("acos", benchx1!(void, "acos"));
    ////dumpResults("atan", benchx1!(void, "atan"));
    //dumpResults("sinh", benchx1!(void, "sinh"));
    //dumpResults("cosh", benchx1!(void, "cosh"));
    //dumpResults("tanh", benchx1!(void, "tanh"));
    ////dumpResults("asinh", benchx1!(void, "asinh"));
    ////dumpResults("acosh", benchx1!(void, "acosh"));
    ////dumpResults("atanh", benchx1!(void, "atanh"));
    //
    //writeln();
    //dumpHeader("Exponentiation");
    //dumpResults("exp", benchx1!(void, "exp"));
    //dumpResults("exp2", benchx1!(void, "exp2"));
    //dumpResults("expm1", benchx1!(void, "expm1"));
    //dumpResults("log", benchx1!(void, "log"));
    //dumpResults("log2", benchx1!(void, "log2"));
    ////dumpResults("log10", benchx1!(void, "log10"));
    //dumpResults("ilogb", benchx1!(int, "ilogb"));
    //dumpResults("sqrt", benchx1!(void, "sqrt"));
    //
    //writeln();
    //dumpHeader("Operations");
    //dumpResults("nextDown", benchx1!(void, "nextDown"));
    //dumpResults("nextUp", benchx1!(void, "nextUp"));
    getchar();
    return 0;
}
