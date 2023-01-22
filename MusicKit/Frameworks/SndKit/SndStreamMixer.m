////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndStreamMixer.h"
#import "SndAudioProcessor.h"

////////////////////////////////////////////////////////////////////////////////
// Debug defines
////////////////////////////////////////////////////////////////////////////////

#define SNDSTREAMMIXER_DEBUG 0
#define SNDSTREAMMIXER_DEBUG_PROCESSBUFFER 0

@implementation SndStreamMixer

////////////////////////////////////////////////////////////////////////////////
// mixer
////////////////////////////////////////////////////////////////////////////////

+ mixer
{
    return [[SndStreamMixer alloc] init];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super init];
    if(self) {
	if(streamClients == nil) 
	    streamClients = [[NSMutableArray alloc] initWithCapacity: 10];
      
	if(streamClientsLock == nil) 
	    streamClientsLock = [NSRecursiveLock new];
      
	if (processorChain == nil) 
	    processorChain = [SndAudioProcessorChain audioProcessorChain];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    NSInteger c = [self countOfClients];
    
    return [NSString stringWithFormat: @"%@ with %li client%s", [super description], (long)c, c > 1 ? "s" : ""];
}

////////////////////////////////////////////////////////////////////////////////
// processInBuffer:outBuffer:nowTime:
////////////////////////////////////////////////////////////////////////////////

- (void)processInBuffer: (SndAudioBuffer *) inB
        outBuffer: (SndAudioBuffer *) outB
          nowTime: (double) t
{
    int clientIndex;

    lastNowTime = nowTime;
    nowTime = t;
    [streamClientsLock lock];

#if SNDSTREAMMIXER_DEBUG_PROCESSBUFFER
    NSLog(@"[mixer] Entering processInBuffer at time: %f **********\n", nowTime);
#endif

    [outB zero];

    // We dynamically check the streamClients count, since it may alter when calling -startProcessingNextBufferWithInput:
    for (clientIndex = 0; clientIndex < [streamClients count]; clientIndex++) {
	SndStreamClient *client = [streamClients objectAtIndex: clientIndex];

	if ([client generatesOutput]) {
	    SndAudioBuffer *currentlyExposedOutputBuffer;
	    
	    // Look at each client's currently exposed output buffer, and add to mix.
	    [client lockOutputBuffer];
	    currentlyExposedOutputBuffer = [client outputBuffer];
#if SNDSTREAMMIXER_DEBUG
	    NSLog(@"[mixer] mixing buffer %@\n", currentlyExposedOutputBuffer);
#endif
	    if (currentlyExposedOutputBuffer != nil) {
#if SNDSTREAMMIXER_DEBUG
		long framesMixed = [outB mixWithBuffer: currentlyExposedOutputBuffer];
		
		NSLog(@"[mixer] Mixed %ld frames from mixing buffer %p\n", framesMixed, currentlyExposedOutputBuffer);
#else
		[outB mixWithBuffer: currentlyExposedOutputBuffer];
#endif
	    }
	    else {
		NSLog(@"[mixer] ERROR - tried to mix a nil output buffer!\n");
	    }
	    [client unlockOutputBuffer];
	}
	
	// NSLog(@"about to start processing next buffer for client %@\n", [client clientName]);
	// Each client should have a second synthing buffer, and a synth thread.
	[client startProcessingNextBufferWithInput: inB nowTime: nowTime];	
    }
    // Do any audio processing on the entire mix.
    [processorChain processBuffer: outB forTime: lastNowTime];

    [streamClientsLock unlock];

#if SNDSTREAMMIXER_DEBUG
    NSLog(@"[mixer] Leaving processInBuffer\n");
#endif
}

////////////////////////////////////////////////////////////////////////////////
// addClient:
//
// Returns false if the client is already registered, or the audio device 
// couldn't start streaming... true if all is well.
////////////////////////////////////////////////////////////////////////////////

- (int) addClient: (SndStreamClient *) client
{
    NSInteger  clientCount;
    BOOL clientPresent;    

    [streamClientsLock lock];
    
    clientPresent = [streamClients containsObject: client];
    if (!clientPresent) 
        [streamClients addObject: client];
    clientCount   = [streamClients count];

#if SNDSTREAMMIXER_DEBUG    
    NSLog(@"[mixer] -addClient: client added.");
#endif
    
    [streamClientsLock unlock];
    return clientCount;
}

////////////////////////////////////////////////////////////////////////////////
// removeClient:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) removeClient: (SndStreamClient *) client
{
    BOOL clientPresent = [streamClients containsObject: client];

    if (clientPresent) {
        [streamClientsLock lock];
        [streamClients removeObject: client];        
#if SNDSTREAMMIXER_DEBUG
        NSLog(@"[mixer] -removeClient: Removed client");
#endif
        [streamClientsLock unlock];
    }
    else
        NSLog(@"[mixer] -removeClient: Error: client was not present.");
    
    return clientPresent;
}

////////////////////////////////////////////////////////////////////////////////
// clientCount
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) countOfClients
{
    return [streamClients count];
}

- (NSArray *) clients
{
    return [NSArray arrayWithArray: streamClients];
}

////////////////////////////////////////////////////////////////////////////////
// finishMixing
////////////////////////////////////////////////////////////////////////////////

- (void) finishMixing
{
    [streamClientsLock lock];    // wait for current processBuffers to finish.
    if ([streamClients count] > 0)
	[streamClients makeObjectsPerformSelector: @selector(finishStreaming)];    
    [streamClientsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

@synthesize audioProcessorChain=processorChain;

////////////////////////////////////////////////////////////////////////////////
// resetTime:
////////////////////////////////////////////////////////////////////////////////

- (void) resetTime: (double) originTimeInSeconds
{
    NSInteger clientCount, clientIndex;
    
    [streamClientsLock lock];   
    clientCount = [streamClients count];
    if (clientCount > 0) {
        for (clientIndex = 0; clientIndex < clientCount; clientIndex++) {
            SndStreamClient *client = [streamClients objectAtIndex: clientIndex];
	    
            [client resetTime: originTimeInSeconds];
        }
    }
    [streamClientsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////
// clientAtIndex:
////////////////////////////////////////////////////////////////////////////////

- (SndStreamClient *) clientAtIndex: (int) clientIndex
{
    SndStreamClient *client;
    
    [streamClientsLock lock];
    client = [streamClients objectAtIndex: clientIndex];
    [streamClientsLock unlock];
    return client;
}

////////////////////////////////////////////////////////////////////////////////

@end

@implementation SndStreamMixer (Deprecated)

- (int) clientCount
{
    return (int)[self countOfClients];
}

@end
