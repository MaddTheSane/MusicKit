//
//  AppDelegate.swift
//  PianoRollSwift
//
//  Created by C.W. Betts on 1/31/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

import Cocoa

@main
class PianoAppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var infoPanel: NSWindow!
    @IBOutlet var helpPanel: NSPanel!



	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}

    @IBAction func play(_ sender: Any?) {
        
    }
/*
 - (IBAction)play:sender
 {
     MKScore *aScore;
     
     aScore = [[self findCurrent] whatScore];
     if (aScore) {
         [scorePlayer setUpPlay:aScore];
         [scorePlayer play:aScore];
     }
 }

 - (IBAction)stopPlay:sender
 {
     [scorePlayer stop];
 }

 */
}

