////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    View showing the current layout of Snd streaming components.
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

#ifndef __SNDKIT_SNDSTREAMARCHITECTUREVIEW_H_
#define __SNDKIT_SNDSTREAMARCHITECTUREVIEW_H_

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class SndAudioArchViewObject;
@class SndStreamClient;
@class SndAudioProcessorChain;
@protocol SndStreamArchitectureViewDelegate;

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndStreamArchitectureView
@brief View showing the current layout of Snd streaming components
  (rudimentary)

  Shows the manager, mixer, clients and processors attached to each.
  User may click on any object to see their current description
  (updated every second). Object then becomes the currentObject,
  which triggers a message to an interested delegate which, for
  example, may wish to activate an editor for that object. An example
  of this behaviour may be found in <b>SndAudioProcessorInspector</b>.
*/
@interface SndStreamArchitectureView : NSView 
{
/*! */ 
  NSTimer *timer;
/*! */ 
  NSMutableArray<SndAudioArchViewObject*> *displayObjectsArray;
/*! */ 
  NSMutableAttributedString *msg;
/*! currentSndArchObject */ 
  id      currentSndArchObject;
/*! objectArrayLock */ 
  NSLock *objectArrayLock;
/*! */ 
  id<SndStreamArchitectureViewDelegate> delegate;
}

/*!
  @brief   NSTimer callback that forces a fresh of the view.
  
  To come
  @param      timer
  @return     self
*/
- (void)update: (NSTimer *) timer;

/*!
  @brief   To come
  
  For internal use only
  @param      client
  @param      rect
  @return     self
*/
- (void)drawStreamClient: (SndStreamClient *) client inRect: (NSRect) rect;

/*!
  @brief   To come
  
  For internal use only
  @param      rect
  @return     self
*/
- (void)drawMixerInRect: (NSRect) rect;

/*!
  @brief   To come
  
  For internal use only
  @param      rect
  @return     self
*/
- (void)drawStreamManagerInRect: (NSRect) rect;

/*!
  @brief   To come
  
  For internal use only
  @param      apc
  @param      rect
  @return     self
*/
- (void)drawAudioProcessorChain: (SndAudioProcessorChain *) apc inRect: (NSRect) rect;

/*!
  @brief   To come  
  @param      aRect
  @param      aColor
  @return     self
*/
- (void)drawRect: (NSRect) aRect withColor: (NSColor *) aColor;

/*!
  @brief   To come  
  @param      theEvent
*/
- (void) mouseUp: (NSEvent *) theEvent;

/*!
  @brief   To come
*/
@property (retain) id<SndStreamArchitectureViewDelegate> delegate;

/*!
  @brief   To come  
  @return     Returns the id of the current, user selected audio architecture object.
*/
- (id) currentlySelectedAudioArchObject;

/*!
  @brief   Clears the currently selected audio architecture object to nil.
  @return     self.
*/
- (void)clearCurrentlySelectedAudioArchObject;

@end

////////////////////////////////////////////////////////////////////////////////
// Simple delegate protocol
////////////////////////////////////////////////////////////////////////////////

/*! @protocol SndStreamArchitectureViewDelegateProtocol
*/
@protocol SndStreamArchitectureViewDelegate <NSObject>
@optional
/*!
  @brief   sent to delegate when an on-screen audio object (mixer, processor
  manager, client) is clicked by the user.
  
  
  @param      sndAudioArchDisplayObject
  @return
*/
- didSelectObject: (id) sndAudioArchDisplayObject;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
