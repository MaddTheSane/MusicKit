/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#ifndef __SNDFORMATS__
#define __SNDFORMATS__

typedef enum {
    SND_FORMAT_UNSPECIFIED          = 0,
    SND_FORMAT_MULAW_8              = 1, /* u-law encoding */
    SND_FORMAT_LINEAR_8             = 2, /* Linear 8 bits */
    SND_FORMAT_LINEAR_16            = 3, /* Linear 16 bits */
    SND_FORMAT_LINEAR_24            = 4, /* Linear 24 bits */
    SND_FORMAT_LINEAR_32            = 5, /* Linear 32 bits */
    SND_FORMAT_FLOAT                = 6, /* IEEE FP 32 bits */
    SND_FORMAT_DOUBLE               = 7,
    SND_FORMAT_INDIRECT             = 8,
    SND_FORMAT_NESTED               = 9,
    SND_FORMAT_DSP_CORE             = 10,
    SND_FORMAT_DSP_DATA_8           = 11,
    SND_FORMAT_DSP_DATA_16          = 12,
    SND_FORMAT_DSP_DATA_24          = 13,
    SND_FORMAT_DSP_DATA_32          = 14,
    SND_FORMAT_DISPLAY              = 16,
    SND_FORMAT_MULAW_SQUELCH        = 17,
    SND_FORMAT_EMPHASIZED           = 18,
    SND_FORMAT_COMPRESSED           = 19,
    SND_FORMAT_COMPRESSED_EMPHASIZED = 20,
    SND_FORMAT_DSP_COMMANDS         = 21,
    SND_FORMAT_DSP_COMMANDS_SAMPLES = 22,
    SND_FORMAT_ADPCM_G721           = 23,
    SND_FORMAT_ADPCM_G722           = 24,
    SND_FORMAT_ADPCM_G723_3         = 25,
    SND_FORMAT_ADPCM_G723_5         = 26,
    SND_FORMAT_ALAW_8               = 27, /* a-law encoding */
    SND_FORMAT_AES                  = 28,
    SND_FORMAT_DELTA_MULAW_8	    = 29
} SndSampleFormat;

#endif
