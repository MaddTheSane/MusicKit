////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Snd methods concerned with recording and playing.
//
//  Original Author: Leigh Smith
//
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "Snd.h"
#import "SndPlayer.h"
#import "SndAudioProcessorChain.h"

@implementation Snd(Playing)

// Begin the playback of the sound at some future time, specified in seconds, over a region of the sound.
// All other play methods are convenience wrappers around this.
- (SndPerformance *) playInFuture: (double) inSeconds 
                      beginSample: (unsigned long) begin
                      sampleCount: (unsigned long) count 
{
    unsigned long playBegin = begin;
    unsigned long playEnd = begin + count;
    
    [self compactSamples]; // in case this is a pasted sound.

    if (playBegin > [self lengthInSampleFrames])
        playBegin = 0;
    
    if (playEnd > [self lengthInSampleFrames] || playEnd < playBegin)
        playEnd = [self lengthInSampleFrames];

    return [[SndPlayer defaultSndPlayer] playSnd: self 
                                  withTimeOffset: inSeconds 
                                    beginAtIndex: playBegin 
                                      endAtIndex: playEnd];
}

- (SndPerformance *) playInFuture: (double) inSeconds
           startPositionInSeconds: (double) startPos
                durationInSeconds: (double) duration
{
    double sr = [self samplingRate];
    return [self playInFuture: inSeconds
		  beginSample: startPos * sr
		  sampleCount: duration * sr];
}

+ (BOOL) isMuted
{
    return SNDIsMuted();
}

+ (void)setMute: (BOOL) aFlag
{
    SNDSetMute(aFlag);
}

// TODO: See if we can make this use self playInFuture so all use of looping
// is done in playInFuture:beginSample:sampleCount:
- (SndPerformance *) playAtTimeInSeconds: (double) t withDurationInSeconds: (double) d
{
//  NSLog(@"Snd playAtTimeInSeconds: %f", t);
  return [[SndPlayer defaultSndPlayer] playSnd: self
                               atTimeInSeconds: t
                        startPositionInSeconds: 0
                             durationInSeconds: d];  
}

- (SndPerformance *) playInFuture: (double) inSeconds 
{
    return [self playInFuture: inSeconds 
                  beginSample: 0
                  sampleCount: [self lengthInSampleFrames]];
}

- (SndPerformance *) playAtDate: (NSDate *) date
{
    return [self playInFuture: [date timeIntervalSinceNow]];
}

// Legacy method for SoundKit compatability
- (SndPerformance *) play: (id) sender beginSample: (int) begin sampleCount: (int) count 
{
    // do something with sender?
    return [self playInFuture: 0.0
		  beginSample: begin
		  sampleCount: count];
}

// Legacy method for SoundKit compatability
- (SndPerformance *) play: sender
{
    // do something with sender?
    return [self playInFuture: 0.0];
}

// Legacy method for SoundKit compatability
- (SndPerformance *)  play
{
    return [self play: self];
}

#if 0
// mirroring the playback 
- (SndCapture *) recordInFuture: (double) inSeconds
     beginSample: (unsigned long) recordBegin
     sampleCount: (unsigned long) count 
{
    
    return [[SndRecorder defaultSndRecorder] recordSnd: self 
                                  withTimeOffset: inSeconds 
                                    beginAtIndex: recordBegin 
                                      endAtIndex: recordEnd];
    
}

- (SndCapture *) recordInFuture: (double) inSeconds
{
    return [self recordInFuture: inSeconds beginSample: 0 sampleCount: SND_RECORD_CONTINUOUSLY];
}

#endif

- record: sender
{
    NSLog(@"Not yet implemented!\n");
    // [self recordInFuture: 0.0];
    return self;
}

- (SndError) record
{
    [self record: self];
    return SND_ERR_NONE;
}

- (BOOL) isRecording
{
    return NO;
}

- (int) samplesPerformedOfPerformance: (SndPerformance *) performance;
{
    return [performance playIndex];
}

- (SndError) waitUntilStopped
{
    return SND_ERR_NOT_IMPLEMENTED;
}

// stop the performance
+ (void) stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds
{
    [[SndPlayer defaultSndPlayer] stopPerformance: performance inFuture: inSeconds];
}

- (void) stopInFuture: (double) inSeconds
{
    if ([self isRecording]) {
	// TODO: must inform the SndStreamRecorder to stop.
        [self tellDelegate: @selector(didRecord:)];	
    }
  // SKoT: I commented this out as the player may have PENDING performances to
  // deal with as well - in which case the Snd won't have a playing status.
  // Basically yet another reason to move playing status stuff out of the snd obj.
//    if ([self isPlaying]) {
        [[SndPlayer defaultSndPlayer] stopSnd: self withTimeOffset: inSeconds];
//    }
}

- (void) stop: (id) sender
{
    [self stopInFuture: 0.0];
}

- (SndError) stop
{
    [self stop: self];
    return SND_ERR_NONE;
}

- pause: sender
{
    [performancesArrayLock lock];
    [performancesArray makeObjectsPerformSelector: @selector(pause)];
    [performancesArrayLock unlock];
    return self;
}

- (SndError) pause
{
    [self pause: self];
    return SND_ERR_NONE;
}

- resume: sender
{
    [performancesArrayLock lock];
    [performancesArray makeObjectsPerformSelector: @selector(resume)];
    [performancesArrayLock unlock];
    return self;
}

- (SndError) resume;
{
    [self resume:self];
    return SND_ERR_NONE;
}

- (BOOL) isPlayable
{
    SndSampleFormat df;
    int cc;
    double sr;
    
    if ([self lengthInSampleFrames] == 0)
	return YES; /* empty sound can be played! */
    df = [self dataFormat];
    cc = [self channelCount];
    if (cc < 1)
	return NO;
    sr = [self samplingRate];
    if(sr <= 0.0)
	return NO;
    switch (df) {
	case SndSampleFormatMulaw8:
	case SndSampleFormatLinear8:
	case SndSampleFormatLinear16:
	case SndSampleFormatLinear24:
	case SndSampleFormatLinear32:
	case SndSampleFormatFloat:
	case SndSampleFormatDouble:
	    return YES;
	default:
	    break;
    }
    return NO;
}

- (NSArray *) performances
{
    return performancesArray;
}

- (void)addPerformance: (SndPerformance*) p
{
    [performancesArrayLock lock];
    [performancesArray addObject: p];
    [performancesArrayLock unlock];
}

- (void)removePerformance: (SndPerformance*) p
{
    [performancesArrayLock lock];
    [performancesArray removeObject: p];
    [performancesArrayLock unlock];
}

- (NSInteger) performanceCount
{
    return [performancesArray count];
}

- (void) setLoopWhenPlaying: (BOOL) yesOrNo
{
    loopWhenPlaying = yesOrNo;
}

- (BOOL) loopWhenPlaying
{
    return loopWhenPlaying;
}

- (void) setLoopStartIndex: (long) newLoopStartIndex
{
    loopStartIndex = newLoopStartIndex;
}

- (long) loopStartIndex
{
    return loopStartIndex;
}

- (void) setLoopEndIndex: (long) newLoopEndIndex
{
    loopEndIndex = newLoopEndIndex;
}

- (long) loopEndIndex
{
    return loopEndIndex;
}

- (BOOL) isPlaying
{
    // if any performances are currently playing, return YES.
    
    for(SndPerformance *perform in performancesArray) {
	if([perform isPlaying])
	    return YES;
    }
    // 
    // performancesArrayLock
    return NO;
}

- (void) setAudioProcessorChain: (SndAudioProcessorChain *) newAudioProcessorChain
{
    audioProcessorChain = newAudioProcessorChain;
}

- (SndAudioProcessorChain *) audioProcessorChain
{
    return audioProcessorChain;
}

- (void) adjustLoopStart: (long *) newLoopStart 
		     end: (long *) newLoopEnd
	   afterRemoving: (long) sampleCountRemoved
	      startingAt: (long) startSample
{
    // NSLog(@"*newLoopStart %ld, *newLoopEnd %ld\n", *newLoopStart, *newLoopEnd);
    if(*newLoopEnd < startSample + sampleCountRemoved)
	*newLoopEnd = MIN(*newLoopEnd, [self lengthInSampleFrames] - 1); // loop end points at last sample played.
    else {
	*newLoopEnd -= sampleCountRemoved;
	if(*newLoopEnd < 0)
	    *newLoopEnd = 0;
    }
    if(*newLoopStart < startSample + sampleCountRemoved)
	// TODO: Perhaps just leave it rather than moving it to startSample?
	*newLoopStart = MIN(*newLoopStart, startSample); 
    else {
	*newLoopStart -= sampleCountRemoved;
	if(*newLoopStart < 0)
	    *newLoopStart = 0;	    
    }
    // NSLog(@"after deleting *newLoopStart %ld, *newLoopEnd %ld\n", *newLoopStart, *newLoopEnd);    
}

- (void) adjustLoopStart: (long *) newLoopStart 
		     end: (long *) newLoopEnd
	     afterAdding: (long) sampleCountAdded
	      startingAt: (long) startSample
{
    long soundLength = [self lengthInSampleFrames];
    
    // NSLog(@"adding %ld to *newLoopStart %ld, *newLoopEnd %ld \n", sampleCountAdded, *newLoopStart, *newLoopEnd);
    if(*newLoopEnd < startSample)
	*newLoopEnd = MIN(*newLoopEnd, soundLength - 1);  // loop end points at last sample played.
    else {
	*newLoopEnd += sampleCountAdded;
	if(*newLoopEnd >= soundLength)
	    *newLoopEnd = soundLength - 1;  // loop end points at last sample played.
    }
    if(*newLoopStart >= startSample) {
	*newLoopStart += sampleCountAdded;
	if(*newLoopStart >= soundLength)
	    *newLoopStart = soundLength - 1;  // loop start points at first sample played.
    }
    // NSLog(@"after adding *newLoopStart %ld, *newLoopEnd %ld, soundLength %ld\n", *newLoopStart, *newLoopEnd, soundLength);    
}

- (void) adjustLoopsAfterAdding: (BOOL) adding 
			 frames: (long) sampleCount
		     startingAt: (long) startSample
{
    int performanceIndex;
    
    // Update loop end index and in all performances.
    if(adding) {
	[self adjustLoopStart: &loopStartIndex
			  end: &loopEndIndex
		  afterAdding: sampleCount
		   startingAt: startSample];	
    }
    else {
	[self adjustLoopStart: &loopStartIndex
			  end: &loopEndIndex
		afterRemoving: sampleCount
		   startingAt: startSample];
    }
    for(performanceIndex = 0; performanceIndex < [performancesArray count]; performanceIndex++) {
	SndPerformance *performance;
	long performanceStartLoopIndex;
	long performanceEndLoopIndex;
	
	[performancesArrayLock lock]; // TODO: check this is right.
	performance = [performancesArray objectAtIndex: performanceIndex];
	performanceStartLoopIndex = [performance loopStartIndex];
	performanceEndLoopIndex = [performance loopEndIndex];
	if(adding) {
	    [self adjustLoopStart: &performanceStartLoopIndex
			      end: &performanceEndLoopIndex
		      afterAdding: sampleCount
		       startingAt: startSample];
	    [performance setEndAtIndex: [performance endAtIndex] + sampleCount];
	}
	else {
	    [self adjustLoopStart: &performanceStartLoopIndex
			      end: &performanceEndLoopIndex
		    afterRemoving: sampleCount
		       startingAt: startSample];
	    // We need to check if playIndex is beyond the potential new endAtIndex. 
	    // If so, we need to adjust it, otherwise it will be set to the endAtIndex in setEndAtIndex:
	    if([performance playIndex] >= [performance endAtIndex] - sampleCount) {
		// NSLog(@"beyond the new end, need to reset the startIndex to beginning\n");
		[performance setPlayIndex: 0];
	    }
	    [performance setEndAtIndex: [performance endAtIndex] - sampleCount];
	}
	// NSLog(@"performanceEndLoopIndex %ld startAtIndex %ld endAtIndex %ld\n",
	//      performanceEndLoopIndex, [performance startAtIndex], [performance endAtIndex]);
	[performance setLoopStartIndex: performanceStartLoopIndex];
	[performance setLoopEndIndex: performanceEndLoopIndex];
	[performancesArrayLock unlock];
    }
}

@end
