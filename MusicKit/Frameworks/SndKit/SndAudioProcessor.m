////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessor.m
//  SndKit
//
//  Created by SKoT McDonald on Tue Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessor.h"
#import "SndAudioBuffer.h"
#import "SndAudioProcessorInspector.h"

@implementation SndAudioProcessor

////////////////////////////////////////////////////////////////////////////////
// audioProcessor 
////////////////////////////////////////////////////////////////////////////////

+ audioProcessor
{
   return [[SndAudioProcessor new] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init 
////////////////////////////////////////////////////////////////////////////////

- init
{
  [super init];
  numParams = 0;
  return self;
}

- initWithParamCount: (int) count name: (NSString*) s
{
  [super init];
  [self setName: s];
  numParams = count;
  bActive = TRUE;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// setNumParams 
////////////////////////////////////////////////////////////////////////////////

- setNumParams: (int) c
{
    numParams = c;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// reset 
////////////////////////////////////////////////////////////////////////////////

- reset
{
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramCount
////////////////////////////////////////////////////////////////////////////////

- (int) paramCount
{
    return numParams;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (int) index
{
    return 0.0f;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (int) index
{
    return @"<none>";
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue: 
////////////////////////////////////////////////////////////////////////////////

- setParam: (int) index toValue: (float) v
{
/*
    switch (index) {
        case kYourParamKeys:
            YourParams = v;
            break;
    }
*/    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
    // no processing? return FALSE!
    // remember to check bActive in derived classes.
    
    // in derived classes, return TRUE if the output buffer has been written to
    return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
// setAudioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (void) setAudioProcessorChain:(SndAudioProcessorChain*)inChain
{
    audioProcessorChain = inChain; /* non retained back pointer */
}

////////////////////////////////////////////////////////////////////////////////
// audioProcessorChain
////////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorChain*) audioProcessorChain
{
    return [[audioProcessorChain retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// isActive
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isActive
{
  return bActive;
}

- setActive: (BOOL) b
{
  bActive = b;
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// name
//////////////////////////////////////////////////////////////////////////////

- setName: (NSString*) aName
{
  if (name != nil)
    [name release];
  name = [aName retain];
  return self;
}

- (NSString*) name
{
  return [[name retain] autorelease];
}

//////////////////////////////////////////////////////////////////////////////
// description
//////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return [NSString stringWithFormat: @"%@ params:%i",name,numParams];
}

//////////////////////////////////////////////////////////////////////////////
// inspect
//////////////////////////////////////////////////////////////////////////////

- inspect
{
  if (inspector == nil)
    inspector = [[SndAudioProcessorInspector alloc] initWithAudioProcessor: self];
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// dealloc
//////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (inspector)
    [inspector release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// paramDictionary
////////////////////////////////////////////////////////////////////////////////

- (NSDictionary*) paramDictionary
{
  int i;
  NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
  for (i = 0; i < numParams; i++) {
    [dictionary setObject: [self paramObjectForIndex: i] forKey: [self paramName: i]];
  }
  return dictionary;
}

////////////////////////////////////////////////////////////////////////////////
// setParamWithKey:toValue:
////////////////////////////////////////////////////////////////////////////////

- setParamWithKey: (NSString*) keyName toValue: (NSValue*) value
{
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (id) paramObjectForIndex: (int) i
{
  float    f = [self paramValue: i];
  NSValue *v = [NSValue value: &f withObjCType: @encode(float)];
  return   v;
}


////////////////////////////////////////////////////////////////////////////////

@end
