#ifndef __MK_FFTControl_H___
#define __MK_FFTControl_H___

/* Generated by Interface Builder */

#import <Cocoa/Cocoa.h>
#import <math.h>
#import "PhiView.h"
#import "ModView.h"

@interface FFTControl:NSObject <NSApplicationDelegate>
{
    ModView	*modView;
    PhiView	*phiView;
    FuncView	*waveView;
    id convView;
    float *FFTData, *PHIData, *MODData;
    float *storeTable[4];
    float *swap[2];
    int currentBuffer;
    int dataLength;
    float phizero;
    BOOL logDisplay;
    id accessoryView;
}

- setModView:anObject;
- setPhiView:anObject;
- setWaveView:anObject;
- setMod:(float*)data;
- setPhi:(float*)data;
- setLogDisplay:sender;
- receiveData:(float*)data length:(int)aLength;
- convolve:sender;
- multiply:sender;
- saveTable:sender;
- restoreTable:sender;
- storeCurrent:sender;
- previous:sender;
- passDraw:(float)curs :(int) tag;
- (IBAction)zoomIn:sender;
- (IBAction)zoomOut:sender;
- (IBAction)onOff:sender;
- (IBAction)normalize:sender;
- (IBAction)save:sender;
- (IBAction)saveAs:sender;
@end
#endif
