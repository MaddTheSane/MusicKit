//////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorFlanger.m
//  SndKit
//
//  Created by SKoT McDonald on Mon Dec 17 2001.
//
//  Based on the C++ Vellocet VFlanger Cubase VST plugin by
//  Vellocet / SKoT McDonald <skot@vellocet.com>
//  http://www.vellocet.com
//
//////////////////////////////////////////////////////////////////////////////

#include <math.h>
#import "SndAudioProcessorFlanger.h"

#import "SndAudioBuffer.h"
#import "SndAudioProcessor.h"

@implementation SndAudioProcessorFlanger

//////////////////////////////////////////////////////////////////////////////
// init
//////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];

  [self setToDefault];

  m_liBuffSize   = 2048;

  m_pfBuff[0]  = (float*) malloc(sizeof(float) * m_liBuffSize);
  m_pfBuff[1]  = (float*) malloc(sizeof(float) * m_liBuffSize);
  memset(m_pfBuff[0],0,sizeof(float) * m_liBuffSize);
  memset(m_pfBuff[1],0,sizeof(float) * m_liBuffSize);

  m_fOsc[0]    = fMin;
  m_fOsc[1]    = fMin;
  m_oscSign[0] = 1.0;
  m_oscSign[1] = 1.0;
  
  m_liPtr = 0;
  
  return self;
}

//////////////////////////////////////////////////////////////////////////////
// dealloc
//////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (m_pfBuff[0])
    free(m_pfBuff[0]);
  if (m_pfBuff[1])
    free(m_pfBuff[1]);
  
  [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////
// setParameter
//////////////////////////////////////////////////////////////////////////////

- (void) setParameter: (long) index toValue: (float) value
{
  if (value < 0.0f)
    value = 0.0f;
  else if (value > 1.0f)
    value = 1.0f;

  switch (index)
  {
    case flanger_kRate:     fRate = value;       break;
    case flanger_kMin:      fMin = (value <= fMax ? value : fMax);       break;
    case flanger_kMax:      fMax = value;  if (fMin > fMax) fMin = fMax; break;
    case flanger_kSwap:     fSwapStereo = value; break;
    case flanger_kPhase:    fPhaseDiff  = value; break;
    case flanger_kFeedback: fFeedback   = value; break;
  }
}

//////////////////////////////////////////////////////////////////////////////
// getParameter
//////////////////////////////////////////////////////////////////////////////

- (float) getParameter: (long) index
{
  float r = 0.0f;
  switch (index)
  {
    case flanger_kRate:     r = fRate;       break;
    case flanger_kMin:      r = fMin;        break;
    case flanger_kMax:      r = fMax;        break;
    case flanger_kSwap:     r = fSwapStereo; break;
    case flanger_kPhase:    r = fPhaseDiff;  break;
    case flanger_kFeedback: r = fFeedback;   break;
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// getParameterName
//////////////////////////////////////////////////////////////////////////////

- (NSString*) getParameterName: (long) index
{
  NSString *r = nil;
	switch (index)
  {
    case flanger_kRate:     r = @"Rate";      break;
    case flanger_kMin:      r = @"Min";       break;
    case flanger_kMax:      r = @"Max";       break;
    case flanger_kSwap:     r = @"Swap chan"; break;
    case flanger_kPhase:    r = @"L/R Phase"; break;
    case flanger_kFeedback: r = @"Feedback";  break;
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// getParameterDisplay
//////////////////////////////////////////////////////////////////////////////

- (NSString*) getParameterDisplay: (long) index
{
  NSString *r;
	switch (index)
  {
    case flanger_kRate:     r = [NSString stringWithFormat: @"%f", (44100*fRate)/11025]; break;
    case flanger_kMin:      r = [NSString stringWithFormat: @"%f", 44100/(fMin *256+1)]; break;
    case flanger_kMax:      r = [NSString stringWithFormat: @"%f", 44100/(fMax *256+1)]; break;
    case flanger_kSwap:     if (fSwapStereo > 0.5f) r = @"R L"; else r = @"L R";         break;
    case flanger_kPhase:    r = [NSString stringWithFormat: @"%f", 180.0f*fPhaseDiff];   break;
    case flanger_kFeedback: r = [NSString stringWithFormat: @"%f", 100.0f*fFeedback];    break;
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// getParameterLabel
//////////////////////////////////////////////////////////////////////////////

- (NSString*) getParameterLabel:(long) index
{
  NSString *r = nil;
	switch (index)
  {
    case flanger_kRate:     r = @"Hz";      break;
    case flanger_kMin:      r = @"Hz";      break;
    case flanger_kMax:      r = @"Hz";      break;
    case flanger_kSwap:     r = @"L R";     break;
    case flanger_kPhase:    r = @"degrees"; break;
    case flanger_kFeedback: r = @" ";       break;
  }
  return r;
}

//////////////////////////////////////////////////////////////////////////////
// processReplacing
//////////////////////////////////////////////////////////////////////////////

- (void) processReplacing_core_inL: (float*) inL inR: (float*) inR
                              outL: (float*) outL outR: (float*) outR
                       sampleCount: (long) sampleCount step: (int) step
{
  float interp, pos, flange[2], in[2];
  long  p1, p2;
	float c, d, range, s, fbk;	       
  long  p, i, j;
  float quarterBuffSize = m_liBuffSize / 4.0f;


  p     = m_liPtr;
  range = fMax - fMin;
  s     = (float)((range  * fRate) / 5512.5f);
  fbk   = 1.0f / (1.0f + fFeedback);

  for (j = 0; j < sampleCount; j += step)
	{
    m_fOsc[0] = m_fOsc[0] + (m_oscSign[0] * s); 
    m_fOsc[1]  = m_fOsc[0] + (fPhaseDiff * range * m_oscSign[0]);
  
    in[0] = inL[j];
    in[1] = inR[j];

    for (i=0; i < 2; i++)
    {
      if (m_fOsc[i] >= fMax)
      {
        m_fOsc[i]    = 2.0f * fMax - m_fOsc[i];
        m_oscSign[i] = -1;
      }
      else if (m_fOsc[i] <= fMin)
      {
        m_fOsc[i]    = 2.0f * fMin - m_fOsc[i];
        m_oscSign[i] = 1;
      }

      pos    = p - m_fOsc[i] * quarterBuffSize;
      p1     = (long) pos;
      interp = pos - p1; // (float) fmod(pos,1.0f);
      p2     = p1+1; 

      while (p1 < 0)
        p1 += m_liBuffSize;
      while (p1 >= m_liBuffSize)
        p1 -= m_liBuffSize; 

      while (p2 < 0)
        p2 += m_liBuffSize;
      while (p2 >= m_liBuffSize)
        p2 -= m_liBuffSize;

      flange[i] = (1.0f - interp) * m_pfBuff[i][p1] + interp * m_pfBuff[i][p2];


   		m_pfBuff[i][p] = (in[i] + fFeedback * flange[i]) * fbk;		// try to do load operations first...

////////////
    }

    if (fSwapStereo > 0.5)
    {
  		c = (m_pfBuff[1][p] + flange[0]);// * 0.5f;		// accumulate to output buss
	  	d = (m_pfBuff[0][p] + flange[1]);// * 0.5f;
    }
    else
    {
  		c = (m_pfBuff[0][p] + flange[0]);// * 0.5f;		// accumulate to output buss
	  	d = (m_pfBuff[1][p] + flange[1]);// * 0.5f;
    }
		outL[j] = c;
		outR[j] = d;

    p++;
    if (p >= m_liBuffSize)
      p = 0;
	}
  m_liPtr = p;
}

//////////////////////////////////////////////////////////////////////////////
//  processReplacingInputBuffer:outputBuffer:
//////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB
{
	float *inData      = [inB data];
  float *outData     = [outB data];
  long  sampleFrames = [inB lengthInSamples]; 
  int   step = 2;

  [self processReplacing_core_inL: inData inR: inData+1
                             outL: outData outR: outData+1
                      sampleCount: sampleFrames*step step: step];

  return TRUE;
}

//////////////////////////////////////////////////////////////////////////////
// setActive:
//////////////////////////////////////////////////////////////////////////////

- setActive: (BOOL) b
{
  memset(m_pfBuff[0], 0, sizeof(float) * m_liBuffSize);
  memset(m_pfBuff[1], 0, sizeof(float) * m_liBuffSize);
  return [super setActive: b];
}

//////////////////////////////////////////////////////////////////////////////
//  setToDefault
//////////////////////////////////////////////////////////////////////////////

- (void) setToDefault
{
	fRate       = 0.04f;			
	fMin        = 0.03f;			
	fMax        = 0.22f;			
  fSwapStereo = 0.0f;
  fPhaseDiff  = 0.2f;
  fFeedback   = 0.6f;
}

//////////////////////////////////////////////////////////////////////////////
// micro accessors and mutators
//////////////////////////////////////////////////////////////////////////////

- (void)  setRate:     (float) f { [self setParameter: flanger_kRate     toValue: f]; };
- (void)  setMin:      (float) f { [self setParameter: flanger_kMin      toValue: f]; };
- (void)  setMax:      (float) f { [self setParameter: flanger_kMax      toValue: f]; };
- (void)  setSwap:     (float) f { [self setParameter: flanger_kSwap     toValue: f]; };
- (void)  setPhase:    (float) f { [self setParameter: flanger_kPhase    toValue: f]; };
- (void)  setFeedback: (float) f { [self setParameter: flanger_kFeedback toValue: f]; };

- (float) getRate      { return [self getParameter: flanger_kRate];     };
- (float) getMin       { return [self getParameter: flanger_kMin];      };
- (float) getMax       { return [self getParameter: flanger_kMax];      };
- (float) getSwap      { return [self getParameter: flanger_kSwap];     };
- (float) getPhase     { return [self getParameter: flanger_kPhase];    };
- (float) getFeedback  { return [self getParameter: flanger_kFeedback]; };

//////////////////////////////////////////////////////////////////////////////

@end

