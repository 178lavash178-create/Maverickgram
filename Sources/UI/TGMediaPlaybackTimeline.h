#import <Cocoa/Cocoa.h>

/* A paused player still gets timer ticks. Do not invalidate AppKit controls
 * unless their visible values actually changed. The caller owns time format. */
static inline void TGUpdatePlaybackTimelineControls(NSSlider *slider,
                                                    NSTextField *label,
                                                    double maximum,
                                                    double position,
                                                    BOOL seekable,
                                                    NSString *text) {
    if ([slider minValue] != 0.0) [slider setMinValue:0.0];
    if ([slider maxValue] != maximum) [slider setMaxValue:maximum];
    if ([slider doubleValue] != position) [slider setDoubleValue:position];
    if ([slider isEnabled] != seekable) [slider setEnabled:seekable];
    if (![[label stringValue] isEqualToString:text]) [label setStringValue:text];
}
