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
    writeln("Hello world");
}
```
Things we learnt so far:
- standard file extension for D source code files is `.d`
- we `import` a module instead of `using` a namespace;
- static methods can be declared outside a class;
- we can call directly any method even if it's not declared in a class (`writeln`);
- `writeln` is D equivalent for C# `Console.WriteLine`;
- syntax is exactly the same as in C# (method definitions, string qualifiers, array declarations, comments)
- many of the keywords are exactly the same (`void`, `string`);

#Coding styles
- D programmers prefer to use the camelCase notation instead of PascalCase for method names, variable names and enum members;
- Module names (C# namespaces) are always in lowercase due to cross-platform compatibility regarding file names.
- If there are conflicts between a named entity and a keyword, in C# you can use verbatim identifiers (@while). D does not have verbatim identifiers, but the convention is to add an underscore at the end of the entity (while_).

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
Since D is not a managed language, you are free to use pointers anywhere in the code, without encompassing them in an unsafe context. On the contrary, D code is by default unsafe, but you can force the safe context using the `@safe` keyword:
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
There is no difference between enum declarations, except that so called C# flags enums are not necessarely decorated with the [Flags] attribute:
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
- Structs cannot implement interfaces;
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
##Interfaces
Interfaces are declared in the same way as in C#, the only difference being that interfaces in D can have final methods, equivalent to C# abstract class:

- C#:
```
interface I {
    void Method();
}

abstract class C {
   void Method()
   {
      Console.WriteLine("hello");
   }
}
```
- D:
```
interface I {
    void Method();
}

interface C {
   final void Method()
   {
      Console.WriteLine("hello");
   }
}
```

##Generic Types
D is not using generics, instead it has a more powerful concept named __templates__.

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
There is no such concept in D language, but D programmers prefer to use [signals and slots](http://dlang.org/phobos/std_signals.html) instead of events. If you are keen to use events in D, a quick and dirty way to implement them can be found below:

- C#:
```
delegate void MyEventHandler(object sender, EventArgs e);
class MyClass
{
    event ChangedEventHandler Changed;
}

```
- D:
```
struct Event(Sender, Args)
{
    void delegate(Sender, Args)[] delegates;
    void opCall(Sender sender, Args args)
    {
        foreach(dg; delegates)
            dg(sender, args);
    }
    void opOpAssign(string op)(void delegate(Sender, Args) dg) if (op == "+")
    {
        delegates ~= dg;
    }
    void opOpAssign(string op)(void delegate(Sender, Args) dg) if (op == "-")
    {
        for(size_t i = 0; i < delegates.length; i++)
        {
            if (delegates[i] is dg)
            {
                delegates = delegates[0 .. i] ~ delegates[i + 1 .. $];
                break;
            }
        }
    }
    
}

alias MyEventHandler = void delegate (object sender, EventArgs e);
class MyClass
{
    Event!(object, EventArgs) Changed;
}

```

##Dynamic Types
There is no such concept in D language. All types must be known at compile time but the same semantics can be simulated by [forwarding](http://dlang.org/operatoroverloading.html#dispatch).


##Boxing
Value types in D are not boxed or unboxed automatically and do not inherit from ValueType. Also, you cannot implement interfaces for value types. 

Depending on your purpose, there are alternatives to boxing in D: 
- if you just want to have a container for several types you can use [std.variant](http://dlang.org/phobos/std_variant.html); - if you want to write general purpose method with object parameters, use generics;

- C#:
```
int a; float b;
object o = a;
o = b;
b = (float)o;

string Foo(object obj)
{
    return obj.ToString();
}
```

- D:
```
int a; float b;
Variant!(int, float) v = a;
v = b;
b = cast(float)v;

string Foo(T)(T obj)
{
    return to!string(obj);
}
```

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
##Enumerable types
In C#, a type can be considered enumerable if implements the `IEnumerable` interface. In D, a type is considered enumerable (Range is more used as the concept in D) if:
- implements three methods named `popFront`, `empty` and `front` or,
- implements a special operator named `opApply`;

- C#:
```
class Fibonacci : IEnumerable<int>
{
    public IEnumerator<int> GetEnumerator()
    {
        return new FibonacciEnumerator();
    }
}

class FibonacciEnumerator : IEnumerator<int>
{
    private int n1 = 0;
    private int n2 = 1;
    
    public int Current
    {
        get { return n1 + n2; }
    }
    
    public void Reset()
    {
        n1 = 0;
        n2 = 1;
    }
    
    public bool MoveNext()
    {
       int temp = n2;
       n2 += n1;
       n1 = temp;
       return true;
    }
}

```
- D (front, popFront, empty)
```
class Fibonacci 
{
    private int n1 = 0;
    private int n2 = 1;
    
    public int front()
    {
       return n1 + n2;
    }

    public void popFront()
    {
       int temp = n2;
       n2 += n1;
       n1 = temp;
    }

    public bool empty()
    {
        return false; 
    }
}

```

- D (opApply)

```
class Fibonacci 
{
    private int n1 = 0;
    private int n2 = 1;
    
    int opApply(int delegate(int) fib)
    {
        int ret = 0;
        int n1 = 0;
        int n2 = 1;
        while (ret == 0)
        {
            int temp = n1 + n2;
            ret = fib(temp);
            n1 = n2;
            n2 = temp;
        }
        return ret;
    }
}

```

#Statements

##Declaring variables
- C#:
```
int x;
string str = "abc";
const long l = 10;
```
- D:
```
int x;
string str = "abc";
immutable long l = 10;
```

##Expressions
- C#:
```
double average = (a + b) / 2; // assignment expression
foo.bar(); // method call
SomeClass c = new SomeClass(); // class initialization
SomeStruct s = new SomeStruct(); //struct initialization
List<T> list = new List<T>();
Dictionary<string, int> = new Dictionary<string, int>();
```
- D:
```
double average = (a + b) / 2;  // assignment expression
foo.bar(); // method call
SomeClass c = new SomeClass(); // class initialization
SomeStruct s = SomeStruct(); //struct initialization
List!T list = new List!T();
Dictionary!(string, int) = new Dictionary!(string, int);
```
Differences:
- Structs in D are initialized without the `new` keyword.
- Generic types in D are initialized using `!` and by specifing types between parantheses. If there is only one specialisation, parantheses can be omitted.

##Using namespaces
D is importing modules instead of using namespaces. A collection of modules in D in named `package`. There is one-to-one correspondence between D modules and filenames and one-to-one correspondence between packages and folders.

- C#
```
using System;
using System.Collections;
```
- D:
```
import system;
//this will try to import 'system.d' from the current folder. 
//if 'system' is a folder name, it will try to import a special file named 'package.d'
import system.collections;
//this will import the file 'collections.d' from a folder named 'system'.
```
if you are creating your own namespaces, the closest match for simulating C# namespaces is a trick used to import C++ code in D:
```
extern (C++, MyNamespace)
{
    class MyClass { ...}
}
//Fully qualified name of MyClass is MyNamespace.MyClass 
```


##Selection statements
The `if else` statement has the same structure as in C#:

- C#:
```
bool b;
int a;
SomeClass c;
void* p;

if (b) { ... }
if (a == 10) { .... } else { ... }
if (c == null) { ... }
if (p != IntPtr.Zero) { ... }
```
- D:
```
bool b;
int a;
SomeClass c;
void* p;

if (b) { ... }
if (a == 10) { .... } else { ... }
if (a) { ... }
if (c is null) { ... }
if (!c) { ... }
if (p) { ... }
```
Differences:
- `null` values are compared using `is` operator. The `is` operator has a very different meaning in D.
- In D, the conditional expression can be any other type than `bool`

The `switch case` statement has exactly the same structure as in C#, except that D provides a `final switch` statement intended to use with enum types:
- C#:
```
enum Color { Blue, Red, Green }
Color c;
switch (c):
{
    case Color.Blue: ... break;
    case Color.Red:  ... break;
    default: ... break;
}
```
- D:
```
enum Color { Blue, Red, Green }
Color c;
final switch (c):
{
    case Color.Blue: ... break;
    case Color.Red:  ... break;
    //compilation error if the switch statement does not treat all members of Color.
}
```
##Iteration statements
`for`, `do`, and `while` semantics are exactly the same in D.
`foreach` statement is more versatile in D and has also reverse counterpart - `foreach_reverse`:

- C#
```
foreach (element in enumerable) { .. }
```
- D
```
foreach (element; range) { ... } 
foreach (index; element; range) { ... }
foreach (index; start .. end) { ... }
```
Also, in D, the iteration element can be modified inside the loop if it's passed by reference:
```
int[] array;
foreach (ref int i; array)
{
    i = i + 1;
}
```
##Jump statements
`break`, `continue`, `default`, `goto`, `return` semantics are exactly the same in D.
There is no `yield return` or `yield break` statement in D, but it can be simulated using _Voldemort_ types. _Voldemort_ types are return types of functions unknown outside the function.

- C#:
```
IEnumerable<int> GiveMeFive()
{
    yield return 1;
    yield return 2;
    yield return 3;
    yield return 4;
    yield return 5;
}
```
- D
```
auto GiveMeFive()
{
    struct Voldemort
    {
        int opApply(int delegate(int) dg)
        {
            int ret = dg(1);
            if (ret) return ret;
            ret = dg(2);
            if (ret) return ret;
            ret = dg(3);
            if (ret) return ret;
            ret = dg(4);
            if (ret) return ret;
            ret = dg(5);
            return ret;
        }
    }
    return Voldemort();
}
```

##Exception handling
`try`, `catch`, `finally` and `throw` semantics are exactly the same in D, but the `Exception` hierarchy is different. Your custom exceptions must derive from `Exception` class like in C#, but `Exception` class is inheriting `Error` and `Throwable`. The last two exceptions are not intended to be caught, being considered fatal errors.

Another way to handle exceptions in D is using `scope` statements:
```
void Foo()
{
    scope(exit) { // this block is executed unconditionally at the end of the function }
    scope(success) { // this block is executed at the end of the function if no exception is thrown }
    scope(failure) { // this block is executed at the end of the function if exception is thrown }
}
```
##Locking
Locking at method level in D is done using a keyword (`synchronized`) instead of an attribute. In statements, the same keyword is used instead of `lock` but a locking object is not always required:

- C#:
```
[MethodImpl(MethodImplOptions.Synchronized)]
void Foo() { ... }

void Bar()
{
    lock(someObject) { ... }
}
```

- D:
```
synchronized void Foo() { ... }

void Bar()
{
    synchronized(someObject) { ... }
    //also
    synchronized  { ... }
}
```

##Pointer operations
D garbage collector is not a moving one, there is no need to use the `fixed` statement, you can perform pointer operations anywhere in code. Also, value types (including structs) are by default created on stack, the garbage collector is not involved in this case and you can directly reference them using a pointer.

- C#:
```
struct Point { int x, y; }
unsafe void Foo()
{
    Point s = new Point();
    fixed (int * p = &s.x)
    {
        *p = 10;
    }
}
```

- D:
```
struct Point { int x, y; }
void Foo()
{
    Point s = Point();
    int * p = &s.x
    *p = 10;
}
```

##Asynchrony
There is no `async` or `await` equivalent in D, you'll need to code yourself the mechanisms using threads or fibers from the core.thread runtime library.

##D specific statements
- You can write assembler directly in code using the `asm` statement: ( `asm { ... }`)
- You can copy-paste parameterized code using the `mixin` statement: ( `mixin("x = 0;")`)
- You can save some typing using the `with` statement: `with(expression) { statement1; statement2; }' 
For further details, please consult the D official language reference on dlang.org.

#More about types

##Arrays

In D, arrays are not classes, but they keep the same reference semantics in D.

- C#:
```
int[] array1;
int[] array2 = { 1, 2, 3, 4, 5 };
int[,] array3 = new int[5, 10];
int[][] array4 = new int[10][20];
int[] array5 = array1.Clone();
int l = array1.Length;
Array.Sort(array5)
Array.Reverse(array5);
Array.Resize(array5, 3);
int * p = array2;

```
- D:
```
int[] array1;
int[] array2 = [ 1, 2, 3, 4, 5 ];
int[][] array3 = new int[5][10];
int[][] array4 = new int[10][20];
int[] array5 = array1.dup();
size_t l = array1.length;
array5.sort();
array5.reverse();
array5.length = 3;
int * p = array2.ptr

```
- array initialization in D is done by enumerating values in right brackets instead of curly brackets;
- there are no multidimensional arrays in D, use jagged arrays instead;
- arrays are not implicitly convertible to pointers, use the `ptr` property for the same effect;
- array length and indices are not necesarely of type `int`, but of type `size_t`. This is in fact an alias to `uint` or to `ulong`, depending of the target architecture (32-bit or 64-bit). A similar variable size type in C# is `IntPtr`.
- array length in D is not fixed, you can simply resize an array by specifying a new length; 

##Strings

In D, strings are not classes like in C#, just simple arrays. In fact, strings are declared in D as:
```
alias string = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];
```
The direct equivalent of C# `string` class is D `wstring`, a UTF-16 encoded array of characters. In D, strings are not directly convertible to char*, instead you can use the `ptr` property of any array. Special care must be taken because D strings are not always zero terminated.

- C#:
```
string s = "hello" + " " + "world";
string s2 = "The path is C:\\Windows";
string s3 = @"The path is C:\Windows";
string s4 = @" this is a
   multiline string";
char* zeroTerminated;
char[] charArray;
string s = new string(zeroTerminated);
string s = new string(charArray);
```
- D:
```
string s = "hello" ~ " " ~ "world";
string s2 = "The path is C:\\Windows";
string s3 = r"The path is C:\Windows";
string s4 = q" this is a
   multiline string";
char* zeroTerminated;
char[] charArray;
string s = zeroTerminated[0 .. strlen(zeroTerminated)].idup;
string s = charArray.idup;
```
- strings are concatenated in D using `~` operator;
- verbatim strings (named Wysiwyg strings in D) are declared using the `r` prefix or `q` prefix if they are multi-line;
- initializing a string from a char* or char[] is done by duplicating the memory and making it immutable (idup).

Notes:
- strings in D are not culture sensitive by default like in C#. Sorting, finding, comparing them or changing case can lead to unexpected results, strings comparisons and transformations are performed in D with array semantics (ordinal).
- there is no `StringBuilder` class in D to manipulate strings. Instead you can use the `std.array.Appender!string`, but it's optimized only for append operations, inserts and removes are not cheap in terms of performance.
- formating is done in C way. Please read [printf](http://www.cplusplus.com/reference/cstdio/printf/) documentation.





