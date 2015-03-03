module internals.oleauto32;

import system;
import system.runtime.interopservices;

mixin LinkLibrary!"oleaut32.lib";

extern(Windows) pure nothrow @nogc :

int VarBoolFromDec(in ref decimal pDecIn, ref short pBoolOut);
int VarDecAdd(in ref decimal pDecLeft, in ref decimal pDecRight, ref decimal pDecResult);
int VarDecCmp(in ref decimal pDecLeft, in ref decimal pDecRight);
int VarDecCmpR8(in ref decimal pDecLeft, in double dblRight);
int VarDecDiv(in ref decimal pDecLeft, in ref decimal pDecRight, ref decimal pDecResult);
int VarDecInt(in ref decimal pDecIn, ref decimal pDecOut);
int VarDecFix(in ref decimal pDecIn, ref decimal pDecOut);
int VarDecFromR4(in float fltIn, ref decimal pDecOut);
int VarDecFromR8(in double dblIn, ref decimal pDecOut);
int VarDecMul(in ref decimal pDecLeft, in ref decimal pDecRight, ref decimal pDecResult);
int VarDecRound(in ref decimal pDecIn, in int cDecimals, ref decimal pDecOut);
int VarDecSub(in ref decimal pDecLeft, in ref decimal pDecRight, ref decimal pDecResult);
int VarUI1FromDec(in ref decimal pDecIn, ref ubyte pByteOut);
int VarI1FromDec(in ref decimal pDecIn, ref byte pByteOut);
int VarUI2FromDec(in ref decimal pDecIn, ref ushort pOut);
int VarI2FromDec(in ref decimal pDecIn, ref short pOut);
int VarUI4FromDec(in ref decimal pDecIn, ref uint pOut);
int VarI4FromDec(in ref decimal pDecIn, ref int pOut);
int VarUI8FromDec(in ref decimal pDecIn, ref ulong pOut);
int VarI8FromDec(in ref decimal pDecIn, ref long pOut);
int VarR4FromDec(in ref decimal pDecIn, ref float pOut);
int VarR8FromDec(in ref decimal pDecIn, ref double pOut);
int VarDecFromCy(in long cyIn, ref decimal pDecOut);
int VarCyFromDec(in ref decimal pDecIn, ref long cyOut);

//int SetErrorInfo(uint dwReserved, IErrorInfo perrinfo);
//int GetErrorInfo(uint dwReserved, out IErrorInfo pperrinfo);
//int reateErrorInfo(out IErrorInfo pperrinfo);