#include <unistd.h>
#import <Cocoa/Cocoa.h>
#import "TGDialogPresentation.h"

static BOOL Aqua = YES;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
static NSUInteger Checks = 0;
static void Check(BOOL value, NSString *detail) {
    Checks++;
    if (!value) { fprintf(stderr,"FAIL: %s\n",[detail UTF8String]); exit(2); }
}
@interface TGProbeAlert : NSAlert
@end
@implementation TGProbeAlert
- (NSInteger)runModal { return 2345; }
@end
@interface TGSheetDriver : NSObject {
@public
    NSAlert *alert;
    NSWindow *parent;
    NSSavePanel *panel;
    NSInteger operation;
    NSInteger buttonIndex;
    BOOL wasAttached;
    BOOL nestedRejected;
}
- (void)fire:(NSTimer *)timer;
@end
@implementation TGSheetDriver
- (void)fire:(NSTimer *)timer {
    (void)timer;
    wasAttached = ([parent attachedSheet] == (panel ? (NSWindow *)panel : [alert window]));
    if (operation == 1) [parent close];
    else if (operation == 2) [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillTerminateNotification object:NSApp];
    else if (operation == 3) [NSApp abortModal];
    else if (operation == 4) [panel cancel:nil];
    else if (operation == 6) [NSApp endSheet:panel returnCode:NSOKButton];
    else {
        if (operation == 5) {
            NSAlert *nested = [[[NSAlert alloc] init] autorelease];
            nestedRejected = TGRunAlert(nested,parent) == NSRunAbortedResponse;
        }
        [[[alert buttons] objectAtIndex:(NSUInteger)buttonIndex] performClick:nil];
    }
}
@end
static void Schedule(TGSheetDriver *driver) {
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.15 target:driver selector:@selector(fire:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}
static NSWindow *Window(void) {
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(120,150,640,480)
        styleMask:NSTitledWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO]; [window makeKeyAndOrderFront:nil]; return window;
}
static NSAlert *Alert(void) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Sheet presentation test"];
    [alert addButtonWithTitle:@"First"]; [alert addButtonWithTitle:@"Second"]; [alert addButtonWithTitle:@"Third"];
    return alert;
}
static void RunCases(void) {
    NSWindow *parent = Window();
    Aqua = NO;
    Check(TGRunAlert([[[TGProbeAlert alloc] init] autorelease],parent)==2345,@"Classic retains runModal result");
    Aqua = YES;
    Check(TGRunAlert(nil,parent)==NSRunAbortedResponse,@"nil alert cancels");
    [parent orderOut:nil];
    Check(TGRunAlert(Alert(),parent)==NSRunAbortedResponse,@"hidden explicit owner cancels");
    [parent makeKeyAndOrderFront:nil];
    NSAlert *reusedAlert = Alert();
    for (NSInteger index=0; index<3; index++) {
        TGSheetDriver *driver = [[[TGSheetDriver alloc] init] autorelease]; driver->parent=parent;driver->alert=reusedAlert;driver->buttonIndex=index;
        NSTextField *field=[[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,250,24)] autorelease];
        [field setStringValue:@"preserved accessory input"];[driver->alert setAccessoryView:field];
        Schedule(driver);
        NSInteger result=TGRunAlert(driver->alert,parent);
        Check(driver->wasAttached,@"native alert attached to explicit parent");
        Check(result==NSAlertFirstButtonReturn+index,@"exact original button result");
        Check(![parent attachedSheet],@"sheet detached before returning");
        Check([[field stringValue] isEqualToString:@"preserved accessory input"],@"accessory values survive");
    }
    for (NSInteger operation=1;operation<=3;operation++) {
        if (operation==2) continue; // Termination notification is tested last.
        parent=Window();
        TGSheetDriver *driver=[[[TGSheetDriver alloc] init] autorelease];driver->parent=parent;driver->alert=Alert();driver->operation=operation;Schedule(driver);
        Check(TGRunAlert(driver->alert,parent)==NSRunAbortedResponse,@"close, termination or external abort cannot accept");
        Check(![parent attachedSheet],@"cancelled sheet detached");
        Check(![[driver->alert window] isVisible],@"cancelled sheet hidden");
    }
    parent=Window();
    TGSheetDriver *driver=[[[TGSheetDriver alloc] init] autorelease];driver->parent=parent;driver->alert=Alert();driver->operation=5;Schedule(driver);
    Check(TGRunAlert(driver->alert,nil)==NSAlertFirstButtonReturn,@"nil owner resolves an available window or uses modal fallback");
    Check(driver->nestedRejected,@"nested presentation safely rejected");
    NSWindow *foreign=Window(); [foreign orderOut:nil];
    [NSApp beginSheet:foreign modalForWindow:parent modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    Check([parent attachedSheet]==foreign,@"foreign sheet fixture is attached before presenting another");
    Check(TGRunAlert(Alert(),parent)==NSRunAbortedResponse,@"unrelated existing sheet left alone");
    Check([parent attachedSheet]==foreign,@"foreign sheet retained");
    Check(TGRunFilePanel([NSSavePanel savePanel],parent)==NSCancelButton,@"file panel never nests on busy owner");
    [NSApp endSheet:foreign];[foreign orderOut:nil];
    parent=Window();
    driver=[[[TGSheetDriver alloc] init] autorelease];driver->parent=parent;driver->panel=[NSOpenPanel openPanel];driver->operation=4;Schedule(driver);
    Check(TGRunFilePanel(driver->panel,parent)==NSCancelButton,@"real file panel cancellation preserved");
    Check(driver->wasAttached,@"real file panel attached");
    Check(![parent attachedSheet],@"file panel detached");
    parent=Window();
    driver=[[[TGSheetDriver alloc] init] autorelease];driver->parent=parent;driver->panel=[NSSavePanel savePanel];driver->operation=6;
    NSString *filename=[NSString stringWithFormat:@"telegraphica-sheet-%@.txt",[[NSProcessInfo processInfo] globallyUniqueString]];
    [driver->panel setDirectoryURL:[NSURL fileURLWithPath:@"/private/tmp" isDirectory:YES]];
    [driver->panel setNameFieldStringValue:filename];Schedule(driver);
    Check(TGRunFilePanel(driver->panel,parent)==NSOKButton,@"save panel completion OK preserved");
    Check(driver->wasAttached,@"real save panel attached");
    Check([[driver->panel nameFieldStringValue] isEqualToString:filename],@"configured save filename preserved");
    Check(![parent attachedSheet],@"accepted save panel detached");
    parent=Window();
    driver=[[[TGSheetDriver alloc] init] autorelease];driver->parent=parent;driver->alert=Alert();driver->operation=2;Schedule(driver);
    Check(TGRunAlert(driver->alert,parent)==NSRunAbortedResponse,@"application termination cannot accept");
    Check(![parent attachedSheet],@"termination sheet detached");
    Check(![[driver->alert window] isVisible],@"termination sheet hidden");
    printf("PASS: %lu native sheet lifecycle, return-code, accessory, busy-owner and file-panel checks\n",(unsigned long)Checks);
}
@interface TGSheetProbeRunner : NSObject
- (void)runCases:(id)sender;
@end
@implementation TGSheetProbeRunner
- (void)runCases:(id)sender {
    (void)sender; RunCases(); [NSApp stop:nil];
    [NSApp postEvent:[NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:NO];
}
@end
int main(void) {
    alarm(30);
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    TGSheetProbeRunner *runner=[[[TGSheetProbeRunner alloc] init] autorelease];
    [runner performSelector:@selector(runCases:) withObject:nil afterDelay:0.1];
    [NSApp run]; alarm(0); [pool drain]; return 0;
}
