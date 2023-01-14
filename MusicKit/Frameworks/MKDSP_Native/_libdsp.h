#ifndef __MK__libdsp_H___
#define __MK__libdsp_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* _libdsp.h - private functions in libdsp_s.a

	01/13/90/jos - Replaced _DSPMessage.h expansion by explicit import.
*/

#include "MKDSPDefines.h"

#import "_DSPTransfer.h"
#import "_DSPObject.h"
#import "_DSPMach.h"
#import "_DSPMessage.h"

/* ============================= _DSPRelocate.c ============================ */

MKDSP_API int _DSPReloc(DSPDataRecord *data, DSPFixup *fixups,
    int fixupCount, int *loadAddresses);
/* 
 * dataRec is assumed to be a P data space. Fixes it up in place. 
 * This is a private libdsp method used by _DSPSendUGTimed and
 * _DSPRelocate. 
 */

MKDSP_API int _DSPRelocate(void);
MKDSP_API int _DSPRelocateUser(void);

/* ============================= DSPControl.c ============================== */
MKDSP_API int _DSPCheckMappedMode(void);
MKDSP_API int _DSPEnterMappedMode(void);
MKDSP_API int _DSPEnterMappedModeNoCheck(void);
MKDSP_API int _DSPEnterMappedModeNoPing(void);
MKDSP_API int _DSPExitMappedMode(void);
MKDSP_API int _DSPReadSSI();
MKDSP_API int _DSPSetSCISCR();
MKDSP_API int _DSPSetSCISCCR();
MKDSP_API int _DSPSetSSICRA();
MKDSP_API int _DSPSetSSICRB();
MKDSP_API int _DSPSetStartTimed();
MKDSP_API int _DSPSetTime();
MKDSP_API int _DSPSetTimeFromInts();
MKDSP_API int _DSPSineTest();
MKDSP_API int _DSPStartTimed();
MKDSP_API DSPDatum _DSPGetValue();

/* ============================= DSPReadFile.c ============================= */
MKDSP_API char *_DSPFGetRecord();
MKDSP_API int _DSPGetIntHexStr6();
MKDSP_API int _DSPLnkRead();
MKDSP_API char *_DSPAddSymbol();
MKDSP_API int _DSPGetRelIntHexStr();
MKDSP_API char *_DSPUniqueName();

/* ============================ DSPStructMisc.c ============================ */

MKDSP_API int _DSPCheckingFWrite( int *ptr, int size, int nitems, FILE *stream);
MKDSP_API int _DSPWriteString(char *str, FILE *fp);
MKDSP_API int _DSPReadString(char **spp, FILE *fp);
MKDSP_API int _DSPFreeString(char *str);
MKDSP_API char *_DSPContiguousMalloc(unsigned size);
MKDSP_API int _DSPContiguousFree(char *ptr);
MKDSP_API void DSPMemMapInit(_DSPMemMap *mm);
MKDSP_API void DSPMemMapPrint(_DSPMemMap *mm);

MKDSP_API char *_DSPContiguousMalloc(unsigned size);
/*
 *	Same as malloc except allocates in one contiguous piece of
 *	memory.	 Calls realloc as necessary to extend the block.
 */

struct _strarr;

/* ============================ _DSPUtilities.c ============================ */
MKDSP_API void _DSPErr(char *msg);
MKDSP_API char *_DSPFirstReadableFile(char *fn, ...);
MKDSP_API char *_DSPGetBody(char *fn);
MKDSP_API char _DSPGetField(FILE *infile, char *string, char *tklist, int lstr);
MKDSP_API int _DSPGetFilter(char *name, char *dname, int ncmax, int*nic, int*noc, float*ic, float*oc);
MKDSP_API float _DSPGetFloatStr(char **s);
MKDSP_API char *_DSPGetHead(char *fn);
MKDSP_API void _DSPGetInputFile(FILE **ipp, char *din);
MKDSP_API void _DSPGetInputOutputFiles(FILE **ipp, FILE **opp, char *din, char *don);
MKDSP_API int _DSPGetIntStr(char **s);
MKDSP_API char *_DSPGetLineStr(char **s);
MKDSP_API void _DSPGetOutputFile(FILE **opp, char *don);
MKDSP_API char *_DSPGetSN(char *g, int ng);
MKDSP_API char *_DSPGetTail(char *fn);
MKDSP_API char *_DSPGetTokStr(char **s);
MKDSP_API int _DSPInInt(int def, char *name);
MKDSP_API int _DSPIndexS(struct _strarr *stra, register char *str, int nstr);
MKDSP_API char *_DSPIntToChar(int i);
MKDSP_API int *_DSPMakeArray(int size);
MKDSP_API FILE *_DSPMyFopen(char *fn, char *mode);
MKDSP_API char *_DSPPadStr(char *s, int n);
MKDSP_API void _DSPParseName(char *name, char *dname);
MKDSP_API void _DSPPutFilter(char *name, char *dname, int ni, int no, float *ic, float *oc);
MKDSP_API char *_DSPRemoveHead(char *fn);
MKDSP_API char *_DSPRemoveTail(char *fn);
MKDSP_API int _DSPSaveMatD(int mrows, int ncols, int imagf, char *name, double rpart[], double ipart[], FILE *fp);
MKDSP_API int _DSPSezYes(void);
MKDSP_API char *_DSPSkipToWhite(char *s);
MKDSP_API char *_DSPSkipWhite(char *s);
MKDSP_API DSP_BOOL _DSPGetFile(FILE **fpp, char *mode, char *name, char *dname);
MKDSP_API DSPLocationCounter _DSPGetMemStr(char **s, char *type);
MKDSP_API DSP_BOOL _DSPNotBlank(char *s);

/* ============================ DSPConversion.c ============================ */

MKDSP_API DSPFix48 *_DSPDoubleIntToFix48UseArg(double dval,DSPFix48 *aFix48P);
/* 
 * The double is assumed to be between -2^47 and 2^47.
 *  Returns, in *aFix48P, the value as represented by dval. 
 *  aFix48P must point to a valid DSPFix48 struct. 
 */

/* ============================= _DSPError.c =============================== */

MKDSP_API int _DSPCheckErrorFP(void);
/*
 * Check error file-pointer.
 * If nonzero, return.
 * If zero, open /tmp/dsperrors and return file-pointer for it.
 * Also, write DSP interlock info to dsperrors.
 */


MKDSP_API int _DSPErrorV(int errorcode,char *fmt,...);


MKDSP_API int _DSPError1(
    int errorcode,
    char *msg,
    char *arg);


MKDSP_API int _DSPError(
    int errorcode,
    char *msg);


MKDSP_API void _DSPFatalError(
    int errorcode,
    char *msg);


MKDSP_API int _DSPMachError(
    int error,
    char *msg);


MKDSP_API int _DSPCheckErrorFP(void);
/*
 * Check error file-pointer.
 * If nonzero, return.
 * If zero, open /tmp/dsperrors and return file-pointer for it.
 * Also, write DSP interlock info to dsperrors.
 */


MKDSP_API int _DSPErrorV(int errorcode,char *fmt,...);


MKDSP_API int _DSPError1(
    int errorcode,
    char *msg,
    char *arg);


MKDSP_API int _DSPError(
    int errorcode,
    char *msg);


MKDSP_API void _DSPFatalError(
    int errorcode,
    char *msg);


MKDSP_API int _DSPMachError(
    int error,
    char *msg);

/* ============================== _DSPCV.c ================================= */

MKDSP_API char *_DSPCVAS(
    int n,			/* number to be converted */
    int fmt);			/* 0=decimal, 1=hex format */
/* 
 * Convert integer to decimal or hex string 
 */


MKDSP_API char *_DSPCVS(int n);
/* 
 * Convert integer to decimal string 
 */


MKDSP_API char *_DSPCVHS(int n);
/* 
 * Convert integer to hex string 
 */


MKDSP_API char *_DSPCVDS(float d);
/* 
 * Convert double to hex string 
 */


MKDSP_API char *_DSPCVFS(float f);
/* 
 * Convert float to hex string 
 */


MKDSP_API char *_DSPIntToChar(int i);
/* 
 * Convert digit between 0 and 9 to corresponding character.
 */

/* ============================ _DSPString.c =============================== */

MKDSP_API char *_DSPNewStr(int size);
/*
 * Create string of given total length in bytes.
 */


MKDSP_API char *_DSPMakeStr(
    int size,			/* size = total length incl \0 */
    char *init);		/* initialization string */
/* 
 * create new string initialized by given string.
 */


MKDSP_API char *_DSPCat(
    char *f1,
    char *f2);
/*
 * Concatenate two strings 
 */


MKDSP_API char *_DSPReCat(
    char *f1,
    char *f2);
/*
 * append second string to first via realloc 
 */


MKDSP_API char *_DSPCopyStr(char *s);
/*
 * Copy string s into freshly malloc'd storage.
 */


MKDSP_API char *_DSPToLowerStr(
    char *s);			/* input string = output string */
/*
 * Convert all string chars to lower case.
 */


MKDSP_API char *_DSPToUpperStr(
    char *s);			/* input string = output string */
/*
 * Convert all string chars to upper case.
 */

MKDSP_API char *_DSPCopyToUpperStr(
    char *s);			/* input string = output string */
/*
 * Efficient combo of _DSPCopyStr and _DSPToUpperStr 
 */

MKDSP_API int _DSPStrCmpI(char *mixedCaseStr,char *upperCaseStr) ;
/* like strcmp but assumes first arg is mixed case and second is upper case
 * and does a case-independent compare.
 *
 * _DSPStrCmpI compares its arguments and returns an integer greater
 * than, equal to, or less than 0, according as mixedCaseStr is lexico-
 * graphically greater than, equal to, or less than upperCaseStr.
 */

#endif

