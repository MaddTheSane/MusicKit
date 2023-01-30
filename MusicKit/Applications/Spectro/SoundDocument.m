/*	$Id$
 *	Originally from SoundEditor3.0.
 *	Modified for Spectro3.0 by Gary Scavone.
 *
 * Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.
 *
 * Legal Statement Covering Additions by The MusicKit Project:
 *
 *   Permission is granted to use and modify this code for commercial and
 *   non-commercial purposes so long as the author attribution and copyright
 *   messages remain intact and accompany all relevant code.
 *
 */

#import <AppKit/AppKit.h>
#import "SoundDocument.h"
#import "SpectroController.h"

#define ZOOM_FACTOR 2.0
#define WAVE_MODE 0
#define OUTLINE_MODE 1
#define PUTVAL(cell,f)	[cell setStringValue: [NSString stringWithFormat: @"%3.3f", f]]

@interface SoundDocument ()
@property (retain) NSURL *soundFileURL;
@end

@implementation SoundDocument

- (id)init
{
    if(self = [super init]) {
	NSRect theFrame;

	theSound = nil;
	theFrame = [[self windowForSheet] frame];
	[self newSoundLocation: &theFrame.origin];
	soundInfo = [[SoundInfo alloc] init];
	fresh = YES;
    }
    return self;
}

- (void) dealloc
{
    [theSound release];
    theSound = nil;
    [soundInfo release];
    [soundfileURL release];
    [super dealloc];
}

// Override returning the nib file name of the document
// If you need to use a subclass of NSWindowController or if your document supports
// multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
- (NSString *) windowNibName
{
    return @"soundDocument";
}

- (void)newSoundLocation: (NSPoint *) p
{
    int count = [(SpectroController*)[NSApp delegate] documentCount];
    int cnt = (count > 3) ? count - 4 : count;
    
    p->x += (20.0 * count);
    p->y -= (25.0 * cnt);
    count = (count > 6) ? 0 : count + 1;
    [(SpectroController*)[NSApp delegate] setCounter: count];
}

@synthesize soundFileURL = soundfileURL;

- (void) setWindowTitle
{
    int channelCount = [theSound channelCount];
    NSString *title = [[[self soundFileURL] path] stringByAppendingFormat: @" (%i Hz %@, %s)", 
			(int) [theSound samplingRate],
			[theSound formatDescription],
			channelCount == 1 ? "Mono" : channelCount == 2 ? "Stereo" : "Mult-channel"];

    [[self windowForSheet] setTitleWithRepresentedFilename: title];
}

- (Snd *) sound
{
    return [[theSound retain] autorelease];
}

- (double) samplingRate
{
    Snd *sound = [self sound];
    
    if ((sound == nil) || [sound isEmpty])
	return 0.0;
    else 
	return [sound samplingRate];
}

- (void)printTimeWindow
{
    [[self windowForSheet] print:self];
}

- (void)printSpectrumWindow
{
    if (mySpectrumDocument)
	[mySpectrumDocument printSpectrum];
}

- (void)printWaterfallWindow
{
    if (mySpectrumDocument)
	[mySpectrumDocument printWaterfall];
}

- (float) sampToSec: (int) samples rate: (float) srate
{
    return (srate == 0.0) ? 0.0 : samples / srate;
}

// You can also choose to override -loadFileWrapperRepresentation:ofType:  instead.
- (BOOL) readFromURL: (NSURL *) soundURL ofType: (NSString *) typeName error: (NSError **) outError
{
    theSound = [[Snd alloc] initFromSoundURL: soundURL]; // will retain.
    
    if (theSound) {
	[self setSoundFileURL: soundURL];
	[theSound setDelegate: self]; // to receive notices of playing/recording completion.
	fresh = NO;
	return YES;
    }
    else
	return NO;
}

- (void) windowControllerDidLoadNib: (NSWindowController *) windowController
{
    [[self windowForSheet] setDelegate: self];
    
    [scrollSound setDelegate: self];
    [scrollSound setSound: theSound];

    [mySpectrumDocument soundChanged]; /*sb */
    [self zoomAll: self];
    [self setButtons];

    mySoundView = [scrollSound soundView];
    if ([[NSUserDefaults standardUserDefaults] floatForKey: @"DisplayType"] < 1.0)
        [mySoundView setDisplayMode: SndViewDisplayModeWave];
    else
        [mySoundView setDisplayMode: SndViewDisplayModeMinMax];
    [mySoundView setDelegate: self];
    [mySoundView setContinuousSelectionUpdates: YES];
    [mySoundView setForegroundColor: objectToColor([[NSUserDefaults standardUserDefaults] objectForKey: @"AmplitudeColor"])];
    // [self setWindowTitle];
}

- (void)saveError:(NSString *)msg arg: (NSString *)arg
{
    NSBundle *mainB = [NSBundle mainBundle];
    
    NSRunAlertPanel([mainB localizedStringForKey:@"Save" value:@"Save" table:nil],
                    [mainB localizedStringForKey:msg value:msg table:nil],
                    [mainB localizedStringForKey:@"OK" value:@"OK" table:nil], nil, nil, arg);
}

// Need to determine the format from the extension.
- (BOOL) writeToURL: (NSURL *) absoluteURL ofType: (NSString *) typeName error: (NSError **) outError
{
    // NSLog(@"writeToURL %@ of type: %@\n", absoluteURL, typeName);
    
#if 0
    if (templateSound && theSound) {
	err = [theSound convertToSampleFormat: [templateSound dataFormat]
				 samplingRate: [templateSound samplingRate]
				 channelCount: [templateSound channelCount]];
	if (err) {
	    /* The DSP is required for compression or decompression */
	    // TODO: assign outError
	    [self saveError: @"Cannot do format conversion %@ (DSP busy?)" arg: @""];
	    return NO;
	}
    }
#endif
    
    return ![theSound writeSoundfile: [absoluteURL path]];
}

#if 0
- (IBAction) revertToSaved: (id) sender
{
    NSBundle *mainB = [NSBundle mainBundle];
    if([[self windowForSheet] isDocumentEdited] && soundfileURL
       && ![[[[soundfileURL path] lastPathComponent] isEqualToString:@"/UNTITLED"]) {
        if (NSRunAlertPanel(
			    [mainB localizedStringForKey:@"Revert" value:@"Revert" table:nil],
			    [mainB localizedStringForKey:@"Revert to saved version of %@?"
						   value:@"Revert to saved version of %@?" table:nil],
			    [mainB localizedStringForKey:@"Revert" value:@"Revert" table:nil],
			    [mainB localizedStringForKey:@"Cancel" value:@"Cancel" table:nil],
			    nil, [soundfileURL path]) == NSAlertDefaultReturn)
            // [self load:nil];
	    ;
    }
}
#endif

- (IBAction) play: sender
{
    if (![theSound isPlayable]) {
	NSLog(@"Sound %@ is not playable\n", theSound);
    }
    else {
	[playButton setEnabled: NO];
	[recordButton setEnabled: NO];
	[stopButton setEnabled: YES];
	[pauseButton setState: 0];
	[theSound play: sender];	
    }
}

- (IBAction) stop: (id) sender
{
    [theSound stop: sender];
    // All the updates of the play and record buttons are done in the didPlay:duringPerformance: delegate message below.
}

- (IBAction) pause: sender
{
    if (![playButton state] && ![recordButton state]) {
	[pauseButton setState: 0];
	return;
    } 
    else if ([pauseButton state])
	[theSound pause: sender];
    else
	[theSound resume: sender];
}

- (IBAction) record: sender
{
    [recordButton setEnabled: NO];
    [playButton setEnabled: NO];
    [stopButton setEnabled: YES];
    [theSound record: sender];
    [self updateChangeCount: NSChangeDone];
}

- (IBAction) displayMode: sender
{
    if ([[sender selectedCell] tag] == OUTLINE_MODE)
        [mySoundView setDisplayMode: SndViewDisplayModeMinMax];
    else 
        [mySoundView setDisplayMode: SndViewDisplayModeWave];
}

- (void)showDisplayTimes
{
    int start, size;
    float srate;
    
    /* Get the times from the ScrollingSound and show
	* them in the appropriate Forms
	*/
    srate = [self samplingRate];
    [scrollSound getWindowSamples: &start Size: &size];
    [wStartSamp setIntValue:start];
    PUTVAL(wStartSec, [self sampToSec: start rate: srate]);
    [wDurSamp setIntValue: size];
    PUTVAL(wDurSec, [self sampToSec: size rate: srate]);
}

- (void)showSelectionTimes
{
    unsigned int start;
    unsigned int size;
    float srate;
    
    /* Get the selection samples and stuff 'em into the selection display */
    
    srate = [self samplingRate];
    [mySoundView getSelection: &start size: &size];
    [sStartSamp setIntValue: start];
    PUTVAL(sStartSec, [self sampToSec: start rate: srate]);
    if (size > ([theSound lengthInSampleFrames] - start))
	return;
    [sDurSamp setIntValue: size];
    PUTVAL(sDurSec, [self sampToSec: size rate: srate]);
}

- (IBAction)windowMatrixChanged: sender
{
    id cell;
    int start, size, dur;
    float rate;
    BOOL startChanged, sizeChanged;
    
    cell = [sender selectedCell];
    start = [wStartSamp intValue];
    size = [wDurSamp intValue];
    dur = [theSound lengthInSampleFrames];
    rate = [self samplingRate];
    startChanged = sizeChanged = NO;
    switch ([cell tag]) {
	case 0:	start = [cell intValue];
	    startChanged = YES;
	    break;
	case 1:	start = (int) ([cell floatValue] * rate);
	    startChanged = YES;
	    break;
	case 2:	size = [cell intValue];
	    sizeChanged = YES;
	    break;
	case 3:	size = (int) ([cell floatValue] * rate);
	    sizeChanged = YES;
	    break;
	default:
            break;
    }
    
    if (size <= 0 || start < 0) {		/* erase and ignore bad values */
	[self showDisplayTimes];
	return;
    }
    if (startChanged) {
	if (start > dur - size)
	    size = dur - start;
	[scrollSound setWindowSize: size];
	[scrollSound setWindowStart: start];
    }
    if (sizeChanged) {
	if (size > dur) size = dur;
	if (start > dur - size)
	    start = dur - size;
	[scrollSound setWindowSize: size];
	[scrollSound setWindowStart: start];
    }
    [self showDisplayTimes];
}

- (IBAction)selectionMatrixChanged: sender
{
    id cell;
    int start, size, end, dur;		/* Start/size/end of selection */
    int	vstart, vsize, vend;	/* Start/size/end of view */
    float rate;
    
    cell = [sender selectedCell];
    start = [sStartSamp intValue];
    size = [sDurSamp intValue];
    dur = [theSound lengthInSampleFrames];
    rate = [self samplingRate];
    switch ([cell tag]) {
	case 0:	start = [cell intValue];
	    break;
	case 1: start = (int)([cell floatValue] * rate);
	    break;
	case 2: size = [cell intValue];
	    break;
	case 3: size = (int)([cell floatValue] * rate);
	    break;
	default:
            break;
    }
    end = start + size;
    vstart = [wStartSamp intValue];
    vsize = [wDurSamp intValue];
    vend = vstart + vsize;
    
    if (start < 0 || size < 0) {				/* Ignore negative values */
	[self showSelectionTimes];
	return;
    }
    if (end > dur) end = dur;		/* Can't select past EOF */
    if (start > end) start = end;
    size = end-start;
    [mySoundView setSelection: start size:size];

    /* If the new start time is outside the current view, scroll the view
    * so that the new start is in the center.  If the whole selection
    * will fit in the view, center the selection instead.
    */
    if (start < vstart  ||  start > vend) {
	if (size <= vsize)
	    vstart = start + size/2 - vsize/2;
	else
	    vstart = start - vsize/2;
	if (vstart < 0)
	    vstart = 0;
	[scrollSound setWindowStart: vstart];
    }

    /* If the new end time is outside the current view, scroll the view
    * so that the new end is in the center.
    */
    if (end < vstart  ||  end > vend) {
	if (size <= vsize)
	    vstart = start + size/2 - vsize/2;
	else
	    vstart = end - vsize / 2;
	if (vstart < 0)
	    vstart = 0;
	[scrollSound setWindowStart: vstart];
    }
}

- (void)touch
{
    [self updateChangeCount: NSChangeDone];        // Indicate the sound document has been changed.
}

- (void)setButtons
{
    [recordButton setEnabled: ([self isRecordable] ? YES : NO)];
    [playButton setEnabled: YES];
}

- (IBAction) sndInfo: (id) sender
{
    NSString *title;
    
    if ([theSound isEmpty])
	return;
    title = [[self soundFileURL] lastPathComponent];
    [soundInfo displaySound: theSound title: title];
}

- (IBAction) spectrum: (id) sender
{	
    if ([theSound isEmpty]) 
	return;
    if (mySpectrumDocument == nil) {
	mySpectrumDocument = [[SpectrumDocument alloc] init];
	[mySpectrumDocument setDelegate: self];
	[mySpectrumDocument setSoundView: mySoundView];
	[mySpectrumDocument setWindowTitle: [[self soundFileURL] path]];
    }
    [mySpectrumDocument spectroButtonDepressed];
    [spectrumButton setState: 0];
}

- (void)setColors
{
    [mySpectrumDocument setViewColors];
}

- (void)zoom: (float) scale center: (int) sample
{
    if ([theSound isEmpty])
	return;
    [scrollSound setReductionFactor: scale];
    [scrollSound centerOnSample: sample];
}

- (IBAction) zoomIn: sender
{
    [self zoom: ([scrollSound reductionFactor] / ZOOM_FACTOR)
	center: [scrollSound sampleAtCenter]];
}

- (IBAction) zoomOut:sender
{
    NSRect aRect;
    float maxRFactor;
    float scale = ([scrollSound reductionFactor] * ZOOM_FACTOR);
    
    if (NSIsEmptyRect(aRect = [scrollSound documentVisibleRect])) 
	return;
    maxRFactor = [theSound lengthInSampleFrames] / aRect.size.width;
    if (scale > maxRFactor)
	[self zoomAll: sender];
    else
	[self zoom: scale center: [scrollSound sampleAtCenter]];
}

- (IBAction) zoomSelect:sender
{
    [scrollSound sizeToSelection:sender];
}

- (IBAction) zoomAll: sender
{
    NSSize size;
    int count;
    float width;
    
    size = [scrollSound contentSize];
    width = size.width;
    count = [theSound lengthInSampleFrames];
    [self zoom: (((float) count) / width) center: (count / 2)];
}

- (BOOL) isRecordable
{
    SndSampleFormat format;
    
    if (!theSound) 
	return YES;
    format = [theSound dataFormat];
    if (format == SndSampleFormatMulaw8 &&
	[theSound samplingRate] == (int) SND_RATE_CODEC &&
	[theSound channelCount] == 1 )
	return YES;
    else
	return NO;
}

- (void)displayChanged:sender
{
    [self showDisplayTimes];
}

- (void) didPlay: (Snd *) soundThatPlayed duringPerformance: (SndPerformance *) endingPerformance
{
    [playButton setState: 0];
    [playButton setEnabled: YES];
    [recordButton setState: 0];
    [recordButton setEnabled: ([self isRecordable]? YES : NO)];
    [pauseButton setState: 0];    
}

- (void)didRecord: sender
{
    [playButton setState: 0];
    [playButton setEnabled: YES];
    [recordButton setState: 0];
    [recordButton setEnabled: YES];
    [pauseButton setState: 0];
}

- (void)hadError: sender
{
    SndError err = [[sender soundBeingProcessed] processingError];
    NSBundle *mainB = [NSBundle mainBundle];
    if ([playButton state]) 
        NSRunAlertPanel(
			[mainB localizedStringForKey: @"Play error" value: @"Play error" table: nil],
                        @"%@",
			[mainB localizedStringForKey: @"OK" value: @"OK" table: nil],
			nil, nil, [mainB localizedStringForKey: SndSoundError(err) value: SndSoundError(err) table: nil]);
    else if ([recordButton state])
        NSRunAlertPanel(
			[mainB localizedStringForKey: @"Record error" value: @"Record error" table: nil],
			@"%@",
			[mainB localizedStringForKey: @"OK" value: @"OK" table: nil],
			nil, nil, [mainB localizedStringForKey: SndSoundError(err) value: SndSoundError(err) table: nil]);
    [self stop: self];
}

- (void)selectionChanged: sender
{	
    if (fresh) { /* covers copy-new-paste situation */
	fresh = NO; /* must do first to avoid infinite recursion */
	[self zoomAll: self];
    }
    [self showSelectionTimes];
    [mySpectrumDocument disableWFSlider];
    [mySpectrumDocument setTotalFrames];
}

- (void)soundDidChange:sender
{
    [self touch];
    [[self sound] compactSamples];
    [mySpectrumDocument soundChanged];
}

- (void) windowDidBecomeMain: (NSNotification *) notification
{
    [(SpectroController *)[NSApp delegate] setDocument: self];
    [[self windowForSheet] makeFirstResponder: mySoundView];
    [mySoundView showCursor];
}

- (void) windowDidResignMain: (NSNotification *) notification
{
    SpectroController *theController = [NSApp delegate];
    if ([theController document] == self)
        [theController setDocument: nil];
    [mySoundView hideCursor];
}

- (void) windowDidMiniaturize: (NSNotification *) notification
{
    NSWindow *theWindow = [notification object];
    
    [mySoundView stop: theWindow];
    [mySoundView hideCursor];
    // [[self windowForSheet] setMiniwindowImage: [NSImage imageNamed: @"Spectro.tiff"]];
}

- (void) windowDidResize: (NSNotification *) notification
{
    double width;
    NSRect tempRect;
    
    tempRect = [mySoundView bounds];
    width = tempRect.size.width;
    tempRect = [scrollSound documentVisibleRect];
    if (width < tempRect.size.width)
	[self zoomAll: self];
}

- (void) windowWillClose:(NSNotification *)notification
{
    [[self windowForSheet] setDelegate: nil];
    [mySpectrumDocument closeWindows];
}

@end
