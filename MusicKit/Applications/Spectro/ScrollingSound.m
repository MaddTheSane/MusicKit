/*
 * $Id$
 *
 * Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.
 *
 * Legal Statement Covering Additions by The MusicKit Project:
 *
 *   Permission is granted to use and modify this code for commercial and
 *   non-commercial purposes so long as the author attribution and copyright
 *   messages remain intact and accompany all relevant code.
 *
 */
#import "ScrollingSound.h"

#import <AppKit/NSApplication.h>
#import <AppKit/NSCursor.h>


@implementation ScrollingSound

- initWithFrame:(NSRect)theFrame
{
	NSRect tempRect = theFrame;
    SndView *theSoundView;
    NSBorderType borderType = NSBezelBorder;
    
	tempRect.size = [NSScrollView contentSizeForFrameSize:(theFrame.size) hasHorizontalScroller:YES hasVerticalScroller:NO borderType:borderType];
	theSoundView = [[SndView alloc] initWithFrame:tempRect];
	self = [super initWithFrame:theFrame];
    [self setBorderType:borderType];
    [self setHasHorizontalScroller:YES];
    [self setHasVerticalScroller:NO];
    [self setScrollsDynamically:YES];
    [self setSoundView:theSoundView];
    [self setBackgroundColor:[NSColor whiteColor]];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [[theSoundView superview] setAutoresizesSubviews:YES];
    [theSoundView setAutoresizingMask:NSViewHeightSizable];
    return self;
}

- (void)centerOnSample:(int)sample
{
	CGFloat r;
	unsigned long samples;
	NSPoint p;
	NSRect tframe;
	
	p.y = p.x = 0.0;
	if ((samples = [[soundView sound] lengthInSampleFrames]) < 1) goto empty;
	r = ((CGFloat) sample) / ((CGFloat) samples);
	tframe = [soundView frame];
	p.y = 0.0;
	p.x = tframe.size.width * r;
	tframe = [[self contentView] frame];
	p.x -= tframe.size.width / 2.0;
	if (p.x < 0.0) p.x = 0.0;
	
	empty:
	[soundView scrollPoint:p];
}

- (int)sampleAtCenter
{
	NSRect aRect;			
	float r;
	
        if (NSIsEmptyRect(aRect = [self documentVisibleRect])) return 0;
	r = aRect.origin.x + (aRect.size.width/ 2.0);
	aRect = [soundView frame];
	if (aRect.size.width == 0.0) return 0;
	r = (r - aRect.origin.x) / aRect.size.width;
	if (r > 1.0) r = 1.0;
        return (int) (r * [[soundView sound] lengthInSampleFrames] + 0.5);
}

@synthesize delegate;
@synthesize soundView;
@synthesize reductionFactor;

- (void)setSoundView:aSoundView
{
	if (soundView)
		[soundView release];
	soundView = [aSoundView retain];
	[self setDocumentView:soundView];
}

- (void)setSound:(Snd *)aSound
{
    if ([soundView sound])
        [[soundView sound] release];
    [[soundView window] makeKeyAndOrderFront:self];
    [soundView setSound:aSound];
    srate = [aSound samplingRate];
}

-(void) setReductionFactor: (CGFloat) rf
{
    NSInteger start, size;

    [soundView getSelection:&start size: &size];
    reductionFactor = rf;
    [soundView setReductionFactor: rf];
    [soundView setSelection: start size: size];
}

- getWindowSamples:(int *)stptr Size:(int *)sizptr
{
	NSRect aRect;			/* dimensions of visible view */

/* Get the graphic dimensions of the currently visible portion of the
 * SoundView and convert those graphic coordinates to times.
 */
	aRect = [self documentVisibleRect];
	*stptr  = aRect.origin.x   * reductionFactor;
	*sizptr = aRect.size.width * reductionFactor;
	return self;
}

- (void)setWindowStart:(NSInteger)start
{
	NSRect aRect;			/* Visible part of SoundView */

	if (srate == 0)
		return;

/* Get the coordinates of the visible part of the SoundView,
 * change its origin, and force a scroll.
 */
	aRect = [self documentVisibleRect];
	aRect.origin.x = start / reductionFactor;
 	[soundView scrollRectToVisible:aRect];
}

/* setWindowSize:  -- Change the duration of the display.
 * 	Argument is an int.  The change in duration is accomplished by
 *	changing the reduction factor while keeping the graphic
 *	size of the SoundView constant.
 */
- (void) setWindowSize:(NSInteger)size
{
	NSRect aRect;			/* Visible part of SoundView */
	CGFloat rFactor;
	
	if (srate == 0)
		return;

/* Get the width of the display and calculate the new reduction factor
 * needed to fit the requested duration within that size.
 */
	aRect = [self documentVisibleRect];
	rFactor = size / aRect.size.width;
	if (rFactor < 0.05)		/* reductionFactor can't be < 1 */
		rFactor = 0.05;
	[self setReductionFactor:rFactor];
}

/* sizeToSelection: -- Set the display start/size to the start/size of
 * current selection.
 */
- sizeToSelection: sender
{
    NSInteger selstart, selsize;

    [soundView getSelection: &selstart size: &selsize];
    if (!selsize)
	return self;
    [self setWindowSize: selsize];		/* Need to do this first */
    [self setWindowStart: selstart];		/* Now set start and scroll */

/* Be sure to notify the delegate that our display changed
*/
    if ([delegate respondsToSelector: @selector(displayChanged:)])
	[delegate performSelector: @selector(displayChanged:) withObject: self];
    return self;
}

/* reflectScroll: -- handle a change in the relationship between
 *	the contentView and the docView.  This method overrides
 *	the standard ScrollView method so as to send a displayChanged:
 *	message to the delegate.
 */
- (void)reflectScrolledClipView:(NSClipView *)sender
{	
	[super reflectScrolledClipView:sender];		/* Do the default actions */
	if (srate == 0)
            srate = [[soundView sound] samplingRate];
	if ([delegate respondsToSelector:@selector(displayChanged:)])
            [delegate performSelector:@selector(displayChanged:) withObject:self];
}

@end
