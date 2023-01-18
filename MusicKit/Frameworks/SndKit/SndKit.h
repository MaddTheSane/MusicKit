/******************************************************************************
  $Id$

  Description: Main class defining a sound object.

  Original Author: Stephen Brandon

  Copyright (c) 1999 Stephen Brandon and the University of Glasgow
  Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.

  Legal Statement:

    This framework and all source code supplied with it, except where specified, are
    Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to
    use the source code for any purpose, including commercial applications, as long
    as you reproduce this notice on all such software.

    Software production is complex and we cannot warrant that the Software will be
    error free.  Further, we will not be liable to you if the Software is not fit
    for the purpose for which you acquired it, or of satisfactory quality. 

    WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
    WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF
    QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES
    RIGHTS.
    
    If a court finds that we are liable for death or personal injury caused by our
    negligence our liability shall be unlimited.  
    
    WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
    OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
    POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
    NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
    DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS
    OF THIS AGREEMENT.

  Legal Statement covering additions made by the MusicKit project:

    Permission is granted to use and modify this code for commercial and
    non-commercial purposes so long as the author attribution and copyright
    messages remain intact and accompany all relevant code.

******************************************************************************/

/* We #import this file regardless of the setting of
   HAVE_CONFIG_H so that other applications compiling against this
   header don't have to define it. If you are seeing errors for
   SndKitConfig.h not found when compiling the MusicKit, you haven't
   run ./configure 
 */
#import <SndKit/SndKitConfig.h>

#import <SndKit/sndfile.h>
#ifdef __OBJC__
#import <SndKit/SndFormat.h>
#import <SndKit/SndEndianFunctions.h>
#import <SndKit/SndTable.h>
#import <SndKit/Snd.h>
#import <SndKit/SndPasteboard.h>
#import <SndKit/SndFunctions.h>
#import <SndKit/SndMuLaw.h>
#import <SndKit/SndOnDisk.h>
#import <SndKit/SndError.h>
#import <SndKit/SndStreamManager.h>
#import <SndKit/SndAudioBuffer.h>
#import <SndKit/SndStreamClient.h>
#import <SndKit/SndStreamRecorder.h>
#import <SndKit/SndStreamMixer.h>
#import <SndKit/SndStreamInput.h>
#import <SndKit/SndAudioProcessorMP3Encoder.h>
#import <SndKit/SndMP3.h>
#import <SndKit/SndAudioProcessor.h>
#import <SndKit/SndAudioProcessorChain.h>
#import <SndKit/SndAudioProcessorDelay.h>
#import <SndKit/SndAudioProcessorDistortion.h>
#import <SndKit/SndAudioProcessorFlanger.h>
#import <SndKit/SndAudioProcessorNoiseGate.h>
#import <SndKit/SndAudioProcessorReverb.h>
#import <SndKit/SndAudioProcessorRecorder.h>
#import <SndKit/SndAudioProcessorToneGenerator.h>
#import <SndKit/SndAudioProcessorInspector.h>
#import <SndKit/SndPerformance.h>
#import <SndKit/SndPlayer.h>
#import <SndKit/SndAudioFader.h>
#import <SndKit/SndBreakpoint.h>
#import <SndKit/SndEnvelope.h>
#import <SndKit/SndAudioBufferQueue.h>

// GUI classes, requires AppKit.h
#import <SndKit/SndView.h>
#import <SndKit/SndMeter.h>
#import <SndKit/SndStretchableScroller.h>

#if defined(__APPLE_CC__) // Only Apple defines AudioUnits.
#import <SndKit/SndAudioUnitProcessor.h>
#import <SndKit/SndAudioUnitController.h>
#endif

#endif

#import <SndKit/SndVSTProcessor.h>
