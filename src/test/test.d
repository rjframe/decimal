import std.stdio;
import decimal;

union RU
{
    real r;
    struct
    {   
        version(LittleEndian)
        {
            ulong m;
            ushort e;    
        }
        else
        {
            ushort e;
            ulong m;
        }
    }
}

int main(string[] argv)
{
    writeln(real.sizeof);
    writeln(real.mant_dig);
    writeln(RU.sizeof);
    writeln("Press Enter to continue...");
    getchar();
    return 0;
}
