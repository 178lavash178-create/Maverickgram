#!/usr/bin/env python
"""Exercise real cell installation/menu tracking, including exceptional dismissal."""
from __future__ import print_function
import os,sys,tempfile,subprocess,shutil
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
def read(name):
    with open(os.path.join(root,name),'rb') as f: return f.read().decode('utf-8')
def method(text,start,end): return text[text.index(start):text.index(end,text.index(start))]
install=method(read('Sources/UI/TGStatusWindowController+AquaShell.inc'),'- (void)installAquaTextCellOnButton:','- (NSButton *)aquaButtonWithAction:')
attach=method(read('Sources/UI/TGStatusWindowController+ComposerMedia.inc'),'- (void)attachPhoto:','- (NSMenu *)composerTextContextMenu').replace('[NSMenu alloc]','[TrackingMenu alloc]')
source=r'''
#import <Cocoa/Cocoa.h>
#include <assert.h>
@interface TGAquaTextButtonCell : NSButtonCell { BOOL _accented; }
@property(nonatomic,assign) BOOL accented;
@end
@implementation TGAquaTextButtonCell
@synthesize accented=_accented;
@end
static NSButton *TrackedButton;
static BOOL Throws;
static NSUInteger TrackingCalls;
NSString *TGLoc(NSString *key) { return key; }
@interface TrackingMenu : NSMenu
@end
@implementation TrackingMenu
- (BOOL)popUpMenuPositioningItem:(NSMenuItem *)item atLocation:(NSPoint)point inView:(NSView *)view {
    (void)item;(void)point; assert(view==TrackedButton);
    assert(![[TrackedButton cell] isHighlighted] && [TrackedButton state]==NSOffState);
    TrackingCalls++;
    // Tracking can unwind after a nested file sheet or an exception.
    [TrackedButton highlight:YES];[TrackedButton setState:NSOnState];
    if(Throws) [NSException raise:@"TrackingCancelled" format:@"probe"];
    return NO;
}
@end
@interface Host : NSObject { NSButton *_attachPhotoButton; }
@property(nonatomic,retain) NSButton *attachPhotoButton;
@end
@implementation Host
@synthesize attachPhotoButton=_attachPhotoButton;
- (NSNumber *)selectedChatID { return [NSNumber numberWithInt:1]; }
- (NSNumber *)selectedMessageThreadID { return nil; }
- (BOOL)showingForumTopicList { return NO; }
- (NSString *)currentAuthState { return @"ready"; }
- (void)appendDetail:(NSString *)text { (void)text; }
__INSTALL__
__ATTACH__
- (void)dealloc { [_attachPhotoButton release];[super dealloc]; }
@end
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    Host *host=[[[Host alloc] init] autorelease];
    host.attachPhotoButton=[[[NSButton alloc] initWithFrame:NSMakeRect(0,0,100,32)] autorelease];
    NSButton *button=host.attachPhotoButton;TrackedButton=button;
    [button setTitle:@"Файл"];[button setButtonType:NSToggleButton];[button setState:NSOnState];
    [button setTarget:host];[button setAction:@selector(attachPhoto:)];
    [host installAquaTextCellOnButton:button accented:NO];
    assert([button target]==host && [button action]==@selector(attachPhoto:));
    assert([[button title] isEqual:@"Файл"] && [button state]==NSOffState);
    assert([[button cell] showsStateBy]==0);
    for(NSUInteger i=0;i<2;i++) {
        Throws=i==1;[button highlight:YES];[button setState:NSOnState];
        BOOL caught=NO;
        @try { [host attachPhoto:button]; } @catch(NSException *e) { assert([[e name] isEqual:@"TrackingCancelled"]);caught=YES; }
        assert(caught==Throws);
        assert(![[button cell] isHighlighted] && [button state]==NSOffState);
    }
    assert(TrackingCalls==2);
    printf("Aqua attachment tracking: actual momentary installation, target/action/title, cancellation and exceptional menu unwind PASS.\n");
    [pool drain];return 0;
}
'''.replace('__INSTALL__',install).replace('__ATTACH__',attach)
folder=tempfile.mkdtemp(prefix='telegraphica-attachment-tracking-')
try:
    path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(path,'wb') as f: f.write(source.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+[path,'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally: shutil.rmtree(folder)
