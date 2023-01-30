

#import <AppKit/NSScrollView.h>
#import <SndKit/Snd.h>
#import <SndKit/SndView.h>

@protocol ScrollingSoundDelegate;

@interface ScrollingSound:NSScrollView
{
	SndView *soundView;
	id<ScrollingSoundDelegate> delegate;
	float srate;
	CGFloat reductionFactor;
}

- (instancetype)initWithFrame:(NSRect)theFrame;
- (void)centerOnSample:(int)sample;
- (int)sampleAtCenter;

/* Methods to set up the object: */
- (void)setDelegate:(id<ScrollingSoundDelegate>)anObject;
- (void)setSoundView:(SndView *)anObject;
- (void)setSound:(Snd *)aSound;
- (void)setReductionFactor:(CGFloat)rf;

/* Methods to retrieve information about the object: */
- (id<ScrollingSoundDelegate>)delegate;
- (SndView *)soundView;
- (CGFloat)reductionFactor;

@property (assign) id<ScrollingSoundDelegate> delegate;
@property (nonatomic, retain) IBOutlet SndView *soundView;
@property (nonatomic) CGFloat reductionFactor;

/* Methods to get time information about the sound, display, and selection */
- getWindowSamples:(int *)stptr Size:(int *)sizptr;

/* Methods to set display and selection by timings */
- (void)setWindowStart:(NSInteger)start;
- (void)setWindowSize:(NSInteger)size;
- sizeToSelection:sender;

/* Method to replace normal ScrollView methods: */
- (void)reflectScrolledClipView:(NSClipView *)sender;

@end

@protocol ScrollingSoundDelegate <NSObject>
@optional
- (void)displayChanged:(ScrollingSound*) sender;

@end
