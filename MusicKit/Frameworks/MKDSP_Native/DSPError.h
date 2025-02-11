#ifndef __MK_DSPError_H___
#define __MK_DSPError_H___
/* DSPError.h - Functions in libdsp_s.a having to do with error handling
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

#include <MKDSP/MKDSPDefines.h>

/***************************** Error Enabling ********************************/

MKDSP_API int DSPEnableErrorLog(void);
/* 
 * Turn on DSP error logging into the current error log file
 * set by DSPSetErrorFile().
 */


MKDSP_API int DSPDisableErrorLog(void);
/* 
 * Turn off DSP error message logging.
 */


MKDSP_API int DSPErrorLogIsEnabled(void);
/* 
 * Returns nonzero if DSP error logging is enabled.
 */

/******************************* ERROR FILE CONTROL **************************/

MKDSP_API int DSPEnableErrorFile(const char *fn);
/* 
 * Turn on DSP error message logging (equivalent to DSPEnableErrorLog())
 * and set the error file to fn (equivalent to DSPSetErrorFile(fn)).
 */


MKDSP_API int DSPEnableErrorFP(FILE *fp);
/* 
 * Turn on DSP error message logging (equivalent to DSPEnableErrorLog())
 * and set the error file pointer to fp (equivalent to DSPSetErrorFP(fp)).
 */


MKDSP_API int DSPSetErrorFile(const char *fn);
/* 
 * Set the file-name for DSP error messages to fn.
 * The default file used if this is not called is
 * DSP_ERRORS_FILE defined in dsp.h.
 * This will clear any file-pointer specified using
 * DSPSetErrorFP().
 */


MKDSP_API const char *DSPGetErrorFile(void);
/* 
 * Get the file-name being used for DSP error messages, if known.
 * If unknown, such as when only a file-pointer was passed to
 * specify the output destination, 0 is returned.
 */


MKDSP_API int DSPSetErrorFP(FILE *fp);
/* 
 * Set the file-pointer for DSP error messages to fp.
 * The file-pointer will clear and override any prior specification
 * of the error messages filename using DSPSetErrorFile().
 */


MKDSP_API FILE *DSPGetErrorFP(void);
/* 
 * Get the file-pointer being used for DSP error messages.
 */


MKDSP_API int DSPCloseErrorFP(void);
/*
 * Close DSP error log file.
 */


/******************************* Error File Usage ****************************/


MKDSP_API int DSPUserError(
    int errorcode,
    char *msg);
/* 
 * Print message string 'msg' and integer error code 'errorcode' to the
 * DSP error log (if any), and return errorcode.  The message string 
 * normally identifies the calling function and the nature of the error.
 * The error code is arbitrary, but positive integers are generally in
 * use by other packages.
 */


MKDSP_API int DSPUserError1(
    int errorcode,
    char *msg,
    char *str);
/* 
 * Print message string 'msg' and integer error code 'errorcode' to the
 * DSP error log (if any), and return errorcode.  The message string is
 * assumed to contain a single occurrence of '%s' which corresponds to the
 * desired placement of 'str' in the style of printf().
 */


MKDSP_API char *DSPMessageExpand(int msg);
/*
 * Convert 24-bit DSP message into a string containing mnemonic message 
 * opcode and argument datum in hex. Example: The DSP message 0x800040
 * expands into "BREAK(0x0040)" which means a breakpoint occurred in the DSP
 * at location 0x40.  (DSP messages are messages from the DSP to the host,
 * as read by DSPReadMessages().  They are not error codes returned by 
 * libdsp functions.)
 */

#endif
