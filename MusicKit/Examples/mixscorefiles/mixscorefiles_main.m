/*
  $Id$

  Original Author: David A. Jaffe.

  Description:
    This example program mixes any number of scorefiles. It parses and
    evaluates each input file and merges its output with that of the other
    input file. This is done by reading a number of files into a single
    MKScore object.

    The program allows the option of specifying a particular portion of each
    file to be used as well as a time offset. It also allows for single
    global tempo.

    See README for a description of this program.
*/

#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>

static const char *const helpString =
"Usage: mixscorefiles -o <outFile> -i <inFile1> -i <inFile2> ...\n"
"Each input file specification can be immediately followed by timing variables:\n\n"
"	-f realNumber  first timeTag included in the mix\n"
"	-l realNumber  last timeTag included in the mix\n"
"	-s realNumber  timeTag shift\n";

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int i;
    NSString *inputFileName = nil;
    NSString *outputFileName = nil;
    double firstTimeTag = 0;
    double lastTimeTag = MK_ENDOFTIME;
    double timeShift = 0;
    MKScore *aScore = [[MKScore alloc] init];

    // either getopt or better

    if (argc==1) {
        fprintf(stderr,helpString);
        exit(1);
    }
    for (i=1; i<argc; i++) {
        if (!strcmp(argv[i],"-i"))  /* Input file */
            if (++i == argc)
                fprintf(stderr,"Missing input file name.\n");
            else {
                if (inputFileName) /* Do previous file. */
                    [aScore readScorefile:inputFileName
                     firstTimeTag:firstTimeTag
                     lastTimeTag:lastTimeTag timeShift:timeShift];
                firstTimeTag = 0;  /* Reset variables for next file */
                lastTimeTag = MK_ENDOFTIME;
                timeShift = 0;
                inputFileName = [NSString stringWithCString: argv[i]];
            }
        else if (!strcmp(argv[i],"-o")) /* Output file */
            if (++i == argc)
                fprintf(stderr,"Missing output file name.\n");
            else {
                outputFileName = [NSString stringWithCString: argv[i]];
            }
        else if (!strcmp(argv[i],"-f")) /* Arguments */
            if (++i == argc)
                fprintf(stderr,"Missing firstTimeTag");
            else firstTimeTag = atof(argv[i]);
        else if (!strcmp(argv[i],"-l"))
            if (++i == argc)
                fprintf(stderr,"Missing lastTimeTag");
            else lastTimeTag = atof(argv[i]);
        else if (!strcmp(argv[i],"-s"))
            if (++i == argc)
                fprintf(stderr,"Missing timeShift");
            else timeShift = atof(argv[i]);
        else fprintf(stderr,"Unknown option :%s\n",argv[i]);
    }
    if (inputFileName) /* Pick up trailing input file. */
        [aScore readScorefile:inputFileName firstTimeTag:firstTimeTag
       lastTimeTag:lastTimeTag timeShift:timeShift];
    if (!outputFileName) /* Default output file name. */
        outputFileName = @"mix.score";
    [aScore writeScorefile:outputFileName];

    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
