/*
 $Id$
 
 Description:
   Enumerates and describes the various sound sample data formats which can processed
   by the MusicKit and SndKit.
 
 Original Author: Stephen Brandon

 Copyright (c) 1999 Stephen Brandon and the University of Glasgow
 Additions Copyright (c) 2004, The MusicKit Project.  All rights reserved.
 
 Legal Statement Covering Additions by Stephen Brandon and the University of Glasgow:

 This framework and all source code supplied with it, except where specified, are
 Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use
 the source code for any purpose, including commercial applications, as long as you
 reproduce this notice on all such software.
 
 Software production is complex and we cannot warrant that the Software will be error free.
 Further, we will not be liable to you if the Software is not fit for the purpose for which
 you acquired it, or of satisfactory quality. 
 
 WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED
 BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR
 PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.
 
 If a court finds that we are liable for death or personal injury caused by our negligence our
 liability shall be unlimited.  
 
 WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA,
 LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE
 OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE
 OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS
 OF THIS AGREEMENT.
 
 Legal Statement Covering Additions by The MusicKit Project:

 Permission is granted to use and modify this code for commercial and
 non-commercial purposes so long as the author attribution and copyright
 messages remain intact and accompany all relevant code.
 
 */
/*!
  @header SndFormats
 
  @brief Enumerates and describes the various sound sample data formats which can processed
  by the MusicKit and SndKit.
 */

#ifndef __SNDFORMATS__
#define __SNDFORMATS__

#import <Foundation/NSObjCRuntime.h>

/*!
  @enum       SndSampleFormat
  @brief   Various sound sample data formats
  @constant   SND_FORMAT_UNSPECIFIED
  @constant   SndSampleFormatMulaw8  u-law encoding.
  @constant   SndSampleFormatLinear8  Linear 8 bits.
  @constant   SndSampleFormatLinear16   Linear 16 bits.
  @constant   SndSampleFormatLinear24   Linear 24 bits.
  @constant   SndSampleFormatLinear32   Linear 32 bits.
  @constant   SndSampleFormatFloat       IEEE Floating Point 32 bits.
  @constant   SndSampleFormatDouble      Floating Point 64 bits, could even be IEEE 80 bit Floating Point.
  @constant   SndSampleFormatIndirect    Fragmented.
  @constant   SndSampleFormatNested
  @constant   SndSampleFormatDspCore
  @constant   SndSampleFormatDspData8
  @constant   SndSampleFormatDspData16
  @constant   SndSampleFormatDspData24
  @constant   SndSampleFormatDspData32
  @constant   SndSampleFormatDisplay
  @constant   SndSampleFormatMulawSquelch
  @constant   SndSampleFormatEmphasized
  @constant   SndSampleFormatCompressed Julius O. Smith III's SoundKit compressed format.
  @constant   SndSampleFormatCompressedEmphasized Julius O. Smith III's SoundKit compressed format.
  @constant   SndSampleFormatDspCommands MC56001 DSP instruction opcodes.
  @constant   SndSampleFormatDspCommandsSamples audio data in a format suitable for MC56001 DSP use?
  @constant   SndSampleFormatAdpcmG721  GSM compressed format.
  @constant   SndSampleFormatAdpcmG722  GSM compressed format.
  @constant   SndSampleFormatAdpcmG723_3  GSM compressed format.
  @constant   SndSampleFormatAdpcmG723_5  GSM compressed format.
  @constant   SndSampleFormatAlaw8  a-law encoding.
  @constant   SndSampleFormatAes  a format specified by the Audio Engineering Society?
  @constant   SndSampleFormatDeltaMulaw8
  @constant   SndSampleFormatMp3  MPEG-1 Layer 3 audio format.
  @constant   SndSampleFormatAac  MPEG-4 Advanced Audio Coder.
  @constant   SndSampleFormatAc3  Dolby AC3 A/52 encoding.
  @constant   SndSampleFormatVorbis  Ogg/Vorbis compressed format.
 */
typedef NS_ENUM(int, SndSampleFormat) {
    SndSampleFormatUnspecified = 0,
    /// u-law encoding
    SndSampleFormatMulaw8 = 1,
    /// Linear 8 bits
    SndSampleFormatLinear8 = 2,
    /// Linear 16 bits
    SndSampleFormatLinear16 = 3,
    /// Linear 24 bits
    SndSampleFormatLinear24 = 4,
    /// Linear 32 bits
    SndSampleFormatLinear32 = 5,
    /// IEEE Floating Point 32 bits
    SndSampleFormatFloat = 6,
    /// Floating Point 64 bits, could even be IEEE 80 bit Floating Point
    SndSampleFormatDouble = 7,
    /// Fragmented
    SndSampleFormatIndirect = 8,

    SndSampleFormatNested = 9,

    SndSampleFormatDspCore = 10,

    SndSampleFormatDspData8 = 11,

    SndSampleFormatDspData16 = 12,

    SndSampleFormatDspData24 = 13,

    SndSampleFormatDspData32 = 14,

    SndSampleFormatDisplay = 16,

    SndSampleFormatMulawSquelch = 17,

    SndSampleFormatEmphasized = 18,
    /// Julius O. Smith III's SoundKit compressed format
    SndSampleFormatCompressed = 19,
    /// Julius O. Smith III's SoundKit compressed format
    SndSampleFormatCompressedEmphasized = 20,
    /// MC56001 DSP instruction opcodes
    SndSampleFormatDspCommands = 21,
    /// audio data in a format suitable for MC56001 DSP use?
    SndSampleFormatDspCommandsSamples = 22,
    /// GSM compressed format
    SndSampleFormatAdpcmG721 = 23,
    /// GSM compressed format
    SndSampleFormatAdpcmG722 = 24,
    /// GSM compressed format
    SndSampleFormatAdpcmG723_3 = 25,
    /// GSM compressed format
    SndSampleFormatAdpcmG723_5 = 26,
    /// a-law encoding
    SndSampleFormatAlaw8 = 27,
    /// a format specified by the Audio Engineering Society?
    SndSampleFormatAes = 28,

    SndSampleFormatDeltaMulaw8 = 29,
    /// MPEG-1 Layer 3 audio format
    SndSampleFormatMp3 = 30,
    /// MPEG-4 Advanced Audio Coder
    SndSampleFormatAac = 31,
    /// Dolby AC3 A/52 encoding
    SndSampleFormatAc3 = 32,
    /// Ogg/Vorbis compressed format
    SndSampleFormatVorbis = 33,
};

#define DeprecatedEnum(type, oldname, newval) \
static const type oldname NS_DEPRECATED_WITH_REPLACEMENT_MAC( #newval , 10.0, 10.8) = newval

DeprecatedEnum(SndSampleFormat, SND_FORMAT_UNSPECIFIED, SndSampleFormatUnspecified);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_MULAW_8, SndSampleFormatMulaw8);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_LINEAR_8, SndSampleFormatLinear8);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_LINEAR_16, SndSampleFormatLinear16);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_LINEAR_24, SndSampleFormatLinear24);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_LINEAR_32, SndSampleFormatLinear32);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_FLOAT, SndSampleFormatFloat);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DOUBLE, SndSampleFormatDouble);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_INDIRECT, SndSampleFormatIndirect);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_NESTED, SndSampleFormatNested);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_CORE, SndSampleFormatDspCore);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_DATA_8, SndSampleFormatDspData8);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_DATA_16, SndSampleFormatDspData16);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_DATA_24, SndSampleFormatDspData24);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_DATA_32, SndSampleFormatDspData32);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DISPLAY, SndSampleFormatDisplay);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_MULAW_SQUELCH, SndSampleFormatMulawSquelch);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_EMPHASIZED, SndSampleFormatEmphasized);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_COMPRESSED, SndSampleFormatCompressed);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_COMPRESSED_EMPHASIZED, SndSampleFormatCompressedEmphasized);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_COMMANDS, SndSampleFormatDspCommands);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DSP_COMMANDS_SAMPLES, SndSampleFormatDspCommandsSamples);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_ADPCM_G721, SndSampleFormatAdpcmG721);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_ADPCM_G722, SndSampleFormatAdpcmG722);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_ADPCM_G723_3, SndSampleFormatAdpcmG723_3);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_ADPCM_G723_5, SndSampleFormatAdpcmG723_5);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_ALAW_8, SndSampleFormatAlaw8);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_AES, SndSampleFormatAes);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_DELTA_MULAW_8, SndSampleFormatDeltaMulaw8);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_MP3, SndSampleFormatMp3);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_AAC, SndSampleFormatAac);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_AC3, SndSampleFormatAc3);
DeprecatedEnum(SndSampleFormat, SND_FORMAT_VORBIS, SndSampleFormatVorbis);

#undef DeprecatedEnum

#endif
