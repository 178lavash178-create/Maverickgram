#import "TGDialogPresentation.h"
#import "TGInterfaceDesign.h"

// Synchronous callers must not outlive their alert, owner window or delegate
// while AppKit dispatches network callbacks and window-close notifications.
@interface TGDialogSheetSession : NSObject {
    NSWindow *_parent;
    NSWindow *_sheet;
    NSInteger _result;
    BOOL _finished;
    BOOL _running;
}
- (id)initWithParent:(NSWindow *)parent sheet:(NSWindow *)sheet;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)code contextInfo:(void *)context;
- (void)panelDidEnd:(NSWindow *)panel returnCode:(NSInteger)code contextInfo:(void *)context;
- (NSInteger)run;
@end

static TGDialogSheetSession *TGActiveDialogSheetSession = nil;

@implementation TGDialogSheetSession
- (id)initWithParent:(NSWindow *)parent sheet:(NSWindow *)sheet {
    self = [super init];
    if (self) {
        _parent = [parent retain]; _sheet = [sheet retain];
        _result = NSRunAbortedResponse;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(cancel:) name:NSWindowWillCloseNotification object:parent];
        [center addObserver:self selector:@selector(cancel:) name:NSApplicationWillTerminateNotification object:NSApp];
    }
    return self;
}
- (void)finishWithCode:(NSInteger)code {
    if (_finished) return;
    _finished = YES; _result = code;
    if (_running && [NSApp modalWindow] == _sheet) [NSApp stopModalWithCode:code];
    [_sheet orderOut:nil];
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)code contextInfo:(void *)context {
    (void)alert; (void)context; [self finishWithCode:code];
}
- (void)panelDidEnd:(NSWindow *)panel returnCode:(NSInteger)code contextInfo:(void *)context {
    (void)panel; (void)context; [self finishWithCode:code];
}
- (void)cancel:(NSNotification *)notification {
    (void)notification;
    if (_finished) return;
    if ([_parent attachedSheet] == _sheet) [NSApp endSheet:_sheet returnCode:NSRunAbortedResponse];
    [self finishWithCode:NSRunAbortedResponse];
}
- (NSInteger)run {
    if (!_finished) {
        _running = YES;
        NSInteger modalResult = [NSApp runModalForWindow:_sheet];
        _running = NO;
        // An external abort must never turn into acceptance, even if AppKit
        // stops the modal loop without invoking a sheet delegate callback.
        if (!_finished) {
            (void)modalResult;
            [self cancel:nil];
        }
    }
    return _result;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_sheet release]; [_parent release]; [super dealloc];
}
@end

static NSWindow *TGDialogParent(NSWindow *preferredParent) {
    NSWindow *parent = preferredParent ? preferredParent : [NSApp keyWindow];
    if (!parent && !preferredParent) parent = [NSApp mainWindow];
    return parent;
}

static BOOL TGDialogParentCanPresent(NSWindow *parent) {
    return [NSThread isMainThread] && parent && [parent isVisible] && ![parent isMiniaturized] &&
        ![parent attachedSheet] && ![parent sheetParent] && !TGActiveDialogSheetSession;
}

NSInteger TGRunAlert(NSAlert *alert, NSWindow *preferredParent) {
    if (!alert || ![NSThread isMainThread]) return NSRunAbortedResponse;
    if (!TGInterfaceDesignIsAqua()) return [alert runModal];
    if (TGActiveDialogSheetSession || [NSApp modalWindow]) return NSRunAbortedResponse;
    NSWindow *parent = TGDialogParent(preferredParent);
    if (!parent && !TGActiveDialogSheetSession) return [alert runModal];
    if (!TGDialogParentCanPresent(parent)) return NSRunAbortedResponse;
    [alert retain];
    TGDialogSheetSession *session = [[TGDialogSheetSession alloc] initWithParent:parent sheet:[alert window]];
    TGActiveDialogSheetSession = session;
    NSInteger result = NSRunAbortedResponse;
    @try {
        [alert beginSheetModalForWindow:parent modalDelegate:session didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
        result = [session run];
    } @finally {
        if ([parent attachedSheet] == [alert window]) [NSApp endSheet:[alert window] returnCode:NSRunAbortedResponse];
        [[alert window] orderOut:nil];
        TGActiveDialogSheetSession = nil;
        [session release]; [alert release];
    }
    return result;
}

NSInteger TGRunFilePanel(NSSavePanel *panel, NSWindow *preferredParent) {
    if (!panel || ![NSThread isMainThread]) return NSCancelButton;
    if (!TGInterfaceDesignIsAqua()) return [panel runModal];
    if (TGActiveDialogSheetSession || [NSApp modalWindow]) return NSCancelButton;
    NSWindow *parent = TGDialogParent(preferredParent);
    if (!parent && !TGActiveDialogSheetSession) return [panel runModal];
    if (!TGDialogParentCanPresent(parent)) return NSCancelButton;
    [panel retain];
    TGDialogSheetSession *session = [[TGDialogSheetSession alloc] initWithParent:parent sheet:panel];
    TGActiveDialogSheetSession = session;
    NSInteger result = NSCancelButton;
    @try {
        // Available since 10.6; unlike the older directory/file API this
        // preserves directoryURL, allowed types and save-name configuration.
        [panel beginSheetModalForWindow:parent completionHandler:^(NSInteger code) {
            [session panelDidEnd:panel returnCode:code contextInfo:NULL];
        }];
        result = [session run];
        if (result != NSOKButton) result = NSCancelButton;
    } @finally {
        if ([parent attachedSheet] == panel) [NSApp endSheet:panel returnCode:NSCancelButton];
        [panel orderOut:nil];
        TGActiveDialogSheetSession = nil;
        [session release]; [panel release];
    }
    return result;
}
