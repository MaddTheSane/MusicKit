#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

@interface SoundInfo: NSObject <NSWindowDelegate>
{
    IBOutlet NSTextField    *siSize;
    IBOutlet NSTextField    *siFrames;
    IBOutlet NSTextField    *siFormat;
    IBOutlet NSTextField    *siTime;
    IBOutlet NSTextField    *siRate;
    IBOutlet NSPanel	    *siPanel;
    IBOutlet NSTextField    *siChannels;
    int ssize;
    Snd *sndhdr;
}

- init;
- (void) displaySound: (Snd *) sound title: (NSString *) title;
@property (retain) Snd *soundHeader;
- (void) display: (NSString *) title;

@end
