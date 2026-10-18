#import <Cocoa/Cocoa.h>
#import "TGChatLifecycleAquaLayout.h"
#import "TGLocalization.h"
#include <assert.h>

/* UI adapters isolate native construction from TDLib. No outgoing action is
 * executed: production actions are checked as target/selector bindings. */
@interface TGUtilityWindowView : NSView @end
@implementation TGUtilityWindowView @end
@interface TGUtilityPanelView : NSView @end
@implementation TGUtilityPanelView @end
@interface TGGroupedCardView : NSView @end
@implementation TGGroupedCardView @end
@interface TGComposerInputBackgroundView : NSView @end
@implementation TGComposerInputBackgroundView @end
@interface TGChatLifecycleContactCell : NSCell @end
@implementation TGChatLifecycleContactCell @end
@interface TGPrimaryTextButtonCell : NSButtonCell @end
@implementation TGPrimaryTextButtonCell @end
@interface TGSecondaryTextButtonCell : NSButtonCell @end
@implementation TGSecondaryTextButtonCell @end
@interface TGHeaderIconButtonCell : NSButtonCell @end
@implementation TGHeaderIconButtonCell @end
@interface TGPointingHandButton : NSButton @end
@implementation TGPointingHandButton @end
static BOOL Aqua=YES;
BOOL TGInterfaceDesignIsAqua(void) {return Aqua;}
typedef NSInteger TGThemeSurfaceRole;
enum {TGThemeSurfaceWindow,TGThemeSurfaceCard};
NSColor *TGClassicHeaderTextColor(CGFloat value) {(void)value;return [NSColor blackColor];}
NSColor *TGClassicInkColor(void) {return [NSColor blackColor];}
NSColor *TGClassicTablePaperColor(void) {return [NSColor whiteColor];}
NSColor *TGThemeSurfaceInkColor(NSColor *color,TGThemeSurfaceRole role,CGFloat contrast) {(void)role;(void)contrast;return color;}
void TGAccessibilityConfigureContent(id element,NSString *value) {(void)element;(void)value;}
void TGAccessibilityConfigureList(id element,NSString *value) {(void)element;(void)value;}
@interface TGMessageItem : NSObject @end
@implementation TGMessageItem @end
static NSString *TGMediaCenterTypeTitleForItem(TGMessageItem *item) {(void)item;return @"Photo";}
static NSString *TGMediaCenterTitleForItem(TGMessageItem *item) {(void)item;return @"photo.jpg";}
static NSString *TGMediaCenterReadableSize(unsigned long long size) {(void)size;return @"2 KB";}
static unsigned long long TGMediaCenterSizeForItem(TGMessageItem *item) {(void)item;return 2048;}
static NSString *TGMediaCenterDateStringForItem(TGMessageItem *item) {(void)item;return @"17.10.2026";}
@interface SurfaceOwner : NSWindowController <NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate> { __FIELDS__ }
__PROPERTIES__
@end
@implementation SurfaceOwner
__SYNTHESIS__
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font {
 NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];[field setStringValue:text];[field setFont:font];[field setBezeled:NO];[field setEditable:NO];return field;
}
- (NSTextField *)labelWithFrame:(NSRect)frame font:(NSFont *)font surface:(TGThemeSurfaceRole)role detail:(BOOL)detail {
 (void)role;(void)detail;return [self labelWithFrame:frame text:@"" font:font];
}
- (void)applyMutedLabelStyle:(id)field {(void)field;}
- (NSButton *)modalCloseButtonWithFrame:(NSRect)frame {return [[[NSButton alloc] initWithFrame:frame] autorelease];}
- (void)applySkeuomorphicButtonStyle:(id)button isPrimary:(BOOL)primary {(void)button;(void)primary;}
- (NSArray *)selectedContacts {return self.selected ? self.selected : [NSArray array];}
- (void)ensureMediaCenterHighQualityThumbnailForItem:(id)item {(void)item;}
- (NSImage *)mediaCenterThumbnailForItem:(id)item {(void)item;return [[[NSImage alloc] initWithSize:NSMakeSize(320,200)] autorelease];}
- (void)addMediaCenterThumbnailSpinnerForItem:(id)item toView:(id)view frame:(NSRect)frame {(void)item;(void)view;(void)frame;}
- (NSMenu *)mediaCenterContextMenuForIndex:(NSUInteger)index {(void)index;return nil;}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table {(void)table;return 0;}
- (void)createChannel:(id)sender {(void)sender;assert(0);}
- (void)createGroup:(id)sender {(void)sender;assert(0);}
- (void)createSecretChat:(id)sender {(void)sender;assert(0);}
- (void)openSelectedContact:(id)sender {(void)sender;assert(0);}
- (void)joinInviteLink:(id)sender {(void)sender;assert(0);}
- (void)previewMediaCenterItem:(id)sender {(void)sender;assert(0);}
__PRODUCTION_METHODS__
- (void)dealloc { [self.window setDelegate:nil];[self.tableView setDataSource:nil];[self.tableView setDelegate:nil];[self.searchField setDelegate:nil];[self.inviteField setDelegate:nil]; __RELEASE__ [super dealloc];}
@end

static NSUInteger CheckPickerTypography(SurfaceOwner *owner) {
 NSUInteger checks=0;
 NSArray *fields=[NSArray arrayWithObject:owner.aquaTitleField];
 for(NSTextField *field in fields) {
  NSString *text=[field stringValue];
  assert([text length] && [text isEqual:TGLoc(@"contacts.title")]);
  NSSize ink=[text sizeWithAttributes:[NSDictionary dictionaryWithObject:[field font] forKey:NSFontAttributeName]];
  assert(ink.width<=NSWidth([field frame]) && ink.height<=NSHeight([field frame]));checks++;
 }
 NSArray *buttons=[NSArray arrayWithObjects:owner.createPopUpButton,owner.openButton,owner.inviteDisclosureButton,owner.joinButton,nil];
 for(NSButton *button in buttons) {
  NSString *title=[button title];
  assert([title length] && [title rangeOfString:@"contacts."].location==NSNotFound);
  NSFont *font=[button font] ? [button font] : [NSFont systemFontOfSize:13];
  NSSize ink=[title sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]];
  NSRect titleRect=[[button cell] titleRectForBounds:[button bounds]];
  assert(ink.width<=NSWidth(titleRect) && ink.height<=NSHeight(titleRect));checks++;
 }
 NSString *placeholder=[[owner.searchField cell] placeholderString];
 assert([placeholder isEqual:TGLoc(@"contacts.search")]);
 NSRect searchInk=[[owner.searchField cell] searchTextRectForBounds:[owner.searchField bounds]];
 assert([placeholder sizeWithAttributes:[NSDictionary dictionaryWithObject:[owner.searchField font] forKey:NSFontAttributeName]].width<=NSWidth(searchInk));checks++;
 NSArray *menuTitles=[NSArray arrayWithObjects:TGLoc(@"contacts.createMenu"),TGLoc(@"create.channel"),TGLoc(@"create.group"),TGLoc(@"create.secret"),nil];
 for(NSUInteger i=0;i<[menuTitles count];i++) {
  NSMenuItem *item=[[[owner.createPopUpButton menu] itemArray] objectAtIndex:i];
  assert([[item title] isEqual:[menuTitles objectAtIndex:i]]);checks++;
 }
 return checks;
}
static NSUInteger CheckPicker(SurfaceOwner *owner) {
 NSUInteger checks=0;[owner.window setDelegate:(id)owner];[owner buildAquaViews];
 NSArray *menu=[[owner.createPopUpButton menu] itemArray];assert([menu count]==4);checks++;
 assert([[menu objectAtIndex:1] action]==@selector(createChannel:));checks++;
 assert([[menu objectAtIndex:2] action]==@selector(createGroup:));checks++;
 assert([[menu objectAtIndex:3] action]==@selector(createSecretChat:));checks++;
 NSDictionary *human=[NSDictionary dictionaryWithObject:@NO forKey:@"is_bot"],*bot=[NSDictionary dictionaryWithObject:@YES forKey:@"is_bot"];
 NSArray *selections=[NSArray arrayWithObjects:[NSArray array],[NSArray arrayWithObject:human],[NSArray arrayWithObject:bot],[NSArray arrayWithObjects:human,human,nil],nil];
 for(NSUInteger busy=0;busy<2;busy++)for(NSUInteger i=0;i<[selections count];i++) {
  owner.selected=[selections objectAtIndex:i];owner.loading=busy;[owner updateSelectionActions];
  assert([owner.openButton isEnabled]==(!busy&&(i==1||i==2)));checks++;
  assert([[menu objectAtIndex:1] isEnabled]==!busy);checks++;
  assert([[menu objectAtIndex:2] isEnabled]==(!busy&&i!=0));checks++;
  assert([[menu objectAtIndex:3] isEnabled]==(!busy&&i==1));checks++;
 }
 for(CGFloat width=560;width<=1000;width+=41)for(CGFloat height=440;height<=850;height+=53)for(NSUInteger invite=0;invite<2;invite++) {
  if(owner.aquaInvitationVisible!=invite)[owner toggleAquaInvitation:nil];
  [owner.window setContentSize:NSMakeSize(width,height)];
  [owner windowDidResize:[NSNotification notificationWithName:NSWindowDidResizeNotification object:owner.window]];
  NSRect bounds=[[owner.window contentView] bounds];TGChatLifecycleAquaGeometry g=TGChatLifecycleAquaFrames(bounds.size,invite);
  assert(NSContainsRect(bounds,g.list)&&NSContainsRect(bounds,g.search)&&NSContainsRect(bounds,g.create));checks+=3;
  assert(!NSIntersectsRect(g.search,g.list)&&!NSIntersectsRect(g.open,g.inviteToggle)&&!NSIntersectsRect(g.title,g.create));checks+=3;
  assert(NSHeight(g.list)>=188&&NSWidth(g.list)==width-36);checks++;
  assert(NSEqualRects([owner.aquaListCard frame],g.list)&&NSEqualRects([owner.searchField frame],g.search));checks++;
  assert(NSEqualRects([owner.openButton frame],g.open)&&NSEqualRects([owner.inviteField frame],g.inviteField));checks++;
  assert([owner.inviteField isHidden]==!invite&&[owner.joinButton isHidden]==!invite);checks++;
  checks+=CheckPickerTypography(owner);
  if(invite){assert(NSContainsRect(bounds,g.inviteField)&&!NSIntersectsRect(g.inviteField,g.join)&&!NSIntersectsRect(g.list,g.inviteField));checks+=3;}
 }
 owner.aquaInvitationVisible=NO;[owner layoutAquaViews];[owner focusInviteLink];assert(owner.aquaInvitationVisible&&![owner.inviteField isHidden]);checks++;
 [owner toggleAquaInvitation:nil];assert(!owner.aquaInvitationVisible&&[owner.inviteField isHidden]);checks++;
 return checks;
}
static NSUInteger CheckCaption(SurfaceOwner *owner) {
 NSUInteger checks=0;[owner ensurePhotoSendPreviewWindow];NSTextView *caption=owner.photoSendCaptionField;NSScrollView *scroll=owner.photoSendCaptionScrollView;
 assert([caption isKindOfClass:[NSTextView class]]&&[scroll documentView]==caption);checks++;
 NSArray *attachmentKeys=[NSArray arrayWithObjects:@"attachment.preview.title",@"attachment.preview.count",@"attachment.send.batch",@"attachment.send.cancelling",@"attachment.send.unconfirmed",@"attachment.send.targetUnavailable",@"attachment.send.cancelled",@"attachment.large.title",@"attachment.large.message",@"attachment.ready",@"attachment.send.album",@"attachment.send.offline",nil];
 for(NSString *key in attachmentKeys) {assert(![TGLoc(key) isEqual:key] && [TGLoc(key) length]);checks++;}
 NSString *count=[NSString stringWithFormat:TGLoc(@"attachment.preview.count"),(unsigned long)10];
 assert([count rangeOfString:@"10"].location!=NSNotFound && [count rangeOfString:@"%"].location==NSNotFound);checks++;
 assert([count sizeWithAttributes:[NSDictionary dictionaryWithObject:[owner.photoSendTitleField font] forKey:NSFontAttributeName]].width<=NSWidth([owner.photoSendTitleField frame]));checks++;
 NSString *batch=[NSString stringWithFormat:TGLoc(@"attachment.send.batch"),(unsigned long)3,(unsigned long)10];
 assert([batch rangeOfString:@"3"].location!=NSNotFound && [batch rangeOfString:@"10"].location!=NSNotFound && [batch rangeOfString:@"%"].location==NSNotFound);checks++;
 assert([TGLoc(@"attachment.send.cancelling") sizeWithAttributes:[NSDictionary dictionaryWithObject:[owner.photoSendErrorField font] forKey:NSFontAttributeName]].width<=NSWidth([owner.photoSendErrorField frame]));checks++;

 assert([[owner.photoSendPreviewWindow title] isEqual:TGLoc(@"attachment.preview.title")]);checks++;
 assert(([[owner.photoSendTitleField stringValue] isEqual:[NSString stringWithFormat:TGLoc(@"attachment.preview.count"),(unsigned long)1]]));checks++;
 for(NSView *view in [[owner.photoSendPreviewWindow contentView] subviews]) if([view isKindOfClass:[NSButton class]]) {NSString *title=[(NSButton *)view title];assert([title isEqual:TGLoc(@"send")]||[title isEqual:TGLoc(@"cancel")]);checks++;}
 assert([TGLoc(@"downloads.retry") sizeWithAttributes:[NSDictionary dictionaryWithObject:[owner.photoSendSendButton font] forKey:NSFontAttributeName]].width<NSWidth([owner.photoSendSendButton frame])-16);checks++;
 assert([scroll hasVerticalScroller]&&![scroll hasHorizontalScroller]&&[scroll autohidesScrollers]);checks++;
 assert(NSHeight([scroll frame])>=100&&![caption isRichText]&&[caption isVerticallyResizable]&&![caption isHorizontallyResizable]);checks++;
 assert([[caption textContainer] widthTracksTextView]);checks++;
 assert([caption enclosingScrollView]==scroll);checks++;
 NSMutableString *text=[NSMutableString string];for(NSUInteger i=0;i<80;i++)[text appendFormat:@"Строка %lu: caption with enough words to wrap and scroll.\n",(unsigned long)i];
 [caption setString:text];[[caption layoutManager] ensureLayoutForTextContainer:[caption textContainer]];
 [caption scrollRangeToVisible:NSMakeRange([text length]-1,1)];assert(NSMinY([[scroll contentView] bounds])>0);checks++;
 assert([[caption string] isEqual:text]);checks++;
 [caption scrollRangeToVisible:NSMakeRange(0,0)];assert(NSMinY([[scroll contentView] bounds])==0);checks++;
 [caption setSelectedRange:NSMakeRange([text length],0)];[caption insertNewline:nil];assert([[caption string] hasSuffix:@"\n\n"]);checks++;
 [owner.photoSendPreviewWindow makeFirstResponder:caption];
 [owner resetAttachmentCaption];
 [caption insertText:@"Old attachment caption"];[caption breakUndoCoalescing];
 NSUndoManager *undo=[caption undoManager];
 if([undo groupingLevel]>0)[undo endUndoGrouping];
 assert([undo canUndo]);checks++;
 // Cancel/new attachment must erase text AND the undo/redo history.
 [owner resetAttachmentCaption];
 assert([[caption string] length]==0&&![undo canUndo]&&![undo canRedo]);checks++;
 assert(NSEqualRanges([caption selectedRange],NSMakeRange(0,0)));checks++;
 [caption insertText:@"New caption"];[caption breakUndoCoalescing];
 if([undo groupingLevel]>0)[undo endUndoGrouping];
 assert([undo canUndo]);checks++;
 [undo undo];assert([[caption string] length]==0);checks++;
 [undo redo];assert([[caption string] isEqual:@"New caption"]);checks++;
 [owner resetAttachmentCaption];assert(![undo canUndo]&&![undo canRedo]);checks++;
 assert(!NSIntersectsRect([owner.photoSendErrorField frame],[scroll frame]));checks++;
 for(NSView *view in [[owner.photoSendPreviewWindow contentView] subviews])assert(![view isKindOfClass:[NSTableView class]]);
 return checks;
}
static NSUInteger CheckMediaGrid(SurfaceOwner *owner) {
 NSUInteger checks=0;NSArray *items=[NSArray arrayWithObjects:[[[TGMessageItem alloc] init] autorelease],[[[TGMessageItem alloc] init] autorelease],nil];
 for(NSUInteger mode=0;mode<2;mode++) {
  Aqua=mode;owner.mediaCenterResultsView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,500,400)] autorelease];
  [owner buildMediaCenterGridRowsWithItems:items width:500];
  for(NSView *tile in [owner.mediaCenterResultsView subviews]) {
   NSUInteger labels=0,images=0,hits=0;
   for(NSView *child in [tile subviews]) {
    if([child isKindOfClass:[NSTextField class]])labels++;
    if([child isKindOfClass:[NSImageView class]]){images++;assert(NSHeight([child frame])==(Aqua ? 128:86));checks++;}
    if([child isKindOfClass:[NSButton class]]){hits++;assert([(NSButton *)child action]==@selector(previewMediaCenterItem:)&&[(NSButton *)child target]==owner);checks++;assert([[child toolTip] rangeOfString:@"photo.jpg"].location!=NSNotFound);checks++;}
   }
   assert(labels==(Aqua ? 0:2)&&images==1&&hits==1);checks++;
  }
 }
 return checks;
}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 NSUInteger checks=0;
 NSString *original=[TGLanguageCode() copy];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
  TGSetLanguageCode(language);Aqua=YES;
  NSWindow *window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,620) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
  SurfaceOwner *owner=[[[SurfaceOwner alloc] initWithWindow:window] autorelease];
  checks+=CheckPicker(owner)+CheckCaption(owner)+CheckMediaGrid(owner);
 }
 TGSetLanguageCode(original);[original release];
 printf("Aqua attachment/contact/media: %lu native layout, real RU/BE/EN typography, selection, disclosure, multiline scroll and image-first checks PASS\n",(unsigned long)checks);
 [pool drain];return 0;
}
