////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
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

#ifndef __SNDAUDIOBUFFERQUEUE_H__
#define __SNDAUDIOBUFFERQUEUE_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;

/*!
  @enum SndAudioBufferQueueType
  @constant audioBufferQueue_typeInput  
  @constant audioBufferQueue_typeOutput  
*/
typedef enum {
  audioBufferQueue_typeInput,
  audioBufferQueue_typeOutput
} SndAudioBufferQueueType;

/*!
  @class SndAudioBufferQueue
  @brief Abstraction of the producer / consumer buffer queue operation found inside
    the SndStreamClients, which have both an input and output SndAudioBufferQueue.
    Provides thread safe buffer exchange and blocking operations.
*/
@interface SndAudioBufferQueue : NSObject 
{
    /*! Array of buffers pending processing (to be consumed) */
    NSMutableArray  *pendingBuffers;
    /*! Array of processed buffers (post consumption) */
    NSMutableArray  *processedBuffers;
    /*! Lock for thread safety around pending buffers array */
    NSConditionLock *pendingBuffersLock;
    /*! Lock for thread safety around processed buffers array */
    NSConditionLock *processedBuffersLock;
    /*! Total number of buffers in the queue, both pending and processed */
    NSUInteger numBuffers;
    /*! Maximum number of buffers ever stored in pending queue */
    NSUInteger maximumPendingBuffers;
    /*! Maximum number of buffers ever stored in process queue */
    NSUInteger maximumProcessedBuffers;
}

/*!
  @brief   Factory method.
  @param   numberOfBuffers Buffer queue length.
  
  Creates a fresh new SndAudioBufferQueue, sets the eventual number of buffers to <em>numberOfBuffers</em>.
  @return     An autoreleased SndAudioBufferQueue instance.
*/
+ (instancetype)audioBufferQueueWithLength: (NSInteger) numberOfBuffers;

- (instancetype)init;

/*!
  @brief   Initializes queue for operation with a total of pending+processed buffers.
  
  Since we add and pop buffers in separate methods, if we try to add before popping, we will
	  need to use one less than the full number of buffers initialized with, such that we never
	  exceed the maximum. For example, if we initialize with 4 buffers, at best we can hold only
  3 processed buffers so we can add a pending buffer, before then popping a processed buffer.
  @param      numberOfBuffers Number of buffers.
  @return     Returns self.
*/
- (instancetype)initQueueWithLength: (NSInteger) numberOfBuffers;

/*!
  @brief Returns the next buffer that is yet to be processed.
  
  In contexts where the queue is used for input and output processing, the returned buffer can be interpreted as: 
  <UL>
  <LI><b>output</b> - The next buffer to be synthesized / produced</li>
  <LI><b>input</b>  - The next input buffer to be processed</li>
  </UL>
 
  Blocks the calling thread until a buffer is present for popping.
  @return     Returns an autoreleased SndAudioBuffer instance.
*/
- (SndAudioBuffer*) popNextPendingBuffer;

/*!
  @brief Returns the next buffer that has already been processed.
 
  In contexts where the queue is used for input and output processing, the returned buffer can be interpreted as: 
    <UL>
    <LI><b>output</b> - The next buffer to be consumed by the world at large</li>
    <LI><b>input</b>  - The next buffer to be filled with input material</li>
    </UL>
 
  Blocks the calling thread until a buffer is present for popping.
  @return     Returns an autoreleased SndAudioBuffer instance.
 */
- (SndAudioBuffer*) popNextProcessedBuffer;

/*!
  @brief Adds buffer to the pending queue.
  @param audioBuffer Buffer to be added
*/
- (void)addPendingBuffer: (SndAudioBuffer*) audioBuffer;

/*!
  @brief Adds a buffer to the processed queue.
  @param audioBuffer Buffer to be added
*/
- (void)addProcessedBuffer: (SndAudioBuffer*) audioBuffer;

/*!
  @brief Moves all processed buffers onto the pending queue.
 */
- (void) cancelProcessedBuffers;

/*!
  @return Number of buffers in the pending queue
*/
- (NSInteger) pendingBuffersCount;

/*!
  @return Number of buffers in the processed queue
*/
- (NSInteger) processedBuffersCount;

/*!
  @brief   Frees the SndAudioBuffers within the queues.
*/
- (void)freeBuffers;

/*!
  @brief   Primes the SndAudioBufferQueue for streaming
  @param      type Either audioBufferQueue_typeInput or audioBufferQueue_typeOutput
  @param      buff The format of the SndAudioBuffer <em>buff</em> will be used as a template 
  for the internal queued buffers. 
  
  If prepared as an input queue, the buffers are initially placed in the processed queue; 
  otherwise the fresh buffers are placed in the pending queue. The former ensures that
  any input buffer consumers do not get empty buffers, and the latter allows buffer
  producers (eg synthesizers) to process several buffers ahead, giving them some processing
  head room in a multi-threaded environment.
  @return     Returns self.
*/
- (BOOL) prepareQueueAsType: (SndAudioBufferQueueType) type withBufferPrototype: (SndAudioBuffer*) buff;

/*!
  @brief Returns the total number of buffers being shuffled about betwixt pending and processed queues.
  @return Number of buffers in queues
*/
- (NSInteger) bufferCount;

@end

#endif
