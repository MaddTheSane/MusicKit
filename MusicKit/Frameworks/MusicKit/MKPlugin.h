/*
 $Id$
 Defined In: The MusicKit

 Description:
 The MusicKit loads plugins (ObjC bundles) at various stages at runtime. These
 plugins can extend the operation of the MusicKit - for example, a plugin might
 allow any application using the MusicKit to be able to open certain types of
 XML files, or save in a totally different format. Bundles can also add ObjC
 categories onto existing MK classes.

 In order for a plugin to be loaded by the MusicKit, it must satisfy several conditions:
 
 (1) have the extension "mkplugin"
 (2) be found in one of the standard library locations .../MusicKitPlugins/<name>.mkplugin
 (3) correspond to the MusicKitPlugin protocol as specified below.

 Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>

 Copyright (c) 2002 tomandandy, Inc.
 Permission is granted to use and modify this code for commercial and non-commercial
 purposes so long as the author attribution and this copyright message remains intact
 and accompanies all derived code.

 */

#import <Foundation/Foundation.h>
#import <MusicKit/MKScore.h>

@protocol MusicKitPlugin <NSObject>
+ (NSString *) protocolVersion;
@property (class, readonly, copy) NSString *protocolVersion;
- (void) setDelegate:(id)delegate;
- (NSArray<NSString*>*)fileSavingSuffixes;
- (NSArray<NSString*>*)fileOpeningSuffixes;
@property (nonatomic, readonly, copy) NSArray<NSString*> *fileSavingSuffixes;
@property (nonatomic, readonly, copy) NSArray<NSString*> *fileOpeningSuffixes;

- (MKScore*)openFileName:(NSString *)f forScore:(MKScore*)s;
@optional
- (MKScore*)openURL:(NSURL *)f forScore:(MKScore*)s error:(NSError**)error;
@end

#define MK_BUNDLE_DIR @"MusicKitPlugins"
#define MK_BUNDLE_EXTENSION @"mkplugin"

extern void MKLoadAllBundlesOneOff(void);
extern BOOL MKLoadAllBundles(void);

