/*
  $Id$
  Description:
    This is basically a bare-bones duplicate of NeXT/Apples' performsound module
    functionality. Compilable with VC++ 6.0 and typically for interface with 
    Objective C routines, in particular, the SndKit.

    Only C functions are exported to avoid different C++ name mangling between VC++ and gcc

  Original Author: Leigh Smith <leigh@tomandandy.com>

  Copyright (C) 1999 Permission is granted to use this code for commercial and
  non-commercial purposes so long as this copyright statement (noting the author) is
  preserved.
*/
/*
  $Log$
  Revision 1.2  2001/09/03 15:02:53  sbrandon
  - added headerdoc comments from MKPerformSndMIDI_MACOSX project
  - added SNDSetBufferSizeInBytes method

  Revision 1.1  2001/07/02 22:03:48  sbrandon
  - initial revision. Still a work in progress, but does allow the MusicKit
    and SndKit to compile on GNUstep.

  Revision 1.2  2001/05/12 08:51:48  sbrandon
  - various header importing changes
  - added some gsdoc comments from the MacOSX framework
  - added SNDStream function declarations from the MacOSX framework

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version

  Revision 1.2  1999/07/21 19:19:42  leigh
  Single Sound playback working
*/

#ifndef __PERFORMSOUND__
#define __PERFORMSOUND__

#define PERFORM_API 

// these don't seem to be defined anywhere standard - probably they
// are in GnuStep
//typedef int BOOL;
#ifndef FALSE
#define FALSE 0
#define TRUE !(FALSE)
#endif
#include <objc/objc.h>

#include <stdlib.h> // for NULL definition
#include "SndStruct.h"
#include "SndFormats.h"

#ifdef __cplusplus
extern "C" {
#endif 

/*!
    @typedef SNDNotificationFun
    @param s
    @param tag
    @param err
    @result
*/
typedef int (*SNDNotificationFun)(SndSoundStruct *s, int tag, int err);

/*!
    @typedef SNDStreamBuffer
    @abstract Describes the format and the data in a limited length buffer used operating a stream.
    @field streamFormat The format describing sample rate, number of channels etc. The field offset
                        is not used since the streamData pointer can be used to refer to non-contiguous
                        data.
    @field streamData A pointer to the data itself. 
*/
typedef struct SNDStreamBuffer {
    SndSoundStruct streamFormat;
    void *streamData;
} SNDStreamBuffer;

/*!
    @typedef SNDStreamProcessor
    @discussion The descriptors "in" and "out" are with respect to the audio hardware, i.e out == play
    @param sampleTime
    @param inStream
    @param outStream
    @param userData
*/
typedef void (*SNDStreamProcessor)(double sampleTime, SNDStreamBuffer *inStream, SNDStreamBuffer *outStream, void *userData);

/*!
    @defined SND_NULL_FUN
    @discussion Indicates no function is to be called.
*/
#define SND_NULL_FUN ((SNDNotificationFun)0)

/*!
    @function       SNDInit
    @abstract       Initialise the Sound hardware.
    @param          guessTheDevice
                        Indicates whether to guess the device to select using the system default.
    @discussion     The <tt>guessTheDevice</tt> parameter allows hard coding devices or using heuristics
                    to prevent the user having to always select the best device to use.
                    Whether guessing or not, a driver is still initialised.
    @result         Returns a YES if initialised correctly, NO if unable to initialise the device,
                    such as an unavailable sound interface.
*/
PERFORM_API BOOL SNDInit(BOOL guessTheDevice);

/*!
    @function       SNDGetAvailableDriverNames
    @abstract       Retrieve a list of available driver descriptions.
    @result         Returns a NULL terminated array of readable strings of each driver's name.
*/
PERFORM_API char **SNDGetAvailableDriverNames(void);

/*!
    @function       SNDSetDriverIndex
    @abstract       Assign currently active driver.
    @param          selectedIndex
                        The 0 base index into the driver table returned by SNDGetAvailableDriverNames
    @result         Returns YES if able to set the index, no if unable (for example selectedIndex out of bounds).
*/
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex);

/*!
    @function       SNDGetAssignedDriverIndex
    @abstract       Return the index into driverList currently selected.
    @result         Returns the index (0 base).
*/
PERFORM_API unsigned int SNDGetAssignedDriverIndex(void);

/*!
    @function       SNDGetVolume
    @abstract       Retrieve the current volume.
    @param          left
                        Receives the current left volume value (what units?).
    @param          right
                        Receives the current right volume value (what units?).
*/
PERFORM_API void SNDGetVolume(float *left, float * right);

/*!
    @function       SNDSetVolume
    @abstract       Sets the current volume.
    @param          left
                        Sets the current left volume value (what units?).
    @param          right
                        Sets the current right volume value (what units?).
    @result         Returns a readable string.
*/
PERFORM_API void SNDSetVolume(float left, float right);

/*!
    @function       SNDIsMuted
    @abstract       Determine if the currently playing sound is muted.
    @result         Returns YES if the currently playing sound is muted.
*/
PERFORM_API BOOL SNDIsMuted(void);

/*!
    @function       SNDSetMute
    @abstract       Mute or unmute the currently playing sound..
    @param          aFlag
                        YES to mute, NO to unmute.
*/
PERFORM_API void SNDSetMute(BOOL aFlag);

/*!
    @function       SNDSetBufferSizeInBytes
    @abstract       Mute or unmute the currently playing sound..
    @param          liBufferSizeInBytes
                        number of bytes in buffer. Note that current implementation
                        uses stereo float output buffers, which therefore take 8 bytes
                        per sample frame.
*/
PERFORM_API BOOL SNDSetBufferSizeInBytes(long liBufferSizeInBytes);

/*!
    @function       SNDStartPlaying
    @abstract       .
    @discussion	    This function need not be implemented if sound streaming is supported.
    @param          soundStruct
                        .
    @param          tag
    @param          priority
    @param          preempt
    @param          beginFun
    @param          endFun
    @result         Returns .
*/
PERFORM_API int SNDStartPlaying(SndSoundStruct *soundStruct, int tag, int priority,  int preempt,
  SNDNotificationFun beginFun, SNDNotificationFun endFun);

/*!
    @function       SNDStartRecording
    @abstract       .
    @discussion	    This function need not be implemented if sound streaming is supported.
    @param          soundStruct
                        .
    @param          tag
    @param          priority
    @param          preempt
    @param          beginRecFun
    @param          endRecFun
    @result         Returns .
*/
PERFORM_API int SNDStartRecording(SndSoundStruct *soundStruct, int tag, int priority, int preempt,
  SNDNotificationFun beginRecFun, SNDNotificationFun endRecFun);
 
/*!
    @function       SNDSamplesProcessed
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to inspect.
    @result         Returns the number of samples processed.
*/
PERFORM_API int SNDSamplesProcessed(int tag);

/*!
    @function       SNDStop
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to stop.
*/
PERFORM_API void SNDStop(int tag);

/*!
    @function       SNDPause
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to pause.
*/
PERFORM_API void SNDPause(int tag);

/*!
    @function       SNDResume
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to resume.
*/
PERFORM_API void SNDResume(int tag);

/*!
    @function       SNDUnreserve
    @abstract       .
    @param          dunno
                        .
    @result         Returns a .
*/
PERFORM_API int SNDUnreserve(int dunno);

/*!
    @function       SNDTerminate
    @abstract       .
*/
PERFORM_API void SNDTerminate(void);

/*!
    @function       SNDStreamNativeFormat
    @abstract       Return in the struct the format of the sound data preferred by the operating system.
    @param          streamFormat
                        pointer to an allocated block of memory into which to put the SndSoundStruct
*/
PERFORM_API void SNDStreamNativeFormat(SndSoundStruct *streamFormat);

/*!
    @function       SNDStreamStart
    @abstract       .
    @param          newStreamProcessor
                        .
    @param          userData
                        
    @result         Returns YES if ?, NO if ?.
*/
PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *userData);

/*!
    @function       SNDStreamStop 
    @abstract       .
    @result         Returns YES if ?, NO if ?.
*/
PERFORM_API BOOL SNDStreamStop(void);


#ifdef __cplusplus
}
#endif

#endif
