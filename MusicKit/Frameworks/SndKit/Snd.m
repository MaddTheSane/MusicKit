////////////////////////////////////////////////////////////////////////////////
//
// $Id$
// 
// Description: Main class defining a sound object.
// 
// Original Author: Stephen Brandon
// 
// LEGAL:
// This framework and all source code supplied with it, except where specified,
// are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free
// to use the source code for any purpose, including commercial applications, as
// long as you reproduce this notice on all such software.
// 
// Software production is complex and we cannot warrant that the Software will be
// error free.  Further, we will not be liable to you if the Software is not fit
// for the purpose for which you acquired it, or of satisfactory quality. 
// 
// WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
// WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
// OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
// PARTIES RIGHTS.
// 
// If a court finds that we are liable for death or personal injury caused by our
// negligence our liability shall be unlimited.  
// 
// WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
// OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
// POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
// NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
// DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
// CONDITIONS OF THIS AGREEMENT.
// 
// Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.
// 
// Legal Statement Covering Additions by The MusicKit Project:
//
//    Permission is granted to use and modify this code for commercial and
//    non-commercial purposes so long as the author attribution and copyright
//    messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

/* HISTORY
 * ..is now contained in the cvs log.
 * pre cvs:
 * 20/6/99 sb: added check to -compactSamples to ensure sound needs it
 */

#ifndef GNUSTEP
#include <libc.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h> /* for memmove() */

#import "Snd.h"
#import "SndError.h"
#import "SndFunctions.h"
#import "SndTable.h"
#import "SndAudioBuffer.h"
#import "SndAudioProcessorChain.h"
#import "SndMuLaw.h"
#import <math.h> // Required for GNUstep. Should be unnecessary in later versions of GS.

#define AU_FORMAT_INT_LENGTH 4

@implementation Snd

+ soundNamed: (NSString *) aName
{
  return [[SndTable defaultSndTable] soundNamed: aName];
}

+ findSoundFor: (NSString *) aName
{
  return [[SndTable defaultSndTable] findSoundFor: aName];
}

+ addName: (NSString *) aname sound: (Snd *) aSnd
{
  return [[SndTable defaultSndTable] addName: aname sound:aSnd];
}

+ addName: (NSString *) aname fromSoundfile: (NSString *) filename
{
  return [[SndTable defaultSndTable] addName: aname fromSoundfile: filename];
}

+ addName: (NSString *) aname fromSection: (NSString *) sectionName
{
  return [[SndTable defaultSndTable] addName: aname fromSection: sectionName];
}

+ addName: (NSString *) aName fromBundle: (NSBundle *) aBundle
{
  return [[SndTable defaultSndTable] addName: aName fromBundle: aBundle];
}

+ (void) removeSoundForName: (NSString *) aname
{
    [[SndTable defaultSndTable] removeSoundForName: aname];
}

+ (void) removeAllSounds
{
    [[SndTable defaultSndTable] removeAllSounds];
}

- (id)initWithFormat: (SndSampleFormat) format
    channelCount: (int) channels
	  frames: (unsigned long) frames
    samplingRate: (float) samplingRate
{
    self = [super init];
    if (self != nil) {
	SndAudioBuffer *singleAudioBuffer;
	
	name = nil;
	conversionQuality = SndConversionQualityLow;
	delegate = nil;
	info = nil;
	currentError = 0;
	tag = 0;
	
	if (performancesArray == nil) {
	    performancesArray     = [[NSMutableArray alloc] init];
	    performancesArrayLock = [NSLock new];
	}
	else
	    [performancesArray removeAllObjects];
	
	editingLock = [[NSRecursiveLock alloc] init];
	
	// initialize loop points to legal values
	loopWhenPlaying = NO;
	loopStartIndex = 0;
	loopEndIndex = frames;
	
	// initialize the priming audio processor chain for playback.
	audioProcessorChain = nil;
	
	// Initialise with an array of a single SndAudioBuffer instance.
	if (soundBuffers)
	    soundBuffers = nil;
	singleAudioBuffer = [SndAudioBuffer audioBufferWithDataFormat: format
							 channelCount: channels
							 samplingRate: samplingRate
							   frameCount: frames];
	soundBuffers = [NSMutableArray arrayWithObject: singleAudioBuffer];
	soundFormat.dataFormat = format;
	soundFormat.sampleRate = samplingRate;
	soundFormat.channelCount = channels;
	soundFormat.frameCount = frames;
	// info = @""; // TODO, should we just leave it nil, rather than empty?
    }
    return self;
}

// The default modern version, generate a zero length floating point, stereo CD quality sound.
- init
{
    return [self initWithFormat: SndSampleFormatFloat channelCount: 2 frames: 0 samplingRate: 44100.0];
}

- initWithAudioBuffer: (SndAudioBuffer *) aBuffer
{
    Snd *newInstance = [self initWithFormat: [aBuffer dataFormat]
			       channelCount: [aBuffer channelCount]
				     frames: [aBuffer lengthInSampleFrames]
			       samplingRate: [aBuffer samplingRate]]; 
  
    memcpy([newInstance bytes], [aBuffer bytes], [aBuffer lengthInBytes]);  
    return newInstance;
}

- initFromSoundfile: (NSString *) filename
{
  self = [self init];
  if (self != nil) {
    if ([self readSoundfile: filename] != SND_ERR_NONE) {
      return nil;
    }
  }
  return self;
}

- initFromSoundURL: (NSURL *) url
{
  self = [self init];
  if (self != nil) {
      // TODO: this should actually read HTTP, FTP URLs also.
    if ([self readSoundfile: [url path]] != SND_ERR_NONE) {
      return nil;
    }
  }
  return self;
}

// Assumes all data is formatted as .au only.
- initWithData: (NSData *) soundData
{
    int magic;		// need to ensure this is 4 bytes long.
    unsigned char *soundDataBytes;
    int infoStringLength;
    char *infoUTF8String;
    // TODO: need to ensure these are all 4 bytes long.
    int dataLocation;
    int dataSize;
    int dataFormat;
    int sampleRate;   
    int channelCount;
    
    if(!(self = [self init]))
	return nil;
    
    [soundData getBytes: &magic range: NSMakeRange(0, AU_FORMAT_INT_LENGTH)]; /* first integer */
    magic = CFSwapInt32BigToHost(magic);
    
    if (magic != SND_MAGIC)     // Verify we do have a .au/.snd file.
	return nil;
    	
    [soundData getBytes: &dataLocation range: NSMakeRange(AU_FORMAT_INT_LENGTH * 1, AU_FORMAT_INT_LENGTH)]; /* second integer */
    dataLocation = CFSwapInt32BigToHost(dataLocation);
    [soundData getBytes: &dataSize range: NSMakeRange(AU_FORMAT_INT_LENGTH * 2, AU_FORMAT_INT_LENGTH)]; /* third integer */
    dataSize = CFSwapInt32BigToHost(dataSize);
    [soundData getBytes: &dataFormat range: NSMakeRange(AU_FORMAT_INT_LENGTH * 3, AU_FORMAT_INT_LENGTH)]; /* fourth integer */
    soundFormat.dataFormat = CFSwapInt32BigToHost(dataFormat);
    [soundData getBytes: &sampleRate range: NSMakeRange(AU_FORMAT_INT_LENGTH * 4, AU_FORMAT_INT_LENGTH)]; /* fifth integer */
    soundFormat.sampleRate = CFSwapInt32BigToHost(sampleRate);
    [soundData getBytes: &channelCount range: NSMakeRange(AU_FORMAT_INT_LENGTH * 5, AU_FORMAT_INT_LENGTH)]; /* sixth integer */
    soundFormat.channelCount = CFSwapInt32BigToHost(channelCount);
    soundFormat.frameCount = SndBytesToFrames(dataSize, channelCount, dataFormat);

    infoStringLength = dataLocation - (AU_FORMAT_INT_LENGTH * 6); // gap between the header and data location is the info string.
    if ((infoUTF8String = malloc(infoStringLength + 1)) == NULL) // + 1 for terminating \0.
	[[NSException exceptionWithName: @"Sound Error"
				 reason: @"Can't allocate memory for info string"
			       userInfo: nil] raise];
    [soundData getBytes: infoUTF8String range: NSMakeRange(AU_FORMAT_INT_LENGTH * 6, infoStringLength)];
    infoUTF8String[infoStringLength] = '\0'; // terminate the string
    self.info = [NSString stringWithUTF8String: infoUTF8String];
    free(infoUTF8String);
    
    if((soundDataBytes = malloc(dataSize)) == NULL) {
	[[NSException exceptionWithName: @"Sound Error"
				 reason: @"Can't allocate memory for Snd instance"
			       userInfo: nil] raise];
    }
    [soundData getBytes: soundDataBytes range: NSMakeRange(dataLocation, dataSize)];
    // TODO: define audioBufferWithFormat: data: (NSData *) and audioBufferWithFormat: bytes:
    soundBuffers = [NSMutableArray arrayWithObject: [SndAudioBuffer audioBufferWithFormat: &soundFormat data: soundDataBytes]];
    free(soundDataBytes);
    
    priority = 0;
    loopEndIndex = [self lengthInSampleFrames] - 1;
    return self;
}

- (NSUInteger) hash
{
    // take into account all basic metadata, including size, formate, rate, channels
    NSUInteger ss = soundFormat.sampleRate + soundFormat.dataFormat + soundFormat.channelCount + [info length];

    return [name length] * 256 + 512 * tag + ss + 1023 * [self lengthInSampleFrames];
}

- (void) dealloc
{
    if (name) {
        if ([[SndTable defaultSndTable] soundNamed: name] == self)
            [[SndTable defaultSndTable] removeSoundForName: name];
	name = nil;
    }
}

// for debugging
- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ (%@ %@ %@)", 
	[super description],
	name != nil ? name : @"(unnamed)",
	SndFormatDescription(soundFormat),
	info != nil ? info : @""];
}

- (NSString *) formatDescription
{
    return SndFormatName([self dataFormat], NO);
}

// TODO: at the moment we ignore the dataFormat, only writing AU format.
// Eventually we need to replace this with file writing routines.
- (NSData *) dataEncodedAsFormat: (NSString *) dataFormat
{
    NSMutableData *soundData; 
    unsigned int dataOffsetLocation = 6 * AU_FORMAT_INT_LENGTH;  // offset past the audio header, not including info.
    unsigned int sampleDataSize = [self dataSize];
    const char *UTF8Info = [info UTF8String];
    NSUInteger UTF8InfoLength = [info lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
    NSUInteger audioBufferIndex;

    // TODO: not sure this will work with indirect sounds.
    dataOffsetLocation += UTF8InfoLength;

    soundData = [NSMutableData dataWithCapacity: sampleDataSize]; 

    // Write header. We standardise to a big endian integer representation
    {
	int bigMagic = NSSwapHostIntToBig(SND_MAGIC);
	int bigDataLocation = NSSwapHostIntToBig(dataOffsetLocation);
	int bigDataSize = NSSwapHostIntToBig(sampleDataSize);
	int bigDataFormat = NSSwapHostIntToBig([self dataFormat]);
	int bigSamplingRate = NSSwapHostIntToBig((int) ([self samplingRate] + 0.5));
	int bigChannelCount = NSSwapHostIntToBig([self channelCount]);
	
	[soundData appendBytes: &bigMagic        length: sizeof(bigMagic)];
	[soundData appendBytes: &bigDataLocation length: sizeof(bigDataLocation)];
	[soundData appendBytes: &bigDataSize     length: sizeof(bigDataSize)];
	[soundData appendBytes: &bigDataFormat   length: sizeof(bigDataFormat)];
	[soundData appendBytes: &bigSamplingRate length: sizeof(bigSamplingRate)];
	[soundData appendBytes: &bigChannelCount length: sizeof(bigChannelCount)];
    }

    // append the info string
    // NSLog(@"writing info %@ length %d, UTF8 %s, length %d\n", info, [info length], UTF8Info, UTF8InfoLength);
    // Write UTF8 data out so foreign language info fields are properly transported.
    [soundData appendBytes: UTF8Info length: UTF8InfoLength];

    for(audioBufferIndex = 0; audioBufferIndex < [soundBuffers count]; audioBufferIndex++) {
	SndAudioBuffer *audioBuffer = [soundBuffers objectAtIndex: audioBufferIndex];
	
	[soundData appendBytes: [audioBuffer bytes] length: [audioBuffer lengthInBytes]];
    }
    return [NSData dataWithData: soundData];
}

- (void) swapHostToBigEndianFormat
{
    void *bytes = [self bytes];
    
    SndSwapHostToBigEndianSound(bytes, bytes, [self lengthInSampleFrames], [self channelCount], [self dataFormat]);
}

- (void) swapBigEndianToHostFormat
{
    void *bytes = [self bytes];
    
    SndSwapBigEndianSoundToHost(bytes, bytes, [self lengthInSampleFrames], [self channelCount], [self dataFormat]);
}

/* Archive data using keyed coding.
 */
- (void) encodeWithCoder: (NSCoder *) aCoder
{
    [aCoder encodeConditionalObject: delegate forKey: @"delegate"];
    [aCoder encodeObject: name forKey: @"Name"];
    [aCoder encodeObject: info forKey: @"Info"];
    [aCoder encodeInt: soundFormat.dataFormat forKey: @"DataFormat"];
    [aCoder encodeDouble: soundFormat.sampleRate  forKey: @"SampleRate"];
    [aCoder encodeInt: soundFormat.channelCount forKey: @"ChannelCount"];
    [aCoder encodeInteger: soundFormat.frameCount forKey: @"FrameCount"];
    [aCoder encodeObject: soundBuffers forKey: @"SoundBuffers"];

#if 0
    // no need to swap data in the header, because coders take care of endian issues for us.
    [aCoder encodeValuesOfObjCTypes: "iiiii", 0, [self dataSize],
     soundFormat.dataFormat, soundFormat.sampleRate, soundFormat.channelCount];
    // [aCoder encodeArrayOfObjCType: "s"count: [info lengthOfBytesUsingEncoding: NSUTF8StringEncoding] at: [info UTF8String]

    /* simple read/write of block of data */
    for(audioBufferIndex = 0; audioBufferIndex < [soundBuffers length]; audioBufferIndex++) {
	SndAudioBuffer *audioBuffer = [soundBuffers objectAtIndex: audioBufferIndex];
	    
	[aCoder encodeArrayOfObjCType: "s"
                                count: [audioBuffer lengthInBytes]
                                   at: [audioBuffer bytes]];
    }
#endif
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    if (!(self = [super init])) {
        return nil;
    }
    if ([aDecoder allowsKeyedCoding]) {
	[self setDelegate: [aDecoder decodeObjectForKey: @"delegate"]];
	[self setName: [aDecoder decodeObjectOfClass: [NSString class] forKey: @"Name"]];
	[self setInfo: [aDecoder decodeObjectOfClass: [NSString class] forKey: @"Info"]];
	soundFormat.dataFormat = [aDecoder decodeIntForKey: @"DataFormat"];
	soundFormat.sampleRate = [aDecoder decodeDoubleForKey: @"SampleRate"];
	soundFormat.channelCount = [aDecoder decodeIntForKey: @"ChannelCount"];
	soundFormat.frameCount = [aDecoder decodeIntegerForKey: @"FrameCount"];
	soundBuffers = [aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [SndAudioBuffer class], nil] forKey: @"SoundBuffers"];
    }
    else {
	int infoSize;
	int magic;
	int dataLocation;
	int dataSize;
	char *infoString;
	unsigned char *soundBytes;
	
	delegate = [aDecoder decodeObject];
	name = [aDecoder decodeObject];
	
	[aDecoder decodeValuesOfObjCTypes: "iiiiii", &magic, &dataLocation, &dataSize,
	    &(soundFormat.dataFormat), &(soundFormat.sampleRate), &(soundFormat.channelCount)];
	
	/* allocate enough room for info string */
	infoSize = dataLocation - (AU_FORMAT_INT_LENGTH * 6);
	if ((infoString = malloc(infoSize + 1)) == NULL)
	    [[NSException exceptionWithName: @"Sound Error"
				     reason: @"Can't allocate memory for Snd class"
				   userInfo: nil] raise];
	[aDecoder decodeArrayOfObjCType: "c" count: infoSize at: infoString];
	infoString[infoSize] = '\0'; // Ensure the string is terminated.
	info = [NSString stringWithUTF8String: infoString];
	free(infoString);
	
	/* allocate enough room for info string */
	if ((soundBytes = malloc(dataSize)) == NULL)
	    [[NSException exceptionWithName: @"Sound Error"
				     reason: @"Can't allocate memory for Snd class"
				   userInfo: nil] raise];
	
	[aDecoder decodeArrayOfObjCType: "c" count: dataSize at: soundBytes];
	soundBuffers = [NSMutableArray arrayWithObject: [SndAudioBuffer audioBufferWithFormat: &soundFormat data: soundBytes]];
	free(soundBytes);
    }
    return self;
}

- awakeAfterUsingCoder: (NSCoder *) aDecoder
{
    conversionQuality = SndConversionQualityLow;
    return self; /* what to do here??? Doesn't seem to be anything pressing... */
}

@synthesize name;

//- (NSString *) name
//{
//    return name;
//}
//
///* this needs to interface with an object-wide name table
// * to identify sounds by name. At the moment multiple sound
// * objects may share the same name, which is not right.
// * Second Thoughts: many sounds MAY share the same name, as
// * they do not have to register with the central name table.
// * The central name table though can only register one sound
// * with any unique name.
// */
//- (void)setName: (NSString *) theName
//{
//    if (name) {
//        [name release];
//        name = nil;
//    }
//    if (!theName) return;
//    if (![theName length]) return;
//    name = [theName copy];
//}

@synthesize delegate;

- (double) samplingRate
{
    return soundFormat.sampleRate;
}

- (unsigned long) lengthInSampleFrames
{
    return soundFormat.frameCount;
}

- (double) duration
{
    double sampleRate = (double) [self samplingRate];
    return (sampleRate == 0) ? 0.0 : (double) [self lengthInSampleFrames] / sampleRate;
}

- (int) channelCount
{
    return soundFormat.channelCount;
}

@synthesize info;

- (BOOL) isEmpty
{
    if (![self isEditable]) 
	return NO;
    if (![self dataSize]) 
	return YES;
    return NO;
}

- (BOOL) isEditable
{
    switch ([self dataFormat]) {
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

- (BOOL) compatibleWithSound: (Snd *) aSound
{
    SndSampleFormat df1 = [self dataFormat];
    SndSampleFormat df2 = [aSound dataFormat];
    BOOL formatsOk = ((df1 == df2) && df1 != SndSampleFormatIndirect);
    
    if (aSound == nil) 
	return YES;
    if ([self samplingRate] == [aSound samplingRate] &&
	[self channelCount] == [aSound channelCount] &&
	formatsOk)
	return YES;
    return NO;
}

- (SndError) convertToSampleFormat: (SndSampleFormat) toFormat
                      samplingRate: (double) toRate
                      channelCount: (int) toChannelCount
{
    NSUInteger soundBufferIndex;
    double stretchFactor = toRate / [self samplingRate];
    long totalFrameCount = 0;
    
    if([self dataFormat] == toFormat && [self samplingRate] == toRate && [self channelCount] == toChannelCount)
	return SND_ERR_NONE;

    for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count]; soundBufferIndex++) {
	SndAudioBuffer *bufferToConvert = [soundBuffers objectAtIndex: soundBufferIndex];
	SndAudioBuffer *error;

	/* SndConvertLowQuality: fastest conversion, non-interpolated */
	/* SndConvertMediumQuality: medium conversion, small filter, uses interpolation */
	/* SndConvertHighQuality: slow, accurate conversion, large filter, uses interpolation */
	error = [bufferToConvert convertToSampleFormat: toFormat
					  channelCount: toChannelCount
					  samplingRate: toRate
					useLargeFilter: conversionQuality == SndConversionQualityHigh
				     interpolateFilter: conversionQuality != SndConversionQualityLow
				useLinearInterpolation: conversionQuality == SndConversionQualityLow];
	totalFrameCount += [bufferToConvert lengthInSampleFrames];
	if (error == nil)
	    return SND_ERR_UNKNOWN;
    }
    soundFormat.dataFormat = toFormat;
    soundFormat.frameCount = totalFrameCount;
    soundFormat.sampleRate = toRate;
    soundFormat.channelCount = toChannelCount;
    loopStartIndex *= stretchFactor;  // adjust the loop pointers if the sound was resampled.
    loopEndIndex *= stretchFactor;
    return SND_ERR_NONE;
}

- (SndError) convertToSampleFormat: (SndSampleFormat) aFormat
{
    return [self convertToSampleFormat: aFormat
                    samplingRate: soundFormat.sampleRate
                    channelCount: soundFormat.channelCount];
}

+ (SndFormat) nativeFormatForOutput: (BOOL) forOutputDevices
{
    SNDStreamBuffer nativeStreamBufferFormat;
    
    SNDStreamNativeFormat(&nativeStreamBufferFormat, forOutputDevices);
    return SndFormatOfSNDStreamBuffer(&nativeStreamBufferFormat);    
}

+ (SndFormat) nativeFormat
{
    return [Snd nativeFormatForOutput: YES];  // check output only.
}

+ (SndFormat) nativeInputFormat
{
    return [Snd nativeFormatForOutput: NO];  // check input only.
}


- (SndError) convertToNativeFormat
{
    SndFormat nativeFormat = [Snd nativeFormat];

    return [self convertToSampleFormat: nativeFormat.dataFormat
                    samplingRate: nativeFormat.sampleRate
                    channelCount: nativeFormat.channelCount];
}

// TODO: Perhaps just use soundFromSampleInRange: specifying entire range and passing a NSZone parameter.
- (id) copyWithZone: (NSZone *) zone
{
    Snd *newSound = [[[self class] allocWithZone: zone] initWithFormat: [self dataFormat]
							  channelCount: [self channelCount]
								frames: [self lengthInSampleFrames]
							  samplingRate: [self samplingRate]];
    
    // TODO: verify deep copying behaviour.
    newSound->soundBuffers = [soundBuffers copyWithZone: zone];
    
    // Duplicate all other ivars
    newSound->soundFormat = soundFormat;
    [newSound setInfo: [self info]];
    
    newSound->priority = priority;		 
    [newSound setDelegate: [self delegate]];		 
    [newSound setName: [self name]];
    newSound->conversionQuality = conversionQuality;
        
    newSound->loopWhenPlaying = loopWhenPlaying;
    newSound->loopStartIndex = loopStartIndex;
    newSound->loopEndIndex = loopEndIndex;

    [newSound setAudioProcessorChain: [self audioProcessorChain]];
    
    return newSound; // Return a retained object per the NSObject spec.
}

- (void *) bytes
{
    SndAudioBuffer *firstBuffer = [soundBuffers objectAtIndex: 0];
    
    return [firstBuffer bytes];
}

- (long) dataSize
{
    return SndDataSize(soundFormat); 
}

- (SndSampleFormat) dataFormat
{
    return soundFormat.dataFormat;
}

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer *) buff
{
    if (buff == nil)
	return FALSE;
    else
	return ([self dataFormat]   == [buff dataFormat]  ) &&
	       ([self channelCount] == [buff channelCount]) &&
	       ([self samplingRate] == [buff samplingRate]);
}

@synthesize format=soundFormat;

// retrieve a sound value at the given frame, for a specified channel, or average over all channels.
// channelNumber is 0 - channelCount to retrieve a single channel, channelCount to average all channels
- (float) sampleAtFrameIndex: (unsigned long) frameIndex channel: (int) channelNumber
{
#if 0
    SndAudioBuffer *singleFrameBuffer = [self audioBuffer frameRange: NSMakeRange(frameIndex, 1) ];
    return [singleFrameBuffer sampleAtFrameIndex: frameIndex channel: channelNumber];
#else
    float theValue = 0.0;
    int channelCount = [self channelCount]; // TODO: can eventually replace channelCount with soundFormat.channelCount
    int averageOverChannels;
    int startingChannel;
    unsigned long sampleIndex;
    unsigned long sampleNumber;
    void *pcmData;
    unsigned long fragmentIndex;
    unsigned long fragmentLength;
    SndSampleFormat dataFormat;
    
    if (channelNumber == channelCount) {
	averageOverChannels = channelCount;
	startingChannel = 0;
    }
    else {
	averageOverChannels = 1;
	startingChannel = channelNumber;
    }
    // 
    pcmData = [self fragmentOfFrame: frameIndex 
		    indexInFragment: &fragmentIndex 
		     fragmentLength: &fragmentLength
			 dataFormat: &dataFormat];
    sampleNumber = fragmentIndex * channelCount + startingChannel;
    
    for(sampleIndex = sampleNumber; sampleIndex < sampleNumber + averageOverChannels; sampleIndex++) {
	// TODO: move this into a SndAudioBuffer method.
	switch (dataFormat) {
	    case SndSampleFormatLinear8:
		theValue += ((char *) pcmData)[sampleIndex];
		break;
	    case SndSampleFormatMulaw8:
		theValue += SndMuLawToLinear(((char *) pcmData)[sampleIndex]);
		break;
	    case SndSampleFormatEmphasized:
	    case SndSampleFormatCompressed:
	    case SndSampleFormatCompressedEmphasized:
	    case SndSampleFormatDspData16:
	    case SndSampleFormatLinear16:
		theValue += ((short *) pcmData)[sampleIndex];
		break;
	    case SndSampleFormatLinear24:
	    case SndSampleFormatDspData24:
		// theValue = ((short *) pcmData)[frameIndex];
		theValue += *((int *) ((char *) pcmData + sampleIndex * 3)) >> 8;
		break;
	    case SndSampleFormatLinear32:
	    case SndSampleFormatDspData32:
		theValue += ((int *) pcmData)[sampleIndex];
		break;
	    case SndSampleFormatFloat:
		theValue += ((float *) pcmData)[sampleIndex];
		break;
	    case SndSampleFormatDouble:
		theValue += ((double *) pcmData)[sampleIndex];
		break;
	    default: /* just in case */
		theValue += ((short *) pcmData)[sampleIndex];
		NSLog(@"SndView sampleAtFrameIndex: unhandled format %d\n", dataFormat);
		break;
	}	
    }
    return (averageOverChannels > 1) ? theValue / averageOverChannels : theValue;
#endif
}

- (SndError) processingError
{
    return currentError;
}

/* default implementation. Provided for subclassing */
- (Snd *) soundBeingProcessed
{
    return self;
}

// delegations which are not nominated per performance.
- (void) tellDelegate: (SEL) theMessage
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject:self];
        }
    }
}

// delegations which are nominated per performance.
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject: self withObject: performance];
        }
    }
}

// Convenience function for when using NSInvocations to send messages. NSInvocations don't like
// dealing with SEL types, so we use a NSString on the other end, and convert to SEL here.
- (void) tellDelegateString: (NSString *) theMessage duringPerformance: (SndPerformance *) performance
{
    [self tellDelegate: NSSelectorFromString(theMessage) duringPerformance: performance];
}

@synthesize conversionQuality;

- (void) normalise
{
    NSUInteger soundBufferIndex;
    float maximumExcursion = 0.0;

    // Determine the maximum excursion (+/-) across all fragment buffers.
    for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count]; soundBufferIndex++) {
	SndAudioBuffer *audioBufferOfSound = [soundBuffers objectAtIndex: soundBufferIndex];
	float maxSample, minSample;
	
	[audioBufferOfSound findMin: &minSample max: &maxSample];
	// NSLog(@"%@ max %f min %f\n", self, maxSample, minSample);

	maximumExcursion = MAX(maximumExcursion, MAX(fabs(maxSample), fabs(minSample)));
    }
    // Now scale all audio buffers.
    for(soundBufferIndex = 0; soundBufferIndex < [soundBuffers count]; soundBufferIndex++) {
	SndAudioBuffer *audioBufferOfSound = [soundBuffers objectAtIndex: soundBufferIndex];
	
	[audioBufferOfSound scaleBy: 1.0 / maximumExcursion];
    }
}

- (double) maximumAmplitude
{
    return SndMaximumAmplitude([self dataFormat]);
}

@end
