#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "TGVideoNoteRecorderWindowController.h"
#import "TGAquaRecordingViews.h"
#import "TGAquaShellViews.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGThemeTextField.h"
#import "TGTheme.h"
#import "TGLocalization.h"
#import "TGDialogPresentation.h"
#include <unistd.h>
static BOOL Aqua=YES;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
#ifndef TELEGRAPHICA_RECORDING_REAL_ASSETS
NSColor *TGColorFromHex(NSUInteger hex) { return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1]; }
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *color,CGFloat alpha,BOOL flip) { (void)name;(void)rect;(void)color;(void)alpha;(void)flip; }
NSImage *TGTemplateIconAssetImage(NSString *name,NSSize size,NSColor *color,CGFloat alpha) { (void)name;(void)color;(void)alpha;return [[[NSImage alloc] initWithSize:size] autorelease]; }
NSColor *TGClassicHeaderTextColor(CGFloat alpha) { return [NSColor colorWithCalibratedWhite:0.1 alpha:alpha]; }
NSColor *TGClassicTableGridColor(void) { return [NSColor grayColor]; }
NSColor *TGClassicCardInkColor(void) { return [NSColor blackColor]; }
NSColor *TGThemeSurfaceInkColor(NSColor *color,TGThemeSurfaceRole role,CGFloat contrast) { (void)role;(void)contrast;return color; }
void TGThemeDrawGroupedCardInPath(NSBezierPath *path,NSRect rect,BOOL flipped) { (void)path;(void)flipped;[[NSColor whiteColor] set];NSRectFill(rect); }
#endif
@implementation TGUtilityWindowView @end
@implementation TGUtilityPanelView @end
@implementation TGGroupedCardView
@synthesize drawsInterior=_drawsInterior;
@end
#ifndef TELEGRAPHICA_RECORDING_REAL_ASSETS
@implementation TGPrimaryTextButtonCell @end
@implementation TGSecondaryTextButtonCell @end
@implementation TGMediaPlaybackButtonCell @end
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release];[super dealloc]; }
@end
#endif
@implementation TGThemeTextField
@synthesize themeSurface=_themeSurface,detailInk=_detailInk,errorInk=_errorInk;
- (void)refreshThemeInk { [self setTextColor:[NSColor blackColor]]; }
@end
@interface TGVoiceRecordingProbe : NSObject <NSWindowDelegate> {
    NSWindow *_voicePreviewWindow;
    NSTextField *_voicePreviewTitleField,*_voicePreviewTimeField,*_voicePreviewErrorField;
    NSButton *_voicePreviewPlayButton,*_voicePreviewStopButton,*_voicePreviewCancelButton,*_voicePreviewSendButton;
    NSSlider *_voicePreviewProgressSlider;
@public NSUInteger timerStarts,timerStops;
}
@property(retain) NSWindow *voicePreviewWindow;
@property(retain) NSTextField *voicePreviewTitleField,*voicePreviewTimeField,*voicePreviewErrorField;
@property(retain) NSButton *voicePreviewPlayButton,*voicePreviewStopButton,*voicePreviewCancelButton,*voicePreviewSendButton;
@property(retain) NSSlider *voicePreviewProgressSlider;
@end
@implementation TGVoiceRecordingProbe
@synthesize voicePreviewWindow=_voicePreviewWindow,voicePreviewTitleField=_voicePreviewTitleField,voicePreviewTimeField=_voicePreviewTimeField,voicePreviewErrorField=_voicePreviewErrorField;
@synthesize voicePreviewPlayButton=_voicePreviewPlayButton,voicePreviewStopButton=_voicePreviewStopButton,voicePreviewCancelButton=_voicePreviewCancelButton,voicePreviewSendButton=_voicePreviewSendButton,voicePreviewProgressSlider=_voicePreviewProgressSlider;
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font { return TGAquaRecordingLabel(frame,text,font,NO); }
- (void)applyMutedLabelStyle:(NSTextField *)field { (void)field; }
- (NSButton *)modalCloseButtonWithFrame:(NSRect)frame { return [[[NSButton alloc] initWithFrame:frame] autorelease]; }
- (void)applySkeuomorphicButtonStyle:(NSButton *)button isPrimary:(BOOL)primary { (void)button;(void)primary; }
- (void)startVoicePreviewTimer { timerStarts++; }
- (void)invalidateVoicePreviewTimer { timerStops++; }
- (void)updateVoicePreviewTimelineWithCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration { (void)time;[self.voicePreviewTimeField setStringValue:[NSString stringWithFormat:@"0:00 / %ld:%02ld",(long)duration/60,(long)duration%60]]; }
#include "TGStatusWindowController+VoicePreview.inc"
- (void)dealloc {
    [_voicePreviewWindow setDelegate:nil];[_voicePreviewWindow close];[_voicePreviewWindow release];
    [_voicePreviewTitleField release];[_voicePreviewTimeField release];[_voicePreviewErrorField release];[_voicePreviewPlayButton release];[_voicePreviewStopButton release];[_voicePreviewCancelButton release];[_voicePreviewSendButton release];[_voicePreviewProgressSlider release];[super dealloc];
}
@end
static NSUInteger Checks=0;
static void Check(BOOL value,const char *message) { Checks++;if(!value) { fprintf(stderr,"FAIL: %s\n",message);exit(2); } }
static void CheckControls(NSWindow *window,NSArray *controls) {
    NSRect bounds=[[window contentView] bounds];
    for(NSView *view in controls) {
        if([view isHidden]) continue;
        Check(NSContainsRect(bounds,[view frame]),"visible recording control is inside window");
        if([view isKindOfClass:[NSButton class]]) {
            NSButton *button=(NSButton *)view;
            NSRect titleRect=[[button cell] titleRectForBounds:[button bounds]];
            CGFloat measured=[[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[button font] forKey:NSFontAttributeName]].width;
            Check(measured<=NSWidth(titleRect)+1,"localized control title fits actual cell");
        }
        for(NSView *other in controls) if(view!=other && ![other isHidden])
            Check(!NSIntersectsRect([view frame],[other frame]),"visible recording controls do not overlap");
    }
}
// Optional visual QA uses the production view tree and original bundled
// assets. Default verification never writes an image or accesses capture input.
static void ExportSnapshot(NSWindow *window,NSString *name) {
    NSString *directory=[[[NSProcessInfo processInfo] environment] objectForKey:@"TELEGRAPHICA_RECORDING_PROBE_OUTPUT"];
    if (![directory length]) return;
#ifndef TELEGRAPHICA_RECORDING_REAL_ASSETS
    Check(NO,"snapshot export requires TELEGRAPHICA_RECORDING_REAL_ASSETS build");
#else
    Check([[NSBundle mainBundle] pathForResource:@"brushed_alu" ofType:@"png" inDirectory:@"Textures"]!=nil,"snapshot bundle contains original metal texture");
    NSError *error=nil;
    Check([[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error],"snapshot output directory is writable");
    NSView *view=[window contentView];[view displayIfNeeded];
    NSBitmapImageRep *bitmap=[view bitmapImageRepForCachingDisplayInRect:[view bounds]];
    Check(bitmap!=nil,"native view creates a snapshot bitmap");
    [view cacheDisplayInRect:[view bounds] toBitmapImageRep:bitmap];
    NSData *png=[bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    Check([png writeToFile:[directory stringByAppendingPathComponent:name] atomically:YES],"native view PNG saved");
#endif
}
static NSArray *VideoControls(TGVideoNoteRecorderWindowController *video) {
    return [NSArray arrayWithObjects:[video valueForKey:@"recordButton"],[video valueForKey:@"stopButton"],[video valueForKey:@"playButton"],[video valueForKey:@"retryButton"],[video valueForKey:@"cancelButton"],[video valueForKey:@"sendButton"],[video valueForKey:@"timerField"],[video valueForKey:@"statusField"],nil];
}
static NSArray *VoiceControls(TGVoiceRecordingProbe *voice) {
    return [NSArray arrayWithObjects:voice.voicePreviewPlayButton,voice.voicePreviewStopButton,voice.voicePreviewCancelButton,voice.voicePreviewSendButton,voice.voicePreviewTimeField,voice.voicePreviewProgressSlider,nil];
}
int main(void) {
    alarm(30);NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language);Aqua=YES;
        TGVideoNoteRecorderWindowController *video=[[TGVideoNoteRecorderWindowController alloc] init];
        Check(NSEqualSizes([[[video window] contentView] bounds].size,NSMakeSize(580,650)),"Aqua video uses dedicated window geometry");
        Check([[[video window] contentView] isKindOfClass:[TGAquaMetalView class]],"Aqua video has metal casework");
        Check([video valueForKey:@"captureSession"]==nil,"UI construction never opens camera");
        for(NSString *selector in [NSArray arrayWithObjects:@"showReadyToRecordControls",@"showStartingControls",@"showRecordingControls",@"showPreparingControls",@"showPreviewControls",nil]) {
            [video performSelector:NSSelectorFromString(selector)];CheckControls([video window],VideoControls(video));
            Check(![[video valueForKey:@"timerField"] isHidden],"Aqua timer remains visible in every recording state");
            if ([language isEqualToString:@"ru"] && [selector isEqualToString:@"showReadyToRecordControls"]) ExportSnapshot([video window],@"aqua-video-ready.png");
            if ([language isEqualToString:@"ru"] && [selector isEqualToString:@"showPreviewControls"]) ExportSnapshot([video window],@"aqua-video-preview.png");
        }
        Check([video valueForKey:@"movieOutput"]==nil && [video valueForKey:@"previewPlayer"]==nil,"state UI tests never record or play media");[video release];
        TGVoiceRecordingProbe *voice=[[TGVoiceRecordingProbe alloc] init];
        [voice configureVoicePreviewWindowForRecording];CheckControls(voice.voicePreviewWindow,VoiceControls(voice));
        Check(![voice.voicePreviewTimeField isHidden] && ![voice.voicePreviewCancelButton isHidden] && ![voice.voicePreviewStopButton isHidden],"Aqua recording shows timer, cancel and stop");
        Check([voice.voicePreviewSendButton isHidden] && [voice.voicePreviewPlayButton isHidden],"recording cannot accidentally send/play");
        Check(voice->timerStarts==1,"recording state starts elapsed display timer");
        if ([language isEqualToString:@"ru"]) ExportSnapshot(voice.voicePreviewWindow,@"aqua-voice-recording.png");
        [voice configureVoicePreviewWindowForReadyDuration:89];CheckControls(voice.voicePreviewWindow,VoiceControls(voice));
        Check([voice.voicePreviewStopButton isHidden] && ![voice.voicePreviewSendButton isHidden] && ![voice.voicePreviewProgressSlider isHidden],"Aqua preview shows send and timeline instead of stop");
        Check(voice->timerStops==1,"preview state stops recording elapsed timer");
        if ([language isEqualToString:@"ru"]) ExportSnapshot(voice.voicePreviewWindow,@"aqua-voice-ready.png");
        [voice release];
        Aqua=NO;
        video=[[TGVideoNoteRecorderWindowController alloc] init];
        Check(NSEqualSizes([[[video window] contentView] bounds].size,NSMakeSize(540,650)),"Classic video geometry preserved");
        Check([[video valueForKey:@"timerField"] isHidden],"Classic ready state keeps original timer visibility");[video release];
        voice=[[TGVoiceRecordingProbe alloc] init];[voice configureVoicePreviewWindowForRecording];
        Check(NSEqualSizes([[voice.voicePreviewWindow contentView] bounds].size,NSMakeSize(420,190)),"Classic voice geometry preserved");
        Check([voice.voicePreviewTimeField isHidden] && [voice.voicePreviewCancelButton isHidden] && voice->timerStarts==0,"Classic recording presentation unchanged");[voice release];
    }
    printf("PASS: %lu production Aqua recording geometry, localized cell fit and state checks without camera/microphone access\n",(unsigned long)Checks);
    alarm(0);[pool drain];return 0;
}
