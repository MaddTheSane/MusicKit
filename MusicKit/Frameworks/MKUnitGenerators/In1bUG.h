/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    In1bUG - from dsp macro /usr/local/lib/dsp/ugsrc/in1b.asm (see source for details).

   In1b reads its input signal from channel 0 (left) of the stereo sound input sample 
   stream of the DSP, writing it to its output. 
   In1b also provides a scaling on its output.

   You instantiate a subclass of the form 
   In1bUG<a>, where <a> = space of input

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
// classgroup Sound Inputs and Outputs
/*!
  @class In1bUG
  @brief <b>In1bUG</b> reads sound from the right channel of DSP serial port and 
  writes it to its output patchpoint.
  
  

In1aUG and In1bUG provide single-channel access to the DSP's stereo input
stream, which comes from the DSP serial port; the former reads its input signal
from the left channel, and the latter reads from the right. 

In order to use an In1aUG or In1bUG, you must first send the message
<b>setSerialSoundIn:YES</b> to the MKOrchestra.  This must be done before the
MKOrchestra is sent the <b>open</b> message.  

If you're building a MKSynthPatch subclass, you should note that every MKSynthPatch
object should have its own signal-input MKUnitGenerator; in other words, you don't
allocate just one such object and then share it amongst the various
MKSynthPatches.  The input signal is sent to all the In1aUGs and
In1bUGs.

<h2>Memory Spaces</h2>

<b>In1bUG<i>a</i></b>
<i>a</i>	output 
*/
#ifndef __MK_In1bUG_H___
#define __MK_In1bUG_H___
#import <MusicKitLegacy/MKUnitGenerator.h>

@interface In1bUG : MKUnitGenerator
{
  BOOL _reservedIn1b1;
}

/*!
  @param arg is an unsigned.
  @return Returns an BOOL.
  @brief Specifies that all arguments are to be optimized if possible.

  
*/
+ (BOOL) shouldOptimize: (unsigned) arg;

/*!
  @brief Sets the factor by which the output signal is scaled.

  By default, the scaler is set to 1.0.  Effective values are between 0.0 and 1.0
  (negative values are the same as their absolute values, but with a
  180 degree phase shift).
  @param value is a double.
  @return Returns <b>self</b>.
*/
- setScale: (double) value;

/*!
  @return Returns an id.
  @brief If scale has not been set, sets it to 1.0.

  This method is invoked
  when you send the <b>run</b> message to the object.
*/
-runSelf;
/* If scaling has not been set, sets it to 1-e. */

/*!
  @param  aPatchPoint is an id.
  @return Returns an id.
  @brief Sets the output patchpoint to <i>aPatchPoint</i>.

  Returns
  <b>nil</b> if the argument isn't a patchpoint; otherwise returns
  <b>self</b>.
*/
-setOutput: (id) aPatchPoint;
/* Sets input patch point. */

@end
#endif
