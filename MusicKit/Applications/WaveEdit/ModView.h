#ifndef __MK_ModView_H___
#define __MK_ModView_H___

/* Generated by Interface Builder */

#import "FuncView.h"
#import "FFTControl.h"

@interface ModView:FuncView
{
    id	FFTControler;
    int block;
}

@property (assign) IBOutlet id FFTControler;
- afterUp:(float*)data length:(int)aLength;
- drawSelfAux:(float)origin;

@end
#endif
