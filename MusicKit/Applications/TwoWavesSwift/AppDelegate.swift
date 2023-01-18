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
	@IBOutlet var soundLength: NSTextField!
	private var somethingChanged = true
	private var type1 = CalcType.sine
	private var type2 = CalcType.sine

	var theSound1 = Snd(format: .linear16, channelCount: 1, frames: UInt(SAMPLING_RATE * SECONDS), samplingRate: SAMPLING_RATE)
	var theSound2 = Snd(format: .linear16, channelCount: 1, frames: UInt(SAMPLING_RATE * SECONDS), samplingRate: SAMPLING_RATE)
	var theSound3 = Snd(format: .linear16, channelCount: 1, frames: UInt(SAMPLING_RATE * SECONDS), samplingRate: SAMPLING_RATE)
	var newSound = Snd()
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
	
	override class func awakeFromNib() {
		
	}

	@IBAction func play(_ sender: Any) {
		
		
		
		somethingChanged = false

	}
	
	@IBAction func playA(_ sender: Any) {
		
	}
	
	@IBAction func playB(_ sender: Any) {
		
	}
	
	@IBAction func updateNums(_ sender: Any) {
		
	}
	
	@IBAction func updateSliders(_ sender: Any) {
		
	}
	
	@IBAction func waveChanged(_ sender: NSButton?) {
		somethingChanged = true
		if let sendTag = sender?.tag,
		   let aCalc = CalcType(rawValue: sendTag){
			type1 = aCalc
		} else {
			type1 = .sine
		}
		calculateSound1()
		soundView1.invalidateCachePixels(start: 0, end: -1)
		soundView1.needsDisplay = true
		
		calcSound3()
		soundView3.invalidateCachePixels(start: 0, end: -1)
		soundView3.needsDisplay = true
	}

	@IBAction func waveChangedB(_ sender: NSButton?) {
		somethingChanged = true
		if let sendTag = sender?.tag,
		   let aCalc = CalcType(rawValue: sendTag){
			type2 = aCalc
		} else {
			type2 = .sine
		}
		calculateSound2()
		soundView2.invalidateCachePixels(start: 0, end: -1)
		soundView2.needsDisplay = true
		
		calcSound3()
		soundView3.invalidateCachePixels(start: 0, end: -1)
		soundView3.needsDisplay = true
	}

	@IBAction func changeLength(_ sender: Any) {
		somethingChanged = true
	}
	
	private func calculateSound1() {
		let theAmp = volumeNum1.floatValue * 32768 / 10
		let theFreq = frequencyNum1.floatValue
		let pointer = soundView1.sound.bytes.assumingMemoryBound(to: Int16.self)
		doCalc(type: type1, pointer: pointer, frequency: theFreq, amplitude: theAmp)
	}
	
	private func calculateSound2() {
		let theAmp = volumeNum2.floatValue * 32768 / 10
		let theFreq = frequencyNum2.floatValue
		let pointer = soundView2.sound.bytes.assumingMemoryBound(to: Int16.self)
		doCalc(type: type2, pointer: pointer, frequency: theFreq, amplitude: theAmp)
	}
	
	private func calcSound3() {
		var clipping = false
		let pointer1 = soundView1.sound.bytes.assumingMemoryBound(to: Int16.self)
		let pointer2 = soundView2.sound.bytes.assumingMemoryBound(to: Int16.self)
		let pointer3 = soundView3.sound.bytes.assumingMemoryBound(to: Int16.self)

		for i in 0 ..< Int(SECONDS * SAMPLING_RATE) {
			var newVal = Int32(pointer1[i]) + Int32(pointer2[i])
			
			if (newVal > 32768 || newVal < -32767) {
				clipping = true
			}
			pointer3[i] = Int16(clamping: newVal)
		}
		
		if clipping {
			messageBox.string = "Combined amplitudes of sounds are too high and are causing clipping. Reduce amplitudes of one or both."
		} else {
			messageBox.string = ""
		}
		messageBox.needsDisplay = true
	}

}
