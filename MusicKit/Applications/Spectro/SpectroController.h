/*
  $Id: SoundController.h 3388 2006-10-10 20:27:56Z leighsmith $
  
  Part of Spectro.app
  Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.

  Legal Statement Covering Additions by The MusicKit Project:

    Permission is granted to use and modify this code for commercial and
    non-commercial purposes so long as the author attribution and copyright
    messages remain intact and accompany all relevant code.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PrefController.h"

@class SoundDocument;

NSString *colorToString(NSColor  *color);
NSColor  *stringToColor(NSString *buf);

NSData *colorToData(NSColor *color);
NSColor *dataToColor(NSData *buffer);
NSColor *objectToColor(id buffer);

@interface SpectroController: NSObject <NSApplicationDelegate>
{
    SoundDocument *currentDocument;
    IBOutlet id infoPanel;
    IBOutlet id saveToAccessoryView;
    PrefController *prefController;
    int counter;
}

- init;
+ (void) initialize;
- (void)setDocument:(SoundDocument *) aDocument;
- (SoundDocument *)document;
- (IBAction)printSound: sender;
- (IBAction)printSpectrum: sender;
- (IBAction)printWaterfall: sender;
- (IBAction) sndInfo: (id) sender;
- (IBAction)showInfoPanel: sender;
- (IBAction)showPreferences: sender;
- (int) documentCount;
- setCounter: (int) count;

@end
