
/* Generated by Interface Builder */

#import "Wave.h"
#import "FFTControl.h"
#import <stdio.h>
#import <appkit/Application.h>
#import <appkit/Button.h>
#import <appkit/Pasteboard.h>
#import <ctype.h>
#define LOGBOTTOM 6.9077552

extern void rfft(float x[], int N, int forward );

@implementation FFTControl
  
- setModView:anObject
{
    modView = anObject;
    [modView setDisplayMode:DISCRETE];
    return self;
}

- setPhiView:anObject
{
    phiView = anObject;
    return self;
}

- setWaveView:anObject
{
    int i;
    
    waveView = anObject;
    dataLength = [(FuncView *)waveView tableLength];
//    fprintf(stderr,"dataLength %d\n",dataLength);
    FFTData = (float*) calloc(dataLength,sizeof(float));
    for(i=0;i<4;i++)
      storeTable[i] = (float*) calloc(dataLength,sizeof(float));
    for(i=0;i<2;i++)
      swap[i] = (float*) calloc(dataLength,sizeof(float));
    PHIData =  (float*) calloc(dataLength/2,sizeof(float));
    MODData = (float*) calloc(dataLength/2,sizeof(float));
    currentBuffer = 0;
    return self;
}

- setConvView:anObject
{
    convView = anObject;
    return self;
}

- setMod:(float*)data
{
    int i;
    float *indData, *indFFT, *indMod, *indPhi,maxValue,minValue,Value;
    
    [self storeCurrent:self];
    indFFT = FFTData;
    indData = data;
    indMod = MODData;
    indPhi = PHIData;
    
    if(logDisplay)
      for(i=0;i<dataLength/2;i++)
	{
	    float value;
	    
	    value = *indData;
	    *(indMod++) = *(indData++);
	    value = exp(((value) - 1)* LOGBOTTOM );
	    if (value - .00101 <= 0) value = 0;
	    *(indFFT++) =  value * cos((*indPhi -.5)*2*M_PI);
	    *(indFFT++) = value * sin((*indPhi -.5)*2*M_PI); /* OK under 3.0 */
	    indPhi++;
	}
    else
      for(i=0;i<dataLength/2;i++)
	{
	    float value;
	    
	    value = *indData;
	    *(indMod++) = *(indData++);
	    *(indFFT++) = value * cos((*indPhi -.5)*2*M_PI);
	    *(indFFT++) = value * sin((*indPhi -.5)*2*M_PI);   /* OK under 3.0 */
	    indPhi++;
	}
    
    
    FFTData[0] = MODData[0] * cos(phizero);
    FFTData[1] = MODData[0] * sin(phizero);
    
    rfft(FFTData,dataLength/2,FALSE);
    
    indFFT = FFTData;   
    for(i=0,maxValue= -10000.,minValue = 10000. ;i<dataLength;i++)
      {
	  Value = *(indFFT++);
	  maxValue = MAX(Value,maxValue);
	  minValue = MIN(Value,minValue);
      }
    
    if((minValue<0 || maxValue>1) && minValue - maxValue < 0)
      {
	  maxValue -= minValue;
	  for(i=0,indFFT = FFTData;i<dataLength;i++,indFFT++)
	    *(indFFT) = (*(indFFT) - minValue) / maxValue;
      }
    
    [waveView setFuncTable:FFTData length:dataLength offset:0];
    [waveView draw:self];
    [waveView setSound:self];
    
    return self;
}

- setPhi:(float*)data
{
    int i;
    float *indData, *indFFT, *indMod, *indPhi,maxValue,minValue,Value;
    
    [self storeCurrent:self];
    indFFT = FFTData;
    indData = data;
    indMod = MODData;
    indPhi = PHIData;
    
    if(logDisplay)
      for(i=0;i<dataLength/2;i++)
	{
	    float value;
	    
	    *(indPhi++) = *(indData);
	    value =  exp((*(indMod++) - 1) * LOGBOTTOM)  ;
	    if (value - .00101 <= 0) value = 0;
	    *(indFFT++) =  value * cos((*indData - .5)*2*M_PI);
	    *(indFFT++) =  value * sin((*indData - .5)*2*M_PI);
	    indData++;
	}
    else
      for(i=0;i<dataLength/2;i++)
	{
	    float value;
	    
	    *(indPhi++) = *(indData);
	    value =  *(indMod++);
	    *(indFFT++) =  value * cos((*indData - .5)*2*M_PI);
	    *(indFFT++) =  value * sin((*indData - .5)*2*M_PI);
	    indData++;
	}
    
    FFTData[0] = MODData[0] * cos(phizero);
    FFTData[1] = MODData[0] * sin(phizero);
    
    rfft(FFTData,dataLength/2,FALSE);
    
    indFFT = FFTData;   
    for(i=0,maxValue= -10000.,minValue = 10000. ;i<dataLength;i++)
      {
	  Value = *(indFFT++);
	  maxValue = MAX(Value,maxValue);
	  minValue = MIN(Value,minValue);
      }
    
    if((minValue<0 || maxValue>1) && minValue - maxValue < 0)
      {
	  maxValue -= minValue;
	  for(i=0,indFFT = FFTData;i<dataLength;i++,indFFT++)
	    *(indFFT) = (*(indFFT) - minValue) / ((maxValue -1 < 0) ? 1 : maxValue);
      }
    
    [waveView setFuncTable:FFTData length:dataLength offset:0];
    [waveView draw:self];
    [waveView setSound:self];
    
    return self;
}

- receiveData:(float*)data length:(int)aLength
{
    int i;
    float *indData, *indFFT, *indMod, *indPhi,maxValue,Value;
    
    indFFT = FFTData;
    indData = data;
    indMod = MODData;
    indPhi = PHIData;
    
    for(i=0;i<dataLength;i++)
      *(indFFT++) = *(indData++);
    
    rfft(FFTData,dataLength/2,TRUE);
    
    indFFT = FFTData;
    
    phizero = atan2(*(indFFT+1),*(indFFT)) ;
    
    for(i=0,maxValue=0;i<dataLength/2;i++,indFFT+=2)
      {
	  Value = *(indMod++) = hypot(*(indFFT),*(indFFT+1));
	  if(i) maxValue = MAX(Value,maxValue);
      }
    
    //    for(i=0;i<20;i++)
    //       fprintf(stderr,"Phase[%d] = %f\n",i*dataLength/20,FFTData[i*dataLength/20]);
    
    indFFT = FFTData;       
    for(i=0,indMod = MODData;i<dataLength/2;i++,indFFT+=2)
      {
	  
	  if(maxValue != 0) *(indMod) /= maxValue;
	  if(*(indMod) - 1e-4 > 0)
	    *(indPhi++) =  .5 + atan2(*(indFFT+1),*(indFFT)) / 2 / M_PI;
	  else *(indPhi++) = *(indPhi - 1);
	  if(logDisplay == YES) *(indMod) = log(MAX(*(indMod),.001))/LOGBOTTOM + 1;
	  indMod ++;
      }
    
    [modView setFuncTable:MODData length:(dataLength/2) offset:0];
    [phiView setFuncTable:PHIData length:(dataLength/2) offset:0];
    [modView draw:self];
    [phiView draw:self];
    
    return self;
}

- convolve:sender
{
    int i;
    float *indData,*indMod,maxvalue;
    
    indData = [convView table];
    indMod = MODData;
    
    for(i=0,maxvalue = 0;i<dataLength/2;i++)
      {
	  float value = *(indData++);
	  maxvalue = MAX(maxvalue,value);
      }
    
    
    indData = [convView table];
    if(logDisplay)
      for(i=0;i<dataLength/2;i++,indMod++)
	{
	    float value1 = *(indData++);
	    float value2 = *(indMod);
	    
	    *(indMod) = MAX(0, value2 + value1 - maxvalue);
	}
    else
      for(i=0;i<dataLength/2;i++)
	{
	    *(indMod++) *= *(indData++);
	}
    
    [modView setFuncTable:MODData length:(dataLength/2) offset:0];
    [modView draw:self];
    [self setMod:MODData];
    return self;
}

- setLogDisplay:sender
{
    logDisplay = [sender intValue];
    [self receiveData:[waveView table] length:[(FuncView *)waveView tableLength]];
    return self;
}

- multiply:sender
{
    int i;
    float *indMult,*indWave,*indWavesup;
    
    [self storeCurrent:self];
    indMult = [convView table] + dataLength/2 -1;
    indWave = [waveView table];
    indWavesup = indWave + dataLength -1 ;
    
    for(i=0;i<dataLength/2;i++)
      {
	  *(indWave) = (*(indWave++) - .5) * *(indMult) + .5;
	  *(indWavesup) = (*(indWavesup--) -.5) * *(indMult--) + .5;
      }
    
    [waveView draw:self];
    [waveView setSound:sender];
    [self receiveData:[waveView table] length:dataLength];
    return self;
}

- normalize:sender
{
    int i;
    float *indWave,maxAmp,minAmp,x,scl;
    
    [self storeCurrent:self];
    indWave = [waveView table];
    maxAmp = -1; 
    minAmp = 1;
    for(i=0;i<dataLength;i++)
      {
	  x = *(indWave++);
	  if (x > maxAmp)
	    maxAmp = x;
	  else if (x < minAmp)
	    minAmp = x;
      }
    indWave = [waveView table];
    if (maxAmp == minAmp) /* Give up */
      return self; 
    scl = 1.0/(maxAmp - minAmp);
    for(i=0;i<dataLength;i++) {
	x = *indWave;
	x = (x-minAmp) * scl;
	*indWave++ = x;
      }
    [waveView draw:self];
    [waveView setSound:sender];
    [self receiveData:[waveView table] length:dataLength];
    return self;
}


- saveTable:sender
{
    int i;
    float *storeInd,*indData;
    
    storeInd = storeTable[[[sender selectedCell] tag]];
    indData = [waveView table];
    for(i=0;i<dataLength;i++)
      *(storeInd++) =  *(indData++);
    return self;
}


- restoreTable:sender
{
    float *storeInd;
    
    [self storeCurrent:self];
    storeInd = storeTable[[[sender selectedCell] tag]];
    [waveView setFuncTable:storeInd length:dataLength offset:0];
    [waveView draw:self];
    [waveView setSound:sender];
    [self receiveData:storeInd length:dataLength];
    
    return self;
}

-storeCurrent:sender
{
    float *indData, *indSwap;
    int i;
    
    indData = [waveView table];
    indSwap = swap[currentBuffer];
    for(i=0;i<dataLength;i++)
      *(indSwap++) = *(indData++);
    
    return self;
}

-previous:sender
{
    
    currentBuffer = 1 - currentBuffer;
    [self storeCurrent:self];
    [waveView setFuncTable:swap[1-currentBuffer] length:dataLength offset:0];
    [waveView draw:self];
    [waveView setSound:sender];
    [self receiveData:swap[1-currentBuffer] length:dataLength];
    return self;
}	

- passDraw:(float)curs :(int) tag
{
    
    switch(tag)
      {
	case 0 : [modView drawSelfAux:curs]; break ;
	  
	case 1 : [phiView drawSelfAux:curs] ; break ;
      }
    return self;
}

- zoomIn:sender
{
    [modView zoomIn:self];
    [phiView zoomIn:self];
    return self;
}

- zoomOut:sender
{
    [modView zoomOut:self];
    [phiView zoomOut:self];
    return self;
}

- appWillTerminate:sender
{
    [waveView stopSound];
    return self;
}

- onOff:sender
{
    if ([sender intValue]) {
	if (![waveView startSound])
	  [(Button *)sender setState:0];
    }
    else [waveView stopSound];
    return self;
}

//===================================================================
// Pasteboard interface methods
//===================================================================
  
//-------------------------------------------------------------------
// copy: -- Copy the current wavetable to the pasteboard
  
static char outputFilePath[MAXPATHLEN+1] = "";
static char outputFileDir[MAXPATHLEN+1] = "~";
static char outputFileName[MAXPATHLEN+1] = "WaveEdit.score";

-(char *) _PartialsString {
    int point;					// current point
    int len = dataLength/2;
    float phaseVal;
    char *s;		// output string
    int max;		// max number of chars in the output string
    char tmp[128];	// temporary buffer for conversions
    int weHaveOne = 0;
    if (!FFTData || !dataLength)
        return NULL;
    max=1024;
    s=malloc(max*sizeof(char));		/* allocate array for output string */
    strcpy(s,"[");
    /* Omit DC component. */
    for (point=1; point<len; point++) {
	//	phaseVal = .75-PHIData[point];
	if (MODData[point] >= 0.001) {
	    weHaveOne = 1;
	    phaseVal = PHIData[point];
	    /* 0:1 to degrees */
	    if (phaseVal < 0)
	      phaseVal += 1;
	    phaseVal *= 360;
	    sprintf(tmp,"{%d,%5.3f,%5.3f}",point,MODData[point],phaseVal);
	    strcat(s,tmp);
	    if (strlen(s)>max-128) {
		max+=1024;
		s=realloc(s,max*sizeof(char));
	    }
	}
    }
    if (!weHaveOne) /* Give it one dummy partial in this case. */
      strcat(s,"{1,0}]");
    else strcat(s,"]");
    return s;
}

static id savePanel = nil;

-_saveIt:(BOOL)useDefault
{
    BOOL flag;
    FILE *fp;
    char *s;
    char *name = "WaveEdit";
    if (!savePanel) {
	savePanel = [SavePanel new];
	[savePanel setTitle:"WaveEdit Save"];
	accessoryView = [[TextField alloc] init];
	[accessoryView sizeTo:256:21];
	[accessoryView setStringValueNoCopy:"myWaveTable"];
	[savePanel setAccessoryView:accessoryView];
    }
    if (!useDefault || !strlen(outputFilePath)) {
	[savePanel setRequiredFileType:"score"];
	[NXApp setAutoupdate:NO];
	flag = [savePanel runModalForDirectory:outputFileDir file:outputFileName]; 
	if (!flag)
	  return self;
	strcpy(outputFilePath,[savePanel filename]);
    }
    s = [self _PartialsString];
    if (!s)
      return nil;
    fp = fopen(outputFilePath,"w");
    if (!fp) {
	NXRunAlertPanel("WaveEdit","Can't open file %s.","OK",NULL,NULL,
			outputFilePath);
	outputFilePath[0] = '\0';
	free(s);
    }
    name = (char *)[accessoryView stringValue];
    if (!strlen(name))
      name = "WaveEdit";
    fprintf(fp,"/* Wavetable created by WaveEdit */\nwaveTable %s = %s;\n",name,
	    s);
    fclose(fp);
    free(s);
    [NXApp setAutoupdate:YES];
    return self;
}

- saveAs:sender
{
    return [self _saveIt:NO];
}

- save:sender
{
    return [self _saveIt:YES];
}


- copy:sender
{
    const char *types[1];
    int num=0;
    char *s;		// output string
    id pb = [Pasteboard new];
    s = [self _PartialsString];
    if (!s)
      return nil;
    types[num++] = NXAsciiPboardType;
    [pb declareTypes: types num: num owner: [self class]];
    [pb writeType: NXAsciiPboardType data:s length:strlen(s)];
    free(s);
    return self;
}

static BOOL IncludesType(const NXAtom *types, NXAtom type)
{
    if (types) while (*types) if (*types++ == type) return YES;
    return NO;
}

static char *eatWhiteSpace(char *p,char *pEnd)
{
#define FORMFEED '\f'
#define CR '\r'
#define TAB '\t'
#define NEWLINE '\n'
    char c;
    while (p < pEnd) {
	c = *p;
	switch (c) {
	  case ' ':
	  case CR:
	  case TAB:
	  case NEWLINE:
	  case FORMFEED:
	    p++;
	    break;
	  default:
	    return p;
	}
    }
    return p;
}

static id abortPaste(char *data,int length)
{
    NXRunAlertPanel("WaveDraw",
		    "Pasteboard doesn't contain a valid Music Kit scorefile waveTable representation: %s","OK",NULL,NULL,data);
    [[Pasteboard new] deallocatePasteboardData:data length:length];
    return nil;
}

static char *getNum(char *p,char *pEnd,float *rtn)
{
    if (!sscanf(p,"%f",rtn)) return p;
    while (p < pEnd && isdigit(*p)) p++;
    if (*p == '.') { 
	p++;                        
	while (p < pEnd && isdigit(*p)) p++;
    }
    if (*p == 'e' || *p == 'E') {   /* Eat exponent */
	p++;
	if (p < pEnd && (isdigit(*p) || *p =='+' || *p == '-')) {
	    p++;
	    while (p < pEnd && isdigit(*p++));
	}
    }
    return p;
}

- paste:sender
{
#define abortCheck() if (p==pEnd) return abortPaste(data,length)
    char   *data,*p,*pEnd;
    int     length,l;
    const NXAtom *types;
    id pboard = [Pasteboard new];
    int i;
    float x;
    float *myMODData = (float*) calloc(dataLength/2,sizeof(float));
    float *myPHIData = (float*) calloc(dataLength/2,sizeof(float));
    /* Copy it to a local place in case there's a parse error */
    types = [pboard types];
    if (!IncludesType(types, NXAsciiPboardType)) {
	NXBeep();
	return nil;
    }
    [pboard readType:NXAsciiPboardType data:&data length:&length];
    l = dataLength/2;
    if (!length)
      NXBeep();
    p = data;
    pEnd = data + length;
    p = eatWhiteSpace(p,pEnd);
    abortCheck();
    if (*p == '[') 
      p++;
    p = eatWhiteSpace(p,pEnd); abortCheck();
    while (p<pEnd) {
	if (*p == ']') 
	  break;
	else if (*p++ != '{')
	  return abortPaste(data,length);
	p = eatWhiteSpace(p,pEnd); abortCheck();
	p = getNum(p,pEnd,&x); abortCheck();
	i = x; 
	p = eatWhiteSpace(p,pEnd); abortCheck();
	if (*p++ != ',') 
	  return abortPaste(data,length);
	p = eatWhiteSpace(p,pEnd); abortCheck();
	p = getNum(p,pEnd,&x); abortCheck();
	if (i < l) { /* Not too high? */
	    myMODData[i] = x;
	}
	p = eatWhiteSpace(p,pEnd); abortCheck();
	if (*p == '}') {
	    if (i < l) myPHIData[i] = 0;
	    p++;
	} else {
	    if (*p++ != ',') 
	      return abortPaste(data,length);
	    p = eatWhiteSpace(p,pEnd); abortCheck();
	    p = getNum(p,pEnd,&x); abortCheck();
	    if (i < l) {
		/* Degrees to 0:1 */
		while (x < 0)
		  x += 360;
		x /= 360;
		myPHIData[i] = x;
	    }
	    if (*p++ != '}') 
	      return abortPaste(data,length);
	}
	p = eatWhiteSpace(p,pEnd);
    }
    [pboard deallocatePasteboardData:data length:length];
    [modView setFuncTable:myMODData length:l offset:0];
    [phiView setFuncTable:myPHIData length:l offset:0];
    [modView draw:self];
    [phiView draw:self];
    [self setMod:myMODData];
    [self setPhi:myPHIData];
    free(myMODData);
    free(myPHIData);
    return self;
}


@end
