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
#import <MusicKit/noDVal.h>              /* Type double utilities */
#import <MusicKit/errors.h>              /* Error codes, debug flags and functions. */
#import <MusicKit/names.h>               /* Various name tables */
#import <MusicKit/midiTranslation.h>     /* Note<->MIDI translation */
#import <MusicKit/classFuncs.h>          /* Stand-in classes */
#import <MusicKit/midi_spec.h>		/* standard MIDI definitions */
#import <MusicKit/fastFFT.h>

/* Music Kit classes. */
#import <MusicKit/MKConductor.h>
#import <MusicKit/MKEnvelope.h>
#import <MusicKit/MKFilePerformer.h>
#import <MusicKit/MKFileWriter.h>
#import <MusicKit/MKInstrument.h>
#import <MusicKit/MKMidi.h>
#import <MusicKit/MKMixerInstrument.h>
#import <MusicKit/MKNote.h>
#import <MusicKit/MKNoteFilter.h>
#import <MusicKit/MKNoteReceiver.h>
#import <MusicKit/MKNoteSender.h>
#import <MusicKit/MKMTCPerformer.h>
#import <MusicKit/MKOrchestra.h>
#import <MusicKit/MKPart.h>
#import <MusicKit/MKPartPerformer.h>
#import <MusicKit/MKPartRecorder.h>
#import <MusicKit/MKPatchTemplate.h>
#import <MusicKit/MKPartials.h>
#import <MusicKit/MKPerformer.h>
#import <MusicKit/MKPlugin.h>
#import <MusicKit/MKTimbre.h>
#import <MusicKit/MKSamplePlayerInstrument.h>
#import <MusicKit/MKSamples.h>
#import <MusicKit/MKScore.h>
#import <MusicKit/MKScorePerformer.h>
#import <MusicKit/MKScoreRecorder.h>
#import <MusicKit/MKScorefileObject.h>
#import <MusicKit/MKScorefilePerformer.h>
#import <MusicKit/MKScorefileWriter.h>
#import <MusicKit/MKSynthData.h>
#import <MusicKit/MKSynthInstrument.h>
#import <MusicKit/MKSynthPatch.h>
#import <MusicKit/MKTuningSystem.h>
#import <MusicKit/MKUnitGenerator.h>
#import <MusicKit/MKWaveTable.h>
#import <MusicKit/MKPatchConnection.h>
#import <MusicKit/MKPatchEntry.h>

#endif /* MUSICKIT_H */

#ifdef __cplusplus
}
#endif

