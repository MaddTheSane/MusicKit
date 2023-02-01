//
//  PlayScore.swift
//  PianoRollSwift
//
//  Created by C.W. Betts on 2/1/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

import Foundation
import MusicKitLegacy

var userCancelFileRead = false

private func handleMKError(msg: String?) {
	if !MKConductor.inPerformance() {
		let alert = NSAlert()
		alert.messageText = "PianoRoll"
		alert.informativeText = msg ?? "Uh…"
		alert.addButton(withTitle: "OK")
		alert.addButton(withTitle: "Cancel")
		if alert.runModal() == .alertFirstButtonReturn {
			MKSetScorefileParseErrorAbort(0);
			userCancelFileRead = true         /* A kludge for now. */
		}
	} else {
		if let msg {
			print(msg)
		}
	}
}


class PlayScore: NSObject {
	var synthInstruments = [AnyObject]()
	var scorePerformer: MKScorePerformer?
	var theOrch: MKOrchestra?
	var samplingRate: Double = 22050;
	var headroom: Double = 0.1;
	var initialTempo: Double = 0
	
	static let shared: PlayScore = {
		MKConductor.setThreadPriority(1.0)
		MKConductor.useSeparateThread(true)
		MKSetErrorProc(handleMKError)
		return PlayScore()
	}()
	
	override init() {
		
	}
	
	deinit {
		synthInstruments.removeAll(keepingCapacity: false)
	}
	
	func setUpPlay(_ scoreObj: MKScore) {
		if isPlaying {
			stop()
		}
		
		samplingRate = 22050
		headroom = 0.1
		initialTempo = 60
		MKConductor.default.setTempo(initialTempo)
		if let scoreInfo = scoreObj.infoNote {
			if scoreInfo.isParPresent(Int32(MK_headroom.rawValue)) {
				headroom = scoreInfo.par(asDouble: Int32(MK_headroom.rawValue))
			}
			if scoreInfo.isParPresent(Int32(MK_samplingRate.rawValue)) {
				samplingRate = scoreInfo.par(asDouble: Int32(MK_samplingRate.rawValue))
				if !((samplingRate == 44100.0) || (samplingRate == 22050.0)) {
					let alert = NSAlert()
					alert.messageText = "ScorePlayer"
					alert.informativeText = "Sampling rate must be 44100 or 22050."
					alert.runModal()
				}
			}
			if scoreInfo.isParPresent(Int32(MK_tempo.rawValue)) {
				initialTempo = scoreInfo.par(asDouble: Int32(MK_tempo.rawValue))
				MKConductor.default.setTempo(initialTempo)
			}
			scorePerformer = nil
			synthInstruments.removeAll(keepingCapacity: false)
		}
	}
	
	func play(_ scoreObj: MKScore) -> Bool {
		
		if isPlaying {
			stop()
		}
		theOrch = MKOrchestra(onDSP: 0) /* A noop if it exists */
		//    [theOrch setHeadroom:headroom];    /* Must be reset for each play */
		theOrch?.samplingRate = samplingRate
		guard let _ = theOrch?.open() else {
			let alert = NSAlert()
			alert.messageText = "ScorePlayer"
			alert.informativeText = "Can't open DSP. Perhaps another application has it."
			alert.runModal()
			return false
		}
		scorePerformer = MKScorePerformer()
		scorePerformer!.setScore(scoreObj)
		scorePerformer!.activate()
		let partPerformers = scorePerformer!.partPerformers()!
		
		for partPerformer in partPerformers {
			let aPart = partPerformer.part()
			let partInfo = aPart?.infoNote
			
			synthInstruments.removeAll()
			guard let partInfo, partInfo.isParPresent(Int32(MK_synthPatch.rawValue)) else {
				let alert = NSAlert()
				alert.messageText = "ScorePlayer"
				alert.informativeText = "\(MKGetObjectName(aPart)!) info missing."
				alert.addButton(withTitle: "Continue")
				alert.addButton(withTitle: "Cancel")
				if alert.runModal() == .alertSecondButtonReturn {
					return false
				}
				continue
			}
			let className = partInfo.par(asStringNoCopy: Int32(MK_synthPatch.rawValue))!
			guard let synthPatchClass = MKSynthPatch.findClass(className) as? MKSynthPatch.Type else {
				/* Class not loaded in program? */
				let alert = NSAlert()
				alert.messageText = "ScorePlayer"
				alert.informativeText = "This scorefile calls for a synthesis instrument (\(className)) that isn't available in this application."
				alert.addButton(withTitle: "Continue")
				alert.addButton(withTitle: "Cancel")
				if alert.runModal() == .alertSecondButtonReturn {
					return false
				}
				/* We would prefer to do dynamic loading here. */

				continue
			}
			let anIns = MKSynthInstrument()!
			synthInstruments.append(anIns)
			partPerformer.noteSender.connect(anIns.noteReceiver)
			anIns.setSynthPatchClass(synthPatchClass)
			guard partInfo.isParPresent(Int32(MK_synthPatchCount.rawValue)) else {
				continue
			}
			let voices = partInfo.par(as: Int32(MK_synthPatchCount.rawValue))
			let synthPatchCount = anIns.setSynthPatchCount(voices, patchTemplate: synthPatchClass.patchTemplate(for: partInfo))
			if synthPatchCount < voices {
				let alert = NSAlert()
				alert.messageText = "ScorePlayer"
				alert.informativeText = "Could only allocate \(synthPatchCount) instead of \(voices) \(className)s for \(MKGetObjectName(aPart) ?? "(nil)")"
				alert.addButton(withTitle: "Continue")
				alert.addButton(withTitle: "Cancel")
				if alert.runModal() == .alertSecondButtonReturn {
					return false
				}
			}
		}
		
		MKSetDeltaT(1.0)
		MKConductor.setClocked(true)
		MKConductor.afterPerformanceSel(#selector(MKMidi.close), to: theOrch, argCount: 0, arg1: nil, retain: false, arg2: nil, retain: false)
		theOrch?.run()
		MKConductor.startPerformance()
		
		return true
	}
	
	func stop() {
		MKConductor.lockPerformance()
	//    [theOrch abort];
		MKConductor.finishPerformance()
		MKConductor.unlockPerformance()
		theOrch?.close()
	}
	
	var isPlaying: Bool {
		if let theOrch, theOrch.deviceStatus() == .running {
			return true
		} else {
			return false
		}
	}
}
