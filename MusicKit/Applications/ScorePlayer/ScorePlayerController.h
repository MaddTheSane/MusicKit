#ifndef __MK_ScorePlayerController_H___
#define __MK_ScorePlayerController_H___

#import <AppKit/AppKit.h>
#import <MusicKitLegacy/MKConductor.h>
#define TEXT 0

@interface ScorePlayerController: NSObject <MKConductorDelegate, NSMenuItemValidation>
{
    IBOutlet NSButton *playButton;
    IBOutlet NSPanel *soundSavePanel;
    IBOutlet NSTextField *soundWriteMsg;
    IBOutlet NSSlider *tempoSlider;
    IBOutlet NSTextField *tempoTitle;
    IBOutlet NSTextField *tempoTextField;
    IBOutlet NSWindow *theMainWindow;
    IBOutlet NSTextField *tooFastErrorMsg;
    IBOutlet NSButton *timeCodeButton;
    IBOutlet NSMatrix *timeCodePortMatrix;
    IBOutlet NSTextField *timeCodeTextField;
    IBOutlet NSPopUpButton *defaultMidiPopUp; // The popup that lists available MIDI drivers for the default "midi" device.
    IBOutlet NSPopUpButton *soundOutputDevicePopUp;  // The popup that lists available sound output devices.
    IBOutlet NSTextField *serialPortDeviceNameField;
    
    // Redundant NeXT specific hardware, needs to be removed.
    IBOutlet NSButton *NeXTDacMuteSwitch;
    IBOutlet NSSlider *NeXTDacVolumeSlider;
    IBOutlet NSPanel *SSAD64xPanel;
    IBOutlet NSPanel *StealthDAI2400Panel;
    IBOutlet NSPanel *NeXTDACPanel;

    // Name of the sound output device.
    NSString *soundOutDeviceName;
}

- (IBAction) help: (id) sender;
- (IBAction) openEditFile: (id) sender;
- (IBAction) deviceSpecificSettings: (id) sender;
// Sets the audio output from the selected list.
- (IBAction) setSoundOutFrom: (id) sender;
// Sets the default MIDI driver name from the selected list.
- (IBAction) setMidiDriverName: (id) sender;
- (IBAction) setTempoFrom: (id) sender;
- (IBAction) setTimeCodeSynch: (id) sender;
- (IBAction) setTimeCodeSerialPort: (id) sender;
// Enables or disables tempo adjustment
- (IBAction) setTempoAdjustment: (id) sender;
- (IBAction) saveAsDefaultDevice: (id) sender;
- (IBAction) playStop: (id) sender;
- (IBAction) selectFile: (id) sender;
- (IBAction) showErrorLog: (id) sender;
- (IBAction) saveScoreAs: (id) sender;
- (IBAction) setNeXTDACVolume: (id) sender;
- (IBAction) setNeXTDACMute: (id) sender;
- (IBAction) getNeXTDACCurrentValues: (id) sender;
- (IBAction) setAD64xConsumer: (id) sender;
- (IBAction) setAD64xProfessional: (id) sender;

@end

#endif
