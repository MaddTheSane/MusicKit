/*	$Id: SoundController.m 3388 2006-10-10 20:27:56Z leighsmith $
*	Originally from SoundEditor3.0.
*	Modified for Spectro3 by Gary Scavone.
*	Last modified: 4/94
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "SpectroController.h"
#import "SoundDocument.h"

NSData *colorToData(NSColor *color)
{
    return [NSKeyedArchiver archivedDataWithRootObject:color];
}

NSColor *stringToColor(NSString *buffer)
{
    float r, g, b;
    const char *buf = [buffer UTF8String];
    
    sscanf(buf, "%f:%f:%f", &r, &g, &b);
    return [NSColor colorWithCalibratedRed: r green: g blue: b alpha: 1.0];
}

NSColor *dataToColor(NSData *buffer)
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:buffer];
}

NSColor *objectToColor(id buffer)
{
    if ([buffer isKindOfClass:[NSData class]]) {
        return dataToColor(buffer);
    } else if ([buffer isKindOfClass:[NSString class]]) {
        return stringToColor(buffer);
    }
    return nil;
}

@implementation SpectroController

- init
{
    self = [super init];
    if(self != nil) {
	counter = 0;	
    }
    return self;
}

+ (void) initialize
{
    [super initialize];    
    
    // register our defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
	@1024, @"WindowSize",
	@2.0f, @"ZPFactor",
	@0.5f, @"HopRatio",
	@"Hanning", @"WindowType",
	@10000, @"SpectrumMaxFreq",
	@-100, @"dBLimit",
	@5000, @"WFMaxFreq",
	@3.0f, @"WFPlotHeight",
	@0, @"DisplayType",
      colorToData([NSColor blackColor]), @"SpectrumColor",
      colorToData([NSColor greenColor]), @"WaterfallColor",
      colorToData([NSColor redColor]), @"CursorColor",
      colorToData([NSColor lightGrayColor]), @"GridColor",
      colorToData([NSColor blueColor]), @"AmplitudeColor",
	nil, nil]];	
}

#if 0

// TODO: set the file types for the document from Snd -soundFileExtensions
// <key>CFBundleDocumentTypes</key>
// <key>CFBundleTypeExtensions</key>
// insert the fileTypes
    NSArray *fileTypes = [Snd soundFileExtensions];
    [Snd defaultFileExtension]    
    pathname = nil;  // so if we fail to load, we have notice of this.

#endif

- (void)setDocument: aDocument
{
    currentDocument = aDocument;
}

- document
{
    return currentDocument;
}

- (IBAction)printSound: sender
{
    [currentDocument printTimeWindow];
}

- (IBAction)printSpectrum: sender
{
    [currentDocument printSpectrumWindow];
}

- (IBAction)printWaterfall: sender
{
    [currentDocument printWaterfallWindow];
}

- (IBAction) sndInfo: (id) sender
{
    [currentDocument sndInfo: sender];
}

- (IBAction)showInfoPanel: sender
{
    [infoPanel makeKeyAndOrderFront: nil];
}

- (IBAction)showPreferences: sender
{
    if (!prefController) {
	[NSBundle loadNibNamed: @"preferences" owner: self];
    }
    [[prefController window] makeKeyAndOrderFront: sender];
}

- (int) documentCount
{
    return counter;
}

- setCounter: (int) count
{
    counter = count;
    return self;
}

- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
    currentDocument = nil;
    [self showInfoPanel: self];
}

- (void) applicationDidHide: (NSNotification *) notification
{
    if (currentDocument)
        [currentDocument stop: nil];
}

@end
