#import <Cocoa/Cocoa.h>

// Shared material and native controls for the Aqua capture/preview windows.
// No recorder, camera, microphone or network ownership lives in these views.
@interface TGAquaRecordingDisplayView : NSView
@end
NSTextField *TGAquaRecordingLabel(NSRect frame, NSString *text, NSFont *font, BOOL displayInk);
NSButton *TGAquaRecordingButton(NSRect frame, NSString *title, id target, SEL action, BOOL primary);
void TGAquaRecordingConfigureClock(NSTextField *clock, CGFloat size);
NSRect TGAquaVoiceRecordingClockFrame(void);
