//
//  TadPole.swift
//  PianoRollSwift
//
//  Created by C.W. Betts on 1/31/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

import Cocoa
import MusicKitLegacy

class TadPole: NSView {
	weak var tadNote: MKNote?
	weak var tadNoteB: MKNote?
	weak var offNote: MKNote?
	var partNumber: Int
	private(set) var isSelected = false
	private var needsErased = false
	var isMoving = false {
		didSet {
			needsDisplay = true
		}
	}

	init(note: MKNote, second: MKNote?, partNumber: Int, beatScale: Double, frequencyScale freqScale: Double) {
		self.partNumber = partNumber
		var aRect: NSRect
		if let second {
			aRect = NSMakeRect(note.timeTag * beatScale, log(note.frequency) * freqScale,
							   (second.timeTag - note.timeTag) * beatScale, 6.0);
		} else {
			aRect = NSMakeRect(note.timeTag * beatScale, log(note.frequency) * freqScale,
							   note.duration() * beatScale, 6.0);
		}
		super.init(frame: aRect)
		tadNote = note
		tadNoteB = second

	}
	
	func erase() {
		needsErased = true
		needsDisplay = true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ dirtyRect: NSRect) {
		if needsErased {
			NSColor.controlBackgroundColor.set()
			NSBezierPath.fill(bounds)
			needsErased = false
		}
		
//		double color;
		var minPoint: NSPoint = .zero, maxPoint: NSPoint = .zero
		let tadPolePath = NSBezierPath()

		if (dirtyRect.size.width > bounds.size.width) {
			maxPoint.x = dirtyRect.size.width;
		} else {
			maxPoint.x = bounds.size.width;
		}
		maxPoint.y = bounds.size.height / 2;
		if (dirtyRect.origin.x > 2) {
			minPoint.x = dirtyRect.origin.x;
		} else {
			minPoint.x = 2.0;
		}
		minPoint.y = bounds.size.height / 2;
//		color = (partNum % 5)/10.0 + 0.5;
		tadPolePath.lineWidth = 1
		if isSelected {
			NSColor.selectedControlColor.set()
		} else {
			NSColor.systemPurple.set()
		}
		tadPolePath.move(to: minPoint)
		tadPolePath.line(to: maxPoint)
		if (minPoint.x == 2) {
			tadPolePath.lineWidth = 3
//			NSColor.systemPurple.set();  // TODO: needs to be some color based on partNum
			minPoint.y = 0.0;
			tadPolePath.move(to: minPoint)
			maxPoint.x = 2.0;
			maxPoint.y = bounds.size.height;
			tadPolePath.line(to: maxPoint)
		}
		tadPolePath.stroke()
	}
	
	func unhilight() {
		isSelected = false
		needsDisplay = true
	}
	
	func highlight() {
		isSelected = true
		needsErased = true
		needsDisplay = true
	}
	
	func setFromPosWith(beatScale bScale: Double, frequencyScale fScale: Double) {
		tadNote?.setTimeTag(frame.origin.x/bScale)
		tadNote?.setPar(Int32(MK_freq.rawValue), to: exp(frame.origin.y/fScale))
	}
	
	override func mouseDown(with event: NSEvent) {
		(superview as? PartView)?.gotClicked(by: self, with: event)
	}
}
