/* 
 * $Id$
 *
 * Originally from SoundEditor2.1
 * Modified by Gary Scavone for Spectro3.0
 * Last modified: 2/94
 */

#import <AppKit/AppKit.h>
#import "SoundInfo.h"

@implementation SoundInfo

- init
{
    self = [super init];
    [NSBundle loadNibNamed:@"soundInfo" owner:self];
    ssize = 0;
    return self;
}

- (void) displaySound: (Snd *) sound title: (NSString *) title
{
    self.soundHeader = [sound retain];
    [self display:title];
}

@synthesize soundHeader=sndhdr;

- (void) display: (NSString *) title
{
    int hours, minutes;
    NSTimeInterval seconds;
    
    [siPanel setTitle: title];
    [siSize setIntegerValue: [sndhdr dataSize]];
    [siRate setIntValue: [sndhdr samplingRate]];
    [siChannels setIntValue: [sndhdr channelCount]];
    [siFormat setStringValue: [sndhdr formatDescription]];
    [siFrames setIntValue: [sndhdr lengthInSampleFrames]];
    seconds = [sndhdr duration];
    hours = (int) (seconds / 3600);
    minutes = (int) ((seconds - hours * 3600) / 60);
    seconds = seconds - hours * 3600 - minutes * 60;
    [siTime setStringValue: [NSString stringWithFormat: @"%02d:%02d:%05.2f", hours, minutes, seconds]];
    [siPanel makeKeyAndOrderFront: self];
    [NSApp runModalForWindow: siPanel];
}

- (BOOL) windowShouldClose: (id) sender
{
    [NSApp stopModal];
    return YES;
}

- (void)dealloc
{
    [sndhdr release];
    [super dealloc];
}

@end
