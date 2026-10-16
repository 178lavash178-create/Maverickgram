#import "TGMediaPlaybackTimeline.h"
#include <stdlib.h>

// Count observable writes without requiring a WindowServer or a media backend.
@interface TimelineControl : NSObject {
@public NSUInteger writes; double minimum, maximum, position; BOOL enabled; NSString *text;
}
@end
@implementation TimelineControl
- (double)minValue { return minimum; }
- (double)maxValue { return maximum; }
- (double)doubleValue { return position; }
- (BOOL)isEnabled { return enabled; }
- (NSString *)stringValue { return text ? text : @""; }
- (void)setMinValue:(double)value { minimum=value; writes++; }
- (void)setMaxValue:(double)value { maximum=value; writes++; }
- (void)setDoubleValue:(double)value { position=value; writes++; }
- (void)setEnabled:(BOOL)value { enabled=value; writes++; }
- (void)setStringValue:(NSString *)value { [text release]; text=[value copy]; writes++; }
- (void)dealloc { [text release]; [super dealloc]; }
@end
static void Require(BOOL ok) { if(!ok) abort(); }
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    TimelineControl *slider=[[[TimelineControl alloc] init] autorelease];
    TimelineControl *label=[[[TimelineControl alloc] init] autorelease];
    TGUpdatePlaybackTimelineControls((id)slider,(id)label,120,30,YES,@"0:30 / 2:00");
    Require(slider->writes==3 && label->writes==1);
    slider->writes=label->writes=0;
    for(NSUInteger tick=0;tick<1000;tick++)
        TGUpdatePlaybackTimelineControls((id)slider,(id)label,120,30,YES,@"0:30 / 2:00");
    Require(slider->writes==0 && label->writes==0);
    TGUpdatePlaybackTimelineControls((id)slider,(id)label,120,30.25,YES,@"0:30 / 2:00");
    Require(slider->writes==1 && label->writes==0);
    TGUpdatePlaybackTimelineControls((id)slider,(id)label,120,31,YES,@"0:31 / 2:00");
    Require(slider->writes==2 && label->writes==1);
    TGUpdatePlaybackTimelineControls((id)slider,(id)label,1,0,NO,@"0:00 / 0:00");
    Require(slider->maximum==1 && slider->position==0 && !slider->enabled);
    TGUpdatePlaybackTimelineControls((id)slider,(id)label,240,0,YES,@"0:00 / 4:00");
    Require(slider->maximum==240 && slider->enabled && [label->text isEqual:@"0:00 / 4:00"]);
    puts("Playback timeline PASS: 1000 unchanged ticks produce zero control writes; progress, second, reset and duration transitions retained.");
    [pool drain]; return 0;
}
