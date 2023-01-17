//
//  AppDelegate.swift
//  TwoWavesSwift
//
//  Created by C.W. Betts on 1/16/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

import Cocoa
import SndKit

/// number of seconds of sound to display
let SECONDS: Float = 0.2

let TWOPI = Float.pi * 2
let SAMPLING_RATE: Float = 44100

private func SINWAVE(_ srate: Float, _ freq: Float, _ amp: Float, _ pos: Int) -> Float {
	return (amp * sin(freq * TWOPI * Float(pos)/srate))
}

private func COSWAVE(_ srate: Float, _ freq: Float, _ amp: Float, _ pos: Int) -> Float {
	return (amp * cos(freq * TWOPI * Float(pos)/srate))
}

private func SQUAREWAVE(_ srate: Float, _ freq: Float, _ amp: Float, _ pos: Int) -> Float {
	let hi: Bool = Float(pos % Int(srate / freq)) < (srate / freq / 2)
	return hi ? amp : 0 - amp
}

private func SAWTOOTH(_ srate: Float, _ freq: Float, _ amp: Float, _ pos: Int) -> Float {
	return (2 * amp * Float(pos%Int(srate / freq)) / (srate/freq) - amp)
}

private func REVSAWTOOTH(_ srate: Float, _ freq: Float, _ amp: Float, _ pos: Int) -> Float {
	return -(2 * amp * Float(pos%Int(srate / freq)) / (srate/freq) - amp)
}

private func TRIANGLE(_ srate: Float, _ freq: Float, _ amp: Float, _ pos: Int) -> Float {
	let hi: Bool = Float(pos%Int(srate / freq)) < (srate/freq/2)
	if hi {
		return 2 * amp * Float(pos % Int(srate / freq)) / (srate/freq/2) - amp
	} else {
		return -(2 * amp * Float(pos % Int(srate / freq)) / (srate/freq/2) - 3 * amp)
	}
}

private enum CalcType: Int {
	case sine = 0
	case cosine
	case square
	case sawtooth
	case reversedSawtooth
	case triangle
}

private func doCalc(type aType: CalcType, pointer: UnsafeMutablePointer<Int16>, frequency theFreq: Float, amplitude theAmp: Float) {
	switch aType {
	case .sine:
		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			pointer[i] = Int16(SINWAVE(SAMPLING_RATE, theFreq, theAmp, i))
		}
	case .cosine:
		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			pointer[i] = Int16(COSWAVE(SAMPLING_RATE, theFreq, theAmp, i))
		}
	case .square:
		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			pointer[i] = Int16(SQUAREWAVE(SAMPLING_RATE, theFreq, theAmp, i))
		}
	case .sawtooth:
		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			pointer[i] = Int16(SAWTOOTH(SAMPLING_RATE, theFreq, theAmp, i))
		}
	case .reversedSawtooth:
		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			pointer[i] = Int16(REVSAWTOOTH(SAMPLING_RATE, theFreq, theAmp, i))
		}
	case .triangle:
		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			pointer[i] = Int16(TRIANGLE(SAMPLING_RATE, theFreq, theAmp, i))
		}
	}
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet var window: NSWindow!
	@IBOutlet var frequencyNum1: NSTextField!
	@IBOutlet var frequencyNum2: NSTextField!
	@IBOutlet var frequencySlide1: NSSlider!
	@IBOutlet var frequencySlide2: NSSlider!
	@IBOutlet var soundView1: SndView!
	@IBOutlet var soundView2: SndView!
	@IBOutlet var soundView3: SndView!
	@IBOutlet var volumeNum1: NSTextField!
	@IBOutlet var volumeNum2: NSTextField!
	@IBOutlet var volumeSlide1: NSSlider!
	@IBOutlet var volumeSlide2: NSSlider!
	@IBOutlet var messageBox: NSTextView!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}

	@IBAction func play(_ sender: Any) {
		
	}
	
	@IBAction func playA(_ sender: Any) {
		
	}
	
	@IBAction func playB(_ sender: Any) {
		
	}
	
	@IBAction func updateNums(_ sender: Any) {
		
	}
	
	@IBAction func updateSliders(_ sender: Any) {
		
	}
	
	@IBAction func waveChanged(_ sender: Any) {
		
	}

	@IBAction func changeLength(_ sender: Any) {
		
	}

}

