/* $Id$ */

#import "MyObject.h"
#import <MusicKitLegacy/MusicKitLegacy.h>
#import <MKSynthPatches/Pluck.h>
#import <AppKit/AppKit.h>

@implementation MyObject

static MKPart *aPart;
static MKPartPerformer *aPartPerformer;
static MKOrchestra *orch;

- init
{
    MKSynthInstrument *aSynthIns; 
    
    [super init];
    numQuarterNotes = 20;
    numEighthNotes = 20;
    numSixteenthNotes = 20;
    numPitchesEnabled = 5;
    tempo = 60;
    pitchMode[0] = 1; pitchMode[2] = 1; pitchMode[4] = 1; pitchMode[7] = 1;
    pitchMode[9] = 1;
    aPart = [[MKPart alloc] init];
    orch = [MKOrchestra new];
    aSynthIns = [[MKSynthInstrument alloc] init];
    MKSetDeltaT(.5);     /* Let Conductor run .5 seconds ahead. */
    aPartPerformer = [[MKPartPerformer alloc] init];
    [aSynthIns setSynthPatchClass: [Pluck class]];
    [[aPartPerformer noteSender] connect: [aSynthIns noteReceiver]];
    [MKConductor setFinishWhenEmpty: YES];
    return self;
}

- setNumQuarterNotes:sender
{
    numQuarterNotes = [sender intValue];
    return self;
}

- setNumEighthNotes:sender
{
    numEighthNotes = [sender intValue];
    return self;
}

- setNumSixteenthNotes:sender
{
    numSixteenthNotes = [sender intValue];
    return self;
}

- setTempoFrom:sender
{
    tempo = [sender doubleValue];
    if ([MKConductor inPerformance])
      [[MKConductor defaultConductor] setTempo:tempo];
    return self;
}

- setMode:sender
{
    int whichCell = [sender selectedRow];
    int isEnabled = [[sender selectedCell] intValue];
    pitchMode[whichCell] = isEnabled;
    if (isEnabled)
    	numPitchesEnabled++;
    else numPitchesEnabled--;
    return self;
}

static double ranNum()
    /* Returns a random number between 0 and 1. */
{
#   define   RANDOMMAX (double)((long)MAXINT)
    return ((double)random()) / RANDOMMAX;
 }

- compute:sender
{
#   define BASE_KEY_NUM 40
    id aNote;
    int i,j,k,l,keyNum;
    double x,time,rhythm;
     
    if ([MKConductor inPerformance]) {
      NSRunAlertPanel(@"example4",
		      @"First stop the performance before computing new notes.",
		      @"OK",NULL,NULL);
      return self;
    }
    if (numPitchesEnabled == 0)
        return self;
    i=0;
    j=0;
    k=0;
    time = 0;
    [aPart freeNotes];       /* Just empty old part. */
    while(i<numEighthNotes || j<numSixteenthNotes || k<numQuarterNotes) {
	x = ranNum();
	if (x > .666) {
		if (i++>=numEighthNotes)
			continue;
		rhythm = 0.5;

	} else if (x > .333) {
		if (j++>=numSixteenthNotes)
			continue;
		rhythm = 0.25;
	} else { 
		if (k++>=numQuarterNotes)
			continue;
		rhythm = 1.0;
	}
	keyNum = -1;
	do {
		l = (int)(ranNum() * 11.999);
		if (pitchMode[l]) 
			keyNum = l + BASE_KEY_NUM;
	} while (keyNum == -1);
	aNote = [[MKNote alloc] init];
	[aNote setDuration:rhythm];
	[aNote setTimeTag:time];
	time += rhythm;
	[aNote setPar:MK_keyNum toInt:keyNum];
	[aPart addNote:aNote];
    }
    return self;
}

/* Invoked by the Conductor when performance finishes. */
- endOfTime
{
   [orch close];
   [startStopButton setState:0];
   return self; 
}

/* Toggle play/stop */ 
- play:sender
{
    if ([MKConductor inPerformance]) {
      [MKConductor finishPerformance];
      return self;
    }
    if (![orch open]) {
      NSRunAlertPanel(@"example4", @"Can't open DSP.", @"OK", NULL, NULL);
      return nil;
    }
    [aPartPerformer setPart: aPart];
    [aPartPerformer activate];
    [[MKConductor defaultConductor] setTempo:tempo];
    [MKConductor afterPerformanceSel: @selector(endOfTime) to: self argCount: 0];
    [orch run];
    [MKConductor startPerformance];
    return self;
}


@end
