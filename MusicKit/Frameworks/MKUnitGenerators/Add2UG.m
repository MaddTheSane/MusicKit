/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/* This is a stub of the class you fill in. Generated by dsploadwrap.*/
/* 
Modification history:

  11/22/89/daj - Changed to use UnitGenerator C functions instead of methods.
*/
#import <MusicKitLegacy/MusicKitLegacy.h>
#import "_unitGeneratorInclude.h"
#import "Add2UG.h"
@implementation Add2UG:MKUnitGenerator
{ /* Instance variables go here */
}

   enum args { i1adr, aout, i2adr};

#import "add2UGInclude.m"

#if _MK_UGOPTIMIZE 
+(BOOL)shouldOptimize:(unsigned) arg
{
    return YES;	
}
#endif _MK_UGOPTIMIZE

-setInput1:aPatchPoint
/* Set first input to specified patchPoint. */
{
    return MKSetUGAddressArg(self,i1adr,aPatchPoint);
}

-setInput2:aPatchPoint
/* Set second input to specified patchPoint. */
{
    return MKSetUGAddressArg(self,i2adr,aPatchPoint);
}

-setOutput:aPatchPoint
/* Set output patchPoint of the oscillator. */
{
    return MKSetUGAddressArg(self,aout,aPatchPoint);
}

-idleSelf
{
  return [self setAddressArgToSink:aout]; /* Patch output to sink. */
}

@end

