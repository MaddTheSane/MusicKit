/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h

 Description:
 A MKScore contains a collection of MKParts and has methods for manipulating
 those MKParts. MKScores and MKParts work closely together.
 MKScores can be performed.
 The MKScore can read or write itself from a scorefile or midifile.

 Original Author: David A. Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2000, The MusicKit Project.
 */
/*
 Modification history prior to CVS commital:

 12/8/89/daj  - Fixed bug in midi-file reading -- first part was being
 initialized to a bogus info object.
 12/15/89/daj - Changed how Midi channel is encoded and written so that the
 information is not lost when reading/writing a format 1
 file.
 12/20/89/daj - Added writeOptimizedScorefile: and
 writeOptimizedScorefileStream:
 01/08/90/daj - Added clipping of firstTimeTag in readScorefile().
 02/26-28/90/daj - Changes to accomodate new way of doing midiFiles.
 Added midifile sys excl and meta-event support.
 03/13/90/daj - Changes for new categories for private methods.
 03/19/90/daj - Changed to use MKGetNoteClass(), MKGetPartClass().
 03/21/90/daj - Added archiving.
 03/27/90/daj - Added 10 new scorefile methods to make the scorefile and
 midifile cases look the same. *SIGH*
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 04/23/90/daj - Changes to make it a shlib and to make header files more
 modular.
 05/16/90/daj - Got rid of the "fudgeTime" kludge in the MIDI file reader,
 now that the MKPart object's been fixed to insure correct
 ordering. Added check for clas of MKPart class in setPart:.
 06/10/90/daj - Fixed bug in writing of scorefiles.
 07/24/90/daj - Removed unneeded copy of Note from readScorefile. Then
 added it back because it actually sped things up.
 08/31/90/daj - Added import of stdlib.h and define of NOT_YET
 09/26/90/daj - Fixed minor bug in freeNotes.
 12/18/90/daj - Added [parts free] to -free to fix memory leak.
 Added MKMIDIFileEndReading() calls to fix memory leak.
 07/08/91/daj - Was off by one in putSysExcl.
 17/01/92/daj - Fixed midifile tempo bug.
 9/03/92/daj - Fixed writing of scorefiles to preserve Part Note List
 ordering.
 17/06/92/daj - When writing midifile, changed it so that if there is no
 title: parameter, the part name of the first part is used.
 19/10/92/daj - Fixed a bug in scorefile merge function.
 11/17/92/daj - Minor change to shut up compiler warnings.
 11/18/92/daj - Removed bogus comment.
 6/26/93/daj - Added replacePart:with: method.
 */

#include <stdlib.h>
#import "_musickit.h"
#import "PartPrivate.h"
#import "NotePrivate.h"
#import "MKPlugin.h"
#import "_midi.h"
#import "midifile.h"
#import "tokens.h"
#import "_error.h"
#import <Foundation/Foundation.h>

#import "ScorePrivate.h"

static NSMutableArray<id<MusicKitPlugin>> *plugins = nil;
static NSArray<NSString*> *scoreFileExtensions = nil;

@implementation MKScore

#define READIT 0
#define WRITEIT 1

/* Creation and freeing ------------------------------------------------ */

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKScore class])
        return;
    [MKScore setVersion: VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
    _MKCheckInit();
    scoreFileExtensions = [@[ _MK_SCOREFILEEXT, _MK_BINARYSCOREFILEEXT ] retain];
}

/* Create a new instance and sends [self init]. */
+ (MKScore *) score
{
    MKScore *newScore = [[[self class] alloc] init];
    
    return [newScore autorelease];
}

+ (MKScoreFormat) scoreFormatOfData: (NSData *) fileData;
{
    int firstWord;
    
    firstWord = NSSwapBigIntToHost(*((int *)[fileData bytes]));
    if (firstWord == MK_SCOREMAGIC)
        return MK_PLAYSCORE;
    else if (firstWord == MK_MIDIMAGIC)
        return MK_MIDIFILE;
    else
        return MK_SCOREFILE;
}

+ (MKScoreFormat) scoreFormatOfFile: (NSString *) filename
{
    NSData *firstWordData;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath: filename];

    if (fh == nil)
	return MK_UNRECOGNIZEDFORMAT;
    firstWordData = [fh readDataOfLength: 4];
    return [MKScore scoreFormatOfData: firstWordData];
}    

+ (MKScoreFormat) scoreFormatOfURL: (NSURL *) filename error:(NSError **)error
{
    NSData *firstWordData;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:filename error:error];

    if (fh == nil)
	return MK_UNRECOGNIZEDFORMAT;
    if (@available(macOS 10.15, *)) {
	firstWordData = [fh readDataUpToLength:4 error:error];
    } else {
	firstWordData = [fh readDataOfLength: 4];
    }
    if (!firstWordData) {
	return MK_UNRECOGNIZEDFORMAT;
    }
    return [MKScore scoreFormatOfData: firstWordData];

}

-init
  /* TYPE: Creating and freeing a MKPart
* Initializes the receiver:
  *
  *  * Creates a new notes collection.
  *
  * Sent by the superclass upon creation;
  * you never invoke this method directly.
  * An overriding subclass method should send [super initialize]
  * before setting its own defaults.
  */
{
  self = [super init];
  if (self != nil) {
    parts = [NSMutableArray new];
  }
  return self;
}

-(void)releaseNotes
  /* Releases the notes contained in the parts. Does not releaseParts
  nor does it release the receiver. Implemented as
  [parts makeObjectsPerformSelector:@selector(releaseNotes)];
  Also releases the receivers info note.
  */
{
  [parts makeObjectsPerformSelector:@selector(releaseNotes)];
  [info release];
  info = nil;
}

- (void)dealloc
  /* Frees receiver, parts and MKNotes, including info note. */
{
  if (parts != nil) {
    [parts makeObjectsPerformSelector:@selector(_unsetScore)];
  //    [parts removeAllObjects];          // LMS redundant
    [parts release];
    parts = nil;
  }
  if (info != nil) {
    [info release];
    info = nil;
  }
  [super dealloc];
}

- (void)removeAllParts
  /* TYPE: Modifying; Removes the receiver's MKParts.
  * Removes the receiver's MKParts.
  * Returns the receiver.
  */
{
  [parts makeObjectsPerformSelector:@selector(_unsetScore)];
  [parts removeAllObjects];
  return;
}

/* Reading Scorefiles ------------------------------------------------ */

/*
 Read from scoreFile to receiver, creating new MKParts as needed and including only those
 notes between times firstTimeTag to time lastTimeTag, inclusive. Note that the TimeTags of the
 notes are not altered from those in the file. I.e. the first note's TimeTag will be greater than or equal to
 firstTimeTag. Merges contents of file with current MKParts when the MKPart name found in the
 file is the same as one of those in the receiver.
 Returns self or nil if error abort.  */
static id readScorefile(MKScore *self, NSData *stream, double firstTimeTag, double lastTimeTag, double timeShift, NSString *fileName)
{
    register _MKScoreInStruct *p;
    register id aNote;
    id rtnVal;
    unsigned int readPosition = 0;   // this is the top level.
    
    p = _MKNewScoreInStruct(stream, self, self->scorefilePrintStream, NO, fileName, &readPosition);
    if (!p)
	return nil;
    _MKParseScoreHeader(p);
    lastTimeTag = MIN(lastTimeTag, MK_ENDOFTIME);
    firstTimeTag = MIN(firstTimeTag, MK_ENDOFTIME);
    do {
	aNote = _MKParseScoreNote(p); /* not retained or autoreleased - so go careful */
    } while (p->timeTag < firstTimeTag);
    
    while (p->timeTag <= lastTimeTag) {
	if (aNote) {
	    _MKNoteShiftTimeTag(aNote, timeShift);
            [(MKPart*)(p->part) addNote:aNote];
	}
	aNote = _MKParseScoreNote(p);/* not retained or autoreleased - so go careful */
	if ((!aNote) && (p->timeTag > (MK_ENDOFTIME-1)))
	    break;
    }
    
    rtnVal = (p->_errCount == MAXINT) ? (MKScore *) nil : self;
    _MKFinishScoreIn(p);
    return rtnVal;
}

/* Read from scoreFile to receiver, creating new MKParts as needed
  and including only those notes between times firstTimeTag to
  time lastTimeTag, inclusive. Note that the TimeTags of the
  notes are not altered from those in the file. I.e.
  the first note's TimeTag will be greater than or equal to
  firstTimeTag.
  Merges contents of file with current MKParts when the MKPart
  name found in the file is the same as one of those in the
  receiver.
  Returns self or nil if file not found or the parse was aborted due to errors. 
 */
- (MKScore*)readScorefile: (NSString *) fileName
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag
      timeShift: (double) timeShift
{
    NSData *stream;
    id rtnVal;
    NSString *e = [fileName pathExtension];
    
    MKLoadAllBundlesOneOff();
    if ([[MKScore bundleExtensions] containsObject: e]) {
	for (id<MusicKitPlugin> p in plugins) {
	    if ([[p fileOpeningSuffixes] containsObject: [e lowercaseString]]) {
		id s = [p openFileName: fileName forScore: self];
		
		if (s)
		    return s;
		else 
		    NSLog(@"Plugin failed to read file, though it should have managed");
	    }
	}
    }

    stream = _MKOpenFileStreamForReading(fileName, _MK_BINARYSCOREFILEEXT, NO);
    if (!stream)
	stream = _MKOpenFileStreamForReading(fileName, _MK_SCOREFILEEXT, YES);
    if (!stream)
	return nil;
    rtnVal = readScorefile(self, stream, firstTimeTag, lastTimeTag, timeShift, fileName);
    return rtnVal;
}

- (MKScore*)readScoreAtURL: (NSURL *) fileURL
	      firstTimeTag: (double) firstTimeTag
	       lastTimeTag: (double) lastTimeTag
		 timeShift: (double) timeShift
		     error: (NSError **) error
{
    NSData *stream;
    id rtnVal;
    NSString *e = [fileURL pathExtension];
    
    MKLoadAllBundlesOneOff();
    if ([[MKScore bundleExtensions] containsObject: [e lowercaseString]]) {
	for (id<MusicKitPlugin> p in plugins) {
	    if ([[p fileOpeningSuffixes] containsObject: [e lowercaseString]]) {
		id s;
		if ([p respondsToSelector:@selector(openURL:forScore:error:)]) {
		    s = [p openURL: fileURL forScore: self error: error];
		} else {
		    s = [p openFileName: fileURL.path forScore: self];
		}
		
		if (s)
		    return s;
		else
		    NSLog(@"Plugin failed to read file, though it should have managed");
	    }
	}
    }

    stream = _MKOpenFileStreamForReading(fileURL.path, _MK_BINARYSCOREFILEEXT, NO);
    if (!stream)
	stream = _MKOpenFileStreamForReading(fileURL.path, _MK_SCOREFILEEXT, YES);
    if (!stream) {
	if (error && *error == nil) {
	    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: fileURL}];
	}
	return nil;
    }
    rtnVal = readScorefile(self, stream, firstTimeTag, lastTimeTag, timeShift, fileURL.path);
    if (rtnVal == nil) {
	if (error && *error == nil) {
	    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{NSURLErrorKey: fileURL}];
	}
    }
    return rtnVal;

}
/* Read from scoreFile to receiver, creating new MKParts as needed
  and including only those notes between times firstTimeTag to
  time lastTimeTag, inclusive. Note that the TimeTags of the
  notes are not altered from those in the file. I.e.
  the first note's TimeTag will be greater than or equal to
  firstTimeTag.
  Merges contents of file with current MKParts when the MKPart
  name found in the file is the same as one of those in the
  receiver.
  Returns self or nil if the parse was aborted due to errors.
  It is the application's responsibility to close the stream after calling this method.
 */
- readScorefileStream: (NSData *) stream
	 firstTimeTag: (double) firstTimeTag
	  lastTimeTag: (double) lastTimeTag
	    timeShift: (double) timeShift
{
  return readScorefile(self, stream, firstTimeTag, lastTimeTag, timeShift, NULL);
}

/* Scorefile reading "convenience" methods  --------------------------- */

- readScorefile: (NSString *) fileName
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag
{
  return [self readScorefile: fileName firstTimeTag: firstTimeTag
                 lastTimeTag: lastTimeTag timeShift: 0.0];
}

- readScorefileStream: (NSMutableData *) stream
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag
{
    return [self readScorefileStream: stream 
			firstTimeTag: firstTimeTag
			 lastTimeTag: lastTimeTag
			   timeShift: 0.0];
}

- readScorefile: (NSString *) fileName
{
  return [self readScorefile: fileName firstTimeTag: 0.0
                 lastTimeTag: MK_ENDOFTIME timeShift: 0.0];
}

- (nullable MKScore*)readScoreAtURL: (NSURL *) fileURL
			      error: (NSError **) error
{
    return [self readScoreAtURL: fileURL
		   firstTimeTag: 0.0
		    lastTimeTag: MK_ENDOFTIME
		      timeShift: 0.0
			  error: error];
}


- readScorefileStream: (NSData *) stream
{
  return [self readScorefileStream: stream firstTimeTag: 0.0
                       lastTimeTag: MK_ENDOFTIME timeShift: 0.0];
}

/* Writing Scorefiles --------------------------------------------------- */

/* Returns by reference the lowest and highest noteTags in receiver. */
- _noteTagRangeLowP: (int *) lowTag highP: (int *) highTag
{
  int noteTag,ht,lt;
  NSArray<MKNote*>* notes;
  NSInteger numOfParts = [parts count],m,partIndex,j;
  ht = 0;
  lt = MAXINT;
  for (partIndex = 0; partIndex < numOfParts; partIndex++) {
    notes = [[parts objectAtIndex:partIndex] notesNoCopy];
    m = [notes count];
    for (j = 0; j < m; j++) {
      noteTag = [[notes objectAtIndex:j] noteTag];
      if (noteTag != MAXINT) {
        ht = MAX(ht,noteTag);
        lt = MIN(lt,noteTag);
      }
    }
  }
  *highTag = ht;
  *lowTag = lt;
  return self;
}

// Returns an array of all the notes in the score which have a time tag between the bounds.
- (NSArray *) notesBetweenFirstTimeTag: (double) firstTimeTag
			   lastTimeTag: (double) lastTimeTag
{
    BOOL timeBounds = (firstTimeTag != 0) || (lastTimeTag != MK_ENDOFTIME);
    NSInteger numOfParts = [parts count], partIndex;
    NSMutableArray *allNotes = [NSMutableArray arrayWithCapacity: [self countOfNotes]];

    for (partIndex = 0; partIndex < numOfParts; partIndex++) {
	MKPart *currentPart = [parts objectAtIndex: partIndex];
	NSArray *notes;
	
	if (timeBounds)
	    notes = [currentPart firstTimeTag: firstTimeTag lastTimeTag: lastTimeTag];
	else {
	    notes = [currentPart notesNoCopy];
	}
	if (notes) {
	    [allNotes addObjectsFromArray: notes]; 
	}
    }
    [allNotes sortUsingSelector: @selector(compare:)]; // order all notes by time.
    return [NSArray arrayWithArray: allNotes]; // returns an immutable, autoreleased version
}

// Returns an array of all the notes in the score which have a valid time tag.
- (NSArray *) notes
{
    return [self notesBetweenFirstTimeTag: 0 lastTimeTag: MK_ENDOFTIME];
}

/* Write score body on aStream. Assumes p is a valid _MKScoreOutStruct. */
- (void) writeNotesToStream: (NSMutableData *) aStream
	     scoreOutStruct: (_MKScoreOutStruct *) p
	       firstTimeTag: (double) firstTimeTag
		lastTimeTag: (double) lastTimeTag
		  timeShift: (double) timeShift
{
    NSArray *allNotes = [self notesBetweenFirstTimeTag: firstTimeTag lastTimeTag: lastTimeTag];

    for (MKPart *currentPart in parts) {
	_MKWritePartDecl(currentPart, p, [currentPart infoNote]);
    }
    p->_timeShift = timeShift;
    
    for (MKNote *currentNote in allNotes) {
	_MKWriteNote(currentNote, [currentNote part], p);
    }
}

/* Same as writeScorefileStream: but only writes notes within specified time bounds. */
- (BOOL)writeScorefileStream: (NSMutableData *) aStream
                firstTimeTag: (double) firstTimeTag
                 lastTimeTag: (double) lastTimeTag
                   timeShift: (double) timeShift
                      binary: (BOOL) isBinary
{
    _MKScoreOutStruct * p;
    int lowTag, highTag;

    if (!aStream)
	return NO;
    p = _MKInitScoreOut(aStream, self, info, timeShift, NO, isBinary);
    [self _noteTagRangeLowP: &lowTag highP: &highTag];
    if (lowTag <= highTag) {
	if (isBinary) {
	    _MKWriteShort(aStream, _MK_noteTagRange);
	    _MKWriteInt(aStream, lowTag);
	    _MKWriteInt(aStream, highTag);
	}
	else {
	    [aStream appendData:[[NSString stringWithFormat: @"%s = %d %s %d;\n",
					   _MKTokNameNoCheck(_MK_noteTagRange), lowTag,
					   _MKTokNameNoCheck(_MK_to), highTag] 
				    dataUsingEncoding: NSNEXTSTEPStringEncoding]];
	}
    }
    [self writeNotesToStream: aStream 
	      scoreOutStruct: p 
	        firstTimeTag: firstTimeTag
                 lastTimeTag: lastTimeTag
	           timeShift: timeShift];
    _MKFinishScoreOut(p, YES);            /* Doesn't close aStream. */
    return YES;
}

- (BOOL)writeScorefileStream: (NSMutableData *) aStream
		firstTimeTag: (double) firstTimeTag
		 lastTimeTag: (double) lastTimeTag
		   timeShift: (double) timeShift
		      binary: (BOOL) isBinary
		       error: (NSError **) error
{
    //TODO: More error handling
    _MKScoreOutStruct * p;
    int lowTag, highTag;

    if (!aStream) {
	if (error) {
	    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
	}
	return NO;
    }
    p = _MKInitScoreOut(aStream, self, info, timeShift, NO, isBinary);
    if (p == NULL) {
	if (error) {
	    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
	}
	return NO;
    }
    [self _noteTagRangeLowP: &lowTag highP: &highTag];
    if (lowTag <= highTag) {
	if (isBinary) {
	    _MKWriteShort(aStream, _MK_noteTagRange);
	    _MKWriteInt(aStream, lowTag);
	    _MKWriteInt(aStream, highTag);
	}
	else {
	    [aStream appendData:[[NSString stringWithFormat: @"%s = %d %s %d;\n",
					   _MKTokNameNoCheck(_MK_noteTagRange), lowTag,
					   _MKTokNameNoCheck(_MK_to), highTag]
				    dataUsingEncoding: NSNEXTSTEPStringEncoding]];
	}
    }
    [self writeNotesToStream: aStream
	      scoreOutStruct: p
		firstTimeTag: firstTimeTag
		 lastTimeTag: lastTimeTag
		   timeShift: timeShift];
    _MKFinishScoreOut(p, YES);            /* Doesn't close aStream. */
    return YES;
}

- (BOOL)writeScorefile: (NSString *) aFileName
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
             timeShift: (double) timeShift
                binary: (BOOL) isBinary
{
    NSMutableData *stream = [[NSMutableData alloc] initWithCapacity:0];
    BOOL success;

    [self writeScorefileStream: stream
                  firstTimeTag: firstTimeTag
                   lastTimeTag: lastTimeTag
                     timeShift: timeShift
                        binary: isBinary];

    success = _MKOpenFileStreamForWriting(aFileName, (isBinary) ? _MK_BINARYSCOREFILEEXT : _MK_SCOREFILEEXT, stream, YES);
    [stream release];
    if (!success) {
	MKErrorCode(MK_cantCloseFileErr, aFileName);
	return NO;
    }
    else
	return YES;
}

- (BOOL)writeScoreToURL: (NSURL *) aFileName
	   firstTimeTag: (double) firstTimeTag
	    lastTimeTag: (double) lastTimeTag
	      timeShift: (NSTimeInterval) timeShift
		 binary: (BOOL) isBinary
		  error: (NSError**) error
{
    NSMutableData *stream = [[NSMutableData alloc] initWithCapacity:0];
    BOOL success;
    NSError *subError = nil;

    success = [self writeScorefileStream: stream
			    firstTimeTag: firstTimeTag
			     lastTimeTag: lastTimeTag
			       timeShift: timeShift
				  binary: isBinary];
    
    if (!success) {
	if (error) {
	    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSURLErrorKey: aFileName}];
	}
	[stream release];
	return NO;
    }
    
    success = [stream writeToURL:aFileName options:NSDataWritingAtomic error:error];
    [stream release];
    if (!success) {
	MKErrorCode(MK_cantCloseFileErr, aFileName);
	
	return NO;
    } else {
	return YES;
    }
}

- (BOOL)writeScorefile: (NSString *) aFileName
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
             timeShift: (double) timeShift
  /* Write scorefile to file with specified name within specified
  bounds. */
{
  return [self writeScorefile: aFileName
                 firstTimeTag: firstTimeTag
                  lastTimeTag: lastTimeTag
                    timeShift: timeShift
                       binary: NO];
}

- (BOOL)writeScoreToURL: (NSURL *) aFileName
	   firstTimeTag: (double) firstTimeTag
	    lastTimeTag: (double) lastTimeTag
	      timeShift: (NSTimeInterval) timeShift
		  error: (NSError**) error
{
    return [self writeScoreToURL:aFileName
		    firstTimeTag:firstTimeTag
		     lastTimeTag:lastTimeTag
		       timeShift:timeShift
			  binary:NO
			   error:error];
}

- (BOOL)writeScorefileStream: (NSMutableData *) aStream
                firstTimeTag: (double) firstTimeTag
                 lastTimeTag: (double) lastTimeTag
                   timeShift: (double) timeShift
/* Same as writeScorefileStream: but only writes notes within specified
  time bounds. */
{
  return [self writeScorefileStream: aStream
                       firstTimeTag: firstTimeTag
                        lastTimeTag: lastTimeTag
                          timeShift: timeShift
                             binary: NO];
}

- (BOOL)writeOptimizedScorefile: (NSString *) aFileName
                   firstTimeTag: (double) firstTimeTag
                    lastTimeTag: (double) lastTimeTag
                      timeShift: (double) timeShift
  /* Write scorefile to file with specified name within specified
  bounds. */
{
    return [self writeScorefile: aFileName
                   firstTimeTag: firstTimeTag
                    lastTimeTag: lastTimeTag
                      timeShift: timeShift
                         binary: YES];
}

- (BOOL)writeOptimizedScoreToURL: (NSURL *) aFileName
		    firstTimeTag: (double) firstTimeTag
		     lastTimeTag: (double) lastTimeTag
		       timeShift: (NSTimeInterval) timeShift
			   error: (NSError**) error
{
    return [self writeScoreToURL:aFileName
		    firstTimeTag:firstTimeTag
		     lastTimeTag:lastTimeTag
		       timeShift:timeShift
			  binary:YES
			   error:error];
}

- (BOOL)writeOptimizedScorefileStream: (NSMutableData *) aStream
                         firstTimeTag: (double) firstTimeTag
                          lastTimeTag: (double) lastTimeTag
                            timeShift: (double) timeShift
  /* Same as writeScorefileStream: but only writes notes within specified
  time bounds. */
{
    return [self writeScorefileStream: aStream
                         firstTimeTag: firstTimeTag
                          lastTimeTag: lastTimeTag
                            timeShift: timeShift
                               binary: YES];
}

/* Scorefile writing "convenience methods" ------------------------ */

- (BOOL)writeScorefile: (NSString *) aFileName
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
{
  return [self writeScorefile: aFileName
                  firstTimeTag: firstTimeTag
                   lastTimeTag: lastTimeTag
                     timeShift: 0.0
                        binary: NO];
}

- (BOOL)writeScorefileStream: (NSMutableData *) aStream
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
{
    return [self writeScorefileStream: aStream
                         firstTimeTag: firstTimeTag
                          lastTimeTag: lastTimeTag
                            timeShift: 0.0
                               binary: NO];
}

- (BOOL)writeScorefile: (NSString *) aFileName
{
    return [self writeScorefile: aFileName
                   firstTimeTag: 0.0
                    lastTimeTag: MK_ENDOFTIME
                      timeShift: 0.0];
}

- (BOOL)writeScoreToURL: (NSURL *) aFileName
		  error: (NSError**) error
{
    return [self writeScoreToURL: aFileName
		    firstTimeTag: 0.0
		     lastTimeTag: MK_ENDOFTIME
		       timeShift: 0.0
			   error: error];

}

- (BOOL)writeScorefileStream: (NSMutableData *) aStream
{
    return [self writeScorefileStream: aStream
                         firstTimeTag: 0.0
                          lastTimeTag: MK_ENDOFTIME
                            timeShift: 0.0];
}

- (BOOL)writeOptimizedScorefile: (NSString *) aFileName
            firstTimeTag: (double) firstTimeTag
             lastTimeTag: (double) lastTimeTag
{
  return [self writeScorefile: aFileName
                  firstTimeTag: firstTimeTag
                   lastTimeTag: lastTimeTag
                     timeShift: 0.0
                        binary: YES];
}

- (BOOL)writeOptimizedScorefileStream: (NSMutableData *) aStream
                  firstTimeTag: (double) firstTimeTag
                   lastTimeTag: (double) lastTimeTag
{
  return [self writeScorefileStream: aStream
                        firstTimeTag: firstTimeTag
                         lastTimeTag: lastTimeTag
                           timeShift: 0.0
                            binary: YES];
}

- (BOOL)writeOptimizedScorefile: (NSString *) aFileName
{
    return [self writeOptimizedScorefile: aFileName
                            firstTimeTag: 0.0
                             lastTimeTag: MK_ENDOFTIME
                               timeShift: 0.0];
}

- (BOOL)writeOptimizedScoreToURL: (NSURL *) aFileName
			   error: (NSError**) error
{
    return [self writeOptimizedScoreToURL: aFileName
			     firstTimeTag: 0.0
			      lastTimeTag: MK_ENDOFTIME
				timeShift: 0.0
				    error: error];
}

- (BOOL)writeOptimizedScorefileStream: (NSMutableData *) aStream
{
    return [self writeOptimizedScorefileStream: aStream
                                  firstTimeTag: 0.0
                                   lastTimeTag: MK_ENDOFTIME
                                     timeShift: 0.0];
}


/* Writing MIDI files ------------------------------------------------ */

static BOOL midifilesEvaluateTempo = YES;

+(void)setMidifilesEvaluateTempo:(BOOL)yesOrNo
{
  midifilesEvaluateTempo = yesOrNo;
}

+(BOOL)midifilesEvaluateTempo
{
  return midifilesEvaluateTempo;
}

static int timeInQuanta(void *p,double timeTag)
{
  return MKMIDI_DEFAULTQUANTASIZE * timeTag + .5; /* .5 for rounding */
}

static void putMidi(struct __MKMidiOutStruct *ptr)
{
  MKMIDIFileWriteEvent(ptr->_midiFileStruct,
                       timeInQuanta(ptr->_midiFileStruct,ptr->_timeTag),
                       ptr->_outBytes,
                       &(ptr->_bytes[0]));
}

static void putSysExcl(struct __MKMidiOutStruct *ptr, NSString *sysExclString)
{
    NSInteger sysExStrLen = [sysExclString lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
    const char *sysExclStr = [sysExclString UTF8String];
    unsigned char *buffer = (unsigned char *) _MKMalloc(sysExStrLen); /* More than enough */
    unsigned char *bufptr = buffer;
    NSInteger bufferLen;
    unsigned char c = _MKGetSysExByte(&sysExclStr);

    if (c == MIDI_SYSEXCL)
	c = _MKGetSysExByte(&sysExclStr);
    *bufptr++ = c;
    while (*sysExclStr && c != MIDI_EOX)
	*bufptr++ = c = _MKGetSysExByte(&sysExclStr);
    if (c != MIDI_EOX)
	*bufptr++ = MIDI_EOX;
    bufferLen = bufptr - buffer;
    MKMIDIFileWriteSysExcl(ptr->_midiFileStruct,
			   timeInQuanta(ptr->_midiFileStruct, ptr->_timeTag),
			   bufferLen,
			   buffer);
    free(buffer);
}

static void sendBufferedData(struct __MKMidiOutStruct *ptr)
/* Dummy function. (Since we don't need an extra level of buffering here) */
{
  // intentionally left blank
}

// return the possible extensions of MIDI files for pathnames
+ (NSArray *) midifileExtensions
{
    return [NSArray arrayWithObjects: _MK_MIDIFILEEXT, @"mid", nil];
}

// return the extension of scorefiles allowed
+ (NSArray *) scorefileExtensions
{
    return [NSArray arrayWithArray: scoreFileExtensions];
}

+ (void) setAlternativeScorefileExtensions: (NSArray *) otherScoreFileExtensions
{
    [scoreFileExtensions release];
    scoreFileExtensions = [otherScoreFileExtensions copy];
}

+ (NSArray *) bundleExtensions
{
    NSMutableArray *a = [[NSMutableArray alloc] init];

    for (id <MusicKitPlugin>p in plugins) {
        if ([[[p class] protocolVersion] isEqualToString:@"1"]) {
            [a addObjectsFromArray:[p fileOpeningSuffixes]];
            [a addObjectsFromArray:[p fileSavingSuffixes]];
        }
    }
    return [a autorelease];
}

// return all fileExtensions readable/writable by this class.
+ (NSArray *) fileExtensions
{
    NSArray *basic = [[MKScore scorefileExtensions] arrayByAddingObjectsFromArray: [MKScore midifileExtensions]];
    MKLoadAllBundlesOneOff();
    return [basic arrayByAddingObjectsFromArray:[MKScore bundleExtensions]];
}

#define T timeInQuanta(fileStructP,(t+timeShift))
#define STRPAR MKGetNoteParAsStringNoCopy
#define INTPAR MKGetNoteParAsInt
#define DOUBLEPAR MKGetNoteParAsDouble
#define INRANGE(_par) (_par >= 128 && _par <= 159)
#define PRESENT(_par) (parBits & (1<<(_par - 128)))
#define WRITETEXT(_meta,_par) MKMIDIFileWriteText(fileStructP,T,(_meta),STRPAR(curNote,(_par)))

/* Write a single MKNote to the MIDI file, tagged appropriately */
static void writeNoteToMidifile(_MKMidiOutStruct *p, MKMIDIFileOut *fileStructP, MKNote *curNote, double timeShift, int defaultChan)
{
    int chan;
    unsigned parBits;
    double t;
    
    /* First handle normal midi */
    chan = INTPAR(curNote,MK_midiChan);
    t = [curNote timeTag];
    _MKWriteMidiOut(curNote, t + timeShift, ((chan == MAXINT) ? defaultChan : chan), p, nil);
    /* Now check for meta-events. */
    parBits= [curNote parVector: 4];
    if (parBits) {
	if (PRESENT(MK_text))
	    WRITETEXT(MKMIDI_text,MK_text);
	if (PRESENT(MK_title))
	    WRITETEXT(MKMIDI_sequenceOrTrackName,MK_title);
	if (PRESENT(MK_instrumentName))
	    WRITETEXT(MKMIDI_instrumentName,MK_instrumentName);
	if (PRESENT(MK_lyric))
	    WRITETEXT(MKMIDI_lyric,MK_lyric);
	if (PRESENT(MK_cuePoint))
	    WRITETEXT(MKMIDI_cuePoint,MK_cuePoint);
	if (PRESENT(MK_marker))
	    WRITETEXT(MKMIDI_marker,MK_marker);
	if (PRESENT(MK_timeSignature)) {
	    int nn, dd, cc, bb;
	    unsigned int allData;
	    NSString *timeSigString = STRPAR(curNote, MK_timeSignature);
	    NSScanner *timeSigScan;
	    
	    if(timeSigString == nil) {
		allData = 0;
	    }
	    else {
		
		/*  From the Standard MIDI File Spec:
		The time signature defined with 4 bytes, a numerator, a denominator, a
		metronome pulse and number of 32nd notes per MIDI quarter-note. The
		numerator is specified as a literal value, but the denominator is
		specified as (get ready) the value to which the power of 2 must be
		raised to equal the number of subdivisions per whole note. For example,
		a value of 0 means a whole note because 2 to the power of 0 is 1 (whole
		note), a value of 1 means a half-note because 2 to the power of 1 is 2
		(half-note), and so on. The metronome pulse specifies how often the
		metronome should click in terms of the number of clock signals per click,
		which come at a rate of 24 per quarter-note. For example, a value of 24
		would mean to click once every quarter-note (beat) and a value of 48
		would mean to click once every half-note (2 beats). And finally, the
		fourth byte specifies the number of 32nd notes per 24 MIDI clock signals.
		This value is usually 8 because there are usually 8 32nd notes in a
		quarter-note. At least one Time Signature Event should appear in the
		first track chunk (or all track chunks in a Type 2 file) before any
		non-zero delta time events. If one is not specified 4/4, 24, 8 should
		be assumed.
		*/
		timeSigScan = [NSScanner scannerWithString: timeSigString];
		[timeSigScan scanInt: &nn];  // numerator
		[timeSigScan scanInt: &dd];  // denominator
					     // 0 is whole note, 1 is 1/2, 2 is 1/4,
					     // 3 is 1/8, 4 is 1/16 (semiquaver)
		[timeSigScan scanInt: &cc];  // clock sigs per metronome click
					     // 24 = quarter note, 48 = half note etc
		[timeSigScan scanInt: &bb];  // 
		allData = ((nn & 0xff) << 24) | ((dd & 0xff) << 16) | ((cc & 0xff) << 8) | (bb & 0xff);
	    }
	    MKMIDIFileWriteSig(fileStructP, T, MKMIDI_timeSig, allData);
	}
	if (PRESENT(MK_keySignature)) {
	    NSString *keySigString = STRPAR(curNote, MK_keySignature);
	    NSScanner *keySigScan;
	    int sf, mi;
	    unsigned int allData;
	    
	    if(keySigString == nil) {
		allData = 0;
	    }
	    else {
		keySigScan = [NSScanner scannerWithString: keySigString];
		[keySigScan scanInt: &sf];  // ??
		[keySigScan scanInt: &mi];  // ??
		allData = ((sf & 0xff) << 8) | (mi & 0xff);
	    }
	    MKMIDIFileWriteSig(fileStructP, T, MKMIDI_keySig, allData);
	}
	if (PRESENT(MK_tempo))
	    MKMIDIFileWriteTempo(fileStructP, T, DOUBLEPAR(curNote, MK_tempo));
    }
}

- (BOOL)writeMidifileStream:(NSMutableData *)aStream firstTimeTag:(double)firstTimeTag lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift
{
    return [self writeMidifileStream: aStream
			firstTimeTag: firstTimeTag
			 lastTimeTag: lastTimeTag
			   timeShift: timeShift
			       error: NULL];
}

/* Write midi on aStream. */
- (BOOL)writeMidifileStream: (NSMutableData *) aStream
	 firstTimeTag: (double) firstTimeTag
	  lastTimeTag: (double) lastTimeTag
	    timeShift: (double) timeShift
		      error:(NSError * _Nullable * _Nullable)error
{
    _MKMidiOutStruct *p;
    MKMIDIFileOut *fileStructP;
    double t = 0;
    MKNote *anInfo = nil;
    NSString *title = nil;
    int defaultChan;
    double tempo;
    MKPart *aPart, *curPart;
    NSArray *notes;
    MKNote *curNote;
    NSInteger partIndex, noteIndex, numOfParts, numOfNotes;
    
    NSAssert((INRANGE(MK_tempo) && INRANGE(MK_lyric) &&
	      INRANGE(MK_cuePoint) && INRANGE(MK_marker) &&
	      INRANGE(MK_timeSignature) &&
	      INRANGE(MK_keySignature)), @"Illegal use of parVector.");
    
    if (!aStream) {
	if (error) {
	    *error = [NSError errorWithDomain:NSOSStatusErrorDomain
					 code:paramErr userInfo:nil];
	}
	return NO;
    }
    tempo = 60;
    if (info) {
	if ([info isParPresent: MK_title])
	    title = [info parAsStringNoCopy: MK_title];
	if (title == nil) { /* Try using tempo track part name */
	    MKPart *aPart = [parts objectAtIndex: 0];
	    if (aPart)
		title = MKGetObjectName(aPart);
	}
	if ([info isParPresent: MK_tempo])
	    tempo = [info parAsDouble: MK_tempo];
    }
    p = _MKInitMidiOut();
    if (!(fileStructP = MKMIDIFileBeginWriting(aStream, 1, title, [MKScore midifilesEvaluateTempo]))) {
	_MKFinishMidiOut(p);
	if (error) {
	    *error = [NSError errorWithDomain:NSCocoaErrorDomain
					 code:NSFileWriteUnknownError
				     userInfo:nil];
	}
	return NO;
    }
    else 
	p->_midiFileStruct = fileStructP; /* Needed so functions called from _MKWriteMidiOut can find struct */
    numOfParts = [parts count];
    if (numOfParts == 0) {
	MKMIDIFileEndWriting(fileStructP);
	_MKFinishMidiOut(p);
	return YES;
    }
    p->_owner = self;
    p->_putSysMidi = putMidi;
    p->_putChanMidi = putMidi;
    p->_putSysExcl = putSysExcl;
    p->_sendBufferedData = sendBufferedData;
    MKMIDIFileWriteTempo(fileStructP, 0, tempo);
    if (info) {
	if ([info isParPresent: MK_copyright])
	    MKMIDIFileWriteText(fileStructP, 0, MKMIDI_copyright, STRPAR(info, MK_copyright));
	if ([info isParPresent: MK_text])
	    MKMIDIFileWriteText(fileStructP, 0, MKMIDI_text, STRPAR(info, MK_text));
	if ([info isParPresent: MK_sequence])
	    MKMIDIFileWriteSequenceNumber(fileStructP, INTPAR(info, MK_sequence));
	if ([info isParPresent: MK_smpteOffset]) {
	    int hr, mn, sec, fr, ff;
	    NSString *smpteString = STRPAR(info, MK_smpteOffset);
	    NSScanner *smpteScan;
	    
	    if(smpteString == nil) {
		hr = mn = sec = fr = ff = 0;
	    }
	    else {
		smpteScan = [NSScanner scannerWithString: smpteString];
		[smpteScan scanInt: &hr];
		[smpteScan scanInt: &mn];
		[smpteScan scanInt: &sec];
		[smpteScan scanInt: &fr];
		[smpteScan scanInt: &ff];
	    }
	    MKMIDIFileWriteSMPTEoffset(fileStructP, hr & 0xff, mn & 0xff, sec & 0xff, fr & 0xff, ff & 0xff);
	}
    }
    MKMIDIFileEndWritingTrack(fileStructP, lastTimeTag < MK_ENDOFTIME ? lastTimeTag : 0); // 0 end time is a little kludgy

    for (partIndex = 0; partIndex < numOfParts; partIndex++) {
	curPart = [parts objectAtIndex: partIndex];
	if ([curPart noteCount] == 0)
	    continue;
	MKMIDIFileBeginWritingTrack(fileStructP, (NSString *) MKGetObjectName(curPart));
	aPart = [curPart copy]; /* Need to copy to split notes. */
	[aPart splitNotes];
	[aPart sort];
	notes = [aPart notesNoCopy];
	anInfo = [aPart infoNote];
	defaultChan = 1;
	if (anInfo) {
	    if ([anInfo isParPresent: MK_midiChan]) {
		defaultChan = [anInfo parAsInt: MK_midiChan];
	    }
	    // If the time of the part info note has not been set, it becomes 0,
	    // otherwise use whatever is there, hopefully user knows best.
	    if([anInfo timeTag] >= MK_ENDOFTIME) {
		[anInfo setTimeTag: 0];
	    }
	    writeNoteToMidifile(p, fileStructP, anInfo, timeShift, defaultChan);
	}
	numOfNotes = [notes count];
	for (noteIndex = 0; noteIndex < numOfNotes; noteIndex++) {
	    curNote = [notes objectAtIndex: noteIndex];
	    if ((t = [curNote timeTag]) >= firstTimeTag) {
		if (t > lastTimeTag)
		    break;
		else {
		    writeNoteToMidifile(p, fileStructP, curNote, timeShift, defaultChan);
		}
	    }
	}
	MKMIDIFileEndWritingTrack(fileStructP, T);
	[aPart release];
    }
    MKMIDIFileEndWriting(fileStructP);
    _MKFinishMidiOut(p);
    return YES;
}

/* Write midi to file with specified name. */
- (BOOL)writeMidifile: (NSString *) aFileName 
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag 
      timeShift: (double) timeShift
{
    NSMutableData *stream = [[NSMutableData alloc] initWithCapacity:0];
    BOOL success;
    
    [self writeMidifileStream: stream
		 firstTimeTag: firstTimeTag
		  lastTimeTag: lastTimeTag
		    timeShift: timeShift];
    success = _MKOpenFileStreamForWriting(aFileName, [[MKScore midifileExtensions] objectAtIndex: 0], stream, YES);
    [stream release];
    
    if (!success) {
	MKErrorCode(MK_cantCloseFileErr, aFileName);
	return NO;
    }
    else {
	return YES;
    }
}

- (BOOL)writeMidiToURL: (NSURL *) aFileName
	  firstTimeTag: (double) firstTimeTag
	   lastTimeTag: (double) lastTimeTag
	     timeShift: (double) timeShift
		 error: (NSError**) error
{
    NSMutableData *stream = [[NSMutableData alloc] initWithCapacity:0];
    BOOL success;
    
    success = [self writeMidifileStream: stream
			   firstTimeTag: firstTimeTag
			    lastTimeTag: lastTimeTag
			      timeShift: timeShift
				  error: error];
    if (!success) {
	MKErrorCode(MK_musicKitErr, aFileName);
	return NO;
    }
    success = [stream writeToURL:aFileName options:0 error:error];
    [stream release];
    
    if (!success) {
	MKErrorCode(MK_cantCloseFileErr, aFileName);
	return NO;
    }
    else {
	return YES;
    }

}

/* Midi file writing "convenience methods" --------------------------- */

- (BOOL)writeMidifileStream: (NSMutableData *) aStream
               firstTimeTag: (double) firstTimeTag
                lastTimeTag: (double) lastTimeTag
{
    return [self writeMidifileStream: aStream
			firstTimeTag: firstTimeTag
			 lastTimeTag: lastTimeTag
			   timeShift: 0.0];
}

- (BOOL)writeMidifile: (NSString *) aFileName
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag
{
    return [self writeMidifile: aFileName 
		  firstTimeTag: firstTimeTag
		   lastTimeTag: lastTimeTag
		     timeShift: 0.0];
}

- (BOOL)writeMidifileStream: (NSMutableData *) aStream
{
    return [self writeMidifileStream: aStream
			firstTimeTag: 0.0
			 lastTimeTag: MK_ENDOFTIME];
}

-(BOOL)writeMidifile: (NSString *) aFileName
{
    return [self writeMidifile: aFileName
		  firstTimeTag: 0.0
		   lastTimeTag: MK_ENDOFTIME];
}

- (BOOL)writeMidiToURL: (NSURL *) aFileName
		 error: (NSError**) error
{
    return [self writeMidiToURL: aFileName
		   firstTimeTag: 0.0
		    lastTimeTag: MK_ENDOFTIME
		      timeShift: 0.0
			  error: error];
}


/* Reading MIDI files ---------------------------------------------- */

- (BOOL)readMidifile: (NSString *) aFileName
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag
     timeShift: (double) timeShift
{
    BOOL rtnVal;
    id stream; /*sb: could be NSMutableData or NSData */

    stream = _MKOpenFileStreamForReading(aFileName, [[MKScore midifileExtensions] objectAtIndex: 0], YES);
    if (stream == nil)
        return NO;
    rtnVal = [self readMidifileStream: stream
                         firstTimeTag: firstTimeTag
                          lastTimeTag: lastTimeTag
                            timeShift: timeShift];
    return rtnVal;
}

- (BOOL)readMidiAtURL: (NSURL *) fileName
	 firstTimeTag: (double) firstTimeTag
	  lastTimeTag: (double) lastTimeTag
	    timeShift: (double) timeShift
		error: (NSError **) error
{
    BOOL rtnVal;
    NSData *stream; /*sb: could be NSMutableData or NSData */

    stream = [NSData dataWithContentsOfURL: fileName
				   options: NSDataReadingMappedIfSafe
				     error: error];
    if (stream == nil)
	return NO;
    rtnVal = [self readMidiFileStream: stream
			 firstTimeTag: firstTimeTag
			  lastTimeTag: lastTimeTag
			    timeShift: timeShift
				error: error];
    return rtnVal;
}

static void writeDataAsNumString(MKNote *aNote, int par, unsigned char *data, int nBytes)
{
#   define ROOM 4 /* Up to 3 digits per number followed by space */
    int size = (nBytes * ROOM) + 1;
    char *str = (char *) _MKMalloc(size); // was alloca
    NSString * retStr;
    int i, j;
    
    for (i = 0; i < nBytes; i++)
	sprintf(&(str[i * ROOM]), "%-3d ", j = data[i + 1]);
    str[size - 1] = '\0'; /* Write over last space. */
    retStr = [NSString stringWithUTF8String: str];
    MKSetNoteParToString(aNote, par, retStr);
    free(str);
}

- (BOOL)readMidifileStream: (NSMutableData *) aStream
	      firstTimeTag: (double) firstTimeTag
	       lastTimeTag: (double) lastTimeTag
		 timeShift: (double) timeShift
{
    return [self readMidiFileStream: aStream
		       firstTimeTag: firstTimeTag
			lastTimeTag: lastTimeTag
			  timeShift: timeShift
			      error: NULL];
}

- (BOOL)readMidiFileStream: (NSData *) aStream
	firstTimeTag: (double) firstTimeTag
         lastTimeTag: (double) lastTimeTag
	   timeShift: (double) timeShift
		     error:(NSError * _Nullable * _Nullable)error
{
    int fileFormatLevel;
    int trackCount;
    double timeFactor, t, prevT, lastTempoTime = -1;
    MKPart *aPart;
    int i;
    register MKNote *aNote;
#   define MIDIPARTS (16 + 1)
    _MKMidiInStruct *midiInPtr;
    id *midiParts, *curPart;
    BOOL trackInfoMidiChanWritten = NO;
    MKMIDIFileIn *fileStructP;
    
    if (!(fileStructP = MKMIDIFileBeginReading(aStream, [MKScore midifilesEvaluateTempo]))) {
	return NO;
    }
#   define DATA (fileStructP->data)
    if (!MKMIDIFileReadPreamble(fileStructP, &fileFormatLevel, &trackCount)) {
	if (error) {
	    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
	}
	return NO;
    }
    if (fileFormatLevel == 0)
	trackCount = MIDIPARTS;
    else 
	trackCount++; 	/* trackCount doesn't include the 'tempo' track so we increment here */
    if (!(midiInPtr = _MKInitMidiIn())) {
	MKMIDIFileEndReading(fileStructP);
	return NO;
    }
    _MK_MALLOC(midiParts, id, trackCount); // TODO: Good candidate to be replaced with NSArray
    curPart = midiParts;
    for (i = 0; i < trackCount; i++) {
	aPart = [MKGetPartClass() new];
	aNote = [MKGetNoteClass() new];
	if ((fileFormatLevel == 0) && (i != 0))
	    [aNote setPar: MK_midiChan toInt: i];
	[aPart setInfoNote: aNote];
	[aNote release];
	[self addPart: aPart];
	*curPart++ = aPart;
    }
    lastTimeTag = MIN(lastTimeTag, MK_ENDOFTIME);
    timeFactor = 1.0 / (double) MKMIDI_DEFAULTQUANTASIZE;
    /* In format 0 files, *curPart will be the _MK_MIDISYS part. */
    curPart = midiParts;
#   define FIRSTTRACK (MKPart *) *midiParts
#   define CURPART (MKPart *) *curPart
    prevT = -1;
    if (!info)
	info = [MKGetNoteClass() new];
#   define SHORTDATA ((int)(*((short *)&(DATA[1]))))
#   define LONGDATA ((int)(*((int *)&(DATA[1]))))
#   define STRINGDATA ((char *)&(DATA[1]))
#   define LEVEL0 (fileFormatLevel == 0)
#   define LEVEL1 (fileFormatLevel == 1)
#   define LEVEL2 (fileFormatLevel == 2)
    if (LEVEL2) /* Sequences numbered consecutively from 0 by default. */
	MKSetNoteParToInt([FIRSTTRACK infoNote], MK_sequence, 0);
    while (MKMIDIFileReadEvent(fileStructP)) {
	if (fileStructP->metaeventFlag) {
	    /* First handle meta-events that are MKPart or MKScore info
	    parameters. We never want to skip these. */
	    switch (DATA[0]) {
		case MKMIDI_sequenceNumber:
		    MKSetNoteParToInt(LEVEL2 ? [CURPART infoNote] : info, MK_sequence, SHORTDATA);
		    break;
		case MKMIDI_smpteOffset:
		    writeDataAsNumString(LEVEL2 ? [CURPART infoNote] : info, MK_smpteOffset, DATA, 5);
		    break;
		case MKMIDI_sequenceOrTrackName:
		    /* Check if it is the first part. There is no MK_title in level 2 files, since
		    the title is merely the name of the first sequence. */
		    if ((curPart == midiParts) && !LEVEL2)
			MKSetNoteParToString(info, MK_title, [NSString stringWithUTF8String: STRINGDATA]);
		    /* In level 1 files, we name the current part with the
		    title. Note that we do this even if the name is a
		    sequence name rather than a track name. In level 0
		    files, we do not name the part. */
		    if(LEVEL1)
			MKSetNoteParToString([CURPART infoNote], MK_title, [NSString stringWithUTF8String: STRINGDATA]);
			if (fileFormatLevel != 0)
			    MKNameObject([NSString stringWithUTF8String: STRINGDATA], *curPart);
			    break;
		case MKMIDI_copyright:
		    MKSetNoteParToString(info, MK_copyright, [NSString stringWithUTF8String: STRINGDATA]);
		    break;
		case MKMIDI_instrumentName:
		    /* An instrument name is the sort of thing you need in a part info note, but the strict definition of
		    the SMF spec allows you to rename the track at different time points, why? It would have been better
		to define more tracks, each with a separate instrument. In that rather wierd case,
		    this code is wrong as it will take the last instrument name used as the info note. */
		    MKSetNoteParToString(LEVEL1 ? [CURPART infoNote] : info, MK_instrumentName, [NSString stringWithUTF8String: STRINGDATA]);
		default:
		    break;
	    }
	}
	t = fileStructP->quanta * timeFactor;
	/* FIXME Should do something better here. (need to change
	MKPart to allow ordering spec for simultaneous notes.) */
	if (t < firstTimeTag)
	    continue;
	if (t > lastTimeTag) {
	    if (LEVEL0)
		break; /* We know we're done */
	    else
		continue;
	}
	if (fileStructP->metaeventFlag) {
	    /* Now handle meta-events that can be in regular notes. These
	    are skipped when out of the time window, as are regular
	    MIDI messages. */
	    aNote = [[MKGetNoteClass() alloc] initWithTimeTag: t + timeShift]; /* retained */
	    switch (DATA[0]) {
		case MKMIDI_trackChange:
		    /* Sent at the end of every track. May be missing from the end of the file. */
		    if (t > (prevT + _MK_TINYTIME)) {
			/* We've got a significant trackChange time. */
			MKSetNoteParToString(aNote, LEVEL1 ? MK_track : MK_sequence, @"end");
			[CURPART addNote: aNote];    /* Put an end-of-track mark */
		    }
		    curPart++;
		    if (curPart >= midiParts + trackCount)
			goto outOfLoop;
			trackInfoMidiChanWritten = NO;
		    if (LEVEL1) /* Other files have no "tracks" */
			MKSetNoteParToInt([CURPART infoNote], MK_track, SHORTDATA);
		    else if (LEVEL2) {
			/* Assign ascending sequence number parameters */
#define OLDNUM MKGetNoteParAsInt([(*(curPart-1)) infoNote], MK_sequence)
			MKSetNoteParToInt([CURPART infoNote], MK_sequence, OLDNUM + 1);
		    }
		    lastTempoTime = -1;
		    prevT = -1;
		    [aNote release];
		    continue; /* Don't clobber prevT below */
		case MKMIDI_tempoChange:
		    /* For MK-compatibility, tempo is duplicated in info
		    MKNotes, but only if it's at time 0 in file.    */
		    if (t == 0) {
			if (lastTempoTime == 0) {
			    /* Supress duplicate tempi, which can arise because of
			    the way we duplicate tempo in info (do it by bypassing the addNote, below) */
			    break;
			}
			else { /* First setting of tempo for current track. */
			    id theInfo = LEVEL2 ? [CURPART infoNote] : info;
			    if (!MKIsNoteParPresent(theInfo, MK_tempo))
				MKSetNoteParToDouble(theInfo, MK_tempo, [MKScore midifilesEvaluateTempo] ? 60 : 60000000.0 / LONGDATA);
			}
		    }
		    lastTempoTime = t;
		    if(![MKScore midifilesEvaluateTempo]) {
			MKSetNoteParToDouble(aNote, MK_tempo, 60000000.0 / LONGDATA);
			[(LEVEL2 ? FIRSTTRACK : CURPART) addNote: aNote];
		    }
		    break;
		case MKMIDI_text:
		case MKMIDI_cuePoint:
		case MKMIDI_lyric:
		    MKSetNoteParToString(aNote,
					 ((DATA[0] == MKMIDI_text) ? MK_text :
					  (DATA[0] == MKMIDI_lyric) ? MK_lyric : MK_cuePoint),
					 [NSString stringWithUTF8String: STRINGDATA]);
		    [CURPART addNote: aNote];
		    break;
		case MKMIDI_marker:
		    MKSetNoteParToString(aNote, MK_marker, [NSString stringWithUTF8String: STRINGDATA]);
		    [(LEVEL2 ? FIRSTTRACK : CURPART) addNote: aNote];
		    break;
		case MKMIDI_timeSig:
		    writeDataAsNumString(aNote, MK_timeSignature, DATA, 4);
		    [(LEVEL2 ? FIRSTTRACK : CURPART) addNote: aNote];
		    break;
		case MKMIDI_keySig: {
		    /* Want sf signed, hence (char) cast  */
		    int sf = (int)((char) DATA[2]); /* sf */
		    int mi = (int)((char) DATA[3]); /* mi */
		    MKSetNoteParToString(aNote, MK_keySignature, [NSString stringWithFormat: @"%-2d %d", sf, mi]);
		    [(LEVEL2 ? FIRSTTRACK : CURPART) addNote: aNote];
		    break;
		}
		default:
		    break;
	    }
	    [aNote release];
	}
	else { /* Standard MIDI, not sys excl */
	    switch (fileStructP->nData) {
		case 3:
		    midiInPtr->_dataByte2 = DATA[2];
		    /* No break */
		case 2:
		    midiInPtr->_dataByte1 = DATA[1];
		    /* No break */
		case 1:
		    /* Status passed directly below. */
		    break;
		default: { /* Sys exclusive */
		    unsigned j;
		    char *str = (char *) _MKMalloc(fileStructP->nData * 3); /* 3 chars per byte */
		    char *ptr = str;
		    unsigned char *p = fileStructP->data;
		    unsigned char *endP = p + fileStructP->nData;
		    
		    snprintf(ptr, "%-2x", j = *p++);
		    ptr += 2;
		    while (p < endP) {
			sprintf(ptr, ",%-2x", j = *p++);
			ptr += 3;
		    }
		    *ptr = '\0';
		    aNote = [[MKGetNoteClass() alloc] initWithTimeTag: t + timeShift];
		    MKSetNoteParToString(aNote, MK_sysExclusive, [NSString stringWithUTF8String: str]); /* copy */
		    [CURPART addNote: aNote];
		    [aNote release];
		    continue;
		}
	    }
	    @autoreleasepool {
		aNote = _MKMidiToMusicKit(midiInPtr, DATA[0]); /* autoreleased */
		if (aNote) { /* _MKMidiToMusicKit can omit MKNotes sometimes. */
		    [aNote setTimeTag: t + timeShift];
		    // Need to copy MKNote because it's "owned" by midiInPtr (pre-OpenStep).
		    // Now we just add to the part as-is, and it will retain or copy it as necessary.
		    if (LEVEL0) {
			// LMS even if aNote has come from a Level0 file it should retain midiChannels from mode messages.
			if (midiInPtr->chan != _MK_MIDISYS) {
			    MKSetNoteParToInt(aNote, MK_midiChan, midiInPtr->chan);
			}
			[midiParts[midiInPtr->chan] addNote: aNote];
		    }
		    else {
			if (!trackInfoMidiChanWritten && midiInPtr->chan != _MK_MIDISYS) {
			    trackInfoMidiChanWritten = YES;
			    MKSetNoteParToInt([CURPART infoNote], MK_midiChan, midiInPtr->chan);
			    /* Set Part's chan to chan of first note in track. */
			}
			if (midiInPtr->chan != _MK_MIDISYS) {
			    MKSetNoteParToInt(aNote, MK_midiChan, midiInPtr->chan);
			}
			[CURPART addNote: aNote];
		    }
		}
	    } /* take care of autoreleased notes one at a time */
	} /* End of standard MIDI block */
	prevT = t;
    } /* End of while loop */
outOfLoop:
    free(midiParts);
    _MKFinishMidiIn(midiInPtr);
    MKMIDIFileEndReading(fileStructP);
    return YES;
}

/* Midifile reading "convenience methods"------------------------ */

- (BOOL)readMidifile: (NSString *) fileName
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag
{
  return [self readMidifile: fileName 
	       firstTimeTag: firstTimeTag
                lastTimeTag: lastTimeTag
		  timeShift: 0.0];
}

-(BOOL)readMidifileStream:(NSMutableData *)aStream
       firstTimeTag:(double)firstTimeTag
        lastTimeTag:(double)lastTimeTag
{
  return [self readMidifileStream:aStream firstTimeTag:firstTimeTag
                      lastTimeTag:lastTimeTag timeShift:0.0];
}

-(BOOL)readMidifile:(NSString *)fileName
/* Like readMidifile:firstTimeTag:lastTimeTag:,
  but always reads the whole file. */
{
  return [self readMidifile:fileName firstTimeTag:0.0
                lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

- (BOOL)readMidiAtURL: (NSURL *) fileName error: (NSError **) error
{
    return [self readMidiAtURL: fileName
		  firstTimeTag: 0.0
		   lastTimeTag: MK_ENDOFTIME
		     timeShift: 0.0
			 error: error];
}

-(BOOL)readMidifileStream:(NSMutableData *)aStream
/* Like readMidifileStream:firstTimeTag:lastTimeTag:,
  but always reads the whole file. */
{
  return [self readMidifileStream:aStream firstTimeTag:0.0
                      lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

/* Number of notes and parts ------------------------------------------ */

- (NSInteger) countOfParts
{
    return [parts count];
}

- (NSInteger) partCount
{
    return self.countOfParts;
}

- (NSInteger)countOfNotes
{
    NSUInteger numOfParts = [parts count], partIndex;
    NSUInteger numNotes = 0;
    for (partIndex = 0; partIndex < numOfParts; partIndex++)
	numNotes += [[parts objectAtIndex:partIndex] noteCount];
    
    return numNotes;
}

- (NSInteger) noteCount
    /* Returns the total number of notes in all the contained MKParts. */
{
    return self.countOfNotes;
}

/* Modifying the set of MKParts. ------------------------------- */

- (MKPart *) replacePart: (MKPart *) oldPart with: (MKPart *) newPart
  /* Removes oldPart from self and replaces it with newPart.
  * Returns newPart.
  * If oldPart is not a member of this score, returns nil
  * and doesn't add newPart.  If newPart is nil, or if
  * newPart is already a member of this score, or
  * if newPart is not a kind of MKPart, returns nil.
  */
{
  NSUInteger i = [parts indexOfObjectIdenticalTo: oldPart];
    
  if (i == NSNotFound)
      return nil;
  [self removePart: oldPart];
  if ((!newPart) || ([newPart score] == self) || ![newPart isKindOfClass: [MKPart class]])
      return nil;
  [newPart _setScore: self];
  [parts insertObject: newPart atIndex: i];
  return newPart;
}

- addPart: (MKPart *) aPart
  /* If aPart is already a member of the MKScore, returns nil. Otherwise,
  adds aPart to the receiver and returns aPart,
  first removing aPart from any other score of which it is a member. */
{
  if ((!aPart) || ([aPart score] == self) || ![aPart isKindOfClass: [MKPart class]])
    return nil;
  [aPart _setScore: self];
  if ([parts indexOfObjectIdenticalTo: aPart] == NSNotFound)
    [parts addObject: aPart];
  return self;
}

- (void) removePart: (MKPart *) aPart
  /* Removes aPart from self and returns aPart.
  If aPart is not a member of this score, returns nil. */
{
  [aPart _unsetScore];
  [parts removeObjectIdenticalTo: aPart];
}

- (void) shiftTime: (double) shift
    /* TYPE: Editing
    * Shift is added to the timeTags of all notes in the MKPart.
    */
{
    NSUInteger numOfParts = [parts count], partIndex;
    
    for (partIndex = 0; partIndex < numOfParts; partIndex++)
	[[parts objectAtIndex: partIndex] shiftTime: shift];
}

- (void) scaleTime: (double) scale
    /* TYPE: Editing
    * Scale factor is applied to the timeTags and durations of all notes in the MKPart.
    */
{
    NSUInteger numOfParts = [parts count], partIndex;
    
    for (partIndex = 0; partIndex < numOfParts; partIndex++)
	[[parts objectAtIndex:partIndex] scaleTime: scale];
}

// Returns the time of the first note in the score.
- (double) earliestNoteTime
{
    NSUInteger numOfParts = [parts count], partIndex;
    double earliestNoteTime = MK_ENDOFTIME;
    
    for (partIndex = 0; partIndex < numOfParts; partIndex++) {
	double earliestNoteTimeInPart = [(MKPart *) [parts objectAtIndex: partIndex] earliestNoteTime];

	if(earliestNoteTime > earliestNoteTimeInPart)
	    earliestNoteTime = earliestNoteTimeInPart;
    }
    return earliestNoteTime;    
}

/* Finding a Part ----------------------------------------------- */

- (BOOL) isPartPresent: (MKPart *) aPart
  /* Returns whether MKPart is a member of the receiver. */
{
    return ([parts indexOfObjectIdenticalTo: aPart] == NSNotFound) ? NO : YES;
}

- (MKPart *) midiPart: (int) aChan
  /* Returns the first MKPart with a MK_midiChan info parameter equal to
  aChan, if any. aChan equal to 0 corresponds to the MKPart representing
  MIDI system and channel mode messages. */
{
  id el, aInfo;
  NSInteger numOfParts, partIndex;
  if (aChan == MAXINT)
    return nil;
  numOfParts = [parts count];
  for (partIndex = 0; partIndex < numOfParts; partIndex++) {
    el = [parts objectAtIndex:partIndex];
    if ((aInfo = [el infoNote]))
      if ([aInfo parAsInt:MK_midiChan] == aChan)
        return [[el retain] autorelease];
  }
  return nil;
}

- (MKPart *) partAtIndex: (NSInteger) partIndex
{
    return [parts objectAtIndex: partIndex];
}

- (MKPart *) partTitled: (NSString *) partTitleToFind
{
    NSInteger partIndex, numOfParts = [parts count];
    
    for (partIndex = 0; partIndex < numOfParts; partIndex++) {
	MKPart *mkp = [parts objectAtIndex: partIndex];
	MKNote *infoNote = [mkp infoNote];
	
	if ([infoNote isParPresent: MK_title]) {
	    NSString *s = [infoNote parAsString: MK_title];
	    
	    if ([s isEqualToString: partTitleToFind])
		return mkp;
	}
    }
    return nil;
}

- (MKPart *) partNamed: (NSString *) partNameToFind
{
    NSInteger partIndex, numOfParts = [parts count];
    
    for (partIndex = 0; partIndex < numOfParts; partIndex++) {
	MKPart *mkp = [parts objectAtIndex: partIndex];
	
	if ([mkp isNamed: partNameToFind])
	    return mkp;
    }
    return nil;
}

/* Manipulating notes. ------------------------------- */


///* Sets the stream to be used for Scorefile 'print' statement output. */
//- (void) setScorefilePrintStream: (NSMutableData *) aStream
//{
//    scorefilePrintStream = aStream;
//}
//
///* Returns the stream used for Scorefile 'print' statement output. */
//- (NSMutableData *) scorefilePrintStream
//{
//    return scorefilePrintStream;
//}

@synthesize scorefilePrintStream;

/* Needed by scorefile parser  TODO: should merge with setInfoNote: */
-_setInfo:aInfo
{
  if (!info)
    info = [aInfo copy];
  else
    [info copyParsFrom: aInfo];
  return self;
}

///* Sets info, overwriting any previous info. aNote is copied. The old info, if any, is freed. */
//- (void) setInfoNote: (MKNote *) aNote
//{
//    [info release];
//    info = [aNote copy];
//}
//
//- (MKNote *) infoNote
//{
//    return info;
//}

@synthesize infoNote=info;

/* combine notes into noteDurs for all MKParts */
- (void)combineNotes
{
    for (MKPart *part in parts) {
	[part combineNotes];
    }
}

/* Returns a copy of the Array of MKParts in the receiver. The MKParts themselves are not copied.
   Now that we use NSArrays, a [List copyWithZone] did a shallow copy, whereas
   [NSMutableArray copyWithZone] does a deep copy, so we emulate the List operation.  
 */
- (NSArray *) parts;
{
    return [_MKLightweightArrayCopy(parts) autorelease];
}

/* Copies receiver, including its MKParts, MKNotes and info. */
- copyWithZone: (NSZone *) zone
{
    NSUInteger numOfParts = [parts count], partIndex;
    MKScore *newScore = [[MKScore allocWithZone:zone] init];
    for (partIndex = 0; partIndex < numOfParts; partIndex++)
	[newScore addPart:[[[parts objectAtIndex:partIndex] copyWithZone:zone] autorelease]];
    
    newScore->info = [info copyWithZone:zone];
    return newScore;
}

/* You never send this message directly.
  Should be invoked with NXWriteRootObject().
  Archives MKParts, MKNotes and info. */
- (void) encodeWithCoder: (NSCoder *) aCoder
{
    [aCoder encodeValuesOfObjCTypes: "@@", &parts, &info];
}

static BOOL isUnarchiving = NO;

/* You never send this message directly. Should be invoked via NXReadObject(). See write:. */
- (id) initWithCoder: (NSCoder *) aDecoder
{
    NSMutableDictionary *tagTable = [NSMutableDictionary dictionary];
    isUnarchiving = YES; /* Inhibit MKParts' mapping of noteTags. */
    
    if ([aDecoder versionForClassName: @"MKScore"] == VERSION2)
	[aDecoder decodeValuesOfObjCTypes: "@@", &parts, &info];
    /* Maps noteTags as represented in the archive file onto a set that is
     unused in the current application. This insures that the integrity
     of the noteTag is maintained. */
    [parts makeObjectsPerformSelector: @selector(_mapTags:) withObject: tagTable];
    isUnarchiving = NO;
    return self;
}

- (NSString *) description
{
    NSMutableString *scoreDescription = [[NSMutableString alloc] initWithFormat: @"%@ containing MKParts:\n", [super description]];
    NSArray *partList = [self parts];
    
    for(MKPart *aPart in partList) {
	[scoreDescription appendString: [aPart description]];
    }
    [scoreDescription appendFormat: @"With MKScore info note:\n%@", [[self infoNote] description]];
    
    return [scoreDescription autorelease];
}

#pragma mark - Private methods

+ (BOOL) _isUnarchiving
{
    return isUnarchiving;
}

- (MKPart*)_newFilePartWithName: (NSString *) name
    /* You never send this message. It is used only by the Scorefile parser
    to add a MKPart to the receiver when a part is declared in the
    scorefile.
    It is a method rather than a C function to hide from the parser
    the differences between MKScore and MKScorefilePerformer.
    */
{
    MKPart *aPart = [MKPart partWithName: name];
    
    [self addPart: aPart];
    return aPart; /* sb: I have checked, and it's ok to return "reference" here rather than retained object */
}

@end

@implementation MKScore (PluginSupport)

+ (void) addPlugin: (id<MusicKitPlugin>) plugin
{
    if (!plugins) {
        plugins = [[NSMutableArray alloc] init];
    }
    [plugins addObject:plugin];
}

@end

