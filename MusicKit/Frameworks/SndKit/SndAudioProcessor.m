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

#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"

@implementation SndAudioProcessor

#define SNDAUDIOPROCESSOR_DEBUG 0

static NSMutableArray *fxClassesArray = nil;

////////////////////////////////////////////////////////////////////////////////
// registerAudioProcessorClass:
////////////////////////////////////////////////////////////////////////////////

+ (void) registerAudioProcessorClass: (Class) fxclass
{
    if (!fxClassesArray)
	fxClassesArray = [[NSMutableArray alloc] init];
    
    if (fxclass != [SndAudioProcessor class]) {// don't want to register the base class!
	if (![fxClassesArray containsObject: fxclass]) {
	    [fxClassesArray addObject: fxclass];
#if SNDAUDIOPROCESSOR_DEBUG
	    NSLog(@"registering FX class: %@",[fxclass className]);
#endif
	}
    }
}

////////////////////////////////////////////////////////////////////////////////
// fxClasses
////////////////////////////////////////////////////////////////////////////////

+ (NSArray*) fxClasses
{
    if (fxClassesArray)
	return fxClassesArray;
    else
	return nil;
}

+ (NSArray *) availableAudioProcessors
{
    // Return the array of names of available audio processors
    NSArray *concreteSubclasses = [NSArray arrayWithObjects: @"Delay",
							     @"Reverb",
							     @"Distortion", 
							     @"Flanger",
							     @"NoiseGate",
							     nil];
    return concreteSubclasses;
}

////////////////////////////////////////////////////////////////////////////////
// audioProcessor
////////////////////////////////////////////////////////////////////////////////

+ (SndAudioProcessor *)audioProcessor
{
    return [SndAudioProcessor new];
}

+ (SndAudioProcessor *) audioProcessorNamed: (NSString *) processorName
{
    NSString *className = [@"SndAudioProcessor" stringByAppendingString: processorName];
    SndAudioProcessor *processor = [NSClassFromString(className) new];

    return processor;
}

- initWithParamCount: (NSInteger) count name: (NSString *) s
{
    self = [super init];
    if (self) {
	[SndAudioProcessor registerAudioProcessorClass: [self class]];
	[self setName: s];
	numParams = count;
	active   = FALSE;
	parameterDelegate = nil;
    }
    return self;
}

- initWithParameterDictionary: (NSDictionary *) paramDictionary name: (NSString *) newName;
{
    SndAudioProcessor *newInstance = [self initWithParamCount: [paramDictionary count] name: newName];
    
    if(paramDictionary != nil)
	[newInstance setParamsWithDictionary: paramDictionary];
    return newInstance;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    return [self initWithParamCount: 0 name: @""];
}

//////////////////////////////////////////////////////////////////////////////
// dealloc
//////////////////////////////////////////////////////////////////////////////

- copyWithZone: (NSZone *) zone
{
    SndAudioProcessor *newProcessor = [[[self class] allocWithZone: zone] initWithParameterDictionary: [self paramDictionary]
												 name: [self name]];

    [newProcessor setActive: [self isActive]];
    return newProcessor; // no need to autorelease (by definition, "copy" is retained)
}

- (void) describeParameters
{
    int parameterCount = [self paramCount];
    int parameterIndex;
    
    for(parameterIndex = 0; parameterIndex < parameterCount; parameterIndex++) {
	NSString *paramLable = [self paramLabel: parameterIndex];
	NSLog(@"Parameter %d: %@: %@ %@\n", parameterIndex, 
	      [self paramName: parameterIndex], [self paramDisplay: parameterIndex],
	      paramLable == nil ? @"" : paramLable);
    }
}

//////////////////////////////////////////////////////////////////////////////
// description
//////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ %@ %@ params:%li",
            [super description], name, active ? @"(active)" : @"(inactive)", (long)numParams];
}

////////////////////////////////////////////////////////////////////////////////
// setNumParams
////////////////////////////////////////////////////////////////////////////////

- (void) setNumParams: (NSInteger) c
{
  numParams = c;
}

////////////////////////////////////////////////////////////////////////////////
// reset
////////////////////////////////////////////////////////////////////////////////

- (void) reset
{
}

////////////////////////////////////////////////////////////////////////////////
// paramCount
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) paramCount
{
  return numParams;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const NSInteger) index
{
  /* Example:
  switch (index) {
    case kYourParamKeys:
      return discoFunkinessAmount;
      break;
  }
  */
  return 0.0f;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString *) paramName: (const NSInteger) index
{
  /* Example:
  switch (index) {
    case kYourParamKeys:
      return = @"TheParameterName";
      break;
  }
  */
  return @"<unnamed>";
}

////////////////////////////////////////////////////////////////////////////////
// paramLabel:
////////////////////////////////////////////////////////////////////////////////

- (NSString *) paramLabel: (const NSInteger) index
{
  /* Example:
  switch (index) {
    case kYourParamKeyForAttenuation:
      return @"deciBels";
      break;
  }
  */
  return nil;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString *) paramDisplay: (const NSInteger) index
{
    /* Example:
    switch (index) {
    case kYourParamKeyForAttenuation:
      return [NSString stringWithFormat: @"%03f", linearToDecibels(attenuation)];
      break;
    }
    */
    // Default to displaying a float unaltered.
    return [NSString stringWithFormat: @"%03f", [self paramValue: index]];
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue:
////////////////////////////////////////////////////////////////////////////////

- (void) setParam: (const NSInteger) index toValue: (const float) v
{
  /* Example:
  switch (index) {
    case kYourParamKeys:
      YourParams = v;
      break;
  }
  */
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB
{
  // no processing? return FALSE!
  // remember to check active in derived classes.

  // in derived classes, return TRUE if the output buffer has been written to.
  return FALSE;
}

@synthesize audioProcessorChain;

////////////////////////////////////////////////////////////////////////////////
// isActive
////////////////////////////////////////////////////////////////////////////////

@synthesize active;
@synthesize name;

////////////////////////////////////////////////////////////////////////////////
// paramDictionary
////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *) paramDictionary
{
    int parameterIndex;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity: numParams];
    
    for (parameterIndex = 0; parameterIndex < numParams; parameterIndex++) {
	[dictionary setObject: [self paramObjectForIndex: parameterIndex] 
		       forKey: [self paramName: parameterIndex]];
    }
    return [NSDictionary dictionaryWithDictionary: dictionary];
}

////////////////////////////////////////////////////////////////////////////////
// setParamsWithDictionary:
////////////////////////////////////////////////////////////////////////////////

- (void) setParamsWithDictionary: (NSDictionary *) paramDictionary
{
    NSEnumerator *keyEnumerator = [paramDictionary keyEnumerator];
    
    for (NSString *key in keyEnumerator) {
	[self setParamWithKey: key toValue: [paramDictionary objectForKey: key]];
    }    
}

////////////////////////////////////////////////////////////////////////////////
// setParamWithKey:toValue:
////////////////////////////////////////////////////////////////////////////////

//- (void) setParamWithKey: (NSString *) keyName toValue: (NSValue *) value
- (void) setParamWithKey: (NSString *) keyName toValue: (NSNumber *) value
{
    unsigned int paramIndex;
    float floatValue;
    
    // [value getValue: &floatValue];
    floatValue = [value floatValue];
    
    // Do an exhaustive search - slow, but we're lazy and the parameter lists will be short (< 20).
    for (paramIndex = 0; paramIndex < [self paramCount]; paramIndex++)
	if ([keyName isEqual: [self paramName: paramIndex]])
	    [self setParam: paramIndex toValue: floatValue];
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (NSNumber *) paramObjectForIndex: (const NSInteger) i
{
    float f = [self paramValue: i];
  // return [NSValue value: &f withObjCType: @encode(float)];
    return [NSNumber numberWithFloat: f];
}

////////////////////////////////////////////////////////////////////////////////

@synthesize parameterDelegate;

@end
