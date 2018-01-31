module test;

import std.stdio;
import decimal;
import std.math;
import std.traits;
import std.string;
import std.conv;
import std.path;
import std.file;
import std.algorithm;
import std.typetuple;
import std.range;



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

string prettyRounding(RoundingMode mode)
{
    switch (mode)
    {
        case RoundingMode.tiesToAway:
            return "RoundingMode.tiesToAway";
        case RoundingMode.tiesToEven:
            return "RoundingMode.tiesToEven";
        case RoundingMode.towardNegative:
            return "RoundingMode.towardNegative";
        case RoundingMode.towardPositive:
            return "RoundingMode.towardPositive";
        case RoundingMode.towardZero:
            return "RoundingMode.towardZero";
        default:
            return "";
    }
}

string prettyClass(int cls)
{
    switch(cls)
    {
        case 0: return "DecimalClass.signalingNaN";
        case 1: return "DecimalClass.quietNaN";
        case 2: return "DecimalClass.negativeInfinity";
        case 3: return "DecimalClass.negativeNormal";
        case 4: return "DecimalClass.negativeSubnormal";
        case 5: return "DecimalClass.negativeZero";
        case 6: return "DecimalClass.positiveZero";
        case 7: return "DecimalClass.positiveSubnormal";
        case 8: return "DecimalClass.positiveNormal";
        case 9: return "DecimalClass.positiveInfinity";
        default: return "";
    }
}


string prettyFlags(ExceptionFlags flags)
{
    if (flags == ExceptionFlags.none)
        return "ExceptionFlags.none";
    string r;
    if (flags & ExceptionFlags.invalidOperation)
        r = "ExceptionFlags.invalidOperation";
    if (flags & ExceptionFlags.overflow)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.overflow";
    }
    if (flags & ExceptionFlags.divisionByZero)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.divisionByZero";
    }
    if (flags & ExceptionFlags.underflow)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.underflow";
    }
    if (flags & ExceptionFlags.inexact)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.inexact";
    }


    return r.idup;
}

string prettyFlagsIntel(int flags)
{
    if (flags == 0)
        return "ExceptionFlags.none";
    string r;
    if (flags & 1)
        r = "ExceptionFlags.invalidOperation";
    if (flags & 8)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.overflow";
    }
    if (flags & 4)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.divisionByZero";
    }
    if (flags & 0x10)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.underflow";
    }
    if (flags & 0x20)
    {
        if (r.length > 0) r ~= " | ";
        r ~= "ExceptionFlags.inexact";
    }


    return r.idup;
}

string getRoundingMode(char[] s)
{
    switch (s)
    {
        case "0": return "RoundingMode.tiesToEven";
        case "1": return "RoundingMode.towardNegative";
        case "2": return "RoundingMode.towardPositive";
        case "3": return "RoundingMode.towardZero";
        case "4": return "RoundingMode.tiesToAway";
        default: return "";
    }
}

string getToken(int type, char[] s, bool raw = false)
{
    switch (type)
    {
        case refint: 
        case inint:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!int(t, 16));
            }
            else
                return s.idup;
        case inlong:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!long(t, 16));
            }
            else
                return s.idup;
        case inuint:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!uint(t, 16));
            }
            else
                return s.idup;
        case inulong:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!ulong(t, 16));
            }
            else
                return s.idup;
        case inshort:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!short(t, 16));
            }
            else
                return s.idup;
        case inbyte:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!byte(t, 16));
            }
            else
                return s.idup;
        case inushort:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!ushort(t, 16));
            }
            else
                return s.idup;
        case inubyte:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                return to!string(parse!ubyte(t, 16));
            }
            else
                return s.idup;
        case infloat:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                uint data = parse!uint(t, 16);
                float f;
                *cast(uint*)&f = data;
                return format("%a", f);
            }
            else
                return s.idup;
        case indouble:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                ulong data = parse!ulong(t, 16);
                double f;
                *cast(ulong*)&f = data;
                return format("%a", f);
            }
            else
                return s.idup;
        case inreal:
            if (s[0] == '[')
            {
                ushort[5] shorts;
                auto t = s[1 .. 5];
                shorts[4] = parse!ushort(t, 16);
                t = s[5 .. 9];
                shorts[3] = parse!ushort(t, 16);
                t = s[9 .. 13];
                shorts[2] = parse!ushort(t, 16);
                t = s[13 .. 17];
                shorts[1] = parse!ushort(t, 16);
                t = s[17 .. $ - 1];
                shorts[0] = parse!ushort(t, 16);
                real f;
                *cast(ushort[5]*)&f = shorts;
                return format("%a", f);
            }
            else
                return s.idup;
        case dpd32:
        case dpd64:
        case dpd128:
            return s[1 .. $ - 1].idup;
        case instring:
            return s.idup;
        case inclass:
            return prettyClass(to!int(s));
        case 7:
            if (s == "0")
                return "false";
            if (s == "1")
                return "true";
            return "";
        case 32:
        case r32:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                uint data = parse!uint(t, 16);
                if (raw)
                    return format("0h%08X", data);
                decimal32 d;
                *cast(uint*)&d = data;
                return d.toString("%+.6e");
            }
            else
                return decimal32(s).toString("%+.6e");
        case 64:
        case r64:
            if (s[0] == '[')
            {
                auto t = s[1 .. $ - 1];
                ulong data = parse!ulong(t, 16);
                decimal64 d;
                *cast(ulong*)&d = data;
                return d.toString("%+.14e");
            }
            else
                return decimal64(s).toString("%+.14e");
        case 128:
        case r128:
            if (s[0] == '[' && indexOf(s, ",") < 0)
            {
                auto t = s[1 .. 17];
                ulong hi = parse!ulong(t, 16);
                t = s[17 .. $ - 1];
                ulong lo = parse!ulong(t, 16);
                decimal128 d;
                *cast(ulong[2]*)&d = [lo, hi];
                return d.toString("%+.33e");
            }
            else if (s[0] == '[')
            {
                auto v = indexOf(s, ",");
                auto t = s[1 .. v];
                ulong hi = parse!ulong(t, 16);
                t = s[v + 1 .. $ - 1];
                ulong lo = parse!ulong(t, 16);
                decimal128 d;
                *cast(ulong[2]*)&d = [lo, hi];
                return d.toString("%+.33e");
            }
            else
                return decimal128(s).toString("%+.33e");
        default:
            return "";

    }
}

struct IntelFunc
{
    string name;
    int params;
    int bitsResult;
    int bits1;
    int bits2;
    int bits3;
    RoundingMode mode;
}

struct TestData
{
    int type1, type2, type3, typeResult;
    string func;
    string op1, op2, op3, result;
    string rm;
    string expected;
    string ofunc;

    int opCmp(const ref TestData other) const
    {
        if (this.func > other.func)
            return 1;
        if (this.func < other.func)
            return -1;
        if (this.type1 > other.type1)
            return 1;
        if (this.type1 < other.type1)
            return -1;
        if (this.type2 > other.type2)
            return 1;
        if (this.type2 < other.type2)
            return -1;
        if (this.type3 > other.type3)
            return 1;
        if (this.type3 < other.type3)
            return -1;
        if (this.typeResult > other.typeResult)
            return 1;
        if (this.typeResult < other.typeResult)
            return -1;
        return 0;
    }

    bool opEquals(const ref TestData other) const
    {
        return this.func == other.func && this.type1 == other.type1 && this.type1 == other.type1 && this.type3 == other.type3 && this.typeResult == other.typeResult
            && this.op1 == other.op1 && this.op2 == other.op2 && this.op3 == other.op3 && this.result == other.result && this.rm == other.rm;
    }

    string key()
    {
        string r;
        auto t = prettyType(type1);
        if (t.length)
            r ~= t;
        t = prettyType(type2);
        if (t.length)
            r ~= r.length ? ", " ~ t : t;
        t = prettyType(type3);
        if (t.length)
            r ~= r.length ? ", " ~ t : t;
        t = prettyType(typeResult);
        return (t.length ? t : "void") ~ " " ~ func ~ "(" ~ r ~ ")";
    }   

    string assertion(string tabs)
    {
        string a = tabs ~ "DecimalControl.rounding = s.rounding;\n" ~ tabs;
        string r;

        if (func == "add")
        {
            r = format("%s + %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " + " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, expected))";
        }
        else if (func == "mul")
        {
            r = format("%s * %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " * " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, expected))";
        }
        else if (func == "sub")
        {
            r = format("%s - %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " - " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, expected))";
        }
        else if (func == "div")
        {
            r = format("%s / %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " / " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, expected))";
        }
        else if (func == "mod")
        {
            r = format("%s %% %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " %% " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, expected))";
        }
        else if (func == "pow")
        {
            r = format("%s ^^ %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " ^^ " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, expected))";
        }
        else if (func == "equ")
        {
            r = format("%s == %s", prettyConstruct(type1, "s.x"), prettyConstruct(type2, "s.y"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == s.result, format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " == " ~ prettyFmt(type2) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", " ~ prettyConstruct(type2, "s.y") ~ ", r, s.result))";
        }
        else if (func == "constructor")
        {
            r = prettyConstruct(typeResult, prettyConstruct(type1, "s.x"));
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyType(typeResult) ~ "(" ~ prettyFmt(type1) ~ ") != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", r, expected))";
        }
        else if (func == "copy")
        {
            r = prettyConstruct(type1, "s.x");
            a ~= "auto r = " ~ r ~ ";";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
            a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(expected) && isNaN(r)), format(\"Test %6d failed, " ~ prettyFmt(type1) ~ " != " ~ prettyFmt(typeResult) ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ prettyConstruct(type1, "s.x") ~ ", r, expected))";
        }
        else
        {
            if (type1 != 0)
                r ~= prettyConstruct(type1, "s.x");
            if (type2 != 0)
                r ~= r.length ? ", " ~ prettyConstruct(type2, "s.y") : prettyConstruct(type2, "s.y");
            if (type3 != 0)
                r ~= r.length ? ", " ~ prettyConstruct(type3, "s.z") : prettyConstruct(type3, "s.z");
            if (typeResult != 0)
                a ~= "auto r = " ~ func ~ "(" ~ r ~ ");";
            else
                a ~= func ~ "(" ~ r ~ ");";
            a ~= "\n" ~ tabs ~ "auto flags = DecimalControl.saveFlags;";
            if (typeResult != 0)
            {
                string f;
                if (type1 != 0)
                    f ~= prettyFmt(type1);
                if (type2 != 0)
                    f ~= f.length ? ", " ~ prettyFmt(type2) : prettyFmt(type2);
                if (type3 != 0)
                    f ~= f.length ? ", " ~ prettyFmt(type3) : prettyFmt(type3);
                f = func ~ "(" ~ f ~ ") != " ~ prettyFmt(typeResult);
                if (typeResult == 32 || typeResult == 64 || typeResult == 128)
                {
                    a ~= "\n" ~ tabs ~ "auto expected = " ~ prettyConstruct(typeResult, "s.result") ~ ";";
                    a ~= "\n" ~ tabs ~ "assert (r == expected || (isNaN(r) && isNaN(expected)), format(\"Test %6d failed, " ~ f ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ r ~ ", r, expected))";
                }
                else
                    a ~= "\n" ~ tabs ~ "assert ((r == " ~ prettyConstruct(typeResult, "s.result") ~ ", format(\"Test %6d failed, " ~ f ~ ", expected: " ~ prettyFmt(typeResult) ~ "\", s.id, " ~ r ~ ", r, " ~ prettyConstruct(typeResult, "s.result") ~ "))";
            }
            
        }

        

        
        

        if (func != "equ")
            a ~= "\n" ~ tabs ~ "assert (flags == s.expectedFlags, format(\"Test %6d failed for flags: result: %d, expected: %d\", flags, s.expectedFlags))";        
        return a;


    }

    string dump(int id)
    {
        string a = "S(" ~ format("%6d, ", id);
        string r;
        if (type1 != 0)
            r ~= prettyVal(type1, op1);
        if (type2 != 0)
            r ~= r.length ? ", " ~ prettyVal(type2, op2) : prettyVal(type2, op2);
        if (type3 != 0)
            r ~= r.length ? ", " ~ prettyVal(type3, op3) : prettyVal(type3, op3);
        if (typeResult != 0)
            r ~= r.length ? ", " ~ prettyVal(typeResult, result) : prettyVal(typeResult, result);

        a ~= r;

        if (func != "equ")
        {
            a ~= ", " ~ prettyVal(inrounding, rm);
            a ~= ", " ~ expected;
        }

        a ~= "),";
        return a;
    }
}


string prettyConstruct(int type, string s)
{
    switch(type)
    {
        case refint:
        case inint:
        case inuint:
            return s;
        case instring:
            return s;
        case inulong:
            return s;
        case inlong:
            return s;
        case inbool:
            return s;
        case infloat:
            return s;
        case indouble:
            return s;
        case inreal:
            return s;
        case inrounding:
            return s;
        case inbyte:
            return s;
        case inshort:
            return s;
        case inubyte:
            return s;
        case inushort:
            return s;
        case 32:
        case r32:
            return format("decimal32(%s)", s);
        case dpd32:
            return s;
        case 64:
        case r64:
            return format("decimal64(%s)", s);
        case dpd64:
            return s;
        case 128:
        case r128:
            return format("decimal128(%s)", s);
        case dpd128:
            return s;
        case inclass:
            return s;
        default:
            return s;      
    }
}

string prettyType(int type)
{
    switch(type)
    {
        case refint:
        case inint:
            return "int";
        case instring:
            return "string";
        case inuint:
            return "uint";
        case inulong:
            return "ulong";
        case inlong:
            return "long";
        case inbool:
            return "bool";
        case infloat:
            return "float";
        case indouble:
            return "double";
        case inreal:
            return "real";
        case inrounding:
            return "RoundingMode";
        case inbyte:
            return "byte";
        case inshort:
            return "short";
        case inubyte:
            return "ubyte";
        case inushort:
            return "ushort";
        case 32:
        case r32:
        case dpd32:
            return "decimal32";
        case 64:
        case r64:
        case dpd64:
            return "decimal64";
        case 128:
        case r128:
        case dpd128:
            return "decimal128";
        case inclass:
            return "DecimalClass";
        default:
            return "";
    }
}

string prettyTypeX(int type)
{
    switch(type)
    {
        case refint:
        case inint:
            return "int";
        case instring:
            return "string";
        case inuint:
            return "uint";
        case inulong:
            return "ulong";
        case inlong:
            return "long";
        case inbool:
            return "bool";
        case infloat:
            return "float";
        case indouble:
            return "double";
        case inreal:
            return "real";
        case inrounding:
            return "RoundingMode";
        case inbyte:
            return "byte";
        case inshort:
            return "short";
        case inubyte:
            return "ubyte";
        case inushort:
            return "ushort";
        case 32:
        case r32:
        case dpd32:
            return "string";
        case 64:
        case r64:
        case dpd64:
            return "string";
        case 128:
        case r128:
        case dpd128:
            return "string";
        case inclass:
            return "DecimalClass";
        default:
            return "";
    }
}

string prettyFmt(int type)
{
    switch(type)
    {
        case refint:
        case inint:
            return "%d";
        case instring:
            return "%s";
        case inuint:
            return "%d";
        case inulong:
            return "%d";
        case inlong:
            return "%d";
        case inbool:
            return "%s";
        case infloat:
            return "%.8e";
        case indouble:
            return "%.17e";
        case inreal:
            return "%.20e";
        case inrounding:
            return "%s";
        case inbyte:
            return "%d";
        case inshort:
            return "%d";
        case inubyte:
            return "%d";
        case inushort:
            return "%d";
        case 32:
        case r32:
        case dpd32:
            return "%.6e";
        case 64:
        case r64:
        case dpd64:
            return "%.14e";
        case 128:
        case r128:
        case dpd128:
            return "%.33e";
        case inclass:
            return "%d";
        default:
            return "";
    }
}

string prettyVal(int type, string s)
{
    switch(type)
    {
        case refint:
        case inint:
        case inuint:
            return format("%11s", s);
        case instring:
            return format("\"%s\"", s);
        case inulong:
            return format("%20s", s);
        case inlong:
            return format("%20s", s);
        case inbool:
            return format("%6s", s);
        case infloat:
            if (s == "+inf" || s == "inf")
                return format("%16s", "+float.infinity");
            else if (s == "-inf")
                return format("%16s", "-float.infinity");
            else if (s == "+nan" || s == "nan")
                return format("%16s", "+float.nan");
            else if (s == "-nan")
                return format("%16s", "-float.nan");
            return format("%16s", s);
        case indouble:
            if (s == "+inf" || s == "inf")
                return format("%24s", "+double.infinity");
            else if (s == "-inf")
                return format("%24s", "-double.infinity");
            else if (s == "+nan" || s == "nan")
                return format("%24s", "+double.nan");
            else if (s == "-nan")
                return format("%24s", "-double.nan");
            return format("%24s", s);
        case inreal:
            if (s == "+inf" || s == "inf")
                return format("%28s", "+real.infinity");
            else if (s == "-inf")
                return format("%28s", "-real.infinity");
            else if (s == "+nan" || s == "nan")
                return format("%28s", "+real.nan");
            else if (s == "-nan")
                return format("%28s", "-real.nan");
            return format("%28s", s);
        case inrounding:
            return format("%-27s", s);
        case inbyte:
            return format("%4s", s);
        case inshort:
            return format("%6s", s);
        case inubyte:
            return format("%4s", s);
        case inushort:
            return format("%6s", s);
        case 32:
        case r32:
        case dpd32:
            return format("%16s", "\"" ~ s ~ "\"");
        case 64:
        case r64:
        case dpd64:
            return format("%24s", "\"" ~ s ~ "\"");
        case 128:
        case r128:
        case dpd128:
            return format("%44s", "\"" ~ s ~ "\"");
        case inclass:
            return format("%30s", s);
        default:
            return "";
    }
}

enum refint = 1;
enum inint = 2;
enum inlong = 3;
enum instring = 4;
enum inuint = 5;
enum inulong = 6;
enum inbool = 7;
enum infloat = 8;
enum indouble = 9;
enum inreal = 10;
enum inrounding = 11;
enum inbyte = 12;
enum inshort = 13;
enum inubyte = 14;
enum inushort = 15;
enum r32 = 16;
enum r64 = 17;
enum r128 = 18;
enum inclass = 19;
enum dpd32 = 20;
enum dpd64 = 21;
enum dpd128 = 22;

int main(string[] argv)
{

    
    TestData[] tests;


    IntelFunc[string] funcs;
    
    funcs["bid32_abs"] = IntelFunc("fabs", 2, 32, 32);
    funcs["bid64_abs"] = IntelFunc("fabs", 2, 64, 64);
    funcs["bid128_abs"] = IntelFunc("fabs", 2, 128, 128);
    funcs["bid32_acos"] = IntelFunc("acos", 2, 32, 32);
    funcs["bid64_acos"] = IntelFunc("acos", 2, 64, 64);
    funcs["bid128_acos"] = IntelFunc("acos", 2, 128, 128);
    funcs["bid32_acosh"] = IntelFunc("acosh", 2, 32, 32);
    funcs["bid64_acosh"] = IntelFunc("acosh", 2, 64, 64);
    funcs["bid128_acosh"] = IntelFunc("acosh", 2, 128, 128);
    funcs["bid32_asin"] = IntelFunc("asin", 2, 32, 32);
    funcs["bid64_asin"] = IntelFunc("asin", 2, 64, 64);
    funcs["bid128_asin"] = IntelFunc("asin", 2, 128, 128);
    funcs["bid32_asinh"] = IntelFunc("asinh", 2, 32, 32);
    funcs["bid64_asinh"] = IntelFunc("asinh", 2, 64, 64);
    funcs["bid128_asinh"] = IntelFunc("asinh", 2, 128, 128);
    funcs["bid32_atan"] = IntelFunc("atan", 2, 32, 32);
    funcs["bid64_atan"] = IntelFunc("atan", 2, 64, 64);
    funcs["bid128_atan"] = IntelFunc("atan", 2, 128, 128);
    funcs["bid32_atan2"] = IntelFunc("atan2", 3, 32, 32, 32);
    funcs["bid64_atan2"] = IntelFunc("atan2", 3, 64, 64, 64);
    funcs["bid128_atan2"] = IntelFunc("atan2", 3, 128, 128, 128);
    funcs["bid32_atanh"] = IntelFunc("atanh", 2, 32, 32);
    funcs["bid64_atanh"] = IntelFunc("atanh", 2, 64, 64);
    funcs["bid128_atanh"] = IntelFunc("atanh", 2, 128, 128);
    funcs["bid32_cbrt"] = IntelFunc("cbrt", 2, 32, 32);
    funcs["bid64_cbrt"] = IntelFunc("cbrt", 2, 64, 64);
    funcs["bid128_cbrt"] = IntelFunc("cbrt", 2, 128, 128);
    funcs["bid32_class"] = IntelFunc("decimalClass", 2, inclass, 32);
    funcs["bid64_class"] = IntelFunc("decimalClass", 2, inclass, 64);
    funcs["bid128_class"] = IntelFunc("decimalClass", 2, inclass, 128);
    funcs["bid32_copy"] = IntelFunc("copy", 2, 32, 32);
    funcs["bid64_copy"] = IntelFunc("copy", 2, 64, 64);
    funcs["bid128_copy"] = IntelFunc("copy", 2, 128, 128);
    funcs["bid32_copySign"] = IntelFunc("copysign", 3, 32, 32, 32);
    funcs["bid64_copySign"] = IntelFunc("copysign", 3, 64, 64, 64);
    funcs["bid128_copySign"] = IntelFunc("copysign", 3, 128, 128, 128);
    funcs["bid32_cos"] = IntelFunc("cos", 2, 32, 32);
    funcs["bid64_cos"] = IntelFunc("cos", 2, 64, 64);
    funcs["bid128_cos"] = IntelFunc("cos", 2, 128, 128);
    funcs["bid32_cosh"] = IntelFunc("cosh", 2, 32, 32);
    funcs["bid64_cosh"] = IntelFunc("cosh", 2, 64, 64);
    funcs["bid128_cosh"] = IntelFunc("cosh", 2, 128, 128);
    funcs["bid128dd_add"] = IntelFunc("", 3, 128, 64, 64);
    funcs["bid128dd_sub"] = IntelFunc("", 3, 128, 64, 64);
    funcs["bid128dd_mul"] = IntelFunc("", 3, 128, 64, 64);
    funcs["bid128dd_div"] = IntelFunc("", 3, 128, 64, 64);
    funcs["bid128dd_mod"] = IntelFunc("", 3, 128, 64, 64);
    funcs["bid128dq_add"] = IntelFunc("add", 3, 128, 64, 128);
    funcs["bid128dq_sub"] = IntelFunc("sub", 3, 128, 64, 128);
    funcs["bid128dq_mul"] = IntelFunc("mul", 3, 128, 64, 128);
    funcs["bid128dq_div"] = IntelFunc("div", 3, 128, 64, 128);
    funcs["bid128dq_mod"] = IntelFunc("mod", 3, 128, 64, 128);
    funcs["bid128d_sqrt"] = IntelFunc("sqrt", 2, 128, 64);
    funcs["bid32_sqrt"] = IntelFunc("sqrt", 2, 32, 32);
    funcs["bid64_sqrt"] = IntelFunc("sqrt", 2, 64, 64);
    funcs["bid128_sqrt"] = IntelFunc("sqrt", 2, 128, 128);
    funcs["bid128ddd_fma"] = IntelFunc("", 4, 128, 64, 64, 64);
    funcs["bid128ddq_fma"] = IntelFunc("fma", 4, 128, 64, 64, 128);
    funcs["bid128dqd_fma"] = IntelFunc("fma", 4, 128, 64, 128, 64);
    funcs["bid128dqq_fma"] = IntelFunc("fma", 4, 128, 64, 128, 128);
    funcs["bid32_erf"] = IntelFunc("erf", 2, 32, 32);
    funcs["bid64_erf"] = IntelFunc("erf", 2, 64, 64);
    funcs["bid128_erf"] = IntelFunc("erf", 2, 128, 128);
    funcs["bid32_erfc"] = IntelFunc("erfc", 2, 32, 32);
    funcs["bid64_erfc"] = IntelFunc("erfc", 2, 64, 64);
    funcs["bid128_erfc"] = IntelFunc("erfc", 2, 128, 128);
    funcs["bid32_exp"] = IntelFunc("exp", 2, 32, 32);
    funcs["bid64_exp"] = IntelFunc("exp", 2, 64, 64);
    funcs["bid128_exp"] = IntelFunc("exp", 2, 128, 128);
    funcs["bid32_exp10"] = IntelFunc("exp10", 2, 32, 32);
    funcs["bid64_exp10"] = IntelFunc("exp10", 2, 64, 64);
    funcs["bid128_exp10"] = IntelFunc("exp10", 2, 128, 128);
    funcs["bid32_exp2"] = IntelFunc("exp2", 2, 32, 32);
    funcs["bid64_exp2"] = IntelFunc("exp2", 2, 64, 64);
    funcs["bid128_exp2"] = IntelFunc("exp2", 2, 128, 128);
    funcs["bid32_expm1"] = IntelFunc("expm1", 2, 32, 32);
    funcs["bid64_expm1"] = IntelFunc("expm1", 2, 64, 64);
    funcs["bid128_expm1"] = IntelFunc("expm1", 2, 128, 128);
    funcs["bid32_fdim"] = IntelFunc("fdim", 3, 32, 32, 32);
    funcs["bid64_fdim"] = IntelFunc("fdim", 3, 64, 64, 64);
    funcs["bid128_fdim"] = IntelFunc("fdim", 3, 128, 128, 128);
    funcs["bid32_fma"] = IntelFunc("fma", 4, 32, 32, 32, 32);
    funcs["bid64_fma"] = IntelFunc("fma", 4, 64, 64, 64, 64);
    funcs["bid128_fma"] = IntelFunc("fma", 4, 128, 128, 128, 128);
    funcs["bid32_fmod"] = IntelFunc("fmod", 3, 32, 32, 32);
    funcs["bid64_fmod"] = IntelFunc("fmod", 3, 64, 64, 64);
    funcs["bid128_fmod"] = IntelFunc("fmod", 3, 128, 128, 128);
    funcs["bid32_frexp"] = IntelFunc("frexp", 3, 32, 32, refint);
    funcs["bid64_frexp"] = IntelFunc("frexp", 3, 64, 64, refint);
    funcs["bid128_frexp"] = IntelFunc("frexp", 3, 128, 128, refint);
    funcs["bid32_from_int32"] = IntelFunc("constructor", 2, 32, inint);
    funcs["bid64_from_int32"] = IntelFunc("constructor", 2, 64, inint);
    funcs["bid128_from_int32"] = IntelFunc("constructor", 2, 128, inint);
    funcs["bid32_from_int64"] = IntelFunc("constructor", 2, 32, inlong);
    funcs["bid64_from_int64"] = IntelFunc("constructor", 2, 64, inlong);
    funcs["bid128_from_int64"] = IntelFunc("constructor", 2, 128, inlong);
    funcs["bid32_from_string"] = IntelFunc("constructor", 2, 32, instring);
    funcs["bid64_from_string"] = IntelFunc("constructor", 2, 64, instring);
    funcs["bid128_from_string"] = IntelFunc("constructor", 2, 128, instring);
    funcs["bid32_from_uint32"] = IntelFunc("constructor", 2, 32, inuint);
    funcs["bid64_from_uint32"] = IntelFunc("constructor", 2, 64, inuint);
    funcs["bid128_from_uint32"] = IntelFunc("constructor", 2, 128, inuint);
    funcs["bid32_from_uint64"] = IntelFunc("constructor", 2, 32, inulong);
    funcs["bid64_from_uint64"] = IntelFunc("constructor", 2, 64, inulong);
    funcs["bid128_from_uint64"] = IntelFunc("constructor", 2, 128, inulong);
    funcs["bid32_hypot"] = IntelFunc("hypot", 3, 32, 32, 32);
    funcs["bid64_hypot"] = IntelFunc("hypot", 3, 64, 64, 64);
    funcs["bid128_hypot"] = IntelFunc("hypot", 3, 128, 128, 128);
    funcs["bid32_ilogb"] = IntelFunc("ilogb", 2, inuint, 32);
    funcs["bid64_ilogb"] = IntelFunc("ilogb", 2, inuint, 64);
    funcs["bid128_ilogb"] = IntelFunc("ilogb", 2, inuint, 128);
    funcs["bid32_inf"] = IntelFunc("");
    funcs["bid64_inf"] = IntelFunc("");
    funcs["bid128_inf"] = IntelFunc("");
    funcs["bid32_isCanonical"] = IntelFunc("isCanonical", 2, inbool, 32);
    funcs["bid64_isCanonical"] = IntelFunc("isCanonical", 2, inbool, 64);
    funcs["bid128_isCanonical"] = IntelFunc("isCanonical", 2, inbool, 128);
    funcs["bid32_isNormal"] = IntelFunc("isNormal", 2, inbool, 32);
    funcs["bid64_isNormal"] = IntelFunc("isNormal", 2, inbool, 64);
    funcs["bid128_isNormal"] = IntelFunc("isNormal", 2, inbool, 128);
    funcs["bid32_isSubnormal"] = IntelFunc("isSubnormal", 2, inbool, 32);
    funcs["bid64_isSubnormal"] = IntelFunc("isSubnormal", 2, inbool, 64);
    funcs["bid128_isSubnormal"] = IntelFunc("isSubnormal", 2, inbool, 128);
    funcs["bid32_isZero"] = IntelFunc("isZero", 2, inbool, 32);
    funcs["bid64_isZero"] = IntelFunc("isZero", 2, inbool, 64);
    funcs["bid128_isZero"] = IntelFunc("isZero", 2, inbool, 128);
    funcs["bid32_isFinite"] = IntelFunc("isFinite", 2, inbool, 32);
    funcs["bid64_isFinite"] = IntelFunc("isFinite", 2, inbool, 64);
    funcs["bid128_isFinite"] = IntelFunc("isFinite", 2, inbool, 128);
    funcs["bid32_isSignaling"] = IntelFunc("isSignaling", 2, inbool, 32);
    funcs["bid64_isSignaling"] = IntelFunc("isSignaling", 2, inbool, 64);
    funcs["bid128_isSignaling"] = IntelFunc("isSignaling", 2, inbool, 128);
    funcs["bid32_isNaN"] = IntelFunc("isNaN", 2, inbool, 32);
    funcs["bid64_isNaN"] = IntelFunc("isNaN", 2, inbool, 64);
    funcs["bid128_isNaN"] = IntelFunc("isNaN", 2, inbool, 128);
    funcs["bid32_isInf"] = IntelFunc("isInfinity", 2, inbool, 32);
    funcs["bid64_isInf"] = IntelFunc("isInfinity", 2, inbool, 64);
    funcs["bid128_isInf"] = IntelFunc("isInfinity", 2, inbool, 128);
    funcs["bid32_isSigned"] = IntelFunc("signbit", 2, inint, 32);
    funcs["bid64_isSigned"] = IntelFunc("signbit", 2, inint, 64);
    funcs["bid128_isSigned"] = IntelFunc("signbit", 2, inint, 128);
    funcs["bid32_ldexp"] = IntelFunc("ldexp", 3, 32, 32, inint);
    funcs["bid64_ldexp"] = IntelFunc("ldexp", 3, 64, 64, inint);
    funcs["bid128_ldexp"] = IntelFunc("ldexp", 3, 128, 128, inint);
    funcs["bid32_lgamma"] = IntelFunc("lgamma", 2, 32, 32);
    funcs["bid64_lgamma"] = IntelFunc("lgamma", 2, 64, 64);
    funcs["bid128_lgamma"] = IntelFunc("lgamma", 2, 128, 128);
    funcs["bid32_llrint"] = IntelFunc("lrint", 2, inlong, 32);
    funcs["bid64_llrint"] = IntelFunc("lrint", 2, inlong, 64);
    funcs["bid128_llrint"] = IntelFunc("lrint", 2, inlong, 128);
    funcs["bid32_lrint"] = IntelFunc("lrint", 2, inlong, 32);
    funcs["bid64_lrint"] = IntelFunc("lrint", 2, inlong, 64);
    funcs["bid128_lrint"] = IntelFunc("lrint", 2, inlong, 128);
    funcs["bid32_rint"] = IntelFunc("rint", 2, 32, 32);
    funcs["bid64_rint"] = IntelFunc("rint", 2, 64, 64);
    funcs["bid128_rint"] = IntelFunc("rint", 2, 128, 128);
    funcs["bid32_log"] = IntelFunc("log", 2, 32, 32);
    funcs["bid64_log"] = IntelFunc("log", 2, 64, 64);
    funcs["bid128_log"] = IntelFunc("log", 2, 128, 128);
    funcs["bid32_log10"] = IntelFunc("log10", 2, 32, 32);
    funcs["bid64_log10"] = IntelFunc("log10", 2, 64, 64);
    funcs["bid128_log10"] = IntelFunc("log10", 2, 128, 128);
    funcs["bid32_log2"] = IntelFunc("log2", 2, 32, 32);
    funcs["bid64_log2"] = IntelFunc("log2", 2, 64, 64);
    funcs["bid128_log2"] = IntelFunc("log2", 2, 128, 128);
    funcs["bid32_log1p"] = IntelFunc("log1p", 2, 32, 32);
    funcs["bid64_log1p"] = IntelFunc("log1p", 2, 64, 64);
    funcs["bid128_log1p"] = IntelFunc("log1p", 2, 128, 128);
    funcs["bid32_logb"] = IntelFunc("logb", 2, 32, 32);
    funcs["bid64_logb"] = IntelFunc("logb", 2, 64, 64);
    funcs["bid128_logb"] = IntelFunc("logb", 2, 128, 128);
    funcs["bid32_lround"] = IntelFunc("lround", 2, inlong, 32);
    funcs["bid64_lround"] = IntelFunc("lround", 2, inlong, 64);
    funcs["bid128_lround"] = IntelFunc("lround", 2, inlong, 128);
    funcs["binary32_to_bid32"] = IntelFunc("constructor", 2, 32, infloat);
    funcs["binary32_to_bid64"] = IntelFunc("constructor", 2, 64, infloat);
    funcs["binary32_to_bid128"] = IntelFunc("constructor", 2, 128, infloat);
    funcs["binary64_to_bid32"] = IntelFunc("constructor", 2, 32, indouble);
    funcs["binary64_to_bid64"] = IntelFunc("constructor", 2, 64, indouble);
    funcs["binary64_to_bid128"] = IntelFunc("constructor", 2, 128, indouble);
    funcs["binary80_to_bid32"] = IntelFunc("constructor", 2, 32, inreal);
    funcs["binary80_to_bid64"] = IntelFunc("constructor", 2, 64, inreal);
    funcs["binary80_to_bid128"] = IntelFunc("constructor", 2, 128, inreal);
    funcs["binary128_to_bid32"] = IntelFunc("");
    funcs["binary128_to_bid64"] = IntelFunc("");
    funcs["binary128_to_bid128"] = IntelFunc("");
    funcs["bid32_to_binary32"] = IntelFunc("to!float", 2, infloat, 32);
    funcs["bid64_to_binary32"] = IntelFunc("to!float", 2, infloat, 64);
    funcs["bid128_to_binary32"] = IntelFunc("to!float", 2, infloat, 128);
    funcs["bid32_to_binary64"] = IntelFunc("to!double", 2, indouble, 32);
    funcs["bid64_to_binary64"] = IntelFunc("to!double", 2, indouble, 64);
    funcs["bid128_to_binary64"] = IntelFunc("to!double", 2, indouble, 128);
    funcs["bid32_to_binary80"] = IntelFunc("to!real", 2, inreal, 32);
    funcs["bid64_to_binary80"] = IntelFunc("to!real", 2, inreal, 64);
    funcs["bid128_to_binary80"] = IntelFunc("to!real", 2, inreal, 128);
    funcs["bid32_to_binary128"] = IntelFunc("");
    funcs["bid64_to_binary128"] = IntelFunc("");
    funcs["bid128_to_binary128"] = IntelFunc("");
    funcs["bid32_nearbyint"] = IntelFunc("nearbyint", 2, 32, 32);
    funcs["bid64_nearbyint"] = IntelFunc("nearbyint", 2, 64, 64);
    funcs["bid128_nearbyint"] = IntelFunc("nearbyint", 2, 128, 128);
    funcs["bid64_add"] = IntelFunc("add", 3, 64, 64, 64);
    funcs["bid64_sub"] = IntelFunc("sub", 3, 64, 64, 64);
    funcs["bid64_mul"] = IntelFunc("mul", 3, 64, 64, 64);
    funcs["bid64_div"] = IntelFunc("div", 3, 64, 64, 64);
    funcs["bid32_add"] = IntelFunc("add", 3, 32, 32, 32);
    funcs["bid32_sub"] = IntelFunc("sub", 3, 32, 32, 32);
    funcs["bid32_mul"] = IntelFunc("mul", 3, 32, 32, 32);
    funcs["bid32_div"] = IntelFunc("div", 3, 32, 32, 32);
    funcs["bid128_add"] = IntelFunc("add", 3, 128, 128, 128);
    funcs["bid128_sub"] = IntelFunc("sub", 3, 128, 128, 128);
    funcs["bid128_mul"] = IntelFunc("mul", 3, 128, 128, 128);
    funcs["bid128_div"] = IntelFunc("div", 3, 128, 128, 128);
    funcs["bid64qq_div"] = IntelFunc("div", 3, 64, 128, 128);
    funcs["bid128_round_integral_nearest_even"] = IntelFunc("nearbyint", 3, 128, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_round_integral_nearest_even"] = IntelFunc("nearbyint", 3, 64, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_round_integral_nearest_even"] = IntelFunc("nearbyint", 3, 32, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_round_integral_positive"] = IntelFunc("nearbyint", 3, 128, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_round_integral_positive"] = IntelFunc("nearbyint", 3, 64, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_round_integral_positive"] = IntelFunc("nearbyint", 3, 32, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_round_integral_negative"] = IntelFunc("nearbyint", 3, 128, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_round_integral_negative"] = IntelFunc("nearbyint", 3, 64, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_round_integral_negative"] = IntelFunc("nearbyint", 3, 32, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_round_integral_nearest_away"] = IntelFunc("nearbyint", 3, 128, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_round_integral_nearest_away"] = IntelFunc("nearbyint", 3, 64, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_round_integral_nearest_away"] = IntelFunc("nearbyint", 3, 32, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_round_integral_exact"] = IntelFunc("rint", 2, 128, 128);
    funcs["bid64_round_integral_exact"] = IntelFunc("rint", 2, 64, 64);
    funcs["bid32_round_integral_exact"] = IntelFunc("rint", 2, 32, 32);
    funcs["bid64dq_div"] = IntelFunc("", 3, 64, 64, 128);
    funcs["bid128_round_integral_zero"] = IntelFunc("nearbyint", 3, 128, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_round_integral_zero"] = IntelFunc("nearbyint", 3, 64, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_round_integral_zero"] = IntelFunc("nearbyint", 3, 32, 32, inrounding, 0, RoundingMode.towardZero);
 
    funcs["bid32_to_int64_xrnint"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int64_xrninta"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int64_xfloor"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int64_xceil"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int64_xint"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int64_xrnint"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int64_xrninta"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int64_xfloor"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int64_xceil"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int64_xint"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int64_xrnint"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int64_xrninta"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int64_xfloor"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int64_xceil"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int64_xint"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_int32_xrnint"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int32_xrninta"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int32_xfloor"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int32_xceil"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int32_xint"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int32_xrnint"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int32_xrninta"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int32_xfloor"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int32_xceil"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int32_xint"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int32_xrnint"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int32_xrninta"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int32_xfloor"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int32_xceil"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int32_xint"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_int16_xrnint"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int16_xrninta"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int16_xfloor"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int16_xceil"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int16_xint"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int16_xrnint"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int16_xrninta"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int16_xfloor"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int16_xceil"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int16_xint"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int16_xrnint"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int16_xrninta"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int16_rninta"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int16_xfloor"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int16_xceil"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int16_xint"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_int8_xrnint"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int8_xrninta"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int8_xfloor"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int8_xceil"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int8_xint"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int8_xrnint"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int8_xrninta"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int8_xfloor"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int8_xceil"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int8_xint"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int8_xrnint"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int8_xrninta"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int8_xfloor"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int8_xceil"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int8_xint"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint64_xrnint"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint64_xrninta"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint64_xfloor"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint64_xceil"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint64_xint"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint64_xrnint"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint64_xrninta"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint64_xfloor"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint64_xceil"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint64_xint"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint64_xrnint"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint64_xrninta"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint64_xfloor"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint64_xceil"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint64_xint"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint32_xrnint"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint32_xrninta"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint32_xfloor"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint32_xceil"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint32_xint"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint32_xrnint"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint32_xrninta"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint32_xfloor"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint32_xceil"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint32_xint"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint32_xrnint"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint32_xrninta"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint32_xfloor"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint32_xceil"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint32_xint"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint16_xrnint"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint16_xrninta"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint16_xfloor"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint16_xceil"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint16_xint"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint16_xrnint"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint16_xrninta"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint16_xfloor"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint16_xceil"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint16_xint"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint16_xrnint"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint16_xrninta"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint16_rninta"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint16_xfloor"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint16_xceil"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint16_xint"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint8_xrnint"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint8_xrninta"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint8_xfloor"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint8_xceil"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint8_xint"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint8_xrnint"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint8_xrninta"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint8_xfloor"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint8_xceil"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint8_xint"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint8_xrnint"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint8_xrninta"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint8_xfloor"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint8_xceil"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint8_xint"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.towardZero);

    funcs["bid32_to_int64_rnint"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int64_floor"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int64_ceil"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int64_int"] = IntelFunc("to!long", 3, inlong, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int64_rnint"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int64_floor"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int64_ceil"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int64_int"] = IntelFunc("to!long", 3, inlong, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int64_rnint"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int64_rninta"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int64_floor"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int64_ceil"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int64_int"] = IntelFunc("to!long", 3, inlong, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_int32_rnint"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int32_rninta"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int32_floor"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int32_ceil"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int32_int"] = IntelFunc("to!int", 3, inint, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int32_rnint"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int32_rninta"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int32_floor"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int32_ceil"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int32_int"] = IntelFunc("to!int", 3, inint, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int32_rnint"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int32_rninta"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int32_floor"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int32_ceil"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int32_int"] = IntelFunc("to!int", 3, inint, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_int16_rnint"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int16_rninta"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int16_floor"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int16_ceil"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int16_int"] = IntelFunc("to!short", 3, inshort, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int16_rnint"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int16_rninta"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int16_floor"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int16_ceil"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int16_int"] = IntelFunc("to!short", 3, inshort, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int16_rnint"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int16_rninta"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int16_rninta"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int16_floor"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int16_ceil"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int16_int"] = IntelFunc("to!short", 3, inshort, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_int8_rnint"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_int8_rninta"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_int8_floor"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_int8_ceil"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_int8_int"] = IntelFunc("to!byte", 3, inbyte, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_int8_rnint"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_int8_rninta"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_int8_floor"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_int8_ceil"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_int8_int"] = IntelFunc("to!byte", 3, inbyte, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_int8_rnint"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_int8_rninta"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_int8_floor"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_int8_ceil"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_int8_int"] = IntelFunc("to!byte", 3, inbyte, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint64_rnint"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint64_floor"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint64_ceil"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint64_int"] = IntelFunc("to!ulong", 3, inulong, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint64_rnint"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint64_floor"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint64_ceil"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint64_int"] = IntelFunc("to!ulong", 3, inulong, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint64_rnint"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint64_rninta"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint64_floor"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint64_ceil"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint64_int"] = IntelFunc("to!ulong", 3, inulong, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint32_rnint"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint32_rninta"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint32_floor"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint32_ceil"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint32_int"] = IntelFunc("to!uint", 3, inuint, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint32_rnint"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint32_rninta"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint32_floor"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint32_ceil"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint32_int"] = IntelFunc("to!uint", 3, inuint, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint32_rnint"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint32_rninta"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint32_floor"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint32_ceil"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint32_int"] = IntelFunc("to!uint", 3, inuint, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint16_rnint"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint16_rninta"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint16_floor"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint16_ceil"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint16_int"] = IntelFunc("to!ushort", 3, inushort, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint16_rnint"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint16_rninta"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint16_floor"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint16_ceil"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint16_int"] = IntelFunc("to!ushort", 3, inushort, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint16_rnint"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint16_rninta"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint16_rninta"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint16_floor"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint16_ceil"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint16_int"] = IntelFunc("to!ushort", 3, inushort, 128, inrounding, 0, RoundingMode.towardZero);
    funcs["bid32_to_uint8_rnint"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid32_to_uint8_rninta"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid32_to_uint8_floor"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid32_to_uint8_ceil"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid32_to_uint8_int"] = IntelFunc("to!ubyte", 3, inubyte, 32, inrounding, 0, RoundingMode.towardZero);
    funcs["bid64_to_uint8_rnint"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid64_to_uint8_rninta"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid64_to_uint8_floor"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid64_to_uint8_ceil"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid64_to_uint8_int"] = IntelFunc("to!ubyte", 3, inubyte, 64, inrounding, 0, RoundingMode.towardZero);
    funcs["bid128_to_uint8_rnint"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.tiesToEven);
    funcs["bid128_to_uint8_rninta"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.tiesToAway);
    funcs["bid128_to_uint8_floor"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.towardNegative);
    funcs["bid128_to_uint8_ceil"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.towardPositive);
    funcs["bid128_to_uint8_int"] = IntelFunc("to!ubyte", 3, inubyte, 128, inrounding, 0, RoundingMode.towardZero);

    funcs["bid32_totalOrder"] = IntelFunc("totalOrder", 3, inbool, 32, 32);
    funcs["bid64_totalOrder"] = IntelFunc("totalOrder", 3, inbool, 64, 64);
    funcs["bid128_totalOrder"] = IntelFunc("totalOrder", 3, inbool, 128, 128);
    funcs["bid32_totalOrderMag"] = IntelFunc("totalOrderAbs", 3, inbool, 32, 32);
    funcs["bid64_totalOrderMag"] = IntelFunc("totalOrderAbs", 3, inbool, 64, 64);
    funcs["bid128_totalOrderMag"] = IntelFunc("totalOrderAbs", 3, inbool, 128, 128);
    funcs["bid32_minnum"] = IntelFunc("min", 3, 32, 32, 32);
    funcs["bid64_minnum"] = IntelFunc("min", 3, 64, 64, 64);
    funcs["bid128_minnum"] = IntelFunc("min", 3, 128, 128, 128);
    funcs["bid32_minnum_mag"] = IntelFunc("minAbs", 3, 32, 32, 32);
    funcs["bid64_minnum_mag"] = IntelFunc("minAbs", 3, 64, 64, 64);
    funcs["bid128_minnum_mag"] = IntelFunc("minAbs", 3, 128, 128, 128);
    funcs["bid32_maxnum"] = IntelFunc("max", 3, 32, 32, 32);
    funcs["bid64_maxnum"] = IntelFunc("max", 3, 64, 64, 64);
    funcs["bid128_maxnum"] = IntelFunc("max", 3, 128, 128, 128);
    funcs["bid32_maxnum_mag"] = IntelFunc("maxAbs", 3, 32, 32, 32);
    funcs["bid64_maxnum_mag"] = IntelFunc("maxAbs", 3, 64, 64, 64);
    funcs["bid128_maxnum_mag"] = IntelFunc("maxAbs", 3, 128, 128, 128);
    funcs["bid32_rem"] = IntelFunc("mod", 3, 32, 32, 32);
    funcs["bid64_rem"] = IntelFunc("mod", 3, 64, 64, 64);
    funcs["bid128_rem"] = IntelFunc("mod", 3, 128, 128, 128);
    funcs["bid128qd_div"] = IntelFunc("div", 3, 128, 128, 64);
    funcs["bid64qd_div"] = IntelFunc("", 3, 64, 128, 64);
    funcs["bid32_sameQuantum"] = IntelFunc("sameQuantum", 3, inbool, 32, 32);
    funcs["bid64_sameQuantum"] = IntelFunc("sameQuantum", 3, inbool, 64, 64);
    funcs["bid128_sameQuantum"] = IntelFunc("sameQuantum", 3, inbool, 128, 128);
    funcs["bid32_pow"] = IntelFunc("pow", 3, 32, 32, 32);
    funcs["bid64_pow"] = IntelFunc("pow", 3, 64, 64, 64);
    funcs["bid128_pow"] = IntelFunc("pow", 3, 128, 128, 128);
    funcs["bid_wcstod128"] = IntelFunc("constructor", 2, 128, instring);
    funcs["bid_wcstod64"] = IntelFunc("constructor", 2, 64, instring);
    funcs["bid_wcstod32"] = IntelFunc("constructor", 2, 32, instring);
    funcs["bid_strtod128"] = IntelFunc("constructor", 2, 128, instring);
    funcs["bid_strtod64"] = IntelFunc("constructor", 2, 64, instring);
    funcs["bid_strtod32"] = IntelFunc("constructor", 2, 32, instring);
    funcs["bid32_nan"] = IntelFunc("");
    funcs["bid64_nan"] = IntelFunc("");
    funcs["bid128_nan"] = IntelFunc("");
    funcs["bid_fesetexceptflag"] = IntelFunc("");
    funcs["bid_fetestexcept"] = IntelFunc("");
    funcs["bid_fegetexceptflag"] = IntelFunc("");
    funcs["bid_feraiseexcept"] = IntelFunc("");
    funcs["bid_feclearexcept"] = IntelFunc("");
    funcs["bid64qq_mul"] = IntelFunc("mul", 3, 64, 128, 128);
    funcs["bid64dq_mul"] = IntelFunc("mul", 3, 64, 64, 128);
    funcs["bid64qd_mul"] = IntelFunc("mul", 3, 64, 128, 64);
    funcs["bid128qdq_fma"] = IntelFunc("fma", 4, 128, 128, 64, 128);
    funcs["bid128qqq_fma"] = IntelFunc("fma", 4, 128, 128, 128, 128);
    funcs["bid128qqd_fma"] = IntelFunc("fma", 4, 128, 128, 128, 64);
    funcs["bid128qdd_fma"] = IntelFunc("fma", 4, 128, 128, 64, 64);
    funcs["bid128ddd_fma"] = IntelFunc("", 4, 128, 64, 64, 64);
    funcs["bid128ddq_fma"] = IntelFunc("fma", 4, 128, 64, 64, 128);
    funcs["bid128dqq_fma"] = IntelFunc("fma", 4, 128, 64, 128, 128);
    funcs["bid128dqd_fma"] = IntelFunc("fma", 4, 128, 64, 128, 64);
    funcs["bid64qdq_fma"] = IntelFunc("", 4, 64, 128, 64, 128);
    funcs["bid64qqq_fma"] = IntelFunc("", 4, 64, 128, 128, 128);
    funcs["bid64qqd_fma"] = IntelFunc("", 4, 64, 128, 128, 64);
    funcs["bid64qdd_fma"] = IntelFunc("", 4, 64, 128, 64, 64);
    funcs["bid64ddd_fma"] = IntelFunc("fma", 4, 64, 64, 64, 64);
    funcs["bid64ddq_fma"] = IntelFunc("", 4, 64, 64, 64, 128);
    funcs["bid64dqq_fma"] = IntelFunc("", 4, 64, 64, 128, 128);
    funcs["bid64dqd_fma"] = IntelFunc("", 4, 64, 64, 128, 64);
    funcs["bid128qd_mul"] = IntelFunc("mul", 3, 128, 128, 64);
    funcs["bid_to_dpd32"] = IntelFunc("toDPD", 2, dpd32, 32);
    funcs["bid_to_dpd64"] = IntelFunc("toDPD", 2, dpd64, 64);
    funcs["bid_to_dpd128"] = IntelFunc("toDPD", 2, dpd128, 128);
    funcs["bid_setDecimalRoundingDirection"] = IntelFunc("");
    funcs["bid_getDecimalRoundingDirection"] = IntelFunc("");
    funcs["bid32_radix"] = IntelFunc("");
    funcs["bid64_radix"] = IntelFunc("");
    funcs["bid128_radix"] = IntelFunc("");
    funcs["bid128_nextafter"] = IntelFunc("nextafter", 3, 128, 128, 128);
    funcs["bid64_nextafter"] = IntelFunc("nextafter", 3, 64, 64, 64);
    funcs["bid32_nextafter"] = IntelFunc("nextafter", 3, 32, 32, 32);
    funcs["bid128_nexttoward"] = IntelFunc("nexttoward", 3, 128, 128, 128);
    funcs["bid64_nexttoward"] = IntelFunc("nexttoward", 3, 64, 64, 128);
    funcs["bid32_nexttoward"] = IntelFunc("nexttoward", 3, 32, 32, 128);
    funcs["bid32_sin"] = IntelFunc("sin", 2, 32, 32);
    funcs["bid64_sin"] = IntelFunc("sin", 2, 64, 64);
    funcs["bid128_sin"] = IntelFunc("sin", 2, 128, 128);
    funcs["bid32_nextdown"] = IntelFunc("nextDown", 2, 32, 32);
    funcs["bid64_nextdown"] = IntelFunc("nextDown", 2, 64, 64);
    funcs["bid128_nextdown"] = IntelFunc("nextDown", 2, 128, 128);
    funcs["bid32_nextup"] = IntelFunc("nextUp", 2, 32, 32);
    funcs["bid64_nextup"] = IntelFunc("nextUp", 2, 64, 64);
    funcs["bid128_nextup"] = IntelFunc("nextUp", 2, 128, 128);
    funcs["bid32_scalbn"] = IntelFunc("scalbn", 3, 32, 32, infloat);
    funcs["bid64_scalbn"] = IntelFunc("scalbn", 3, 64, 64, infloat);
    funcs["bid128_scalbn"] = IntelFunc("scalbn", 3, 128, 128, infloat);
    funcs["bid128_quantize"] = IntelFunc("quantize", 3, 128, 128, 128);
    funcs["bid64_quantize"] = IntelFunc("quantize", 3, 64, 64, 64);
    funcs["bid32_quantize"] = IntelFunc("quantize", 3, 32, 32, 32);
    funcs["bid64dq_add"] = IntelFunc("", 3, 64, 64, 128);
    funcs["bid64dq_sub"] = IntelFunc("", 3, 64, 64, 128);
    funcs["bid32_quiet_equal"] = IntelFunc("equ", 3, inbool, 32, 32);
    funcs["bid32_quiet_not_equal"] = IntelFunc("nequ", 3, inbool, 32, 32);
    funcs["bid64_quiet_equal"] = IntelFunc("equ", 3, inbool, 64, 64);
    funcs["bid64_quiet_not_equal"] = IntelFunc("nequ", 3, inbool, 64, 64);
    funcs["bid128_quiet_equal"] = IntelFunc("equ", 3, inbool, 128, 128);
    funcs["bid128_quiet_not_equal"] = IntelFunc("nequ", 3, inbool, 128, 128);
    funcs["bid32_quiet_greater"] = IntelFunc("isGreater", 3, inbool, 32, 32);
    funcs["bid64_quiet_greater"] = IntelFunc("isGreater", 3, inbool, 64, 64);
    funcs["bid128_quiet_greater"] = IntelFunc("isGreater", 3, inbool, 128, 128);
    funcs["bid32_quiet_not_greater"] = IntelFunc("isNotGreater", 3, inbool, 32, 32);
    funcs["bid32_quiet_greater_equal"] = IntelFunc("isGreaterOrEqual", 3, inbool, 32, 32);
    funcs["bid64_quiet_greater_equal"] = IntelFunc("isGreaterOrEqual", 3, inbool, 64, 64);
    funcs["bid128_quiet_greater_equal"] = IntelFunc("isGreaterOrEqual", 3, inbool, 128, 128);
    funcs["bid32_quiet_greater_unordered"] = IntelFunc("isGreaterOrUnordered", 3, inbool, 32, 32);
    funcs["bid64_quiet_greater_unordered"] = IntelFunc("isGreaterOrUnordered", 3, inbool, 64, 64);
    funcs["bid128_quiet_greater_unordered"] = IntelFunc("isGreaterOrUnordered", 3, inbool, 128, 128);
    funcs["bid32_quiet_less"] = IntelFunc("isLess", 3, inbool, 32, 32);
    funcs["bid64_quiet_less"] = IntelFunc("isLess", 3, inbool, 64, 64);
    funcs["bid128_quiet_less"] = IntelFunc("isLess", 3, inbool, 128, 128);
    funcs["bid32_quiet_not_less"] = IntelFunc("isNotLess", 3, inbool, 32, 32);
    funcs["bid32_quiet_less_equal"] = IntelFunc("isLessOrEqual", 3, inbool, 32, 32);
    funcs["bid64_quiet_less_equal"] = IntelFunc("isLessOrEqual", 3, inbool, 64, 64);
    funcs["bid128_quiet_less_equal"] = IntelFunc("isLessOrEqual", 3, inbool, 128, 128);
    funcs["bid32_quiet_less_unordered"] = IntelFunc("isLessOrUnordered", 3, inbool, 32, 32);
    funcs["bid64_quiet_less_unordered"] = IntelFunc("isLessOrUnordered", 3, inbool, 64, 64);
    funcs["bid128_quiet_less_unordered"] = IntelFunc("isLessOrUnordered", 3, inbool, 128, 128);
    funcs["bid32_signaling_equal"] = IntelFunc("isEqual", 3, inbool, 32, 32);
    funcs["bid32_signaling_not_equal"] = IntelFunc("isNotEqual", 3, inbool, 32, 32);
    funcs["bid32_signaling_greater"] = IntelFunc("greater", 3, inbool, 32, 32);
    funcs["bid32_signaling_not_greater"] = IntelFunc("ngt", 3, inbool, 32, 32);
    funcs["bid32_signaling_greater_equal"] = IntelFunc("gtequ", 3, inbool, 32, 32);
    funcs["bid32_signaling_greater_unordered"] = IntelFunc("gtu", 3, inbool, 32, 32);
    funcs["bid32_signaling_less"] = IntelFunc("less", 3, inbool, 32, 32);
    funcs["bid32_signaling_not_less"] = IntelFunc("nless", 3, inbool, 32, 32);
    funcs["bid32_signaling_less_equal"] = IntelFunc("lessequ", 3, inbool, 32, 32);
    funcs["bid32_signaling_less_unordered"] = IntelFunc("lessu", 3, inbool, 32, 32);
    funcs["bid64_signaling_equal"] = IntelFunc("isEqual", 3, inbool, 64, 64);
    funcs["bid64_signaling_not_equal"] = IntelFunc("isNotEqual", 3, inbool, 64, 64);
    funcs["bid64_signaling_greater"] = IntelFunc("gt", 3, inbool, 64, 64);
    funcs["bid64_signaling_not_greater"] = IntelFunc("ngt", 3, inbool, 64, 64);
    funcs["bid64_signaling_greater_equal"] = IntelFunc("gtequ", 3, inbool, 64, 64);
    funcs["bid64_signaling_greater_unordered"] = IntelFunc("gtu", 3, inbool, 64, 64);
    funcs["bid64_signaling_less"] = IntelFunc("less", 3, inbool, 64, 64);
    funcs["bid64_signaling_not_less"] = IntelFunc("nless", 3, inbool, 64, 64);
    funcs["bid64_signaling_less_equal"] = IntelFunc("gtequ", 3, inbool, 64, 64);
    funcs["bid64_signaling_less_unordered"] = IntelFunc("lessu", 3, inbool, 64, 64);
    funcs["bid128_signaling_equal"] = IntelFunc("isEqual", 3, inbool, 128, 128);
    funcs["bid128_signaling_not_equal"] = IntelFunc("isNotEqual", 3, inbool, 128, 128);
    funcs["bid128_signaling_greater"] = IntelFunc("gt", 3, inbool, 128, 128);
    funcs["bid128_signaling_not_greater"] = IntelFunc("ngt", 3, inbool, 128, 128);
    funcs["bid128_signaling_greater_equal"] = IntelFunc("gtequ", 3, inbool, 128, 128);
    funcs["bid128_signaling_greater_unordered"] = IntelFunc("gtu", 3, inbool, 128, 128);
    funcs["bid128_signaling_less"] = IntelFunc("less", 3, inbool, 128, 128);
    funcs["bid128_signaling_not_less"] = IntelFunc("nless", 3, inbool, 128, 128);
    funcs["bid128_signaling_less_equal"] = IntelFunc("lessequ", 3, inbool, 128, 128);
    funcs["bid128_signaling_less_unordered"] = IntelFunc("lessu", 3, inbool, 128, 128);
    funcs["bid32_tan"] = IntelFunc("tan", 2, 32, 32);
    funcs["bid64_tan"] = IntelFunc("tan", 2, 64, 64);
    funcs["bid128_tan"] = IntelFunc("tan", 2, 128, 128);
    funcs["bid32_tanh"] = IntelFunc("tanh", 2, 32, 32);
    funcs["bid64_tanh"] = IntelFunc("tanh", 2, 64, 64);
    funcs["bid128_tanh"] = IntelFunc("tanh", 2, 128, 128);
    funcs["bid32_sinh"] = IntelFunc("sinh", 2, 32, 32);
    funcs["bid64_sinh"] = IntelFunc("sinh", 2, 64, 64);
    funcs["bid128_sinh"] = IntelFunc("sinh", 2, 128, 128);
    funcs["bid32_tgamma"] = IntelFunc("tgamma", 2, 32, 32);
    funcs["bid64_tgamma"] = IntelFunc("tgamma", 2, 64, 64);
    funcs["bid128_tgamma"] = IntelFunc("tgamma", 2, 128, 128);
    funcs["bid32_scalbln"] = IntelFunc("scalb", 3, 32, 32, inint);
    funcs["bid64_scalbln"] = IntelFunc("scalb", 3, 64, 64, inint);
    funcs["bid128_scalbln"] = IntelFunc("scalb", 3, 128, 128, inint);
    funcs["bid32_modf"] = IntelFunc("modf", 3, 32, 32, r32);
    funcs["bid64_modf"] = IntelFunc("modf", 3, 64, 64, r64);
    funcs["bid128_modf"] = IntelFunc("modf", 3, 128, 128, r128);
    funcs["bid_testSavedFlags"] = IntelFunc("");
    funcs["bid_testFlags"] = IntelFunc("");
    funcs["str64"] = IntelFunc("");
    funcs["bid_signalException"] = IntelFunc("");
    funcs["bid_saveFlags"] = IntelFunc("");
    funcs["bid_restoreFlags"] = IntelFunc("");
    funcs["bid_lowerFlags"] = IntelFunc("");
    funcs["bid_is754"] = IntelFunc("");
    funcs["bid_is754R"] = IntelFunc("");
    funcs["bid32_quantexp"] = IntelFunc("quantexp", 2, inint, 32);
    funcs["bid64_quantexp"] = IntelFunc("quantexp", 2, inint, 64);
    funcs["bid128_quantexp"] = IntelFunc("quantexp", 2, inint, 128);
    funcs["bid_dpd_to_bid32"] = IntelFunc("fromDPD", 2, 32, dpd32);
    funcs["bid_dpd_to_bid64"] = IntelFunc("fromDPD", 2, 64, dpd64);
    funcs["bid_dpd_to_bid128"] = IntelFunc("fromDPD", 2, 128, dpd128);
    funcs["bid32_to_bid64"] = IntelFunc("constructor", 2, 64, 32);
    funcs["bid32_to_bid128"] = IntelFunc("constructor", 2, 128, 32);
    funcs["bid64_to_bid32"] = IntelFunc("constructor", 2, 32, 64);
    funcs["bid64_to_bid128"] = IntelFunc("constructor", 2, 128, 64);
    funcs["bid128_to_bid32"] = IntelFunc("constructor", 2, 32, 128);
    funcs["bid128_to_bid64"] = IntelFunc("constructor", 2, 64, 128);
    funcs["bid32_to_string"] = IntelFunc("to!string", 2, instring, 32);
    funcs["bid64_to_string"] = IntelFunc("to!string", 2, instring, 64);
    funcs["bid128_to_string"] = IntelFunc("to!string", 2, instring, 128);
    funcs["bid128_quiet_unordered"] = IntelFunc("isUnordered", 3, inbool, 128, 128);
    funcs["bid64_quiet_unordered"] = IntelFunc("isUnordered", 3, inbool, 64, 64);
    funcs["bid32_quiet_unordered"] = IntelFunc("isUnordered", 3, inbool, 32, 32);
    funcs["bid128_quiet_ordered"] = IntelFunc("isOrdered", 3, inbool, 128, 128);
    funcs["bid64_quiet_ordered"] = IntelFunc("isOrdered", 3, inbool, 64, 64);
    funcs["bid32_quiet_ordered"] = IntelFunc("isOrdered", 3, inbool, 32, 32);
    funcs["bid128_quiet_not_less"] = IntelFunc("isNotLess", 3, inbool, 128, 128);
    funcs["bid64_quiet_not_less"] = IntelFunc("isNotLess", 3, inbool, 64, 64);
    funcs["bid32_quiet_not_less"] = IntelFunc("isNotLess", 3, inbool, 32, 32);
    funcs["bid128_quiet_not_greater"] = IntelFunc("isNotGreater", 3, inbool, 128, 128);
    funcs["bid64_quiet_not_greater"] = IntelFunc("isNotGreater", 3, inbool, 64, 64);
    funcs["bid32_quiet_not_greater"] = IntelFunc("isNotGreater", 3, inbool, 32, 32);
    funcs["bid64q_sqrt"] = IntelFunc("", 2, 64, 128);
    funcs["bid64qq_sub"] = IntelFunc("", 3, 64, 128, 128);
    funcs["bid64qq_add"] = IntelFunc("", 3, 64, 128, 128);
    funcs["bid64qd_sub"] = IntelFunc("", 3, 64, 128, 64);
    funcs["bid64qd_add"] = IntelFunc("", 3, 64, 128, 64);
    funcs["bid32_negate"] = IntelFunc("neg", 2, 32, 32);
    funcs["bid64_negate"] = IntelFunc("neg", 2, 64, 64);
    funcs["bid128_negate"] = IntelFunc("neg", 2, 128, 128);
    funcs["bid64dq_sub"] = IntelFunc("", 3, 64, 64, 128);
    funcs["bid64dq_add"] = IntelFunc("", 3, 64, 64, 128);
    funcs["bid128qd_sub"] = IntelFunc("sub", 3, 128, 128, 64);
    funcs["bid128qd_add"] = IntelFunc("add", 3, 128, 128, 64);

    funcs.rehash();

    
    string input = "..\\src\\test\\readtest.in";
    string output = "..\\src\\test\\intel.d";

    auto f = File(output, "w");
    int i, j;
    foreach (line; File(input).byLine())
    {
        ++i;
        if (line.startsWith("--"))
        {
            ++j;
        }
        else
        {
            auto tokens = line.split();
            if (!tokens.length)
                ++j;
            else
            {
                int params;
                if (auto pf = tokens[0] in funcs)
                {
                    ++j;
                    string rm = getRoundingMode(tokens[1]);
                    assert(rm.length);
                    
                    string op1, op2, op3, res;
                    bool err;

                    if (i == 94645)
                    {
                        err = err;
                    }

                    bool raw = (*pf).name == "isCanonical";

                    if ((*pf).name.length)
                    {
                        int tok = 2;
                        if ((*pf).params == 2)
                        {
                            if ((*pf).bits1 == inrounding)
                                op1 = prettyRounding((*pf).mode);
                            else
                                op1 = getToken((*pf).bits1, tokens[tok++], raw);

                            if ((*pf).bitsResult == inrounding)
                                res = prettyRounding((*pf).mode);
                            else
                                res = getToken((*pf).bitsResult, tokens[tok++], raw);
                        }
                        else if ((*pf).params == 3)
                        {
                            if ((*pf).bits1 == inrounding)
                                op1 = prettyRounding((*pf).mode);
                            else
                                op1 = getToken((*pf).bits1, tokens[tok++], raw);

                            if ((*pf).bits2 == inrounding)
                                op2 = prettyRounding((*pf).mode);
                            else
                                op2 = getToken((*pf).bits2, tokens[tok++], raw);

                            if ((*pf).bitsResult == inrounding)
                                res = prettyRounding((*pf).mode);
                            else
                                res = getToken((*pf).bitsResult, tokens[tok++], raw);
                        }

                        else if ((*pf).params == 4)
                        {
                            if ((*pf).bits1 == inrounding)
                                op1 = prettyRounding((*pf).mode);
                            else
                                op1 = getToken((*pf).bits1, tokens[tok++], raw);

                            if ((*pf).bits2 == inrounding)
                                op2 = prettyRounding((*pf).mode);
                            else
                                op2 = getToken((*pf).bits2, tokens[tok++], raw);

                            if ((*pf).bits3 == inrounding)
                                op3 = prettyRounding((*pf).mode);
                            else
                                op3 = getToken((*pf).bits3, tokens[tok++], raw);

                            if ((*pf).bitsResult == inrounding)
                                res = prettyRounding((*pf).mode);
                            else
                                res = getToken((*pf).bitsResult, tokens[tok++], raw);
                        }
                        else
                        {
                            writefln("%06d: Unsupported params (%d) '%s'", i, (*pf).params, (*pf).name);
                            err = true;
                        }

                        if (!err)
                        {
                            assert(res.length);
                            if ((*pf).params >= 2)
                                assert(op1.length);
                            if ((*pf).params >= 3)
                                assert(op2.length);
                            if ((*pf).params >= 4)
                                assert(op3.length);

                            //writeln(i);
                            auto t = tokens[tok++];
                            string expected = prettyFlagsIntel(parse!int(t, 16));

                            tests ~= TestData((*pf).bits1, (*pf).bits2, (*pf).bits3, (*pf).bitsResult, (*pf).name, op1, op2, op3, res, rm, expected, to!string(tokens[0]));
                            //f.writefln("%06d: %s %s %s %s %s %s %s", i, (*pf).name, res, op1, op2, op3, rm, expected);
                            
                        }
                    }
                }
                else
                    writefln("%06d: Unknown function '%s'", i, tokens[0]);
            }
        }

    }

    auto sorted = tests.sort();

    int id = 1;
    string previous = "";
    foreach(t; uniq(sorted))
    {
        if (t.key != previous)
        {
            if (previous.length)
            {
                f.writeln("\t];");
                f.writeln();
                f.writeln("\tauto traps = DecimalControl.enabledExceptions;");
                f.writeln("\tDecimalControl.disableExceptions();");
                f.writeln("\tforeach(s; tests)");
                f.writeln("\t\ttest(s)");
                f.writeln("\tDecimalControl.enableExceptions(traps);");
                f.writeln("}");
                f.writeln();
            }

            previous = t.key;
            f.writefln("//%s", t.ofunc);
            f.writefln("@(\"%s\")", previous);
            f.writeln("unittest");
            f.writeln("{");
            f.writeln("\tstruct S");
            f.writeln("\t{");
            f.writeln("\t\tint id;");
            string pt = prettyTypeX(t.type1);
            if (pt.length) f.writefln("\t\t%s x;", pt);
            pt = prettyTypeX(t.type2);
            if (pt.length) f.writefln("\t\t%s y;", pt);
            pt = prettyTypeX(t.type3);
            if (pt.length) f.writefln("\t\t%s z;", pt);
            pt = prettyTypeX(t.typeResult);
            if (pt.length) f.writefln("\t\t%s result;", pt);
            if (t.func != "equ")
            {
                f.writeln("\t\tRoundingMode rounding;");
                f.writeln("\t\tExceptionFlags expectedFlags;");
            }
            f.writeln("\t}");
            f.writeln();
            f.writeln("\tvoid test(S s)");
            f.writeln("\t{");
            if (t.func != "equ")
            {
                f.writeln("\t\tDecimalControl.resetFlags()");
            }
            f.writeln(t.assertion("\t\t"));
            f.writeln("\t}");
            f.writeln();
            f.writeln("\tS[] tests =");
            f.writeln("\t[");
        }

        f.writeln("\t\t" ~ t.dump(id++));


    }

    if (previous.length)
    {
        f.writeln("\t];");
        f.writeln();
        f.writeln("\tauto traps = DecimalControl.enabledExceptions;");
        f.writeln("\tDecimalControl.disableExceptions();");
        f.writeln("\tforeach(s; tests)");
        f.writeln("\t\ttest(s)");
        f.writeln("\tDecimalControl.enableExceptions(traps);");
        f.writeln("}");
        f.writeln();
    }

   

    writeln("Press Enter to continue...");
    getchar();
    return 0;
}
