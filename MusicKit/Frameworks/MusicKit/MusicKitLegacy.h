/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the main public include file that will include all other class header files.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2003 The MusicKit Project.
*/

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MUSICKIT_H
#define MUSICKIT_H

/* Include files outside of the Music Kit. */
#import <Foundation/Foundation.h>           /* Contains nil, etc. */

// These used to be in NS3.3 ansi/math.h but are no longer
// However they are in System.framework on Win32 which is typically #imported afterwards...sigh
#if !defined(MAXSHORT) // && !defined(WIN32)
#define MAXSHORT ((short)0x7fff)
#endif
#if !defined(MAXINT)
#define MAXINT  ((int)0x7fffffff)       /* max pos 32-bit int */
#endif

 /* Music Kit include files */
#import <MusicKitLegacy/noDVal.h>              /* Type double utilities */
#import <MusicKitLegacy/errors.h>              /* Error codes, debug flags and functions. */
#import <MusicKitLegacy/names.h>               /* Various name tables */
#import <MusicKitLegacy/midiTranslation.h>     /* Note<->MIDI translation */
#import <MusicKitLegacy/classFuncs.h>          /* Stand-in classes */
#import <MusicKitLegacy/midi_spec.h>		/* standard MIDI definitions */
#import <MusicKitLegacy/fastFFT.h>

/* Music Kit classes. */
#import <MusicKitLegacy/MKConductor.h>
#import <MusicKitLegacy/MKEnvelope.h>
#import <MusicKitLegacy/MKFilePerformer.h>
#import <MusicKitLegacy/MKFileWriter.h>
#import <MusicKitLegacy/MKInstrument.h>
#import <MusicKitLegacy/MKMidi.h>
#import <MusicKitLegacy/MKMixerInstrument.h>
#import <MusicKitLegacy/MKNote.h>
#import <MusicKitLegacy/MKNoteFilter.h>
#import <MusicKitLegacy/MKNoteReceiver.h>
#import <MusicKitLegacy/MKNoteSender.h>
#import <MusicKitLegacy/MKMTCPerformer.h>
#import <MusicKitLegacy/MKOrchestra.h>
#import <MusicKitLegacy/MKPart.h>
#import <MusicKitLegacy/MKPartPerformer.h>
#import <MusicKitLegacy/MKPartRecorder.h>
#import <MusicKitLegacy/MKPatchTemplate.h>
#import <MusicKitLegacy/MKPartials.h>
#import <MusicKitLegacy/MKPerformer.h>
#import <MusicKitLegacy/MKPlugin.h>
#import <MusicKitLegacy/MKTimbre.h>
#import <MusicKitLegacy/MKSamplePlayerInstrument.h>
#import <MusicKitLegacy/MKSamples.h>
#import <MusicKitLegacy/MKScore.h>
#import <MusicKitLegacy/MKScorePerformer.h>
#import <MusicKitLegacy/MKScoreRecorder.h>
#import <MusicKitLegacy/MKScorefileObject.h>
#import <MusicKitLegacy/MKScorefilePerformer.h>
#import <MusicKitLegacy/MKScorefileWriter.h>
#import <MusicKitLegacy/MKSynthData.h>
#import <MusicKitLegacy/MKSynthInstrument.h>
#import <MusicKitLegacy/MKSynthPatch.h>
#import <MusicKitLegacy/MKTuningSystem.h>
#import <MusicKitLegacy/MKUnitGenerator.h>
#import <MusicKitLegacy/MKWaveTable.h>
#import <MusicKitLegacy/MKPatchConnection.h>
#import <MusicKitLegacy/MKPatchEntry.h>

#endif /* MUSICKIT_H */

#ifdef __cplusplus
}
#endif

