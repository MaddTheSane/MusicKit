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

******************************************************************************/

#import <MKPerformSndMIDI/PerformSound.h>
#import "SndFormat.h"
#import "SndEndianFunctions.h"
#import "SndTable.h"
#import "Snd.h"
#import "SndFunctions.h"
#import "SndMuLaw.h"
#import "SndExpt.h"

#import "SndView.h"
#ifndef USE_NEXTSTEP_SOUND_IO
# import "sounderror.h"
#endif
#import "SndStreamManager.h"
#import "SndAudioBuffer.h"
#import "SndStreamClient.h"
#import "SndStreamRecorder.h"
#import "SndStreamMixer.h"

#ifndef SK_NO_MP3_ENCODER
# import "SndAudioProcessorMP3Encoder.h"
# import "SndMP3.h"
#endif

#import "SndAudioProcessor.h"
#import "SndAudioProcessorChain.h"
#import "SndAudioProcessorDelay.h"
#import "SndAudioProcessorDistortion.h"
#import "SndAudioProcessorFlanger.h"
#import "SndAudioProcessorNoiseGate.h"
#import "SndAudioProcessorReverb.h"
#import "SndAudioProcessorRecorder.h"
#import "SndAudioProcessorToneGenerator.h"
#import "SndAudioProcessorInspector.h"
#import "SndPerformance.h"
#import "SndPlayer.h"
#import "SndAudioFader.h"
#import "SndBreakpoint.h"
#import "SndEnvelope.h"
#import "SndAudioBufferQueue.h"
