#!/usr/bin/env python
"""Run the production late-update path after switching away from messages."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
with open(os.path.join(root, 'Sources/UI/TGStatusWindowController+MessageDataFlow.inc'), 'rb') as handle:
    source = handle.read().decode('utf-8')
start = source.index('- (void)updateMessageJumpToNewestButtonVisibility {')
end = source.index('\n- (void)jumpToNewestMessages:', start)
method = source[start:end]
harness = r'''
#import <Foundation/Foundation.h>
static NSString *const TGSectionChats = @"chats";
@interface ButtonProbe : NSObject
@property(nonatomic) BOOL hidden;
@property(nonatomic) BOOL enabled;
@end
@implementation ButtonProbe
@synthesize hidden, enabled;
@end
@interface VisibilityProbe : NSObject
@property(nonatomic,copy) NSString *currentAuthState;
@property(nonatomic,copy) NSString *activeSection;
@property(nonatomic,retain) NSNumber *selectedChatID;
@property(nonatomic) BOOL chatNavigationClosed;
@property(nonatomic) BOOL mediaCenterVisible;
@property(nonatomic,retain) ButtonProbe *messageJumpToNewestButton;
@end
@implementation VisibilityProbe
@synthesize currentAuthState, activeSection, selectedChatID, chatNavigationClosed, mediaCenterVisible, messageJumpToNewestButton;
- (void)dealloc { [currentAuthState release]; [activeSection release]; [selectedChatID release]; [messageJumpToNewestButton release]; [super dealloc]; }
__METHOD__
@end
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VisibilityProbe *probe = [[[VisibilityProbe alloc] init] autorelease];
    probe.messageJumpToNewestButton = [[[ButtonProbe alloc] init] autorelease];
    NSArray *sections = [NSArray arrayWithObjects:@"chats", @"settings", @"contacts", @"calls", @"profile", @"workshop", [NSNull null], nil];
    NSUInteger cases = 0;
    for (id section in sections) for (NSUInteger mask=0; mask<16; mask++) {
        probe.activeSection = section == [NSNull null] ? nil : section;
        probe.currentAuthState = (mask & 1) ? @"ready" : @"connecting";
        probe.selectedChatID = (mask & 2) ? [NSNumber numberWithInt:1] : nil;
        probe.chatNavigationClosed = (mask & 4) != 0;
        probe.mediaCenterVisible = (mask & 8) != 0;
        BOOL expected = (mask == 3 && (section == [NSNull null] || [section isEqual:@"chats"]));
        // A delayed history/scroll callback can arrive after either state.
        for (NSUInteger prior=0;prior<2;prior++) {
            probe.messageJumpToNewestButton.hidden = prior;
            probe.messageJumpToNewestButton.enabled = !prior;
            [probe updateMessageJumpToNewestButtonVisibility];
            if (probe.messageJumpToNewestButton.hidden != !expected || probe.messageJumpToNewestButton.enabled != expected) {
                fprintf(stderr,"Message jump visibility regression: mask%lu section%s\n", (unsigned long)mask, [[section description] UTF8String]);
                return 1;
            }
            cases++;
        }
    }
    printf("Message jump visibility PASS: %lu late updates across messages, media, closed chats and utility sections.\n", (unsigned long)cases);
    [pool drain]; return 0;
}
'''.replace('__METHOD__', method)
folder = tempfile.mkdtemp(prefix='telegraphica-message-jump-')
try:
    path = os.path.join(folder, 'probe.m')
    binary = os.path.join(folder, 'probe')
    with open(path, 'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:] + [path, '-framework', 'Foundation', '-o', binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
