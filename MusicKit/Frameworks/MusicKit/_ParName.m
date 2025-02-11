/*
 $Id$
 Defined In: The MusicKit

 Description:
   See _ParName.h
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2004 The MusicKit Project.
 */
/*
 Modification history prior to commit to CVS:
 
 09/18/89/daj - Changes to accomodate new way of doing parameters (structs
                                                                   rather than objects).
 09/22/89/daj - Changes to accomodate changes in _MKNameTable.
 parameter.m:
 09/22/89/daj - Added _MK_BACKHASH bit or'ed in with type when adding name,
 to accommodate new way of handling back-hashing.
 10/06/89/daj - Type changes for new _MKNameTable implementation.
 10/15/89/daj - Merged _ParName.m and parameter.m and flushed global functions
 that are no longer needed.
 10/20/89/daj - Added binary scorefile support.
 Changed writeData() to give anonymous data a default name
 of the form class-name# where # is an integer.
 02/01/90/daj - Fixed trace message.
 Fixed bug in anonymous data naming.
 Added comments.
 03/05/90/daj - Added _MKSymbolize() call in _MKGetPar() to insure that
 parameter names are valid scorefile symbols. Changed
 scorefile string-printing routine (_MKParWriteStdValueOn)
 to encode chars such as \n as character escape codes.
 03/21/90/daj - Small changes to quiet -W compiler warnings.
 08/13/90/daj - Added _MKParNameStr().
 09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
 10/04/92/daj - Fixed bug that would cause a crash if you try and write a
 parameter with a nil value (a rather bizarre thing to do, admitedly).
 Currently, I'm writing a zero now.  This is not quite right either.
 I should probably define a Scorefile symbol "nil".
 1/30/96/daj -  Changed _MKParWriteStdValueOn to use _MKParAsStringNoCopy().
 Also changed default of _MKParAsStringNoCopy to do no copy.
 */
#import <ctype.h>

#define MK_INLINE 1
#import "_musickit.h"
#import "tokens.h"
#import "TuningSystemPrivate.h"
#import "_error.h"
#import "_MKNameTable.h"
#import "PartialsPrivate.h"
#import "MKEnvelope.h"
#import "_ParName.h"
/* First, here's how parameter names are represented: */

@implementation _ParName

#define BINARY(_p) (_p && _p->_binary) /* writing a binary scorefile? */

static id newParName(const NSString * name,int param)
/* Make a new one */
{
  register _ParName *self = [_ParName new];
  self->s = [(const id)name copy];
  _MKNameGlobal((const id)name,self,_MK_param | _MK_BACKHASHBIT,YES,YES);
  self->par = param;
  self->printfunc = NULL;
  return self;
}

unsigned _MKGetParNamePar(_ParName *self)
/* Return parameter */
{
  return self->par;
}


/* Here's a lot of initialization. */

static _ParName **parIds = NULL; /* Par name array. */

/* Define parameter names */
#import "parNames.m"

static void initParNames(unsigned int fromPar, unsigned int toPar)
/* Initialize all NeXT parameters */
{
  register unsigned i;
  register _ParName **parId = &(parIds[fromPar]);
  const NSString * *parNamePtr = (const NSString **) &(parNames[fromPar]);
  for (i = fromPar; i < toPar; i++)
    *parId++ = newParName((NSString *) *parNamePtr++, i);
}

static BOOL keywordsPrintfunc(_MKParameter *parameter, NSMutableData *aStream, _MKScoreOutStruct *p)
/* Used to write parameters with keyword-valued arguments. */
{
  int i = _MKParAsInt(parameter);
  if (BINARY(p))
    _MKWriteIntPar(aStream,i);
  else if (!_MK_VALIDTOKEN(i))
    [aStream appendData:[[NSString stringWithFormat:@"%d", i] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
  else [aStream appendBytes:_MKTokName(i) length:strlen(_MKTokName(i))];
  return YES;
}

/* For keeping track of application-defined parameters: */
static int parArrSize = (int)MK_appPars;
static int highestPar = _MK_FIRSTAPPPAR - 1;

id _MKParNameObj(int aPar)
/* Returns _ParName object of specified parameter. aPar must be a valid
parameter */
{
  return parIds[aPar];
}

NSString *_MKParNameStr(int aPar)
/* Returns _ParName object of specified parameter. aPar must be a valid
parameter */
{
  return parIds[aPar]->s;
}

int MKHighestPar()
/* Returns the number of the most recently-created parameter name */
{
  return highestPar;
}

/* Gets parameter name, installing if necessary. Also returns _ParName object by reference. */
int _MKGetPar(NSString *aName, _ParName **aPar)
{
    unsigned short type;
    
    if (aName == nil) 
	return MK_noPar;
    if (![aName lengthOfBytesUsingEncoding: NSUTF8StringEncoding]) {
	return MK_noPar; /* DAJ - Jan 27, 96 */
    }
    *aPar = _MKGetNamedGlobal(aName,&type);
    if (*aPar)
	return (int) _MKGetParNamePar(*aPar);
    else {
	/* Allocates a new parameter number and sets obj's instance variable to that number. */
#       define EXPANDAMT 5
	BOOL wasChanged;
	
	aName = _MKSymbolize(aName, &wasChanged); /* Make valid sf symbol */
	*aPar = newParName(aName, ++highestPar);
//	if (wasChanged) { /* _MKSymbolize copied the string */
	    if (highestPar >= parArrSize) {
		_MK_REALLOC(parIds, _ParName *, (highestPar + EXPANDAMT));
		parArrSize = highestPar + EXPANDAMT;
	    }
//	}
	parIds[highestPar] = *aPar;
	if (MKIsTraced(MKTraceParameters))
	    NSLog(@"Adding new parameter %@\n", (*aPar)->s);
	return highestPar;
    }
}

static void initSyns()
/* Install synonyms. */
{
    register unsigned int i;
    register const NSString * *parNamePtr = (const NSString **) &(parSynNames[0]);
    register int *parSynPtr = (int *) &(parSyns[0]);
    _ParName *oldObj, *newObj;
    
    for (i = 0; i < SYNS; i++) {
	oldObj = _MKParNameObj(*parSynPtr);
	newObj = newParName((NSString *) *parNamePtr++, *parSynPtr++);
	newObj->printfunc = oldObj->printfunc;
	/* Same printfunc */
    }
}


#define INT(_x) ((int)_x)

BOOL
_MKParInit(void)
/* Sent once from Note. Returns YES. Initializes the world */
{
  _MK_CALLOC(parIds, id, _MK_maxPrivPar);
  initParNames(MK_noPar, MK_privatePars);
  initParNames(MK_privatePars + 1, _MK_maxPrivPar);
  initSyns();
  parIds[INT(MK_keyNum)]->printfunc = _MKKeyNumPrintfunc;
  parIds[INT(MK_freq)]->printfunc = _MKFreqPrintfunc;
  parIds[INT(MK_freq0)]->printfunc = _MKFreqPrintfunc;
  parIds[INT(MK_chanMode)]->printfunc = keywordsPrintfunc;
  parIds[INT(MK_sysRealTime)]->printfunc = keywordsPrintfunc;
  return YES;
}


/* Primitives for creating, freeing and copying _MKParameters */

#define CACHESIZE 100
static _MKParameter * _cache[100]; /* Avoid unnecessary malloc/free */
static unsigned _cachePtr = 0;

static _MKParameter * newPar(parNum)
int parNum;
/* Returns new _MKParameter struct */
{
  register _MKParameter *param;
  // we assume that the cached param has been previously nullified
  if (_cachePtr > 0)
    param = _cache[--_cachePtr];
  else _MK_CALLOC(param,_MKParameter,1);
  param->parNum = parNum;
  return param;
}

static inline void releaseParIfNecessary(_MKParameter *param)
{
  switch (param->_uType) {
      case MK_string:
      case MK_envelope:
      case MK_waveTable:
      case MK_object:
        [param->_uVal.symbol release];
      default:
      ;
  }
}

#define DEBUG_CACHE 0

_MKParameter *_MKFreeParameter(_MKParameter *param)
/* Frees object and string datum, if any. */
{
  if (!param)
    return NULL;
#   if DEBUG_CACHE
  {
    int i;
    for (i=0; i<_cachePtr; i++)
      if (_cache[i] == param) {
        NSLog(@"Attempt to free freed parameter.\n");
        return NULL;
      }
  }
#   endif
    releaseParIfNecessary(param);
    param->_uVal.symbol = nil; // it's a union, so this does the int and double too.
    if (_cachePtr < CACHESIZE)
      _cache[_cachePtr++] = param;
    else {
      free(param);
      param = NULL;
    }
    return NULL;
}

BOOL _MKIsParPublic(_MKParameter *param)
/* Returns whether this is a public parameter. */
{
  return _MKIsPar(parIds[param->parNum]->par);
}

_MKParameter *_MKCopyParameter(_MKParameter *param)
/* Creates a copy of the _MKParameter */
{
  _MKParameter *newOne;
  if (!param)
    return NULL;
  newOne = newPar(param->parNum);
  newOne->_uVal = param->_uVal;
  newOne->_uType = param->_uType;
  switch (param->_uType) {
      case MK_string:
      case MK_envelope:
      case MK_waveTable:
      case MK_object:
        [newOne->_uVal.symbol retain];
      default:
      ;
  }
return newOne;
}


/* All of the following return a new _MKParameter struct initialized as
specified */

_MKParameter * _MKNewDoublePar(double value, int parNum)
{
  register _MKParameter *param = newPar(parNum);
  param->_uType = MK_double;
  param->_uVal.rval = value;
  return param;
}

_MKParameter * _MKNewStringPar(NSString * value, int parNum)
{
  register _MKParameter *param = newPar(parNum);
  param->_uType = MK_string;
  param->_uVal.sval = [value retain]; // no need to release old val as we assume nil
    return param;
}

_MKParameter * _MKNewIntPar(int value, int parNum)
{
  register _MKParameter *param = newPar(parNum);
  param->_uType = MK_int;
  param->_uVal.ival = value;
  return param;
}

_MKParameter * _MKNewObjPar(id value, int parNum, _MKToken type)
{
  register _MKParameter *param = newPar(parNum);
  param->_uType = type;
  param->_uVal.symbol = [value retain]; // no need to release old val as we assume nil
  return param;
}


/* All of the following set the parameter struct to the value indicated */

_MKParameter * _MKSetDoublePar(_MKParameter * param, double value)
/* Set the Parameter to type and double and assign doubleVal. */
{
  releaseParIfNecessary(param);
  param->_uType = MK_double;
  param->_uVal.rval = value;
  return param;
}

_MKParameter * _MKSetIntPar(_MKParameter *param, int value)
/* Set the Parameter to type int and assign intVal. */
{
  releaseParIfNecessary(param);
  param->_uType = MK_int;
  param->_uVal.ival = value;
  return param;
}

_MKParameter * _MKSetStringPar(_MKParameter *param, NSString *value)
/* Set the Parameter to type string and add a reference to stringVal. */
{
  releaseParIfNecessary(param);
  param->_uVal.sval = [value retain];
  param->_uType = MK_string;
  return param;
}

_MKParameter * _MKSetObjPar(_MKParameter *param, id value, _MKToken type)
/* Sets obj field and type */
{
  releaseParIfNecessary(param);
  param->_uVal.symbol = [value retain];
  param->_uType = type;
  return param;
}

static double firstEnvValue(param)
_MKParameter *param;
/* If receiver is not type MK_envelope, returns MK_NODVAL. Otherwise,
returns the first value of the envelope multiplied by yScale plus
yOffset. If the receiver is envelope typed but the object is not
an envelope, returns MK_NODVAL. */
{
  double rtn,dummy,dummy2;
  id env;
  if (param->_uType == MK_envelope)
    env = param->_uVal.symbol;
  else return MK_NODVAL;
  if ((![env isKindOfClass: _MKClassEnvelope()]) ||
      ([env getNth:0 x:&dummy y:&rtn smoothing:&dummy2] <MK_noEnvError))
    return MK_NODVAL;
  return rtn;
}

int _MKParAsInt(_MKParameter *param)
/* Get the current value as an integer. If the receiver is envelope-valued,
returns truncated firstEnvValue(param). If the receiver is
waveTable-valued, returns MAXINT.
*/
{
  switch (param->_uType) {
    case MK_double:
      return ((int) param->_uVal.rval);
    case MK_string:
      return (_MKStringToInt(param->_uVal.sval));
    case MK_int:
      return param->_uVal.ival;
    case MK_envelope:
      return (int)firstEnvValue(param);
    default:
      break;
  }
  return MAXINT;
}

double _MKParAsDouble(_MKParameter *param)
/* Get the current value as a double. If the receiver is envelope-valued,
returns firstEnvValue(param). If the receiver is waveTable-valued
returns MK_NODVAL. */
{
  switch (param->_uType) {
    case MK_double:
      return param->_uVal.rval;
    case MK_string:
      return (_MKStringToDouble(param->_uVal.sval));
    case MK_int:
      return ((double) param->_uVal.ival);
    case MK_envelope:
      return (double)firstEnvValue(param);
    default:
      break;
  }
  return MK_NODVAL;
}

NSString * _MKParAsString(_MKParameter *param)
/* Returns a copy of the datum as a string. If the receiver is envelope-
valued, returns a description of the envelope. */
{
  switch (param->_uType) {
    case MK_double:
      return _MKDoubleToString(param->_uVal.rval);
    case MK_int:
      return _MKIntToString(param->_uVal.ival);
    case MK_string:
      return param->_uVal.sval;//sb: was _MKMakeStr(param->_uVal.sval);
    case MK_envelope:
      return [param->_uVal.symbol description];//@" (envelope) ";//sb: was _MKMakeStr(" (envelope) "); /*** FIXME ***/
    case MK_waveTable:
      return [param->_uVal.symbol description];//@" (waveTable) ";//sb: was _MKMakeStr(" (waveTable) ");  /*** FIXME ***/
    default:
      return [param->_uVal.symbol description];// NSStringFromClass([param->_uVal.symbol class]);//sb: was _MKMakeStr([NSStringFromClass([param->_uVal.symbol class]) UTF8String]); /*** FIXME ***/
  }
  return @"";//sb: was _MKMakeStr("");
}

NSString * _MKParAsStringNoCopy(_MKParameter *param)
/* Returns the value as a string , but does
not copy that string. Application should not
delete the returned value and should not rely on its
staying around for longer than the Parameter object.
This method is provided as a speed optimzation.
*/
{
  switch (param->_uType) {
    case MK_double:
      return _MKDoubleToStringNoCopy(param->_uVal.rval);
    case MK_int:
      return _MKIntToStringNoCopy(param->_uVal.ival);
    case MK_string:
      return param->_uVal.sval;
    case MK_envelope:
      return [param->_uVal.symbol description];//@" (envelope) ";   /*** FIXME: ***/
    case MK_waveTable:
      return [param->_uVal.symbol description];//@" (waveTable) ";  /*** FIXME: ***/
    default:
      return [param->_uVal.symbol description];//(NSString *)NSStringFromClass([param->_uVal.symbol class]); /*** FIXME: ***/
  }
  return @"";
}

id _MKParAsEnv(_MKParameter *param)
/* Returns envelope if any, else nil. The envelope is not copied. */
{
  if (param->_uType == MK_envelope)
    return param->_uVal.symbol;
  return nil;
}

id _MKParAsObj(_MKParameter *param)
/* If type is MK_envelope, MK_waveTable or MK_object, returns the object.
Otherwise, returns nil. */
{
  switch (param->_uType) {
    case MK_envelope:
    case MK_waveTable:
    case MK_object:
      return param->_uVal.symbol;
    default:
      return nil;
  }
}

id _MKParAsWave(_MKParameter *param)
/* Returns waveTable if any, else nil. The waveTable is not copied. */
{
  if (param->_uType == MK_waveTable)
    return param->_uVal.symbol;
  else return nil;
}

_MKParameterUnion *_MKParRaw(_MKParameter *param)
/* Returns the raw _MKParameterUnion *. */
{
  return &param->_uVal;
}


/* The following is used for printing parameters to scorefiles and such */

static void parNameWriteValueOn(_ParName *parNameObj,NSMutableData *aStream,
                                _MKParameter *aVal,_MKScoreOutStruct *p)
{
  if (!parNameObj->printfunc || (!parNameObj->printfunc(aVal,aStream,p)))
    _MKParWriteStdValueOn(aVal,aStream,p);
}

void _MKParWriteOn(_MKParameter *param,NSMutableData *aStream,
                   _MKScoreOutStruct *p)
/* Called by Note's _MKWriteParameters() */
{
  register _ParName *self = parIds[param->parNum];
  if (_MKIsPrivatePar(self->par))
    return;
  if (BINARY(p)) {
    BOOL appPar = (self->par >= (int)(_MK_FIRSTAPPPAR));
    if (appPar)
      _MKWriteShort(aStream,MK_appPars);
    else _MKWriteShort(aStream,self->par);
    parNameWriteValueOn(self,aStream,param,p);
    if (appPar)
      _MKWriteNSString(aStream,self->s);
  }
  else {
    [aStream appendData:[[NSString stringWithFormat:@"%@:", self->s] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    parNameWriteValueOn(self,aStream,param,p);
  }
}

void _MKParWriteValueOn(_MKParameter *param,NSMutableData *aStream,
                        _MKScoreOutStruct *p)
/* Private function used by ScorefileVars to write their values */
{
  parNameWriteValueOn(parIds[param->parNum],aStream,param,p);
}

/*
 Strategy for writing objects:
 If we're not writing a scorefile, just print object definition.
 If a name isn't in there and the obj isn't named, name it.
 If a name isn't in the local table and the obj is named,
 it needs to have a decl generated.
 If a name is in there and the obj's name is not pointing to the same object,
 make a new name to point to the new obj.
 */

static NSString *genAnonName(id obj)
/* Generate default anonymous name */ /*sb: as a temporary NSString */
{
  //    return _MKMakeStrcat([NSStringFromClass([obj class]) UTF8String],"1");
  return [NSString stringWithFormat:@"%@1",NSStringFromClass([obj class])];
}

static void writeObj(id dataObj,NSMutableData *aStream,_MKToken declToken,BOOL
                     binary)
{
  if (!binary)
    [aStream appendBytes:"[" length:1];
  if (declToken == MK_object) {
    if (![dataObj respondsToSelector:@selector(writeASCIIStream:)]) {
      MKErrorCode(MK_notScorefileObjectTypeErr, NSStringFromClass([dataObj class]));
      if (binary)
        _MKWriteChar(aStream,'\0');
      else [aStream appendBytes:"]" length:1];
      return;
    }
    [aStream appendData:[[NSString stringWithFormat:@"%@ ", NSStringFromClass([dataObj class])] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    [dataObj writeASCIIStream:aStream];
  }
  else
    if (binary)
      [dataObj writeBinaryScorefileStream: aStream];
  else {
    [dataObj writeScorefileStream:aStream];
    [aStream appendBytes:"]" length:1];
  }
}

static void writeData(NSMutableData *aStream,_MKScoreOutStruct *p, id dataObj,int type)
{
    id hashObj;
    NSString *name;
    BOOL binary = BINARY(p);
    unsigned short tmp;
    _MKToken declToken;
    
    switch (type) {
        case MK_envelope:
            declToken = _MK_envelopeDecl;
            break;
        case MK_waveTable:
            declToken = _MK_waveTableDecl;
            break;
        default:
            declToken = _MK_objectDecl;
            break;
    }
    if (binary) {
        int val = (int)(uintptr_t)NSMapGet(p->_binaryIndecies, dataObj);
        
        if (val) {
            _MKWriteShort(aStream, type);
            _MKWriteShort(aStream, val);
            return;
        }
    }
    if (!p) {         /* We're not writing a scorefile so don't give it a name. */
        if (binary) {
            _MKWriteShort(aStream, type);
            _MKWriteChar(aStream, '\0');
        }
        writeObj(dataObj,aStream, declToken, binary);
        return;
    }
    name = (NSString *) MKGetObjectName(dataObj);
    if (!name) {
        name = genAnonName(dataObj);
        MKNameObject(name, dataObj);
        name = (NSString *) MKGetObjectName(dataObj);
    }
    /* If we've gotten here, it's named and we're writing a scorefile. */
    hashObj = _MKNameTableGetObjectForName(p->_nameTable, name, nil, &tmp);
    if (hashObj && (hashObj != dataObj)) {     /* Resolve name collisions. */
        name = _MKUniqueName(name, p->_nameTable, dataObj, &hashObj); /*sb: was _MKMakeStr(name) */
    }
    if (hashObj == dataObj)          /* It's already declared in file. */
        [aStream appendData: [name dataUsingEncoding: NSNEXTSTEPStringEncoding]];        /* Just write name.
                                                                                          (If we got here, we must be
                                                                                          writing an ascii file) */
    else {                           /* It's not been declared yet. */
        if (binary) {
	    _MKWriteShort(aStream, declToken);
	    _MKWriteNSString(aStream, name);
            NSMapInsert(p->_binaryIndecies, dataObj, (void*)(uintptr_t)(++(p->_highBinaryIndex)));
        }
        else {
            [aStream appendData: [[NSString stringWithFormat: @"%s %@ = ", _MKTokName(declToken), name]
                                  dataUsingEncoding: NSNEXTSTEPStringEncoding]];
        }
        writeObj(dataObj, aStream, declToken, binary);
        _MKNameTableAddName(p->_nameTable, name, nil, dataObj,
                            type | _MK_BACKHASHBIT, YES);
    }
}


static void sfWriteStrPar(register NSMutableData *aStream, NSString *strBuf)
/* Print str to aStream such that, when read in again as a scorefile,
it will look identical. */
{
  char c;
  const char *tmp;
  const register char *str = [strBuf UTF8String];
#   define WRITECHAR(_c) c = (_c); [aStream appendBytes:&c length:1]
  WRITECHAR('"');
  for (tmp = str; *str; str++)
    switch (*str) {
      case BACKSPACE:  case FORMFEED:  case NEWLINE:  case CR:  case TAB:
      case VT:  case BACKSLASH:  case QUOTE:  case '"':
        [aStream appendBytes:tmp length:str - tmp]; /* Write string up to here. */
        tmp = str + 1;                /* update tmp */
        /* Translate char. */
        WRITECHAR(BACKSLASH);
        WRITECHAR(*(char *)(strrchr((char *)_MKTranstab(),*str)-1));
        break;
      default:
        break;
    }
  [aStream appendBytes:tmp length:str - tmp];  /* Write remainder of string. */
  WRITECHAR('"');
}

void _MKParWriteStdValueOn(_MKParameter *param,NSMutableData *aStream,
                           _MKScoreOutStruct *p)
/* Private method that writes value in a standard way.
If the_ParName for this parameter has a non-NULL print function,
that function is used instead. That function may call
_MKParWriteStdValueOn, if desired. */
{
  switch (param->_uType) {
    case MK_double:
      if (BINARY(p)) {
        _MKWriteDoublePar(aStream,_MKParAsDouble(param));
      }
      else {
        [aStream appendData:[[NSString stringWithFormat:@"%.5f", _MKParAsDouble(param)]
	                              dataUsingEncoding:NSNEXTSTEPStringEncoding]];
      }
      break;
    case MK_string:
      if (BINARY(p))
        _MKWriteStringPar(aStream,_MKParAsStringNoCopy(param));
      else sfWriteStrPar(aStream,_MKParAsStringNoCopy(param));
      break;
    case MK_envelope:
    case MK_waveTable:
    case MK_object:
      if (param->_uVal.symbol)
        writeData(aStream,p,param->_uVal.symbol,param->_uType);
      else /* parameter with value of nil! Write it as 0.  This is not
        * really the right thing.  Should have a scorefile symbol
        * "nil".   FIXME
        */
        if (BINARY(p))
          _MKWriteIntPar(aStream,0);
      else [aStream appendBytes:"0" length:1];
      break;
    default:
    case MK_int:
      if (BINARY(p))
        _MKWriteIntPar(aStream,_MKParAsInt(param));
      else [aStream appendData:[[NSString stringWithFormat:@"%d", _MKParAsInt(param)] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
      break;
  }
}


void _MKArchiveParOn(_MKParameter *param,NSCoder *aTypedStream) /*sb: originally ocnverted as NSArchiver */
{
// note: the parameter name was originally a UTF8String (type "*"). If versionning can
// be used here then it would be good to catch this.

  BOOL isMKPublicPar = (param->parNum<(int)(MK_privatePars));
  /*  Version3 and earlier: (param->parNum<(int)(_MK_FIRSTAPPPAR)) */
  [aTypedStream encodeValueOfObjCType:"c" at:&isMKPublicPar];
  if (isMKPublicPar) /* Write parameter number */
    [aTypedStream encodeValueOfObjCType:"s" at:&param->parNum];
  else        /* Write parameter name */
    [aTypedStream encodeValueOfObjCType:"@" at:&(parIds[param->parNum]->s)];
  [aTypedStream encodeValueOfObjCType:"s" at:&param->_uType];
  switch (param->_uType) {
    case MK_double:
      [aTypedStream encodeValueOfObjCType:"d" at:&param->_uVal.rval];
      break;
    case MK_string:
      [aTypedStream encodeValueOfObjCType:"@" at:&param->_uVal.sval];//sb: type was "%"
      break;
    case MK_envelope:
    case MK_waveTable:
    case MK_object:
      [aTypedStream encodeValueOfObjCType:"@" at:&param->_uVal.symbol];
      break;
    default:
    case MK_int:
      [aTypedStream encodeValueOfObjCType:"i" at:&param->_uVal.ival];
      break;
  }
}

void _MKUnarchiveParOn(_MKParameter *param,NSCoder *aTypedStream) /*sb: NSCoder originally converted as NSArchiver */
{
  BOOL isMKPublicPar;
  NSString *strVar;
  [aTypedStream decodeValueOfObjCType:"c" at:&isMKPublicPar size:sizeof(isMKPublicPar)];
  /* See fix for bug in MKNote.m's read: method */
  if (isMKPublicPar) /* Write parameter number */
    [aTypedStream decodeValueOfObjCType:"s" at:&param->parNum size:sizeof(param->parNum)];
  else {       /* Write parameter name */
    id aParNameObj;
    [aTypedStream decodeValueOfObjCType:"@" at:&strVar size:sizeof(strVar)];
    param->parNum = _MKGetPar(strVar,&aParNameObj);
    [strVar release];
    strVar = nil;
  }
  [aTypedStream decodeValueOfObjCType:"s" at:&param->_uType size:sizeof(param->_uType)];
  switch (param->_uType) {
    case MK_double:
      [aTypedStream decodeValueOfObjCType:"d" at:&param->_uVal.rval size:sizeof(param->_uVal.rval)];
      break;
    case MK_string:
      [aTypedStream decodeValueOfObjCType:"@" at:&param->_uVal.sval size:sizeof(param->_uVal.sval)];//sb: type was "%"
      break;
    case MK_envelope:
    case MK_waveTable:
    case MK_object:
      [aTypedStream decodeValueOfObjCType:"@" at:&param->_uVal.symbol size:sizeof(param->_uVal.symbol)];
      break;
    default:
    case MK_int:
      [aTypedStream decodeValueOfObjCType:"i" at:&param->_uVal.ival size:sizeof(param->_uVal.ival)];
      break;
  }
}

@end

