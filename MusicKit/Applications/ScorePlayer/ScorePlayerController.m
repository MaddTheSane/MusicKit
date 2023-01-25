/*
 $Id$  
 
 Description:
 This is NOT a good programming example.  It is full of special-purpose
 hacks, some of which have only historical significance.  Please see
 MusicKit/Examples for good examples of how to use the MusicKit.
 
 Original Author: David A. Jaffe
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Addition of timecode and Intel support copyright David A. Jaffe, 1992
 Portions Copyright (c) 1999-2004 The MusicKit Project
 */
/*
 Modification history prior to commitment to CVS:
 
 8/9/90/daj - Changed to allow abort on all alert panels.
 8/9/90/daj - Changes for thread safety.
 8/14/90/daj - Added setuid(getuid())
 8/18/90/daj - Increased deltaT to .75 from .5.  Especially in view of the
 -open bug (the buffers don't seem to be filling properly)
 this is probably a good idea.
 8/20/90/daj - Added automatic tempo adjustment when falling out of real 
 time.
 This required starting the tempo animation at the start of 
 the performance.
 10/8/90/daj - Changed to make automatic tempo adjustment NOT the default.
 1/25/91/daj - Changed to use scrolling alert panel for Music Kit messages.
 4/24/91/daj - Changed to not complain if there's no part info or no
 synthpatch in the part info.
 4/26/91/daj - More work on the damn alert panel stuff.
 8/22/91/daj - Localized.
 6/06/92/daj - Added resetting of tuning system before reading a new file.
 10/21/92/daj - Various fixes.
 9/28/94/daj - Changes for Intel support.
 */   

#import <AppKit/AppKit.h>
#import <Foundation/NSBundle.h>
#import <MusicKit/MusicKit.h>

#import "ErrorLog.h"
#import "MKAlert.h"
#import "ScorePlayerController.h"

@implementation ScorePlayerController

static NSMutableArray *synthInstruments;
static NSOpenPanel *openPanel;
static NSString *fileName, *shortFileName;
static MKScore *scoreObj;
static MKScorePerformer *scorePerformer;
static MKOrchestra *theOrch;
static double headroom = .1;
static BOOL userCancelFileRead = NO;
static NSString *errMsg;
static double initialTempo = 60.0;
static double lastTempo = 60.0;
static double desiredTempo = 60.0;
static NSArray *openFileExtensions;
static NSString *dir = nil;
static BOOL messageFlashed = NO;
static BOOL isLate = NO;
static BOOL wasLate = NO;
// MIDI management
static NSString *defaultMidiDeviceName;
static NSMutableDictionary *playingMidiDevices;
static MKSamplePlayerInstrument *nonSynthInstrument = nil;
static int midiOffset;
// MTC sync
static BOOL synchToTimeCode = NO;
static NSString *timeCodeDevice;
static MKMidi *timeCodeMIDIDevice = nil;

static unsigned capabilities;
static double samplingRate;
static id mySelf; // Keeps self available for C functions.
static NSTimer *tempoAnimator = nil;

static NSString *outputFilePath; /* Complete output file path */
static NSString *outputFileDir;	 /* Just the directory */
static NSString *outputFileName; /* Just the name */

static BOOL DSPCommands = NO;
static BOOL writeData = NO;

/* The following added based on Ensemble's version of the same. */
/* Scores can be saved as Scorefiles, Midi files, or DSPCommands files */

enum _fileType {NO_TYPE = -1, SCORE_FILE, PLAYSCORE_FILE, MIDI_FILE, DSP_COMMANDS_FILE, SOUND_FILE};
static enum _fileType saveType = NO_TYPE;
static enum _fileType scoreForm = NO_TYPE;

static NSArray *fileIcons;
static NSArray *fileTypes;
static NSArray *saveFileExtensions;

static NSButton *accessoryView = nil;
static NSSavePanel *savePanel = nil;
static NSString *soundFile = nil;

static int warnedAboutSrate = NO;
static NSDate *lastModifyTime;

static ErrorLog *errorLog;
static BOOL errorDuringPlayback = NO;

#if m68k
#define SOUND_OUT_PAUSE_BUG 1 /* Workaround for problem synching MIDI to DSP */
#endif


/* Localizable strings */
#define STR_SCOREPLAYER NSLocalizedString(@"ScorePlayer", "Name of program")

#define STR_SCOREPLAYER_ERROR NSLocalizedString(@"ScorePlayer Error", "ScorePlayer error alert panel name.")

#define STR_OK NSLocalizedString(@"OK", "OK button name")

#define STR_CANCEL NSLocalizedString(@"Cancel", "Cancel button name")

#define STR_FILE_CHANGED NSLocalizedString(@"File has changed. Reread it?", "This message appears when the user attempts to play a file, but that file has changed.")

#define STR_YES NSLocalizedString(@"Yes", "Yes button name")

#define STR_NO NSLocalizedString(@"No", "No button name")

#define STR_NO_FILE_OPEN NSLocalizedString(@"No file open.", "This message appears when the user asks to edit a file but no file is open. Also used as title of main window when no file is open.")

#define STR_NO_SETTINGS NSLocalizedString(@"The selected device has no user-settable settings.", "This message appears when the user asks to set settings of a sound out device for which there is no settings panel.")

#define STR_EDIT_CANT_OPEN_FILE NSLocalizedString(@"Can't open file for editing.", "This message appears if the user tries to edit a file but that file can't be opened.")

#define STR_READING NSLocalizedString(@"Reading %@...", "This message appears when a file is being read.  It takes one argument which follows the message. E.g. 'Reading x.score...'")

#define STR_HUNG_DSP NSLocalizedString(@"No response from DSP--aborting", "Hung DSP msg")

#define STR_FIX_ERRORS NSLocalizedString(@"Fix scorefile errors and try again.", "This message appears after the user aborts a scorefile parse due to errors.")

#define STR_BAD_SRATE NSLocalizedString(@"Sampling rate must be 44100 or 22050 for the NeXT DACs--using default of 22050.", "This message appears if the scorefile specifies an illegal sampling rate.")

#define STR_BAD_SSI_SRATE NSLocalizedString(@"Requested sampling rate not supported by the specified serial port device.", "This message appears if the scorefile specifies an illegal sampling rate for SSI device.")

#define STR_ERRORS NSLocalizedString(@"There were errors during playback.\nClick the \"Show Errors\" menu item to view them.", "This message appears after a file is played if errors occurred during playback")

#define STR_CANT_OPEN_DSP NSLocalizedString(@"Can't open DSP. Perhaps another application has it.", "This message appears if the DSP is busy.")

#define STR_INFO_MISSING NSLocalizedString(@"%@ info missing.", "This message takes one leading argument, the name of a scorefile part.  It appears when a part is declared with no info.")

#define STR_NO_SYNTHPATCH NSLocalizedString(@"This scorefile calls for a synthesis instrument (%@) that isn't available in this application.", "This message appears if a SynthPatch is specified in the scorefile for which no SynthPatch can be found.  Its one argument is the name of the SynthPatch.")

#define STR_CONTINUE NSLocalizedString(@"Continue", "Continue button name")

#define STR_PLAYING NSLocalizedString(@"Playing %@...", "This message appears when a file is being played.  The trailing argument is the name of the file.")

#define STR_TOO_MANY_SYNTHPATCHES NSLocalizedString(@"Could only allocate %ld instead of %ld %@s for %@", "This message apepars when too many Synthpatches are requested in the scorefile for a given part. There are four arguments, which must appear in the following order: 1 = the number of patches that could be allocated, 2 = number of patches that were requested to be allocated, 3 = the name of the synthpatch specified in the scorefile and 4 = the part name")

#define STR_SCOREFILE NSLocalizedString(@"Score File", "This appears in the SaveAs... panel")

#define STR_PLAYSCOREFILE NSLocalizedString(@"Playscore File", "This appears in the SaveAs... panel")

#define STR_MIDIFILE NSLocalizedString(@"MIDI File", "This appears in the SaveAs... panel")

#define STR_DSPFILE NSLocalizedString(@"DSPCommands File", "This appears in the SaveAs... panel")

#define STR_SOUNDFILE NSLocalizedString(@"Sound File", "This appears in the SaveAs... panel")

#define STR_CANT_OPEN_MIDI NSLocalizedString(@"Can't open MIDI driver port for MIDI. Perhaps another application has it.", "This message appears if the serial port is busy.")

- (void)showConductorDidSeek
{
    [timeCodeTextField setStringValue: @"Time code running"];
}

- (void)showConductorWillSeek
{
    [timeCodeTextField setStringValue: @"Time code starting..."];
}

- (void)showConductorDidReverse
{
    [timeCodeTextField setStringValue: @"Time code running backwards"];
}

- (void)showConductorDidPause
{
    [timeCodeTextField setStringValue: @"Time code stopped.  Waiting for time code to start"];
}

- (void)showConductorDidResume
{ 
    [timeCodeTextField setStringValue: @"Time code running"];
}

- (IBAction) showErrorLog: sender
{
    [errorLog show]; 
}

- (void)runAlert: (NS_RELEASES_ARGUMENT NSString *) text
{
    [errorLog addText: text];
    [text release];
    errorDuringPlayback = YES;
}

static void handleMKError(NSString *msg)
{
    if (![MKConductor inPerformance]) {
        [errorLog addText: msg];
	if (!mkRunAlertPanel(STR_SCOREPLAYER_ERROR, msg, STR_OK, STR_CANCEL, NULL)) {
            MKSetScorefileParseErrorAbort(0);
            userCancelFileRead = YES;         /* A kludge for now. */
        }
    }
    else {
        [MKConductor sendMsgToApplicationThreadSel: @selector(runAlert:)
                                                to: mySelf
                                          argCount: 1, [msg copy]];
    }
}

static void setFileTime(void)
{
    NSDictionary *fattrs;
    
    if (scoreForm == PLAYSCORE_FILE)
        return;
    
    fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath: fileName error: NULL];
    lastModifyTime = [[fattrs objectForKey:NSFileModificationDate] retain];
}

// Return YES if we should re-read the score file.
static BOOL needToReread(void)
{
    NSDictionary *fattrs;
    NSDate *fileModifyTime;
    BOOL reread;
    
    if (scoreForm == PLAYSCORE_FILE)
        return NO;
    fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath: fileName error: NULL];
    fileModifyTime = [fattrs objectForKey: NSFileModificationDate];
    reread = ([fileModifyTime compare: lastModifyTime] == NSOrderedDescending);
    [lastModifyTime release];
    lastModifyTime = [fileModifyTime retain];
    return reread;
}

// These are the class names.
// All should be replaced with sound output device names list determined dynamically.
#define  NEXT_SOUND @"NeXT Sound"
#define  DAI2400 @"StealthDAI2400"
#define  AD64x @"SSAD64x"
#define  PROPORT @"ArielProPort"
#define  GENERIC @"Default sound device"  // @"DSPSerialPortDevice"

/* Should figure a way to get rid of these case statements! */

- (void) setSoundOutDevice: (NSString *) soundOutputName
{
    warnedAboutSrate = NO;
    soundOutDeviceName = [soundOutputName retain];
    [serialPortDeviceNameField setStringValue: soundOutputName];
    /* Run alert panel here if we're playing? FIXME */
}

+ (NSString*)scoreFileEditorAppName
{
    return @"TextEdit";
}

/* Invoked by U.I. */
- (IBAction) setSoundOutFrom: sender
{
    NSString *selectedDevice = [sender titleOfSelectedItem];
    
    if ([soundOutDeviceName isEqualToString: selectedDevice])
	return;
    if ([selectedDevice isEqualToString: NEXT_SOUND] && (!([theOrch capabilities] & MKOrchestraCapabilitiesHostSoundOut))) {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = STR_SCOREPLAYER;
	alert.informativeText = @"NeXT sound not supported on this architecture";
	[alert runModal];
	[alert release];
	[soundOutputDevicePopUp selectItemWithTitle: soundOutDeviceName];
	return;
    }
    [self setSoundOutDevice: selectedDevice];
}

- (IBAction) saveAsDefaultDevice: sender
{
    MKOrchestraCapabilities caps = [theOrch capabilities];
    if (caps & MKOrchestraCapabilitiesHostSoundOut) {
        NSDictionary *pdi =
        [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
        NSMutableDictionary *pdm = [[pdi mutableCopy] autorelease];
        
        [pdm setObject: soundOutDeviceName forKey: @"MKOrchestraSoundOut"];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName: NSGlobalDomain];
        [[NSUserDefaults standardUserDefaults] setPersistentDomain: pdm forName: NSGlobalDomain]; 
	
    }
    if (caps & MKOrchestraCapabilitiesNeXTCompatibleDSPPort)
        if (![soundOutDeviceName isEqualToString: NEXT_SOUND]) {
            NSDictionary *pdi = [[NSUserDefaults standardUserDefaults] persistentDomainForName: NSGlobalDomain];
            NSMutableDictionary *pdm = [[pdi mutableCopy] autorelease];
	    
            [pdm setObject: soundOutDeviceName forKey: @"MKDSPSerialPortDevice0"];
            [[NSUserDefaults standardUserDefaults] removePersistentDomainForName: NSGlobalDomain];
            [[NSUserDefaults standardUserDefaults] setPersistentDomain: pdm forName: NSGlobalDomain]; 
        }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) deviceSpecificSettings: sender
{
    if ([soundOutDeviceName isEqualToString: DAI2400]) {
	if (!StealthDAI2400Panel) {
	    [NSBundle loadNibNamed: @"StealthDAI2400" owner: self];
	}
	[StealthDAI2400Panel makeKeyAndOrderFront: self];
    }
    else if ([soundOutDeviceName isEqualToString: AD64x]) {
        if (!SSAD64xPanel) {
	    [NSBundle loadNibNamed: @"SSAD64x" owner: self];
	}
	[SSAD64xPanel makeKeyAndOrderFront: self];
    }
    else if ([soundOutDeviceName isEqualToString: NEXT_SOUND]) {
	if (!NeXTDACPanel) {
	    [NSBundle loadNibNamed:@"NextDACs" owner:self];
	}
	[NeXTDACPanel makeKeyAndOrderFront:self];
    }
    else {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = STR_SCOREPLAYER;
	alert.informativeText = @"No special settings for this device";
	[alert runModal];
    }
}

// - (void) setOrchestraVolume: (id) sender
- (IBAction) setNeXTDACVolume:sender
{
    [[[theOrch audioProcessorChain] postFader] setAmp: [sender floatValue] clearingEnvelope: NO];
}

- (IBAction)setNeXTDACMute:sender
{
    [Snd setMute:[sender intValue]];
}

- (IBAction)getNeXTDACCurrentValues:sender
{
    float l = [[[theOrch audioProcessorChain] postFader] amp];
    [NeXTDacVolumeSlider setFloatValue: l];
    [NeXTDacMuteSwitch setIntValue: [Snd isMuted]];
}

- (IBAction) setAD64xConsumer: (id) sender
{
    
}

- (IBAction) setAD64xProfessional: (id) sender
{
    
}

- (IBAction) setDAI2400CopyProhibit: (id) sender
{
    
}

 - (IBAction) setDAI2400Emphasis: (id) sender
{
    
}

- (IBAction) openEditFile: sender
{
    NSString *editor;
    
    if (!fileName) {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = STR_SCOREPLAYER;
	alert.informativeText = STR_NO_FILE_OPEN;
	[alert runModal];
	[alert release];
	return;
    }
    editor = [ScorePlayerController scoreFileEditorAppName];
    if ([editor length] == 0) {
	if (![[NSWorkspace sharedWorkspace] openFile: fileName]) {
	    NSAlert *alert = [[NSAlert alloc] init];
	    alert.messageText = STR_SCOREPLAYER;
	    alert.informativeText = STR_EDIT_CANT_OPEN_FILE;
	    [alert runModal];
	    [alert release];
	}
    }
    else {
	if (![[NSWorkspace sharedWorkspace] openFile: fileName withApplication: editor]) {
	    NSAlert *alert = [[NSAlert alloc] init];
	    alert.messageText = STR_SCOREPLAYER;
	    alert.informativeText = STR_EDIT_CANT_OPEN_FILE;
	    [alert runModal];
	    [alert release];
	}
    }
}

static int fileType(NSString *name)
/* return the file type for the specified name */
{
    NSString *ext = [name pathExtension];
    
    if ([[MKScore midifileExtensions] indexOfObject: ext] != NSNotFound)
        return MIDI_FILE;
    else if ([ext caseInsensitiveCompare:@"playscore"] == NSOrderedSame)
        return PLAYSCORE_FILE;
    // TODO: [[Snd fileExtensions] indexOfObject: ext] != NSNotFound
    else if ([ext caseInsensitiveCompare:@"snd"] == NSOrderedSame)
        return (soundFile && [soundFile length]) ? SOUND_FILE : DSP_COMMANDS_FILE;
    return SCORE_FILE;
}

// Menu Item update method selectively enabling the editing of scores and saving files.
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
    BOOL validFileNameAndObject = fileName && [fileName length] && scoreObj;
    
    if([[menuItem title] isEqualToString: @"Edit Scorefile..."])
        return validFileNameAndObject && scoreForm == SCORE_FILE;
    if([[menuItem title] isEqualToString: @"Save As..."])
        return validFileNameAndObject;
    // TODO: surely this is more valid?
    // return [super validateMenuItem: menuItem];
    return YES;
}

- (BOOL) setFile
{
    MKTuningSystem *tuningSys;
    MKNote *scoreInfo;
    MKScore *loadResult = nil;
    
    MKSetScorefileParseErrorAbort(10);
    /* Can this every happen? */
    if (!fileName || ![fileName length]) {
        [theMainWindow setTitle: STR_NO_FILE_OPEN];
        return NO;
    }
    scoreForm = fileType(fileName);    // determine what sort of file we are reading.
    setFileTime();
    scoreObj = [MKScore score];
    [theMainWindow setTitle: [NSString stringWithFormat: STR_READING, shortFileName]];
    [playButton setEnabled: NO];
    tuningSys = [[MKTuningSystem alloc] init]; /* 12-tone equal tempered */
    [tuningSys install];
    [tuningSys release];
    userCancelFileRead = NO;
    if (scoreForm == MIDI_FILE) {
        BOOL success = [scoreObj readMidifile: fileName];
        if (success) {
            loadResult = scoreObj;
        }
    } else {
        loadResult = [scoreObj readScorefile: fileName];
    }
    if (!loadResult || userCancelFileRead) {
	/* Error in file? */
        if (!userCancelFileRead) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = STR_SCOREPLAYER;
            alert.informativeText = STR_FIX_ERRORS;
            [alert runModal];
            [alert release];
        }
	scoreObj = nil;
        [fileName release];
	fileName = [@"" retain];
	[theMainWindow setTitle: STR_SCOREPLAYER];
	[playButton setEnabled: YES];
	return NO;
    }
    samplingRate = [theOrch defaultSamplingRate];
    headroom = .1;
    initialTempo = 60.0;
    [[MKConductor defaultConductor] setTempo: initialTempo];
    scoreInfo = [scoreObj infoNote];
    if (scoreInfo) { /* Configure performance as specified in info. */ 
	int midiOffsetPar;
	midiOffset = 0;
	midiOffsetPar = [MKNote parTagForName: @"midiOffset"];
	if ([scoreInfo isParPresent: midiOffsetPar])
	    midiOffset = [scoreInfo parAsDouble: midiOffsetPar];
	if ([scoreInfo isParPresent: MK_headroom])
            headroom = [scoreInfo parAsDouble: MK_headroom];	  
	if ([scoreInfo isParPresent: MK_alternativeSamplingRate] &&
	    [theOrch prefersAlternativeSamplingRate])
            samplingRate = [scoreInfo parAsDouble: MK_alternativeSamplingRate];
	else if ([scoreInfo isParPresent: MK_samplingRate]) 
            samplingRate = [scoreInfo parAsDouble: MK_samplingRate];
	if ([scoreInfo isParPresent: MK_tempo]) {
	    initialTempo = [scoreInfo parAsDouble: MK_tempo];
	    [[MKConductor defaultConductor] setTempo: initialTempo];
	} 
	if ([soundOutDeviceName isEqualToString: NEXT_SOUND]) {
#if SOUND_OUT_PAUSE_BUG
	    if (samplingRate == 22050)
                midiOffset +=  .36363636363636/8.0;
	    else midiOffset += .181818181818181/8.0;
#else
	    if (samplingRate == 22050)
                midiOffset +=  .36363636363636;
	    else midiOffset += .181818181818181;
#endif
	}
	/* Note: there is a .1 second indeterminacy (in the 22khz case) due 
	    to not knowing where we are in soundout buffering. Using more, 
	    but smaller buffers would solve this. */
    }
    lastTempo = desiredTempo = initialTempo;
    [tempoSlider setFloatValue: 0.0];
    [tempoTextField setFloatValue: initialTempo];
    [theMainWindow setTitle: shortFileName];
    [playButton setEnabled: YES];
    [scoreObj retain];  // yep, keep it.
    return YES;
}


-_enableMTCControls:(BOOL)yesOrNo
{
    [timeCodeButton setEnabled: yesOrNo];
    [timeCodePortMatrix setEnabled: yesOrNo];
    if (yesOrNo) 
        [timeCodeTextField setStringValue:
            (synchToTimeCode) ? @"Press Play, then start time code" : @"Press button above to enable time code"];
    if (!synchToTimeCode)
        [timeCodeTextField setEnabled: yesOrNo];
    else 
        [timeCodeTextField setEnabled: YES];
    return self;
}

static BOOL setUpFile(NSString *workspaceFileName);

- endOfTime	// called by the MusicKit thread
{
    NSEnumerator *midiDevEnumerator = [playingMidiDevices objectEnumerator];
    MKMidi *midiDev;
    
    [theOrch close]; /* This will block! */
    while ((midiDev = [midiDevEnumerator nextObject])) {
	[midiDev close];
    }
    if (DSPCommands) {
	DSPCommands = NO;
	[theOrch setOutputCommandsFile: NULL];
    }
    else if (writeData) {
	writeData = NO;
	[theOrch setOutputSoundfile: NULL];
    }
    [theOrch setHostSoundOut: [soundOutDeviceName isEqualToString: NEXT_SOUND]];
    [tempoAnimator invalidate];
    [tempoAnimator release];
    tempoAnimator = nil;
    [playButton setState: NSOffState];
    [tooFastErrorMsg setTextColor: [NSColor lightGrayColor]];
    [tooFastErrorMsg setBackgroundColor: [NSColor lightGrayColor]];
    if (errorDuringPlayback && ![errorLog isVisible]) {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = STR_SCOREPLAYER;
	alert.informativeText = STR_ERRORS;
	[alert runModal];
	[alert release];
    }
    messageFlashed = NO;
    isLate = NO;
    wasLate = NO;
    errorDuringPlayback = NO;
    [theMainWindow setTitle: shortFileName];
    [soundSavePanel close];
    [self _enableMTCControls: YES];
    return self;
}

#if 0  /*sb: as this is never called */
void *endOfTimeProc(msg_header_t *msg,ScorePlayerController *myself )
{
    [tempoAnimator invalidate];
    [myself->playButton setImage: playImage];
    [myself->playButton display];
    [myself->tooFastErrorMsg setTextColor:[NSColor lightGrayColor]];
    [myself->tooFastErrorMsg setBackgroundColor:[NSColor lightGrayColor]];
    if (errorDuringPlayback && ![errorLog isVisible])
	NSRunAlertPanel(STR_SCOREPLAYER, STR_ERRORS, STR_OK, nil, nil);
    messageFlashed = NO;
    isLate = NO;
    wasLate = NO;
    errorDuringPlayback = NO;
    [myself->theMainWindow setTitle: shortFileName];
    [myself->soundSavePanel close];
    [myself->dspCommandsSavePanel close];
    [myself _enableMTCControls: YES];
    return myself;
}
#endif

/* Accepts all MIDI device namings */
static BOOL isMIDIInstrumentName(NSString *synthPatchName)
{
    return synthPatchName && [synthPatchName hasPrefix: @"midi"];
}

#if SOUND_OUT_PAUSE_BUG

static BOOL checkForMidi(MKScore *obj)
{
    NSArray *subobjs = [obj parts];
    int i, cnt;
    MKNote *info;
    
    if (!subobjs)
	return NO;
    cnt = [subobjs count];
    for (i = 0; i < cnt; i++) {
	info = [(MKPart *)[subobjs objectAtIndex: i] infoNote];
	if ([info isParPresent: MK_synthPatch] &&
	    (isMIDIInstrumentName([info parAsStringNoCopy: MK_synthPatch]))) {
	    return YES;
	}
    }
    return NO;
}
#endif

static double tempoExponent = 1.5;

/* scales the initial tempo by the current slider value (-1,1) */
static double getTempo(float val)
{
    val = pow(tempoExponent,val);
    return initialTempo * val;
}

/* reverses above mapping */
static double getUntempo(float tempoVal)
{
    return log(tempoVal/initialTempo) / log(tempoExponent);
}

#define ANIMATE_DIFF_THRESHOLD 1.0
#define ANIMATE_INCREMENT 0.3

- (void) startMidi
{
    NSEnumerator *midiDevEnumerator = [playingMidiDevices objectEnumerator];
    
    for (MKMidi *midiDev in midiDevEnumerator) {
	if ([midiDev openOutputOnly]) {	// set the localDeltaT time offset, negative values are for orchestras
	    if (midiOffset > 0) 
		[midiDev setLocalDeltaT: midiOffset];
	    else if (midiOffset < 0)
		[theOrch setLocalDeltaT: -midiOffset];
	    // NSLog(@"About to run %@\n", midiDev);
	    [midiDev run];
	}
	else {
	    mkRunAlertPanel(STR_SCOREPLAYER_ERROR, STR_CANT_OPEN_MIDI, STR_OK, STR_CANCEL, NULL);
	}
    }
}

- (void) startPlay
{
    NSInteger partCount, synthPatchCount, voices, i;
    NSString *msg = nil;
    double actualSrate;  
    NSArray *partPerformers;
    NSString *writeMsg = nil;
    
    /* Could keep these around, in repeat-play cases: */ 
    [scorePerformer release];
    scorePerformer = nil;
    [synthInstruments release];
    [self _enableMTCControls: NO];
    
    if (synchToTimeCode) {
	timeCodeMIDIDevice = [[MKMidi midiOnDevice: timeCodeDevice] retain];
	[[MKConductor defaultConductor] setMTCSynch: timeCodeMIDIDevice];
    }
    else
        [[MKConductor defaultConductor] setMTCSynch: nil];
    
    theOrch = [[MKOrchestra alloc] initOnDSP: 0]; /* A noop if it exists */
    
    [theOrch setHeadroom: headroom];    /* Must be reset for each play */ 
    if ([soundOutDeviceName isEqualToString: NEXT_SOUND]) {
	if (![theOrch supportsSamplingRate: samplingRate]) {
	    msg = STR_BAD_SRATE;
	    actualSrate = [theOrch defaultSamplingRate];
	}
	else 
	    actualSrate = samplingRate;
    }
    else if ([soundOutDeviceName isEqualToString: GENERIC]) {
	actualSrate = samplingRate;
    }
    else {
	if (![theOrch supportsSamplingRate: samplingRate]){
	    msg = STR_BAD_SSI_SRATE;
	    actualSrate = [theOrch defaultSamplingRate];
	}
	else 
	    actualSrate = samplingRate;
    }
    if (msg && !warnedAboutSrate) {	
        [errorLog addText: msg];
	warnedAboutSrate = YES;
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = STR_SCOREPLAYER;
	alert.informativeText = msg;
	[alert runModal];
	[alert release];
    }
    [theOrch setSamplingRate: actualSrate];
    
#if SOUND_OUT_PAUSE_BUG
    if (checkForMidi(scoreObj))
	[theOrch setFastResponse: YES];
    else
	[theOrch setFastResponse: NO];
#endif
    [theOrch setOutputCommandsFile: (DSPCommands) ? outputFilePath : nil];
    [theOrch setOutputSoundfile: (writeData) ? outputFilePath : nil];
    [theOrch setHostSoundOut: !writeData && [soundOutDeviceName isEqualToString: NEXT_SOUND]];
    
#if 0 // LMS disabled until cross-platform orchestra opening works
    if (![theOrch open]) {
        [errorLog addText: STR_CANT_OPEN_DSP];
        NSRunAlertPanel(STR_SCOREPLAYER, STR_CANT_OPEN_DSP, STR_OK, NULL, NULL);
	return; 
    }
#endif
    scorePerformer = [MKScorePerformer new];
    [scorePerformer setScore: scoreObj];
    [scorePerformer activate]; 
    partPerformers = [scorePerformer partPerformers];
    partCount = [partPerformers count];
    synthInstruments = [[NSMutableArray array] retain];
    for (i = 0; i < partCount; i++) {
	MKPartPerformer *partPerformer = [partPerformers objectAtIndex: i];
	MKPart *aPart = [partPerformer part]; 
	MKNote *partInfo = [aPart infoNote];
	NSString *synthPatchName = nil;
	NSString *instrumentClassName = nil;
	
	if (!partInfo) {
            errMsg = [NSString stringWithFormat: STR_INFO_MISSING, MKGetObjectName(aPart)];
            [errorLog addText: errMsg];
	    NSAlert *alert = [[NSAlert alloc] init];
	    alert.messageText = STR_SCOREPLAYER;
	    alert.informativeText = errMsg;
	    [alert addButtonWithTitle:STR_CONTINUE];
	    [alert addButtonWithTitle:STR_CANCEL];

	    if ([alert runModal] == NSAlertSecondButtonReturn) {
		[alert release];
		return;
	    }
	    [alert release];
	    continue;
	}		
        if([partInfo isParPresent: MK_synthPatch]) {
	    synthPatchName = [partInfo parAsStringNoCopy: MK_synthPatch];	    
	    instrumentClassName = [NSString stringWithFormat: @"MK%@Instrument", synthPatchName]; 
	}
	else if(scoreForm == MIDI_FILE) {
	    // If it's a SMF, all parts are default MKMidi synthPatches.
	    synthPatchName = @"midi";
            [partInfo setPar: MK_synthPatch toString: synthPatchName];
        }
	if (isMIDIInstrumentName(synthPatchName)) {
            MKMidi *newMIDI = nil;
	    int midiChan = [partInfo parAsInt: MK_midiChan];
	    
	    if ((midiChan == MAXINT) || (midiChan > 16))
		midiChan = 0;
            if ([synthPatchName isEqualToString: @"midi"])  // set the default MIDI device.
		synthPatchName = defaultMidiDeviceName;	    
	    if ((newMIDI = [playingMidiDevices objectForKey: synthPatchName]) == nil) {
                newMIDI = [MKMidi midiOnDevice: synthPatchName];
                // Check that newMIDI is not nil, i.e midiOnDevice did initialise
                if(newMIDI != nil)
                    [playingMidiDevices setObject: newMIDI forKey: synthPatchName];
            }
            if(newMIDI != nil)
                [[partPerformer noteSender] connect: [newMIDI channelNoteReceiver: midiChan]];
	}
        else if(NSClassFromString(instrumentClassName) != nil) { // TODO: should be "SamplePlayer" and MKSamplePlayerInstrument
	    // TODO: need an NSArray of these
	    nonSynthInstrument = [[NSClassFromString(instrumentClassName) alloc] init];
            [[partPerformer noteSender] connect: [nonSynthInstrument noteReceiver]];
	}
	else {
	    MKSynthInstrument *anIns;
	    Class synthPatchClass = ([synthPatchName length]) ? [MKSynthPatch findPatchClass: synthPatchName] : nil;
	    
	    if (!synthPatchClass) {         /* Class not loaded in program? */
                errMsg = [NSString stringWithFormat: STR_NO_SYNTHPATCH, synthPatchName];
                [errorLog addText: errMsg];
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = STR_SCOREPLAYER;
		alert.informativeText = errMsg;
		[alert addButtonWithTitle:STR_CONTINUE];
		[alert addButtonWithTitle:STR_CANCEL];
		if ([alert runModal] == NSAlertSecondButtonReturn) {
		    [alert release];
		    return;
		}
		/* TODO: We would prefer to dynamically load the class here. */
		[alert release];
		continue;
	    }
	    anIns = [MKSynthInstrument new];      
	    [synthInstruments addObject: anIns];
	    [[partPerformer noteSender] connect: [anIns noteReceiver]];
	    [anIns setSynthPatchClass: synthPatchClass];
	    if (![partInfo isParPresent: MK_synthPatchCount])
		continue;         
	    voices = [partInfo parAsInt: MK_synthPatchCount];
	    synthPatchCount = [anIns setSynthPatchCount: voices
                                          patchTemplate: [synthPatchClass patchTemplateFor: partInfo]];
	    if (synthPatchCount < voices) {
                errMsg = [NSString stringWithFormat: STR_TOO_MANY_SYNTHPATCHES,
			  (long)synthPatchCount, (long)voices, synthPatchName, MKGetObjectName(aPart)];
		
                [errorLog addText: errMsg];
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = STR_SCOREPLAYER;
		alert.informativeText = errMsg;
		[alert addButtonWithTitle:STR_CONTINUE];
		[alert addButtonWithTitle:STR_CANCEL];

		if ([alert runModal] == NSAlertSecondButtonReturn) {
		    [alert release];
		    return;
		}
		[alert release];
	    }
	}
    }
    errorDuringPlayback = NO;
    [theMainWindow setTitle: [NSString stringWithFormat: STR_PLAYING, shortFileName]];
    MKSetDeltaT(.75);
    [MKOrchestra setTimed: YES];
    [MKConductor afterPerformanceSel: @selector(endOfTime) to: self argCount: 0];
    [playButton setState: NSOnState]; // Should be this anyway
    if (synchToTimeCode)
    [self showConductorDidPause];
    if (writeData) {
	writeMsg = @"Writing sound file (silently) ...";
    }
    else if (DSPCommands) {
	writeMsg = @"Writing DSP Commands format soundfile.";
    }
    if (writeData || DSPCommands) {
	[soundWriteMsg setStringValue: writeMsg];
	[soundSavePanel orderFront: self];
    }
    tempoAnimator = [[NSTimer scheduledTimerWithTimeInterval: ANIMATE_INCREMENT
						      target: self
						    selector: @selector(animateTempo:)
						    userInfo: nil
						     repeats: YES] retain];
    [self startMidi];
    [theOrch run];
    [MKConductor startPerformance];     
}

- (IBAction) setTempoAdjustment: sender
{
    [MKConductor setDelegate: ([[sender selectedCell] tag] == 0) ? self : nil];
}

- (IBAction) setMidiDriverName: (id) driverPopup
{
    [defaultMidiDeviceName release];
    defaultMidiDeviceName = [[driverPopup titleOfSelectedItem] retain];
    // NSLog(@"defaultMidiDeviceName = %@\n", defaultMidiDeviceName);
    [[NSUserDefaults standardUserDefaults] setObject: defaultMidiDeviceName forKey: @"DefaultMIDIOutput"];

}

+ (void) initialize
{
    NSDictionary *scorePlayerDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
        @"NeXTsound", @"DefaultSoundOutput",
	[[MKMidi midi] driverName], @"DefaultMIDIOutput", // Naturally the application should use the systems idea of a default.
	NULL, NULL];
    [[NSUserDefaults standardUserDefaults] registerDefaults: scorePlayerDefaults];
}

static void abortNow(void);

- (void)orchestraDidAbort: whichOrch
    /* This is received by the appkit thread */
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = STR_SCOREPLAYER;
    alert.informativeText = STR_HUNG_DSP;
    [alert runModal];
    [alert release];
    abortNow();
}

- (void) applicationWillFinishLaunching: (NSNotification *) aNotification 
{
    NSString *s;
    static int inited = 0;
    NSUserDefaults *scorePlayerDefaults = [NSUserDefaults standardUserDefaults];
    
    if (inited++)
        return;
    mySelf = self;
    saveFileExtensions = [[NSArray alloc] initWithObjects:
        @"score", @"playscore",@"midi", @"snd", @"snd",nil];
    fileIcons = [[NSArray alloc] initWithObjects:
        @"ScorePlayerDoc", @"ScorePlayerDoc2", @"Midi", @"Sound", @"Sound",nil];
    SSAD64xPanel = StealthDAI2400Panel = NeXTDACPanel = nil;
    openFileExtensions = [[MKScore fileExtensions] retain];  // accept both MIDI and Scorefiles.
    errorLog = [[ErrorLog alloc] init];
    [MKConductor setThreadPriority: 1.0];
    [MKPartPerformer setFastActivation: YES]; /* We're not modifying parts while playing */
    setuid(getuid()); /* Must be after setThreadPriority. */
    [MKConductor useSeparateThread: YES];
//    [MKConductor setDelegate: self]; /* Default is no tempo adjustment */
    [[MKConductor defaultConductor] setDelegate: self];
    /* These numbers could be endlessly tweaked */
    MKSetLowDeltaTThreshold(.25);
    MKSetHighDeltaTThreshold(.4);
//    _MKSetConductorThreadMaxStress(1000000); /* Don't do cthread_yields */
#if 0
    ec = port_allocate(task_self(), &endOfTimePort);
#error DPSConversion: 'addPort:forMode:' used to be DPSAddPort(endOfTimePort, (DPSPortProc)endOfTimeProc, sizeof(msg_header_t), (void *)self, 30).  endOfTimePort should be retained to avoid loss through deallocation, the functionality of (DPSPortProc)endOfTimeProc should be implemented by a delegate of the NSPort in response to 'handleMachMessage:' or 'handlePortMessage:',  and 30 should be converted to an NSRunLoop mode (NSDefaultRunLoopMode, NSModalPanelRunLoopMode, and NSEventTrackingRunLoopMode are predefined).
    [[NSRunLoop currentRunLoop] addPort:[NSPort portWithMachPort: endOfTimePort] forMode: 30];
#endif
    MKSetErrorProc(handleMKError);

    playingMidiDevices = [[NSMutableDictionary dictionaryWithCapacity: 8] retain]; // heaps!
    [MKOrchestra setAbortNotification: self]; 
    theOrch = [[MKOrchestra alloc] init];
    capabilities = [theOrch capabilities];
    
    if (capabilities & MKOrchestraCapabilitiesHostSoundOut) {
        s = [scorePlayerDefaults stringForKey: @"MKOrchestraSoundOut"];
	if ([s isEqual: @"Host"]) {
	    [self setSoundOutDevice: NEXT_SOUND];
	}
	else {
            s = [scorePlayerDefaults stringForKey: @"MKDSPSerialPortDevice0"];
	    [soundOutputDevicePopUp selectItemWithTitle: s];
	    [self setSoundOutDevice: s];
	}
    } 
    else {
        if ((capabilities & MKOrchestraCapabilitiesNeXTCompatibleDSPPort)) {
            s = [scorePlayerDefaults stringForKey: @"MKDSPSerialPortDevice0"];
	    [soundOutputDevicePopUp selectItemWithTitle: s];
	    [self setSoundOutDevice: s];
	}
	else {
	    [soundOutputDevicePopUp selectItemWithTitle: GENERIC];
	    [soundOutputDevicePopUp setEnabled: NO];
	    [self setSoundOutDevice: GENERIC];
	}
    }
    
    // initialise the device list for selecting MIDI drivers to be used as the default "midi" instrument.
    [defaultMidiPopUp removeAllItems];
    [defaultMidiPopUp addItemsWithTitles: [MKMidi getDriverNames]];
    defaultMidiDeviceName = [[scorePlayerDefaults stringForKey: @"DefaultMIDIOutput"] retain];
    // if the default device name is no longer in the available drivers, we'll default to the first.
    [defaultMidiPopUp selectItemWithTitle: defaultMidiDeviceName]; 
}

static BOOL setUpFile(NSString *workspaceFileName)
{
    // Look for a score in a default place if this is the first time this has been run
    BOOL firstTime = [[NSUserDefaults standardUserDefaults] objectForKey: @"NSDefaultOpenDirectory"] == nil;
    
    if (!openPanel)
        openPanel = [NSOpenPanel new];    
    if (!workspaceFileName) {
	NSModalResponse success = NSModalResponseCancel;
	openPanel.allowedFileTypes = openFileExtensions;
	if (firstTime) {
            NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
	    openPanel.directoryURL = [NSURL fileURLWithPath:
				      [[libraryDirs objectAtIndex: 0]
				       stringByAppendingPathComponent: @"/Music/Scores"]];
        } else if (dir) {
	    openPanel.directoryURL = [NSURL fileURLWithPath:dir];
	    [dir release];
	    dir = nil;
	}
	success = [openPanel runModal];
	if (success != NSModalResponseOK)
	    return NO;
        [fileName release];
	fileName = [[openPanel URL].path copy];
        [shortFileName release];
	shortFileName = [[fileName lastPathComponent] copy];
    } else {
        [fileName release];
	fileName = [workspaceFileName copy];
        [shortFileName release];
	shortFileName = [[workspaceFileName lastPathComponent] copy];
    }
    if ([shortFileName isEqualToString:@"Jungle.score"] ||
        [shortFileName isEqualToString:@"Jungle.playscore"])
        tempoExponent = 1.3;  /* TODO: A real hack to make the demos play ok.  Probably redundant */
    else
        tempoExponent = 1.5;
    firstTime = NO;
    return YES;
}

static void abortNow()
{
    NSEnumerator *midiDevEnumerator = [playingMidiDevices objectEnumerator];
    MKMidi *midiDev;
    
    if ([MKConductor inPerformance]) {
	[MKConductor lockPerformance];
        while ((midiDev = [midiDevEnumerator nextObject])) {
            // This is tricky. allNotesOff sends note offs to all channels immediately,
            //  while abort will remove any pending events beyond time 0.
            [midiDev allNotesOff];
            [midiDev abort];
        }
        if(nonSynthInstrument)
            [nonSynthInstrument abort];
	[theOrch abort];
	[MKConductor finishPerformance];
	[MKConductor unlockPerformance];
    }
}

- (IBAction) selectFile: sender
{
    abortNow(); /* Could move this to after setUpFile() */
    if (!setUpFile(nil)) {
        return;
    }
    [self setFile]; 
}

- (BOOL) application: (NSApplication *) theApplication openFile: (NSString *) filename
{
    NSString *aType = [fileName pathExtension];
    if (aType)
        if ([openFileExtensions indexOfObject: aType] == NSNotFound)
            return NO;
    setUpFile(filename);
    abortNow();
    [self setFile];
    return YES;
}

- (IBAction) playStop: sender
{
    if (!fileName || ![fileName length])
        [self selectFile: self];
    if (!fileName || ![fileName length])
        return;
    if ([MKConductor inPerformance])
        abortNow();
    else {
	if (needToReread()) {
            NSLog(@"File has changed, re-reading\n");
	    [self setFile];
	}
        [self startPlay];
    }
    return;
}

- setTooFastErrorMsg: obj
{
    tooFastErrorMsg = obj;
    return self;
}

#define INITIAL_SLOWDOWN_FACTOR .9
#define SUBSEQUENT_SLOWDOWN_FACTOR .925

static void adjustTempo(double slowDown)
{
    double d = lastTempo * slowDown;
    if (d < desiredTempo) /* User may have just set slider lower than this. */
        desiredTempo = d;
}

#define PROTECT_PAGING_TIME 1.5

- conductorCrossedLowDeltaTThreshold
{
    if (MKGetTime() < PROTECT_PAGING_TIME)
        return self;
    adjustTempo(INITIAL_SLOWDOWN_FACTOR);
    [[MKConductor defaultConductor] setTempo: desiredTempo];
    isLate = YES;
    return self;
}

- conductorCrossedHighDeltaTThreshold
{
    if (isLate)  /* If early time test failed, this won't be true. */
        wasLate = YES;
    isLate = NO;
    return self;
}

- (void)animateTempo:(NSTimer*) sender
{
    double diff;
    BOOL forceAdjustment = isLate;
    
    if (forceAdjustment) 
        adjustTempo(SUBSEQUENT_SLOWDOWN_FACTOR);
    if ((isLate || wasLate) && !messageFlashed) {
	[tooFastErrorMsg setTextColor: [NSColor blackColor]];
	[tooFastErrorMsg setBackgroundColor: [NSColor lightGrayColor]];
	messageFlashed = YES;
    }
    else if (!isLate && messageFlashed) {
	[tooFastErrorMsg setTextColor: [NSColor lightGrayColor]];
	[tooFastErrorMsg setBackgroundColor: [NSColor lightGrayColor]];
	messageFlashed = NO;
	wasLate = NO;
    }
    diff = lastTempo - desiredTempo;
    if (diff < 0.0)  /* Abs value */
        diff = -diff;
    if (!forceAdjustment && diff < ANIMATE_DIFF_THRESHOLD) /* diff too small */
        return;
    [MKConductor lockPerformance];
    [[MKConductor defaultConductor] setTempo: desiredTempo];
    [MKConductor unlockPerformance];
    [tempoTextField setFloatValue: desiredTempo];
    if (wasLate || isLate)
	[tempoSlider setFloatValue: getUntempo(desiredTempo)];
    lastTempo = desiredTempo;
}

- (IBAction) setTempoFrom: sender	// currently called by slider only
{
    double val = [sender doubleValue];
    desiredTempo = getTempo(val);
    // LMS it's unclear if this was only able to happen when not playing due to earlier MK limitations.
    //    if (![MKConductor inPerformance]) {  
    [[MKConductor defaultConductor] setTempo: desiredTempo];
    [tempoTextField setFloatValue: desiredTempo];
    lastTempo = desiredTempo;
//    }
}

- (IBAction) setTimeCodeSynch: sender
{
    synchToTimeCode = [sender intValue];
    [timeCodeTextField setStringValue: (synchToTimeCode) ? @"Press Play, then start time code" : @"Press button above to enable time code"]; 
}

// TODO: rename to setTimeCodeMidiDevice:
- (IBAction) setTimeCodeSerialPort: sender
{
    /* 0 for portA, 1 for portB */
    [timeCodeDevice release];
    timeCodeDevice = [[[sender selectedCell] title] copy];
}


- (void)conductorWillSeek: sender
{
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorWillSeek)
					    to: self argCount: 0];
}

- (void)conductorDidSeek: sender
{
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidSeek)
					    to: self argCount: 0];
}

- (void)conductorDidReverse:(MKConductor *)sender
{
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidReverse)
                                            to: self
                                      argCount: 0];
}

- (void)conductorDidPause: sender
{
    NSEnumerator *midiDevEnumerator = [playingMidiDevices objectEnumerator];
    
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidPause) to: self argCount: 0];
    [synthInstruments makeObjectsPerformSelector: @selector(allNotesOff)];
    
    for (MKMidi *midiDev in midiDevEnumerator) {
        [midiDev allNotesOff];
    }
}

- (void)conductorDidResume: sender
{
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidResume) to: self argCount: 0];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification
{
    abortNow();
}

/*! Set up and run the Save panel for the given type.  The accessory view
 * is a button which allows the type to be changed when saving scores.
 */
static BOOL getSavePath(NSString **returnBuf, NSString *dir, NSString *name, NSString *theType)
{
    NSModalResponse flag;
    
    if (!savePanel) {
	savePanel = [NSSavePanel new];
	[savePanel setTitle:@"ScorePlayer Save"];
	[accessoryView setImagePosition: NSImageAbove];
	[accessoryView setTarget: mySelf];
	[accessoryView setAction:@selector(changeSaveType:)];
	[accessoryView setFrameSize: NSMakeSize(124, 68)];
    }
    [savePanel setAccessoryView: accessoryView];
    if (theType && [theType length])
        [savePanel setAllowedFileTypes: @[theType]];
    flag = [savePanel runModal];
    if (flag == NSModalResponseOK)
        *returnBuf = [savePanel URL].path;
    soundFile = (saveType==SOUND_FILE) ? *returnBuf : NULL;
    
    return flag == NSModalResponseOK;
}

NSString *getPath(NSString *dir, NSString *name, NSString *ext)
/* Construct a path given a file name, directory, and type */
{
    if (!dir || ![dir length]) 
	dir = [NSHomeDirectory() retain];
    if (!name ) 
	name=@"";
    if (!ext ) 
	ext=@"";
    if ([[name pathExtension] isEqualToString: ext])
        name = [name stringByDeletingPathExtension];
    return [dir stringByAppendingPathComponent: [name stringByAppendingPathExtension: ext]];
}

- (void)setSaveType:(int)type
    /* Set the Save panel accessory view icon and label according to type. */
{
    saveType = type;
    if (!accessoryView) {
	accessoryView = [[NSButton alloc] init];
        [fileTypes release];
        fileTypes = [[NSArray alloc] initWithObjects:
            STR_SCOREFILE, STR_PLAYSCOREFILE, STR_MIDIFILE, STR_DSPFILE, STR_SOUNDFILE, nil];
    }
    // TODO, the icons should probably be determined from the OS itself, not held within the app, since the
    // ScorePlayer has it's preferred file icon, but other programs may also.
    [accessoryView setImage: [NSImage imageNamed: [fileIcons objectAtIndex: type]]];
    [accessoryView setTitle: [fileTypes objectAtIndex: type]];
    [savePanel setAllowedFileTypes: @[[saveFileExtensions objectAtIndex: type]]];
}

- (IBAction)changeSaveType: sender
    /* Called by the accessory view (the Type button on the Save Panel */
{
    saveType++;
    if (saveType == SOUND_FILE && (!(capabilities & MKOrchestraCapabilitiesSoundFileOut)))
        saveType++;
    if (saveType > SOUND_FILE) 
	saveType = SCORE_FILE; /* Wrap */
    [self setSaveType: saveType];
}

- (IBAction) saveScoreAs: sender
    /* Save the score, always prompting for a file name first.
       This is what the SaveAs: menu item calls. */
{
    if ([MKConductor inPerformance])
        abortNow();
    if (saveType == -1) 
	[self setSaveType: SCORE_FILE];
    if (!getSavePath(&outputFilePath, outputFileDir, outputFileName, [saveFileExtensions objectAtIndex: saveType]))
	return;
    [outputFilePath retain];
    outputFileDir = [[outputFilePath stringByDeletingLastPathComponent] retain];
    outputFileName = [[outputFilePath lastPathComponent] retain];
    [self setSaveType: fileType(outputFilePath)];
    [outputFilePath release];
    outputFilePath = [getPath(outputFileDir, outputFileName, [saveFileExtensions objectAtIndex: saveType]) retain];
    switch (saveType) {
	case SCORE_FILE: 
	    [scoreObj writeScorefile: outputFilePath];
	    break;
	case PLAYSCORE_FILE: 
	    [scoreObj writeOptimizedScorefile: outputFilePath];
	    break;
	case MIDI_FILE:
	    [scoreObj writeMidifile: outputFilePath];
	    break;
	case DSP_COMMANDS_FILE:
	    /* Here we play the score, capturing the performance in the DSPCommands file. */
	    DSPCommands = YES;
	    [playButton performClick: self];
	    break;
	case SOUND_FILE:
	    /* Here we play the score, capturing the performance in the sound file. */
	    writeData = YES;
	    [playButton performClick: self];
	    break;
	default:
	    break;
    }
    [[NSCursor arrowCursor] set]; 
}

/* Display the help file formatted as HTML with the default handling application. */
- (IBAction) help: sender
{
    /* Look in the app wrapper */
    NSString *helpfile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"help.html"];
    
    if (![[NSWorkspace sharedWorkspace] openFile: helpfile]) {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = STR_SCOREPLAYER;
	alert.informativeText = STR_EDIT_CANT_OPEN_FILE;
	[alert runModal];
	[alert release];
    }
}

- (IBAction)pause: sender
{
    [MKConductor lockPerformance];
    [[MKConductor defaultConductor] pause];
    [MKConductor unlockPerformance];
}

- (IBAction)resume: sender
{
    [MKConductor lockPerformance];
    [[MKConductor defaultConductor] resume];
    [MKConductor unlockPerformance];
}

@end

