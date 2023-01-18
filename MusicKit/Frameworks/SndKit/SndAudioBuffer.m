////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    In memory audio buffer. See SndAudioBuffer.h for description.
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <math.h>
#import "SndAudioBuffer.h"
#import "SndMuLaw.h"

// vector library support is currently only available on MacOS X.
// But there are a small set of SSE replacement routines under GCC.
#if defined(__APPLE_CC__)
#import <Accelerate/Accelerate.h>
#elif (__i386__ && __GNUC__)
#import "vDSP.h"
#endif

#define SNDAUDIOBUFFER_DEBUG_MIXING 0

@implementation SndAudioBuffer

////////////////////////////////////////////////////////////////////////////////
// audioBufferWrapperAroundSNDStreamBuffer:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSNDStreamBuffer: (SNDStreamBuffer *) streamBuffer
{
    // Repack the format parameters from the stream buffer into a SndFormat structure.
    SndFormat streamFormat = SndFormatOfSNDStreamBuffer(streamBuffer);
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: &streamFormat
    							   data: streamBuffer->streamData];
    
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithSnd:inRange:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithSnd: (Snd *) snd inRange: (NSRange) rangeInFrames
{
    SndFormat sndFormat = [snd format];
    SndAudioBuffer *ab;
 
    sndFormat.frameCount = rangeInFrames.length;
    ab = [[SndAudioBuffer alloc] initWithFormat: &sndFormat
					   data: [snd bytes] + rangeInFrames.location * SndFrameSize(sndFormat)];
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndFormat *) newFormat data: (void *) sampleData
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: newFormat data: sampleData];
    
    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithFormat:duration:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithFormat: (SndFormat) newFormat
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithFormat: &newFormat data: NULL];

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithDataFormat:channelCount:samplingRate:duration:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithDataFormat: (SndSampleFormat) newDataFormat
	       channelCount: (int) newChannelCount
               samplingRate: (double) newSamplingRate
                   duration: (double) timeInSeconds
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithDataFormat: newDataFormat
						       channelCount: newChannelCount
						       samplingRate: newSamplingRate
							   duration: timeInSeconds];

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferWithDataFormat:channelCount:samplingRate:frameCount:
////////////////////////////////////////////////////////////////////////////////

+ audioBufferWithDataFormat: (SndSampleFormat) newDataFormat
	       channelCount: (int) newChannelCount
               samplingRate: (double) newSamplingRate
		 frameCount: (long) newFrameCount
{
    SndAudioBuffer *ab = [[SndAudioBuffer alloc] initWithDataFormat: newDataFormat
						       channelCount: newChannelCount
						       samplingRate: newSamplingRate
							 frameCount: newFrameCount];
    
    return [ab autorelease];
}

- (void) stereoChannels: (int *) leftAndRightChannels
{
    memcpy(leftAndRightChannels, speakerConfiguration, 2 * sizeof(int));
}

- (NSArray *) speakerConfiguration
{
    signed char speakerIndex;  // A maximum of 128 channels - plenty!
    SndFormat nativeFormat = [Snd nativeFormat];
    NSMutableArray *speakerNamesArray = [NSMutableArray arrayWithCapacity: nativeFormat.channelCount];
    const char **speakerNames = SNDSpeakerConfiguration();
    
    if(speakerConfiguration != NULL)
	free(speakerConfiguration);
    speakerConfiguration = (signed char *) malloc(SND_SPEAKER_SIZE * sizeof(signed char));	

    // Default to the left channel preceding the right in the sample data.
    speakerConfiguration[SND_SPEAKER_LEFT] = 0;
    speakerConfiguration[SND_SPEAKER_RIGHT] = 1;
    
    for(speakerIndex = 0; speakerIndex < nativeFormat.channelCount; speakerIndex++) {
        // Cache the speaker configuration so that stereoChannels is a fast method.
        if(strcmp("Left", speakerNames[speakerIndex]) == 0)
            speakerConfiguration[SND_SPEAKER_LEFT] = speakerIndex;
        else if(strcmp("Right", speakerNames[speakerIndex]) == 0)
            speakerConfiguration[SND_SPEAKER_RIGHT] = speakerIndex;
	else
	    speakerConfiguration[SND_SPEAKER_RIGHT] = SND_SPEAKER_UNUSED;
        [speakerNamesArray addObject: [NSString stringWithUTF8String: speakerNames[speakerIndex]]];
    }
    
    return [NSArray arrayWithArray: speakerNamesArray];
}

////////////////////////////////////////////////////////////////////////////////
// initWithBuffer:range:
////////////////////////////////////////////////////////////////////////////////

- initWithBuffer: (SndAudioBuffer *) b
           range: (NSRange) rangeInFrames
{
    self = [self init];
    if (self) {
	void *ptr = NULL;
	int frameSize  = 0, length, offset;
	int dataLength = 0;
	
	format = b->format;
	frameSize = [self frameSizeInBytes];
	ptr = [b bytes] + frameSize * rangeInFrames.location;
	length = frameSize * rangeInFrames.length;
	offset = frameSize * rangeInFrames.location;
	
	if (offset + length > [b lengthInBytes])
	    dataLength = [b lengthInBytes] - offset;
	else
	    dataLength = length;
	
	if (length < 0)
	    NSLog(@"SndAudioBuffer::initWithBuffer:range: ERR - length (%d) < 0! frameSize = %d, range.length = %lu", length, frameSize, (unsigned long) rangeInFrames.length);
        
	[data setLength: dataLength];
	memcpy([data mutableBytes], ptr, dataLength);
	format.frameCount = dataLength / frameSize;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithBuffer:
////////////////////////////////////////////////////////////////////////////////

- initWithBuffer: (SndAudioBuffer *) b
{
    self = [self init];
    if (self) {
        format = b->format;
        [data release];
        data = [[NSMutableData alloc] initWithData: b->data];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithFormat:data:
////////////////////////////////////////////////////////////////////////////////

// This is the designated initializer.
- initWithFormat: (SndFormat *) newFormat data: (void *) sampleData
{
    self = [super init];
    if (self != nil) {
	long byteCount;

        format = *newFormat;

        byteCount = SndDataSize(format);

        if (byteCount < 0)
            NSLog(@"SndAudioBuffer -initWithFormat: error byteCount (%ld) < 0", byteCount);

	[data release];
        if (sampleData == NULL) {
            data = [[NSMutableData alloc] initWithLength: byteCount];
        }
        else {
            data = [[NSMutableData alloc] initWithBytes: sampleData length: byteCount];
        }
	// TODO: Perhaps cache this in +initialize and just copy the speaker configuration array.
	// [self speakerConfiguration];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithDataFormat:channelCount:samplingRate:frameCount:
////////////////////////////////////////////////////////////////////////////////

- initWithDataFormat: (SndSampleFormat) newDataFormat
	channelCount: (int) newChannelCount
        samplingRate: (double) newSamplingRate
          frameCount: (long) newFrameCount
{
    SndFormat newFormat;
    
    newFormat.sampleRate   = newSamplingRate;
    newFormat.channelCount = newChannelCount;
    newFormat.dataFormat   = newDataFormat;
    newFormat.frameCount   = newFrameCount;
    return [self initWithFormat: &newFormat data: NULL];
}

// Convenience method.
- initWithDataFormat: (SndSampleFormat) newDataFormat
	channelCount: (int) newChannelCount
        samplingRate: (double) newSamplingRate
            duration: (double) timeInSeconds
{
    return [self initWithDataFormat: newDataFormat
		       channelCount: newChannelCount
		       samplingRate: newSamplingRate
			 frameCount: timeInSeconds * newSamplingRate];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    // Default format typical for modern hardware.
    return [self initWithDataFormat: SND_FORMAT_LINEAR_16
		       channelCount: 2
		       samplingRate: 44100.0
			 frameCount: 0];
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [data release];
    data = nil;
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    float sampleMin, sampleMax;
    
    [self findMin: &sampleMin max: &sampleMax];
    return [NSString stringWithFormat: @"%@ (%@) (min: %.3f, max: %.3f)",
        [super description], SndFormatDescription(format), sampleMin, sampleMax];
}

////////////////////////////////////////////////////////////////////////////////
// zeroFrameRange:
////////////////////////////////////////////////////////////////////////////////

- zeroFrameRange: (NSRange) frameRange
{
    int frameSize = [self frameSizeInBytes];
    
    // TODO: this assumes all bytes per sample need to be set to zero to create a zero valued sample.
    memset([data mutableBytes] + frameRange.location * frameSize, 0, frameRange.length * frameSize);
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// zero
////////////////////////////////////////////////////////////////////////////////

- zero
{
    // We could be more conservative and call zeroFrameRange, but in the interests of efficiency of calculating
    // the range, we just blank the whole thing. This will only be inefficient if the lengthInSampleFrames is
    // less than the data length.
    memset([data mutableBytes], 0, [data length]);
    return self;
}

    
////////////////////////////////////////////////////////////////////////////////
// micro accessors
////////////////////////////////////////////////////////////////////////////////

- (SndSampleFormat) dataFormat { return format.dataFormat;   }
- (NSData *) data              { return [[data retain] autorelease]; }
- (void *) bytes               { return [data mutableBytes]; }
- (int) channelCount           { return format.channelCount; }
- (double) samplingRate        { return format.sampleRate; }
- (SndFormat) format           { return format; }

////////////////////////////////////////////////////////////////////////////////
// duration
////////////////////////////////////////////////////////////////////////////////

- (double) duration
{
    return (double) [self lengthInSampleFrames] / format.sampleRate;
}

////////////////////////////////////////////////////////////////////////////////
// hasSameFormatAsBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer *) buff
{
    if (buff == nil)
        return FALSE;
    else
#if 0
	return format == buff->format;
#else
	return ( format.dataFormat   == buff->format.dataFormat   ) &&
               ( format.sampleRate   == buff->format.sampleRate   ) &&
               ( format.channelCount == buff->format.channelCount ) &&
               ( format.frameCount   == buff->format.frameCount   );
#endif
}

////////////////////////////////////////////////////////////////////////////////
// mixWithBuffer:fromStart:toEnd:canExpand
////////////////////////////////////////////////////////////////////////////////

- (long) mixWithBuffer: (SndAudioBuffer *) buff
	     fromStart: (unsigned long) startFrame
		 toEnd: (unsigned long) endFrame
	     canExpand: (BOOL) canExpandInPlace
{
    unsigned long lengthInSampleFrames = [self lengthInSampleFrames];
    unsigned long incomingLengthInSampleFrames = [buff lengthInSampleFrames];
    int selfDataFormat = [self dataFormat];
    int buffDataFormat = [buff dataFormat];
    long frameCount;
    long lengthInSamples;
    int selfNumChannels = [self channelCount];
    int buffNumChannels = [buff channelCount];
    float *in = NULL;
    float *out = (float *) [data bytes];
    SndAudioBuffer *convertedBuffer = nil;
    
    if (startFrame > lengthInSampleFrames)
	NSLog(@"mixWithBuffer: startFrame %lu is > length %lu", startFrame, lengthInSampleFrames);
    else if (endFrame > lengthInSampleFrames) {
	NSLog(@"mixWithBuffer: endFrame %lu is > length %lu - truncating", endFrame, lengthInSampleFrames);
	endFrame = lengthInSampleFrames;
    }

    frameCount = MIN(incomingLengthInSampleFrames, endFrame - startFrame);
    // number of samples for all channels. This remains correct following buffer conversion, if necessary.
    lengthInSamples = frameCount * selfNumChannels; 

    // Check whether we need to convert formats of buffers
    if (![self hasSameFormatAsBuffer: buff]) {
	if (canExpandInPlace && selfNumChannels == buffNumChannels) { /* expand in place - saves allocating new buffer/data object */
	    SndChangeSampleType([buff bytes], [buff bytes], buffDataFormat, selfDataFormat, lengthInSamples);
	    in = [buff bytes];
	}
	else {
	    convertedBuffer = [[buff audioBufferConvertedToFormat: selfDataFormat
						     channelCount: selfNumChannels
						     samplingRate: [self samplingRate]] retain];
	    in = [convertedBuffer bytes];
	    // NSLog(@"buff = %@, convertedBuffer = %@\n", buff, convertedBuffer);
	}
#if SNDAUDIOBUFFER_DEBUG_MIXING
	NSLog(@"mixWithBuffer: had to convert from format %@, channels %d to format %@, channels = %d\n", 
            SndFormatName(buffDataFormat, NO), buffNumChannels, SndFormatName(selfDataFormat, NO), selfNumChannels);
#endif
    }
    else {
	in = [buff bytes];
#if SNDAUDIOBUFFER_DEBUG_MIXING
	NSLog(@"mixWithBuffer: no conversion mixing.");
#endif
    }
    out += startFrame * selfNumChannels; // use selfNumChannels since we may have changed the channel count.
    // TODO: we need a universal vector mixer for all destination sample formats.
    if(selfDataFormat == SND_FORMAT_FLOAT) {
#if defined(__APPLE_CC__) // || (__i386__ && __GNUC__)
	// NSLog(@"vectors in %p, out %p, lengthInSamples %d", in, out, lengthInSamples);
	vDSP_vadd(in, 1, out, 1, out, 1, lengthInSamples);
#else
#warning Vector units not available, using scalar mixing.
	unsigned long sampleIndex;
	
	for (sampleIndex = 0; sampleIndex < lengthInSamples; sampleIndex++) {
	    out[sampleIndex] += in[sampleIndex]; // interleaving automatically taken care of!
	}
#endif
#if SNDAUDIOBUFFER_DEBUG_MIXING
	NSLog(@"out[0]: %f in[0]: %f lengthInSamples:%li\n", out[0], in[0], lengthInSamples);
	NSLog(@"out[1]: %f in[1]: %f lengthInSamples:%li\n", out[1], in[1], lengthInSamples);
	NSLog(@"out[2]: %f in[2]: %f lengthInSamples:%li\n", out[2], in[2], lengthInSamples);
	NSLog(@"out[3]: %f in[3]: %f lengthInSamples:%li\n", out[3], in[3], lengthInSamples);
#endif
    }
    else {
	NSLog(@"mixWithBuffer: attempting to mix into buffer of unsupported format %d\n", selfDataFormat);
    }
    if (convertedBuffer)
	[convertedBuffer release];

    return frameCount;
}

////////////////////////////////////////////////////////////////////////////////
// mixWithBuffer:
////////////////////////////////////////////////////////////////////////////////

- (long) mixWithBuffer: (SndAudioBuffer *) buff
{
    // NSLog(@"mix %@ with new buffer: %@\n", self, buff);

    return [self mixWithBuffer: buff 
	             fromStart: 0 
                         toEnd: [self lengthInSampleFrames]
                     canExpand: NO];
}

- (SndAudioBuffer *) audioBufferOfChannel: (int) channelNumber
{
    SndAudioBuffer *monoBuffer;
    SndSampleFormat dataFormat = [self dataFormat];
    long frameCount = [self lengthInSampleFrames];
    short mapChannel = channelNumber;
    
    if(channelNumber < 0 || channelNumber > format.channelCount) {
	NSLog(@"SndAudioBuffer audioBufferOfChannel: channel %d out of range [0,%d]\n", channelNumber, format.channelCount);
	return nil;
    }
    
    monoBuffer = [SndAudioBuffer audioBufferWithDataFormat: dataFormat
					      channelCount: 1
					      samplingRate: [self samplingRate]
						frameCount: frameCount];
    SndChannelMap([self bytes], [monoBuffer bytes], frameCount, [self channelCount], 1, dataFormat, &mapChannel);
	
    return monoBuffer;
}

////////////////////////////////////////////////////////////////////////////////
// copyWithZone:
////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone: (NSZone *) zone
{
    SndAudioBuffer *dest = [[[self class] allocWithZone: zone] initWithBuffer: self];
    return dest; // copy returns a retained object according to NSObject spec
}

////////////////////////////////////////////////////////////////////////////////
// copyDataFromBuffer:
////////////////////////////////////////////////////////////////////////////////

- copyDataFromBuffer: (SndAudioBuffer *) from
{
    if (from != nil) {
        if ([self hasSameFormatAsBuffer: from])
            [data setData: [from data]];
        else {
            NSLog(@"SndAudioBuffer -copyDataFromBuffer: Buffers are different formats from %@ to %@ - unhandled case!", from, self);
            // TODO! use copyFromBuffer instead
        }
    }
    else
        NSLog(@"SndAudioBuffer -copyDataFromBuffer: ERR: param 'from' is nil!");
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// copyBytes:intoRange:format:
////////////////////////////////////////////////////////////////////////////////

- copyBytes: (void *) bytes intoRange: (NSRange) bytesRange format: (SndFormat) newFormat
{
    long originalFrameCount = format.frameCount;
    long lastFrameLocation;
    
    if (!bytes) {
	NSLog(@"AudioBuffer::copyBytes:intoRange:format: ERR: param 'from' is nil!");
	return nil;
    }
    [data replaceBytesInRange: bytesRange withBytes: (const void *) bytes];
    format = newFormat;
    // Can extend the frame count.
    lastFrameLocation = (bytesRange.location + bytesRange.length) / [self frameSizeInBytes];
    format.frameCount = MAX(lastFrameLocation, originalFrameCount);
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// copyBytes:count:format:
////////////////////////////////////////////////////////////////////////////////

- copyBytes: (void *) bytes count: (unsigned int) count format: (SndFormat) newFormat
{
    return [self copyBytes: bytes intoRange: NSMakeRange(0, count) format: newFormat];
}

// This is pretty kludgy, it only really works for SND_FORMAT_LINEAR_16 to SND_FORMAT_FLOAT conversions. It should
// be revamped to work with all formats, and to do channel mapping if necessary.
- (long) copyFromBuffer: (SndAudioBuffer *) fromBuffer
	 intoFrameRange: (NSRange) bufferFrameRange
	 fromFrameRange: (NSRange) fromFrameRange
{
    int numOfChannelsInBuffer = [self channelCount];
    // We could simply store all pcm data into a 2 channel (stereo) buffer and then do the conversion to larger
    // number of channels later, but in the interests of efficiency and the mess of not properly filling our given
    // buffer, we move the pcm channels into the stereo channels of the audio buffer.
    // Left channel in 0th element, Right channel in 1st element.
    short stereoChannels[2] = { 0, 1 };
    // short stereoChannels[2];
    // [fromBuffer stereoChannels: stereoChannels];
    short *fromData = [fromBuffer bytes];
    
    if (bufferFrameRange.length > format.frameCount) {
	NSLog(@"frameRange length %ld exceeds buffer length %lu\n", format.frameCount, (unsigned long)bufferFrameRange.length);
    }

    // Catch the trivial case where both buffers have the same format (although the frame counts can differ),
    // if so we just copy data.
    if ((format.dataFormat   == [fromBuffer dataFormat]) &&
	(format.sampleRate   == [fromBuffer samplingRate]) &&
	(format.channelCount == [fromBuffer channelCount]) &&
	bufferFrameRange.length == fromFrameRange.length) {
	unsigned long frameWidth = SndFrameSize([self format]);
	NSRange rangeInBytes;
	
	rangeInBytes.location = bufferFrameRange.location * frameWidth;
	rangeInBytes.length = bufferFrameRange.length * frameWidth;
	[self copyBytes: [fromBuffer bytes] + (fromFrameRange.location * frameWidth) intoRange: rangeInBytes format: format];
    }
    else {
#if 0
	return [self convertBytes: [fromBuffer bytes] + (fromFrameRange.location * SndFrameSize([fromBuffer format]))
		   intoFrameRange: bufferFrameRange
		       fromFormat: [fromBuffer dataFormat]
		     channelCount: [fromBuffer channelCount]
		     samplingRate: [fromBuffer samplingRate]];
	// TODO: need to pass in the channel conversion map.
#else	
	
	
	switch ([self dataFormat]) {
	    case SND_FORMAT_FLOAT: {
		// Our buffer is in an array of floats, numOfChannelsInBuffer per frame.
		// TODO: we should rewrite this to manipulate the audio data as array of bytes until we need to actually do the conversion.
		// This is preferable to having duplicated code with just a couple of changes for type definitions and arithmetic.
		// So the switch statement should be moved inside the loops.
		float *buff = [self bytes];  
		unsigned long frameIndex;
		unsigned long sampleIndex;
		unsigned short channelIndex;
		
		for (frameIndex = 0; frameIndex < fromFrameRange.length; frameIndex++) {
		    long currentBufferSample = (bufferFrameRange.location + frameIndex) * numOfChannelsInBuffer;
		    // LAME always produces stereo data in two separate buffers
		    long currentSample = (fromFrameRange.location + frameIndex) * [fromBuffer channelCount];
		    
		    buff[currentBufferSample + stereoChannels[0]] = fromData[currentSample] / 32768.0;
		    buff[currentBufferSample + stereoChannels[1]] = fromData[currentSample + 1] / 32768.0;
		    // Silence any other (neither L or R) channels in the buffer.
		    for(channelIndex = 0; channelIndex < numOfChannelsInBuffer; channelIndex++) {
			if(channelIndex != stereoChannels[0] && channelIndex != stereoChannels[1]) {
			    // we use integer values for zero so they will cast appropriate to the size of buff[x].
			    buff[currentBufferSample + channelIndex] = 0;
			}
		    }
		}
		// Silence the rest of the buffer, all channels
		for (sampleIndex = (bufferFrameRange.location + frameIndex) * numOfChannelsInBuffer; sampleIndex < (bufferFrameRange.location + bufferFrameRange.length) * numOfChannelsInBuffer; sampleIndex++) {
		    buff[sampleIndex] = 0;
		}
		
		break;
	    }
	    default:
		NSLog(@"SndAudioBuffer -copyFromBuffer:intoFrameRange:fromRange: - unhandled data format %d", [self dataFormat]);
	}
#endif
    }
    return fromFrameRange.length;
}

////////////////////////////////////////////////////////////////////////////////
// copyFromBuffer:intoRange:
////////////////////////////////////////////////////////////////////////////////

- copyFromBuffer: (SndAudioBuffer *) fromBuffer intoRange: (NSRange) rangeInFrames
{
#if 0
    return [self copyFromBuffer: fromBuffer
		 intoFrameRange: rangeInFrames
		 fromFrameRange: NSMakeRange(0, rangeInFrames.length)];
#else	
    if([self hasSameFormatAsBuffer: fromBuffer]) {
	long   frameSize;
	NSRange rangeInBytes;
	
	frameSize = SndFrameSize(format);
	
	rangeInBytes.location = rangeInFrames.location * frameSize;
	rangeInBytes.length = rangeInFrames.length * frameSize;
	return [self copyBytes: [fromBuffer bytes] intoRange: rangeInBytes format: format];
    }
    return nil;
#endif
}

- (void) fillSNDStreamBuffer: (SNDStreamBuffer *) streamBuffer
{
    long streamDataSizeInBytes = SndFramesToBytes(streamBuffer->frameCount, streamBuffer->channelCount, streamBuffer->dataFormat);
    
#if 0
    if(streamBuffer->interleaved == NO) {
	// Not interleaved, we need to convert from self (which is always interleaved) to non-interleaved streamData
	// using SndConvert functions/methods.
    }
#endif
    // NSLog(@"copying %d bytes to output buffer\n", streamDataSizeInBytes);
    memcpy(streamBuffer->streamData, [self bytes], streamDataSizeInBytes);
}


////////////////////////////////////////////////////////////////////////////////
// frameSizeInBytes
////////////////////////////////////////////////////////////////////////////////

- (int) frameSizeInBytes
{
    return SndFrameSize(format);
}

////////////////////////////////////////////////////////////////////////////////
// lengthInSampleFrames
////////////////////////////////////////////////////////////////////////////////

- (unsigned long) lengthInSampleFrames
{
    return format.frameCount;
}

////////////////////////////////////////////////////////////////////////////////
// setLengthInSampleFrames
////////////////////////////////////////////////////////////////////////////////

- setLengthInSampleFrames: (unsigned long) newSampleFrameCount
{
    long frameSizeInBytes = [self frameSizeInBytes];
    unsigned long oldLengthInBytes = SndDataSize(format);
    unsigned long newLengthInBytes = frameSizeInBytes * newSampleFrameCount;

    if (format.frameCount < newSampleFrameCount) { // enlarge the data if setting longer
        [data setLength: newLengthInBytes];
        if (oldLengthInBytes < newLengthInBytes) {
            NSRange r = {oldLengthInBytes, newLengthInBytes - oldLengthInBytes};
            [data resetBytesInRange: r];
        }
    }
    format.frameCount = newSampleFrameCount;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// lengthInBytes
////////////////////////////////////////////////////////////////////////////////

- (long) lengthInBytes
{
    return SndDataSize(format);
}

- (void) findMin: (float *) pMin 
	      at: (unsigned long *) minLocation 
	     max: (float *) pMax 
	      at: (unsigned long *) maxLocation
{
    unsigned long samplesInBuffer = [self lengthInSampleFrames] * format.channelCount;
    
#if defined(__APPLE_CC__)  // || (__i386__ && __GNUC__)
    // vector implementation
    switch(format.dataFormat) {
	case SND_FORMAT_FLOAT: {
	    const vFloat *samplePtr = (vFloat *) [data bytes];
	    int32_t maxIndex = vIsmax(samplesInBuffer, samplePtr);
	    int32_t minIndex = vIsmin(samplesInBuffer, samplePtr);
	    
	    *pMax = ((float *) samplePtr)[maxIndex];
	    *maxLocation = (unsigned long) maxIndex;
	    *pMin = ((float *) samplePtr)[minIndex];    
	    *minLocation = (unsigned long) minIndex;
	    break;
	// case SND_FORMAT_LINEAR_16:
        // break;
	default:
	    NSLog(@"findMin:at:max:at: unsupported format %d\n", format.dataFormat);
	}
    }
#else
#warning Vector units not available, using scalar max/min finding.
    unsigned long sampleIndex;
    const void *samplePtr = [data bytes];
    *pMin = 0.0;
    *pMax = 0.0;

    // Check all channels
    for (sampleIndex = 0; sampleIndex < samplesInBuffer; sampleIndex++) {
	float sample = 0.0;

	switch(format.dataFormat) {
	case SND_FORMAT_FLOAT:
	    sample = ((float *) samplePtr)[sampleIndex];
	    break;
	case SND_FORMAT_LINEAR_16:
	    sample = ((short *) samplePtr)[sampleIndex];
	    break;
	default:
	    NSLog(@"findMin:max: unsupported format %d\n", format.dataFormat);
	}
	
	if (sample < *pMin) {
	    *pMin = sample;
	    *minLocation = sampleIndex;
	}
	else if (sample > *pMax) {
	    *pMax = sample;
	    *maxLocation = sampleIndex;
	}
    }
#endif
}

- (void) findMin: (float *) pMin max: (float *) pMax
{
    unsigned long minLocation, maxLocation;
    
    [self findMin: pMin at: &minLocation max: pMax at: &maxLocation];
}

- (float) findMaximumMagnitudeAt: (unsigned long *) sampleIndex
{
    float minAmp, maxAmp;
    unsigned long minLocation, maxLocation;
    float absMinAmp, absMaxAmp;
    
    [self findMin: &minAmp at: &minLocation max: &maxAmp at: &maxLocation];
    absMinAmp = fabs(minAmp);
    absMaxAmp = fabs(maxAmp);
    if(absMinAmp > absMaxAmp) {
	if(sampleIndex)
	    *sampleIndex = minLocation;
	return absMinAmp;
    }
    else {
	if(sampleIndex)
	    *sampleIndex = maxLocation;
	return absMaxAmp;
    }
}

- (float) findMaximumMagnitudeAt: (unsigned long *) frameIndex channel: (unsigned int *) channel
{
    unsigned long sampleIndex;
    float maximumMagnitude = [self findMaximumMagnitudeAt: &sampleIndex];
    
    *frameIndex = sampleIndex / [self channelCount];
    *channel = sampleIndex % [self channelCount];
    return maximumMagnitude;
}

// Return an array of RMS values, for the number of channels.
- (void) amplitudeRMSOfChannels: (float *) rmsAmpPerChannel
{
    unsigned long framesInBuffer = [self lengthInSampleFrames];
    const float *samplePtr = (const float *) [data bytes];
    unsigned int channelIndex;
    
#if defined(__APPLE_CC__)  // || (__i386__ && __GNUC__)
    // vector implementation
    for (channelIndex = 0; channelIndex < format.channelCount; channelIndex++) {
	float sumOfSquares = 0.0;

	vDSP_dotpr(samplePtr + channelIndex, format.channelCount, samplePtr + channelIndex, format.channelCount, &sumOfSquares, framesInBuffer);
	rmsAmpPerChannel[channelIndex] = sqrt(sumOfSquares / framesInBuffer);
	// NSLog(@"rmsAmpPerChannel = %p channelIndex = %d\n", rmsAmpPerChannel, channelIndex);
    }
#else
    for (channelIndex = 0; channelIndex < format.channelCount; channelIndex++) {
	unsigned frameIndex;
        float sumOfSquares = 0.0;

	for (frameIndex = 0; frameIndex < framesInBuffer; frameIndex++) {
	    sumOfSquares += samplePtr[frameIndex] * samplePtr[frameIndex]; // Multiply and add.
	}
	rmsAmpPerChannel[channelIndex] = sqrt(sumOfSquares / framesInBuffer);
    }
#endif
}

- (double) maximumAmplitude
{
    return SndMaximumAmplitude([self dataFormat]);
}

- (void) scaleBy: (float) scaleFactor
{
    unsigned long samplesInBuffer = [self lengthInSampleFrames] * format.channelCount;

//#ifndef __APPLE_CC__
#if 1
   // Scalar implementation
    switch(format.dataFormat) {
	case SND_FORMAT_FLOAT: {
	    unsigned long sampleIndex;
	    float *samplePtr = (float *) [data bytes];
	    
	    // Check all channels
	    for (sampleIndex = 0; sampleIndex < samplesInBuffer; sampleIndex++) {	    
		samplePtr[sampleIndex] *= scaleFactor;
	    }
	    break;
	}
	default:
	    NSLog(@"Attempt to normalise unsupported format %d\n", format.dataFormat);
    }
 #else
    // Altivec implementation
    switch(format.dataFormat) {
	case SND_FORMAT_FLOAT: {
	    
	}
	default:
	    NSLog(@"normalise unsupported format %d\n", format.dataFormat);
    }
#endif
}

- (void) normalise
{
    float minSample, maxSample, maximumExcursion;

    [self findMin: &minSample max: &maxSample];
    maximumExcursion = MAX(fabs(maxSample), fabs(minSample));
    
    [self scaleBy: 1.0 / maximumExcursion];
}

// retrieve a sound value at the given frame, for a specified channel, or average over all channels.
// channelNumber is 0 - channelCount to retrieve a single channel, channelCount to average all channels
- (float) sampleAtFrameIndex: (unsigned long) frameIndex channel: (int) channelNumber
{
    float theSampleValue = 0.0;
    int averageOverChannels;
    int startingChannel;
    unsigned long sampleIndex;
    unsigned long sampleNumber;
    const void *pcmData = [data bytes];
    
    if(frameIndex >= [self lengthInSampleFrames]) {
	NSLog(@"SndAudioBuffer sampleAtFrameIndex:channel: frameIndex %ld out of range [0,%ld]\n", frameIndex, [self lengthInSampleFrames]);
	return 0.0;
    }
    if(channelNumber < 0 || channelNumber > format.channelCount) {
	NSLog(@"SndAudioBuffer sampleAtFrameIndex:channel: channel %d out of range [0,%d]\n", channelNumber, format.channelCount);
	return 0.0;
    }
    
    if (channelNumber == format.channelCount) {
	averageOverChannels = format.channelCount;
	startingChannel = 0;
    }
    else {
	averageOverChannels = 1;
	startingChannel = channelNumber;
    }
    // 
    sampleNumber = frameIndex * format.channelCount + startingChannel;
    
    for(sampleIndex = sampleNumber; sampleIndex < sampleNumber + averageOverChannels; sampleIndex++) {
	switch (format.dataFormat) {
	    case SND_FORMAT_LINEAR_8:
		theSampleValue += ((char *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_MULAW_8:
		theSampleValue += SndMuLawToLinear(((char *) pcmData)[sampleIndex]);
		break;
	    case SND_FORMAT_EMPHASIZED:
	    case SND_FORMAT_COMPRESSED:
	    case SND_FORMAT_COMPRESSED_EMPHASIZED:
	    case SND_FORMAT_DSP_DATA_16:
	    case SND_FORMAT_LINEAR_16:
		theSampleValue += ((short *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_LINEAR_24:
	    case SND_FORMAT_DSP_DATA_24:
		// theSampleValue = ((short *) pcmData)[frameIndex];
		// TODO: this makes assumptions about the endian order and size of an int.
		theSampleValue += *((int *) ((char *) pcmData + sampleIndex * 3)) >> 8;
		break;
	    case SND_FORMAT_LINEAR_32:
	    case SND_FORMAT_DSP_DATA_32:
		theSampleValue += ((int *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_FLOAT:
		theSampleValue += ((float *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_DOUBLE:
		theSampleValue += ((double *) pcmData)[sampleIndex];
		break;
	    default: /* just in case */
		theSampleValue += ((short *) pcmData)[sampleIndex];
		NSLog(@"SndAudioBuffer sampleAtFrameIndex:channel: unhandled format %d\n", format.dataFormat);
		break;
	}	
    }
    return (averageOverChannels > 1) ? theSampleValue / averageOverChannels : theSampleValue;
}

- (BOOL) setSample: (float) sampleValue atFrameIndex: (unsigned long) frameIndex channel: (int) channelNumber
{
    unsigned long sampleIndex = frameIndex * format.channelCount + channelNumber;
    const void *pcmData = [data mutableBytes];
    
    if(frameIndex >= [self lengthInSampleFrames]) {
	NSLog(@"SndAudioBuffer -setSample:atFrameIndex:channel: frameIndex %ld out of range [0,%ld]\n", frameIndex, [self lengthInSampleFrames]);
	return NO;
    }
    if(channelNumber < 0 || channelNumber > format.channelCount) {
	NSLog(@"SndAudioBuffer -setSample:atFrameIndex:channel: channel %d out of range [0,%d]\n", channelNumber, format.channelCount);
	return NO;
    }
    
    switch (format.dataFormat) {
	case SND_FORMAT_LINEAR_8:
	    ((unsigned char *) pcmData)[sampleIndex] = (unsigned char) (sampleValue * SndMaximumAmplitude(format.dataFormat));
	    break;
	case SND_FORMAT_MULAW_8:
	    ((unsigned char *) pcmData)[sampleIndex] = SndLinearToMuLaw(sampleValue * SndMaximumAmplitude(SND_FORMAT_LINEAR_16));
	    break;
	case SND_FORMAT_EMPHASIZED:
	case SND_FORMAT_COMPRESSED:
	case SND_FORMAT_COMPRESSED_EMPHASIZED:
	case SND_FORMAT_DSP_DATA_16:
	case SND_FORMAT_LINEAR_16:
	    ((short *) pcmData)[sampleIndex] = (short) (sampleValue * SndMaximumAmplitude(format.dataFormat));
	    break;
	case SND_FORMAT_LINEAR_24:
	case SND_FORMAT_DSP_DATA_24: {
		int intRepresentationOfSample = (sampleValue * SndMaximumAmplitude(format.dataFormat));
		// TODO: shift up to the top of the integer, assuming the first byte is the msb. This is problematic for little-endians
		int alignedSample = intRepresentationOfSample << 8;
		memcpy((unsigned char *) pcmData + sampleIndex * 3, (unsigned char *) &alignedSample, 3);
	    }
	    break;
	case SND_FORMAT_LINEAR_32:
	case SND_FORMAT_DSP_DATA_32:
	    ((int *) pcmData)[sampleIndex] = (int) (sampleValue * SndMaximumAmplitude(format.dataFormat));
	    break;
	case SND_FORMAT_FLOAT:
	    ((float *) pcmData)[sampleIndex] = sampleValue;
	    break;
	case SND_FORMAT_DOUBLE:
	    ((double *) pcmData)[sampleIndex] = sampleValue;
	    break;
	default: /* just in case */
	    ((short *) pcmData)[sampleIndex] = (short) (sampleValue * SndMaximumAmplitude(format.dataFormat));
	    NSLog(@"SndAudioBuffer -setSample:atFrameIndex:channel: unhandled format %d\n", format.dataFormat);
	    break;
    }
    return YES;
}

@end
