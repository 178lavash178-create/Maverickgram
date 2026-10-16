#!/usr/bin/env python
"""Execute the actual controller setter without loading TDLib or an account."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
with open(os.path.join(ROOT, 'Sources/UI/TGStatusWindowController.m'), 'rb') as handle:
    controller = handle.read().decode('utf-8')
start = controller.index('- (void)setActiveSection:(NSString *)section {')
end = controller.index('\n- (void)setClient:', start)
setter = controller[start:end]
selected_chat_start = controller.index('- (void)setSelectedChatID:(NSNumber *)chatID {')
selected_chat_end = controller.index('\n- (void)setProfileUserID:', selected_chat_start)
selected_chat_setter = controller[selected_chat_start:selected_chat_end]
thread_start = controller.index('- (void)setSelectedMessageThreadID:(NSNumber *)threadID {')
thread_end = controller.index('\n- (void)setActiveSection:', thread_start)
thread_setters = controller[thread_start:thread_end]
with open(os.path.join(ROOT, 'Sources/UI/TGStatusWindowController+MediaWindows.inc'), 'rb') as handle:
    media_controller = handle.read().decode('utf-8')
media_start = media_controller.index('- (void)closeMediaCenter:(id)sender {')
media_end = media_controller.index('\n#include', media_start)
media_close = media_controller[media_start:media_end]
harness = r'''
#import <Foundation/Foundation.h>
static BOOL Aqua;
static BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
static void Check(BOOL condition, const char *message) {
    if (!condition) { fprintf(stderr, "Aqua section routing: %s\n", message); exit(1); }
}
@interface MediaPanelProbe : NSObject {
    BOOL _hidden;
}
@property(nonatomic, assign) BOOL hidden;
@end
@implementation MediaPanelProbe
@synthesize hidden = _hidden;
@end
@interface RoutingProbe : NSObject {
    NSString *_activeSection;
    NSObject *_aquaToolbarView;
    NSMutableArray *_events;
    NSString *_laidOutSection;
    BOOL _mediaCenterVisible;
    NSUInteger _mediaCenterGeneration;
    NSMutableSet *_mediaCenterSaveRequests;
    NSMutableSet *_mediaCenterDownloadingFileIDs;
    MediaPanelProbe *_mediaCenterPanelView;
    NSNumber *_selectedChatID;
    NSNumber *_selectedMessageThreadID;
    NSString *_selectedMessageTopicKind;
    NSMutableSet *_pendingArrivalMessageIDs;
}
@property(nonatomic, assign) BOOL mediaCenterVisible;
@property(nonatomic, assign) NSUInteger mediaCenterGeneration;
@property(nonatomic, retain) NSMutableSet *mediaCenterSaveRequests;
@property(nonatomic, retain) NSMutableSet *mediaCenterDownloadingFileIDs;
@property(nonatomic, retain) MediaPanelProbe *mediaCenterPanelView;
@property (nonatomic, copy) NSString *activeSection;
@property (nonatomic, retain) NSObject *aquaToolbarView;
@property (nonatomic, readonly) NSMutableArray *events;
@property (nonatomic, readonly) NSString *laidOutSection;
@property(nonatomic, retain) NSNumber *selectedChatID;
@property(nonatomic, retain) NSNumber *selectedMessageThreadID;
@property(nonatomic, copy) NSString *selectedMessageTopicKind;
@property(nonatomic, retain) NSMutableSet *pendingArrivalMessageIDs;
- (void)invalidateAutomaticReadRequests;
- (void)invalidateAquaPhotoPreview;
- (void)invalidateAquaChatInfoPanel;
- (id)sectionTransitionController;
- (void)cancelAnimation;
- (void)synchronizeUserOpenedChat;
- (void)layoutContentView;
@end
@implementation RoutingProbe
@synthesize activeSection = _activeSection, aquaToolbarView = _aquaToolbarView;
@synthesize mediaCenterVisible = _mediaCenterVisible, mediaCenterGeneration = _mediaCenterGeneration;
@synthesize mediaCenterSaveRequests = _mediaCenterSaveRequests, mediaCenterDownloadingFileIDs = _mediaCenterDownloadingFileIDs;
@synthesize mediaCenterPanelView = _mediaCenterPanelView;
@synthesize selectedChatID = _selectedChatID, selectedMessageThreadID = _selectedMessageThreadID;
@synthesize selectedMessageTopicKind = _selectedMessageTopicKind, pendingArrivalMessageIDs = _pendingArrivalMessageIDs;
- (id)init { if ((self = [super init])) _events = [[NSMutableArray alloc] init]; return self; }
- (void)dealloc { [_activeSection release]; [_aquaToolbarView release]; [_events release]; [_laidOutSection release]; [_mediaCenterSaveRequests release]; [_mediaCenterDownloadingFileIDs release]; [_mediaCenterPanelView release]; [_selectedChatID release]; [_selectedMessageThreadID release]; [_selectedMessageTopicKind release]; [_pendingArrivalMessageIDs release]; [super dealloc]; }
- (NSMutableArray *)events { return _events; }
- (NSString *)laidOutSection { return _laidOutSection; }
- (void)invalidateAutomaticReadRequests { [_events addObject:@"invalidate"]; }
- (void)invalidateAquaPhotoPreview { [_events addObject:@"invalidatePhoto"]; }
- (void)invalidateAquaChatInfoPanel { [_events addObject:@"invalidateInfo"]; }
- (BOOL)isAquaChatInfoPanelActive { return NO; }
- (void)closeAquaChatInfo:(id)sender { (void)sender; }
- (id)transcriptMotionController { return self; }
- (void)cancelAllAnimations { [_events addObject:@"cancelTranscript"]; }
- (void)updateAquaChatBackgroundScope { [_events addObject:@"background"]; }
- (id)sectionTransitionController { return self; }
- (void)cancelAnimation { [_events addObject:@"cancel"]; }
- (void)synchronizeUserOpenedChat { [_events addObject:@"synchronize"]; }
- (void)layoutContentView {
    [_laidOutSection release]; _laidOutSection = [_activeSection copy];
    [_events addObject:@"layout"];
}
- (void)closeMediaCenterInlinePreview:(id)sender { (void)sender; [_events addObject:@"closePreview"]; }
- (void)updateVisibleSection { [_events addObject:@"visibility"]; }
- (void)requestComposerRefocus { [_events addObject:@"refocus"]; }
__MEDIA_CLOSE__
__PRODUCTION_SETTER__
__SELECTED_CHAT_SETTER__
__THREAD_SETTERS__
@end
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *sections = [NSArray arrayWithObjects:@"chats", @"contacts", @"calls", @"settings", @"profile", @"workshop", nil];
    NSUInteger transitions = 0;
    for (NSNumber *mode in [NSArray arrayWithObjects:@NO, @YES, nil]) {
        Aqua = [mode boolValue];
        for (NSString *source in sections) for (NSString *destination in sections) {
            RoutingProbe *probe = [[[RoutingProbe alloc] init] autorelease];
            // Construction can assign a section before the Aqua shell exists.
            probe.activeSection = source;
            Check(![[probe events] containsObject:@"layout"], "initialization must not lay out an uninstalled shell");
            probe.aquaToolbarView = [[[NSObject alloc] init] autorelease];
            [[probe events] removeAllObjects];
            probe.activeSection = destination;
            BOOL changed = ![source isEqualToString:destination];
            NSArray *expected = changed
                ? (Aqua ? [NSArray arrayWithObjects:@"invalidatePhoto", @"invalidateInfo", @"invalidate", @"cancel", @"synchronize", @"layout", nil]
                        : [NSArray arrayWithObjects:@"invalidatePhoto", @"invalidateInfo", @"invalidate", @"cancel", @"synchronize", nil])
                : [NSArray arrayWithObject:@"synchronize"];
            Check([[probe events] isEqualToArray:expected], "transition invalidates previews/profile before reads and synchronization; only installed Aqua shell lays out");
            if (changed && Aqua) Check([[probe laidOutSection] isEqualToString:destination], "layout must observe the incoming section");
            [[probe events] removeAllObjects];
            probe.activeSection = [NSString stringWithFormat:@"%@", destination];
            Check([[probe events] isEqualToArray:[NSArray arrayWithObject:@"synchronize"]], "equal section values must not trigger redundant layout");
            transitions++;
        }
    }
    NSUInteger identities=0;
    for(NSUInteger mode=0;mode<2;mode++) {
        Aqua=mode;
        RoutingProbe *probe=[[[RoutingProbe alloc] init] autorelease];
        // Real heap objects with equal values ensure this does not accidentally
        // pass through NSNumber tagged-pointer identity on modern runtimes.
        NSNumber *first=[[[NSDecimalNumber alloc] initWithString:@"9223372036854775701"] autorelease];
        NSNumber *equal=[[[NSDecimalNumber alloc] initWithString:@"9223372036854775701"] autorelease];
        NSNumber *other=[[[NSDecimalNumber alloc] initWithString:@"9223372036854775702"] autorelease];
        Check(first!=equal && [first isEqual:equal], "identity fixture must use distinct equal-valued number objects");
        probe.mediaCenterSaveRequests=[NSMutableSet setWithObject:@"request"];
        probe.mediaCenterDownloadingFileIDs=[NSMutableSet setWithObject:@"file"];
        probe.pendingArrivalMessageIDs=[NSMutableSet setWithObject:@"arrival"];
        probe.selectedChatID=first;
        [probe.mediaCenterSaveRequests addObject:@"request"];[probe.mediaCenterDownloadingFileIDs addObject:@"file"];[probe.pendingArrivalMessageIDs addObject:@"arrival"];
        [[probe events] removeAllObjects];probe.selectedChatID=equal;
        Check([[probe events] isEqualToArray:[NSArray arrayWithObjects:@"synchronize",@"background",nil]], "equal chat values preserve profile/photo and transcript animation state");
        Check([probe.mediaCenterSaveRequests count]==1 && [probe.mediaCenterDownloadingFileIDs count]==1 && [probe.pendingArrivalMessageIDs count]==1, "equal chat preserves transfer/arrival state");
        [[probe events] removeAllObjects];probe.selectedChatID=other;
        Check([[probe events] isEqualToArray:[NSArray arrayWithObjects:@"invalidate",@"cancelTranscript",@"invalidatePhoto",@"invalidateInfo",@"synchronize",@"background",nil]], "changed chat cancels transient UI before new context synchronization");
        Check([probe.mediaCenterSaveRequests count]==0 && [probe.mediaCenterDownloadingFileIDs count]==0 && [probe.pendingArrivalMessageIDs count]==0, "changed chat clears old transfer/arrival context");identities++;
        probe.selectedMessageThreadID=first;[probe.mediaCenterSaveRequests addObject:@"request"];[probe.mediaCenterDownloadingFileIDs addObject:@"file"];
        [[probe events] removeAllObjects];probe.selectedMessageThreadID=equal;
        Check([[probe events] count]==0 && [probe.mediaCenterSaveRequests count]==1 && [probe.mediaCenterDownloadingFileIDs count]==1, "equal thread values preserve profile/photo and transfer state");
        [[probe events] removeAllObjects];probe.selectedMessageThreadID=other;
        Check([[probe events] isEqualToArray:[NSArray arrayWithObjects:@"invalidate",@"invalidatePhoto",@"invalidateInfo",nil]], "changed thread invalidates reads/photo/profile");
        Check([probe.mediaCenterSaveRequests count]==0 && [probe.mediaCenterDownloadingFileIDs count]==0, "changed thread clears old transfers");identities++;
        probe.selectedMessageTopicKind=@"thread";
        [[probe events] removeAllObjects];probe.selectedMessageTopicKind=[NSMutableString stringWithString:@"thread"];
        Check([[probe events] count]==0, "equal topic kind values preserve profile/photo presentation");
        [[probe events] removeAllObjects];probe.selectedMessageTopicKind=@"forum";
        Check([[probe events] isEqualToArray:[NSArray arrayWithObjects:@"invalidate",@"invalidatePhoto",@"invalidateInfo",nil]], "changed topic kind invalidates reads/photo/profile");identities++;
    }
    for(NSUInteger mode=0;mode<2;mode++) {
        Aqua=mode;
        RoutingProbe *probe=[[[RoutingProbe alloc] init] autorelease];
        probe.mediaCenterVisible=YES; probe.mediaCenterGeneration=9;
        probe.mediaCenterSaveRequests=[NSMutableSet setWithObject:@"request"];
        probe.mediaCenterDownloadingFileIDs=[NSMutableSet setWithObject:@"file"];
        probe.mediaCenterPanelView=[[[MediaPanelProbe alloc] init] autorelease];
        [probe closeMediaCenter:nil];
        NSArray *expected=Aqua ? [NSArray arrayWithObjects:@"closePreview",@"layout",@"visibility",@"refocus",nil]
                               : [NSArray arrayWithObjects:@"closePreview",@"visibility",@"refocus",nil];
        Check([[probe events] isEqualToArray:expected], "closing media restores Aqua geometry before visibility/refocus and preserves Classic event order");
        Check(!probe.mediaCenterVisible && probe.mediaCenterGeneration==10 && probe.mediaCenterPanelView.hidden, "media state is closed");
        Check([probe.mediaCenterSaveRequests count]==0 && [probe.mediaCenterDownloadingFileIDs count]==0, "media save state cleaned");
    }
    printf("Aqua actual media close restores geometry before presentation; Classic ordering unchanged PASS\n");
    printf("Aqua section routing passed: %lu real-setter transitions, Classic preservation, construction guard and repeated-section checks.\n", (unsigned long)transitions);
    printf("Aqua actual identity setters passed: %lu chat/thread/topic flows with distinct equal-value objects and true context changes.\n", (unsigned long)identities);
    [pool drain]; return 0;
}
'''.replace('__PRODUCTION_SETTER__', setter).replace('__MEDIA_CLOSE__', media_close).replace('__SELECTED_CHAT_SETTER__', selected_chat_setter).replace('__THREAD_SETTERS__', thread_setters)
folder = tempfile.mkdtemp(prefix='telegraphica-aqua-section-routing-')
try:
    source = os.path.join(folder, 'routing-probe.m')
    binary = os.path.join(folder, 'routing-probe')
    with open(source, 'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:] + [source, '-framework', 'Foundation', '-o', binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
