#import <musickit/synthpatches/DBWave1vi.h>
#import <objc/NXStringTable.h>

#import "PerformerController.h"
#import "RandomPerformer.h"
#import <musickit/musickit.h>

#define PERFORMERS 9

static RandomPerformer *performers[PERFORMERS];
static Orchestra *theOrch;

@implementation PerformerController:Application

- showInfoPanel:sender
{
    [NXApp loadNibSection:"InfoPanel.nib" owner:self];
    [infoPanel makeKeyAndOrderFront:NXApp];
    return self; 
}

#define STRINGVAL(_x) [stringTable valueForStringKey:_x]

static void handleMKError(char *msg)
    /* Error handling routine */
{
    if ([Conductor performanceThread] == NO_CTHREAD) { /* Not performing */
	if (!NXRunAlertPanel("ScorePlayer",msg,"OK","Cancel",NULL,NULL))
	    [NXApp terminate:NXApp];
    }
    else {  
	/* When we're performing in a separate thread, we can't bring
	   up a panel because the Application Kit is not thread-safe.
	   In fact, neither is standard IO. Therefore, we use write() to
	   stderr here, causing errors to appear on the console.
	   Note that we assume that the App is not also writing to stderr.

	   An alternative would be to use mach messaging to signal the
	   App thread that there's a panel to be displayed.
	 */
	int fd = stderr->_file;
	char *str = "PerformerExample: ";
	write(fd,str,strlen(str));
	write(fd,msg,strlen(msg));
	str = "\n";
	write(fd,str,strlen(str));
    }
}

- appDidInit:sender
{
    int i;
    SynthInstrument *anIns;
    if (theOrch) /* We're already playing? */
      return self;

    /* Set function to call when a Music Kit error occurs. */
    MKSetErrorProc(handleMKError);

    /* Create the Orchestra which manages all DSP activity. */
    theOrch = [Orchestra new];

    if ([theOrch prefersAlternativeSamplingRate]) 
      [theOrch setSamplingRate:11025]; /* For slow memory DSP cards */ 

    /* Opening the Orchestra instance has the effect of claiming the DSP
       and allowing us to allocate Orchestra resources. */
    while (![theOrch open]) {               
	if (NXRunAlertPanel("PerformerExample",
			    STRINGVAL("DSPUnavailable"),
			    STRINGVAL("Quit"),
			    STRINGVAL("TryAgain"),
			    NULL) == NX_ALERTDEFAULT)
	    [self terminate:sender];
    }

    /* Create instances of our special Performers subclass. (See
       RandomPerformer.m for the definition of our subclass.) Then 
       assign a SynthInstrument and a synthesis voice (SynthPatch) to
        each. */
    for (i=0; i<PERFORMERS; i++) {

	/* Create a RandomPerformer. */
	performers[i] = [[RandomPerformer alloc] init];

        /* Create a SynthInstrument to manage SynthPatches. */
	anIns = [[SynthInstrument alloc] init];

	/* Assign the class of SynthPatch. */
	[anIns setSynthPatchClass:[DBWave1vi class]];   

	/* only one note at a time on this Instrument */
	if ([anIns setSynthPatchCount:1] != 1) {
	    NXRunAlertPanel("PerformerExample",
			    STRINGVAL("TooManyVoices"),
			    "OK",NULL,NULL);
	    [anIns free];
	    [performers[i] free];
	    performers[i] = nil;
	    break;
	}

	/* Connect our performer to the SynthInstrument. */
	[[performers[i] noteSender] connect:[anIns noteReceiver]];
	[performers[i] activate];
	[performers[i] pause];   /* Start with all paused. */
    }
    MKSetDeltaT(.75); /* Run about .75 seconds ahead of the time when the 
  			 DSP plays the sound. This gives the DSP a 
			 'cushion' and helps rhythmic steadiness. */

    /* Since all Performers may be paused, we need to tell the Conductor
       not to finish the performance if that occurs. */
    [Conductor setFinishWhenEmpty:NO];

    /* Performance will run in a separate Mach thread to allow maximum
       independence between user interface and music. */
    [Conductor useSeparateThread:YES];
    [Conductor setThreadPriority:1.0];  /* Boost priority of performance. */ 
    
    /* Start the DSP running */
    [theOrch run];				

    /* Start the performance. */
    [Conductor startPerformance];        
    return self;
}

- pauseOrResume:sender
  /* Pause or resume the selected performer */
{    
    RandomPerformer *perf;
    int curPerformerIndex = [sender selectedTag];
    perf = performers[curPerformerIndex];
    [Conductor lockPerformance];
    if ([perf status] == MK_paused)
	[perf resume];
    else [perf pause];
    [Conductor unlockPerformance];
    return self;
}

- setOctave:sender
  /* Adjust the octave of the performer */
{    
    id selectedCell = [sender selectedCell];
    int curPerformerIndex = [selectedCell tag];
    [Conductor lockPerformance];
    [performers[curPerformerIndex] setOctaveTo:[selectedCell intValue]];
    [Conductor unlockPerformance];
    return self;
}

- setSpeed:sender
  /* Adjust the speed of the performer */
{    
    id selectedCell = [sender selectedCell];
    int curPerformerIndex = [selectedCell tag];
    double val = 1.0/((double)[selectedCell floatValue]);

    /* Take inverse because slider is actually 1/rhythmicValue. */

    [Conductor lockPerformance];
    [performers[curPerformerIndex] setRhythmicValueTo:val];
    [Conductor unlockPerformance];
    return self;
}

- terminate:sender
{
    /* Clean up gracefully (not really needed) */
    [Conductor lockPerformance];
    [Conductor finishPerformance];
    [Conductor unlockPerformance];
    [theOrch close];
    [super terminate:self];
    return self;
}

@end

