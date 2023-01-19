#import "_MKList.h"

@implementation _MKList

-(id)init
{
    self = [super init];
	int i;
	theList = (id *)malloc(6 * sizeof(id));
	for (i=0;i<6;i++) {
		theList[i] = nil;
	}
    return self;
}
-(id)objectAtIndex:(NSInteger)indx
{
	if (indx < 0 || indx > 5) return nil;
	return theList[indx];
}

-(id *)baseAddress
{
	return theList;
}

-(void)dealloc
{
	free(theList);
	[super dealloc];
}

@end
