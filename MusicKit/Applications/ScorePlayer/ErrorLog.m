/*
  $Id$  

  Description:
    Created on Jan. 25, 1991. 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc. All rights reserved.
  Addition of timecode and Intel support copyright David A. Jaffe, 1992
  Portions Copyright (c) 1999-2000 The MusicKit Project.  All rights reserved.
*/

#import "ErrorLog.h"
#import <AppKit/AppKit.h>
#import <Foundation/NSBundle.h>

@implementation ErrorLog

- (instancetype)init
{
    NSString *path;
    self = [super init];
    if (((path = [[NSBundle mainBundle] pathForResource:@"ErrorLog" ofType:@"nib"]) == nil))
        NSLog(@"Nib file missing for ScorePlayer!\n");
    else
        [NSBundle loadNibFile:path
            externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, @"NSOwner", nil]
                     withZone:[self zone]];
    //        panel =

    return self;
}

- (void)clear
{
    NSInteger endPos = [[[msg textStorage] string] length];
    [msg replaceCharactersInRange:NSMakeRange(0,endPos) withString:@"\n"];
}

- (void)buttonPressed:sender
{
    [self clear]; 
}

- (BOOL)isVisible
{
    return [panel isVisible];
}

- setMsg:anObject
{
    msg = [anObject documentView];
    [msg setFont:[NSFont fontWithName:@"Courier" size:[[msg font] pointSize]]];
    return self;
}

- (void)dealloc
{
    [panel release];
    [super dealloc];
}

- (void)addText:(NSString *)theText
{
    NSInteger endPos = [[msg string] length];
    [msg replaceCharactersInRange:NSMakeRange(endPos,0) withString:[NSString stringWithFormat:@"%@\n",theText]];
    endPos++;
    [msg scrollRangeToVisible:NSMakeRange(endPos,0)];
}

- (void)show
{
    [panel orderFront:panel]; 
}

@end

