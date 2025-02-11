/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2003 The MusicKit Project.
*/
/*
Modification history before CVS repository commital.

  02/25/90/daj - Changed to make instancable. Added sysexcl support.
  11/18/92/daj - Added evaluateTempo arg to beginWriting/reading
  04/02/99/lms - Made public header
*/
#ifndef MK__midifile_H___
#define MK__midifile_H___

#import <Foundation/Foundation.h>

/* The magic number appearing as the first 4 bytes of a MIDI file. */
#define MK_MIDIMAGIC  ((int)1297377380)  // "MThd"

/*
 * Only the two following metaevents are supported; data[0] contains one
 * of the following codes if the metaevent flag is set. The metaevents are
 * provided for reading. Separate functions exist to write metaevents.
 */

#define MKMIDI_DEFAULTQUANTASIZE (1000)

typedef NS_ENUM(int, MKMIDIMetaEvent) {
    /* In all of the metaevents, data[0] is the metaevent itself. */
    MKMIDI_sequenceNumber = 0,
    /*
     * data[1] and data[2] contain high and low order bits of number. 
     */
    MKMIDI_text = 1,
    MKMIDI_copyright = 2,
    MKMIDI_sequenceOrTrackName = 3,
    MKMIDI_instrumentName = 4,
    MKMIDI_lyric = 5,
    MKMIDI_marker = 6,
    MKMIDI_cuePoint = 7,
    /* data[1]* specifies null-terminated text. 
     */
    /*
     * MKMIDI_channelprefix, should be implemented by midifile.m and 
     * should not be passed up to user. 
     */
    MKMIDI_trackChange,
    /*
     * Track change metaevent: data[1] and data[2] contain high/low order bits,
     * respectively, containing the track number. These events can only be 
     * encountered when reading a level-1 file.
     */
    MKMIDI_tempoChange,
    /*
     * Tempo change metaevent: data[1:3] contain 3 bytes of data.
     */
    MKMIDI_smpteOffset,
    /*
      data[1:5] are the 5 numbers hr mn sec fr ff
      */
    MKMIDI_timeSig,
    /* data is a single int, where 1-byte fields are nn dd cc bb */
    MKMIDI_keySig
    /*  data is a single short, where 1-byte fields are sf mi  */
};
typedef enum MKMIDIMetaEvent MKMIDIMetaevent;

typedef struct _midiFileInStruct {
    double tempo;       /* in quarter notes per minute */
    double timeScale;   /* timeScale * currentTime gives time in seconds */
    int currentTrack;   /* Current track number */
    int currentTime;    /* Current time in quanta. */
    int currentOffset;	/* Added by dirk */
    int division;       /* # of delta-time ticks per quarter. (See spec) */
    short format;       /* Level 0, 1 or 2 */
    int quantaSize;     /* In micro-seconds. */
    unsigned char runningStatus; /* Current MIDI running status */
    NSData *midiStream; /* Midifile stream */
    int curBufSize;     /* Size of data buffer */
    /* Info for current msg. These are passed up to caller */
    int quanta;	        /* Time in quanta */
    BOOL metaeventFlag; /* YES if this is a meta-event */
    int nData;          /* Number of significant bytes in data */
    unsigned char *data;/* Data bytes */
    BOOL evaluateTempo;
    unsigned int streamPos; /*sb: used to keep track of position within stream, for reading and writing. */
} MKMIDIFileIn;

typedef struct _midiFileOutStruct {
    double tempo;     
    double timeScale; 
    int currentTrack;
    int division;
    int currentCount;
    int lastTime;
    NSMutableData *midiStream;
    int quantaSize;
    BOOL evaluateTempo;
} MKMIDIFileOut;

/*!
  @brief Begins reading the standard MIDI file located in the NSData instance fileData.
 */
extern MKMIDIFileIn *MKMIDIFileBeginReading(NSData *fileData, BOOL evaluateTempo);

extern void MKMIDIFileEndReading(MKMIDIFileIn *p);

/*!
  @brief Read the header of the specified file, and return the midifile level 
  (format) of the file, and the total number of tracks, in the respective 
  parameters. The return value will be non-zero if all is well; any error
  causes zero to be returned.
 */
extern int MKMIDIFileReadPreamble(MKMIDIFileIn *p, int *level, int *track_count);

/*!
 @brief Read the next event in the current track. Return nonzero if successful;
  zero if an error or end-of-stream occurred.
 Data should be an array of length 3. 
 @result Return endOfStream when EOS is reached, return 1 otherwise.
 */
extern int MKMIDIFileReadEvent(MKMIDIFileIn *p);

/*!
  @brief Writes the preamble and opens track zero for writing. In level 1 files,
  track zero is used by convention for timing information (tempo,time
  signature, click track). To begin the first track in this case, first
  call MKMIDIFileBeginWritingTrack.
  MKMIDIFileBeginWriting must be balanced by a call to MKMIDIFileEndWriting.
 */
MKMIDIFileOut *MKMIDIFileBeginWriting(NSMutableData *midiStream, int level, NSString *sequenceName, BOOL evaluateTempo);

/*!
 @brief Terminates writing to the stream. After this call, the stream may be closed.
 */
extern int MKMIDIFileEndWriting(MKMIDIFileOut *p);

/*!
 @brief Must be called in a level 1 file to bracket each
 chunk of track data (except track 0, which is special).
 */
extern int MKMIDIFileBeginWritingTrack(MKMIDIFileOut *p, NSString *trackName);

/*!
 @brief Must be called in a level 1 file to bracket each
 chunk of track data (except track 0, which is special).
 */
extern int MKMIDIFileEndWritingTrack(MKMIDIFileOut *p, int quanta);

extern int MKMIDIFileWriteTempo(MKMIDIFileOut *p, int quanta, double beatsPerMinute);

extern int MKMIDIFileWriteEvent(MKMIDIFileOut *p, int quanta, int ndata, unsigned char *bytes);

/*!
  @brief Assumes there's no MIDI_SYSEXCL at start and there is a MIDI_EOX at end. 
 */
extern int MKMIDIFileWriteSysExcl(MKMIDIFileOut *p, int quanta, int ndata, unsigned char *bytes);

/*!
  @brief Write time sig or key sig. Specified in midifile format. 
 */
extern int MKMIDIFileWriteSig(MKMIDIFileOut *p, int quanta, short metaevent, unsigned data);

extern int MKMIDIFileWriteText(MKMIDIFileOut *p, int quanta, short metaevent, NSString *data);

extern int MKMIDIFileWriteSMPTEoffset(MKMIDIFileOut *p,
				      unsigned char hr,
				      unsigned char min,
				      unsigned char sec,
				      unsigned char ff,
				      unsigned char fr);

int MKMIDIFileWriteSequenceNumber(MKMIDIFileOut *p, int data);

#endif
