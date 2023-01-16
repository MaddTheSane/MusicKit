/******************************************************************************
$Id$

Description: Hold-all for displaying a sound.

Original Author: Stephen Brandon

LEGAL:
This framework and all source code supplied with it, except where specified, 
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are 
free to use the source code for any purpose, including commercial applications, 
as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be 
error free.  Further, we will not be liable to you if the Software is not fit 
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL 
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES 
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD 
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our 
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS 
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR 
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE 
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED 
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS 
OF THIS AGREEMENT.

******************************************************************************/

#import "SndDisplayData.h"

@implementation SndDisplayData
+ (void)initialize
{
  if (self == [SndDisplayData class])
  {
    [self setVersion: 0];
  }
}
-(id)init
{
    if (self = [super init]) {
	pixelCount = startPixel = 0;
	maxArray = minArray = NULL;
    }
    return self;
}
- (void)dealloc
{
	if (maxArray) free(maxArray);
	if (minArray) free(minArray);
    [super dealloc];
}

@synthesize pixelCount;
@synthesize startPixel;
- (NSInteger)endPixel
{
	return startPixel + pixelCount - 1;
}
@synthesize pixelDataMax=maxArray;
@synthesize pixelDataMin=minArray;
- (BOOL)setPixelDataMax:(float *)data min:(float *)data2 count:(NSInteger)count start:(NSInteger)start
{
	if (![self setPixelDataMax:(float *)data count:(int)count start:(int)start])
		return NO;
	if (![self setPixelDataMin:(float *)data2 count:(int)count start:-1])
		return NO;
	return YES;
}
- (BOOL)setPixelDataMax:(float *)data count:(NSInteger)count start:(NSInteger)start
{
	if (maxArray) {
		free(maxArray);
		maxArray = NULL;
		}
	maxArray = (float *)malloc(count * sizeof(float));
	if (maxArray) {
		pixelCount = count;
		memmove(maxArray,data, count * sizeof(float));
		if (start != -1) startPixel = start;
		return YES;
	}
	return NO;
}
- (BOOL)setPixelDataMin:(float *)data count:(NSInteger)count start:(NSInteger)start
{
	if (minArray) {
		free(minArray);
		minArray = NULL;
		}
	minArray = (float *)malloc(count * sizeof(float));
	if (minArray) {
		pixelCount = count;
		memmove(minArray,data, count * sizeof(float));
		if (start != -1) startPixel = start;
		return YES;
	}
	return NO;
}
- (BOOL)addPixelDataToMax:(float *)data toMin:(float *)data2 count:(NSInteger)count fromIndex:(NSInteger)from
{
 /* 'from' is expressed in terms of the position within the sound being cached.
  * It's not a direct index into the alloc'ed arrays.
  */
	if (![self addPixelDataToMax:data count:count fromIndex:from - startPixel])
		return NO;
	if (![self addPixelDataToMin:(float *)data2 count:count fromIndex:from - startPixel])
		return NO;
	return YES;
}
- (BOOL)addPixelDataToMax:(float *)data count:(NSInteger)count fromIndex:(NSInteger)from
{ /* here, from is a direct index into our array */
    NSInteger newSize = from + count;
	maxArray = (float *) realloc(maxArray,newSize * sizeof(float));
	if (maxArray) {
		pixelCount = newSize;
		memmove(maxArray + from ,data, count * sizeof(float));
		return YES;
	}
	return NO;
}
- (BOOL)addPixelDataToMin:(float *)data count:(NSInteger)count fromIndex:(NSInteger)from
{/* here, from is a direct index into our array */
    NSInteger newSize = from + count;
	minArray = (float *) realloc(minArray,newSize * sizeof(float));
	if (minArray) {
		pixelCount = newSize;
		memmove(minArray + from ,data, count * sizeof(float));
		return YES;
	}
	return NO;
}
- (BOOL)addDataFromDisplayData:(SndDisplayData *)anObject
{
	float *newMaxArray,*newMinArray;
	NSInteger newStartPoint,newCount;
	if (!anObject) return NO;
	newMaxArray = [anObject pixelDataMax];
	newMinArray = [anObject pixelDataMin];
	newCount = [anObject pixelCount];
	newStartPoint = [anObject startPixel];
	
	if (!newMinArray || !newMaxArray) return NO;
	if (!newCount) return YES; /* consider it done... */
	if (newStartPoint > pixelCount + startPixel) {
		NSLog(@"SndDisplayData: discontinuous data append (expected %ld, got %ld)\n",
		      pixelCount + startPixel,(long)newStartPoint);
		return NO;
	}
	if (newStartPoint < pixelCount + startPixel)
		NSLog(@"SndDisplayData: new data overlaps, but continuing (expected %ld, got %ld)\n",
		  pixelCount + startPixel,(long)newStartPoint);
	[self addPixelDataToMax:newMaxArray toMin:newMinArray count:(int)newCount
			 fromIndex:(int)newStartPoint];
	return YES;
}
- (BOOL)truncateToLastPixel:(NSInteger)pixel;
{
	pixelCount = pixel - startPixel + 1;
	maxArray = (float *) realloc(maxArray, pixelCount * sizeof(float));
	minArray = (float *) realloc(minArray, pixelCount * sizeof(float));
	return (maxArray != NULL && minArray != NULL);
}

- (BOOL)truncateToFirstPixel:(NSInteger)pixel
{
    NSInteger newBase = pixel - startPixel;
    NSInteger newCount = pixelCount - newBase;
    NSInteger i;
	if (!maxArray || !minArray) return NO;
	for (i = 0;i < newCount; i++) {
		maxArray[i] = maxArray[newBase + i];
		minArray[i] = minArray[newBase + i];
	} /* shove all data from area which will survive, down into bottom of array */
	maxArray = (float *) realloc(maxArray, newCount * sizeof(float));
	minArray = (float *) realloc(minArray, newCount * sizeof(float));
	startPixel = pixel;
	pixelCount = newCount;
	return (maxArray != NULL && minArray != NULL);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super init])) {
	return nil;
    }
    if (aDecoder.allowsKeyedCoding) {
	pixelCount = [aDecoder decodeIntegerForKey:@"pixelCount"];
	startPixel = [aDecoder decodeIntegerForKey:@"startPixel"];
	maxArray = (float *)malloc(pixelCount * sizeof(float));
	minArray = (float *)malloc(pixelCount * sizeof(float));
	// FIXME: better way of decoding an array of floats?
	NSArray<NSNumber*> *tmpArray;
	if (@available(macOS 11.0, *)) {
	    tmpArray = [aDecoder decodeArrayOfObjectsOfClass:[NSNumber class] forKey:@"MaxArray"];
	} else {
	    tmpArray = [aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSNumber class], nil] forKey:@"MaxArray"];
	}
	for (NSInteger i  = 0; i < pixelCount; i++) {
	    maxArray[i] = [tmpArray[i] floatValue];
	}
	if (@available(macOS 11.0, *)) {
	    tmpArray = [aDecoder decodeArrayOfObjectsOfClass:[NSNumber class] forKey:@"MinArray"];
	} else {
	    tmpArray = [aDecoder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSNumber class], nil] forKey:@"MinArray"];
	}
	for (NSInteger i  = 0; i < pixelCount; i++) {
	    minArray[i] = [tmpArray[i] floatValue];
	}
    } else {
        NSInteger v = [aDecoder versionForClassName:@"SndView"];
        if (v == 0) {
		int tempCount, tempStart;
		[aDecoder decodeValuesOfObjCTypes:"ii", &tempCount, &tempStart];
		pixelCount = tempCount;
		startPixel = tempStart;
		
		maxArray = (float *)malloc(pixelCount * sizeof(float));
		minArray = (float *)malloc(pixelCount * sizeof(float));
		[aDecoder decodeArrayOfObjCType:"f" count:pixelCount at:maxArray];
		[aDecoder decodeArrayOfObjCType:"f" count:pixelCount at:minArray];
        }
    }
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (aCoder.allowsKeyedCoding) {
	[aCoder encodeInteger:pixelCount forKey:@"pixelCount"];
	[aCoder encodeInteger:startPixel forKey:@"startPixel"];
	// FIXME: better way of encoding an array of floats?
	NSMutableArray *tmpArr = [NSMutableArray array];
	for (int i = 0; i < pixelCount; i++) {
	    [tmpArr addObject:@(maxArray[i])];
	}
	[aCoder encodeObject:tmpArr forKey:@"MaxArray"];
	tmpArr = [NSMutableArray array];
	for (int i = 0; i < pixelCount; i++) {
	    [tmpArr addObject:@(minArray[i])];
	}
	[aCoder encodeObject:tmpArr forKey:@"MinArray"];
    } else {
	int tempCount = (int)pixelCount, tempStart = (int)startPixel;
	[aCoder encodeValuesOfObjCTypes:"ii", &tempCount, &tempStart];
	[aCoder encodeArrayOfObjCType:"f" count:pixelCount at:maxArray];
	[aCoder encodeArrayOfObjCType:"f" count:pixelCount at:minArray];
    }
}

@end

// Old NeXTStep methods would return themselves on success, and nil on failure.
// These replicate the old behavior.
@implementation SndDisplayData (Deprecated)

- (id)addDataFrom:(SndDisplayData *)anObject
{
    if ([self addDataFromDisplayData:anObject]) {
	return self;
    } else {
	return nil;
    }
}

- (id)addPixelDataMax:(float *)data count:(int)count from:(int)from
{
    if ([self addPixelDataToMax:data count:count fromIndex:from]) {
	return self;
    } else {
	return nil;
    }
}

- (id)addPixelDataMin:(float *)data count:(int)count from:(int)from
{
    if ([self addPixelDataToMin:data count:count fromIndex:from]) {
	return self;
    } else {
	return nil;
    }
}

-(id)addPixelDataMax:(float *)data min:(float *)data2 count:(int)count from:(int)from
{
    if ([self addPixelDataToMax:data toMin:data2 count:count fromIndex:from]) {
	return self;
    } else {
	return nil;
    }
}

@end
