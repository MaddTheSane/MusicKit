/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified, 
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free 
to use the source code for any purpose, including commercial applications, as 
long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be 
error free.  Further, we will not be liable to you if the Software is not fit 
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL 
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES 
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD 
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our 
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, 
LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR 
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE 
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED 
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS 
OF THIS AGREEMENT.

******************************************************************************/

#ifndef __SNDDISPLAYDATA_H__
#define __SNDDISPLAYDATA_H__

#import <AppKit/AppKit.h>

/*!
@class SndDisplayData
@brief For internal use of the SndView
*/

@interface SndDisplayData:NSObject
{
/*! */  
	NSInteger pixelCount;
/*! */  
	NSInteger startPixel;
/*!  */  
	float *maxArray;
/*!  */  
	float *minArray;
}
/*!
 */
@property (readonly) NSInteger pixelCount;
/*!
 */
@property (readonly) NSInteger startPixel;
/*!
 */
@property (nonatomic, readonly) NSInteger endPixel;
/*!
 */
@property (readonly) float* pixelDataMax NS_RETURNS_INNER_POINTER;
/*!
 */
@property (readonly) float* pixelDataMin NS_RETURNS_INNER_POINTER;

/*!
 */
- (BOOL)setPixelDataMax:(float *)data min:(float *)data2 count:(NSInteger)count start:(NSInteger)start;
/*!
 */
- (BOOL)setPixelDataMax:(float *)data count:(NSInteger)count start:(NSInteger)start;
/*!
 */
- (BOOL)setPixelDataMin:(float *)data count:(NSInteger)count start:(NSInteger)start;

/*!
 */
- (BOOL)addPixelDataToMax:(float *)data toMin:(float *)data2 count:(NSInteger)count fromIndex:(NSInteger)from;
/*!
 */
- (BOOL)addPixelDataToMax:(float *)data count:(NSInteger)count fromIndex:(NSInteger)from;
/*!
 */
- (BOOL)addPixelDataToMin:(float *)data count:(NSInteger)count fromIndex:(NSInteger)from;

/*!
 */
- (BOOL)addDataFromDisplayData:(SndDisplayData *)anObject;
/*!
 */
- (BOOL)truncateToLastPixel:(NSInteger)pixel;
/*!
 */
- (BOOL)truncateToFirstPixel:(NSInteger)pixel;
@end

@interface SndDisplayData (Deprecated)
/*!
 */
- addPixelDataMax:(float *)data min:(float *)data2 count:(int)count from:(int)from NS_DEPRECATED_WITH_REPLACEMENT_MAC("-addPixelDataToMax:toMin:count:fromIndex:", 10.0, 10.8);
/*!
 */
- addPixelDataMax:(float *)data count:(int)count from:(int)from NS_DEPRECATED_WITH_REPLACEMENT_MAC("-addPixelDataToMax:count:fromIndex:", 10.0, 10.8);
/*!
 */
- addPixelDataMin:(float *)data count:(int)count from:(int)from NS_DEPRECATED_WITH_REPLACEMENT_MAC("addPixelDataToMin:count:fromIndex:", 10.0, 10.8);
/*!
 */
- (id)addDataFrom:(SndDisplayData *)anObject NS_DEPRECATED_WITH_REPLACEMENT_MAC("-addDataFromDisplayData:", 10.0, 10.8);

@end

#endif
