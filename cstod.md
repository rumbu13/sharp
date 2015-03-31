#Introduction
- Hello World in C#
```
//helloworld.cs
using System;
class Hello
{
    static void Main(string[] args)
    {
        Console.WriteLine("Hello world!");
    }
}
```

- Hello world in D:
```
//helloworld.d
import std.stdio;
void main(string[] args)
{
    writeln("Hello world"!)
}
```
Things we learnt so far:
- standard file extension for D source code files is `.d`
- we `import` a module instead of `using` a namespace;
- static methods can be declared outside any class;
- we can call directly any method even if it's not declared in a class (`writeln`);
- `writeln` is D equivalent for C# `Console.WriteLine`;
- syntax is exactly the same as in C# (method definitions, string qualifiers, array declarations)
- many of the keywords are exactly the same (`void`, `string`);

#Type system
##Built-in types
Basic type names are very similar in both languages with the following differences:
- The 8 bit signed integer from C# `sbyte` is written in D as `byte`;
- The 8 bit unsigned integer from C# `byte` is written in D as `ubyte`;
- There is no type equivalence for `decimal`
- There are three types of char in D: `char`, `wchar` and `dchar`, each of them corresponding to an UTF encoding : UTF-8, UTF-16 and UTF-32. Since C# is using internally UTF-16 chars, the direct equivalent of C# `char` is D `wchar`.
- There are also three types of string in D: `string`, `wstring` and `dstring`. The direct equivalent of C# `string` is in fact D `wstring`. These are not keywords in D, they are in fact declared as aliases to immutable char arrays.
- There is another floating point type in D: `real` with no type equivalence in C#.
- Complex floating point types `Complex<T>` are keywords in D: `cfloat, cdouble, creal` and they imaginary counterparts are `ifloat`, `idouble`, `ireal`;

##Arrays
Arrays in D are not too different than the ones form C#:
- C#:
``` 
int[] array;
fixed int array[20];
```
- D:
```
int[] array;
int array[20]
```
##Pointers
Since D is not a managed language, you are free to use pointers anywhere in the code, without encompassing them in an unsafe context. On th contrary, D code is by default unsafe, but you can force the safe context using the `@safe` keyword:
- C#
```
int value;
//here you can't use pointers
unsafe {
    int * p = &value
}
```
- D
```
int value;
int * p = &value
@safe {
    //here you can't use pointers
}
```

##Delegates
Delegates in D are declared with the same keyword, but the return type precedes the declaration:
- C#:
```
delegate int Foo(int x);
```
- D:
```
int delegate(int x) Foo;
int function(int x) Foo;
```
Since D doesn't need to declare methods inside a class, you can declare also a `function`, equivalent to a delegate without class context.
A notable difference between C# and D is the fact that __delegates are not multicast__ in D, therefore you cannot join or remove them.

##Enums
There is no difference between enum declarations, except that so called C# flags nums are not necessarly decorated with attributes:
- C#
```
enum Option { 
    Option1, 
    Option2
}
[Flags]
enum Options {
    Option1,
    Option2,
    All = Option1 | Option2
}
```
- D:
```
enum Option { 
    Option1, 
    Option2
}

enum Options {
    Option1,
    Option2,
    All = Option1 | Option2
}
```
##Structs
Struct are declared exactly the same way in D.














