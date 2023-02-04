
/* Generated by Interface Builder */

#import "PhiView.h"

@implementation PhiView
@synthesize FFTControler;

- afterUp:(float*)data length:(int)aLength
{
    [FFTControler setPhi:FuncTable];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect newVis = self.visibleRect;

    [super drawRect:dirtyRect];
    if(!block)[FFTControler passDraw:newVis.origin.x tag:0.];
    else block = 0;
}

- (void)drawSelfAux:(CGFloat)origin
{
    static NSRect newVis;
    static int first=1;

    if(first) { newVis = self.visibleRect; first = 0 ;}
    newVis.origin.x = origin;
    block = 1; 
    [self scrollRectToVisible:newVis];
    block = 0;
}

@end
