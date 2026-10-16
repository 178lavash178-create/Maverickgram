#!/usr/bin/env python
"""Run the real Aqua folder controller methods against isolated view hosts."""
from __future__ import print_function
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))


def read(relative):
    with open(os.path.join(ROOT, relative), 'rb') as handle:
        return handle.read().decode('utf-8')


def method(source, signature, start_at=0):
    start = source.index(signature, start_at)
    body = source.index('{', start)
    # Keep positions while ignoring braces inside comments and literals.
    masked = re.sub(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"',
                    lambda match: ' ' * len(match.group(0)), source)
    depth = 0
    for position in range(body, len(source)):
        if masked[position] == '{':
            depth += 1
        elif masked[position] == '}':
            depth -= 1
            if depth == 0:
                return source[start:position + 1]
    raise AssertionError('Unclosed controller method: ' + signature)


drawer_source = read('Sources/UI/TGStatusWindowController+AquaFolderDrawer.inc')
shell_source = read('Sources/UI/TGStatusWindowController+AquaShell.inc')
signatures = [
    '- (BOOL)aquaUsesExternalFolderDrawer',
    '- (BOOL)aquaFolderListExpanded',
    '- (void)toggleAquaFolders:',
    '- (void)aquaFolderPresentationChanged:',
    '- (void)aquaFolderDrawerPlacementChanged:',
    '- (void)layoutAquaFolderListInFrame:',
]
production = '\n'.join(method(drawer_source, signature) for signature in signatures)
production += '\n' + method(shell_source, '- (void)updateAquaShellVisibility')
if 'prepareToOpen' in method(drawer_source, '- (void)configureAquaFolderDrawer'):
    raise AssertionError('Restoring the saved drawer on startup must not move the parent window')

# This production block runs before layoutAquaShell. It must never resize a
# scroll view currently owned by NSDrawer using the old 46pt Classic geometry.
section = read('Sources/UI/TGStatusWindowController+SectionLayout.inc')
classic_start = section.index('CGFloat drawerFolderButtonHeight = 46.0;')
guard = section.rfind('if (!aqua)', 0, classic_start)
if guard < 0:
    raise AssertionError('Classic folder geometry must be Aqua-gated')
guard_body = method(section, section[guard:section.index('{', guard)].strip(), guard)
if ('CGFloat drawerFolderButtonHeight = 46.0;' not in guard_body or
        '[folderButton setFrame:' not in guard_body or
        '[contentView addSubview:self.drawerFolderScrollView' not in guard_body):
    raise AssertionError('The entire Classic folder geometry/reparenting block must remain Aqua-gated')
if '[self layoutAquaFolderListInFrame:frames.folders]' not in shell_source:
    raise AssertionError('Aqua layout must route shared folder controls through their presentation host')
if '[content addSubview:self.drawerFolderScrollView' in shell_source:
    raise AssertionError('The Aqua shell must not steal the scroll view from its selected host')

harness = r'''
#import <Foundation/Foundation.h>
#include <math.h>
static BOOL Aqua=YES, DrawerPreference=YES;
static NSUInteger checks=0;
static NSString * const TGSectionChats=@"chats";
static NSString * const TGSectionProfile=@"profile";
static BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
static BOOL TGAquaFoldersUseDrawer(void) { return DrawerPreference; }
static void Check(BOOL condition,const char *text) {
    checks++; if(!condition) { fprintf(stderr,"Aqua folder routing: %s\n",text); exit(1); }
}
enum { NSWindowAbove=1 };
@interface ProbeDefaults : NSObject { NSMutableDictionary *_values; }
+ (id)standardUserDefaults;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
@end
@implementation ProbeDefaults
+ (id)standardUserDefaults { static ProbeDefaults *defaults=nil; if(!defaults) defaults=[[self alloc] init]; return defaults; }
- (id)init { self=[super init]; if(self) _values=[[NSMutableDictionary alloc] init]; return self; }
- (void)setBool:(BOOL)value forKey:(NSString *)key { [_values setObject:[NSNumber numberWithBool:value] forKey:key]; }
- (id)objectForKey:(NSString *)key { return [_values objectForKey:key]; }
- (void)dealloc { [_values release]; [super dealloc]; }
@end
@interface ProbeView : NSObject {
    BOOL _hidden;
    NSRect _frame, _bounds;
    ProbeView *_superview, *_contentView;
    NSMutableArray *_children;
    id _target;
    SEL _action;
    NSInteger _tag;
}
@property(nonatomic,assign) BOOL hidden;
@property(nonatomic,assign) NSRect frame;
@property(nonatomic,assign) NSRect bounds;
@property(nonatomic,assign) ProbeView *superview;
@property(nonatomic,retain) ProbeView *contentView;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL action;
@property(nonatomic,assign) NSInteger tag;
- (void)addSubview:(ProbeView *)view positioned:(NSInteger)position relativeTo:(id)relative;
- (void)removeFromSuperview;
- (void)setBoundsOrigin:(NSPoint)origin;
- (void)reflectScrolledClipView:(ProbeView *)clip;
@end
@implementation ProbeView
@synthesize hidden=_hidden, frame=_frame, bounds=_bounds, superview=_superview, contentView=_contentView, target=_target, action=_action, tag=_tag;
- (id)init { self=[super init]; if(self) _children=[[NSMutableArray alloc] init]; return self; }
- (void)dealloc { [_contentView release]; [_children release]; [super dealloc]; }
- (void)setFrame:(NSRect)frame { _frame=frame; _bounds.size=frame.size; if(_contentView) { NSRect bounds=[_contentView bounds]; bounds.size=frame.size; [_contentView setBounds:bounds]; } }
- (void)addSubview:(ProbeView *)view positioned:(NSInteger)position relativeTo:(id)relative { (void)position; (void)relative; [view retain]; [view removeFromSuperview]; [_children addObject:view]; [view setSuperview:self]; [view release]; }
- (void)removeFromSuperview { if(_superview) [_superview->_children removeObjectIdenticalTo:self]; _superview=nil; }
- (void)setBoundsOrigin:(NSPoint)origin { _bounds.origin=origin; }
- (void)reflectScrolledClipView:(ProbeView *)clip { (void)clip; }
@end
@interface ProbeDrawer : NSObject {
    BOOL _canShowExternally, _visible;
    ProbeView *_scroll, *_host;
    NSArray *_buttons;
    NSUInteger _layoutCount;
    NSUInteger _prepareCount;
    BOOL _requestedOpenAtPreparation;
    id _preparationObserver;
}
@property(nonatomic,assign) BOOL canShowExternally;
@property(nonatomic,assign) BOOL visible;
@property(nonatomic,readonly) ProbeView *host;
@property(nonatomic,readonly) NSArray *buttons;
@property(nonatomic,readonly) NSUInteger layoutCount;
@property(nonatomic,readonly) NSUInteger prepareCount;
@property(nonatomic,readonly) BOOL requestedOpenAtPreparation;
@property(nonatomic,assign) id preparationObserver;
- (id)initWithScroll:(ProbeView *)scroll;
- (void)setFolderButtons:(NSArray *)buttons;
- (void)layout;
- (void)attachFolderScrollView;
- (void)detachFolderScrollView;
- (void)prepareToOpen;
@end
@implementation ProbeDrawer
@synthesize canShowExternally=_canShowExternally, visible=_visible;
@synthesize preparationObserver=_preparationObserver;
- (id)initWithScroll:(ProbeView *)scroll { self=[super init]; if(self) { _scroll=[scroll retain]; _host=[[ProbeView alloc] init]; } return self; }
- (void)dealloc { [_scroll release]; [_host release]; [_buttons release]; [super dealloc]; }
- (ProbeView *)host { return _host; }
- (NSArray *)buttons { return _buttons; }
- (NSUInteger)layoutCount { return _layoutCount; }
- (NSUInteger)prepareCount { return _prepareCount; }
- (BOOL)requestedOpenAtPreparation { return _requestedOpenAtPreparation; }
- (void)prepareToOpen {
    _prepareCount++;
    _requestedOpenAtPreparation=[[_preparationObserver valueForKey:@"aquaFolderDrawerRequestedOpen"] boolValue];
    [[_preparationObserver valueForKey:@"events"] addObject:@"prepare"];
}
- (void)setFolderButtons:(NSArray *)buttons { [buttons retain]; [_buttons release]; _buttons=buttons; }
- (void)layout { _layoutCount++; }
- (void)attachFolderScrollView { [_host addSubview:_scroll positioned:NSWindowAbove relativeTo:nil]; }
- (void)detachFolderScrollView { self.visible=NO; if([_scroll superview]==_host) [_scroll removeFromSuperview]; }
@end
#define NSView ProbeView
#define NSClipView ProbeView
#define NSButton ProbeView
#define NSUserDefaults ProbeDefaults
@interface RoutingProbe : NSObject {
    NSString *_activeSection, *_currentAuthState;
    ProbeDrawer *_aquaFolderDrawer;
    BOOL _aquaFolderDrawerRequestedOpen, _aquaFoldersCollapsed, _chatNavigationClosed, _mediaCenterVisible;
    BOOL _infoReplacesConversation;
    NSArray *_drawerFolderButtons, *_navigationButtons;
    NSMutableDictionary *_views;
    NSMutableArray *_events;
    ProbeView *_window;
    NSInteger _lastFolderTag;
}
@property(nonatomic,copy) NSString *activeSection;
@property(nonatomic,copy) NSString *currentAuthState;
@property(nonatomic,retain) ProbeDrawer *aquaFolderDrawer;
@property(nonatomic,assign) BOOL aquaFolderDrawerRequestedOpen;
@property(nonatomic,assign) BOOL aquaFoldersCollapsed;
@property(nonatomic,assign) BOOL chatNavigationClosed;
@property(nonatomic,assign) BOOL mediaCenterVisible;
@property(nonatomic,assign) BOOL infoReplacesConversation;
@property(nonatomic,retain) NSArray *drawerFolderButtons;
@property(nonatomic,retain) NSArray *navigationButtons;
@property(nonatomic,readonly) NSMutableArray *events;
@property(nonatomic,readonly) NSInteger lastFolderTag;
- (ProbeView *)window;
- (void)layoutContentView;
- (void)updateVisibleSection;
- (void)refreshInterfaceDesignControls;
- (void)folderFilterChanged:(id)sender;
- (BOOL)aquaChatInfoReplacesConversation;
__VIEW_DECLARATIONS__
@end
@implementation RoutingProbe
@synthesize activeSection=_activeSection,currentAuthState=_currentAuthState,aquaFolderDrawer=_aquaFolderDrawer;
@synthesize aquaFolderDrawerRequestedOpen=_aquaFolderDrawerRequestedOpen,aquaFoldersCollapsed=_aquaFoldersCollapsed,chatNavigationClosed=_chatNavigationClosed,mediaCenterVisible=_mediaCenterVisible;
@synthesize drawerFolderButtons=_drawerFolderButtons,navigationButtons=_navigationButtons;
@synthesize infoReplacesConversation=_infoReplacesConversation;
- (id)init {
    self=[super init]; if(!self) return nil;
    _views=[[NSMutableDictionary alloc] init]; _events=[[NSMutableArray alloc] init];
    _window=[[ProbeView alloc] init]; _window.contentView=[[[ProbeView alloc] init] autorelease];
    self.drawerFolderScrollView.contentView=[[[ProbeView alloc] init] autorelease];
    self.aquaFolderDrawer=[[[ProbeDrawer alloc] initWithScroll:self.drawerFolderScrollView] autorelease];
    self.aquaFolderDrawer.preparationObserver=self;
    self.currentAuthState=@"ready"; self.activeSection=@"chats";
    NSMutableArray *buttons=[NSMutableArray array];
    NSInteger tags[]={-1,-2,3,17};
    for(NSUInteger i=0;i<4;i++) { ProbeView *button=[[[ProbeView alloc] init] autorelease]; button.tag=tags[i]; button.target=self; button.action=@selector(folderFilterChanged:); [buttons addObject:button]; }
    self.drawerFolderButtons=buttons;
    self.navigationButtons=[NSArray arrayWithObjects:[[[ProbeView alloc] init] autorelease],[[[ProbeView alloc] init] autorelease],nil];
    return self;
}
- (void)dealloc { [_activeSection release]; [_currentAuthState release]; [_aquaFolderDrawer release]; [_drawerFolderButtons release]; [_navigationButtons release]; [_views release]; [_events release]; [_window release]; [super dealloc]; }
- (ProbeView *)viewForName:(NSString *)name { ProbeView *view=[_views objectForKey:name]; if(!view) { view=[[[ProbeView alloc] init] autorelease]; [_views setObject:view forKey:name]; } return view; }
__VIEW_METHODS__
- (ProbeView *)window { return _window; }
- (NSMutableArray *)events { return _events; }
- (NSInteger)lastFolderTag { return _lastFolderTag; }
- (void)layoutContentView { [_events addObject:@"layout"]; }
- (void)updateVisibleSection { [_events addObject:@"visibility"]; }
- (void)refreshInterfaceDesignControls { [_events addObject:@"refresh"]; }
- (void)folderFilterChanged:(id)sender { _lastFolderTag=[sender tag]; }
- (BOOL)aquaChatInfoReplacesConversation { return _infoReplacesConversation; }
- (BOOL)isAquaChatInfoPanelActive { return _infoReplacesConversation; }
__PRODUCTION_METHODS__
@end
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSArray *sections=[NSArray arrayWithObjects:@"chats",@"settings",@"contacts",@"calls",@"profile",@"workshop",nil];
    NSUInteger cases=0;
    for(NSUInteger mode=0;mode<2;mode++) for(NSUInteger preference=0;preference<2;preference++) for(NSUInteger edge=0;edge<2;edge++) for(NSUInteger opened=0;opened<2;opened++) for(NSUInteger collapsed=0;collapsed<2;collapsed++) {
        Aqua=mode; DrawerPreference=preference;
        RoutingProbe *probe=[[[RoutingProbe alloc] init] autorelease];
        probe.aquaFolderDrawer.canShowExternally=edge;
        probe.aquaFolderDrawerRequestedOpen=opened; probe.aquaFoldersCollapsed=collapsed;
        Check([probe aquaUsesExternalFolderDrawer]==(mode && preference && edge),"external mode requires Aqua, drawer preference and usable screen edge");
        Check([probe aquaFolderListExpanded]==(preference ? opened : !collapsed),"drawer and inline expansion states stay independent, including no-edge fallback");
        NSArray *identity=[[probe.drawerFolderButtons copy] autorelease];
        [[ProbeDefaults standardUserDefaults] setBool:opened forKey:@"TGAquaFolderDrawerOpen"];
        [[ProbeDefaults standardUserDefaults] setBool:collapsed forKey:@"TGAquaFoldersCollapsed"];
        [probe toggleAquaFolders:nil];
        BOOL explicitOpening=mode && preference && !opened;
        Check(probe.aquaFolderDrawer.prepareCount==(explicitOpening ? 1U : 0U),"only an explicit closed-to-open Aqua drawer toggle requests accommodation once");
        if(explicitOpening) Check(!probe.aquaFolderDrawer.requestedOpenAtPreparation,"opening preparation happens before requested-open changes to true");
        Check(probe.aquaFolderDrawerRequestedOpen==(mode && preference ? !opened : opened),"toggle only changes external requested-open preference in drawer mode");
        Check(probe.aquaFoldersCollapsed==(mode && !preference ? !collapsed : collapsed),"toggle preserves the inactive presentation's expansion state");
        Check([[[ProbeDefaults standardUserDefaults] objectForKey:@"TGAquaFolderDrawerOpen"] boolValue]==probe.aquaFolderDrawerRequestedOpen,"requested drawer expansion persists independently");
        Check([[[ProbeDefaults standardUserDefaults] objectForKey:@"TGAquaFoldersCollapsed"] boolValue]==probe.aquaFoldersCollapsed,"inline collapse preference persists independently");
        NSArray *toggleEvents=explicitOpening ? [NSArray arrayWithObjects:@"prepare",@"layout",@"visibility",nil]
            : (mode ? [NSArray arrayWithObjects:@"layout",@"visibility",nil] : [NSArray array]);
        Check([probe.events isEqual:toggleEvents],"explicit opening prepares before layout; closing and Classic/inline toggles never move the parent");
        NSUInteger prepared=probe.aquaFolderDrawer.prepareCount;
        [probe.events removeAllObjects];
        probe.aquaFolderDrawer.visible=YES;
        [probe aquaFolderPresentationChanged:nil];
        Check([probe.events isEqual:(mode ? [NSArray arrayWithObjects:@"refresh",@"layout",@"visibility",nil] : [NSArray array])],"mode switch refreshes presentation and geometry once, Classic remains unchanged");
        Check(probe.aquaFolderDrawer.visible==!mode,"mode switch closes an old external drawer before reparenting");
        Check(probe.aquaFolderDrawer.prepareCount==prepared,"changing presentation in Settings never accommodates or moves the parent window");
        [probe.events removeAllObjects]; [probe aquaFolderDrawerPlacementChanged:nil];
        Check([probe.events isEqual:(mode ? [NSArray arrayWithObjects:@"layout",@"visibility",nil] : [NSArray array])],"edge availability changes relayout Aqua without changing Classic");
        Check(probe.aquaFolderDrawer.prepareCount==prepared,"passive edge availability notification never moves the parent window");
        if(mode) {
            NSRect inlineFrame=NSMakeRect(0,200,292,96);
            [probe layoutAquaFolderListInFrame:inlineFrame];
            Check(probe.drawerFolderButtons==identity || [probe.drawerFolderButtons isEqual:identity],"host switching preserves every existing folder button");
            Check([probe.aquaFolderDrawer.buttons isEqual:identity],"drawer receives the same All, Archive and custom controls");
            Check(probe.drawerFolderScrollView.superview==(preference && edge ? probe.aquaFolderDrawer.host : [[probe window] contentView]),"scroll view belongs exclusively to drawer or inline main view");
            if(!(preference && edge)) {
                Check(NSEqualRects(probe.drawerFolderScrollView.frame,inlineFrame),"no-edge fallback restores the inline scroll frame");
                Check(NSHeight(probe.drawerFolderContentView.frame)==128,"inline document fits all four existing folders");
            }
            for(NSUInteger step=0;step<3;step++) {
                probe.aquaFolderDrawer.canShowExternally=step==1;
                [probe.drawerFolderScrollView.contentView setBoundsOrigin:NSMakePoint(200,10000)];
                [probe layoutAquaFolderListInFrame:inlineFrame];
                BOOL externalNow=preference && step==1;
                Check(probe.drawerFolderScrollView.superview==(externalNow ? probe.aquaFolderDrawer.host : [[probe window] contentView]),"screen-edge loss and restoration move the same live scroll view between exclusive hosts");
                if(!externalNow) {
                    Check(NSEqualPoints([probe.drawerFolderScrollView.contentView bounds].origin,NSMakePoint(0,32)),"inline fallback clamps stale drawer scroll position to the actual document range");
                    [probe.drawerFolderScrollView.contentView setBoundsOrigin:NSMakePoint(-10,-100)];
                    [probe layoutAquaFolderListInFrame:inlineFrame];
                    Check(NSEqualPoints([probe.drawerFolderScrollView.contentView bounds].origin,NSZeroPoint),"inline fallback clamps negative scroll offsets");
                }
            }
            probe.aquaFolderDrawer.canShowExternally=edge;
            Check(probe.aquaFolderDrawer.prepareCount==prepared,"layout and fallback host transfers never request accommodation");
            for(NSUInteger i=0;i<[identity count];i++) {
                ProbeView *button=[identity objectAtIndex:i];
                Check(button.target==probe && button.action==@selector(folderFilterChanged:),"moving folders preserves their original action routing");
                [button.target performSelector:button.action withObject:button];
                Check(probe.lastFolderTag==button.tag,"All, Archive and custom folders keep their original IDs after moving");
            }
        }
        for(NSUInteger auth=0;auth<2;auth++) for(NSString *section in sections) for(NSUInteger empty=0;empty<2;empty++)
        for(NSUInteger info=0;info<2;info++) for(NSUInteger closed=0;closed<2;closed++) for(NSUInteger media=0;media<2;media++) {
            probe.currentAuthState=auth ? @"ready" : @"waitCode"; probe.activeSection=section;
            probe.infoReplacesConversation=info;probe.chatNavigationClosed=closed;probe.mediaCenterVisible=media;
            probe.drawerFolderButtons=empty ? [NSArray array] : identity;
            BOOL expanded=preference ? probe.aquaFolderDrawerRequestedOpen : !probe.aquaFoldersCollapsed;
            BOOL chats=auth && [section isEqual:@"chats"], external=mode && preference && edge;
            probe.aquaFolderDrawer.visible=YES;
            probe.drawerFolderScrollView.hidden=NO;
            probe.aquaFooterView.hidden=NO;
            [probe updateAquaShellVisibility];
            Check(probe.aquaFolderDrawer.prepareCount==prepared,"passive auth/section visibility updates never request accommodation");
            if(mode) {
                Check(probe.aquaFolderDrawer.visible==(chats && external && expanded && !empty),"external drawer cannot remain open in settings, other sections, auth or empty-folder state");
                Check(probe.drawerFolderScrollView.hidden==(!chats || !expanded || empty),"shared folders visibility follows auth, section and expansion");
                Check(probe.aquaFolderEditButton.hidden==(!chats || external),"main Edit control only appears for inline folders");
                Check(probe.aquaFolderDivider.hidden==(!chats || external || !expanded || empty),"external drawer never leaves a duplicate inline splitter");
                Check(probe.aquaFolderHeaderButton.hidden==!chats,"folder toggle only appears in authorized chat section");
                Check(probe.aquaFooterView.hidden==(!chats || closed || media || info),"composer footer hides for replacing profile, closed conversation, media and non-chat/auth state without changing folders");
            } else Check(probe.aquaFolderDrawer.visible && !probe.drawerFolderScrollView.hidden && !probe.aquaFooterView.hidden,"Aqua visibility routine does not mutate Classic folder/footer views");
            cases++;
        }
    }
    printf("Aqua folder production routing passed: %lu cases, %lu assertions; mode, edge fallback, auth, sections, shared-control routes and replacing-profile/media/closed-chat footer isolation.\n",(unsigned long)cases,(unsigned long)checks);
    [pool drain]; return 0;
}
'''

view_names = re.findall(r'self\.(\w+)', production)
non_views = set(['currentAuthState', 'activeSection', 'aquaFolderDrawer',
                 'aquaFolderDrawerRequestedOpen', 'aquaFoldersCollapsed',
                 'chatNavigationClosed', 'mediaCenterVisible',
                 'navigationButtons', 'drawerFolderButtons'])
views = sorted(set(view_names) - non_views)
harness = harness.replace('__VIEW_DECLARATIONS__', '\n'.join(
    '@property(nonatomic,readonly) ProbeView *%s;' % name for name in views))
harness = harness.replace('__VIEW_METHODS__', '\n'.join(
    '- (ProbeView *)%s { return [self viewForName:@"%s"]; }' % (name, name) for name in views))
harness = harness.replace('__PRODUCTION_METHODS__', production)
folder = tempfile.mkdtemp(prefix='telegraphica-aqua-folder-routing-')
try:
    source = os.path.join(folder, 'folder-routing.m')
    binary = os.path.join(folder, 'folder-routing')
    with open(source, 'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:] + [source, '-framework', 'Foundation', '-o', binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
