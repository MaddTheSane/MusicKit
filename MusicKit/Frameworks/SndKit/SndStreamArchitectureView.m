////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndStreamManager.h"
#import "SndStreamArchitectureView.h"
#import "SndAudioProcessor.h"
#import "SndStreamMixer.h"

//////////////////////////////////////////////////////////////////////////////// 
// SndAudioArchViewObject
////////////////////////////////////////////////////////////////////////////////

@class SndAudioArchViewObject;

@interface SndAudioArchViewObject : NSObject
{
	NSRect rect;
	id     sndAudioArchObject;
}
- initWithRect: (NSRect) r andSndAudioArchObject: (id) object;
@property (readonly) NSRect rect;
@property (readonly, strong) id sndAudioArchObject;
- (id) sndAudioArchObject;

@end

@implementation SndAudioArchViewObject

- initWithRect: (NSRect) r andSndAudioArchObject: (id) object
{
	self = [super init];
	if(self != nil) {
		rect = r;
		sndAudioArchObject = object;
	}
	return self;
}

- (void) dealloc
{
	sndAudioArchObject = nil;
}

@synthesize rect;
@synthesize sndAudioArchObject;

@end

////////////////////////////////////////////////////////////////////////////////
// SndStreamArchitectureView
////////////////////////////////////////////////////////////////////////////////

@implementation SndStreamArchitectureView

////////////////////////////////////////////////////////////////////////////////
// initWithFrame:
////////////////////////////////////////////////////////////////////////////////

- initWithFrame: (NSRect) frameRect
{
	self = [super initWithFrame: frameRect];
	
	objectArrayLock = [[NSLock alloc] init];
	
	currentSndArchObject = nil;
	timer = [NSTimer scheduledTimerWithTimeInterval: 1
											 target: self
										   selector: @selector(update:)
										   userInfo: nil
											repeats: TRUE];
	
	if (displayObjectsArray != nil)
		[displayObjectsArray removeAllObjects];
	else
		displayObjectsArray = [[NSMutableArray alloc] init];
	
	msg = [[NSMutableAttributedString alloc] initWithString: @"Ready."];
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    [timer invalidate];
}

////////////////////////////////////////////////////////////////////////////////
// update:
////////////////////////////////////////////////////////////////////////////////

- (void)update: (NSTimer*) timer
{
	[self setNeedsDisplay: TRUE];
}

////////////////////////////////////////////////////////////////////////////////
// drawRect:
////////////////////////////////////////////////////////////////////////////////

- (void) drawRect: (NSRect) rect
{
	[objectArrayLock lock];
	
	NSEraseRect([self bounds]);
	
	// Frame the rect
	[self drawRect: rect withColor: [NSColor blackColor]];
	[displayObjectsArray removeAllObjects];
	
	// Draw the root node
	{
		NSRect mr, xr;
		
		xr.origin.x    = rect.size.width  * 3 / 7;
		xr.origin.y    = rect.size.height * 2 / 7;
		xr.size.width  = rect.size.width / 7;
		xr.size.height = rect.size.height / 7 - 1;
		[self drawMixerInRect: xr];
		{
			id theSndArchObj = [[SndStreamManager defaultStreamManager] mixer];
                    SndAudioArchViewObject *theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: xr andSndAudioArchObject: theSndArchObj];
			[displayObjectsArray addObject: theDisplayObj];
		}
		
		mr = xr;
		mr.origin.y = rect.size.height * 1 / 7;
		[self drawStreamManagerInRect: mr];
		{
			id theSndArchObj = [SndStreamManager defaultStreamManager];
                    SndAudioArchViewObject *theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: mr andSndAudioArchObject: theSndArchObj];
			[displayObjectsArray addObject: theDisplayObj];
		}
		
		{
			// Draw each of the stream clients
			SndStreamMixer *mixer   = [[SndStreamManager defaultStreamManager] mixer];
			int c = [mixer countOfClients], i;
			for (i=0;i<c;i++) {
				NSRect cr;
				cr.size.width  = rect.size.width / 7;
				cr.size.height = rect.size.height/ 7 - 1;
				cr.origin.x    = rect.size.width * (i+1)/(c+1) - cr.size.width/2;
				cr.origin.y    = rect.size.height * 5 / 7;
				{
					id theSndArchObj = [mixer clientAtIndex: i];
                                    SndAudioArchViewObject *theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: cr andSndAudioArchObject: theSndArchObj];
					[self drawStreamClient: theSndArchObj inRect: cr];
					[displayObjectsArray addObject: theDisplayObj];
				}
				
				{
					NSBezierPath *userPath  = [NSBezierPath bezierPath]; // user path for drawing segments
					NSPoint p1 = xr.origin;
					[[NSColor redColor] set];
					p1.y += xr.size.height;
					p1.x += xr.size.width / 2;
					[userPath moveToPoint: p1];
					p1 = cr.origin;
					p1.x += cr.size.width/2;
					[userPath lineToPoint: p1];
					[userPath stroke];
				}
				{
					NSPoint p = {5,10};
					if (currentSndArchObject == nil)
						[msg setAttributedString:[[NSAttributedString alloc] initWithString:@"Ready"]];
					else
						[msg setAttributedString:[[NSAttributedString alloc] initWithString:[currentSndArchObject description]]];
					[msg drawAtPoint: p];
				}
			}
		}
	}
	[objectArrayLock unlock];  
}

////////////////////////////////////////////////////////////////////////////////
// drawStreamClient:atOrigin:
////////////////////////////////////////////////////////////////////////////////

- (void)drawStreamClient: (SndStreamClient*) client inRect: (NSRect) rect
{
	NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [client clientName]];
	NSRange r = NSMakeRange(0, [s length]);
	NSRect  aRect = rect;
	NSColor *clr = (currentSndArchObject == client ? [NSColor systemRedColor] : [NSColor labelColor]);
	
	[self drawRect: rect withColor: clr];
    [s setAlignment: NSTextAlignmentCenter range: r];
	[s drawInRect: rect];
	aRect.origin.x += rect.size.width + 10;
	[self drawAudioProcessorChain: [client audioProcessorChain] inRect: aRect];
}

////////////////////////////////////////////////////////////////////////////////
// drawRootNodeAtOrigin:
////////////////////////////////////////////////////////////////////////////////

- (void)drawMixerInRect: (NSRect) rect
{
	NSMutableAttributedString *s     = [[NSMutableAttributedString alloc] initWithString: @"Mixer"];
	NSRange                    r     = {0, [s length]};
	SndStreamMixer            *mixer = [[SndStreamManager defaultStreamManager] mixer];
	SndAudioProcessorChain    *apc   = [mixer audioProcessorChain];
	NSRect                     aRect = rect;
	NSColor *clr = (currentSndArchObject == mixer ? [NSColor systemRedColor] : [NSColor labelColor]);
	
	[self drawRect: rect withColor: clr];
    [s setAlignment: NSTextAlignmentCenter range: r];
	[s drawInRect: rect];
	aRect.origin.x += rect.size.width + 10;
	[self drawAudioProcessorChain: apc inRect: aRect];
}

////////////////////////////////////////////////////////////////////////////////
// drawRootNodeAtOrigin:
////////////////////////////////////////////////////////////////////////////////

- (void)drawStreamManagerInRect: (NSRect) rect
{
	NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: @"Manager"];
	NSRange r = {0, [s length]};
	NSColor *clr = (currentSndArchObject == [SndStreamManager defaultStreamManager] ?
					[NSColor systemRedColor] : [NSColor labelColor]);
	
	[self drawRect: rect withColor: clr];
    [s setAlignment: NSTextAlignmentCenter range: r];
	[s drawInRect: rect];
}

////////////////////////////////////////////////////////////////////////////////
// drawAudioProcessorChain:inRect:
////////////////////////////////////////////////////////////////////////////////

- (void)drawAudioProcessorChain: (SndAudioProcessorChain*) apc inRect: (NSRect) rect
{
	int c = [apc processorCount], i;
	for (i = 0; i < c; i++) {
		SndAudioProcessor           *ap = [apc processorAtIndex: i];
		NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString: [ap name]];
		NSRange                       r = {0, [name length]};
		NSColor *clr = (currentSndArchObject == ap ? [NSColor redColor] : [NSColor blackColor]);
		NSColor *textClr = [ap isActive] ? [NSColor redColor] : [NSColor blueColor];    
		NSRect              theProcRect = rect;
		
		theProcRect.origin.y    += rect.size.height;
		theProcRect.origin.y    -= 14 * (i + 1);
		theProcRect.size.height  = 13;
		{
			id theDisplayObj = [[SndAudioArchViewObject alloc] initWithRect: theProcRect andSndAudioArchObject: ap];
			[displayObjectsArray addObject: theDisplayObj];
		}
		[self drawRect: theProcRect withColor: clr];
		[name addAttribute: NSForegroundColorAttributeName value: textClr range: r];
            [name setAlignment: NSTextAlignmentCenter range: r];
		[name drawInRect: theProcRect];
	}
}

////////////////////////////////////////////////////////////////////////////////
// drawRect:withColor:
////////////////////////////////////////////////////////////////////////////////

- (void)drawRect: (NSRect) aRect withColor: (NSColor*) aColor
{
	NSBezierPath *userPath  = [NSBezierPath bezierPath]; // user path for drawing segments
	NSPoint p1 = aRect.origin;
	[aColor set];
	
	[userPath moveToPoint: p1];
	p1.x += aRect.size.width;
	[userPath lineToPoint: p1];
	p1.y += aRect.size.height;
	[userPath lineToPoint: p1];
	p1.x = aRect.origin.x;
	[userPath lineToPoint: p1];
	p1.y = aRect.origin.y;
	[userPath lineToPoint: p1];
	[userPath stroke];
}

////////////////////////////////////////////////////////////////////////////////
// mouseUp:
////////////////////////////////////////////////////////////////////////////////

- (void) mouseUp: (NSEvent*) theEvent
{
	NSInteger i, c;
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	[objectArrayLock lock];
	c = [displayObjectsArray count];
	currentSndArchObject = nil;
	for (i = 0; i < c; i++) {
		SndAudioArchViewObject *theObj = [displayObjectsArray objectAtIndex: i];
		NSRect r = [theObj rect];
		if (mouseLoc.x >= r.origin.x && mouseLoc.y >= r.origin.y &&
			mouseLoc.x <= r.origin.x + r.size.width && mouseLoc.y <= r.origin.y + r.size.height) {
			currentSndArchObject = [theObj sndAudioArchObject];
			if (delegate != nil && [delegate respondsToSelector: @selector(didSelectObject:)])
				[delegate didSelectObject: [theObj sndAudioArchObject]];
			break;
		}
	}
	[objectArrayLock unlock];
	[self setNeedsDisplay: TRUE];  
}

@synthesize delegate;

////////////////////////////////////////////////////////////////////////////////
// currentlySelectedAudioArchObject
////////////////////////////////////////////////////////////////////////////////

@synthesize currentlySelectedAudioArchObject = currentSndArchObject;

- (void)clearCurrentlySelectedAudioArchObject
{
	currentSndArchObject = nil;
}

////////////////////////////////////////////////////////////////////////////////

@end

