////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    This class is to be regarded as HIGHLY EXPERIMENTAL.
//    Don't use it for general Snd use!!!
//
//    Current experimental activity - stream from disk behaviour.
//    Should be safe to use for playback ONLY!!
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_

#import <Foundation/Foundation.h>

#import <SndKit/Snd.h>

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndOnDisk
@brief Experimental Snd class. USE WITH EXTREME CAUTION.
 _ONLY_ use SndOnDisk for solo playback at present.

  Experimental testing and development ground for disk-based Snds.
*/

@interface SndOnDisk : Snd {
  BOOL             bImageInMemory;
  NSString        *theFileName;
  
  SndAudioBuffer  *cachedBuffer;
  NSRange          cachedBufferRange;
  NSLock          *cacheLock;

  NSConditionLock *readAheadLock;
  SndAudioBuffer  *readAheadBuffer;
  NSRange          readAheadRange;
}

- init;
- (void) dealloc;
- (unsigned char*) data;
- (long) dataSize;
- (SndError) readSoundfile:(NSString *)filename startFrame: (int) startFrame frameCount: (int) frameCount;
- (SndError) readSoundfile: (NSString*) filename;
- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion;
- (long) fillAudioBuffer: (SndAudioBuffer *) buff
	        toLength: (long) fillLength
          samplesInRange: (NSRange) sndSampleReadRange;

@property (readonly, copy) NSString *filename;

- (void)requestNextBufferWithRange: (NSRange) range;
- (void)receiveRequestedBuffer: (SndAudioBuffer*) aBuffer;

@end

@interface SndOnDiskAudioBufferServerJob : NSObject {
  SndOnDisk        *clientSndOnDisk;
  NSRange         audioBufferRange;
  SndAudioBuffer *audioBuffer;
}

- initWithSndOnDisk: (SndOnDisk*) sndExpt bufferRange: (NSRange) range;
@property (readonly, retain) SndOnDisk *snd;
@property (readonly) NSRange range;
@property (readonly, retain) SndAudioBuffer *buffer;

@end

@interface SndOnDiskAudioBufferServer : NSObject {
  NSMutableArray  *pendingJobsArray;
  NSConditionLock *pendingJobsArrayLock;
  BOOL bGo;
  SndOnDiskAudioBufferServerJob *activeJob;
}

+ (void) initialize;
+ (SndOnDiskAudioBufferServer*)defaultServer;
@property (class, readonly, retain) SndOnDiskAudioBufferServer *defaultServer;
+ (SndAudioBuffer*) readRange: (NSRange) range ofSoundFile: (NSString*) theFileName;
- addJob: (SndOnDiskAudioBufferServerJob*) aJob;
- (void) serverThread;
@end

////////////////////////////////////////////////////////////////////////////////

#endif
