/*
  $Id$
  Defined In: The MusicKit

  Description: 
    A pseudo-performer that does its work by managing a set of MKPartPerformers.
    Many of the methods resemble MKPerformer methods, but they operate by
    doing a broadcast to the contained MKPartPerformers.

    Note that while MKScorePerformer resembles a MKPerformer, it is not identical
    to a MKPerformer and some care must be taken when using it. For example,
    the method -noteSenders returns the MKNoteSenders of the MKPartPerformers.
    The MKScorePerformer itself does not have any MKNoteSenders. Thus, to find
    the name of one of these, you have to specify the owner as the
    MKPartPerformer, not as the MKScorePerformer. If you use the MKNoteSender
    owner method to determine the owner, you won't have any problem.
 
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
/* Modification history prior to commit to CVS repository:

   03/17/90/daj - Added delegate mechanism. Added settable PartPerformerClass
   04/21/90/daj - Small mods to get rid of -W compiler warnings.
   08/27/90/daj - Changes to support zone API
   02/07/91/daj - Fixed bug that could cause ScorePerformer's delegate message
   		  to be sent twice.  Also added support for invoking 
		  ScorePerformer's deactivate when all its PartPerformers
		  are automatically deactivated.  It could be argued that,
		  for consistancy, we should make it so that ScorePerformer's 
		  activate method is invoked if individual PartPerformers are 
		  activated and the same for pause/resume. But it could also
		  be argued that the "score-as-a-whole" should not be
		  considered active unless it was explicitly activated. 
		  The same cannot be said of deactivating -- if all 
		  PartPerformers have reached the end of their data and
		  have deactivated themselves, it's hard to argue for anything 
		  but the interpretation that the "score-as-a-whole" should
		  automatically be deactivated. So that's what happens now.
		  This is less than clean, but probably nobody will ever
		  notice (!).
   06/06/92/daj - Changed freePartPerformers to refuse to do so if the
                  MKScorePerformer is in performance.
   11/01/94/daj - Fixed _partPerformerDidDeactivate: so it correctly notices
	          when all PartPerformers are deactivated.
 */

#import "_musickit.h"
#import "ConductorPrivate.h"
#import "PartPerformerPrivate.h"
#import "ScorePerformerPrivate.h"

@implementation MKScorePerformer

+ (MKScorePerformer *) scorePerformer
{
    return [[[MKScorePerformer alloc] init] autorelease];
}

- init
{
    self = [super init];
    if(self != nil) {
	partPerformers = [[NSMutableArray alloc] init];
	partPerformerClass = [MKPartPerformer class];
	_deactivateMsgPtr = NULL;
	duration = MK_ENDOFTIME;
	lastTimeTag = MK_ENDOFTIME;
	status = MK_inactive;
	conductor = [MKConductor defaultConductor];
    }
    return self;
}

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKScorePerformer class])
	return;
    [MKScorePerformer setVersion: VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partPerformers,firstTimeTag,lastTimeTag,timeShift,
     duration, and partPerformerClass. Also optionally archives score
     conductor and delegate using NXWriteObjectReference().
     */
{
    NSAssert((sizeof(MKPerformerStatus) == sizeof(int)), @"write: method error.");
    [aCoder encodeObject:partPerformers];
    [aCoder encodeConditionalObject:score];
    [aCoder encodeValuesOfObjCTypes:"dddd#",&firstTimeTag,&lastTimeTag,
		 &timeShift,&duration,&partPerformerClass];
    [aCoder encodeConditionalObject:conductor];
    [aCoder encodeConditionalObject:delegate];
}

- (id) initWithCoder: (NSCoder *) aDecoder
  /* TYPE: Archiving; Reads object.
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     */
{
    if ([aDecoder versionForClassName: @"MKScorePerformer"] == VERSION2) {
	partPerformers = [[aDecoder decodeObject] retain];
	score = [[aDecoder decodeObject] retain];
	[aDecoder decodeValuesOfObjCTypes: "dddd#",&firstTimeTag,&lastTimeTag,
		    &timeShift,&duration,&partPerformerClass];
	conductor = [[aDecoder decodeObject] retain];
	delegate = [[aDecoder decodeObject] retain];
    }
    /* from awake */
    if (!conductor)
        conductor = [MKConductor defaultConductor];
    status = MK_inactive;
    return self;
}

static void unsetPartPerformers(MKScorePerformer *self)
{
    unsigned n = [self->partPerformers count], i;
    
    for (i = 0; i < n; i++)
        _MKSetScorePerformerOfPartPerformer([self->partPerformers objectAtIndex: i], nil);
    [self->score release];
    self->score = nil;
}

- releasePartPerformers
    /* Frees all PartPerformers. Returns self. */
{
    if (status != MK_inactive)
	return nil;
    unsetPartPerformers(self);
    [partPerformers removeAllObjects];
    return self;
}

- removePartPerformers
  /* Sets score to nil and removes all PartPerformers, but doesn't free them.
     Returns self.
     */
{
    unsetPartPerformers(self);
    [partPerformers removeAllObjects];
    return self;
}

- (MKScore *) score
  /* Returns score. */
{
    return score;
}

- (BOOL)activate
    /* If score is not set or MKScore contains no parts, returns nil. Otherwise, 
    sends activateSelf, broadcasts activate message to contents, and 
    returns self and sets status to MK_active if any one of the
    MKPartPerformers returns self.
    */ 
{
    if (!score || (![score partCount]) || (![self activateSelf]))
	return NO;
    for (MKPerformer *performer in partPerformers)
        if ([performer activate])
            status = MK_active;
    if (status != MK_active)
	return NO;
    _deactivateMsgPtr = MKCancelMsgRequest(_deactivateMsgPtr);
    // LMS - why shouldn't this be a deactivate rather than _deactivate?
    _deactivateMsgPtr = [MKConductor _afterPerformanceSel:
				@selector(_deactivate) to:self argCount:0];
    if ([delegate respondsToSelector:@selector(performerDidActivate:)])
	[delegate performerDidActivate:self];
    return YES;
}

- activateSelf
  /* TYPE: Performing; Does nothing; subclass may override for special behavior.
   * Invoked from the activate method,
   * a subclass can implement
   * this method to perform pre-performance activities.
   * If activateSelf returns nil, the activation of the 
   * PartPerformers is aborted.
   * The default does nothing and returns the receiver.
   */
{
    return self;
}

/* Snapshots the score over which we will sequence and creates
   MKPartPerformers for each MKPart in the MKScore in the same order as the
   corresponding MKParts. Note that any MKParts added to 
   aScore after -setScore: is sent will not appear in the performance. In
   order to get such MKParts to appear, you must send setScore: again. 
   If aScore is not the same as the previously specified score,
   frees all contained MKPartPerformers.  The MKPartPerformers are added
   in the order the corresponding MKParts appear in the MKScore. 
*/
- (void) setScore: (MKScore *) aScore
{
    if (aScore == score)
	return;
    if (status != MK_inactive)
	return;
    [self releasePartPerformers]; // also releases score
    score = [aScore retain];
    if (score != nil) {
	NSArray *partsList = [aScore parts];
        unsigned numberOfParts = [partsList count], partIndex;

        for (partIndex = 0; partIndex < numberOfParts; partIndex++) {
	    MKPartPerformer *newEl = [partPerformerClass new];
	    
	    [partPerformers addObject: newEl];
            [newEl setPart: [partsList objectAtIndex: partIndex]];
	    _MKSetScorePerformerOfPartPerformer(newEl, self);
            [newEl release]; /* Prevent leak. Retained by partPerformers */
	}
	/* Broadcast current state. */ 
	[self setFirstTimeTag: firstTimeTag];
	[self setLastTimeTag: lastTimeTag];
	[self setDuration: duration];
	[self setTimeShift: timeShift];
	[self setConductor: conductor];
    }
}

- pause
  /* Broadcasts activate message to contained MKPartPerformers. */
{
    [partPerformers makeObjectsPerformSelector: @selector(pause)];
    status = MK_paused;
    if ([delegate respondsToSelector: @selector(performerDidPause:)])
	[delegate performerDidPause: self];
    return self;
}

- resume
  /* Broadcasts activate message to contained PartPerformers. */
{
    [partPerformers makeObjectsPerformSelector: @selector(resume)];
    status = MK_active;
    if ([delegate respondsToSelector: @selector(performerDidResume:)])
	[delegate performerDidResume: self];
    return self;
}

/* There are three cases:
    	1. deactivate send to the MKScorePlayer:
		First _deactivate is invoked.  This sets status to inactive
		so there's no danger of multiple invocations of _deactivate,
		due to status check in _partPerformerDidDeactivate.
	2. MKPartPerformers all eventually deactivate themselves, due to 
		finishing the score. 
		In this case, _deactivate is sent from 
		_partPerformerDidDeactivate.
	3. MKConductor +finishPerformance is sent.
		In this case, _deactivate is sent by the Conductor.  
		Note that the Conductor also deactivates the PartPerformers.
		Here it's a race. We don't know the order that the deactivate
		messages will come in.  If the MKScorePerformer gets his first,
		the PartPerformers will be deactivated and then will ignore
		their messages from the Conductor. if the PartPerformers get
		their's first, _deactivate will be sent from 
		_partPerformerDidDeactivate: and the check in _deactivate will 
		guarantee that the delegate message isn't sent twice. Get it?
*/
    
- (void) deactivate
  /* Sends [self _deactivate], broadcasts deactivate message to 
     contained PartPerformers and sets status to MK_inactive. */
{
    [self _deactivate];
    [partPerformers makeObjectsPerformSelector: @selector(deactivate)];
}

- setFirstTimeTag: (double) aTimeTag
  /* Broadcast setFirstTimeTag: to contained PartPerformers. */
{ 
    unsigned n = [partPerformers count], i;
    
    firstTimeTag = aTimeTag;
    for (i = 0; i < n; i++)
        [[partPerformers objectAtIndex: i] setFirstTimeTag: aTimeTag];
    return self;
}		

- setLastTimeTag: (double) aTimeTag
  /* Broadcast setLastTimeTag: to contained PartPerformers. */
{
    unsigned n = [partPerformers count], i;
    lastTimeTag = aTimeTag;
    for (i = 0; i < n; i++)
        [[partPerformers objectAtIndex:i] setLastTimeTag:aTimeTag];
    return self;
}		

- (double) firstTimeTag  
  /* TYPE: Accessing time
   * Returns the value of the receiver's firstTimeTag variable.
   */
{
    return firstTimeTag;
}

- (double) lastTimeTag 
  /* TYPE: Accessing time
   * Returns the value of the receiver's lastTimeTag variable.
   */
{
    return lastTimeTag;
}

- setTimeShift: (double) aTimeShift
  /* Broadcast setTimeShift: to contained PartPerformers. */
{
    unsigned n = [partPerformers count], i;
    for (i = 0; i < n; i++)
        [[partPerformers objectAtIndex:i] setTimeShift:aTimeShift];
    timeShift = aTimeShift;
    return self;
}		

/* Broadcast setDuration: to contained MKPartPerformers. */
- setDuration: (double) aDuration
{
    unsigned n = [partPerformers count];
    unsigned int partPerformersIndex;
    
    for (partPerformersIndex = 0; partPerformersIndex < n; partPerformersIndex++) {
	MKPartPerformer *performer = [partPerformers objectAtIndex: partPerformersIndex];
        [performer setDuration: aDuration];
    }
    duration = aDuration;
    return self;
}		


- (double) timeShift 
  /* TYPE: Accessing time
   * Returns the value of the receiver's timeShift variable.
   */
{
    return timeShift;
}

- (double) duration 
  /* TYPE: Accessing time
   * Returns the value of the receiver's duration variable.
   */
{
    return duration;
}

- copyWithZone: (NSZone *) zone
  /* Copies object. This involves copying firstTimeTag and lastTimeTag. 
     The score of the new object is set with setScore:, creating a new set 
     of partPerformers. */
{ /*sb: changed a lot of this. Need to check */
    MKScorePerformer *newObj = [[MKScorePerformer allocWithZone:[self zone]] init];
    [newObj->partPerformers autorelease];
    newObj->partPerformers = nil;
    [newObj setScore:score];
    newObj->_deactivateMsgPtr = NULL;
    newObj->status = MK_inactive;
    newObj->lastTimeTag = lastTimeTag;
    newObj->firstTimeTag = firstTimeTag;
    newObj->timeShift = timeShift;
    newObj->duration = duration;
    newObj->conductor = conductor; /* no retain held to prevent retain loops */

/*
    MKScorePerformer *newObj = [super copyWithZone:zone];
    newObj->partPerformers = nil;
    [newObj setScore:score];
    newObj->_deactivateMsgPtr = NULL;
    newObj->status = MK_inactive;
#if 0
// This happens automatically
    newObj->lastTimeTag = lastTimeTag; 
    newObj->firstTimeTag = firstTimeTag;
    newObj->timeShift = timeShift;
    newObj->duration = duration;
    newObj->conductor = conductor;
    newObj->score = score;
#endif
 */
    return newObj;
}

- (void) dealloc
  /* Frees contained PartPerformers and self. */
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    if (status != MK_inactive)
      return;
    [self releasePartPerformers]; /* this includes releasing the score object */
    [partPerformers release];
    [super dealloc];
}

/* Broadcasts setConductor: to contained MKPartPerformers. */
- setConductor: (MKConductor *) aConductor
{
    if ((conductor = aConductor) == nil) 
	aConductor = [MKConductor defaultConductor];
    if (status == MK_inactive)
	conductor = aConductor;
    else
	return nil;
    [partPerformers makeObjectsPerformSelector: @selector(setConductor:) withObject: aConductor];
    return self;
}

- (MKPartPerformer *) partPerformerForPart: (MKPart *) aPart
  /* Returns the MKPartPerformer for aPart, if found. */
{
    for (MKPartPerformer *partPerformer in partPerformers) {
        if ([partPerformer part] == aPart) {
            return partPerformer;
        }
    }
    return nil;
}

- (NSArray *) partPerformers
{
    return [_MKLightweightArrayCopy(partPerformers) autorelease];
}

- (NSArray *) noteSenders
  /* TYPE: Processing
     Returns an auto-released array of the sender's MKPartPerformers' MKNoteSenders. 
     It's NOT the caller's responsibility to free the array. */
{
    NSMutableArray *anArray = [[NSMutableArray alloc] initWithCapacity:[partPerformers count]];
    void (*addImp)(id _Nonnull, SEL _Nonnull, id) = [anArray methodForSelector: @selector(addObject:)];
    
    for (MKPartPerformer *obj in partPerformers)
        (*addImp)(anArray, @selector(addObject:), [obj noteSender]);
    return [anArray autorelease];
}

- (int) status
  /* TYPE: Querying; Returns the receiver's status.
   * Returns the receiver's status as one of the
   * following values:
   *
   *  *   	Status	        Meaning
   *  *		MK_inactive	between performances
   *  *		MK_active	in performance
   *  * 	MK_paused	in performance but currently paused
   *
   * A performer's status is set as a side effect of 
   * methods such as activate and pause.
   */
{
    return (int) status;
}

- setPartPerformerClass: (Class) aPartPerformerSubclass
{
    if (!_MKInheritsFrom(aPartPerformerSubclass, [MKPartPerformer class]))
	return nil;
    partPerformerClass = aPartPerformerSubclass;
    return self;
}

- (Class) partPerformerClass
{
    return partPerformerClass;
}

@synthesize delegate;

#if 0
-setArchiveScore:(BOOL)yesOrNo
 /* Archive score when the receiver or any object pointing to the receiver
    is archived. */  
{
    archiveScore = yesOrNo;
}

-(BOOL) archiveScore
  /* Returns whether MKScore is archived when the receiver or any object 
   pointing to the receiver is archived. */
{
    return archiveScore;
}
#endif

#pragma mark - Private methods

- _partPerformerDidDeactivate: sender
{  
    MKPartPerformer *obj;
    NSInteger n, i;
    
    if (status == MK_inactive) /* No need to bother in this case. */
       	return self;
    n = [partPerformers count];
    for (i = 0; i < n; i++) {
        obj = [partPerformers objectAtIndex: i];
        if ((sender != obj) && ([obj status] != MK_inactive))
                return nil; /* One still active. */
    }
    [self _deactivate];
    return self;
}

- _deactivate
{
    /* This is needed to prevent deactivate being called twice as explained above. */
    if (status == MK_inactive)
    	return self;
    status = MK_inactive;
    _deactivateMsgPtr = MKCancelMsgRequest(_deactivateMsgPtr);
    if ([delegate respondsToSelector: @selector(performerDidDeactivate:)])
	[delegate performerDidDeactivate: self];
    return self;
}
  
@end
