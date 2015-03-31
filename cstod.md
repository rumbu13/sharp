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
##Structs and classes
Struct and classes are declared exactly the same way in D except:
- There is no explicit layout in D. Nevertheless, there is a solution in the standard library.
- D has _unions_, the equivalent of a C# _struct_ with explicit layout where all fields offsets are 0:

-C#:
```
[StructLayout(LayoutKind.Explicit)]
struct MyUnion {
  [FieldOffset(0)]
  int someInt;
  [FieldOffset(0)]
  float someFloat;
}
```
-D:
```
union MyUnion {
  int someInt;
  float someFloat;
}
```

##Generic Types
D is not using generics, instead, it has a more powerful concept named __templates__.

- C#:
```
void Foo(T)(T arg);
class C(T) where T: class;
class D(T) where T: C;
```
- D:
```
void Foo(T)(T arg);
class C(T) if is(T == class);
class C(T) if is(T : C);
```
There are no direct equivalents of other generic constraints, but the D template system is so versatile that you can create your own. 
- C#:
```
class C(T) where T: new();
```
- D:
```
class C(T) if (is(typeof(new T()) == T))
```
The template constraint will be read as _if the result of expresssion `new T()` is of type T_. If the T class has no contructor or is some other type, the `new T()` expression will result in an error or some other type, therefore the constraint will not be satisfied.

##Events
There is no such concept in D language. Various solutions exists to simulate the same behaviour.

##Dynamic Types
There is no such concept in D language. All types must be known at compile time. 

##Boxing
Value types in D are not boxed or unboxed automatically and do not inherit from ValueType. Also, you cannot implement interfaces for value types. Various solutions exists in the standard library to box or unbox a value.

##Nullable types
Value types are not nullable in D language. There are solutions in the standard library to simulate this behaviour:

- C#:
```
int? x = 10
if (x.HasValue)...
int y = x.Value;
int z = x.GetValueOrDefault()
x = null;
```
- D:
```
import std.typecons;
Nullable!int x = 10
if (x.isNull)...
int y = x.get();
int z = x.isNull ? int.init : x.get();
x.nullify();
```











