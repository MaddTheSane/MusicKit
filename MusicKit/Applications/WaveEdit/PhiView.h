#ifndef __MK_PhiView_H___
#define __MK_PhiView_H___

/* Generated by Interface Builder */

#import "FuncView.h"
#import "FFTControl.h"
#import <AppKit/AppKit.h>

@class FFTControl;

@interface PhiView:FuncView
{
	FFTControl *FFTControler;
    int block;
}

@property (assign) IBOutlet FFTControl *FFTControler;
- afterUp:(float*)data length:(int)aLength;
- (void)drawSelfAux:(CGFloat)origin;
@end
#endif
