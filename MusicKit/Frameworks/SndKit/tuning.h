// Reverb model tuning values
//
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#ifndef _tuning_
#define _tuning_

#define scalewet 3.0f
#define scaledry 2.0f

static const float muted		= 0;
static const float fixedgain		= 0.015f;
static const float scaledamp		= 0.4f;
static const float scaleroom		= 0.28f;
static const float offsetroom		= 0.7f;
static const float initialroom		= 0.5f;
static const float initialdamp		= 0.5f;
static const float initialwet		= (1/scalewet);
static const float initialdry		= (1/scaledry);
static const float initialwidth	= 1;
static const float initialmode		= 0;
static const float freezemode		= 0.5f;

#define STEREO_SPREAD 23

// These values assume 44.1KHz sample rate
// they will probably be OK for 48KHz sample rate
// but would need scaling for 96KHz (or other) sample rates.
// The values were obtained by listening tests.
static const int combtuning[NUMCHANNELS][NUMCOMBS] = {{1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617},
					       {1116+STEREO_SPREAD, 1188+STEREO_SPREAD, 1277+STEREO_SPREAD, 
						1356+STEREO_SPREAD, 1422+STEREO_SPREAD, 1491+STEREO_SPREAD, 
						1557+STEREO_SPREAD, 1617+STEREO_SPREAD}};
static const int allpasstuning[NUMCHANNELS][NUMALLPASSES] = {{556, 441, 341, 225},
						      {556+STEREO_SPREAD, 441+STEREO_SPREAD, 
						       341+STEREO_SPREAD, 225+STEREO_SPREAD}};

#endif //_tuning_

//ends

