/*
  $Id$
  Defined In: The MusicKit

  Description:
    Need to document that you must never free an object that was installed
    in the shared data table during a performance, even if its reference count 
    has gone to 0. You may free it after the performance.

    That's because I don't remove the mapping from the object (e.g partials
    object) to the List of sharedDataInfos.

  Original Author: David A. Jaffe
  
  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000 The MusicKit Project
*/
/* 
Modification history:

  $Log$
  Revision 1.7  2006/02/05 17:57:10  leighsmith
  Cleaned up prototypes for Xcode 2.2 as it is much more strict about mixing id with a defined type

  Revision 1.6  2002/01/29 16:05:59  sbrandon
  re-typed _MKOrchTrace calls to use NSString

  Revision 1.5  2000/10/01 06:37:16  leigh
  Changed NXHashTable functions to FoundationKit NSHashTable functions.

  Revision 1.4  2000/06/09 03:16:09  leigh
  Typed ivars

  Revision 1.3  1999/11/07 05:11:26  leigh
  Doco cleanup and removal of redundant HashTable include

  Revision 1.2  1999/07/29 01:26:01  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  11/20/89/daj - Changed to do lazy garbage collection of synth data. 
  11/17/92/daj - Minor change to shut up compiler warning
  9/25/93/daj -  Updated for new typed sharedSynthInfo
*/ 
#import "_musickit.h"
#import "UnitGeneratorPrivate.h"
#import "_SharedSynthInfo.h"
#import "OrchestraPrivate.h"

@implementation _SharedSynthInfo: NSObject

/* The shared object table is a NSMutableDictionary that hashes from id (e.g. MKPartials
object) to a NSMutableArray object. The NSMutableArray is a NSMutableArray of _SharedSynthInfos.
Each _SharedSynthInfo contains a back-pointer to the NSMutableArray. */

enum {obj, objSegment, objSegmentLength};

/* Functions for freeing just the values of the table. */

#if 0
static void freeObject (void *aList) 
{
    _SharedSynthInfo *el;
    id myList = (id)aList;
    unsigned noteIndex;

    for (noteIndex = 0; noteIndex < [myList count]; noteIndex++) {
      el = [myList objectAtIndex: noteIndex];
      [el->synthObject _setShared:nil];
    }
    [myList removeAllObjects];
    [myList release];
};
    
static void noFree (void *item) {};
#endif

id _MKFreeSharedSet(NSMutableDictionary *sharedSet, NSHashTable **garbageTable)
{
    NSEnumerator *enumerator = [sharedSet objectEnumerator];
    id myList;
    unsigned noteIndex;

    while ((myList = [enumerator nextObject])) {
        for (noteIndex = 0; noteIndex < [myList count]; noteIndex++) {
            [((_SharedSynthInfo *)([myList objectAtIndex: noteIndex]))->synthObject _setShared:nil];
        }
        [myList removeAllObjects];
    }
    [sharedSet removeAllObjects];
//    [sharedSet freeKeys:noFree values:freeObject];
    NSFreeHashTable(*garbageTable);
    *garbageTable = NULL;
    [sharedSet release];
    return nil; /* sb: nil for compatibility with old -free method */
}

NSMutableDictionary* _MKNewSharedSet(NSHashTable **garbageTable)
{
    static NSHashTableCallBacks proto = {NULL, NULL, NULL, NULL, NULL};
    // proto.free = NXNoEffectFree
    *garbageTable = NSCreateHashTable(proto, 0);
    return [[NSMutableDictionary alloc] initWithCapacity:4];
}

static void reallyRelease(_SharedSynthInfo *aSharedSynthInfo)
{
    [aSharedSynthInfo->theList removeObject:aSharedSynthInfo];
    [aSharedSynthInfo release];
}

BOOL _MKReleaseSharedSynthClaim(_SharedSynthInfo *aSharedSynthInfo, BOOL lazy)
    /* Returns YES if still in use or slated for garbage collection.
       Returns NO if it can be deallocated now. */
{
    if (--aSharedSynthInfo->referenceCount > 0)
        return YES; /* Still in use */
#   define ORCH [aSharedSynthInfo->synthObject orchestra]
    if (lazy) {
	NSHashInsert(_MKGetSharedSynthGarbage(ORCH),
		     (const void *)aSharedSynthInfo); 
	return YES;
    }
    else reallyRelease(aSharedSynthInfo);
    return NO;
}

void _MKAddSharedSynthClaim(_SharedSynthInfo *aSharedSynthInfo)
{
    aSharedSynthInfo->referenceCount++;
}

int _MKGetSharedSynthReferenceCount(_SharedSynthInfo *aSharedSynthInfo)
{
    return aSharedSynthInfo->referenceCount;
}

static id findSharedSynthInfo(id aList,MKOrchMemSegment whichSegment,int howLong,MKOrchSharedType type)
{
    register _SharedSynthInfo *el;
    unsigned noteIndex;
    BOOL test = 0; /* Initialize it to shut up compiler warning */
    int isEqualFlag = ((whichSegment == MK_noSegment) ? obj : 
			(howLong == 0) ? objSegment : objSegmentLength);
    for (noteIndex = 0; noteIndex < [aList count]; noteIndex++) {
        el = [aList objectAtIndex: noteIndex];
	switch (isEqualFlag) {
	  case obj:
	    test = YES;
	  case objSegment:
	    test = (whichSegment == (el)->segment);
	    break;
	  case objSegmentLength:
	    test = ((whichSegment == (el)->segment) && (howLong == (el)->length));
	    break;
	}
	if (test) {
	    if ((type == MKOrchestraSharedTypeNone) || (type == (el)->type))
	      return (el);
	}
    }
    return nil;
}

id _MKFindSharedSynthObj(NSMutableDictionary* sharedSet,NSHashTable *garbageTable,id aKeyObj,
			 MKOrchMemSegment whichSegment,int howLong,
			 MKOrchSharedType type)
{
    id aList = [sharedSet objectForKey:[NSValue valueWithNonretainedObject:aKeyObj]];
    id rtnVal;
    _SharedSynthInfo *aSharedSynthInfo;
    if (!aList)
      return nil;
    aSharedSynthInfo = findSharedSynthInfo(aList,whichSegment,howLong,type);
    if (!aSharedSynthInfo)
      return nil;
    rtnVal = aSharedSynthInfo->synthObject;
    if (aSharedSynthInfo->referenceCount == 0)   /* Was lazily deallocated */
      NSHashRemove(garbageTable,(const void *)aSharedSynthInfo);
    [rtnVal _addSharedSynthClaim];
    return rtnVal;
}	

BOOL _MKCollectSharedDataGarbage(id orch,NSHashTable *garbageTable)
    /* Deallocates all garbage and empties the table. */
{
    id dataObj;
    BOOL gotOne = NO;
    _SharedSynthInfo *infoObj;
    NSHashEnumerator state = NSEnumerateHashTable(garbageTable);
    if (_MK_ORCHTRACE(orch, MKTraceOrchestraAlloc)) {
        NSLog(@"MK OK\n");
        _MKOrchTrace(orch, MKTraceOrchestraAlloc,
		   @"Garbage collecting unreferenced shared data.");
    }
    while ((infoObj = (_SharedSynthInfo *) NSNextHashEnumeratorItem(&state))) {
	gotOne = YES;
	dataObj = infoObj->synthObject;
	[dataObj _setShared:nil];
	reallyRelease(infoObj);
	_MKDeallocSynthElement(dataObj,NO);
        [dataObj release];/* since we were holding the retain in the _SharedSynthInfo,
            		   * we don't release the dataObj in a -dealloc method, we do it here */
    }
    if (gotOne)
        NSResetHashTable(garbageTable);
    else if (_MK_ORCHTRACE(orch,MKTraceOrchestraAlloc))
        _MKOrchTrace(orch,MKTraceOrchestraAlloc,@"No unreferenced shared data found.");
    return gotOne;
}	

BOOL _MKInstallSharedObject(NSMutableDictionary* sharedSet,id aSynthObj,
			    id aKeyObj,MKOrchMemSegment whichSegment,
			    int howLong,MKOrchSharedType whichType)
    /* Returns NO if object is already in Set */
{
    _SharedSynthInfo *aSharedSynthInfo;
    NSMutableArray *aList = nil;
    id idKey = [NSValue valueWithNonretainedObject:aKeyObj];
    aList = [sharedSet objectForKey:idKey];
    if (!aList) {
	aList = [[NSMutableArray alloc] init];
        [sharedSet setObject:aList forKey:idKey];
        [aList release];/* retain is now held in sharedSet */
    }
    else if (findSharedSynthInfo(aList,whichSegment,howLong,whichType))
      return NO;
    aSharedSynthInfo = [_SharedSynthInfo new];
    aSharedSynthInfo->synthObject = [aSynthObj retain];
    aSharedSynthInfo->theList = aList;
    aSharedSynthInfo->theKeyObject = aKeyObj;
    aSharedSynthInfo->segment = whichSegment;
    aSharedSynthInfo->length = howLong;
    aSharedSynthInfo->type = whichType;
    aSharedSynthInfo->referenceCount = 0;
    [aList addObject:aSharedSynthInfo];
    [aSynthObj _setShared:aSharedSynthInfo];
    _MKAddSharedSynthClaim(aSharedSynthInfo);
    [aSharedSynthInfo release];
    return YES;
}

@end

