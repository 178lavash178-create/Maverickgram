#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real profile editor and native bio/state with synthetic data only."""
from __future__ import print_function, unicode_literals
import os,sys,tempfile,shutil,subprocess
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
def read(path):
 with open(os.path.join(ROOT,path),'rb') as f:return f.read().decode('utf-8')
def implementation(path,name):
 source=read(path);begin=source.index('@implementation '+name+'\n');return source[begin:source.index('\n@end',begin)+5]
buttons=read('Sources/UI/TGStatusButtonCells.m');buttons=buttons[:buttons.index('\n@implementation TGDrawerButtonCell')]
avatar=read('Sources/UI/TGMessageLayoutSupport.m');avatar=avatar[avatar.index('NSString *TGInitialsForTitle'):avatar.index('NSString *TGShortTimeStringFromDateValue')]
harness=r'''
#import <Cocoa/Cocoa.h>
#import "TGProfileEditWindowController.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGMessageLayoutSupport.h"
#import "TGAvatarImagePresentation.h"
#import "TGMediaImageLoader.h"
#import "TGAquaAppearance.h"
#import "TGAquaShellViews.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
// Only external file selection/decode is isolated. All controller, native form,
// utility material, avatar view and button rendering below are production code.
static NSUInteger PanelCalls;
NSInteger TGRunAlert(NSAlert *alert,NSWindow *parent){(void)alert;(void)parent;return NSAlertSecondButtonReturn;}
NSInteger TGRunFilePanel(NSSavePanel *panel,NSWindow *parent){(void)panel;(void)parent;PanelCalls++;return NSCancelButton;}
NSImage *TGMediaCachedThumbnailFromFile(NSString *path,NSUInteger size){(void)size;return [path length]?[[[NSImage alloc] initWithContentsOfFile:path] autorelease]:nil;}
TGMediaImageLoadToken *TGLoadImageThumbnailFromFileAsync(NSString *path,NSUInteger size,void(^completion)(NSImage *)){(void)path;(void)size;(void)completion;return nil;}
__BUTTONS__
__PRIMARY__
__SECONDARY__
__AQUA_CELL__
__CARD__
__AVATAR_HELPERS__
__AVATAR_VIEW__
@interface TGProfileEditWindowController (ProbeActions)
- (void)saveProfile:(id)sender;
- (void)cancelProfileEdit:(id)sender;
- (void)chooseProfilePhoto:(id)sender;
@end
@interface SyntheticProfileDelegate:NSObject<TGProfileEditWindowControllerDelegate>
@property(nonatomic) NSUInteger saves,photos;
@property(nonatomic,retain) NSDictionary *saved;
@end
@implementation SyntheticProfileDelegate
@synthesize saves=_saves,photos=_photos,saved=_saved;
- (void)dealloc{[_saved release];[super dealloc];}
- (void)profileEditWindowController:(TGProfileEditWindowController *)c didRequestSaveFirstName:(NSString *)first lastName:(NSString *)last username:(NSString *)user bio:(NSString *)bio{(void)c;self.saves++;self.saved=[NSDictionary dictionaryWithObjectsAndKeys:first,@"first",last,@"last",user,@"user",bio,@"bio",nil];}
- (void)profileEditWindowController:(TGProfileEditWindowController *)c didRequestSetPhotoAtPath:(NSString *)path{(void)c;(void)path;self.photos++;}
@end
static NSUInteger Checks;
static void Require(BOOL value,const char *why){Checks++;if(!value){fprintf(stderr,"Profile editor: %s\n",why);exit(1);}}
static id Field(TGProfileEditWindowController *editor,NSString *name){return [editor valueForKey:name];}
static NSBitmapImageRep *Render(NSView *view){NSBitmapImageRep *bitmap=[view bitmapImageRepForCachingDisplayInRect:[view bounds]];[view cacheDisplayInRect:[view bounds] toBitmapImageRep:bitmap];return bitmap;}
static void CheckLabels(NSView *content){
 for(NSView *view in [content subviews]){
  Require(NSContainsRect([content bounds],[view frame]),"all real root controls stay inside utility window");
  if([view isKindOfClass:[NSTextField class]]&&![(NSTextField *)view isEditable]&&[[(NSTextField *)view stringValue] length]&&! [view isHidden]){
   NSTextField *field=(NSTextField *)view;NSSize size=[[field stringValue] sizeWithAttributes:[NSDictionary dictionaryWithObject:[field font] forKey:NSFontAttributeName]];
   if([field frame].size.height<30)Require(size.width<NSWidth([field frame])-2,"actual localized heading/label fits its production frame");
  }
 }
}
int main(int argc,const char **argv){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 BOOL aqua=argc>1&&strcmp(argv[1],"aqua")==0;
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){
  TGSetLanguageCode(language);TGProfileEditWindowController *editor=[[[TGProfileEditWindowController alloc] init] autorelease];SyntheticProfileDelegate *delegate=[[[SyntheticProfileDelegate alloc] init] autorelease];editor.delegate=delegate;
  [editor configureWithFirstName:@"  Alice  " lastName:@"  Example  " username:@"  @synthetic_user  " bio:@"  Line one\nLine two\nThird line  "];
  // Modern diagnostic hosts can inherit Dark mode; the supported historical
  // systems use Aqua. Select that appearance only in the synthetic probe.
  Class appearanceClass=NSClassFromString(@"NSAppearance");
  if(appearanceClass&&[[editor window] respondsToSelector:@selector(setAppearance:)]) {
   id appearance=[appearanceClass performSelector:@selector(appearanceNamed:) withObject:@"NSAppearanceNameAqua"];
   if(appearance)[[editor window] performSelector:@selector(setAppearance:) withObject:appearance];
  }
  NSView *content=[[editor window] contentView];Require(NSWidth([content bounds])==(aqua?500:470),"Classic and Aqua keep their separate production geometries");
  if(aqua){
   Require([content isKindOfClass:[TGAquaUtilityWindowView class]],"Aqua uses shared utility material");Require([(TGAquaUtilityWindowView *)content headerHeight]==52&&[(TGAquaUtilityWindowView *)content footerHeight]==54,"profile header and footer have reserved rails");
   NSTextView *bio=Field(editor,@"bioTextView");NSScrollView *scroll=Field(editor,@"bioScrollView");
   Require(NSHeight([content bounds])==500,"Aqua form uses compact 500 pt content height");
   NSTextField *heading=nil;for(NSView *v in [content subviews])if([v isKindOfClass:[NSTextField class]]&&[[(NSTextField *)v stringValue] isEqual:TGLoc(@"profile.edit.title")])heading=(NSTextField *)v;
   Require(heading&&[[heading font] pointSize]==14&&NSEqualRects([heading frame],NSMakeRect(24,466,452,20)),"profile title shares 14 pt type and optical placement within the standard 52 pt utility header");
   NSRect avatarFrame=[Field(editor,@"avatarView") frame],firstFrame=[Field(editor,@"firstNameField") frame],lastFrame=[Field(editor,@"lastNameField") frame],userFrame=[Field(editor,@"usernameField") frame];
   Require(NSEqualRects(avatarFrame,NSMakeRect(24,360,72,72)),"actual avatar remains 72 pt with 16 pt clear space below header");
   Require(NSHeight(firstFrame)==26&&NSHeight(lastFrame)==26&&NSHeight(userFrame)==26&&NSMinY(firstFrame)==NSMinY(lastFrame),"all native name/username input frames share height and baseline");
   Require(NSMinY(firstFrame)-NSMinY(userFrame)==54,"name and username rows keep a consistent compact vertical rhythm");
   Require(NSHeight([scroll frame])==100&&NSMinY([scroll frame])==118,"biography keeps a real 100 pt multiline viewport in the compact form");
   NSRect cancelFrame=[Field(editor,@"cancelButton") frame],saveFrame=[Field(editor,@"saveButton") frame],errorFrame=[Field(editor,@"errorField") frame];
   Require(NSMinY(cancelFrame)==13&&NSMinY(saveFrame)==13&&NSHeight(saveFrame)==28,"save and cancel sit vertically centered in the standard 54 pt footer");
   Require(NSHeight(errorFrame)>=32&&NSMinY(errorFrame)>54&&NSMaxY(errorFrame)<NSMinY([scroll frame]),"two-line validation has separate clear space between biography and footer");
   Require([Field(editor,@"photoButton") nextKeyView]==Field(editor,@"firstNameField")&&[Field(editor,@"firstNameField") nextKeyView]==Field(editor,@"lastNameField")&&[Field(editor,@"lastNameField") nextKeyView]==Field(editor,@"usernameField")&&[Field(editor,@"usernameField") nextKeyView]==bio&&[bio nextKeyView]==Field(editor,@"cancelButton"),"keyboard traversal follows the visible compact form in reading order");
   Require([bio isKindOfClass:[NSTextView class]]&&[scroll documentView]==bio,"bio is a genuine multiline native document with scroll ownership");
   Require(![bio isRichText]&&[bio isVerticallyResizable]&&! [bio isHorizontallyResizable]&&[scroll hasVerticalScroller]&&! [scroll hasHorizontalScroller],"bio wraps and scrolls vertically without rich text or horizontal scrolling");
   Require([[bio string] isEqual:@"  Line one\nLine two\nThird line  "],"configuration preserves all bio newlines and surrounding text before save");
   [bio setSelectedRange:NSMakeRange([[bio string] length],0)];[bio insertNewline:nil];Require([[bio string] hasSuffix:@"\n"]&&delegate.saves==0,"Return inserts newline in bio and never prematurely saves");
   TGProfileAvatarView *avatar=Field(editor,@"avatarView");NSString *path=[NSString stringWithUTF8String:argv[2]];[editor setAvatarLocalPath:path];Require([[avatar avatarLocalPath] isEqual:path],"existing photo path reaches real avatar presentation");Require([[avatar displayName] rangeOfString:@"Alice"].location!=NSNotFound,"avatar fallback receives configured name");
   NSMutableString *longBio=[NSMutableString string];for(NSUInteger i=0;i<60;i++)[longBio appendFormat:@"Synthetic line %lu\n",(unsigned long)i];[bio setString:longBio];[[bio layoutManager] ensureLayoutForTextContainer:[bio textContainer]];[bio scrollRangeToVisible:NSMakeRange([[bio string] length],0)];
   Require(NSHeight([bio bounds])>NSHeight([[scroll contentView] bounds]),"long bio grows its actual native document beyond viewport");Require(NSMinY([[scroll contentView] bounds])>0,"end of a long bio is reachable through real scrolling");
   [editor configureWithFirstName:@"  Alice  " lastName:@"  Example  " username:@"  @synthetic_user  " bio:@"  Line one\nLine two\nThird line  "];
   Require(NSMinY([[scroll contentView] bounds])<1,"reconfiguring a short bio clears a long document's stale scroll offset");
   // Use real native editing to populate both undo and redo, then replace
   // the edit session with a much shorter value (the former stale-range bug).
   [editor configureWithFirstName:@"Alice" lastName:@"Example" username:@"synthetic_user" bio:@"A substantially longer cancelled biography from the previous session."];
   [[editor window] makeFirstResponder:bio];[bio setSelectedRange:NSMakeRange([[bio string] length],0)];[bio insertText:@" Previous edit"];[bio breakUndoCoalescing];
   NSUndoManager *undo=[bio undoManager];Require([undo canUndo],"real bio editing registers native undo");[undo undo];Require([undo canRedo],"undo creates a real redo entry before session replacement");
   [editor configureWithFirstName:@"Alice" lastName:@"Example" username:@"synthetic_user" bio:@"Short\nBio"];
   Require(![undo canUndo]&&! [undo canRedo],"reconfiguration clears previous draft's native undo and redo ranges");
   [bio setSelectedRange:NSMakeRange([[bio string] length],0)];[bio insertText:@" New"];[bio breakUndoCoalescing];Require([undo canUndo],"new edit session still supports undo");[undo undo];Require([[bio string] isEqual:@"Short\nBio"],"undo affects only new short bio and cannot resurrect cancelled text");[undo redo];Require([[bio string] isEqual:@"Short\nBio New"],"redo uses only valid ranges from the current bio");
   [editor configureWithFirstName:@"  Alice  " lastName:@"  Example  " username:@"  @synthetic_user  " bio:@"  Line one\nLine two\nThird line  "];
   Require(NSMinX([Field(editor,@"firstNameField") frame])==NSMinX([Field(editor,@"usernameField") frame])&&NSMaxX([Field(editor,@"lastNameField") frame])==NSMaxX([scroll frame]),"name, username and bio edges align");
   CheckLabels(content);NSBitmapImageRep *bitmap=Render(content);Require(bitmap!=nil,"actual production Aqua form and material produce a native raster");
   NSColor *body=[[bitmap colorAtX:(NSInteger)(490*[bitmap pixelsWide]/500.0) y:(NSInteger)(270*[bitmap pixelsHigh]/NSHeight([content bounds]))] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];Require([body redComponent]>.97&&[body greenComponent]>.97&&[body blueComponent]>.97,"Aqua body is white instead of full-window metal");
   const char *preview=getenv("TG_PROFILE_PROBE_PREVIEW_DIR");if(preview&&[language isEqual:@"ru"]){NSString *file=[[NSString stringWithUTF8String:preview] stringByAppendingPathComponent:@"aqua-profile-editor.png"];[[bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:file atomically:YES];}
   [editor showErrorMessage:@"Synthetic server error: correct the profile and retry."];Require(![Field(editor,@"errorField") isHidden],"error appears inline");Require(!NSIntersectsRect([Field(editor,@"errorField") frame],[Field(editor,@"saveButton") frame]),"inline error stays above save/cancel rail");[editor showErrorMessage:nil];Require([Field(editor,@"errorField") isHidden],"cleared inline error leaves no stale text");
  }else{
   Require(Field(editor,@"bioTextView")==nil&&Field(editor,@"bioField")!=nil,"Classic retains original bio control");Require(NSEqualRects([Field(editor,@"bioField") frame],NSMakeRect(28,93,414,68)),"Classic bio frame remains unchanged");
  }
  [editor setSaving:YES];Require(![Field(editor,@"firstNameField") isEnabled]&&! [Field(editor,@"photoButton") isEnabled]&&! [Field(editor,@"saveButton") isEnabled]&&! [Field(editor,@"cancelButton") isEnabled],"all mutation actions disable while saving");if(aqua)Require(![Field(editor,@"bioTextView") isEditable],"multiline bio also locks during save");
  [editor saveProfile:nil];[editor chooseProfilePhoto:nil];Require(delegate.saves==0&&PanelCalls==0,"busy action guards prevent duplicate saves and file-panel opening");[editor setSaving:NO];
  [editor chooseProfilePhoto:nil];Require(PanelCalls>0&&delegate.photos==0,"cancelling native file selection leaves current photo unchanged");PanelCalls=0;
  [editor saveProfile:nil];Require(delegate.saves==1,"valid form reaches existing delegate once");Require([[delegate.saved objectForKey:@"first"] isEqual:@"Alice"]&&[[delegate.saved objectForKey:@"last"] isEqual:@"Example"]&&[[delegate.saved objectForKey:@"user"] isEqual:@"synthetic_user"],"save retains existing trimming and username normalization");Require([[delegate.saved objectForKey:@"bio"] isEqual:@"Line one\nLine two\nThird line"],"save preserves internal bio paragraphs in both designs");
  NSUInteger validSaves=delegate.saves;
  if(aqua){NSTextField *first=Field(editor,@"firstNameField");[[editor window] makeFirstResponder:first];NSText *nativeEditor=[first currentEditor];Require(nativeEditor!=nil,"native first-name field editor is active");[nativeEditor setString:@"  Edited First  "];[editor saveProfile:nil];Require(delegate.saves==validSaves+1&&[[delegate.saved objectForKey:@"first"] isEqual:@"Edited First"],"save commits active native field editor before reading profile values");validSaves=delegate.saves;}
  [Field(editor,@"firstNameField") setStringValue:@"  "];[editor saveProfile:nil];Require(delegate.saves==validSaves&&[[Field(editor,@"errorField") stringValue] isEqual:TGLoc(@"profile.edit.firstNameRequired")],"missing name remains a localized inline validation error");
  [editor configureWithFirstName:nil lastName:nil username:nil bio:nil];Require([[Field(editor,@"firstNameField") stringValue] length]==0&&[[Field(editor,@"errorField") stringValue] length]==0,"reconfiguration resets fields/error without retaining previous drafts");[[editor window] close];
 }
 printf("Profile editor %s PASS: %lu real controller/native layout/localization/state checks; no remote save/photo operations.\n",aqua?"Aqua":"Classic",(unsigned long)Checks);[pool drain];return 0;}
'''
for token,value in [('__BUTTONS__',buttons),('__PRIMARY__',implementation('Sources/UI/TGStatusButtonCells.m','TGPrimaryTextButtonCell')),('__SECONDARY__',implementation('Sources/UI/TGStatusButtonCells.m','TGSecondaryTextButtonCell')),('__AQUA_CELL__',implementation('Sources/UI/TGAquaShellViews.m','TGAquaTextButtonCell')),('__CARD__',implementation('Sources/UI/TGStatusViewCells.m','TGGroupedCardView')),('__AVATAR_HELPERS__',avatar),('__AVATAR_VIEW__',implementation('Sources/UI/TGStatusViewComponents.m','TGProfileAvatarView'))]:harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-profile-editor-')
try:
 source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe');
 with open(source,'wb') as f:f.write(harness.encode('utf-8'))
 deps=['Sources/UI/TGProfileEditWindowController.m','Sources/UI/TGAvatarImagePresentation.m','Sources/UI/TGButtonAppearance.m','Sources/UI/TGIconAssets.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGTheme.m','Sources/UI/TGThemeTextField.m','Sources/UI/TGVisualWorldThemeSpec.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGDialogPresentation.m','Sources/UI/TGLocalization.m']
 # TGRunFilePanel is intentionally a cancel-only transport in this probe.
 deps.remove('Sources/UI/TGDialogPresentation.m')
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Core'),'-I'+os.path.join(ROOT,'Sources/Services'),'-I'+os.path.join(ROOT,'Sources/Media'),source]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary])
 asset=os.path.join(ROOT,'Sources/Resources/Icons/user.png')
 for design in ['classic','aqua']:subprocess.check_call([binary,design,asset],env=dict(os.environ,HOME=folder))
finally:shutil.rmtree(folder)
