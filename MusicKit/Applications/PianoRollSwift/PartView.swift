//
//  PlayScore.swift
//  PianoRollSwift
//
//  Created by C.W. Betts on 1/31/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

import Cocoa
import MusicKitLegacy
import MusicKitLegacy.MKPlugin

let MAXFREQ: Double = 7040

private let DEFAULT_BEATSCALE: Double = 32
private let DEFAULT_FREQSCALE: Double = 16

class PartView: NSView {
	
	var beatScale: Double = DEFAULT_BEATSCALE
	var frequencyScale: Double = DEFAULT_FREQSCALE
	private var selectedList = [TadPole]()

	/* used to quickly identify PartView in a NSWindow */
	override var tag: Int {
		return 1
	}
	
	func setScore(_ aScore: MKScore) {
		beatScale = DEFAULT_BEATSCALE
		frequencyScale = DEFAULT_FREQSCALE

		let theParts = aScore.parts
		let partCount = theParts.count

		var scoreDuration: Double = 0
		/* find the length of the score */
		for thePart in theParts {
			for j in 0 ..< thePart.countOfNotes {
				let theNote = thePart.note(at: j)!
				if theNote.noteType == .noteDur {
					if theNote.timeTag + theNote.duration() > scoreDuration {
						scoreDuration = theNote.timeTag + theNote.duration()
					}
				} else if theNote.timeTag > scoreDuration {
					scoreDuration = theNote.timeTag
				}
			}
		}
		if scoreDuration * beatScale > bounds.size.width {
			beatScale = bounds.size.width / scoreDuration
		}
		frame = NSRect(origin: frame.origin, size: CGSize(width: scoreDuration*beatScale, height: log(MAXFREQ)*frequencyScale))
		
		for (i, thePart) in theParts.enumerated() {
			for j in 0 ..< thePart.countOfNotes {
				let theNote = thePart.note(at: j)!
				switch theNote.noteType {
				case .noteDur:
					let newTad = TadPole(note: theNote, second: nil, partNumber: i, beatScale: beatScale, frequencyScale: frequencyScale)
					addSubview(newTad)
				case .noteUpdate:
					if theNote.noteTag == .max { /* no note tag! */
						break
					}
					fallthrough
				case .noteOn:
					if MKIsNoDVal(theNote.frequency) { /* no frequency - not quite kosher */
						break;
					}
					for k in (j + 1) ..< thePart.countOfNotes {
						let newTad = TadPole(note: theNote, second: thePart.note(at: k), partNumber: i, beatScale: beatScale, frequencyScale: frequencyScale)
						addSubview(newTad)
					}
				case .noteOff, .mute:
					break;
					
				@unknown default:
					break
				}
				
			}
		}
	}
	
	func gotClicked(by sender: TadPole, with theEvent: NSEvent) {
		var loop = true, inside = true, wasdragged = false, wasSelected = true;
			
		if (!sender.isSelected) {
			wasSelected = false
			sender.isMoving = true
			sender.highlight()
			for selected in selectedList {
				selected.unhilight()
			}
			selectedList.removeAll()
			selectedList.append(sender)
		} else {
			sender.erase()
		}
		var ePoint = theEvent.locationInWindow
		while loop {
			guard let nEvent = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else {
				continue
			}
			var thePoint = nEvent.locationInWindow
			thePoint = convert(thePoint, from: nil)
			inside = NSMouseInRect(thePoint, bounds, isFlipped)
			switch nEvent.type {
			case .leftMouseUp:
				loop = false
				if !wasdragged, wasSelected {
					sender.unhilight()
					if let idx = selectedList.firstIndex(of: sender) {
						selectedList.remove(at: idx)
					}
				} else {
					for theTad in selectedList {
						theTad.setFromPosWith(beatScale: beatScale, frequencyScale: frequencyScale)
						theTad.isMoving = false
					}
				}
				
			case .leftMouseDragged:
				wasdragged = true
				for theTad in selectedList {
					theTad.isMoving = true
					theTad.setFrameOrigin(NSPoint(x: (theTad.frame.origin.x + thePoint.x - ePoint.x), y: (theTad.frame.origin.y + thePoint.y - ePoint.y)))
				}
				ePoint = thePoint
				
			default:
				// Makes explicit to the compiler we do nothing with other events.
				break;
			}
		}
	}
}
