/*
  $Id$
  Defined In: The MusicKit

  Description:
    See class documentation below.
    
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2006, The MusicKit Project.
*/
/*!
  @class MKScore

  @brief A MKScore is a collection of MKPart objects.  MKScores can be read from and
    written to a scorefile or midifile, performed with a MKScorePerformer,
    and can be used to record MKNotes from a MKScoreRecorder.

A MKScore is a collection of MKPart objects.  MKScores can be read from
and written to a <b>.score</b> or <b>.playscore </b> scorefile or a
Standard MIDI file, performed with a MKScorePerformer, and can be used
to record MKNotes from a MKScoreRecorder.

Each MKScore has an info MKNote (a mute) that defines, in its
parameters, information that can be useful in performing or otherwise
interpreting the MKScore.  Typical information includes tempo, DSP
headroom (see the MKOrchestra Class), and sampling rate (the
parameters MK_tempo, MK_headroom, and MK_samplingRate are provided to
accommodate this utility).

When you read a scorefile into a MKScore, a MKPart object is created
and added to the MKScore for each MKPart name in the file's <b>part</b>
statement.  If the MKScore already contains a MKPart with the same
name as a MKPart in the file, the MKNotes from the two sources are
merged together in the existing MKPart in the MKScore.

MKScoreFile <b>print</b> statements are printed as the scorefile is
read into a MKScore.  You can set the stream on which the messages are
printed by invoking <b>setScorefilePrintStream:</b>.

*/
#ifndef __MK_Score_H___
#define __MK_Score_H___

#import <Foundation/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

@class MKNote;
@class MKPart;

/*!
  @enum       MKScoreFormat
  @brief   Formats that MKScore can read or write.
  @constant   MK_UNRECOGNIZEDFORMAT
  @constant   MK_MIDIFILE  MIDI Manufacturers Association Standard MIDI File V1.0.
  @constant   MK_SCOREFILE Text format version of Scorefile format, described in
  <A href=http://www.musickit.org/MusicKitConcepts/scorefilesummary.html>this syntax description</A>.
  @constant   MK_PLAYSCORE Binary format version of Scorefile format.
  @constant   MK_MUSICXML  XML based MusicXML format.
 */
 typedef NS_ENUM(int, MKScoreFormat) {
    MK_UNRECOGNIZEDFORMAT,
    MK_MIDIFILE,
    MK_SCOREFILE,
    MK_PLAYSCORE,
    MK_MUSICXML
};

@interface MKScore: NSObject <NSCoding, NSCopying>
{
    /*! The object's collection of MKParts. */
    NSMutableArray<MKPart*> *parts;
    /*! The stream used by scorefile <b>print</b> statements. */
    NSMutableData *scorefilePrintStream;    
    /*! The object's info MKNote. */
    MKNote *info;
}
 
/*!
  @return Returns an id.
  @brief Initializes the receiver. 
 
  You invoke this method when creating a new
  instance.  A subclass implementation should send <b>[super init]</b>
  before performing its own initialization. 
*/
- init;

 /*!
 Removes and releases the MKNotes contained in the receiver's MKParts.
 Also releases the receiver's info MKNote.  Returns the receiver.
 */
- (void)releaseNotes;

/*! 
  @brief Removes the receiver's MKParts.
 */
- (void) removeAllParts; 

/*!
  @param  fileName is an NSString instance.
  @return Returns an id.
  @brief Opens the scorefile named <i>fileName</i> and merges its contents
  with the receiver.  
 
  The file is automatically closed. Returns the receiver or <b>nil</b> if the file couldn't be read.
*/
- (nullable MKScore*)readScorefile: (NSString *) fileName;

- (nullable MKScore*)readScoreAtURL: (NSURL *) fileURL
			      error: (NSError **) error;

/*!
  @param  stream is a NSData instance.
  @return  Returns the receiver or <b>nil</b> if the file couldn't be read.
  @brief Reads the scorefile pointed to by <i>stream</i> into the receiver.
 
  The file must be open for reading; the sender is responsible for
  closing the file. 
*/
- (nullable MKScore*)readScorefileStream: (NSData *) stream;

/*!
  @param  fileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be read.
  @brief The same as <b>readScorefile:</b>, but only those
  MKNotes with timeTags in the specified range are added
  to the receiver.
 
 The added MKNotes' timeTags are shifted by <i>timeShift</i> beats.  
*/
- (nullable MKScore*)readScorefile: (NSString *) fileName
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag
      timeShift: (double) timeShift; 

/*!
  @param  fileURL is a NSURL instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be read.
  @brief The same as <b>readScorefile:</b>, but only those
  MKNotes with timeTags in the specified range are added
  to the receiver.
 
 The added MKNotes' timeTags are shifted by <i>timeShift</i> beats.
*/
- (nullable MKScore*)readScoreAtURL: (NSURL *) fileURL
	      firstTimeTag: (double) firstTimeTag
	       lastTimeTag: (double) lastTimeTag
		 timeShift: (double) timeShift
		     error: (NSError*__autoreleasing*) error;

/*!
  @param  stream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be read.
  @brief The same as <b>readScorefileStream:</b>, but only those
  MKNotes with timeTags in the specified range are added
	  to the receiver.
 
 The added MKNotes' timeTags are shifted by <i>timeShift</i> beats.  
*/
- (nullable MKScore*)readScorefileStream: (NSData *) stream
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag
            timeShift: (double) timeShift; 

//TODO: migrate to NSFileHandle?

/*!
  @param  aFileName is a NSString instance.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief Opens the scorefile named <b>aFileName</b> and writes the receiver to
  it (the file is overwritten).
 
 The file is automatically closed.
*/
- (BOOL)writeScorefile: (NSString *) aFileName; 

- (BOOL)writeScoreToURL: (NSURL *) aFileName
		  error: (NSError**) error;

/*!
  @param  aStream is a NSMutableData instance.
  @return Returns an id.
  @brief Writes the receiver into the scorefile pointed to by <i>aStream</i>.
 
  The file must be open for reading; the sender is responsible for
  closing the file.  Returns the receiver or <b>nil</b> if the file
  couldn't be written.
*/
- (BOOL)writeScorefileStream: (NSMutableData *) aStream;

/*!
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief The same as <b>writeScorefile:</b>, but only those
  MKNotes with timeTags in the specified range are written
  to the file.
 
 The written MKNotes' timeTags are shifted by <i>timeShift</i> beats.  
*/
- (BOOL)writeScorefile: (NSString *) aFileName
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
             timeShift: (double) timeShift;

- (BOOL)writeScoreToURL: (NSURL *) aFileName
	   firstTimeTag: (double) firstTimeTag
	    lastTimeTag: (double) lastTimeTag
	      timeShift: (NSTimeInterval) timeShift
		  error: (NSError**) error;

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief The same as <b>writeScorefileStream:</b>, but only those
	  MKNotes with timeTags in the specified range are written
	  to the file.
 
 The written MKNotes' timeTags are shifted by <i>timeShift</i> beats.  
*/
- (BOOL)writeScorefileStream: (NSMutableData *) aStream
                firstTimeTag: (double) firstTimeTag
                 lastTimeTag: (double) lastTimeTag
                   timeShift: (double) timeShift;

/*!
  @param  aFileName is a NSString instance.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief Opens the OptimizedScorefile named <b>fileName</b> and writes the
  receiver to it (the file is overwritten).
 
 The file is automatically closed.  
*/
- (BOOL)writeOptimizedScorefile: (NSString *) aFileName;

- (BOOL)writeOptimizedScoreToURL: (NSURL *) aFileName
			   error: (NSError**) error;

/*!
  @param  aStream is a NSMutableData instance.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief Writes the receiver into the OptimizedScorefile pointed to by <i>aStream</i>.
 
  The file must be open for reading; the sender is responsible for closing the file.  
*/
- (BOOL)writeOptimizedScorefileStream: (NSMutableData *) aStream;

/*!
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief The same as <b>writeOptimizedScorefile:</b>, but only
  those MKNotes with timeTags in the specified range are
	  written to the file.
 
 The written MKNotes' timeTags are shifted by <i>timeShift</i> beats.  
 */
- (BOOL)writeOptimizedScorefile: (NSString *) aFileName
             firstTimeTag: (double) firstTimeTag 
              lastTimeTag: (double) lastTimeTag
                timeShift: (double) timeShift;

- (BOOL)writeOptimizedScoreToURL: (NSURL *) aFileName
		    firstTimeTag: (double) firstTimeTag
		     lastTimeTag: (double) lastTimeTag
		       timeShift: (NSTimeInterval) timeShift
			   error: (NSError**) error;

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
  @brief The same as <b>writeOptimizedScorefileStream:</b>, but
  only those MKNotes with timeTags in the specified range are written
  to the file. 
*/
- (BOOL)writeOptimizedScorefileStream: (NSMutableData *) aStream
                   firstTimeTag: (double) firstTimeTag 
                    lastTimeTag: (double) lastTimeTag;

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns an id.
  @brief The same as <b>writeOptimizedScorefileStream:</b>, but
  only those MKNotes with timeTags in the specified range
	  are written to the file. The written MKNotes' timeTags
	  are shifted by <i>timeShift</i> beats.  Returns the
	  receiver or <b>nil</b> if the file couldn't be written.
*/
- (BOOL)writeOptimizedScorefileStream: (NSMutableData *) aStream 
                   firstTimeTag: (double) firstTimeTag 
                    lastTimeTag: (double) lastTimeTag 
                      timeShift: (double) timeShift; 
 
/*!
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns an id.
  @brief Reads the midifile <i>aFileName</i> into the receiver.  
 
  The MKNotes that are created are retained in the receiver
  only if their timeTags are within the given boundaries. 
  <i>TimeShift</i> is added to each timeTag.
  
  @see -<b>readMidiFileStream</b>: for a discussion of MIDI to MKNote conversion.
*/
- (BOOL)readMidifile: (NSString *) aFileName
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag
     timeShift: (double) timeShift;

- (BOOL)readMidiAtURL: (NSURL *) fileName
	 firstTimeTag: (double) firstTimeTag
	  lastTimeTag: (double) lastTimeTag
	    timeShift: (double) timeShift
		error: (NSError **) error;

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns an id.
  @brief Reads the midifile from <i>aStream</i> into the receiver.  
 
  Only the MKNote objects that have timeTags within the
  given boundaries are retained in the receiver.
  <i>timeShift<b></b></i> is added to each MKNote's
  timeTag.
*/
- (BOOL)readMidifileStream: (NSMutableData *) aStream
        firstTimeTag: (double) firstTimeTag
         lastTimeTag: (double) lastTimeTag
           timeShift: (double) timeShift
NS_DEPRECATED_MAC(10.0, 10.8, "Use -readMidiFileStream:firstTimeTag:lastTimeTag:timeShift:error: instead");

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @param  error is a double.
  @return Returns a BOOL.
  @brief Reads the midifile from <i>aStream</i> into the receiver.
 
  Only the MKNote objects that have timeTags within the
  given boundaries are retained in the receiver.
  <i>timeShift<b></b></i> is added to each MKNote's
  timeTag.
*/
- (BOOL)readMidiFileStream: (NSData *) aStream
	      firstTimeTag: (double) firstTimeTag
	       lastTimeTag: (double) lastTimeTag
		 timeShift: (double) timeShift
		     error: (NSError **) error;

/*!
  @param  fileName is a NSString instance.
  @return Returns an id.
  @brief Reads the midifile <i>fileName</i> into the receiver, creating
  MKParts for each MIDI Channel represented in the file and MKNotes
  for each MIDI message.
 
  @see -<b>readMidifileStream</b>: for a discussion of MIDI to MKNote conversion.
*/
- (BOOL)readMidifile: (NSString *) fileName;

- (BOOL)readMidiAtURL: (NSURL *) fileName
		error: (NSError **) error;

/*!
  @param  aStream is a NSMutableData instance.
  @return Returns an id.
  @brief Reads the midifile from aStream, converting the messages therein into MKNote objects.
 
  A midifile is converted into MKNotes as follows:
  
  If the file is format 0, the Channel Voice messages are
  written into 16 MKParts, one for each channel.  Channel
  Mode and System messages are combined in an additional
  MKPart.  The midi channel of a particular MKPart can be
  determined by examining the MK_midiChan parameter of the
  MKPart info MKNote.  The special MKPart has no
  MK_midiChan parameter.
  
  If the file is format 1, each track is written to a
  separate MKPart.  The track number is set in the MKPart
  info's MK_track parameter.
  
  If the file is format 2, each track is written to a
  separate MKPart.  The track number is set in the MKPart
  info's MK_sequence parameter.
  
  Tempo is encoded in the MK_tempo parameter of the
  MKScore's info.  Similarly, copyright shows up in the
  MKScore's info as an MK_copyright parameter.
  
  The info of each MKPart that corresponds to a track is
  given an MK_instrumentName parameter if a corresponding
  meta-event appears in the file.
  
  Other MIDI file meta-events such as time signature,
  lyric, etc. appear as corresponding MKNote parameters in
  mute MKNotes in the appropriate MKPart.
  
  The current contents of the MKScore are not affected.
  The new MKParts are never merged with the current
  contents.  Instead, new MKParts are added to the
  MKScore.  
*/
- (BOOL)readMidifileStream: (NSMutableData *) aStream;

/*!
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns an id.
  @brief Writes the receiver's MKNotes, within the given
  timeTag range,  as a midifile named <i>aFileName</i>.  
 
  <i>timeShift</i> is added to each MKNote's timeTag.

  @see -<b>writeMidifile:</b> for conversion details. 
 */
- (BOOL)writeMidifile: (NSString *) aFileName
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag
      timeShift: (double) timeShift;

- (BOOL)writeMidiToURL: (NSURL *) aFileName
	  firstTimeTag: (double) firstTimeTag
	   lastTimeTag: (double) lastTimeTag
	     timeShift: (double) timeShift
		 error: (NSError**) error;

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @param  error is a pointer to an NSError.
  @return Returns a BOOL.
  @brief Write the receiver, as a midifile, to <i>aStream</i>.
 
  Only the MKNotes within the given timeTag boundaries are written.
  <i>timeShift</i> is added to each MKNote's timeTag.
*/
- (BOOL)writeMidifileStream: (NSMutableData *) aStream
	       firstTimeTag: (double) firstTimeTag
		lastTimeTag: (double) lastTimeTag
		  timeShift: (double) timeShift
		      error: (NSError**) error;

/*!
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @return Returns an id.
  @brief Write the receiver, as a midifile, to <i>aStream</i>.
 
  Only the MKNotes within the given timeTag boundaries are written. 
  <i>timeShift</i> is added to each MKNote's timeTag.
*/
- (BOOL)writeMidifileStream: (NSMutableData *) aStream
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag
            timeShift: (double) timeShift;

/*!
  @param  aStream is a NSMutableData instance.
  @return Returns an id.
  @brief Write the receiver, as a midifile, to <i>aStream</i>.
*/
- (BOOL)writeMidifileStream: (NSMutableData *) aStream;

/*!
  @param  aFileName is a NSString instance.
  @return Returns an id.
  @brief The receiver is written as a format 1 midifile.
 
  The MKScore instance is written as follows:
  
  The MKParts are written in the order they appear in the
  MKScore as separate tracks.  The track number encoded in
  the MKPart's info MKNote is ignored.  MKNoteDurs are
  split into noteOns and noteOffs as defined by MKPart's
  <b>splitNotes</b> method.  The original MKPart isn't
  altered.
  
  If the receiver's info has a title or tempo parameter,
  these are written to the midifile.  
*/
- (BOOL)writeMidifile: (NSString *) aFileName;

- (BOOL)writeMidiToURL: (NSURL *) aFileName
		 error: (NSError**) error;

/*!
  @return Returns an unsigned.
  @brief Returns the number of MKNotes in all the receiver's MKParts.
*/
@property (readonly) NSInteger countOfNotes;

- (NSInteger) noteCount NS_DEPRECATED_WITH_REPLACEMENT_MAC("-countOfNotes", 10.0, 10.8);

/*!
  @brief Removes <i>oldPart</i> from the receiver and replaces it with <i>newPart</i>.
 
  If <i>oldPart</i> is not a
  member of this score, returns <b>nil</b> and doesn't add <i>newPart</i>.
  If <i>oldPart</i> is <b>nil</b>, or if <i>newPart</i> is already a
  member of this score, or if <i>oldPart</i> is not a kind of MKPart,
  returns <b>nil</b>.
  @param  oldPart is an id.
  @param  newPart is an id.
  @return Returns <i>newPart</i>.
*/
- (nullable MKPart *) replacePart: (nullable MKPart *) oldPart with: (MKPart *) newPart;

/*!
  @brief Adds <i>aPart</i> to the receiver.
 
  The MKPart is first removed from the MKScore that it's presently a member of, if any.  
  @param  aPart is an MKPart instance.
  @return Returns <i>self</i>, or <b>nil</b> if it's already a member of the receiver.
*/
- addPart: (MKPart *) aPart; 

/*!
  @brief Removes <i>aPart</i> from the receiver.  
  @param  aPart is an MKPart instance.
*/
- (void) removePart: (MKPart *) aPart;

/*!
  @brief Shifts the timeTags of all receiver's MKNotes by <i>shift</i> beats.
  @param  shift is a double.
*/
- (void) shiftTime: (double) shift; 

/*!
  @brief Scales the timeTags and durations of all receiver's MKNotes by <i>scale</i> beats. 
  @param  scale is a double.
*/
- (void) scaleTime: (double) scale;

/*!
  @brief Returns the time tag of the earliest note in the score.

  This can be useful to determine how much silence precedes the first note.
  @return Returns a double of time in seconds.
 */
- (double) earliestNoteTime;

/*!
  @brief Returns <b>YES</b> if <i>aPart</i> has been added to the receiver, otherwise returns <b>NO</b>.
  @param  aPart is an MKPart instance.
  @return Returns a BOOL.
*/
- (BOOL) isPartPresent: (MKPart *) aPart; 

/*!
  @brief Returns the first MKPart object that represents MIDI Channel <i>aChan</i>
  by checking the MK_midiChan info parameter.
 
  There are 17 MIDI Channels: 0 represents the channel for MIDI
  System and Channel Mode messages and 1 through 16 represent the
  Voice Channels.
  @param  aChan is an int.
  @return Returns an MKPart instance.
*/
- (nullable MKPart *) midiPart: (int) aChan; 

/*!
  @brief Returns the number of MKPart contained in the receiver.
  @return Returns an unsigned.
*/
- (NSInteger) partCount NS_DEPRECATED_WITH_REPLACEMENT_MAC("-countOfParts", 10.0, 10.8);

@property (readonly) NSInteger countOfParts;

/*!
  @brief Creates and returns a NSMutableArray containing the receiver's MKParts.
 
  The MKParts themselves aren't copied.
  @return Returns a NSArray of MKParts.
*/
- (NSArray<MKPart*> *) parts;

@property (readonly, copy) NSArray<MKPart*> *parts;

/*!
  @brief Retrieve the partIndex'th MKPart stored in the receiver.
  @return Returns a MKPart instance or nil if 0 < partIndex > [MKScore partCount].
 */
- (MKPart *) partAtIndex: (NSInteger) partIndex;

/*!
  @brief Returns the MKPart whose info note has an MK_title parameter
   equal to partTitleToFind, nil if it couldn't be found.
  @param  partTitleToFind
  @return Returns the MKPart, nil if it couldn't be found.
 */
- (nullable MKPart *) partTitled: (NSString *) partTitleToFind;

/*!
  @brief Returns the MKPart named partNameToFind, nil if it couldn't be found.
  @param  partNameToFind
  @return Returns the MKPart named partNameToFind, nil if it couldn't be found.
 */
- (nullable MKPart *) partNamed: (NSString *) partNameToFind;

/*!
  @brief Returns an NSArray of all MKNotes in all MKParts in the receiver.
  @return Returns an autoreleased NSArray instance.
 */
- (NSArray<MKNote*> *) notes;

@property (readonly, copy, nonatomic) NSArray<MKNote*> *notes;

/*!
  @brief Returns an NSArray of all the notes in the score which have a time tag between
  the bounds.
  @return Returns an autoreleased NSArray instance.
*/
- (NSArray<MKNote*> *) notesBetweenFirstTimeTag: (double) firstTimeTag
                                    lastTimeTag: (double) lastTimeTag;

/*!
 @brief Combine notes into noteDurs for all MKParts 
*/
- (void)combineNotes;

/*!
  @brief Creates and returns a new MKScore as a copy of the receiver in the
  nominated NSZone.
  
  The receiver's MKPart, MKNotes, and info MKNote are all copied.
  @return Returns an id.
 */
- (id)copyWithZone: (nullable NSZone *) zone;

/*!
  @brief Sets the receiver's info MKNote to a copy of <i>aNote</i>.
 
  The receiver's previous info MKNote is removed and released.
  @param  aNote is an MKNote.
*/
- (void) setInfoNote: (MKNote *) aNote;

/*!
  @brief Returns the receiver's info MKNote.
  @return Returns an MKNote.
*/
- (MKNote *) infoNote;

@property (nullable, copy) MKNote *infoNote;

/*!
  @brief Sets the stream used by ScoreFile <b>print</b> statements to <b>aStream</b>.  
  @param  aStream is a NSMutableData instance.
*/
- (void) setScorefilePrintStream: (NSMutableData *) aStream;

/*!
  @brief Returns the receiver's ScoreFile <b>print</b> statement stream.
  @return Returns a NSMutableData instance.
*/
- (NSMutableData *) scorefilePrintStream;

@property (assign, nullable) NSMutableData *scorefilePrintStream;

/*!
  @brief Sets the class variable <i>midifilesEvaluateTempo</i>, which
  specifies how tempo is interpreted when reading or writing MIDI
  files.
 
  Tempo is interepreted as follows:
  
  If <i>midifilesEvaluateTempo</i> is YES, the MKNotes'
  timeTags and durations are modified according to the tempo.  For
  example, if the tempo is 120 and a MIDI note begins at time 1.0 in
  the file and lasts for a half of a beat, the corresponding Music Kit
  MKNote will have a timeTag of 0.5 and a duration of 0.25.  
  Similarly, when writing files, the tempo is taken into account.  For
  example, if the tempo is 120 and a Music Kit MKNote has a timeTag of
  0.5 and a duration of 0.25, it is converted back to a MIDI note that
  begins at time 1.0 and lasts for a half of a beat.
		
  If <i>midifilesEvaluateTempo</i> is NO, the
  modification of timeTags and durations is not performed.   NO is an
  appropriate value when you are doing real-time tempo modification
  with a slider or other control.
  
  Whatever the value of <i>midifilesEvaluateTempo</i>,
  the first tempo event found in the file is supplied as the MKScore
  info's MK_tempo parameter.   Note that the Music Kit does not
  currently support evaluating time-varying tempos found in Standard
  MIDI Files.
  
  The default value of <i>midifilesEvaluateTempo</i> is
  YES. When so, when writing to a MIDIfile, tempo is factored into the timestamps. 
  @param  yesOrNo is a BOOL.
  @return Returns an id.
*/
+ (void)setMidifilesEvaluateTempo: (BOOL) yesOrNo;

/*!
  @brief Returns the value of the class variable <i>midifilesEvaluateTempo.</i> 

  @see +<b>setMidifilesEvaluateTempo:</b>.
  @return Returns a BOOL.
*/
+ (BOOL) midifilesEvaluateTempo;

@property (class, readwrite) BOOL midifilesEvaluateTempo;

/*!
  @brief Returns the possible file extensions used in writing and
  reading MIDI files appropriate for the native operating system.
  @return Returns an NSArray of NSStrings.
*/
+ (NSArray<NSString*> *) midifileExtensions;

@property (class, readonly, copy) NSArray<NSString*> *midifileExtensions;

/*!
  @brief Returns the possible file extensions used in writing and
  reading scorefiles files appropriate for the native operating system.
  @return Returns an NSArray of NSStrings.
*/
+ (NSArray<NSString*> *) scorefileExtensions;

@property (class, readonly, copy) NSArray<NSString*> *scorefileExtensions;

/*!
  @brief This method allows overriding the file extensions used in writing and
  reading scorefiles files returned by <i>scorefileExtensions</i>.
 */
+ (void) setAlternativeScorefileExtensions: (NSArray *) otherScoreFileExtensions;

/*!
  @brief Returns the possible file extensions used in writing and
  reading scorefiles and MIDI files appropriate for the
  native operating system.
  @return Returns an NSArray of NSStrings.
*/
+ (NSArray<NSString*> *) fileExtensions;

@property (class, readonly, copy) NSArray<NSString*> *fileExtensions;

/*!
  @brief Returns the possible file extensions supported by any available plugins. 
 
  It does not make a distinction between extensions supported for reading and those for writing,
  so query each plugin in turn to see what it supports.
  @return Returns an NSArray of NSStrings.
 */
+ (NSArray<NSString*> *) bundleExtensions;

@property (class, readonly, copy) NSArray<NSString*> *bundleExtensions;

/*!
  @brief Creates and returns an allocated, initialised and autoreleased MKScore instance.
  @return Returns a newly allocated MKScore instance.
*/
+ (instancetype) score;

/*!
  @brief Determines the format of the scorefile data.
  @param fileData An NSData object containing score data, it should be a MIDI file, Scorefile or playscore format.
  @return Returns whether the data is a MIDI file (MK_MIDIFILE), Scorefile (MK_SCOREFILE), playscore (MK_PLAYSCORE).
 */
+ (MKScoreFormat) scoreFormatOfData: (NSData *) fileData;

/*!
  @brief Determines the format of the named scorefile.
  @param filename The name of the file to be inspected.
  @return Returns the format of the files data.
 */
+ (MKScoreFormat) scoreFormatOfFile: (NSString *) filename;

/*!
  @brief Determines the format of the named scorefile.
  @param filename The URL of the file to be inspected.
  @return Returns the format of the files data.
 */
+ (MKScoreFormat) scoreFormatOfURL: (NSURL *) filename error: (NSError**) error;

/*!
  @brief The same as <b>writeScorefile:</b>, but only those
  MKNotes with timeTags in the specified range are written
  to the file.  
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
*/
- (BOOL)writeScorefile: (NSString *) aFileName
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag;

/*!
  @brief The same as <b>writeScorefileStream:</b>, but only those
	  MKNotes with timeTags in the specified range are written
	  to the file. 
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
*/
- (BOOL)writeScorefileStream: (NSMutableData *) aStream 
                firstTimeTag: (double) firstTimeTag
                 lastTimeTag: (double) lastTimeTag;

/*!
  @brief The same as <b>readScorefile:</b>, but only those
	  MKNotes with timeTags in the specified range are added
	  to the receiver.
  @param  fileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be read.
*/
- readScorefile: (NSString *) fileName 
   firstTimeTag: (double) firstTimeTag 
    lastTimeTag: (double) lastTimeTag;

/*!
  @brief The same as <b>readScorefileStream:</b>, but only those
	  MKNotes with timeTags in the specified range are added
	  to the receiver.
  @param  stream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be read.
*/
- readScorefileStream: (NSMutableData *) stream 
         firstTimeTag: (double) firstTimeTag 
          lastTimeTag: (double) lastTimeTag;

/*!
  @brief The same as <b>writeOptimizedScorefile:</b>, but only
	  those MKNotes with timeTags in the specified range are
	  written to the file. 
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns the receiver or <b>nil</b> if the file couldn't be written.
*/
- (BOOL)writeOptimizedScorefile: (NSString *) aFileName 
                   firstTimeTag: (double) firstTimeTag
                    lastTimeTag: (double) lastTimeTag;

/*!
  @brief Reads the midifile <i>aFileName</i> into the receiver.
 
  The MKNotes that are created are retained in the
  receiver only if their timeTags are within the given
  boundaries.
  
  @see  -<b>readMidiFileStream:</b> for a discussion of MIDI to MKNote conversion.  
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns an id.
*/
- (BOOL)readMidifile: (NSString *) aFileName 
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag;

/*!
  @brief Reads the midifile from <i>aStream</i> into the receiver.  
 
  Only the MKNote objects that have timeTags within the
  given boundaries are retained in the receiver.
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns an id.
*/
- (BOOL)readMidifileStream: (NSMutableData *) aStream 
        firstTimeTag: (double) firstTimeTag
         lastTimeTag: (double) lastTimeTag;

/*!
  @brief Writes the receiver's MKNotes, within the given
  timeTag range, as a midifile named <i>aFileName</i>.
 
  @see -<b>writeMidifile:</b> for conversion details.
  @param  aFileName is a NSString instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns an id.
*/
- (BOOL)writeMidifile: (NSString *) aFileName
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag;

/*!
  @brief Write the receiver, as a midifile, to <i>aStream</i>.
 
  Only the MKNotes within the given timeTag boundaries are written. 
  @param  aStream is a NSMutableData instance.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns an id.
*/
- (BOOL)writeMidifileStream: (NSMutableData *) aStream
               firstTimeTag: (double) firstTimeTag
                lastTimeTag: (double) lastTimeTag;

@end

NS_ASSUME_NONNULL_END

#endif
