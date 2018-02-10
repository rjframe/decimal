module test;

import std.stdio;
import std.range;
import std.string;
import std.format;
import std.conv;
import std.algorithm;
import std.traits;
import decimal;

immutable string inputFileName = "..\\src\\test\\readtest.in";

struct NumberedRange(R)
{
    private int _no = 1;
    private R _range;

    this(R range) { this._range = range; }

    @property bool empty() { return _range.empty; }
    void popFront() { _range.popFront(); ++_no; }
    @property auto front() { return NumberedRangeElement(_range.front, _no); }

    struct NumberedRangeElement
    {
        ElementType!R item;
        int no;
    }
}

struct NoEmptyLinesRange(R)
{
    private R _range;

    this(R range) { this._range = range; }
    void skip()
    {
        while (!_range.empty && _range.front.item.strip().empty)
            _range.popFront();
    }

    @property bool empty() { skip(); return _range.empty; }
    void popFront() { skip(); _range.popFront(); }
    @property auto front() { skip(); return _range.front; }
}

struct NoCommentsRange(R)
{
    private R _range;

    this(R range) { this._range = range; }
    void skip()
    {
        while (!_range.empty && _range.front.item.startsWith("--"))
            _range.popFront();
    }

    @property bool empty() { skip(); return _range.empty; }
    void popFront() { skip(); _range.popFront(); }
    @property auto front() 
    { 
        skip(); 
        return _range.front; 
    }
}

struct TokenizedRange(R)
{
    private R _range;
    this(R range) { this._range = range; }

    struct TokenizedItem
    {
        int lineNo;
        string func;
        int rounding;
        string op1;
        string op2;
        string op3;
        string res;
        int expected;
        int longintsize;

        this(T)(int lineNo, T line)
        {
            
            this.lineNo = lineNo;
            string s = to!string(line);
            auto u = s.indexOf("--");
            if (u >= 0)
                s = s[0 .. u];
            u = s.indexOf("ulp=");
            if (u >= 0)
                s = s[0 .. u];
            u = s.indexOf("underflow_before_only");
            if (u >= 0)
                s = s[0 .. u];
            u = s.indexOf("str_prefix=");
            if (u >= 0)
                s = s[0 .. u];
            u = s.indexOf("longintsize=");
            if (u >= 0)
            {
                longintsize = to!int(s[u + 12 .. u + 14]);
                s = s[0 .. u];
            }
            
            string t = s;

            if (!(t.formattedRead!"%s %d %s %s %s %s %x"(func, rounding, op1, op2, op3, res, expected) == 7))
            {
                t = s;
                if (!(t.formattedRead!"%s %d %s %s %s %x"(func, rounding, op1, op2, res, expected) == 6))
                {
                    t = s;
                    if (!(t.formattedRead!"%s %d %s %s %x"(func, rounding, op1, res, expected) == 5))
                        throw new Exception(format("%6d: Error reading tokens: %s", lineNo, line));
                }
            }
        }

    }

    @property bool empty() { return _range.empty; }
    void popFront() { _range.popFront(); }
    @property auto front() { return TokenizedItem(_range.front.no, _range.front.item); }
}

auto numbered(R)(R range)
{ 
    return NumberedRange!R(range); 
}

auto withoutEmptyLines(R)(R range)
{
    return NoEmptyLinesRange!R(range);
}

auto withoutComments(R)(R range)
{
    return NoCommentsRange!R(range);
}

auto tokenize(R)(R range)
{
    return TokenizedRange!R(range);
}

ExceptionFlags translateFlags(int intelFlags)
{
    ExceptionFlags result;
    if (intelFlags & 1)
        result |= ExceptionFlags.invalidOperation;
    if (intelFlags & 4)
        result |= ExceptionFlags.divisionByZero;
    if (intelFlags & 8)
        result |= ExceptionFlags.overflow;
    if (intelFlags & 16)
        result |= ExceptionFlags.underflow;
    if (intelFlags & 32)
        result |= ExceptionFlags.inexact;
    return result;
}

RoundingMode translateRounding(int intelRounding)
{
    switch (intelRounding)
    {
        case 0:
            return RoundingMode.tiesToEven;
        case 1:
            return RoundingMode.towardNegative;
        case 2:
            return RoundingMode.towardPositive;
        case 3:
            return RoundingMode.towardZero;
        case 4:
            return RoundingMode.tiesToAway;
        default:
            assert(0);
    }
}

DecimalClass translateClass(int intelClass)
{
    switch (intelClass)
    {
        case 0:
            return DecimalClass.signalingNaN;
        case 1:
            return DecimalClass.quietNaN;
        case 2:
            return DecimalClass.negativeInfinity;
        case 3:
            return DecimalClass.negativeNormal;
        case 4:
            return DecimalClass.negativeSubnormal;
        case 5:
            return DecimalClass.negativeZero;
        case 6:
            return DecimalClass.positiveZero;
        case 7:
            return DecimalClass.positiveSubnormal;
        case 8:
            return DecimalClass.positiveNormal;
        case 9:
            return DecimalClass.positiveInfinity;
        default:
            assert(0);
    }
}

string prettyFlags(ExceptionFlags flags)
{
    char[5] result = '_';

    if (flags & ExceptionFlags.invalidOperation)
        result[0] = 'i';
    if (flags & ExceptionFlags.divisionByZero)
        result[1] = 'z';
    if (flags & ExceptionFlags.overflow)
        result[2] = 'o';
    if (flags & ExceptionFlags.underflow)
        result[3] = 'u';
    if (flags & ExceptionFlags.inexact)
        result[4] = 'x';
    return result.idup;
}

bool equ(T)(const T x, const T y, const bool checkZeroSign)
{
    static if (isDecimal!T)
    {
        if (isZero(x) && isZero(y))
        {
            if (checkZeroSign)
                return signbit(x) == signbit(y);
            else
                return true;
        }
        
        if (isSignaling(x))
            return isSignaling(y);
        if (isNaN(x))
            return isNaN(y);
        if (signbit(x) != signbit(y))
            return false;
        return approxEqual(x, y);
    }
    else static if (isFloatingPoint!T)
    {
        static import std.math;
        if (x == 0 && y == 0)
        {
            if (checkZeroSign)
                return std.math.signbit(x) == std.math.signbit(y);
            else
                return true;
        }
        
        if (std.math.isNaN(x))
            return std.math.isNaN(y);

        if (std.math.signbit(x) != std.math.signbit(y))
            return false;
        if (std.math.isInfinity(x))
            return std.math.isInfinity(y) || y == std.math.copysign(T.max, y);
        if (std.math.isInfinity(y))
            return std.math.isInfinity(x) || x == std.math.copysign(T.max, x);
        return std.math.approxEqual(x, y);
    }
        
    else
        return x == y;
}

bool test0(string func, O, E)(E element, out string errorMessage, const bool checkZeroSign = true)
{
    DecimalControl.rounding = RoundingMode.implicit;
    auto expected = parseOperand!O(element.res);
    mixin("auto result = " ~ func ~ ";");
    bool t1 = equ(result, expected, checkZeroSign);
    bool t2 = true;
    if (!t1)
        errorMessage = format("%6d (%s): %s() => " ~ defaultFormat!O ~ ", expected was " ~ defaultFormat!O, 
                              element.lineNo, element.func, func, result, expected);
    else
        errorMessage = "";
    return t1 && t2;
}

bool test1(string func, I, O, E)(E element, out string errorMessage, const bool checkZeroSign = true)
{
    if (element.lineNo == 16501)
    {
        bool x = true;
    }
    DecimalControl.rounding = RoundingMode.implicit;
    auto input = parseOperand!I(element.op1);
    auto expected = parseOperand!O(element.res);
    DecimalControl.resetFlags();
    DecimalControl.rounding = translateRounding(element.rounding);
    mixin("O result = " ~ func ~ "(input);");
    auto flags = DecimalControl.saveFlags();
    bool t1 = equ(result, expected, checkZeroSign);

    auto expectedFlags = translateFlags(element.expected);

    static if (isDecimal!O || isFloatingPoint!O)
    {
        if (element.func.endsWith("_from_string") && isNaN(expected))
        {
            //intel considers enough to return nan on unparsable strings and does not raise invalidOp
            flags &= ~(ExceptionFlags.invalidOperation);
        }

        static if (isDecimal!O)
        {
            if (element.func.endsWith("_from_string") && isSubnormal(expected))
            {
                //intel does not set underflow flag when parsing subnormals
                flags &= ~(ExceptionFlags.underflow);
            }
        }

        if (element.func.indexOf("binary") >= 0)
        {
            //intel does not set inexact/overflow or set it unexpectedly when converting from binary
            flags &= ExceptionFlags.invalidOperation;
            expectedFlags &= ExceptionFlags.invalidOperation;
            //intel considers float.nan as invalid when converting to decimal
            if (input != input)
            {
                expectedFlags &= ~ExceptionFlags.invalidOperation;
            }
        }

        if (element.func.startsWith("sin") >= 0)
        {
            //intel sets underflow unexpectedly
            flags &= ~ExceptionFlags.underflow;
            expectedFlags &= ~ExceptionFlags.underflow;
        }
    }

    

    bool t2 = flags == expectedFlags;
    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] %s(" ~ defaultFormat!I ~ ") => " ~ defaultFormat!O ~ ", expected was " ~ defaultFormat!O, 
                              element.lineNo, element.func, translateRounding(element.rounding), func, input, result, expected);
    if (!t2)
    {
        if (!t1)
            errorMessage ~= "\r\n";
        errorMessage ~= format("%6d (%s): [%s] %s(" ~ defaultFormat!I ~ ") => " ~ defaultFormat!O ~ ", flags mismatch: result [%s], expected [%s]", 
                              element.lineNo, element.func, translateRounding(element.rounding), func, input, result, prettyFlags(flags), prettyFlags(translateFlags(element.expected)));
    }

    return t1 && t2;
}

bool test_rounding(string func, I, O, E)(E element, out string errorMessage, const RoundingMode mode, const bool checkZeroSign = true)
{
    if (element.lineNo == 79662)
    {
        bool x = true;
    }
    DecimalControl.rounding = RoundingMode.implicit;
    auto input = parseOperand!I(element.op1);
    auto expected = parseOperand!O(element.res);
    DecimalControl.resetFlags();
    DecimalControl.rounding = translateRounding(element.rounding);
    mixin("auto result = " ~ func ~ "(input, mode);");
    auto flags = DecimalControl.saveFlags();
    bool t1 = equ(result, expected, checkZeroSign);
    
    //we must use to!int for lround on 32 bit instead of decimal.lround, which sets ovf flag
    if (element.func.indexOf("lround") >= 0)
        flags &= ~ExceptionFlags.overflow;

    bool t2 = flags == translateFlags(element.expected);
    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] %s(" ~ defaultFormat!I ~ ", %s) => " ~ defaultFormat!O ~ ", expected was " ~ defaultFormat!O, 
                              element.lineNo, element.func, translateRounding(element.rounding), func, input, mode, result, expected);
    if (!t2)
    {
        if (!t1)
            errorMessage ~= "\r\n";
        errorMessage ~= format("%6d (%s): [%s] %s(" ~ defaultFormat!I ~ ", %s) => " ~ defaultFormat!O ~ ", flags mismatch: result [%s], expected [%s]", 
                               element.lineNo, element.func, translateRounding(element.rounding), func, input, mode, result, prettyFlags(flags), prettyFlags(translateFlags(element.expected)));
    }

    return t1 && t2;
}

bool testop(string op, I1, I2, O, E)(E element, out string errorMessage, const bool checkZeroSign = true)
{
    if (element.lineNo == 92365)
    {
        bool x = true;
    }

    DecimalControl.rounding = RoundingMode.implicit;
    auto input1 = parseOperand!I1(element.op1);
    auto input2 = parseOperand!I2(element.op2);
    auto expected = parseOperand!O(element.res);
    DecimalControl.resetFlags();
    DecimalControl.rounding = translateRounding(element.rounding);
    mixin("O result = input1 " ~ op ~ " input2;");
    auto flags = DecimalControl.saveFlags();
    bool t1 = equ(result, expected, checkZeroSign);

    auto expectedFlags = translateFlags(element.expected);
    
    static if (op == "*" || op == "/" || op == "+" || op == "-")
    {
        //intel does not set underflow on subnormals on mul/div
        if (!(expectedFlags & ExceptionFlags.underflow) && (flags & ExceptionFlags.underflow))
            expectedFlags |= ExceptionFlags.underflow;
    }

    static if (op == "*" || op == "/")
    {
        //intel does not set always inexact on mul/div
        if (!(expectedFlags & ExceptionFlags.inexact) && (flags & ExceptionFlags.inexact))
            expectedFlags |= ExceptionFlags.inexact;
    }

    bool t2 = flags == expectedFlags;

    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] " ~ defaultFormat!I1 ~ " %s " ~ defaultFormat!I2 ~ " => " ~ defaultFormat!O ~ ", expected was " ~ defaultFormat!O, 
                              element.lineNo, element.func, translateRounding(element.rounding), input1, op, input2, result, expected);
    if (!t2)
    {
        if (!t1)
            errorMessage ~= "\r\n";
        errorMessage ~= format("%6d (%s): [%s] " ~ defaultFormat!I1 ~ " %s " ~ defaultFormat!I2 ~ " => " ~ defaultFormat!O ~ ", flags mismatch: result [%s], expected [%s]", 
                               element.lineNo, element.func, translateRounding(element.rounding), input1, op, input2, result, prettyFlags(flags), prettyFlags(translateFlags(element.expected)));
    }

    return t1 && t2;
}

bool test2(string func, I1, I2, O, E)(E element, out string errorMessage, const bool checkZeroSign = true)
{
    if (element.lineNo == 125397)
    {
        bool x = true;
    }
    DecimalControl.rounding = RoundingMode.implicit;
    auto input1 = parseOperand!I1(element.op1);
    auto input2 = parseOperand!I2(element.op2);
    auto expected = parseOperand!O(element.res);
    DecimalControl.resetFlags();
    DecimalControl.rounding = translateRounding(element.rounding);
    mixin("auto result = " ~ func ~ "(input1, input2);");
    auto flags = DecimalControl.saveFlags();
    bool t1 = equ(result, expected, checkZeroSign);
    auto expectedFlags = translateFlags(element.expected);

    static if (func.endsWith("remainder"))
    {
        //intel does not set underflow on subnormals remainder
        flags &= ~ExceptionFlags.inexact;
        flags &= ~ExceptionFlags.underflow;
        expectedFlags &= ~ExceptionFlags.inexact;
        expectedFlags &= ~ExceptionFlags.underflow;
    }

    bool t2 = flags == expectedFlags;
    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] %s(" ~ defaultFormat!I1 ~ ", " ~ defaultFormat!I2 ~ ") => " ~ defaultFormat!O ~ ", expected was " ~ defaultFormat!O, 
                              element.lineNo, element.func, translateRounding(element.rounding), func, input1, input2, result, expected);
    if (!t2)
    {
        if (!t1)
            errorMessage ~= "\r\n";
        errorMessage ~= format("%6d (%s): [%s] %s(" ~ defaultFormat!I1 ~ ", " ~ defaultFormat!I2 ~ ") => " ~ defaultFormat!O ~ ", flags mismatch: result [%s], expected [%s]", 
                               element.lineNo, element.func, translateRounding(element.rounding), func, input1, input2, result, prettyFlags(flags), prettyFlags(translateFlags(element.expected)));
    }

    return t1 && t2;
}

bool test3(string func, I1, I2, I3, O, E)(E element, out string errorMessage, const bool checkZeroSign = true)
{
    if (element.lineNo == 45352)
    {
        bool x = true;
    }
    DecimalControl.rounding = RoundingMode.implicit;
    auto input1 = parseOperand!I1(element.op1);
    auto input2 = parseOperand!I2(element.op2);
    auto input3 = parseOperand!I3(element.op3);
    auto expected = parseOperand!O(element.res);
    DecimalControl.resetFlags();
    DecimalControl.rounding = translateRounding(element.rounding);
    mixin("O result = " ~ func ~ "(input1, input2, input3);");
    auto flags = DecimalControl.saveFlags();
    bool t1 = equ(result, expected, checkZeroSign);
    auto expectedFlags = translateFlags(element.expected);

    static if (func.endsWith("fma"))
    {
        //intel does not set underflow on subnormals on fma
        flags &= ~ExceptionFlags.inexact;
        flags &= ~ExceptionFlags.underflow;
        expectedFlags &= ~ExceptionFlags.inexact;
        expectedFlags &= ~ExceptionFlags.underflow;
    }

    bool t2 = flags == expectedFlags;

    


    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] %s(" ~ defaultFormat!I1 ~ ", " ~ defaultFormat!I2 ~ ", " ~ defaultFormat!I3 ~ ") => " ~ defaultFormat!O ~ ", expected was " ~ defaultFormat!O, 
                              element.lineNo, element.func, translateRounding(element.rounding), func, input1, input2, input3, result, expected);
    if (!t2)
    {
        if (!t1)
            errorMessage ~= "\r\n";
        errorMessage ~= format("%6d (%s): [%s] %s(" ~ defaultFormat!I1 ~ ", " ~ defaultFormat!I2 ~ ", " ~ defaultFormat!I3 ~ ") => " ~ defaultFormat!O ~ ", flags mismatch: result [%s], expected [%s]", 
                               element.lineNo, element.func, translateRounding(element.rounding), func, input1, input2, input3, result, prettyFlags(flags), prettyFlags(translateFlags(element.expected)));
    }

    return t1 && t2;
}

bool test_ref(string func, I, O1, O2, E)(E element, out string errorMessage, const bool checkZeroSign = true)
{
    if (element.lineNo == 94002)
    {
        bool x = true;
    }
    DecimalControl.rounding = RoundingMode.implicit;
    auto input1 = parseOperand!I(element.op1);
    auto expectedExp = parseOperand!O1(element.op2);
    auto expected = parseOperand!O2(element.res);
    DecimalControl.resetFlags();
    DecimalControl.rounding = translateRounding(element.rounding);
    O1 resultExp;
    mixin ("auto result = " ~ func ~ "(input1, resultExp);");
    auto flags = DecimalControl.saveFlags();
    bool t1 = equ(result, expected, checkZeroSign);
    t1 = t1 & equ(resultExp, expectedExp, checkZeroSign);
    bool t2 = flags == translateFlags(element.expected);
    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] %s(" ~ defaultFormat!I ~ ") => (" ~ defaultFormat!O2 ~ ", " ~ defaultFormat!O1 ~ "), expected was (" ~ defaultFormat!O2 ~ ", " ~ defaultFormat!O1 ~ ")",
                              element.lineNo, element.func, translateRounding(element.rounding), func, input1, result, resultExp, expected, expectedExp);
    if (!t2)
    {
        if (!t1)
            errorMessage ~= "\r\n";
        errorMessage ~= format("%6d (%s): [%s] %s(" ~ defaultFormat!I ~ ") => (" ~ defaultFormat!O2 ~ ", " ~ defaultFormat!O1 ~ "), flags mismatch: result [%s], expected [%s]", 
                               element.lineNo, element.func, translateRounding(element.rounding), func, input1, result, resultExp, prettyFlags(flags), prettyFlags(translateFlags(element.expected)));
    }

    return t1 && t2;
}


bool test_class(I, E)(E element, out string errorMessage)
{
    auto input = parseOperand!I(element.op1);
    auto expected = parseOperand!int(element.res);
    auto result = decimalClass(input);
    bool t1 = equ(result, translateClass(expected), true);
 
    errorMessage = "";
    if (!t1)
        errorMessage = format("%6d (%s): [%s] decimalClass(" ~ defaultFormat!I ~ ") => %s , expected was %s",
                              element.lineNo, element.func, translateRounding(element.rounding), input, result, translateClass(expected));
    return t1; 
}

template defaultFormat(T)
{
    static if (is(T == decimal32))
        enum defaultFormat = "%+.6e";
    else static if (is(T == decimal64))
        enum defaultFormat = "%+.15e";
    else static if (is(T == decimal128))
        enum defaultFormat = "%+.33e";
    else static if (is(T == uint) || is(T == int) || is(T == ulong) || is(T == long) || is(T == ushort) || is(T == short) || is(T == byte) || is(T == ubyte))
        enum defaultFormat ="%+d";
    else static if (is(T == float) || is(T == double) || is(T == real))
        enum defaultFormat = "%+a";
    else
        enum defaultFormat = "%s";
}

T parseOperand(T)(string op)
{
    static if (is(T == decimal32))
    {
        if (op.startsWith("["))
        {
            decimal32 d;
            string s = op[1 .. $ - 1];
            auto bits = parse!uint(s, 16);
            *cast(uint*)&d = bits;
            return d;
        }
        else
            return decimal32(op);
    }
    else static if (is(T == decimal64))
    {
        if (op.startsWith("["))
        {
            decimal64 d;
            string s = op[1 .. $ - 1];
            auto bits = parse!ulong(s, 16);
            *cast(ulong*)&d = bits;
            return d;
        }
        else
            return decimal64(op);
    }
    else static if (is(T == decimal128))
    {
        if (op.startsWith("["))
        {
            string s1, s2;
            auto v = indexOf(op, ",");
            if (v >= 0)
            {
                s1 = op[1 .. v];
                s2 = op[v + 1 .. $ - 1];
            }
            else
            {
                s1 = op[1 .. 17];
                s2 = op[17 .. $ - 1];
            }
            ulong hi = parse!ulong(s1, 16);
            ulong lo = parse!ulong(s2, 16);
            decimal128 d;
            *cast(ulong[2]*)&d = [lo, hi];
            return d;
        }
        else
            return decimal128(op);
    }
    else static if (is(T == bool))
    {
        return op == "1";
    }
    else static if (is(T == byte) || is(T == short) || is(T == int) || is(T == long))
    {
        if (op == "NULL")
            return 0;
        if (op.startsWith("["))
        {
            auto s = op[1 .. $ - 1];
            return cast(T)parse!(Unsigned!T)(s, 16);
        }
        else
            return to!T(op);
    }
    else static if (is(T == ubyte) || is(T == ushort) || is(T == uint) || is(T == ulong))
    {
        if (op == "NULL")
            return 0;
        if (op.startsWith("["))
        {
            auto s = op[1 .. $ - 1];
            return parse!T(s, 16);
        }
        else if (op.startsWith("-"))
            return cast(T)to!(Signed!T)(op);
        else
            return to!T(op);
    }
    else static if (is(T == float))
    {   
        if (op.startsWith("["))
        {
            auto s = op[1 .. $ - 1];
            auto bits = parse!uint(s, 16);
            float f;
            *cast(uint*)&f = bits;
            return f;
        }
        else
            return to!T(op);
    }
    else static if (is(T == double))
    {   
        if (op.startsWith("["))
        {
            auto s = op[1 .. $ - 1];
            auto bits = parse!ulong(s, 16);
            double d;
            *cast(ulong*)&d = bits;
            return d;
        }
        else
            return to!T(op);
    }
    else static if (is(T == double))
    {   
        if (op.startsWith("["))
        {
            auto s = op[1 .. $ - 1];
            auto bits = parse!ulong(s, 16);
            double d;
            *cast(ulong*)&d = bits;
            return d;
        }
        else
            return to!T(op);
    }
    else static if (is(T == real))
    {   
        if (op.startsWith("["))
        {
            auto s = op[1 .. $ - 1];
            ushort[5] bits;
            auto t = s[0..4];
            bits[4] = parse!ushort(t, 16);
            t = s[4..8];
            bits[3] = parse!ushort(t, 16);
            t = s[8..12];
            bits[2] = parse!ushort(t, 16);
            t = s[12..16];
            bits[1] = parse!ushort(t, 16);
            t = s[16..20];
            bits[0] = parse!ushort(t, 16);
            real r;
            *cast(ushort[5]*)&r = bits;
            return r;
        }
        else
            return to!T(op);
    }
    else static if (is(T: string))
    {
        if (op == "EMPTY")
            return "";
        else
            return op;
    }
    else
        static assert(0);
}

struct Stat
{
    int total;
    int skipped;
    int failed;
    int notApplicable;
    int passed;
}

int main(string[] argv)
{

  
    auto file = File(inputFileName);

    auto range = file.byLine()
        .numbered()
        .withoutEmptyLines()
        .withoutComments()
        .tokenize();

    Stat[string] tests;

    foreach(element; range)
    {
        if (auto p = element.func in tests)
            ++((*p).total);
        else
            tests[element.func]= Stat(1, 0, 0, 0, 0);

        string msg;
        bool na = false;
        bool skip = false;
        bool outcome = false;
        switch(element.func)
        {
            case "bid32_abs":
                outcome = test1!("fabs", decimal32, decimal32)(element, msg);
                break;
            case "bid64_abs":
                outcome = test1!("fabs", decimal64, decimal64)(element, msg);
                break;
            case "bid128_abs":
                outcome = test1!("fabs", decimal128, decimal128)(element, msg);
                break;
            case "bid32_isInf":
                outcome = test1!("isInfinity", decimal32, bool)(element, msg);
                break;
            case "bid64_isInf":
                outcome = test1!("isInfinity", decimal64, bool)(element, msg);
                break;
            case "bid128_isInf":
                outcome = test1!("isInfinity", decimal128, bool)(element, msg);
                break;
            case "bid32_isNaN":
                outcome = test1!("isNaN", decimal32, bool)(element, msg);
                break;
            case "bid64_isNaN":
                outcome = test1!("isNaN", decimal64, bool)(element, msg);
                break;
            case "bid128_isNaN":
                outcome = test1!("isNaN", decimal128, bool)(element, msg);
                break;
            case "bid32_isFinite":
                outcome = test1!("isFinite", decimal32, bool)(element, msg);
                break;
            case "bid64_isFinite":
                outcome = test1!("isFinite", decimal64, bool)(element, msg);
                break;
            case "bid128_isFinite":
                outcome = test1!("isFinite", decimal128, bool)(element, msg);
                break;
            case "bid32_isZero":
                outcome = test1!("isZero", decimal32, bool)(element, msg);
                break;
            case "bid64_isZero":
                outcome = test1!("isZero", decimal64, bool)(element, msg);
                break;
            case "bid128_isZero":
                outcome = test1!("isZero", decimal128, bool)(element, msg);
                break;
            case "bid32_isSubnormal":
                outcome = test1!("isSubnormal", decimal32, bool)(element, msg);
                break;
            case "bid64_isSubnormal":
                outcome = test1!("isSubnormal", decimal64, bool)(element, msg);
                break;
            case "bid128_isSubnormal":
                outcome = test1!("isSubnormal", decimal128, bool)(element, msg);
                break;
            case "bid32_isSignaling":
                outcome = test1!("isSignaling", decimal32, bool)(element, msg);
                break;
            case "bid64_isSignaling":
                outcome = test1!("isSignaling", decimal64, bool)(element, msg);
                break;
            case "bid128_isSignaling":
                outcome = test1!("isSignaling", decimal128, bool)(element, msg);
                break;
            case "bid32_isNormal":
                outcome = test1!("isNormal", decimal32, bool)(element, msg);
                break;
            case "bid64_isNormal":
                outcome = test1!("isNormal", decimal64, bool)(element, msg);
                break;
            case "bid128_isNormal":
                outcome = test1!("isNormal", decimal128, bool)(element, msg);
                break;
            case "bid32_isCanonical":
                outcome = test1!("isCanonical", decimal32, bool)(element, msg);
                break;
            case "bid64_isCanonical":
                outcome = test1!("isCanonical", decimal64, bool)(element, msg);
                break;
            case "bid128_isCanonical":
                outcome = test1!("isCanonical", decimal128, bool)(element, msg);
                break;
            case "bid32_isSigned":
                outcome = test1!("signbit", decimal32, int)(element, msg);
                break;
            case "bid64_isSigned":
                outcome = test1!("signbit", decimal64, int)(element, msg);
                break;
            case "bid128_isSigned":
                outcome = test1!("signbit", decimal128, int)(element, msg);
                break;
            case "bid32_copy":
                outcome = test1!("decimal32", decimal32, decimal32)(element, msg);
                break;
            case "bid64_copy":
                outcome = test1!("decimal64", decimal64, decimal64)(element, msg);
                break;
            case "bid128_copy":
                outcome = test1!("decimal128", decimal128, decimal128)(element, msg);
                break;
            case "bid32_negate":
                outcome = test1!("-", decimal32, decimal32)(element, msg);
                break;
            case "bid64_negate":
                outcome = test1!("-", decimal64, decimal64)(element, msg);
                break;
            case "bid128_negate":
                outcome = test1!("-", decimal128, decimal128)(element, msg);
                break;
            case "bid32_inf":
                outcome = test0!("decimal32.infinity", decimal32)(element, msg);
                break;
            case "bid64_inf":
                outcome = test0!("decimal64.infinity", decimal64)(element, msg);
                break;
            case "bid128_inf":
                outcome = test0!("decimal128.infinity", decimal128)(element, msg);
                break;
            case "bid32_nan":
                outcome = test1!("NaN!decimal32", uint, decimal32)(element, msg);
                break;
            case "bid64_nan":
                outcome = test1!("NaN!decimal64", ulong, decimal64)(element, msg);
                break;
            case "bid128_nan":
                outcome = test1!("NaN!decimal128", ulong, decimal128)(element, msg);
                break;
            case "bid32_copySign":
                outcome = test2!("copysign", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_copySign":
                outcome = test2!("copysign", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_copySign":
                outcome = test2!("copysign", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_from_int32":
                outcome = test1!("decimal32", int, decimal32)(element, msg);
                break;
            case "bid64_from_int32":
                outcome = test1!("decimal64", int, decimal64)(element, msg);
                break;
            case "bid128_from_int32":
                outcome = test1!("decimal128", int, decimal128)(element, msg);
                break;
            case "bid32_from_int64":
                outcome = test1!("decimal32", long, decimal32)(element, msg);
                break;
            case "bid64_from_int64":
                outcome = test1!("decimal64", long, decimal64)(element, msg);
                break;
            case "bid128_from_int64":
                outcome = test1!("decimal128", long, decimal128)(element, msg);
                break;
            case "bid32_from_uint32":
                outcome = test1!("decimal32", uint, decimal32)(element, msg);
                break;
            case "bid64_from_uint32":
                outcome = test1!("decimal64", uint, decimal64)(element, msg);
                break;
            case "bid128_from_uint32":
                outcome = test1!("decimal128", uint, decimal128)(element, msg);
                break;
            case "bid32_from_uint64":
                outcome = test1!("decimal32", ulong, decimal32)(element, msg);
                break;
            case "bid64_from_uint64":
                outcome = test1!("decimal64", ulong, decimal64)(element, msg);
                break;
            case "bid128_from_uint64":
                outcome = test1!("decimal128", ulong, decimal128)(element, msg);
                break;
            case "binary32_to_bid32":
                outcome = test1!("decimal32", float, decimal32)(element, msg);
                break;
            case "binary64_to_bid32":
                outcome = test1!("decimal32", double, decimal32)(element, msg);
                break;
            case "binary80_to_bid32":
                outcome = test1!("decimal32", real, decimal32)(element, msg);
                break;
            case "binary32_to_bid64":
                outcome = test1!("decimal64", float, decimal64)(element, msg);
                break;
            case "binary64_to_bid64":
                outcome = test1!("decimal64", double, decimal64)(element, msg);
                break;
            case "binary80_to_bid64":
                outcome = test1!("decimal64", real, decimal64)(element, msg);
                break;
            case "binary32_to_bid128":
                outcome = test1!("decimal128", float, decimal128)(element, msg);
                break;
            case "binary64_to_bid128":
                outcome = test1!("decimal128", double, decimal128)(element, msg);
                break;
            case "binary80_to_bid128":
                outcome = test1!("decimal128", real, decimal128)(element, msg);
                break;
            case "bid32_to_binary32":
                outcome = test1!("cast(float)", decimal32, float)(element, msg);
                break;
            case "bid32_to_binary64":
                outcome = test1!("cast(double)", decimal32, double)(element, msg);
                break;
            case "bid32_to_binary80":
                outcome = test1!("cast(real)", decimal32, real)(element, msg);
                break;
            case "bid64_to_binary32":
                outcome = test1!("cast(float)", decimal64, float)(element, msg);
                break;
            case "bid64_to_binary64":
                outcome = test1!("cast(double)", decimal64, double)(element, msg);
                break;
            case "bid64_to_binary80":
                outcome = test1!("cast(real)", decimal64, real)(element, msg);
                break;
            case "bid128_to_binary32":
                outcome = test1!("cast(float)", decimal128, float)(element, msg);
                break;
            case "bid128_to_binary64":
                outcome = test1!("cast(double)", decimal128, double)(element, msg);
                break;
            case "bid128_to_binary80":
                outcome = test1!("cast(real)", decimal128, real)(element, msg);
                break;
            case "bid32_ilogb":
                outcome = test1!("ilogb", decimal32, int)(element, msg);
                break;
            case "bid64_ilogb":
                outcome = test1!("ilogb", decimal64, int)(element, msg);
                break;
            case "bid128_ilogb":
                outcome = test1!("ilogb", decimal128, int)(element, msg);
                break;
            case "bid32_maxnum":
                outcome = test2!("fmax", decimal32, decimal32, decimal32)(element, msg, false);
                break;
            case "bid64_maxnum":
                outcome = test2!("fmax", decimal64, decimal64, decimal64)(element, msg, false);
                break;
            case "bid128_maxnum":
                outcome = test2!("fmax", decimal128, decimal128, decimal128)(element, msg, false);
                break;
            case "bid32_maxnum_mag":
                outcome = test2!("fmaxAbs", decimal32, decimal32, decimal32)(element, msg, false);
                break;
            case "bid64_maxnum_mag":
                outcome = test2!("fmaxAbs", decimal64, decimal64, decimal64)(element, msg, false);
                break;
            case "bid128_maxnum_mag":
                outcome = test2!("fmaxAbs", decimal128, decimal128, decimal128)(element, msg, false);
                break;
            case "bid32_minnum":
                outcome = test2!("fmin", decimal32, decimal32, decimal32)(element, msg, false);
                break;
            case "bid64_minnum":
                outcome = test2!("fmin", decimal64, decimal64, decimal64)(element, msg, false);
                break;
            case "bid128_minnum":
                outcome = test2!("fmin", decimal128, decimal128, decimal128)(element, msg, false);
                break;
            case "bid32_minnum_mag":
                outcome = test2!("fminAbs", decimal32, decimal32, decimal32)(element, msg, false);
                break;
            case "bid64_minnum_mag":
                outcome = test2!("fminAbs", decimal64, decimal64, decimal64)(element, msg, false);
                break;
            case "bid128_minnum_mag":
                outcome = test2!("fminAbs", decimal128, decimal128, decimal128)(element, msg, false);
                break;
            case "bid32_quiet_equal":
                outcome = testop!("==", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_equal":
                outcome = testop!("==", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_equal":
                outcome = testop!("==", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_not_equal":
                outcome = testop!("!=", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_not_equal":
                outcome = testop!("!=", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_not_equal":
                outcome = testop!("!=", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_greater":
                outcome = test2!("isGreater", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_greater":
                outcome = test2!("isGreater", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_greater":
                outcome = test2!("isGreater", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_signaling_greater":
                outcome = testop!(">", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_signaling_greater":
                outcome = testop!(">", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_signaling_greater":
                outcome = testop!(">", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_greater_equal":
                outcome = test2!("isGreaterOrEqual", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_greater_equal":
                outcome = test2!("isGreaterOrEqual", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_greater_equal":
                outcome = test2!("isGreaterOrEqual", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_signaling_greater_equal":
                outcome = testop!(">=", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_signaling_greater_equal":
                outcome = testop!(">=", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_signaling_greater_equal":
                outcome = testop!(">=", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_greater_unordered":
                outcome = test2!("isGreaterOrUnordered", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_greater_unordered":
                outcome = test2!("isGreaterOrUnordered", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_greater_unordered":
                outcome = test2!("isGreaterOrUnordered", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_less":
                outcome = test2!("isLess", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_less":
                outcome = test2!("isLess", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_less":
                outcome = test2!("isLess", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_signaling_less":
                outcome = testop!("<", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_signaling_less":
                outcome = testop!("<", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_signaling_less":
                outcome = testop!("<", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_less_equal":
                outcome = test2!("isLessOrEqual", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_less_equal":
                outcome = test2!("isLessOrEqual", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_less_equal":
                outcome = test2!("isLessOrEqual", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_signaling_less_equal":
                outcome = testop!("<=", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_signaling_less_equal":
                outcome = testop!("<=", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_signaling_less_equal":
                outcome = testop!("<=", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_less_unordered":
                outcome = test2!("isLessOrUnordered", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_less_unordered":
                outcome = test2!("isLessOrUnordered", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_less_unordered":
                outcome = test2!("isLessOrUnordered", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_not_greater":
                outcome = test2!("!isGreater", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_not_greater":
                outcome = test2!("!isGreater", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_not_greater":
                outcome = test2!("!isGreater", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_not_less":
                outcome = test2!("!isLess", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_not_less":
                outcome = test2!("!isLess", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_not_less":
                outcome = test2!("!isLess", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_ordered":
                outcome = test2!("!isUnordered", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_ordered":
                outcome = test2!("!isUnordered", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_ordered":
                outcome = test2!("!isUnordered", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_quiet_unordered":
                outcome = test2!("isUnordered", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_quiet_unordered":
                outcome = test2!("isUnordered", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_quiet_unordered":
                outcome = test2!("isUnordered", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_to_bid64":
                outcome = test1!("decimal64", decimal32, decimal64)(element, msg);
                break;
            case "bid32_to_bid128":
                outcome = test1!("decimal128", decimal32, decimal128)(element, msg);
                break;
            case "bid64_to_bid128":
                outcome = test1!("decimal128", decimal64, decimal128)(element, msg);
                break;
            case "bid64_to_bid32":
                outcome = test1!("decimal32", decimal64, decimal32)(element, msg);
                break;
            case "bid128_to_bid32":
                outcome = test1!("decimal32", decimal128, decimal32)(element, msg);
                break;
            case "bid128_to_bid64":
                outcome = test1!("decimal64", decimal128, decimal64)(element, msg);
                break;
            case "bid32_nextdown":
                outcome = test1!("nextDown", decimal32, decimal32)(element, msg);
                break;
            case "bid64_nextdown":
                outcome = test1!("nextDown", decimal64, decimal64)(element, msg);
                break;
            case "bid128_nextdown":
                outcome = test1!("nextDown", decimal128, decimal128)(element, msg);
                break;
            case "bid32_nextup":
                outcome = test1!("nextUp", decimal32, decimal32)(element, msg);
                break;
            case "bid64_nextup":
                outcome = test1!("nextUp", decimal64, decimal64)(element, msg);
                break;
            case "bid128_nextup":
                outcome = test1!("nextUp", decimal128, decimal128)(element, msg);
                break;
            case "bid32_class":
                outcome = test_class!decimal32(element, msg);
                break;
            case "bid64_class":
                outcome = test_class!decimal64(element, msg);
                break;
            case "bid128_class":
                outcome = test_class!decimal128(element, msg);
                break;
            case "bid32_from_string":
                outcome = test1!("decimal32", string, decimal32)(element, msg);
                break;
            case "bid64_from_string":
                outcome = test1!("decimal64", string, decimal64)(element, msg);
                break;
            case "bid128_from_string":
                outcome = test1!("decimal128", string, decimal128)(element, msg);
                break;
            case "bid32_add":
                outcome = testop!("+", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_add":
                outcome = testop!("+", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid64dq_add":
                outcome = testop!("+", decimal64, decimal128, decimal64)(element, msg);
                break;
            case "bid64qd_add":
                outcome = testop!("+", decimal128, decimal64, decimal64)(element, msg);
                break;
            case "bid64qq_add":
                outcome = testop!("+", decimal128, decimal128, decimal64)(element, msg);
                break;
            case "bid128_add":
                outcome = testop!("+", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_sub":
                outcome = testop!("-", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_sub":
                outcome = testop!("-", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid64dq_sub":
                outcome = testop!("-", decimal64, decimal128, decimal64)(element, msg);
                break;
            case "bid64qd_sub":
                outcome = testop!("-", decimal128, decimal64, decimal64)(element, msg);
                break;
            case "bid64qq_sub":
                outcome = testop!("-", decimal128, decimal128, decimal64)(element, msg, false);
                break;
            case "bid128_sub":
                outcome = testop!("-", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_mul":
                outcome = testop!("*", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_mul":
                outcome = testop!("*", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid64dq_mul":
                outcome = testop!("*", decimal64, decimal128, decimal64)(element, msg);
                break;
            case "bid64qd_mul":
                outcome = testop!("*", decimal128, decimal64, decimal64)(element, msg);
                break;
            case "bid64qq_mul":
                outcome = testop!("*", decimal128, decimal128, decimal64)(element, msg);
                break;
            case "bid128_mul":
                outcome = testop!("*", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_div":
                outcome = testop!("/", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_div":
                outcome = testop!("/", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid64dq_div":
                outcome = testop!("/", decimal64, decimal128, decimal64)(element, msg);
                break;
            case "bid64qd_div":
                outcome = testop!("/", decimal128, decimal64, decimal64)(element, msg);
                break;
            case "bid64qq_div":
                outcome = testop!("/", decimal128, decimal128, decimal64)(element, msg);
                break;
            case "bid128_div":
                outcome = testop!("/", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_rem":
                outcome = test2!("remainder", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_rem":
                outcome = test2!("remainder", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_rem":
                outcome = test2!("remainder", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_hypot":
                outcome = test2!("hypot", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_hypot":
                outcome = test2!("hypot", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_hypot":
                outcome = test2!("hypot", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_totalOrder":
                outcome = test2!("totalOrder", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_totalOrder":
                outcome = test2!("totalOrder", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_totalOrder":
                outcome = test2!("totalOrder", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_totalOrderMag":
                outcome = test2!("totalOrderAbs", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_totalOrderMag":
                outcome = test2!("totalOrderAbs", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_totalOrderMag":
                outcome = test2!("totalOrderAbs", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_sameQuantum":
                outcome = test2!("sameQuantum", decimal32, decimal32, bool)(element, msg);
                break;
            case "bid64_sameQuantum":
                outcome = test2!("sameQuantum", decimal64, decimal64, bool)(element, msg);
                break;
            case "bid128_sameQuantum":
                outcome = test2!("sameQuantum", decimal128, decimal128, bool)(element, msg);
                break;
            case "bid32_fmod":
                outcome = test2!("fmod", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_fmod":
                outcome = test2!("fmod", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_fmod":
                outcome = test2!("fmod", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_quantize":
                outcome = test2!("quantize", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_quantize":
                outcome = test2!("quantize", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_quantize":
                outcome = test2!("quantize", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_fdim":
                outcome = test2!("fdim", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_fdim":
                outcome = test2!("fdim", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_fdim":
                outcome = test2!("fdim", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_nextafter":
                outcome = test2!("nextAfter", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_nextafter":
                outcome = test2!("nextAfter", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_nextafter":
                outcome = test2!("nextAfter", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_nexttoward":
                outcome = test2!("nextToward", decimal32, decimal128, decimal32)(element, msg);
                break;
            case "bid64_nexttoward":
                outcome = test2!("nextToward", decimal64, decimal128, decimal64)(element, msg);
                break;
            case "bid32_fma":
                outcome = test3!("fma", decimal32, decimal32, decimal32, decimal32)(element, msg, false);
                break;
            case "bid64_fma":
                outcome = test3!("fma", decimal64, decimal64, decimal64, decimal64)(element, msg, false);
                break;
            case "bid128_fma":
                outcome = test3!("fma", decimal128, decimal128, decimal128, decimal128)(element, msg, false);
                break;
            case "bid64ddq_fma":
                outcome = test3!("fma", decimal64, decimal64, decimal128, decimal64)(element, msg, false);
                break;
            case "bid64dqd_fma":
                outcome = test3!("fma", decimal64, decimal128, decimal64, decimal64)(element, msg, false);
                break;
            case "bid64dqq_fma":
                outcome = test3!("fma", decimal64, decimal128, decimal128, decimal64)(element, msg, false);
                break;
            case "bid64qdd_fma":
                outcome = test3!("fma", decimal128, decimal64, decimal64, decimal64)(element, msg, false);
                break;
            case "bid64qdq_fma":
                outcome = test3!("fma", decimal128, decimal64, decimal128, decimal64)(element, msg, false);
                break;
            case "bid64qqq_fma":
                outcome = test3!("fma", decimal128, decimal128, decimal128, decimal64)(element, msg, false);
                break;
            case "bid64qqd_fma":
                outcome = test3!("fma", decimal128, decimal128, decimal64, decimal64)(element, msg, false);
                break;
            case "bid128_nexttoward":
                outcome = test2!("nextToward", decimal128, decimal128, decimal128)(element, msg);
                break;
            //case "bid32_rem":
            //    outcome = test2!("remainder", decimal32, decimal32, decimal32)(element, msg);
            //    break;
            case "bid32_lround":
                if (element.longintsize == 64)
                    outcome = test1!("lround", decimal32, long)(element, msg);
                else
                    outcome = test_rounding!("decimal.to!int", decimal32, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_lround":
                if (element.longintsize == 64)
                    outcome = test1!("lround", decimal64, long)(element, msg);
                else
                    outcome = test_rounding!("decimal.to!int", decimal64, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_lround":
                if (element.longintsize == 64)
                    outcome = test1!("lround", decimal128, long)(element, msg);
                else
                    outcome = test_rounding!("decimal.to!int", decimal128, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_llrint":
                outcome = test1!("lrint", decimal32, long)(element, msg);
                break;
            case "bid64_llrint":
                outcome = test1!("lrint", decimal64, long)(element, msg);
                break;
            case "bid128_llrint":
                outcome = test1!("lrint", decimal128, long)(element, msg);
                break;
            case "bid32_lrint":
                if (element.longintsize == 64)
                    outcome = test1!("lrint", decimal32, long)(element, msg);
                else
                    outcome = test_rounding!("toExact!int", decimal32, int)(element, msg, translateRounding(element.rounding));
                break;
            case "bid64_lrint":
                if (element.longintsize == 64)
                    outcome = test1!("lrint", decimal64, long)(element, msg);
                else
                    outcome = test_rounding!("toExact!int", decimal64, int)(element, msg, translateRounding(element.rounding));
                break;
            case "bid128_lrint":
                if (element.longintsize == 64)
                    outcome = test1!("lrint", decimal128, long)(element, msg);
                else
                    outcome = test_rounding!("toExact!int", decimal128, int)(element, msg, translateRounding(element.rounding));
                break;
            case "bid32_round_integral_nearest_away":
                outcome = test_rounding!("nearbyint", decimal32, decimal32)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_round_integral_nearest_even":
                outcome = test_rounding!("nearbyint", decimal32, decimal32)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_round_integral_negative":
                outcome = test_rounding!("nearbyint", decimal32, decimal32)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_round_integral_positive":
                outcome = test_rounding!("nearbyint", decimal32, decimal32)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_round_integral_zero":
                outcome = test_rounding!("nearbyint", decimal32, decimal32)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_round_integral_exact":
                outcome = test1!("rint", decimal32, decimal32)(element, msg);
                break;
            case "bid64_round_integral_nearest_away":
                outcome = test_rounding!("nearbyint", decimal64, decimal64)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_round_integral_nearest_even":
                outcome = test_rounding!("nearbyint", decimal64, decimal64)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_round_integral_negative":
                outcome = test_rounding!("nearbyint", decimal64, decimal64)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_round_integral_positive":
                outcome = test_rounding!("nearbyint", decimal64, decimal64)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_round_integral_zero":
                outcome = test_rounding!("nearbyint", decimal64, decimal64)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_round_integral_exact":
                outcome = test1!("rint", decimal64, decimal64)(element, msg);
                break;
            case "bid128_round_integral_nearest_away":
                outcome = test_rounding!("nearbyint", decimal128, decimal128)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_round_integral_nearest_even":
                outcome = test_rounding!("nearbyint", decimal128, decimal128)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_round_integral_negative":
                outcome = test_rounding!("nearbyint", decimal128, decimal128)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_round_integral_positive":
                outcome = test_rounding!("nearbyint", decimal128, decimal128)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_round_integral_zero":
                outcome = test_rounding!("nearbyint", decimal128, decimal128)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_nearbyint":
                outcome = test1!("nearbyint", decimal32, decimal32)(element, msg);
                break;
            case "bid64_nearbyint":
                outcome = test1!("nearbyint", decimal64, decimal64)(element, msg);
                break;
            case "bid128_nearbyint":
                outcome = test1!("nearbyint", decimal128, decimal128)(element, msg);
                break;
            case "bid128_round_integral_exact":
                outcome = test1!("rint", decimal128, decimal128)(element, msg);
                break;
            case "bid32_to_int8_ceil":
                outcome = test_rounding!("decimal.to!byte", decimal32, byte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int8_floor":
                outcome = test_rounding!("decimal.to!byte", decimal32, byte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int8_rninta":
                outcome = test_rounding!("decimal.to!byte", decimal32, byte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int8_int":
                outcome = test_rounding!("decimal.to!byte", decimal32, byte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int8_rnint":
                outcome = test_rounding!("decimal.to!byte", decimal32, byte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int8_xceil":
                outcome = test_rounding!("decimal.toExact!byte", decimal32, byte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int8_xfloor":
                outcome = test_rounding!("decimal.toExact!byte", decimal32, byte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int8_xrninta":
                outcome = test_rounding!("decimal.toExact!byte", decimal32, byte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int8_xint":
                outcome = test_rounding!("decimal.toExact!byte", decimal32, byte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int8_xrnint":
                outcome = test_rounding!("decimal.toExact!byte", decimal32, byte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint8_ceil":
                outcome = test_rounding!("decimal.to!ubyte", decimal32, ubyte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint8_floor":
                outcome = test_rounding!("decimal.to!ubyte", decimal32, ubyte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint8_rninta":
                outcome = test_rounding!("decimal.to!ubyte", decimal32, ubyte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint8_int":
                outcome = test_rounding!("decimal.to!ubyte", decimal32, ubyte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint8_rnint":
                outcome = test_rounding!("decimal.to!ubyte", decimal32, ubyte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint8_xceil":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal32, ubyte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint8_xfloor":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal32, ubyte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint8_xrninta":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal32, ubyte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint8_xint":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal32, ubyte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint8_xrnint":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal32, ubyte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int16_ceil":
                outcome = test_rounding!("decimal.to!short", decimal32, short)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int16_floor":
                outcome = test_rounding!("decimal.to!short", decimal32, short)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int16_rninta":
                outcome = test_rounding!("decimal.to!short", decimal32, short)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int16_int":
                outcome = test_rounding!("decimal.to!short", decimal32, short)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int16_rnint":
                outcome = test_rounding!("decimal.to!short", decimal32, short)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int16_xceil":
                outcome = test_rounding!("decimal.toExact!short", decimal32, short)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int16_xfloor":
                outcome = test_rounding!("decimal.toExact!short", decimal32, short)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int16_xrninta":
                outcome = test_rounding!("decimal.toExact!short", decimal32, short)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int16_xint":
                outcome = test_rounding!("decimal.toExact!short", decimal32, short)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int16_xrnint":
                outcome = test_rounding!("decimal.toExact!short", decimal32, short)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint16_ceil":
                outcome = test_rounding!("decimal.to!ushort", decimal32, ushort)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint16_floor":
                outcome = test_rounding!("decimal.to!ushort", decimal32, ushort)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint16_rninta":
                outcome = test_rounding!("decimal.to!ushort", decimal32, ushort)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint16_int":
                outcome = test_rounding!("decimal.to!ushort", decimal32, ushort)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint16_rnint":
                outcome = test_rounding!("decimal.to!ushort", decimal32, ushort)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint16_xceil":
                outcome = test_rounding!("decimal.toExact!ushort", decimal32, ushort)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint16_xfloor":
                outcome = test_rounding!("decimal.toExact!ushort", decimal32, ushort)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint16_xrninta":
                outcome = test_rounding!("decimal.toExact!ushort", decimal32, ushort)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint16_xint":
                outcome = test_rounding!("decimal.toExact!ushort", decimal32, ushort)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint16_xrnint":
                outcome = test_rounding!("decimal.toExact!ushort", decimal32, ushort)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int32_ceil":
                outcome = test_rounding!("decimal.to!int", decimal32, int)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int32_floor":
                outcome = test_rounding!("decimal.to!int", decimal32, int)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int32_rninta":
                outcome = test_rounding!("decimal.to!int", decimal32, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int32_int":
                outcome = test_rounding!("decimal.to!int", decimal32, int)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int32_rnint":
                outcome = test_rounding!("decimal.to!int", decimal32, int)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int32_xceil":
                outcome = test_rounding!("decimal.toExact!int", decimal32, int)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int32_xfloor":
                outcome = test_rounding!("decimal.toExact!int", decimal32, int)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int32_xrninta":
                outcome = test_rounding!("decimal.toExact!int", decimal32, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int32_xint":
                outcome = test_rounding!("decimal.toExact!int", decimal32, int)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int32_xrnint":
                outcome = test_rounding!("decimal.toExact!int", decimal32, int)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint32_ceil":
                outcome = test_rounding!("decimal.to!uint", decimal32, uint)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint32_floor":
                outcome = test_rounding!("decimal.to!uint", decimal32, uint)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint32_rninta":
                outcome = test_rounding!("decimal.to!uint", decimal32, uint)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint32_int":
                outcome = test_rounding!("decimal.to!uint", decimal32, uint)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint32_rnint":
                outcome = test_rounding!("decimal.to!uint", decimal32, uint)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint32_xceil":
                outcome = test_rounding!("decimal.toExact!uint", decimal32, uint)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint32_xfloor":
                outcome = test_rounding!("decimal.toExact!uint", decimal32, uint)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint32_xrninta":
                outcome = test_rounding!("decimal.toExact!uint", decimal32, uint)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint32_xint":
                outcome = test_rounding!("decimal.toExact!uint", decimal32, uint)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint32_xrnint":
                outcome = test_rounding!("decimal.toExact!uint", decimal32, uint)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int64_ceil":
                outcome = test_rounding!("decimal.to!long", decimal32, long)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int64_floor":
                outcome = test_rounding!("decimal.to!long", decimal32, long)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int64_rninta":
                outcome = test_rounding!("decimal.to!long", decimal32, long)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int64_int":
                outcome = test_rounding!("decimal.to!long", decimal32, long)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int64_rnint":
                outcome = test_rounding!("decimal.to!long", decimal32, long)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_int64_xceil":
                outcome = test_rounding!("decimal.toExact!long", decimal32, long)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_int64_xfloor":
                outcome = test_rounding!("decimal.toExact!long", decimal32, long)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_int64_xrninta":
                outcome = test_rounding!("decimal.toExact!long", decimal32, long)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_int64_xint":
                outcome = test_rounding!("decimal.toExact!long", decimal32, long)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_int64_xrnint":
                outcome = test_rounding!("decimal.toExact!long", decimal32, long)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint64_ceil":
                outcome = test_rounding!("decimal.to!ulong", decimal32, ulong)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint64_floor":
                outcome = test_rounding!("decimal.to!ulong", decimal32, ulong)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint64_rninta":
                outcome = test_rounding!("decimal.to!ulong", decimal32, ulong)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint64_int":
                outcome = test_rounding!("decimal.to!ulong", decimal32, ulong)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint64_rnint":
                outcome = test_rounding!("decimal.to!ulong", decimal32, ulong)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_to_uint64_xceil":
                outcome = test_rounding!("decimal.toExact!ulong", decimal32, ulong)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid32_to_uint64_xfloor":
                outcome = test_rounding!("decimal.toExact!ulong", decimal32, ulong)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid32_to_uint64_xrninta":
                outcome = test_rounding!("decimal.toExact!ulong", decimal32, ulong)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid32_to_uint64_xint":
                outcome = test_rounding!("decimal.toExact!ulong", decimal32, ulong)(element, msg, RoundingMode.towardZero);
                break;
            case "bid32_to_uint64_xrnint":
                outcome = test_rounding!("decimal.toExact!ulong", decimal32, ulong)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int8_ceil":
                outcome = test_rounding!("decimal.to!byte", decimal64, byte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int8_floor":
                outcome = test_rounding!("decimal.to!byte", decimal64, byte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int8_rninta":
                outcome = test_rounding!("decimal.to!byte", decimal64, byte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int8_int":
                outcome = test_rounding!("decimal.to!byte", decimal64, byte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int8_rnint":
                outcome = test_rounding!("decimal.to!byte", decimal64, byte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int8_xceil":
                outcome = test_rounding!("decimal.toExact!byte", decimal64, byte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int8_xfloor":
                outcome = test_rounding!("decimal.toExact!byte", decimal64, byte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int8_xrninta":
                outcome = test_rounding!("decimal.toExact!byte", decimal64, byte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int8_xint":
                outcome = test_rounding!("decimal.toExact!byte", decimal64, byte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int8_xrnint":
                outcome = test_rounding!("decimal.toExact!byte", decimal64, byte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint8_ceil":
                outcome = test_rounding!("decimal.to!ubyte", decimal64, ubyte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint8_floor":
                outcome = test_rounding!("decimal.to!ubyte", decimal64, ubyte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint8_rninta":
                outcome = test_rounding!("decimal.to!ubyte", decimal64, ubyte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint8_int":
                outcome = test_rounding!("decimal.to!ubyte", decimal64, ubyte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint8_rnint":
                outcome = test_rounding!("decimal.to!ubyte", decimal64, ubyte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint8_xceil":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal64, ubyte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint8_xfloor":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal64, ubyte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint8_xrninta":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal64, ubyte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint8_xint":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal64, ubyte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint8_xrnint":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal64, ubyte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int16_ceil":
                outcome = test_rounding!("decimal.to!short", decimal64, short)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int16_floor":
                outcome = test_rounding!("decimal.to!short", decimal64, short)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int16_rninta":
                outcome = test_rounding!("decimal.to!short", decimal64, short)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int16_int":
                outcome = test_rounding!("decimal.to!short", decimal64, short)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int16_rnint":
                outcome = test_rounding!("decimal.to!short", decimal64, short)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int16_xceil":
                outcome = test_rounding!("decimal.toExact!short", decimal64, short)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int16_xfloor":
                outcome = test_rounding!("decimal.toExact!short", decimal64, short)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int16_xrninta":
                outcome = test_rounding!("decimal.toExact!short", decimal64, short)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int16_xint":
                outcome = test_rounding!("decimal.toExact!short", decimal64, short)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int16_xrnint":
                outcome = test_rounding!("decimal.toExact!short", decimal64, short)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint16_ceil":
                outcome = test_rounding!("decimal.to!ushort", decimal64, ushort)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint16_floor":
                outcome = test_rounding!("decimal.to!ushort", decimal64, ushort)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint16_rninta":
                outcome = test_rounding!("decimal.to!ushort", decimal64, ushort)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint16_int":
                outcome = test_rounding!("decimal.to!ushort", decimal64, ushort)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint16_rnint":
                outcome = test_rounding!("decimal.to!ushort", decimal64, ushort)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint16_xceil":
                outcome = test_rounding!("decimal.toExact!ushort", decimal64, ushort)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint16_xfloor":
                outcome = test_rounding!("decimal.toExact!ushort", decimal64, ushort)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint16_xrninta":
                outcome = test_rounding!("decimal.toExact!ushort", decimal64, ushort)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint16_xint":
                outcome = test_rounding!("decimal.toExact!ushort", decimal64, ushort)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint16_xrnint":
                outcome = test_rounding!("decimal.toExact!ushort", decimal64, ushort)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int32_ceil":
                outcome = test_rounding!("decimal.to!int", decimal64, int)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int32_floor":
                outcome = test_rounding!("decimal.to!int", decimal64, int)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int32_rninta":
                outcome = test_rounding!("decimal.to!int", decimal64, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int32_int":
                outcome = test_rounding!("decimal.to!int", decimal64, int)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int32_rnint":
                outcome = test_rounding!("decimal.to!int", decimal64, int)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int32_xceil":
                outcome = test_rounding!("decimal.toExact!int", decimal64, int)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int32_xfloor":
                outcome = test_rounding!("decimal.toExact!int", decimal64, int)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int32_xrninta":
                outcome = test_rounding!("decimal.toExact!int", decimal64, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int32_xint":
                outcome = test_rounding!("decimal.toExact!int", decimal64, int)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int32_xrnint":
                outcome = test_rounding!("decimal.toExact!int", decimal64, int)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint32_ceil":
                outcome = test_rounding!("decimal.to!uint", decimal64, uint)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint32_floor":
                outcome = test_rounding!("decimal.to!uint", decimal64, uint)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint32_rninta":
                outcome = test_rounding!("decimal.to!uint", decimal64, uint)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint32_int":
                outcome = test_rounding!("decimal.to!uint", decimal64, uint)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint32_rnint":
                outcome = test_rounding!("decimal.to!uint", decimal64, uint)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint32_xceil":
                outcome = test_rounding!("decimal.toExact!uint", decimal64, uint)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint32_xfloor":
                outcome = test_rounding!("decimal.toExact!uint", decimal64, uint)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint32_xrninta":
                outcome = test_rounding!("decimal.toExact!uint", decimal64, uint)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint32_xint":
                outcome = test_rounding!("decimal.toExact!uint", decimal64, uint)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint32_xrnint":
                outcome = test_rounding!("decimal.toExact!uint", decimal64, uint)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int64_ceil":
                outcome = test_rounding!("decimal.to!long", decimal64, long)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int64_floor":
                outcome = test_rounding!("decimal.to!long", decimal64, long)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int64_rninta":
                outcome = test_rounding!("decimal.to!long", decimal64, long)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int64_int":
                outcome = test_rounding!("decimal.to!long", decimal64, long)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int64_rnint":
                outcome = test_rounding!("decimal.to!long", decimal64, long)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_int64_xceil":
                outcome = test_rounding!("decimal.toExact!long", decimal64, long)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_int64_xfloor":
                outcome = test_rounding!("decimal.toExact!long", decimal64, long)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_int64_xrninta":
                outcome = test_rounding!("decimal.toExact!long", decimal64, long)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_int64_xint":
                outcome = test_rounding!("decimal.toExact!long", decimal64, long)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_int64_xrnint":
                outcome = test_rounding!("decimal.toExact!long", decimal64, long)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint64_ceil":
                outcome = test_rounding!("decimal.to!ulong", decimal64, ulong)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint64_floor":
                outcome = test_rounding!("decimal.to!ulong", decimal64, ulong)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint64_rninta":
                outcome = test_rounding!("decimal.to!ulong", decimal64, ulong)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint64_int":
                outcome = test_rounding!("decimal.to!ulong", decimal64, ulong)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint64_rnint":
                outcome = test_rounding!("decimal.to!ulong", decimal64, ulong)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid64_to_uint64_xceil":
                outcome = test_rounding!("decimal.toExact!ulong", decimal64, ulong)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid64_to_uint64_xfloor":
                outcome = test_rounding!("decimal.toExact!ulong", decimal64, ulong)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid64_to_uint64_xrninta":
                outcome = test_rounding!("decimal.toExact!ulong", decimal64, ulong)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid64_to_uint64_xint":
                outcome = test_rounding!("decimal.toExact!ulong", decimal64, ulong)(element, msg, RoundingMode.towardZero);
                break;
            case "bid64_to_uint64_xrnint":
                outcome = test_rounding!("decimal.toExact!ulong", decimal64, ulong)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int8_ceil":
                outcome = test_rounding!("decimal.to!byte", decimal128, byte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int8_floor":
                outcome = test_rounding!("decimal.to!byte", decimal128, byte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int8_rninta":
                outcome = test_rounding!("decimal.to!byte", decimal128, byte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int8_int":
                outcome = test_rounding!("decimal.to!byte", decimal128, byte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int8_rnint":
                outcome = test_rounding!("decimal.to!byte", decimal128, byte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int8_xceil":
                outcome = test_rounding!("decimal.toExact!byte", decimal128, byte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int8_xfloor":
                outcome = test_rounding!("decimal.toExact!byte", decimal128, byte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int8_xrninta":
                outcome = test_rounding!("decimal.toExact!byte", decimal128, byte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int8_xint":
                outcome = test_rounding!("decimal.toExact!byte", decimal128, byte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int8_xrnint":
                outcome = test_rounding!("decimal.toExact!byte", decimal128, byte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint8_ceil":
                outcome = test_rounding!("decimal.to!ubyte", decimal128, ubyte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint8_floor":
                outcome = test_rounding!("decimal.to!ubyte", decimal128, ubyte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint8_rninta":
                outcome = test_rounding!("decimal.to!ubyte", decimal128, ubyte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint8_int":
                outcome = test_rounding!("decimal.to!ubyte", decimal128, ubyte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint8_rnint":
                outcome = test_rounding!("decimal.to!ubyte", decimal128, ubyte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint8_xceil":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal128, ubyte)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint8_xfloor":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal128, ubyte)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint8_xrninta":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal128, ubyte)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint8_xint":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal128, ubyte)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint8_xrnint":
                outcome = test_rounding!("decimal.toExact!ubyte", decimal128, ubyte)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int16_ceil":
                outcome = test_rounding!("decimal.to!short", decimal128, short)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int16_floor":
                outcome = test_rounding!("decimal.to!short", decimal128, short)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int16_rninta":
                outcome = test_rounding!("decimal.to!short", decimal128, short)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int16_int":
                outcome = test_rounding!("decimal.to!short", decimal128, short)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int16_rnint":
                outcome = test_rounding!("decimal.to!short", decimal128, short)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int16_xceil":
                outcome = test_rounding!("decimal.toExact!short", decimal128, short)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int16_xfloor":
                outcome = test_rounding!("decimal.toExact!short", decimal128, short)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int16_xrninta":
                outcome = test_rounding!("decimal.toExact!short", decimal128, short)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int16_xint":
                outcome = test_rounding!("decimal.toExact!short", decimal128, short)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int16_xrnint":
                outcome = test_rounding!("decimal.toExact!short", decimal128, short)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint16_ceil":
                outcome = test_rounding!("decimal.to!ushort", decimal128, ushort)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint16_floor":
                outcome = test_rounding!("decimal.to!ushort", decimal128, ushort)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint16_rninta":
                outcome = test_rounding!("decimal.to!ushort", decimal128, ushort)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint16_int":
                outcome = test_rounding!("decimal.to!ushort", decimal128, ushort)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint16_rnint":
                outcome = test_rounding!("decimal.to!ushort", decimal128, ushort)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint16_xceil":
                outcome = test_rounding!("decimal.toExact!ushort", decimal128, ushort)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint16_xfloor":
                outcome = test_rounding!("decimal.toExact!ushort", decimal128, ushort)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint16_xrninta":
                outcome = test_rounding!("decimal.toExact!ushort", decimal128, ushort)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint16_xint":
                outcome = test_rounding!("decimal.toExact!ushort", decimal128, ushort)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint16_xrnint":
                outcome = test_rounding!("decimal.toExact!ushort", decimal128, ushort)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int32_ceil":
                outcome = test_rounding!("decimal.to!int", decimal128, int)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int32_floor":
                outcome = test_rounding!("decimal.to!int", decimal128, int)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int32_rninta":
                outcome = test_rounding!("decimal.to!int", decimal128, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int32_int":
                outcome = test_rounding!("decimal.to!int", decimal128, int)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int32_rnint":
                outcome = test_rounding!("decimal.to!int", decimal128, int)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int32_xceil":
                outcome = test_rounding!("decimal.toExact!int", decimal128, int)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int32_xfloor":
                outcome = test_rounding!("decimal.toExact!int", decimal128, int)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int32_xrninta":
                outcome = test_rounding!("decimal.toExact!int", decimal128, int)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int32_xint":
                outcome = test_rounding!("decimal.toExact!int", decimal128, int)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int32_xrnint":
                outcome = test_rounding!("decimal.toExact!int", decimal128, int)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint32_ceil":
                outcome = test_rounding!("decimal.to!uint", decimal128, uint)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint32_floor":
                outcome = test_rounding!("decimal.to!uint", decimal128, uint)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint32_rninta":
                outcome = test_rounding!("decimal.to!uint", decimal128, uint)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint32_int":
                outcome = test_rounding!("decimal.to!uint", decimal128, uint)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint32_rnint":
                outcome = test_rounding!("decimal.to!uint", decimal128, uint)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint32_xceil":
                outcome = test_rounding!("decimal.toExact!uint", decimal128, uint)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint32_xfloor":
                outcome = test_rounding!("decimal.toExact!uint", decimal128, uint)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint32_xrninta":
                outcome = test_rounding!("decimal.toExact!uint", decimal128, uint)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint32_xint":
                outcome = test_rounding!("decimal.toExact!uint", decimal128, uint)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint32_xrnint":
                outcome = test_rounding!("decimal.toExact!uint", decimal128, uint)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int64_ceil":
                outcome = test_rounding!("decimal.to!long", decimal128, long)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int64_floor":
                outcome = test_rounding!("decimal.to!long", decimal128, long)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int64_rninta":
                outcome = test_rounding!("decimal.to!long", decimal128, long)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int64_int":
                outcome = test_rounding!("decimal.to!long", decimal128, long)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int64_rnint":
                outcome = test_rounding!("decimal.to!long", decimal128, long)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_int64_xceil":
                outcome = test_rounding!("decimal.toExact!long", decimal128, long)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_int64_xfloor":
                outcome = test_rounding!("decimal.toExact!long", decimal128, long)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_int64_xrninta":
                outcome = test_rounding!("decimal.toExact!long", decimal128, long)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_int64_xint":
                outcome = test_rounding!("decimal.toExact!long", decimal128, long)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_int64_xrnint":
                outcome = test_rounding!("decimal.toExact!long", decimal128, long)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint64_ceil":
                outcome = test_rounding!("decimal.to!ulong", decimal128, ulong)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint64_floor":
                outcome = test_rounding!("decimal.to!ulong", decimal128, ulong)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint64_rninta":
                outcome = test_rounding!("decimal.to!ulong", decimal128, ulong)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint64_int":
                outcome = test_rounding!("decimal.to!ulong", decimal128, ulong)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint64_rnint":
                outcome = test_rounding!("decimal.to!ulong", decimal128, ulong)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid128_to_uint64_xceil":
                outcome = test_rounding!("decimal.toExact!ulong", decimal128, ulong)(element, msg, RoundingMode.towardPositive);
                break;
            case "bid128_to_uint64_xfloor":
                outcome = test_rounding!("decimal.toExact!ulong", decimal128, ulong)(element, msg, RoundingMode.towardNegative);
                break;
            case "bid128_to_uint64_xrninta":
                outcome = test_rounding!("decimal.toExact!ulong", decimal128, ulong)(element, msg, RoundingMode.tiesToAway);
                break;
            case "bid128_to_uint64_xint":
                outcome = test_rounding!("decimal.toExact!ulong", decimal128, ulong)(element, msg, RoundingMode.towardZero);
                break;
            case "bid128_to_uint64_xrnint":
                outcome = test_rounding!("decimal.toExact!ulong", decimal128, ulong)(element, msg, RoundingMode.tiesToEven);
                break;
            case "bid32_frexp":
                outcome = test_ref!("frexp", decimal32, int, decimal32)(element, msg);
                break;
            case "bid64_frexp":
                outcome = test_ref!("frexp", decimal64, int, decimal64)(element, msg);
                break;
            case "bid128_frexp":
                outcome = test_ref!("frexp", decimal128, int, decimal128)(element, msg);
                break;
            case "bid32_modf":
                outcome = test_ref!("modf", decimal32, decimal32, decimal32)(element, msg);
                break;
            case "bid64_modf":
                outcome = test_ref!("modf", decimal64, decimal64, decimal64)(element, msg);
                break;
            case "bid128_modf":
                outcome = test_ref!("modf", decimal128, decimal128, decimal128)(element, msg);
                break;
            case "bid32_sqrt":
                outcome = test1!("sqrt", decimal32, decimal32)(element, msg);
                break;
            case "bid64_sqrt":
                outcome = test1!("sqrt", decimal64, decimal64)(element, msg);
                break;
            case "bid64q_sqrt":
                outcome = test1!("sqrt", decimal128, decimal64)(element, msg);
                break;
            case "bid128_sqrt":
                outcome = test1!("sqrt", decimal128, decimal128)(element, msg);
                break;
            case "bid32_cbrt":
                outcome = test1!("cbrt", decimal32, decimal32)(element, msg);
                break;
            case "bid64_cbrt":
                outcome = test1!("cbrt", decimal64, decimal64)(element, msg);
                break;
            case "bid128_cbrt":
                outcome = test1!("cbrt", decimal128, decimal128)(element, msg);
                break;
            case "bid32_quantexp":
                outcome = test1!("quantexp", decimal32, int)(element, msg);
                break;
            case "bid64_quantexp":
                outcome = test1!("quantexp", decimal64, int)(element, msg);
                break;
            case "bid128_quantexp":
                outcome = test1!("quantexp", decimal128, int)(element, msg);
                break;
            //case "bid32_scalbn":
            //    outcome = test2!("scalbn", decimal32, int, decimal32)(element, msg);
            //    break;
            case "bid32_ldexp":
                outcome = test2!("scalbn", decimal32, int, decimal32)(element, msg);
                break;
            case "bid64_ldexp":
                outcome = test2!("scalbn", decimal64, int, decimal64)(element, msg);
                break;
            case "bid128_ldexp":
                outcome = test2!("scalbn", decimal128, int, decimal128)(element, msg);
                break;
            case "bid32_sin":
                outcome = test1!("sin", decimal32, decimal32)(element, msg);
                break;
            case "bid64_sin":
                outcome = test1!("sin", decimal64, decimal64)(element, msg);
                break;
            case "bid128_sin":
                outcome = test1!("sin", decimal128, decimal128)(element, msg);
                break;
            case "bid_is754":
            case "bid_is754R":
            case "bid_getDecimalRoundingDirection":
            case "bid_lowerFlags":
            //always 10
            case "bid32_radix":
            case "bid64_radix":
            case "bid128_radix":
            //flags management, we have our own
            case "bid_restoreFlags":
            case "bid_saveFlags":
            case "bid_setDecimalRoundingDirection":
            case "bid_signalException":
            case "bid_testFlags":
            case "str64":         
            case "bid_testSavedFlags":
            case "bid_fetestexcept":
            case "bid_fesetexceptflag":
            case "bid_fegetexceptflag":
            case "bid_feraiseexcept":
            case "bid_feclearexcept":
            //no equivalent operators in D
            case "bid32_signaling_greater_unordered":
            case "bid64_signaling_greater_unordered":
            case "bid128_signaling_greater_unordered":
            case "bid32_signaling_less_unordered":
            case "bid64_signaling_less_unordered":
            case "bid128_signaling_less_unordered":
            case "bid32_signaling_not_greater":
            case "bid64_signaling_not_greater":
            case "bid128_signaling_not_greater":
            case "bid32_signaling_not_less":
            case "bid64_signaling_not_less":
            case "bid128_signaling_not_less":
            case "bid32_signaling_ordered":
            case "bid64_signaling_ordered":
            case "bid128_signaling_ordered":
            case "bid32_signaling_unordered":
            case "bid64_signaling_unordered":
            case "bid128_signaling_unordered":
            //better formatting engine than simple strings
            case "bid32_to_string":
            case "bid64_to_string":
            case "bid128_to_string":
            case "bid_strtod32":
            case "bid_strtod64":
            case "bid_strtod128":
            case "bid_wcstod32":
            case "bid_wcstod64":
            case "bid_wcstod128":
            //128 bit real not supported
            case "binary128_to_bid32":
            case "binary128_to_bid64":
            case "binary128_to_bid128":
            case "bid32_to_binary128":
            case "bid64_to_binary128":
            case "bid128_to_binary128":
            //bad formatted data in readtest.in file, anyway ldexp does the same thing for Intel (which is not correct)
            case "bid32_scalbn":
            case "bid64_scalbn":
            case "bid128_scalbn":
            case "bid32_scalbln":
            case "bid64_scalbln":
            case "bid128_scalbln":
                if (auto p = element.func in tests)
                    ++((*p).notApplicable);
                else
                    tests[element.func].notApplicable = 1;
                na = true;
                break;
            default:
                if (auto p = element.func in tests)
                    ++((*p).skipped);
                else
                    tests[element.func].notApplicable = 1;
                skip = true;
                break;
        }

        if (!na && !skip)
        {
            auto p = element.func in tests;
            if (outcome)
                ++((*p).passed);
            else
            {
                ++((*p).failed);
                writeln(msg);
            }
        }
    }

    writeln("Press Enter to continue...");
    getchar();

    auto keys = sort(tests.keys);
    Stat stats;
    foreach(key; keys)
    {
        auto p = tests[key];
        stats.total += p.total;
        stats.passed += p.passed;
        stats.failed += p.failed;
        stats.skipped += p.skipped;
        stats.notApplicable += p.notApplicable;

        writefln("%-35s -> Total: %6d, Passed: %6d, Failed: %6d, Skipped: %6d, N/A: %6d, Completion: %7.2f%%",
                 key, p.total, p.passed, p.failed, p.skipped, p.notApplicable, (p.notApplicable + p.passed) * 100.0 / p.total);
    }

    writeln("==========================================================================================================");
    writefln("%-35s -> Total: %6d, Passed: %6d, Failed: %6d, Skipped: %6d, N/A: %6d, Completion: %7.2f%%",
             "TOTAL", stats.total, stats.passed, stats.failed, stats.skipped, stats.notApplicable, (stats.notApplicable + stats.passed) * 100.0 / stats.total);

    


    
    writeln();

    
    writeln("Press Enter to continue...");
    getchar();
    return 0;
}
