/* $Id$
  Example Application within the MusicKit

  Description:
    See MidiRecord.m for details.

  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/

#import <AppKit/AppKit.h>
#import <MusicKitLegacy/MusicKitLegacy.h>

@interface MidiRecord : NSObject <NSApplicationDelegate>
{
    MKMidi *midiIn;
    MKScore *score;
    MKScoreRecorder *scoreRecorder;
    NSString *scoreFilePath;
    NSString *scoreFileDir;
    NSString *scoreFileName;
    NSSavePanel *savePanel;
    BOOL needsUpdate;

    IBOutlet id saveAsMenuItem;
    IBOutlet id saveMenuItem;
    IBOutlet id myWindow;
    IBOutlet id infoPanel;
    IBOutlet NSButton *recordButton;
    IBOutlet NSPopUpButton *driverPopup;
}

- (IBAction) go: sender;
- (IBAction) saveAs: sender;
- (IBAction) save: sender;
- (IBAction) showInfoPanel: sender;
- (IBAction) setDriverName: (id) sender;
- init;
@end
