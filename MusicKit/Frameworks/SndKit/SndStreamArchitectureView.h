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

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndStreamArchitectureView
@abstract View showing the current layout of Snd streaming components
          (rudimentary)
@discussion Shows the manager, mixer, clients and processors attached to each.
            User may click on any object to see their current description
            (updated every second). Object then becomes the currentObject,
            which triggers a message to an interested delegate which, for
            example, may wish to activate an editor for that object. An example
            of this behaviour may be found in <b>SndAudioProcessorInspector</b>.
*/
@interface SndStreamArchitectureView : NSView {
/*! @var timer */ 
  NSTimer *timer;
/*! @var displayObjectsArray */ 
  NSMutableArray *displayObjectsArray;
/*! @var msg */ 
  NSMutableAttributedString *msg;
/*! @var  currentSndArchObject */ 
  id      currentSndArchObject;
/*! @var  objectArrayLock */ 
  NSLock *objectArrayLock;
/*! @var delegate */ 
  id      delegate;
}

/*!
  @method     update:
  @abstract   NSTimer callback that forces a fresh of the view.
  @discussion To come
  @param      timer
  @result     self
*/
- update: (NSTimer*) timer;
/*!
  @method     drawStreamClient:inRect:
  @abstract   To come
  @discussion For internal use only
  @param      client
  @param      rect
  @result     self
*/
- drawStreamClient: (SndStreamClient*) client inRect: (NSRect) rect;
/*!
  @method     drawMixerInRect:
  @abstract   To come
  @discussion For internal use only
  @param      rect
  @result     self
*/
- drawMixerInRect: (NSRect) rect;
/*!
  @method     drawStreamManagerInRect:
  @abstract   To come
  @discussion For internal use only
  @param      rect
  @result     self
*/
- drawStreamManagerInRect: (NSRect) rect;
/*!
  @method     drawAudioProcessorChain:inRect:
  @abstract   To come
  @discussion For internal use only
  @param      apc
  @param      rect
  @result     self
*/
- drawAudioProcessorChain: (SndAudioProcessorChain*) apc inRect: (NSRect) rect;
/*!
  @method     drawRect:withColor:
  @abstract   To come
  @discussion To come
  @param      aRect
  @param      aColor
  @result     self
*/
- drawRect: (NSRect) aRect withColor: (NSColor*) aColor;
/*!
  @method     mouseUp:
  @abstract   To come
  @discussion To come
  @param      theEvent
*/
- (void) mouseUp: (NSEvent*) theEvent;
/*!
  @method     setDelegate:
  @abstract   To come
  @discussion To come
  @param      delegate
  @result     self
*/
- (void) setDelegate: (id) delegate;
/*!
  @method     delegate
  @abstract   To come
  @discussion To come
  @result     A delegate id.
*/
- (id) delegate;
/*!
  @method     currentlySelectedAudioArchObject
  @abstract   To come
  @discussion To come
  @param      delegate
  @result     Returns the id of the current, user selected audio architecture object.
*/
- (id) currentlySelectedAudioArchObject;
/*!
  @method     clearCurrentlySelectedAudioArchObject
  @abstract   Clears the currently selected audio architecture object to nil.
  @discussion To come
  @result     self.
*/
- clearCurrentlySelectedAudioArchObject;

@end

////////////////////////////////////////////////////////////////////////////////
// Simple informal delegate protocol
////////////////////////////////////////////////////////////////////////////////

/*! @protocol SndStreamArchitectureViewDelegateProtocol
*/
@protocol SndStreamArchitectureViewDelegateProtocol
/*!
  @method     didSelectObject:
  @abstract   sent to delegate when an on-screen audio object (mixer, processor
              manager, client) is clicked by the user.
  @discussion
  @param      sndAudioArchDisplayObject
  @result
*/
- didSelectObject: (id) sndAudioArchDisplayObject;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
