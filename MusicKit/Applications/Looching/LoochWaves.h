/* wavetable data for LoochWaves */

double 	freqs[3][7][7] = {
	{
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 10.0, 11.0},
		{1.0, 2.0, 4.0, 5.0, 7.0, 8.0, 9.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 4.0, 5.0, 7.0, 8.0, 10.0},
		{1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 12.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0}
	},
	{
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0},
		{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0}
	},
	{
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0},
		{1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0}
	}
};
 
 
double 	amps[3][7][7] =  {
	{
		{1.0, 0.5, 0.25, 0.12, 0.06, 0.03, .015},
		{1.0, 1.0, 1.0, 0.2, 0.1, 0.001},
		{1.0, 0.5, 0.3, 0.02, 0.01, 0.01, 0.05},
		{1.0, 1.0, 0.1, 0.05, 0.001, 0.0, 0.0},
		{1.0, 0.5, 0.2, 0.3, 0.1, 0.1, 0.05},
		{1.0, 0.2, 0.1, 0.4, 0.05, 0.05, 0.01},
		{1.0, 0.4, 0.1, 0.001, 0.01, 0.001, 0.0}
	},
	{
		{1.0, 0.5, 0.25, 0.12, 0.06, 0.03, .015},
		{1.0, 1.0, 1.0, 0.2, 0.1, 0.01},
		{1.0, 0.5, 0.3, 0.02, 0.1, 0.01, 0.05},
		{1.0, 1.0, 0.1, 0.5, 0.01, 0.1, 0.02},
		{1.0, 0.5, 0.2, 0.3, 0.1, 0.1, 0.05},
		{1.0, 0.2, 0.1, 0.4, 0.05, 0.05, 0.01},
		{1.0, 0.4, 0.1, 0.001, 0.01, 0.001, 0.0}
	},
	{
		{1.0, 0.5, 0.25, 0.012, 0.06, 0.003, .0015},
		{1.0, 1.0, 0.5, 0.2, 0.01, 0.001},
		{1.0, 0.5, 0.3, 0.002, 0.01, 0.001, 0.005},
		{1.0, 1.0, 0.1, 0.05, 0.001, 0.0, 0.0},
		{1.0, 0.5, 0.2, 0.03, 0.01, 0.01, 0.005},
		{1.0, 0.2, 0.1, 0.4, 0.05, 0.05, 0.01},
		{1.0, 0.4, 0.1, 0.001, 0.01, 0.001, 0.0}
	}
};

/* pitch sets */
double pitches[5][14] = {
	/* the Original */
	{50.0, 66.667, 75.0, 100.0, 114.0, 133.333, 150.0, 177.777, 200.0,
	 228.0, 266.666, 300.0, 355.555, 400.0},
	/* morning stuff */
	{116.5, 174.6, 261.6, 349.2, 392.0, 440.0, 466.2, 523.2, 659.3,
	 698.5, 784.0, 0.0, 0.0, 0.0},
	/* the Big Drone */
	{70.0, 70.0, 70.0, 70.0, 70.0, 70.0, 70.0, 140.0, 140.0, 105.0,
	 105.0, 105.0, 140.0, 210.0},
	/* arnie */
	{261.6, 247.0, 196.0, 207.6, 311.12, 277.2, 0.0, 0.0, 0.0, 0.0, 0.0,
	 0.0, 0.0, 0.0},
	/* bach */
	{98.0, 247.0, 293.7, 392.0, 110.0, 261.6, 123.5, 349.2, 164.8, 329.6,
	 130.8, 440.0, 174.6, 220.0}
};
	 
int toneindex[5] = {14, 11, 14, 6, 14};


