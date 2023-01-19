
#import <AppKit/AppKit.h>

@interface PrefController:NSObject
{
    IBOutlet NSColorWell *spectrumColorWell;
    IBOutlet NSColorWell *waterfallColorWell;
    IBOutlet NSColorWell *cursorColorWell;
    IBOutlet NSColorWell *gridColorWell;
    IBOutlet NSColorWell *amplitudeColorWell;
    IBOutlet NSBox *colorView;
    IBOutlet NSBox *fftView;
    IBOutlet NSBox *spectrumDisplayView;
    IBOutlet NSBox *soundDisplayView;
    IBOutlet NSBox *multiView;
    IBOutlet NSPanel *window;
    IBOutlet NSFormCell *windowSizeCell;
    IBOutlet NSFormCell *hopRatioCell;
    IBOutlet NSFormCell *zpFactorCell;
    IBOutlet NSMatrix *windowTypeMatrix;
    IBOutlet NSFormCell *spectrumMaxFreqCell;
    IBOutlet NSFormCell *dBLimitCell;
    IBOutlet NSFormCell *wfPlotHeightCell;
    IBOutlet NSFormCell *wfMaxFreqCell;
    IBOutlet NSMatrix *displayMode;
    
    IBOutlet NSView *realColorView;
    IBOutlet NSView *realFftView;
    IBOutlet NSView *realSpectrumDisplayView;
    IBOutlet NSView *realSoundDisplayView;

}

- window;
- (void) awakeFromNib;
- (IBAction)okay: sender;
- (IBAction)defaults: sender;
- (IBAction)setPref: sender;
- (void)setPrefToView: theView;
@end
