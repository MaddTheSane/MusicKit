//
//  Document.swift
//  PianoRollSwift
//
//  Created by C.W. Betts on 1/31/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

import Cocoa
import MusicKitLegacy

class PRDocument: NSDocument, NSWindowDelegate {
	@IBOutlet weak var partView: PartView!
	var score = MKScore()!

	override init() {
	    super.init()
		fileType = "com.next.musickit.score"
		// Add your subclass-specific initialization here.
	}

	override class var autosavesInPlace: Bool {
		return true
	}

	override var windowNibName: NSNib.Name? {
		// Returns the nib file name of the document
		// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
		return NSNib.Name("Document")
	}
	
	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
		partView.setScore(score)
	}

	override func write(to url: URL, ofType typeName: String) throws {
		switch typeName {
		case "com.next.musickit.score":
			try score.write(to: url)
		case "com.next.musickit.playscore":
			try score.writeOptimizedScore(to: url)
		case "public.midi-audio":
			try score.writeMidi(to: url)
		default:
			throw NSError(domain: NSOSStatusErrorDomain, code: paramErr)
		}
	}

	override func read(from url: URL, ofType typeName: String) throws {
		score = try score.read(at: url)
	}


}

