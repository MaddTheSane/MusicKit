/*
  $Id$

  Part of Spectro.app
  Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.

  Legal Statement Covering Additions by The MusicKit Project:

    Permission is granted to use and modify this code for commercial and
    non-commercial purposes so long as the author attribution and copyright
    messages remain intact and accompany all relevant code.

*/
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSDocument.h> // For some reason GnuStep doesn't include this
#import <SndKit/SndKit.h>
#import "SoundInfo.h"
#import "SpectrumDocument.h"
#import "ScrollingSound.h"

@interface SoundDocument: NSDocument <NSWindowDelegate, SndDelegate, SndViewDelegate>
{
    IBOutlet NSButton *playButton;
    IBOutlet NSButton *recordButton;
    IBOutlet NSButton *stopButton;
    IBOutlet NSButton *pauseButton;
    IBOutlet NSButton *spectrumButton;
    IBOutlet id wStartSamp;
    IBOutlet id wStartSec;
    IBOutlet id wDurSamp;
    IBOutlet id wDurSec;
    IBOutlet id sStartSamp;
    IBOutlet id sStartSec;
    IBOutlet id sDurSamp;
    IBOutlet id sDurSec;
    IBOutlet ScrollingSound *scrollSound;
    SoundInfo *soundInfo;
    SpectrumDocument *mySpectrumDocument;
    Snd *theSound;
    NSURL *soundfileURL;
    SndView *mySoundView;
    BOOL fresh;
}

- (instancetype)init;
- (void)newSoundLocation: (NSPoint *) p;

/*!
  @brief Loads a file of the type given by aType from the URL.
  @returns YES if file successfully read.
*/
- (BOOL) readFromURL: (NSURL *) soundURL ofType: (NSString *) typeName error: (NSError **) outError;

/*!
  @brief Writes a file of the type given by aType.
  @returns YES if file successfully written.
*/
- (BOOL) writeToURL: (NSURL *) absoluteURL ofType: (NSString *) typeName error: (NSError **) outError;

/*!
  @brief Assigns the title of the window from the sound format.
 */
- (void) setWindowTitle;

/*!
  @brief Returns the Snd instance currently being displayed.
 */
- (Snd *) sound;

- (double) samplingRate;
- (void)printTimeWindow;
- (void)printSpectrumWindow;
- (void)printWaterfallWindow;
- (float)sampToSec:(int)samples rate: (float)srate;
- (void)saveError:(NSString *)msg arg: (NSString *)arg;
- (IBAction) play:sender;
- (void) stop: (id) sender;
- (IBAction) pause:sender;
- (IBAction) record:sender;
- (IBAction) displayMode:sender;
- (void)showDisplayTimes;
- (void)showSelectionTimes;
- (IBAction)windowMatrixChanged:sender;
- (IBAction)selectionMatrixChanged:sender;
- (void)touch;
- (void)setButtons;
- (IBAction) sndInfo:sender;
- (IBAction) spectrum: (id) sender;
- (void)setColors;
- (void)zoom: (float) scale center: (int) sample;
- (IBAction) zoomIn:sender;
- (IBAction) zoomOut:sender;
- (IBAction) zoomSelect:sender;
- (IBAction) zoomAll:sender;
- (BOOL) isRecordable;

@end

@interface SoundDocument(/*ScrollingSoundDelegate*/)

- (void)displayChanged: sender;

@end
