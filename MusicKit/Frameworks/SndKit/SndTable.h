////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/Snd.h>

@interface SndTable : NSObject {
  NSMutableDictionary *nameTable;
}

+ (SndTable*)defaultSndTable;
@property (class, readonly, retain) SndTable *defaultSndTable;
- (instancetype)init;
- (Snd*)soundNamed:(NSString *)aName;
- (Snd*)findSoundFor:(NSString *)aName;
- (Snd*)addName:(NSString *)aname sound:(Snd*)aSnd;
- (Snd*)addName:(NSString *)aname fromSoundfile:(NSString *)filename;
- (Snd*)addName:(NSString *)aname fromSection:(NSString *)sectionName DEPRECATED_ATTRIBUTE;
- (Snd*)addName:(NSString *)aName fromBundle:(NSBundle *)aBundle;
- (void)removeSoundForName: (NSString *) aname;
- (void) removeAllSounds;

@end
