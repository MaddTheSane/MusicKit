#ifndef __MK_ExampApp_H___
#define __MK_ExampApp_H___

/* 
 *  Music Kit programming example  
 *  Author: Doug Keislar, NeXT Developer Support  
 *  This example illustrates real-time DSP control.   
 *  The interface has a button for playing a note with a plucked-string 
 * timbre, and a slider to change its pitch.
 */

#import <AppKit/AppKit.h>

@interface ExampApp : NSObject <NSApplicationDelegate>
{
    IBOutlet NSPanel *infoPanel;
    IBOutlet id stringTable;
}

- (IBAction)playNote:sender;
- (IBAction)bendPitch:sender;
- (IBAction)showInfoPanel:sender;

@end

#endif
