
/* Generated by Interface Builder */

#import "Controller.h"
#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>
#import <MusicKit/MusicKit.h>
#import "FluteIns.h"
#import <math.h>

#define MINLENGTH 30
#define MAXLENGTH 71
#define MAXD2LENGTH 38

static MKNote *theNote,*theNoteOff,*theNoteUpdate;
static MKOrchestra *theOrch;
static MKSynthInstrument *theIns;
static MKMidi *midiIn;

@implementation Controller

- play:sender
{
    int		MY_outAmp = [[MKNote class] parName: "MY_outAmp"];
    int		MY_dLineLength = [[MKNote class] parName: "MY_dLineLength"];
    int		MY_noiseVolume = [[MKNote class] parName: "MY_noiseVolume"];
    double xAmpArray[] = {0.0,0.2,1.0,2.0}; 
    double yAmpArray[] = {0.0,0.0,1.0,0.0};
    id ampEnvelope;

    if ([sender state] == 1)	{

        if (! theNote) 	{
  	    theNote = [MKNote new];			
	    theNoteUpdate = [MKNote new];
	    theNoteOff = [MKNote new];
            theIns = [MKSynthInstrument new];
            theOrch = [MKOrchestra new];          
	    [theOrch setSamplingRate: 22050.0];
	    ampEnvelope = [MKEnvelope new];
	    [ampEnvelope setPointCount:4 xArray:xAmpArray yArray:yAmpArray];
	    [ampEnvelope setStickPoint:2];
	
    	    midiIn = [MKMidi new];
//	    [myMidiHandler init];
	    [[midiIn channelNoteSender:1] connect:[myMidiHandler noteReceiver]];
//	    [[myMidiFilter noteSender] connect:[synthIns noteReceiver]];
	    [midiIn openInputOnly];

	    [theNote setNoteType:MK_noteOn]; 	
	    [theNote setNoteTag:MKNoteTag()];      
	    [theNoteUpdate setNoteType:MK_noteUpdate]; 
	    [theNoteUpdate setNoteTag:[theNote noteTag]]; 
	    [theNoteOff setNoteType:MK_noteOff]; 
	    [theNoteOff setNoteTag:[theNote noteTag]]; 
	    MKSetDeltaT(.01) ;           
	    [MKOrchestra setFastResponse:YES]; 
	    [MKOrchestra setTimed:NO]; 
	     if (![theOrch open]) {               
	    fprintf(stderr,"Can't open DSP. Perhaps some other process has it.\n");
		exit(1);
	    }
	    [theIns setSynthPatchClass:[FluteIns class]];   
	    [theIns setSynthPatchCount:1];	
	    [MKConductor setFinishWhenEmpty:NO];
//	[Conductor useSeparateThread:YES];
//	[Conductor setThreadPriority:1.0];     /* Boost priority of performance */
	    [theOrch run];				
             [midiIn run];
	    [MKConductor startPerformance];    
	    [MKConductor lockPerformance];	     /* Prepare to send MK message */
	    [theNote setPar:MK_portamento toDouble: 0.5];   
	    [theNote setPar:MK_ampEnv toEnvelope:ampEnvelope];
    	    [theNoteUpdate setPar:MK_amp1 toDouble: 0.5];  

	    [theNote setPar:MY_outAmp toDouble: 0.2];
	    [theNote setPar:MY_dLineLength toDouble: MINLENGTH];

	    [theNote setPar:MY_noiseVolume toDouble: 0.05];  

	    [[theIns noteReceiver] receiveNote:theNote];
	    [MKConductor unlockPerformance];

        }	
    }
    else	{
        [MKConductor lockPerformance];
	[[theIns noteReceiver] receiveNote:theNoteOff];
	[theNote free];
	[theNoteUpdate free];
	[theNoteOff free];
	[MKConductor finishPerformance];       
	[MKConductor unlockPerformance];
    }
    return self;
}

- changeVelocity: (double) velocity;
{
    int		MY_envelopeSlew = [[MKNote class] parName: "MY_envelopeSlew"];
    double temp;
    [MKConductor lockPerformance];
    temp = (velocity - 128.0) / 128.0;
    [theNoteUpdate setPar:MY_envelopeSlew toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeAmps:sender
{
    int		MY_outAmp = [[MKNote class] parName: "MY_outAmp"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = [[sender cellAt: 0 : 0] doubleValue];
    [[ampPots cellAt: 0 : 0] setDoubleValue: temp];
    [theNoteUpdate setPar:MK_amp1 toDouble: temp];  
    temp = [[sender cellAt: 1 : 0] doubleValue];
    [[ampPots cellAt: 1 : 0] setDoubleValue: temp];
    [theNoteUpdate setPar:MY_outAmp toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeAmpsQuick: (double) inValue : (double) outValue
{
    int		MY_outAmp = [[MKNote class] parName: "MY_outAmp"];
        
    [MKConductor lockPerformance];
    [theNoteUpdate setPar:MK_amp1 toDouble: inValue];  
    [theNoteUpdate setPar:MY_outAmp toDouble: outValue];  
    [[ampFields cellAt: 0 : 0] setDoubleValue: inValue];
    [[ampFields cellAt: 1 : 0] setDoubleValue: outValue];
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeSlide:sender
{
    int		MY_dLineLength = [[MKNote class] parName: "MY_dLineLength"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = [sender doubleValue];
//    printf("Slide length is: %f\n",temp);
    temp = MINLENGTH + (MAXLENGTH - MINLENGTH) * temp;
    [theNoteUpdate setPar:MY_dLineLength toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeSlideQuick: (double) value
{
    int		MY_dLineLength = [[MKNote class] parName: "MY_dLineLength"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = value;
    temp = MINLENGTH + (MAXLENGTH - MINLENGTH) * temp;
    [theNoteUpdate setPar:MY_dLineLength toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeEmbouchure:sender
{
    int		MY_delay2Length = [[MKNote class] parName: "MY_delay2Length"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = [sender doubleValue];
//    printf("Embouchure is: %f\n",temp);
    temp = 1.0 - temp;
    [theNoteUpdate setPar:MY_delay2Length toDouble: temp * MAXD2LENGTH];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeEmbouchureQuick:(double) value;
{
    int		MY_delay2Length = [[MKNote class] parName: "MY_delay2Length"];
    double temp;

    [MKConductor lockPerformance];
    temp = value;
    [theNoteUpdate setPar:MY_delay2Length toDouble: temp * MAXD2LENGTH];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeNoiseVolume:sender
{
    int		MY_noiseVolume = [[MKNote class] parName: "MY_noiseVolume"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = [sender doubleValue];
    [[ampPots cellAt: 2 : 0] setDoubleValue: temp];
    [theNoteUpdate setPar:MY_noiseVolume toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- changeNoiseVolumeQuick:(double) value;
{
    int		MY_noiseVolume = [[MKNote class] parName: "MY_noiseVolume"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = value;
    [[ampPots cellAt: 2 : 0] setDoubleValue: temp];
    [theNoteUpdate setPar:MY_noiseVolume toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

@end
