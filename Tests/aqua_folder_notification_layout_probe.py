#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Execute production utility constructors/layouts and local state, no TDLib calls."""
from __future__ import print_function, unicode_literals
import os,re,shutil,subprocess,sys,tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
 with open(os.path.join(ROOT,path),'rb') as f:return f.read().decode('utf-8')
def group(source,start,end):
 a=source.index(start);return source[a:source.index(end,a)]
def owner(name,path,methods,extra=''):
 source=read(path);interface=group(source,'@interface '+name+' ()','@end')
 props=re.findall(r'@property\s*\([^)]*\)\s*([^;]+);',interface)
 fields=[];decl=[];synth=[];release=[]
 for spec in props:
  m=re.match(r'(.+?)([A-Za-z_]\w*)$',spec.strip());typ,n=m.groups()
  fields.append(typ+'_'+n+';');decl.append('@property(nonatomic,'+('retain' if '*' in typ else 'assign')+') '+typ+n+';')
  synth.append('@synthesize '+n+'=_'+n+';')
  if '*' in typ:release.append('[_'+n+' release];')
 return '@interface '+name+' : NSWindowController <NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate> {'+'\n'.join(fields)+'}\n'+'\n'.join(decl)+'\n@end\n@implementation '+name+'\n'+'\n'.join(synth)+'\n'+extra+'\n'+methods+'\n- (void)dealloc { [self.window setDelegate:nil]; '+''.join(release)+' [super dealloc];}\n@end\n'
folder=read('Sources/UI/TGChatFolderManagementWindowController.m')
notification=read('Sources/UI/TGNotificationSettingsWindowController.m')
base=group(folder,'- (NSTextField *)labelWithFrame:','- (void)buildViews {').split('#include')[0]
# Real builders, state extraction and checkbox serialization; actions are bound but never executed.
fm=base+read('Sources/UI/TGChatFolderManagementWindowController+Aqua.inc')+group(folder,'- (void)updateControlStates {','- (void)reloadFolders {')+group(folder,'- (NSDictionary *)definitionFromControls {','- (BOOL)definitionHasInclusionRule:')
fm+=group(folder,'- (NSInteger)numberOfRowsInTableView:','- (void)tableViewSelectionDidChange:')
fm+='- (void)tableViewSelectionDidChange:(NSNotification *)note {(void)note;}\n'
nm=group(notification,'- (NSTextField *)labelWithFrame:','- (void)buildViews {').split('#include')[0]+read('Sources/UI/TGNotificationSettingsWindowController+Aqua.inc')
nm+=group(notification,'- (NSInteger)numberOfRowsInTableView:','#include "TGNotificationSettingsWindowController+Theme.inc"')
nm+=group(notification,'- (void)updateEditorAvailability {','- (void)reloadExceptions {')
nm+=group(notification,'- (NSTimeInterval)selectedMuteDuration {','- (void)applyPressed:')
nm+='- (void)refreshPreviewTheme:(id)note {(void)note;}\n'
harness=r'''
#import <Cocoa/Cocoa.h>
#import "TGLocalization.h"
#import "TGChatItem.h"
#import "TGStatusViewCells.h"
#import "TGThemeTextField.h"
#import "TGThemeContrast.h"
#import "TGAquaAppearance.h"
#import "TGChatListSelectionAppearance.h"
#include <assert.h>
@class TGChatFolderSharingWindowController;
static NSUInteger Checks,Avatars;
BOOL TGInterfaceDesignIsAqua(void) {return YES;}
NSColor *TGColorFromHex(NSUInteger value){return [NSColor colorWithCalibratedRed:((value>>16)&255)/255.0 green:((value>>8)&255)/255.0 blue:(value&255)/255.0 alpha:1];}
NSColor *TGClassicSelectedRowColor(void){return [NSColor blueColor];}
NSColor *TGClassicSelectedRowTextColor(void){return [NSColor whiteColor];}
NSColor *TGClassicTablePaperColor(void){return [NSColor whiteColor];}
NSColor *TGClassicCardInkColor(void){return [NSColor blackColor];}
NSColor *TGClassicCardMutedInkColor(void){return [NSColor darkGrayColor];}
NSColor *TGClassicHeaderTextColor(CGFloat a){return [[NSColor blackColor] colorWithAlphaComponent:a];}
NSColor *TGThemeReadableInk(NSColor *c,NSColor *s,CGFloat r){(void)s;(void)r;return c;}
NSImage *TGTemplateIconAssetImage(NSString *name,NSSize size,NSColor *color,CGFloat a){(void)name;(void)size;(void)color;(void)a;return nil;}
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *color,CGFloat a,BOOL flipped){(void)name;(void)rect;(void)color;(void)a;(void)flipped;}
void TGDrawAvatarInRect(NSString *path,NSString *title,NSRect rect,BOOL selected,BOOL flipped){(void)path;(void)title;(void)selected;(void)flipped;assert(rect.size.width==28 || rect.size.width==30);Avatars++;}
void TGAquaDrawSurfaceInPath(NSBezierPath *path,NSRect rect,TGThemeSurfaceRole role,BOOL flipped) {(void)path;(void)role;(void)flipped;[[NSColor colorWithCalibratedWhite:.91 alpha:1] set];NSRectFill(rect);}
__UTILITY_WINDOW__
@implementation TGThemeTextField
- (void)setThemeSurface:(TGThemeSurfaceRole)role {(void)role;}
- (void)setDetailInk:(BOOL)value {(void)value;}
- (void)refreshThemeInk {}
@end
@implementation TGThemeSwitchButton @end
@interface TGHeaderIconButtonCell : NSButtonCell @end
@implementation TGHeaderIconButtonCell @end
@interface TGPrimaryTextButtonCell : NSButtonCell @end
@implementation TGPrimaryTextButtonCell @end
@interface TGSecondaryTextButtonCell : NSButtonCell @end
@implementation TGSecondaryTextButtonCell @end
@implementation TGRepresentedObjectCell
@synthesize representedObject=_representedObject;
- (void)setObjectValue:(id)value {self.representedObject=value;}
- (void)dealloc {[_representedObject release];[super dealloc];}
@end
@interface TGTDLibClient : NSObject @end
@implementation TGTDLibClient
- (BOOL)chatFolderAPIKindSupportsSharing:(NSString *)kind {return [kind isEqual:@"chatFolder"];}
@end
static NSString * const TGChatFolderDragPasteboardType=@"synthetic-folder-row";
__CELLS__
__FOLDER__
__NOTIFICATION__
static void Fit(NSView *root) {
 for(NSView *child in [root subviews]) {
  assert(NSContainsRect([root bounds],[child frame]));Checks++;
  if([child isKindOfClass:[NSButton class]]) {
   NSButton *button=(NSButton *)child;
   if([[button title] length]) {
    NSFont *font=[button font] ? [button font]:[NSFont systemFontOfSize:13];
    CGFloat text=[[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
    CGFloat reserve=[button isKindOfClass:[TGThemeSwitchButton class]] ? 18:14;
    if(text+reserve>NSWidth([button frame]))fprintf(stderr,"title %s width%.0f need%.0f\n",[[button title] UTF8String],NSWidth([button frame]),text+reserve);
    assert(text+reserve<=NSWidth([button frame]));Checks++;
   }
  }
 }
}
static void RasterRows(void) {
 NSDictionary *summary=[NSDictionary dictionaryWithObjectsAndKeys:@1,@"chat_id",@"Очень длинное название для проверки строки и обрезки заголовка",@"title",@YES,@"muted",@YES,@"is_shareable",nil];
 TGChatItem *chat=[[[TGChatItem alloc] initWithChatID:@1 title:[summary objectForKey:@"title"] typeSummary:@"Private" unreadCount:@0] autorelease];
 NSArray *cells=[NSArray arrayWithObjects:[[[TGChatFolderListCell alloc] initTextCell:@""] autorelease],[[[TGChatFolderChatCell alloc] initTextCell:@""] autorelease],[[[TGNotificationExceptionCell alloc] initTextCell:@""] autorelease],nil];
 NSView *view=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,240,44)] autorelease];
 for(NSUInteger i=0;i<[cells count];i++)for(NSUInteger selected=0;selected<2;selected++) {
  TGRepresentedObjectCell *cell=[cells objectAtIndex:i];cell.representedObject=i==1 ? (id)chat:(id)summary;[cell setHighlighted:selected];
  NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:240 pixelsHigh:44 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
  [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
  [cell drawInteriorWithFrame:[view bounds] inView:view];[NSGraphicsContext restoreGraphicsState];
  NSUInteger ink=0;for(NSUInteger y=0;y<44;y++)for(NSUInteger x=50;x<230;x++) {
   NSColor *color=[[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
   if(selected ? ([color redComponent]>.95&&[color greenComponent]>.95&&[color blueComponent]>.95):([color redComponent]<.4&&[color greenComponent]<.4&&[color blueComponent]<.4))ink++;
  }
  assert(ink>5);Checks++;
  NSColor *background=[[bitmap colorAtX:2 y:2] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  if(selected)assert([background blueComponent]>.6 && [background redComponent]<.3);else assert([background redComponent]>.95);Checks++;
 }
 assert(Avatars>=4);Checks++;
}
static void Preview(NSWindow *window,NSString *name) {
 const char *folder=getenv("TG_UTILITY_PROBE_PREVIEW_DIR");if(!folder)return;
 NSView *view=[window contentView];NSBitmapImageRep *bitmap=[view bitmapImageRepForCachingDisplayInRect:[view bounds]];[view cacheDisplayInRect:[view bounds] toBitmapImageRep:bitmap];
 NSString *path=[[NSString stringWithUTF8String:folder] stringByAppendingPathComponent:name];[[bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:path atomically:YES];
}
static NSWindow *Window(CGFloat w,CGFloat h) {NSWindow *window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,w,h) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
 Class appearanceClass=NSClassFromString(@"NSAppearance");if(appearanceClass && [window respondsToSelector:@selector(setAppearance:)]){id appearance=[appearanceClass performSelector:@selector(appearanceNamed:) withObject:@"NSAppearanceNameAqua"];if(appearance)[window performSelector:@selector(setAppearance:) withObject:appearance];}return window;}

int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];NSString *original=[TGLanguageCode() copy];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
  TGSetLanguageCode(language);RasterRows();
  TGChatFolderManagementWindowController *f=[[[TGChatFolderManagementWindowController alloc] initWithWindow:Window(780,640)] autorelease];
  f.client=[[[TGTDLibClient alloc] init] autorelease];f.selectedChatIDs=[NSMutableSet setWithObjects:@7,@8,nil];f.folderDefinitions=[NSArray array];f.filteredChatItems=[NSArray array];
  [f buildAquaViews];assert([(TGAquaUtilityWindowView *)[f.window contentView] headerHeight]==52 && [(TGAquaUtilityWindowView *)[f.window contentView] footerHeight]==54);Checks++;
  if([language isEqual:@"ru"]){[f.titleField setStringValue:@"Работа"];f.folderDefinitions=[NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:@"Работа" forKey:@"title"],[NSDictionary dictionaryWithObject:@"Личное" forKey:@"title"],[NSDictionary dictionaryWithObject:@"Проекты" forKey:@"title"],nil];[f.folderTableView reloadData];[f.folderTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];Preview(f.window,@"aqua-folders-layout-adapters.png");}

  NSArray *actions=[NSArray arrayWithObjects:f.importButton,f.addButton,f.deleteButton,f.shareButton,f.refreshButton,f.saveButton,nil];
  SEL expected[]={@selector(importFolder:),@selector(addFolder:),@selector(deleteFolder:),@selector(shareFolder:),@selector(refreshAction:),@selector(saveFolder:)};
  for(NSUInteger i=0;i<[actions count];i++){NSButton *button=[actions objectAtIndex:i];assert([button target]==f && [button action]==expected[i]);Checks++;if(i<5){assert([[button toolTip] length]);Checks++;}}
  NSRect folderMinimum=[NSWindow contentRectForFrameRect:NSMakeRect(0,0,720,600) styleMask:NSTitledWindowMask|NSResizableWindowMask];
  for(NSNumber *width in [NSArray arrayWithObjects:@720,@780,@980,nil])for(NSNumber *height in [NSArray arrayWithObjects:[NSNumber numberWithDouble:NSHeight(folderMinimum)],@640,@738,nil]) {
   [f.window setContentSize:NSMakeSize([width doubleValue],[height doubleValue])];[f layoutAquaViews];Fit([f.window contentView]);
   NSScrollView *left=[f.aquaViews objectForKey:@"folderScroll"],*right=[f.aquaViews objectForKey:@"chatScroll"];
   assert(!NSIntersectsRect([left frame],[right frame]) && NSHeight([right frame])>=170);Checks++;
   assert(NSMaxY([right frame])+8<=NSMinY([f.chatSearchField frame]));Checks++;
   assert(NSWidth([f.chatTableView frame])==NSWidth([[right contentView] bounds]) && NSWidth([f.folderTableView frame])==NSWidth([[left contentView] bounds]));Checks++;
   for(NSView *view in [f.aquaViews allValues])assert(![view isKindOfClass:[NSBox class]]||NSWidth([view frame])==1);
  }
  [f.titleField setStringValue:@"Synthetic"];[f.includeGroupsButton setState:NSOnState];[f.excludeMutedButton setState:NSOnState];
  f.editingDefinition=[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:@7],@"pinned_chat_ids",[NSArray arrayWithObject:@9],@"excluded_chat_ids",nil];
  NSDictionary *definition=[f definitionFromControls];assert([[definition objectForKey:@"include_groups"] boolValue] && [[definition objectForKey:@"exclude_muted"] boolValue] && [[definition objectForKey:@"included_chat_ids"] isEqual:[NSArray arrayWithObject:@8]] && [[definition objectForKey:@"pinned_chat_ids"] isEqual:[NSArray arrayWithObject:@7]] && [[definition objectForKey:@"excluded_chat_ids"] isEqual:[NSArray arrayWithObject:@9]]);Checks++;
  f.loading=YES;[f updateControlStates];assert(![f.saveButton isEnabled] && ![f.folderTableView isEnabled] && ![f.includeGroupsButton isEnabled] && ![f.chatSearchField isEnabled]);Checks++;f.loading=NO;f.editingDefinition=[NSDictionary dictionaryWithObject:@"chatFolder" forKey:@"api_kind"];[f updateControlStates];assert([f.saveButton isEnabled] && [f.shareButton isEnabled]);Checks++;
  TGNotificationSettingsWindowController *n=[[[TGNotificationSettingsWindowController alloc] initWithWindow:Window(660,500)] autorelease];[n buildAquaViews];assert([(TGAquaUtilityWindowView *)[n.window contentView] headerHeight]==52 && [(TGAquaUtilityWindowView *)[n.window contentView] footerHeight]==54);Checks++;
  NSDictionary *a=[NSDictionary dictionaryWithObjectsAndKeys:@1,@"chat_id",@"Альфа Alpha",@"title",@YES,@"muted",@NO,@"show_preview",nil];
  NSDictionary *b=[NSDictionary dictionaryWithObjectsAndKeys:@2,@"chat_id",@"Бета Beta",@"title",@NO,@"muted",@YES,@"show_preview",nil];
  n.exceptions=[NSArray arrayWithObjects:a,b,nil];[n applyAquaSearch];[n.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];[n tableViewSelectionDidChange:nil];assert([[[n selectedSummary] objectForKey:@"chat_id"] isEqual:@2]);Checks++;
  if([language isEqual:@"ru"])Preview(n.window,@"aqua-notifications-layout-adapters.png");
  [n.aquaSearchField setStringValue:@"beta"];[n applyAquaSearch];assert([[n displayedExceptions] count]==1 && [[[n selectedSummary] objectForKey:@"chat_id"] isEqual:@2]);Checks++;
  [n.aquaSearchField setStringValue:@"no match"];[n applyAquaSearch];assert(![n selectedSummary] && ![n.applyButton isEnabled] && [[n displayedExceptions] count]==0);Checks++;
  [n.aquaSearchField setStringValue:@""];[n aquaSearchChanged:nil];assert([[n displayedExceptions] count]==2);Checks++;
  NSRect notificationMinimum=[NSWindow contentRectForFrameRect:NSMakeRect(0,0,600,460) styleMask:NSTitledWindowMask|NSResizableWindowMask];
  for(NSNumber *width in [NSArray arrayWithObjects:@600,@660,@860,nil])for(NSNumber *height in [NSArray arrayWithObjects:[NSNumber numberWithDouble:NSHeight(notificationMinimum)],@500,@658,nil]) {
   [n.window setContentSize:NSMakeSize([width doubleValue],[height doubleValue])];[n layoutAquaViews];Fit([n.window contentView]);
   NSScrollView *scroll=[n.aquaViews objectForKey:@"scroll"];assert(!NSIntersectsRect([scroll frame],[n.selectionField frame]) && NSHeight([scroll frame])>=260);Checks++;
   assert(NSMaxY([n.mutePopUpButton frame])<NSMinY([[n.aquaViews objectForKey:@"muteLabel"] frame]));Checks++;
   assert(NSWidth([n.tableView frame])==NSWidth([[scroll contentView] bounds]));Checks++;
  }
  [n.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];[n tableViewSelectionDidChange:nil];assert([n.applyButton isEnabled] && [n.mutePopUpButton indexOfSelectedItem]==4 && [n.previewButton state]==NSOffState);Checks++;
  [n setLoading:YES status:@"Synthetic error"];assert(![n.applyButton isEnabled] && ![n.aquaSearchField isEnabled] && [[n.statusField toolTip] isEqual:@"Synthetic error"]);Checks++;
  NSMutableArray *many=[NSMutableArray array];for(NSUInteger i=0;i<80;i++)[many addObject:a];n.exceptions=many;[n applyAquaSearch];[n layoutAquaViews];NSScrollView *overflow=[n.aquaViews objectForKey:@"scroll"];
  [n.tableView scrollRowToVisible:79];assert(NSHeight([n.tableView frame])>NSHeight([[overflow contentView] bounds]) && NSMinY([[overflow contentView] bounds])>0);Checks++;
  NSTimeInterval durations[]={0,3600,28800,86400,-1};for(NSInteger i=0;i<5;i++){[n.mutePopUpButton selectItemAtIndex:i];assert([n selectedMuteDuration]==durations[i]);Checks++;}
  SEL na[]={@selector(refreshPressed:),@selector(resetPressed:),@selector(applyPressed:)};NSArray *nb=[NSArray arrayWithObjects:n.refreshButton,n.resetButton,n.applyButton,nil];for(NSUInteger i=0;i<3;i++){assert([[nb objectAtIndex:i] target]==n && [[nb objectAtIndex:i] action]==na[i]);Checks++;}
 }
 TGSetLanguageCode(original);[original release];printf("Aqua folders/notification exceptions: %lu real production constructor/layout/local filter/state/localized typography and selected-row raster checks PASS.\n",(unsigned long)Checks);[pool drain];return 0;
}
'''
appearance=read('Sources/UI/TGAquaAppearance.m');start=appearance.index('@implementation TGAquaUtilityWindowView\n');utility=appearance[start:appearance.index('\n@end',start)+5];harness=harness.replace('__UTILITY_WINDOW__',utility)
harness=harness.replace('__CELLS__',read('Sources/UI/TGChatFolderManagementWindowController+Cells.inc')+read('Sources/UI/TGNotificationSettingsWindowController+AquaCell.inc'))
harness=harness.replace('__FOLDER__',owner('TGChatFolderManagementWindowController','Sources/UI/TGChatFolderManagementWindowController.m',fm))
harness=harness.replace('__NOTIFICATION__',owner('TGNotificationSettingsWindowController','Sources/UI/TGNotificationSettingsWindowController.m',nm))
folder=tempfile.mkdtemp(prefix='telegraphica-folder-notification-')
try:
 source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
 with open(source,'wb') as f:f.write(harness.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Core'),'-Wno-incomplete-implementation','-Wno-objc-method-access',source,os.path.join(ROOT,'Sources/UI/TGLocalization.m'),os.path.join(ROOT,'Sources/Core/TGChatItem.m'),'-framework','Cocoa','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
