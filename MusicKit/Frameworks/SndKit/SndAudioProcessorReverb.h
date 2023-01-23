////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    FreeVerb-based
//    FreeVerb originally written by Jezar at Dreampoint, June 2000
//    http://www.dreampoint.co.uk
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//  Rewritten by: Leigh M. Smith <leigh@leighsmith.com>
//
//  Jezar's code described as "This code is public domain"
//
//  Copyright (c) 2001,2009 The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORREVERB_H__
#define __SNDKIT_SNDAUDIOPROCESSORREVERB_H__

#import <Foundation/Foundation.h>
#import <SndKit/SndAudioProcessor.h>

@class SndReverbCombFilter;
@class SndReverbAllpassFilter;

#define NUMCOMBS 8
#define NUMALLPASSES 4
#define NUMCHANNELS 2

/*!
 @brief SndReverbParam Parameter keys
 @constant rvrbRoomSize  Room size
 @constant rvrbDamp  Damping amount
 @constant rvrbWet  Wet level
 @constant rvrbDry  Dry level
 @constant rvrbWidth  Width
 @constant rvrbMode  Mode [1 = hold]
 @constant rvrbNumParams  Number of parameters
*/
enum {
    rvrbRoomSize  = 0,
    rvrbDamp      = 1,
    rvrbWet       = 2,
    rvrbDry       = 3,
    rvrbWidth     = 4,
    rvrbMode      = 5, 
    rvrbNumParams = 6
};

////////////////////////////////////////////////////////////////////////////////

/*!
  @class SndAudioProcessorReverb
  @brief A reverb processor

  A reverb based on FreeVerb originally written by Jezar at Dreampoint, June 2000
*/
@interface SndAudioProcessorReverb : SndAudioProcessor {
    float gain;
    float roomsize, roomsize1;
    float damp, damp1;
    float wet, wet1, wet2;
    float dry;
    float width;
    float mode;

    // The following are all declared statically allocated 
    // to speed up the traversal across the filters.

    /*! Comb filters */
    SndReverbCombFilter *comb[NUMCHANNELS][NUMCOMBS];

    /*! Allpass filters */
    SndReverbAllpassFilter *allpass[NUMCHANNELS][NUMALLPASSES];

    long   bufferLength;
    float *inputMix;
    float *outputAccumL;
    float *outputAccumR;
}

- (instancetype) init;

- (void) mute;

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB 
                        outputBuffer: (SndAudioBuffer *) outB;

- (float) paramValue: (const int) index;

- (NSString *) paramName: (const int) index;

- (void) setParam: (const int) index toValue: (const float) v;

// Recalculate internal values after parameter change
- (void) update;

@property (nonatomic) float roomSize;

@property (nonatomic) float damp;

@property (nonatomic) float wet;

@property (nonatomic) float dry;

@property (nonatomic) float width;

@property (nonatomic) float mode;

////////////////////////////////////////////////////////////////////////////////

@end

@interface SndAudioProcessorReverb (Deprecated)

- (float) getRoomSize NS_DEPRECATED_WITH_REPLACEMENT_MAC("-roomSize", 10.0, 10.8);

- (float) getDamp NS_DEPRECATED_WITH_REPLACEMENT_MAC("-damp", 10.0, 10.8);

- (float) getWet NS_DEPRECATED_WITH_REPLACEMENT_MAC("-wet", 10.0, 10.8);

- (float) getDry NS_DEPRECATED_WITH_REPLACEMENT_MAC("-dry", 10.0, 10.8);

- (float) getWidth NS_DEPRECATED_WITH_REPLACEMENT_MAC("-width", 10.0, 10.8);

- (float) getMode NS_DEPRECATED_WITH_REPLACEMENT_MAC("-mode", 10.0, 10.8);

@end

#endif
