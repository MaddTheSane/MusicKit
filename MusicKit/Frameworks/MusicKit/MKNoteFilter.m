/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
  NoteFilter.m
  Responsibility: David A. Jaffe
  
  DEFINED IN: The Music Kit
  HEADER FILES: musickit.h
*/
/* Modification history:

  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  03/08/95/daj - Added setting of owner in addNoteSender.
*/

#import "_musickit.h"

#import "InstrumentPrivate.h"
#import "MKNoteSender.h"
#import "NoteReceiverPrivate.h"

#import "MKNoteFilter.h"
@implementation MKNoteFilter: MKInstrument
  /* NoteFilter is an abstract class. 
     NoteFilter adds some of the functionality of Performer to that of 
     Instrument. In particular, it adds the ability to send to elements
     in a collection of NoteSenders.
     You subclass NoteFilter and override
     realizeNote:fromNoteSender: to do multiplexing of the input and output
     paths of the NoteFilter. NoteFilters may modify Notes.
     The only requirement is that any modification
     you make before sending a Note is undone afterwards. I.e. the 
     'copy on write or memory' principle is used.
     */
{
    id noteSenders;    /* Collection of NoteSenders. */
}

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKNoteFilter class])
      return;
//    [self setVersion:VERSION2];
    [MKNoteFilter setVersion:VERSION2]; //sb: suggested by Stone conversion guide
    return;
}

-init
{
    [super init]; /* Creates noteReceivers */
    noteSenders = [[NSMutableArray alloc] init];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: and archives noteSender List. */
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:noteSenders];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    [super initWithCoder:aDecoder];
    if ([aDecoder versionForClassName:@"NoteFilter"] == VERSION2) 
      noteSenders = [[aDecoder decodeObject] retain];
    return self;
}

#import "noteDispatcherMethods.m"

- copyWithZone:(NSZone *)zone
  /* Copies object, copying NoteSenders and NoteReceivers. */
{
    MKNoteFilter *newObj = [super copyWithZone:zone];
//    id *el,newEl;
    int i;
    unsigned n;
    newObj->noteSenders = [[NSMutableArray arrayWithCapacity:n = [noteSenders count]] retain];
    for (i=0; i<n; i++) 
      [newObj addNoteSender: [[noteSenders objectAtIndex:i] copy]];
    return newObj;
}

-addNoteSender:(id)aNoteSender
  /* If aNoteSender is already owned by the receiver, returns nil.
     Otherwise, aNoteSender is removed from its owner, the owner
     of aNoteSender is set to self, aNoteSender is added to 
     noteSenders (as the last element) and aNoteSender is returned. 
     For some subclasses, it is inappropriate for anyone
     other than the subclass instance itself to send this message. 
     If you override this method, first forward it to super.
     If the receiver is in performance, this message is ignored and nil
     is returned.
     */
{
    id owner = [aNoteSender owner];
    if (owner == self)
      return nil;
    if (_noteSeen)
      return nil;
    [owner removeNoteSender:aNoteSender];
    if (![noteSenders containsObject:aNoteSender]) [noteSenders addObject:aNoteSender];
    [aNoteSender _setOwner:self];    /* Tell it we're the owner */
    [aNoteSender _setPerformer:nil]; /* Tell it we're not a performer */
    return aNoteSender;
}

-removeNoteSender:(id)aNoteSender
  /* If aNoteSender is not owned by the receiver, returns nil.
     Otherwise, removes aNoteSender from the receiver's MKNoteSender List
     and returns aNoteSender. 
     For some subclasses, it is inappropriate for anyone
     other than the subclass instance itself to send this message. 
     If the receiver is in a performance, this message is ignored and nil is
     returned. */
{
    if ([aNoteSender owner] != self)
      return nil;
    if (_noteSeen)
      return nil;
    [noteSenders removeObject:aNoteSender];
    [aNoteSender _setOwner:nil];
    return aNoteSender;
}


- (void)dealloc
  /* TYPE: Creating
   * This invokes \fBfreenoteSenders\fR and \fBfreenoteReceivers\fR.
   * Then it frees itself.
   */
{
    [self freeNoteSenders];
    [noteSenders release];
    [super dealloc];
}

@end

