/* $Id$
   Plays scorefile in background. -- David Jaffe 
 */

#import <Foundation/Foundation.h>
#import <MusicKitLegacy/MusicKitLegacy.h>

@interface PlayScore:NSObject

- init; 
- (void)setUpPlay: (MKScore *) scoreObj;
- (BOOL) play:(MKScore *)scoreObj;
- stop;

@end
