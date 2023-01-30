// $Id$

#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>

@interface Controller: NSObject
{
    IBOutlet NSTextFieldCell *freqNum1;
    IBOutlet NSTextFieldCell *freqNum2;
    IBOutlet NSSlider *freqSlide1;
    IBOutlet NSSlider *freqSlide2;
    IBOutlet SndView *soundView1;
    IBOutlet SndView *soundView2;
    IBOutlet SndView *soundView3;
    IBOutlet NSTextFieldCell *volNum1;
    IBOutlet NSTextFieldCell *volNum2;
    IBOutlet NSSlider *volSlide1;
    IBOutlet NSSlider *volSlide2;
    IBOutlet NSMatrix *waveType1;
    IBOutlet NSMatrix *waveType2;
    IBOutlet NSTextView *mesgBox;
    IBOutlet NSFormCell *sLength;
    
    Snd * theSound1;
    Snd * theSound2;
    Snd * theSound3;
    Snd * newSound;
    
    float soundLength;
    int type1,type2;
    BOOL somethingChanged;
}

- (IBAction)play:sender;
- (IBAction)playA:sender;
- (IBAction)playB:sender;

- (IBAction)updateNums:sender;
- (IBAction)updateSliders:sender;
- (IBAction)waveChanged:sender;
- recalc;
- calcSound1;
- calcSound2;
- calcSound3;
- (IBAction)changeLength:sender;

@end
