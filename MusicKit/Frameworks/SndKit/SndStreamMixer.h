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

#ifndef __SND_STREAM_MIXER_H__
#define __SND_STREAM_MIXER_H__

#import <Foundation/Foundation.h>

#import <SndKit/SndAudioBuffer.h>
#import <SndKit/SndStreamClient.h>
#import <SndKit/SndAudioProcessorChain.h>

/*!
  @class SndStreamMixer
  @brief Stream mixer and effects processor

  The SndStreamMixer class is responsible for managing the mixing of SndAudioBuffers from all
  current SndStreamClients. After mixing all buffers, it can apply any signal processing to the mixed
  result by modifying it's SndAudioProcessorChain retrieved using audioProcessorChain.
*/
@interface SndStreamMixer : NSObject
{
    /*! A modifiable array of SndStreamClients currently being mixed. */
    NSMutableArray *streamClients;
    /*! Controls access to the clients preventing their addition or removal while being mixed. */
    NSRecursiveLock *streamClientsLock;
    /*! A chain of SndAudioProcessors that is applied after mixing all the stream clients together. */
    SndAudioProcessorChain *processorChain;
    /*! The current time (in seconds) to mix up to, as updated from the SndStreamManager, passed into processInBuffer:outBuffer:nowTime. */
    double nowTime;
    /*! The previous time of last update from SndStreamManager. */
    double lastNowTime;
}

/*!
  @brief   Factory method returning an initialized and autoreleased SndStreamMixer instance.
  @return     Returns an initialized and autoreleased SndStreamMixer instance.
*/
+ (instancetype)mixer;

/*!
  @brief   Initializer method.
  @return     Returns self.
*/
- (instancetype)init;

/*!
  @brief   Mixes together all clients currently exposed output buffers.
  
  After mixing all client exposed output buffers, processInBuffer:outBuffer:nowTime
  then applies any audio processing to the mix. Each client then receives the message
  startProcessingNextBufferWithInput:nowTime:, passing the input buffer, to generate
  the next buffer.
  @param      inB The input buffer filled with recorded audio.
  @param      outB The output buffer to fill for playback.
  @param      t The current now time.
  @return     Returns self.
*/
- (void)processInBuffer: (SndAudioBuffer *) inB
        outBuffer: (SndAudioBuffer *) outB
          nowTime: (double) t;

/*!
  @brief   Removes the given SndStreamClient from mixing.
  @param      client The SndStreamClient instance to remove.
  @return     Returns YES if client was successfully removed, NO if it was not being mixed.
*/
- (BOOL) removeClient: (SndStreamClient *) client;

/*!
  @brief   Add a SndStreamClient to the mix.
  
  If the client is already being mixed, it will not be added again.
  @param      client A SndStreamClient instance.
  @return     Returns the new number of clients.
*/
- (int) addClient: (SndStreamClient *) client;

/*!
  @brief Returns an NSArray of clients of the SndStreamMixer instance.
  @return Return the clients in an immutable autoreleased array.
 */
- (NSArray *) clients;

/*!
  @brief Informs the receiver that all mixing is to be completed, that mixing clients and buffers are to be updated.
  
  This should be sent when the manager is shutting down.
*/
- (void) finishMixing;

/*!
  @brief   Returns the number of stream clients currently connected to the mixer.
  @return     Returns the number of stream clients currently connected to the mixer.
*/
- (NSInteger) countOfClients;

/*!
  @brief   Returns the SndAudioProcessorChain applied after mixing SndStreamClients.
  @return     Returns a reference to the audio processor chain.
*/
- (SndAudioProcessorChain *) audioProcessorChain;

@property (readonly, strong) SndAudioProcessorChain *audioProcessorChain;

/*!
  @brief   Resets the mixer's sense of time, and pro
  @param      originTimeInSeconds
*/
- (void) resetTime: (double) originTimeInSeconds;

/*!
  @brief   Returns a given SndStreamClient being mixed, indexed by a numeric identifier.
  @param      clientIndex
*/
- (SndStreamClient *) clientAtIndex: (int) clientIndex;

@end

////////////////////////////////////////////////////////////////////////////////

@interface SndStreamMixer (Deprecated)

/*!
  @brief   Returns the number of stream clients currently connected to the mixer.
  @return     Returns the number of stream clients currently connected to the mixer.
*/
- (int) clientCount NS_DEPRECATED_WITH_REPLACEMENT_MAC("-countOfClients", 10.0, 10.8);

@end

#endif
