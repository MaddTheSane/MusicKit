#include "FuncView.h"

#define vertclip(X) MIN(MAX((X),0),funcFrame.size.height)
#define horiclip(X) MIN(MAX((X),funcFrame.origin.x),funcFrame.origin.x + funcFrame.size.width-1)
#define tableclip(X) MIN(MAX((X),0),tableLength-1)
#define near(X) ratio * ((int) floor((X)/ratio + .45))
#define under(X) ratio * ((int) floor((X)/ratio))
#define over(X) ratio * ((int) ceil((X)/ratio))
#define BORDER 12.

#import <Foundation/NSTimer.h>

@implementation FuncView


- (instancetype)initWithFrame:(NSRect)frameRect
{

	if (self = [super initWithFrame:frameRect]) {
		
		// Create a border around the view where it is possible to clic without modifying the FuncTable
//		newObj->frame.size.height += 2 * BORDER ;
//		newObj->frame.size.width += 2* BORDER ;
//
//		[newObj setFrame:&(newObj->frame)];
		
//		[self translate:BORDER :BORDER];
		funcFrame = self.bounds;
		funcFrame.origin.x = 0. ;
		funcFrame.origin.y = -1. ;
		clip = funcFrame;
		clip.size.height += 1;
		tableLength = funcFrame.size.width ;
		FuncTable = (float *) calloc(tableLength,sizeof(float));
		displayMode = CONTINUOUS;
		editableFlag = YES;
		scrollable = NO;
		ratio = 1;
	}
    return self;
}

@synthesize scrollView;

-(void)setScrollView:anObject
{
    if([anObject class] != [NSScrollView class]) return;
    scrollable = YES;
    scrollView = anObject;
    [self removeFromSuperview];
    [scrollView setDocumentView:self];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setBorderType:NSLineBorder];
    [scrollView setNeedsDisplay:YES];
}
    


- (void)drawRect:(NSRect)rect
{
    int i;

	NSRectClip(clip);
    NSEraseRect(rect);
	[[NSColor blackColor] set];
	NSBezierPath *path = [NSBezierPath bezierPath];
    
    if(displayMode == CONTINUOUS || ratio == 1)
    {
		[path moveToPoint:NSMakePoint(under(rect.origin.x),FuncTable[(int)(MAX(under(rect.origin.x)/ratio,0))] *
									  funcFrame.size.height)];
		for(i=under(rect.origin.x);i<=over(rect.origin.x + rect.size.width);i+=ratio) {
			[path lineToPoint:NSMakePoint((float)i,FuncTable[(int)tableclip(i/ratio)] *  funcFrame.size.height)];
		}
    }	
    else
    {
		[path moveToPoint:NSMakePoint(rect.origin.x-ratio,0.)];
		[path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width + ratio,0.)];
	for(i=under(rect.origin.x);i<=over(rect.origin.x + rect.size.width);i+=ratio)
	{
		[path moveToPoint:NSMakePoint(i, 0)];
		[path lineToPoint:NSMakePoint((float)i,FuncTable[(int)tableclip(i/ratio)] *
									  funcFrame.size.height)];
	 }
    }
	
	[path stroke];
}

-(void)mouseDown:(NSEvent *)anEvent
{
    int looping = YES;
    int i,anOffset,aLength;
//    int oldMask;
    int inside;
    CGFloat xmin,xmax,ymin,ymax,dx,funcmin,funcmax;
    NSEvent *nextEvent;
    NSPoint cursor;
    NSPoint lastx, lasty;
    NSRect white;
	NSRect visible = funcFrame;
    NSBezierPath *path;
    
    if(editableFlag == NO) return;
//    oldMask = [self.window addToEventMask:NX_LMOUSEDRAGGEDMASK];
    //TODO: don't use -lockFocus anymore!
    [self  lockFocus];
    if(scrollable) visible = [scrollView documentVisibleRect];
    funcFrame.size.width = visible.size.width;
    funcFrame.origin.x = visible.origin.x ;
   
    NSRectClip(clip);
    [[NSColor blackColor] set];
    lastx = anEvent.locationInWindow;
    lastx = [self convertPoint:lastx fromView:nil];
    
    while(looping) {
	nextEvent = [self.window nextEventMatchingMask:(NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged)];
	switch(nextEvent.type) {
	  case NSEventTypeLeftMouseUp:
	    looping = NO;
	    [self afterUp:FuncTable length:tableLength];
	    break;
	  case NSEventTypeLeftMouseDragged:
            cursor = [self convertPoint:nextEvent.locationInWindow fromView:nil];
	    inside = NSPointInRect(cursor,funcFrame);
	    /* If the last and current cursors are outside the editable window, then don'd do anything! */
	    if(lastx.x != horiclip(lastx.x) && cursor.x != horiclip(cursor.x)) continue;
	    
	    if(lastx.x  - cursor.x < 0)		/* Mouse moving right */
	      {
		  xmin = near(lastx.x);
		  xmax = near(cursor.x);
		  ymin = vertclip( lastx.y);
		  ymax = vertclip( cursor.y);
	      }
	    else				/* Mouse moving left */
	      {
		  xmin = near(cursor.x);
		  xmax = near(lastx.x) ;
		  ymin = vertclip( cursor.y);
		  ymax = vertclip( lastx.y) ;
	      }
	    dx = xmax-xmin;
	    
	    white.origin.x = xmin - (ratio > 1)*ratio;
	    white.origin.y = -1.;
	    white.size.height = clip.size.height;
	    white.size.width = dx + ( (ratio > 1)? 2*ratio : .2);
	    NSEraseRect(white);
	    
	    funcmin = FuncTable[(int)tableclip(xmin/ratio-1)]*funcFrame.size.height;		
	    funcmax = FuncTable[(int)tableclip(xmax/ratio+1)]*funcFrame.size.height;
	    
            path = [NSBezierPath bezierPath];
	    if(displayMode == CONTINUOUS || ratio == 1) {
            [path moveToPoint:NSMakePoint(xmin-ratio, funcmin)];
		for(i=(int)xmin;i<=(int)xmax;i+=ratio) {
            CGFloat ddx = MAX(dx,1.);
            CGFloat value;
		    if(i < 0 || i/ratio - tableLength >= 0) continue;
		    value = ymin*(1 - ((CGFloat)i-xmin)/ddx) + ymax*(((CGFloat)i-xmin)/ddx);
		    FuncTable[(int)(i/ratio)] =  value / funcFrame.size.height;
            [path lineToPoint:NSMakePoint((float)i,value)];
		}
            [path lineToPoint:NSMakePoint(xmax+ratio, funcmax)];
	    }
	    else {
            [path moveToPoint:NSMakePoint(xmin-ratio, funcmin)];
            [path lineToPoint:NSMakePoint(xmin-ratio, 0.)];
            [path lineToPoint:NSMakePoint(xmax+ratio, 0.)];
		for(i=(int)xmin;i<=(int)xmax;i+=ratio) {
		    CGFloat ddx = MAX(dx,1.);
            CGFloat value;
		    if(i < 0 || i/ratio - tableLength >= 0) continue;
		    value = ymin*(1 - ((CGFloat)i-xmin)/ddx) + ymax*(((CGFloat)i-xmin)/ddx);
            [path moveToPoint:NSMakePoint((CGFloat)i,0.)];
            [path lineToPoint:NSMakePoint((CGFloat)i,value)];
		    FuncTable[(int)(i/ratio)] =  value / funcFrame.size.height;
		}
	    }
	    [path stroke];
	    [self.window flushWindow];
	    anOffset = tableclip(xmin/ratio);
	    aLength = tableclip(i/ratio-1) - anOffset+1;
	    [self afterDrag:FuncTable length:aLength offset:anOffset];
	    lastx = cursor;
	    break;
	  default: 
	    break;
	}
    }
    [self  unlockFocus];
}

-afterDrag:(float*) data length:(int)aLength offset:(int)anOffset
{
    return self;
}

- afterUp:(float*)data length:(int)aLength
{
    return self;
}

-(float*) table
{
    return FuncTable;
}

- (int) tableLength
{
    return tableLength;
}

-(int)setFuncTable:(float*)data length:(int)aLength offset:(int)anOffset
{
    int i;
    float *indTable;
    float *indData;

    indTable=FuncTable+anOffset;
    indData=data;
    for(i=0;i<MIN(aLength,tableLength-anOffset);i++)
	*(indTable++) = *(indData++);
    return (int)MIN(aLength,tableLength-anOffset);
}

-(IBAction)draw:sender
{
    switch(scrollable)
    {
	case YES : [scrollView display]; break;
	case NO : [self display]; break;
    }
}

-(void)setDisplayMode:(int)aMode
{
    if(aMode == CONTINUOUS || aMode == DISCRETE)
	displayMode = aMode;
    [self draw:self];
}


-(int)setTableLength:(int)aLength
{
    if(aLength > 0 && scrollable == YES)
    {
	tableLength = aLength;
    }
    if(aLength > 0 && scrollable == NO)
    {
	tableLength = (int) MIN(aLength,self.frame.size.width - 2*BORDER);
	ratio = (int) floor((self.frame.size.width - 2*BORDER) / tableLength + 0.5);
    }
    free(FuncTable);
    FuncTable = (float *) calloc(tableLength,sizeof(float));
    NSRect frame = self.frame;
    NSRect bounds = self.bounds;
    frame.size.width = tableLength * ratio + 2*BORDER ;
    bounds.size.width = tableLength * ratio ;
    self.frame = frame;
    self.bounds = bounds;
    clip.size.width = tableLength * ratio ;
    funcFrame.size.width = tableLength * ratio ;
//    [self.superview descendantFrameChanged:self];
    return(tableLength);
}

-(IBAction)zoomIn:sender
{
    if(scrollable == YES)
    {
	ratio *= 2;
        NSRect frame = self.frame;
	frame.size.width = tableLength * ratio + 2*BORDER ;
        self.frame = frame;
        NSRect bounds = self.bounds;
	bounds.size.width = tableLength * ratio ;
        self.bounds = bounds;
	clip.size.width = tableLength * ratio ;
	funcFrame.size.width = tableLength * ratio ;
//	[self.superview descendantFrameChanged:self];
	[self draw:self];
    }
}

-(IBAction)zoomOut:sender
{
    if(ratio >= 2 && scrollable == YES)
    {
	ratio /= 2;
        NSRect frame = self.frame;
        NSRect bounds = self.bounds;
	frame.size.width = tableLength * ratio + 2*BORDER ;
	bounds.size.width = tableLength * ratio ;
        self.frame = frame;
        self.bounds = bounds;
	clip.size.width = tableLength * ratio ;
	funcFrame.size.width = tableLength * ratio ;
//	[self.superview descendantFrameChanged:self];
	[self draw:self];
    }
}

-(void)setEditable:(BOOL)flag
{
    editableFlag = flag;
}

@end

