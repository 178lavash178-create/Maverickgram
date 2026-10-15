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
harness = r'''
#import <Foundation/Foundation.h>
static BOOL Aqua;
static BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
static void Check(BOOL condition, const char *message) {
    if (!condition) { fprintf(stderr, "Aqua section routing: %s\n", message); exit(1); }
}
@interface RoutingProbe : NSObject {
    NSString *_activeSection;
    NSObject *_aquaToolbarView;
    NSMutableArray *_events;
    NSString *_laidOutSection;
}
@property (nonatomic, copy) NSString *activeSection;
@property (nonatomic, retain) NSObject *aquaToolbarView;
@property (nonatomic, readonly) NSMutableArray *events;
@property (nonatomic, readonly) NSString *laidOutSection;
- (void)invalidateAutomaticReadRequests;
- (id)sectionTransitionController;
- (void)cancelAnimation;
- (void)synchronizeUserOpenedChat;
- (void)layoutContentView;
@end
@implementation RoutingProbe
@synthesize activeSection = _activeSection, aquaToolbarView = _aquaToolbarView;
- (id)init { if ((self = [super init])) _events = [[NSMutableArray alloc] init]; return self; }
- (void)dealloc { [_activeSection release]; [_aquaToolbarView release]; [_events release]; [_laidOutSection release]; [super dealloc]; }
- (NSMutableArray *)events { return _events; }
- (NSString *)laidOutSection { return _laidOutSection; }
- (void)invalidateAutomaticReadRequests { [_events addObject:@"invalidate"]; }
- (id)sectionTransitionController { return self; }
- (void)cancelAnimation { [_events addObject:@"cancel"]; }
- (void)synchronizeUserOpenedChat { [_events addObject:@"synchronize"]; }
- (void)layoutContentView {
    [_laidOutSection release]; _laidOutSection = [_activeSection copy];
    [_events addObject:@"layout"];
}
__PRODUCTION_SETTER__
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
                ? (Aqua ? [NSArray arrayWithObjects:@"invalidate", @"cancel", @"synchronize", @"layout", nil]
                        : [NSArray arrayWithObjects:@"invalidate", @"cancel", @"synchronize", nil])
                : [NSArray arrayWithObject:@"synchronize"];
            Check([[probe events] isEqualToArray:expected], "transition invalidates reads and lays out once after synchronization; Classic remains unchanged");
            if (changed && Aqua) Check([[probe laidOutSection] isEqualToString:destination], "layout must observe the incoming section");
            [[probe events] removeAllObjects];
            probe.activeSection = [NSString stringWithFormat:@"%@", destination];
            Check([[probe events] isEqualToArray:[NSArray arrayWithObject:@"synchronize"]], "equal section values must not trigger redundant layout");
            transitions++;
        }
    }
    printf("Aqua section routing passed: %lu real-setter transitions, Classic preservation, construction guard and repeated-section checks.\n", (unsigned long)transitions);
    [pool drain]; return 0;
}
'''.replace('__PRODUCTION_SETTER__', setter)
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
