////////////////////////////////////////////////////////////////////////////////
//
//  SndMP3.h
//  SndKit
//
//  Created by SKoT McDonald on Tue Apr 16 2002.
//  Copyright (c) 2002 SndKit. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_MP3_H__
#define __SND_MP3_H__

#import <Foundation/Foundation.h>
#import "Snd.h"

////////////////////////////////////////////////////////////////////////////////

@interface SndMP3 : Snd {
  NSData        *mp3Data;
  NSMutableData *pcmData;

  long          *frameLocations;
  long           frameLocationsCount;
  double         duration;
  long           lengthInSampleFrames;
  long           decodedSampledCount;
  BOOL           bDecoding;

  NSLock        *pcmDataLock;
}

- (int) readSoundURL: (NSURL *) soundURL;
- initFromSoundURL: (NSURL *) url;
- (void) dealloc;
- (double) duration;
- (long) lengthInSampleFrames;
- (int) channelCount;
- (double) samplingRate;

/*!
  @method convertToNativeFormat
  @discussion Actually all this does is check the MP3 is the same as the native format, if not it flags an error.
 */
- (int) convertToNativeFormat;

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
	        intoFrameRange: (NSRange) bufferRange
	        samplesInRange: (NSRange) sndReadingRange;

- (int) readSoundfile: (NSString*) filename;
- (int) readSoundURL: (NSURL*) soundURL
   startTimePosition: (double) segmentStartTime
            duration: (double) segmentDuration;

/*!
  @method soundFileExtensions
  @result Returns an array of file extensions available for reading and writing.
  @discussion Returns an array of file extensions indicating the file format (and file extension)
  that audio files may be read from or written to. Includes all of Snd's formats and "mp3".
 */
+ (NSArray *) soundFileExtensions;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
