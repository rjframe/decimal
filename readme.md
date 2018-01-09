# decimal
D implementation of floating point decimal data type according to IEEE-754-2008

# Why

- 1.1 + 2.2 = 3.3 (decimal) but 1.1 + 2.2 = 3.3000000000000003 (float)

- 0.45 = 0.45 (decimal) but 0.45 = 0.450000018 (float)

# Features:

- fully IEEE-754-2008 compliant;
- using Intel's binary decimal enconding;
- three decimal data types: _decimal32, decimal64 and decimal128_
- all D operators supported for all numeric types (left and right side integrals, floats, chars);
- conversion supported from/to integrals, floats, bools, chars
- conversion to other decimal formats (Microsoft Currency, Microsoft Decimal, IBM Densely Packed Decimal)
- all std.math functions implemented (even logarithms and trigonometry);
- all format specifiers implemented (%f, %e, %g, %a);
- integrated with phobos format and conversion functions (to, format, writef);
- thread local precision (from 1 to 34 _decimal_ digits);
- new rounding mode - Europe's most used - tiesToAway;
- alternate exception handling (through flags);
- minimal dependencies (some traits and some floating point functions);
- comprehensive documentation;


Documentation: http://rumbu13.github.io/decimal/doc/package.html

