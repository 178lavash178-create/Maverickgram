#!/usr/bin/env python
"""Exercise production search-panel and contact footer geometry without TDLib."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as handle:
        return handle.read().decode('utf-8')
contacts=read('Sources/UI/TGContactsViewController.m')
start=contacts.index('- (void)layoutContent {')
layout=contacts[start:contacts.index('\n- (void)setView:',start)]
cells=read('Sources/UI/TGStatusViewCells.m')
start=cells.index('@implementation TGRepresentedObjectCell\n')
cell=cells[start:cells.index('\n@end',start)+len('\n@end')]
properties=['titleField','createChatButton','refreshButton','searchField','profileView','listCardView','scrollView','tableView','statusField','spinner','openButton','actionButton']
types=['NSTextField','NSButton','NSButton','NSSearchField','NSView','NSView','NSScrollView','NSTableView','NSTextField','NSProgressIndicator','NSButton','NSButton']
interface='@interface ContactLayoutProbe : NSViewController\n'+''.join('@property(nonatomic,retain) %s *%s;\n'%(t,p) for t,p in zip(types,properties))+'@end\n@implementation ContactLayoutProbe\n'+''.join('@synthesize %s=_%s;\n'%(p,p) for p in properties)+layout+'\n@end\n'
harness=r'''
#import <Cocoa/Cocoa.h>
#import "TGStatusViewCells.h"
#import "TGSearchResultItem.h"
#import "TGLocalization.h"
#import "TGTheme.h"
#import "TGIconAssets.h"
#import "TGMessageLayoutSupport.h"
#import "TGInterfaceDesign.h"
#include <stdlib.h>
void TGDrawAvatarInRect(NSString *p,NSString *t,NSRect r,BOOL s,BOOL f) {(void)p;(void)t;(void)r;(void)s;(void)f;}
static void Require(BOOL value,const char *message) {if(!value){fprintf(stderr,"Auxiliary layout: %s\n",message);exit(1);}}
__CELL__
__SEARCH__
__CONTACT__
@interface SearchTarget : NSObject { @public NSUInteger changed,commits,closes; }
@end
@implementation SearchTarget
- (void)changed:(id)sender {(void)sender;changed++;}
- (void)commit:(id)sender {(void)sender;commits++;}
- (void)close:(id)sender {(void)sender;closes++;}
@end
int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    [NSApplication sharedApplication];
    TGChatSearchPanelView *panel=[[[TGChatSearchPanelView alloc] initWithFrame:NSMakeRect(0,0,420,460)] autorelease];
    SearchTarget *target=[[[SearchTarget alloc] init] autorelease];panel.target=target;panel.queryChangedAction=@selector(changed:);panel.commitAction=@selector(commit:);panel.closeAction=@selector(close:);
    NSMutableArray *results=[NSMutableArray array];
    for(NSUInteger i=0;i<50;i++) {TGSearchResultItem *item=[[[TGSearchResultItem alloc] init] autorelease];item.chatTitle=@"Synthetic search result";[results addObject:item];}
    panel.results=results;
    NSScrollView *scroll=[panel valueForKey:@"scrollView"];
    [[scroll contentView] scrollToPoint:NSMakePoint(0,280)];[scroll reflectScrolledClipView:[scroll contentView]];
    [panel setFrameSize:NSMakeSize(520,500)];
    Require(fabs([[scroll contentView] bounds].origin.y-280)<1,"resizing keeps the current search position");
    panel.results=[NSArray arrayWithObject:[results objectAtIndex:0]];
    Require([[scroll contentView] bounds].origin.y==0,"a new query starts at its first result");
    panel.query=@"query";[panel controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:[panel searchField]]];Require(target->changed==1,"typing still routes query changes");
    panel.query=@"";[panel searchFieldAction:nil];Require(target->changed==2,"native cancel routes cleared query");
    panel.selectedIndex=0;[panel commitSearch:nil];Require(target->commits==1,"search result still commits");[panel closeSearch:nil];Require(target->closes==1,"close still routes to owner");
    NSUInteger layouts=0;
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language);
        for(NSNumber *width in [NSArray arrayWithObjects:@320,@420,@620,nil]) {
            [panel setFrameSize:NSMakeSize([width doubleValue],460)];
            for(NSString *key in [NSArray arrayWithObjects:@"titleField",@"searchField",@"statusField",@"scrollView",nil])
                Require(NSContainsRect([panel bounds],[[panel valueForKey:key] frame]),"search controls fit narrow window");
            if(aqua) Require([[panel searchField] isBezeled] && [[[panel searchField] cell] searchButtonCell]!=nil && [[[panel searchField] cell] cancelButtonCell]!=nil,"Aqua uses native search and clear affordances");
            layouts++;
        }
        for(NSNumber *width in [NSArray arrayWithObjects:@420,@719,@720,@980,nil]) {
            ContactLayoutProbe *c=[[[ContactLayoutProbe alloc] init] autorelease];[c setView:[[[NSView alloc] initWithFrame:NSMakeRect(0,0,[width doubleValue],560)] autorelease]];
            c.titleField=[[[NSTextField alloc] init] autorelease];c.createChatButton=[[[NSButton alloc] init] autorelease];c.refreshButton=[[[NSButton alloc] init] autorelease];c.searchField=[[[NSSearchField alloc] init] autorelease];c.profileView=[[[NSView alloc] init] autorelease];c.listCardView=[[[NSView alloc] init] autorelease];c.scrollView=[[[NSScrollView alloc] init] autorelease];c.tableView=[[[NSTableView alloc] init] autorelease];c.statusField=[[[NSTextField alloc] init] autorelease];c.spinner=[[[NSProgressIndicator alloc] init] autorelease];c.openButton=[[[NSButton alloc] init] autorelease];c.actionButton=[[[NSButton alloc] init] autorelease];[c.openButton setTitle:TGLoc(@"contacts.open")];[c.actionButton setTitle:TGLoc(@"contacts.actions")];[c layoutContent];
            Require(NSContainsRect([[c view] bounds],[c.openButton frame]) && NSContainsRect([[c view] bounds],[c.actionButton frame]) && !NSIntersectsRect([c.openButton frame],[c.actionButton frame]),"contact actions fit and do not overlap");
            NSButton *buttons[]={c.openButton,c.actionButton};for(NSUInteger i=0;i<2;i++) {
                CGFloat text=[[buttons[i] title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:i==0?13:12] forKey:NSFontAttributeName]].width;
                Require(NSWidth([buttons[i] frame])>=ceil(text)+(i==0?32:28),"localized contact action fits its actual font");
            }
            layouts++;
        }
    }
    printf("Auxiliary %s: %lu localized narrow/wide production layouts; search scroll/cancel/commit/close routes PASS.\n",aqua?"Aqua":"Classic",(unsigned long)layouts);
    [pool drain];return 0;
}
'''.replace('__CELL__',cell).replace('__SEARCH__',read('Sources/UI/TGChatSearchPanelView.inc')).replace('__CONTACT__',interface)
folder=tempfile.mkdtemp(prefix='telegraphica-auxiliary-layout-')
try:
    source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(source,'wb') as handle:handle.write(harness.encode('utf-8'))
    deps=['Sources/Core/TGSearchResultItem.m','Sources/UI/TGIconAssets.m','Sources/UI/TGLocalization.m','Sources/UI/TGTheme.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGDialogPresentation.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGVisualWorldThemeSpec.m']
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Core'),source]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary])
    subprocess.check_call([binary,'aqua']);subprocess.check_call([binary,'classic'])
finally:
    shutil.rmtree(folder)
