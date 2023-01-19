/*
  $Id$

*/
#import "PrefController.h"
#import "SpectroController.h"
#import "SoundDocument.h"
#import <AppKit/AppKit.h>
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBox.h>

@implementation PrefController

- window
{
    return window;
}

- (void) setUpWell: (NSColorWell *) well tag: (int) aTag
{
    [well setTag: aTag];
    [well setContinuous: YES];
}

// TODO: we currently initialize all the preferences in SpectroController.
#if 0
+ (void) initialize;
{    
    [super initialize];    
    
    // register our defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
	    @"1024", @"WindowSize",
	    @"2.0", @"ZPFactor",
	    @"0.5", @"HopRatio",
	    @"Hanning", @"WindowType",
	    @"10000", @"SpectrumMaxFreq",
	    @"-100", @"dBLimit",
	    @"5000", @"WFMaxFreq",
	    @"3.0", @"WFPlotHeight",
	    @"0", @"DisplayType",
	    colorToString([NSColor blackColor]), @"SpectrumColor",
	    colorToString([NSColor greenColor]), @"WaterfallColor",
	    colorToString([NSColor redColor]), @"CursorColor",
	    colorToString([NSColor lightGrayColor]), @"GridColor",
	    colorToString([NSColor blueColor]), @"AmplitudeColor",
	    nil, nil]];	
}
#endif

- (void) awakeFromNib
{
    NSString *type;
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    [[NSColorPanel sharedColorPanel] setContinuous: YES];

    if([standardUserDefaults objectForKey: @"SpectrumColor"] != nil) {
        id encColor = [standardUserDefaults objectForKey: @"SpectrumColor"];
        if ([encColor isKindOfClass:[NSData class]]) {
            [spectrumColorWell setColor: dataToColor(encColor)];
        } else if ([encColor isKindOfClass:[NSString class]]) {
            [spectrumColorWell setColor: stringToColor(encColor)];
        }
    }
    if([standardUserDefaults objectForKey: @"WaterfallColor"] != nil) {
        id encColor = [standardUserDefaults objectForKey: @"WaterfallColor"];
        if ([encColor isKindOfClass:[NSData class]]) {
            [waterfallColorWell setColor: dataToColor(encColor)];
        } else if ([encColor isKindOfClass:[NSString class]]) {
            [waterfallColorWell setColor: stringToColor(encColor)];
        }
    }
    if([standardUserDefaults objectForKey: @"CursorColor"] != nil) {
        id encColor = [standardUserDefaults objectForKey: @"CursorColor"];
        if ([encColor isKindOfClass:[NSData class]]) {
            [cursorColorWell setColor: dataToColor(encColor)];
        } else if ([encColor isKindOfClass:[NSString class]]) {
            [cursorColorWell setColor: stringToColor(encColor)];
        }
    }
    if([standardUserDefaults objectForKey: @"GridColor"] != nil) {
        id encColor = [standardUserDefaults objectForKey: @"GridColor"];
        if ([encColor isKindOfClass:[NSData class]]) {
            [gridColorWell setColor: dataToColor(encColor)];
        } else if ([encColor isKindOfClass:[NSString class]]) {
            [gridColorWell setColor: stringToColor(encColor)];
        }
    }
    if([standardUserDefaults objectForKey: @"AmplitudeColor"] != nil) {
        id encColor = [standardUserDefaults objectForKey: @"AmplitudeColor"];
        if ([encColor isKindOfClass:[NSData class]]) {
            [amplitudeColorWell setColor: dataToColor(encColor)];
        } else if ([encColor isKindOfClass:[NSString class]]) {
            [amplitudeColorWell setColor: stringToColor(encColor)];
        }
    }
    
    [windowSizeCell setIntegerValue: [standardUserDefaults integerForKey: @"WindowSize"]];
    [zpFactorCell setFloatValue: [standardUserDefaults floatForKey: @"ZPFactor"]];
    [hopRatioCell setFloatValue: [standardUserDefaults floatForKey: @"HopRatio"]];
    [spectrumMaxFreqCell setIntegerValue: [standardUserDefaults integerForKey: @"SpectrumMaxFreq"]];
    [wfMaxFreqCell setIntegerValue: [standardUserDefaults integerForKey: @"WFMaxFreq"]];
    [dBLimitCell setIntegerValue: [standardUserDefaults integerForKey: @"dBLimit"]];
    [wfPlotHeightCell setFloatValue: [standardUserDefaults floatForKey: @"WFPlotHeight"]];
    if ([[standardUserDefaults objectForKey: @"DisplayType"] intValue])
	[displayMode selectCellWithTag: 1];
    else
	[displayMode selectCellWithTag: 0];

    type = [standardUserDefaults stringForKey: @"WindowType"];
    if ([type isEqualToString:@"Rectangular"])
	[windowTypeMatrix selectCellAtRow: 0 column: 0];	
    if ([type isEqualToString:@"Triangular"])
	[windowTypeMatrix selectCellAtRow: 1 column: 0];	
    if ([type isEqualToString:@"Hamming"])
	[windowTypeMatrix selectCellAtRow: 2 column: 0];	
    if ([type isEqualToString:@"Hanning"])
	[windowTypeMatrix selectCellAtRow: 3 column: 0];	
    if ([type isEqualToString:@"Blackman3"])
	[windowTypeMatrix selectCellAtRow: 0 column: 1];	
    if ([type isEqualToString:@"Blackman4"])
	[windowTypeMatrix selectCellAtRow: 1 column: 1];	
    if ([type isEqualToString:@"Kaiser"])
	[windowTypeMatrix selectCellAtRow: 2 column: 1];
    
    [self setPrefToView: [colorView contentView]];
}

- (IBAction)okay: sender
{
    int selectedRow, selectedCol, temp;
    NSUserDefaults *ourDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *newDefaults = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
	@"", @"WindowSize",
	@"", @"ZPFactor",
	@"", @"HopRatio",
	@"", @"WindowType",
	@"", @"SpectrumMaxFreq",
	@"", @"dBLimit",
	@"", @"WFMaxFreq",
	@"", @"WFPlotHeight",
	@"", @"DisplayType",
	@"", @"SpectrumColor",
	@"", @"WaterfallColor",
	@"", @"CursorColor",
	@"", @"GridColor",
	@"", @"AmplitudeColor",
	NULL, NULL] retain];

    if ([windowSizeCell integerValue] > 0)
	[ourDefaults setInteger: [windowSizeCell integerValue] forKey: @"WindowSize"];
    else {
	[windowSizeCell setIntegerValue: 1024];
	[ourDefaults removeObjectForKey: @"WindowSize"];
    }
    
    if ([zpFactorCell floatValue] >= 1.0)
	[ourDefaults setFloat: [zpFactorCell floatValue] forKey: @"ZPFactor"];
    else {
	[zpFactorCell setFloatValue: 1.0];
	[ourDefaults removeObjectForKey: @"ZPFactor"];
    }
    if ([hopRatioCell floatValue] > 0)
	[ourDefaults setFloat: [hopRatioCell floatValue] forKey: @"HopRatio"];
    else {
	[hopRatioCell setFloatValue: 0.5];
	[ourDefaults removeObjectForKey: @"HopRatio"];
    }
    if ([spectrumMaxFreqCell intValue] > 0)
	[ourDefaults setInteger: [spectrumMaxFreqCell integerValue] forKey: @"SpectrumMaxFreq"];
    else {
	[spectrumMaxFreqCell setIntValue: 10000];
	[ourDefaults removeObjectForKey: @"SpectrumMaxFreq"];
    }
    if ((temp = [dBLimitCell intValue]) < 0)
	[ourDefaults setInteger: [dBLimitCell integerValue] forKey: @"dBLimit"];
    else {
	[dBLimitCell setIntegerValue: -temp];
	[ourDefaults removeObjectForKey: @"dBLimit"];
    }
    if ([wfMaxFreqCell intValue] > 0)
	[ourDefaults setInteger: [wfMaxFreqCell integerValue] forKey: @"WFMaxFreq"];
    else {
	[wfMaxFreqCell setIntegerValue: 5000];
	[ourDefaults removeObjectForKey: @"WFMaxFreq"];
    }
    if ([wfPlotHeightCell floatValue] >= 1)
	[ourDefaults setFloat: [wfPlotHeightCell floatValue] forKey: @"WFPlotHeight"];
    else {
	[wfPlotHeightCell setFloatValue: 3.0];
	[ourDefaults removeObjectForKey: @"WFPlotHeight"];
    }
    if ([displayMode selectedRow] > 0)
	[ourDefaults setInteger: 1 forKey: @"DisplayType"]; /* Outline Mode */
    else {
	[ourDefaults setInteger: 0 forKey: @"DisplayType"]; /* Wave Mode */
    }
    selectedRow = [windowTypeMatrix selectedRow];
    selectedCol = [windowTypeMatrix selectedColumn];
    if (!selectedCol) {
        switch (selectedRow) {
            case 0:
                [ourDefaults setObject: @"Rectangular" forKey: @"WindowType"];
                break;
            case 1:
                [ourDefaults setObject: @"Triangular" forKey: @"WindowType"];
                break;
            case 2:
                [ourDefaults setObject: @"Hamming" forKey: @"WindowType"];
                break;
            case 3:
                [ourDefaults setObject: @"Hanning" forKey: @"WindowType"];
                break;
        }
    } else {
        switch (selectedRow) {
            case 0:
                [ourDefaults setObject: @"Blackman3" forKey: @"WindowType"];
                break;
            case 1:
                [ourDefaults setObject: @"Blackman4" forKey: @"WindowType"];
                break;
            case 2:
                [ourDefaults setObject: @"Kaiser" forKey: @"WindowType"];
                break;
        }
    }
    [ourDefaults setObject: colorToData([spectrumColorWell color]) forKey: @"SpectrumColor"];
    [ourDefaults setObject: colorToData([waterfallColorWell color]) forKey: @"WaterfallColor"];
    [ourDefaults setObject: colorToData([cursorColorWell color]) forKey: @"CursorColor"];
    [ourDefaults setObject: colorToData([gridColorWell color]) forKey: @"GridColor"];
    [ourDefaults setObject: colorToData([amplitudeColorWell color]) forKey: @"AmplitudeColor"];

//    [ourDefaults registerDefaults: newDefaults]; //stick these in the temporary area that is searched last.

    [window orderOut: self];
    [([NSColorPanel sharedColorPanelExists] ? [NSColorPanel sharedColorPanel] : nil) orderOut: self];
    [[(SpectroController*)[NSApp delegate] document] setColors];
}

- (IBAction)defaults: sender
{
    [windowSizeCell setIntegerValue: 1024];
    [zpFactorCell setFloatValue: 2.0];
    [hopRatioCell setFloatValue: 0.5];
    [spectrumMaxFreqCell setIntegerValue: 10000];
    [wfMaxFreqCell setIntegerValue: 5000];
    [dBLimitCell setIntegerValue: -100];
    [wfPlotHeightCell setFloatValue: 3.0];
    [windowTypeMatrix selectCellAtRow: 3 column: 0];	/* Hanning */
    [displayMode selectCellAtRow: 0 column: 0];		/* Wave Mode */
    [spectrumColorWell setColor: [NSColor blackColor]];
    [cursorColorWell setColor: [NSColor redColor]];
    [gridColorWell setColor: [NSColor lightGrayColor]];
    [amplitudeColorWell setColor: [NSColor blueColor]];
}

- (IBAction)setPref: sender
{
    id newView = nil;
    
    switch ([sender tag]) {
    case 0: 
	newView = realColorView;
	break;
    case 1:
	newView = realFftView;
	break;
    case 2:
	newView = realSpectrumDisplayView;
	break;
    case 3:
	newView = realSoundDisplayView;
	break;
    }
    
    [self setPrefToView: newView];
}

- (void)setPrefToView:theView
{
    NSRect boxRect, viewRect;
    
    boxRect = [multiView frame];
    viewRect = [theView frame];
    
    [[multiView contentView] retain];
    [multiView setContentView: theView];
    
    viewRect.origin.x = (NSWidth(boxRect) - NSWidth(viewRect)) / 2.0;
    viewRect.origin.y = (NSHeight(boxRect) - NSHeight(viewRect)) / 2.0;
    
    [theView setFrame:viewRect];	/* center the view */
    [multiView setNeedsDisplay:YES];
}

@end
