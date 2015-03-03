module internals.user32;

import system;
import system.runtime.interopservices;

import internals.kernel32;

mixin LinkLibrary!"user32.lib";

extern(Windows) @nogc nothrow:

int LoadStringW(in void* hInstance, uint uID, wchar* lpBuffer, int nBufferMax);
short GetKeyState(in int nVirtKey);