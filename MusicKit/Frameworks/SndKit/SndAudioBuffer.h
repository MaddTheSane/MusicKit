////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: An object for containings raw audio data, and doing audio 
//               operations on that data
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.
//
//  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDAUDIOBUFFER_H__
#define __SNDAUDIOBUFFER_H__

#import <Foundation/Foundation.h>
#import <MKPerformSndMIDI/PerformSound.h>
#import "Snd.h"
/*!
@class SndAudioBuffer
@abstract   Audio Buffer
@discussion To come
*/
@interface SndAudioBuffer : NSObject
{
/*! @var byteCount  */
  unsigned int byteCount;
/*! @var maxByteCount  */
  unsigned int maxByteCount;
/*! @var samplingRate  */
  double samplingRate;
/*! @var dataFormat */
  int    dataFormat;
/*! @var channelCount  */
  int    channelCount;
/*! @var data */
  NSMutableData *data;
}

/*!
  @method     audioBufferWithFormat:duration:
  @abstract   Factory method
  @discussion
  @param      format
  @param      timeInSec
  @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format duration: (double) timeInSec;

/*!
  @method     audioBufferWithFormat:channelCount:samplingRate:duration:
  @abstract   Factory method
  @discussion
  @param      dataFormat
  @param      chanCount
  @param      samRate
  @param      duration
  @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (int) dataFormat
           channelCount: (int) chanCount
           samplingRate: (double) samRate
               duration: (double) time;

/*!
    @method     audioBufferWithFormat:data:
    @abstract   Factory method
    @discussion The dataLength member of format MUST be set to the length of d (in bytes)!
    @param      format
    @param      d
    @result     An SndAudioBuffer
*/
+ audioBufferWithFormat: (SndSoundStruct*) format data: (void*) d;

/*!
    @method     audioBufferWrapperAroundSNDStreamBuffer:
    @abstract   Factory method
    @discussion
    @param      cBuff
    @result     An SndAudioBuffer
*/
+ audioBufferWrapperAroundSNDStreamBuffer: (SNDStreamBuffer*) cBuff;

/*!
    @method     audioBufferWithSndSeg:range:
    @abstract   Factory method
    @discussion
    @param      snd 
    @param      r
    @result     An SndAudioBuffer 
*/
+ audioBufferWithSndSeg: (Snd*) snd range: (NSRange) r;

/*!
  @method     initWithFormat:data:
  @abstract   Initialization method
  @discussion
  @param      f
  @param      d
  @result     self.
*/
- initWithFormat: (SndSoundStruct*) f data: (void*) d;

/*!
  @method     initWithBuffer:
  @abstract   Initialization method
  @discussion
  @param      b
  @result     self.
*/
- initWithBuffer: (SndAudioBuffer*) b;
/*!
  @method     initWithBuffer:range:
  @abstract   Initialization method
  @discussion
  @param      b
  @param      r
  @result     self.
*/
- initWithBuffer: (SndAudioBuffer*) b
           range: (NSRange) r;

/*!
  @method     initWithFormat:channelCount:samplingRate:duration:
  @abstract   Initialization method
  @discussion
  @param      _dataFormat
  @param      _channelCount
  @param      _samplingRate
  @param      time
  @result     An SndAudioBuffer
*/
- initWithFormat: (int) _dataFormat
    channelCount: (int) _channelCount
    samplingRate: (double) _samplingRate
        duration: (double) time;

/*!
  @method     mixWithBuffer:fromStart:toEnd:
  @abstract   Initialization method
  @discussion
  @param      buff
  @param      start
  @param      end
  @param      exp if TRUE, receiver is allowed to expand <i>buff</i> in place
                  if required to change format before mixing.
  @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff
      fromStart: (long) start
          toEnd: (long) end
      canExpand: (BOOL) exp;

/*!
  @method   mixWithBuffer:
  @abstract
  @discussion
  @param      buff
  @result     self.
*/
- mixWithBuffer: (SndAudioBuffer*) buff;

/*!
  @method     copy
  @abstract
  @discussion
  @result     A duplicate SndAudioBuffer with its own, identical data.
*/
- copy;

/*!
  @method     copyData:
  @abstract
  @discussion
  @param      ab
  @result     self.
*/
- copyData: (SndAudioBuffer*) ab;

/*!
  @method     copyBytes:count:format:
  @abstract   copies bytes from the char* array given
  @discussion grows the internal NSMutableData object as necessary
  @param      bytes the char* array to copy from
  @param      count the number of bytes to copy from the array
  @param      format pointer to a SndSoundStruct containing valid channelCount,
              samplingRate and dataFormat variables.
  @result     self.
*/
- copyBytes: (char*) bytes count:(unsigned int)count format:(SndSoundStruct *)f;

/*!
  @method     lengthInSamples
  @abstract
  @discussion
  @result     buffer length in sample frames
*/
- (long) lengthInSampleFrames;

/*!
  @method     lengthInBytes
  @abstract
  @discussion
  @result     buffer length in bytes
*/
- (long) lengthInBytes;

/*!
  @method     duration
  @abstract
  @discussion
  @result     Duration in seconds (as determined by format sampling rate)
*/
- (double) duration;

/*!
  @method     samplingRate
  @abstract
  @discussion
  @result     sampling rate
*/
- (double) samplingRate;
/*!
  @method     channelCount
  @abstract
  @discussion
  @result     Number of channels
*/
- (int) channelCount;
/*!
  @method     dataFormat
  @abstract
  @discussion
  @result     Data format identifier
*/
- (int) dataFormat;

/*!
  @method     data
  @abstract
  @discussion
  @result     pointer to NSData object contaiing the audio data
*/
//- (NSMutableData*) data;

/*!
  @method     bytes
  @abstract
  @discussion
  @result     pointer to NSData object contaiing the audio data
*/
- (void*) bytes;

/*!
  @method     hasSameFormatAsBuffer:
  @abstract   compares the data format and length of this buffer to a second buffer
  @param      buff
  @result     TRUE if the buffers have the same format and length
*/
- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer*) buff;

/*!
  @method convertToFormat:
  @param  sndFormatCode
*/
- convertToFormat: (int) sndFormatCode;

/*!
  @method convertDataToFormat:
  @param  newDataFormat
  @param  newData
*/
- (NSMutableData*) convertDataToFormat: (int) newDataFormat;

/*!
    @method     zero
    @abstract   Sets data to zero
    @discussion
    @result     self
*/
- zero;

/*!
    @method     zeroForeignBuffer
    @abstract   Sets buffer data to zero, regardless of whether the buffer is owned by the SndAudioBuffer or not.
    @discussion Same as zero, but skips a buffer ownership test.
    @result     self
*/
- (void) zeroForeignBuffer;

/*!
    @method     frameSizeInBytes
    @abstract
    @discussion
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (int) frameSizeInBytes;

/*!
    @method     description
    @abstract    
    @discussion 
    @result     Integer size of sample frame (channels * sample size in bytes)
*/
- (NSString*) description;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
