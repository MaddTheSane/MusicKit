////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Allpass filter implementation
//    Holds and filters a single audio channel.
//
//  Original Author: Written by Jezar at Dreampoint, June 2000
//    http://www.dreampoint.co.uk
//  Rewritten into Objective-C by Leigh M. Smith <leigh@leighsmith.com>
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

#import "SndReverbAllpassFilter.h"
#import "denormals.h"

@implementation SndReverbAllpassFilter

- initWithLength: (NSUInteger) size
{
    self = [super init];
    if (self != nil) {
	bufferIndex = 0;
	bufferSize = size;
	if ((buffer = (float *) malloc(size * sizeof(float))) == NULL) {
	    return nil;
	}
    }
    return self;
}

- (void) dealloc
{
    free(buffer);
}

- (void) mute
{
    int sampleIndex;

    for (sampleIndex = 0; sampleIndex < bufferSize; sampleIndex++)
	buffer[sampleIndex] = 0;
}

- (void) setFeedback: (float) val
{
    feedback = val;
}

- (float) feedback
{
    return feedback;
}

// This used to be inline for C++, for speed.
// For now we keep it dynamic, but we may need to statically call the method.
- (float) process: (float) input
{
    float output;
    float bufout;
    
    bufout = buffer[bufferIndex];
    undenormalise(bufout);
    
    output = -input + bufout;
    buffer[bufferIndex] = input + (bufout * feedback);
    
    if(++bufferIndex >= bufferSize) 
	bufferIndex = 0;
    
    return output;
}

// TODO: should incorporate process: inline into this method & use this method as interface.-
- (void) processBuffer: (float *) input
	     replacing: (float *) output
		length: (long) bufferLength
	      channels: (int) skip
{
    long i;
  
    for (i = 0; i < bufferLength; i += skip) 
	output[i] = [self process: input[i]];
}

@end
