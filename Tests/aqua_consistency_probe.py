#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real session presentation/layout methods and native control resources, no account operations."""
from __future__ import print_function, unicode_literals
import os,sys,subprocess,tempfile,shutil
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
source=r'''
#import <Cocoa/Cocoa.h>
#import "TGDialogPresentation.h"
#import "TGAquaAppearance.h"
#import "TGStatusButtonCells.h"
#import "TGThemeTextField.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
#import "TGIconAssets.h"
@interface SessionFixture:NSObject
@property(nonatomic,retain) NSWindow *activeSessionsWindow;
@property(nonatomic,retain) NSTextField *activeSessionsStatusField;
@property(nonatomic,retain) NSTableView *activeSessionsTableView;
@property(nonatomic,retain) NSPopUpButton *activeSessionsTerminatePopup;
@property(nonatomic,retain) NSButton *activeSessionsTerminateButton,*activeSessionsRefreshButton,*activeSessionsCloseButton;
@end
@implementation SessionFixture
@synthesize activeSessionsWindow,activeSessionsStatusField,activeSessionsTableView,activeSessionsTerminatePopup,activeSessionsTerminateButton,activeSessionsRefreshButton,activeSessionsCloseButton;
- (NSTextField *)utilityLabelWithFrame:(NSRect)r text:(NSString *)s font:(NSFont *)f {TGThemeTextField *v=[[[TGThemeTextField alloc] initWithFrame:r] autorelease];[v setStringValue:s];[v setFont:f];[v setDetailInk:([f pointSize]<13)];[v setEditable:NO];[v setSelectable:NO];[v setBezeled:NO];[v setDrawsBackground:NO];return v;}
- (void)reloadActiveSessions:(id)sender{(void)sender;}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)t{(void)t;return 0;}
- (id)tableView:(NSTableView *)t objectValueForTableColumn:(NSTableColumn *)c row:(NSInteger)r{(void)t;(void)c;(void)r;return @"";}
#include "TGStatusWindowController+AquaSessions.inc"
- (void)dealloc{[activeSessionsWindow release];[activeSessionsStatusField release];[activeSessionsTableView release];[activeSessionsTerminatePopup release];[activeSessionsTerminateButton release];[activeSessionsRefreshButton release];[activeSessionsCloseButton release];[super dealloc];}
@end
// macOS 11+ defaults to Automatic/FullWidth table styling with 16 pt of
// native row padding on each side, independent of intercellSpacing. The
// supported 10.8–10.13 cell-based tables have no such padding. Select Plain
// only in the modern diagnostic fixture so its geometry models those systems;
// keep the exact document/viewport-width assertion below unchanged.
static void MatchLegacyTableStyle(NSTableView *table) {
    SEL selector=NSSelectorFromString(@"setStyle:");
    if (![table respondsToSelector:selector]) return;
    NSInvocation *call=[NSInvocation invocationWithMethodSignature:[table methodSignatureForSelector:selector]];
    [call setTarget:table]; [call setSelector:selector];
    NSInteger plainStyle=4; // NSTableViewStylePlain, introduced in macOS 11.
    [call setArgument:&plainStyle atIndex:2]; [call invoke];
}
static NSUInteger checks;
static void Require(BOOL ok,const char *m){checks++;if(!ok){fprintf(stderr,"Aqua consistency: %s\n",m);exit(1);}}
static void Contains(NSRect a,NSRect b){Require(NSContainsRect(a,b),"control contained in native session surface");}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];[[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:@"aqua" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
for(NSString *lang in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){TGSetLanguageCode(lang);
SessionFixture *f=[[[SessionFixture alloc] init] autorelease];f.activeSessionsWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,620,480) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[f.activeSessionsWindow setReleasedWhenClosed:NO];
NSView *old=[f.activeSessionsWindow contentView];f.activeSessionsStatusField=[f utilityLabelWithFrame:NSZeroRect text:@"" font:[NSFont systemFontOfSize:12]];[old addSubview:f.activeSessionsStatusField];
f.activeSessionsTableView=[[[NSTableView alloc] initWithFrame:NSMakeRect(0,0,560,300)] autorelease];[f.activeSessionsTableView setHeaderView:nil];MatchLegacyTableStyle(f.activeSessionsTableView);[f.activeSessionsTableView setDelegate:(id)f];[f.activeSessionsTableView setDataSource:(id)f];[f.activeSessionsTableView setRowHeight:58];[f.activeSessionsTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];[f.activeSessionsTableView setFocusRingType:NSFocusRingTypeNone];[f.activeSessionsTableView setGridStyleMask:NSTableViewGridNone];[f.activeSessionsTableView addTableColumn:[[[NSTableColumn alloc] initWithIdentifier:@"session"] autorelease]];
NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSMakeRect(30,112,560,300)] autorelease];[scroll setDocumentView:f.activeSessionsTableView];[old addSubview:scroll];
f.activeSessionsTerminatePopup=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];[f.activeSessionsTerminatePopup addItemWithTitle:@"Synthetic session"];
f.activeSessionsTerminateButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[f.activeSessionsTerminateButton setTitle:TGLoc(@"settings.sessions.terminate")];
// Match the production destructive settings action, without performing it.
[f.activeSessionsTerminateButton setButtonType:NSMomentaryPushInButton];[f.activeSessionsTerminateButton setBezelStyle:NSRegularSquareBezelStyle];[f.activeSessionsTerminateButton setBordered:NO];[f.activeSessionsTerminateButton setImagePosition:NSImageLeft];[f.activeSessionsTerminateButton setFont:[NSFont systemFontOfSize:14]];
[[f.activeSessionsTerminateButton cell] setAlignment:NSLeftTextAlignment];
NSColor *destructive=[NSColor colorWithCalibratedRed:0.920 green:0.140 blue:0.140 alpha:1];
[f.activeSessionsTerminateButton setImage:TGTemplateIconAssetImage(@"running",NSMakeSize(16,16),destructive,1)];
[f.activeSessionsTerminateButton setAttributedTitle:[[[NSAttributedString alloc] initWithString:TGLoc(@"settings.sessions.terminate") attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14],NSFontAttributeName,destructive,NSForegroundColorAttributeName,nil]] autorelease]];
f.activeSessionsRefreshButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[f.activeSessionsRefreshButton setTarget:f];[f.activeSessionsRefreshButton setAction:@selector(reloadActiveSessions:)];
f.activeSessionsCloseButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[f.activeSessionsCloseButton setTitle:TGLoc(@"close")];[f.activeSessionsCloseButton setButtonType:NSMomentaryPushInButton];[f.activeSessionsCloseButton setBezelStyle:NSRoundedBezelStyle];[f.activeSessionsCloseButton setBordered:YES];[f.activeSessionsCloseButton setFont:[NSFont systemFontOfSize:12]];
[f configureAquaActiveSessionsWindow];[f setActiveSessionsStatusText:@"Synthetic long error that must remain entirely available, including additional diagnostic context in the tooltip."];
Require([[f.activeSessionsStatusField toolTip] isEqual:[f.activeSessionsStatusField stringValue]],"long error available in full tooltip");
Require([f.activeSessionsRefreshButton target]==f&&[f.activeSessionsRefreshButton action]==@selector(reloadActiveSessions:),"refresh action preserved after cell replacement");
for(NSNumber *width in [NSArray arrayWithObjects:@500,@620,@980,@500,nil])for(NSNumber *height in [NSArray arrayWithObjects:@338,@480,@720,@338,nil]){
[f.activeSessionsWindow setContentSize:NSMakeSize([width doubleValue],[height doubleValue])];[f layoutAquaActiveSessionsWindow];NSView *root=TGUtilityWindowContentView(f.activeSessionsWindow);
Require([root isKindOfClass:[TGAquaUtilityWindowView class]],"shared Aqua rail component");
NSMutableArray *controls=[NSMutableArray array];for(NSView *v in [root subviews]){Contains([root bounds],[v frame]);[controls addObject:v];}
for(NSUInteger i=0;i<[controls count];i++)for(NSUInteger j=i+1;j<[controls count];j++)Require(!NSIntersectsRect([[controls objectAtIndex:i] frame],[[controls objectAtIndex:j] frame]),"session controls never overlap");
if(NSWidth([f.activeSessionsTableView frame])!=NSWidth([[scroll contentView] bounds]))fprintf(stderr,"width actual=%g clip=%g root=%g column=%g\n",NSWidth([f.activeSessionsTableView frame]),NSWidth([[scroll contentView] bounds]),NSWidth([root bounds]),[[[f.activeSessionsTableView tableColumns] lastObject] width]);
Require(NSWidth([f.activeSessionsTableView frame])==NSWidth([[scroll contentView] bounds]),"table document follows native viewport width");
CGFloat text=[[f.activeSessionsTerminateButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[f.activeSessionsTerminateButton font] forKey:NSFontAttributeName]].width;
Require(text+20<=NSWidth([f.activeSessionsTerminateButton frame]),"localized terminate caption fits");}
if([lang isEqual:@"ru"]&&getenv("TG_CONSISTENCY_PREVIEW_DIR")){[f.activeSessionsWindow setContentSize:NSMakeSize(620,480)];[f layoutAquaActiveSessionsWindow];NSView *v=[f.activeSessionsWindow contentView];
Class appearanceClass=NSClassFromString(@"NSAppearance");
if(appearanceClass&&[f.activeSessionsWindow respondsToSelector:@selector(setAppearance:)]){id appearance=[appearanceClass performSelector:@selector(appearanceNamed:) withObject:@"NSAppearanceNameAqua"];if(appearance)[f.activeSessionsWindow performSelector:@selector(setAppearance:) withObject:appearance];}
NSBitmapImageRep *b=[v bitmapImageRepForCachingDisplayInRect:[v bounds]];[v cacheDisplayInRect:[v bounds] toBitmapImageRep:b];[[b representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[[NSString stringWithUTF8String:getenv("TG_CONSISTENCY_PREVIEW_DIR")] stringByAppendingPathComponent:@"aqua-sessions.png"] atomically:YES];}
[f.activeSessionsWindow close];}
printf("Aqua session consistency PASS: %lu real production presentation/layout/localized native control checks; no account operations.\n",(unsigned long)checks);[pool drain];return 0;}
'''
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-consistency-')
try:
 app=os.path.join(folder,'Probe.app');os.makedirs(os.path.join(app,'Contents','MacOS'));os.makedirs(os.path.join(app,'Contents','Resources'))
 for name in ['Icons','Textures']:shutil.copytree(os.path.join(ROOT,'Sources','Resources',name),os.path.join(app,'Contents','Resources',name))
 path=os.path.join(folder,'probe.m');binary=os.path.join(app,'Contents','MacOS','Probe')
 with open(path,'wb') as f:f.write(source.encode('utf-8'))
 deps=['TGButtonAppearance','TGIconAssets','TGAquaAppearance','TGTheme','TGThemeTextField','TGVisualWorldThemeSpec','TGInterfaceDesign','TGLocalization','TGDialogPresentation','TGStatusButtonCells','TGIconDrawing']
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources',d) for d in ['UI','Core','Services','Media']]+[path]+[os.path.join(ROOT,'Sources/UI',d+'.m') for d in deps]+['-framework','Cocoa','-o',binary])
 subprocess.check_call([binary],env=dict(os.environ,HOME=folder))
finally:shutil.rmtree(folder)
