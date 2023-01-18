//////////////////////////////////////////////////////////////
//
// EnvelopeView.h -- Interface for the EnvelopeView class
// Copyright 1991-94 Fernando Lopez Lezcano All Rights Reserved
//
//////////////////////////////////////////////////////////////

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>            // for envelope class stuff
//#import <Envelope.h>			   // so we substitute this for now.

@interface EnvelopeView : NSView <NSCopying>
{
    // Controller theController;
    id theController;				// object which controls the envelope view
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
- (void)controllerIs:sender;
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
- (void)setXMinTo:(CGFloat)coord;
- (void)setXMaxTo:(CGFloat)coord;
- setXLimitsTo: (CGFloat)min : (CGFloat)max;
- (void)setYMinTo:(CGFloat)coord;
- (void)setYMaxTo:(CGFloat)coord;
- (void)setXSnapTo:(CGFloat)coord;
- (void)setYSnapTo:(CGFloat)coord;
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
- (CGFloat)getXMax;
- (CGFloat)getXMin;
- (CGFloat)getYMax;
- (CGFloat)getYMin;
- (CGFloat)getXSnap;
- (CGFloat)getYSnap;
- (BOOL) getShowSmooth;
- (BOOL) getDrawSegments;

@end
