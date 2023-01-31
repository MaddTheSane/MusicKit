/* $Id$ */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <MusicKitLegacy/MusicKitLegacy.h>
#import "PartView.h"

@interface Document:NSObject
{
    IBOutlet NSWindow *docWindow;
    IBOutlet PartView *partView;
    MKScore *theScore;
    NSString *name;
    BOOL current;
}

- initWithScore: (MKScore *) aScore;
- partView;
- (NSWindow *) docWindow;
@property (copy) NSString *name;
- (NSString *) whatName NS_DEPRECATED_WITH_REPLACEMENT_MAC("-name", 10.0, 10.8);
- whatScore;
@property (readonly, getter=isCurrent) BOOL current;

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;

@end
