//////////////////////////////////////////////////////////////
//
// EnvelopeView.h -- Interface for the EnvelopeView class
// Copyright 1991-94 Fernando Lopez Lezcano All Rights Reserved
//
//////////////////////////////////////////////////////////////

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>            // for envelope class stuff
//#import <Envelope.h>			   // so we substitute this for now.

@class EEController;

@interface EnvelopeView : NSView <NSCopying>
{
    // Controller theController;
    EEController *theController;				// object which controls the envelope view
    MKEnvelope *theEnvelope;			// the envelope object being viewed
    NSCursor *theCross;				// crosshairs cursor
    NSCursor *theFilledCross;			// crosshairs plus knob cursor
	
    int selected;				// current highlighted point in envelope
    CGFloat defaultSmooth;			// default smoothing read from the defaults database
    NSColor *envColour;				// colour to draw envelope with
    int defaultFormat;				// which copy format to begin popup menu on.

    CGFloat xMax;				// coordinate system limits
    CGFloat xMin;
    CGFloat yMax;
    CGFloat yMin;
	
    CGFloat xSnap;				// Snap increments
    CGFloat ySnap;
	
    NSBezierPath *userPath;			// user path for drawing segments
	
    BOOL showSmooth;				// show or not smoothing in envelopes
    BOOL drawSegments;				// draw or not segments between points
}

- (void)resetCursorRects;
- initWithFrame:(NSRect)frameRect;
@property (assign) IBOutlet EEController *controller;
- (void)controllerIs:sender NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setController:" , 10.0, 10.8);
- (void)drawRect:(NSRect)rect;
- (int) hitKnobAt:(NSPoint)p border:(CGFloat)delta;
- (int) movePoint:(int)n to: (NSPoint)p;
- (void)mouseDown:(NSEvent *)event;

- (void)highlight;
- (void)dim;
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (IBAction)copy:(id)id;
- (IBAction)paste:(id)id;

- (void)setPointTo:(int)i;
- (void)nextPoint;
- (void)previousPoint;
- setXAt: (int)point to: (CGFloat)coord;
- setYAt: (int)point to: (CGFloat)coord;
- setYrAt: (int)point to: (CGFloat)coord;
- setSmoothAt: (int)point to: (CGFloat)val;
- (void)setXMinTo:(CGFloat)coord NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setXMin:", 10.0, 10.8);
- (void)setXMaxTo:(CGFloat)coord NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setXMax:", 10.0, 10.8);
- (void)setXLimitsTo: (CGFloat)min : (CGFloat)max;
- (void)setYMinTo:(CGFloat)coord NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setYMin:", 10.0, 10.8);
- (void)setYMaxTo:(CGFloat)coord NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setYMax:", 10.0, 10.8);
- (void)setXSnapTo:(CGFloat)coord NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setXSnap:", 10.0, 10.8);
- (void)setYSnapTo:(CGFloat)coord NS_DEPRECATED_WITH_REPLACEMENT_MAC("-setYSnap:", 10.0, 10.8);
- (void)setStickyAt:(int)point To:(NSControlStateValue)state;
- (void) setShowSmooth: (BOOL) state;
- (void) setDrawSegments: (BOOL) state;
- (void)scaleLimits;
- (int)getPoint;
- (CGFloat)getX:(int)i;
- (CGFloat)getY:(int)i;
- (CGFloat)getYr:(int)i;
- (CGFloat)getSmoothing:(int)i;
- (int)getSticky:(int)i;
- (CGFloat)getXMax NS_DEPRECATED_WITH_REPLACEMENT_MAC("-xMax", 10.0, 10.8);
- (CGFloat)getXMin NS_DEPRECATED_WITH_REPLACEMENT_MAC("-xMin", 10.0, 10.8);
- (CGFloat)getYMax NS_DEPRECATED_WITH_REPLACEMENT_MAC("-yMax", 10.0, 10.8);
- (CGFloat)getYMin NS_DEPRECATED_WITH_REPLACEMENT_MAC("-yMin", 10.0, 10.8);
- (CGFloat)getXSnap NS_DEPRECATED_WITH_REPLACEMENT_MAC("-xSnap", 10.0, 10.8);
- (CGFloat)getYSnap NS_DEPRECATED_WITH_REPLACEMENT_MAC("-ySnap", 10.0, 10.8);
- (BOOL) getShowSmooth NS_DEPRECATED_WITH_REPLACEMENT_MAC("-showSmooth", 10.0, 10.8);
- (BOOL) getDrawSegments NS_DEPRECATED_WITH_REPLACEMENT_MAC("-drawSegments", 10.0, 10.8);

@property (nonatomic) CGFloat xMax;
@property (nonatomic) CGFloat xMin;
@property (nonatomic) CGFloat yMax;
@property (nonatomic) CGFloat yMin;
@property (nonatomic) CGFloat xSnap;
@property (nonatomic) CGFloat ySnap;
@property (nonatomic) BOOL showSmooth;
@property (nonatomic) BOOL drawSegments;


@end
