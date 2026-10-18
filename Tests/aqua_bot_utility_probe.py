#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real bot/QR constructors: localized geometry, state and resize regression.

No TDLib object is supplied, no command/result is sent, no QR authentication is
requested. Native controls/materials and the production QR encoder are real.
"""
from __future__ import print_function, unicode_literals
import os, sys, tempfile, subprocess, shutil
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
def read(p):
    with open(os.path.join(ROOT,p),'rb') as f:return f.read().decode('utf-8')
def impl(p,name):
    s=read(p);i=s.index('@implementation '+name+'\n');return s[i:s.index('\n@end',i)+5]
buttons=read('Sources/UI/TGStatusButtonCells.m');buttons=buttons[:buttons.index('\n@implementation TGDrawerButtonCell')]
source=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGDialogPresentation.h"
#import "TGBotInteractionWindowController.h"
#import "TGBotKeyboardWindowController.h"
#import "TGQRCodeLoginWindowController.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGStatusButtonCells.h"
#import "TGAquaShellViews.h"
#import "TGAquaAppearance.h"
#import "TGTheme.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
NSInteger TGRunAlert(NSAlert *a, NSWindow *w){(void)a;(void)w;return NSAlertSecondButtonReturn;}
#include "TGUtilityWindowGeometry.inc"
__VIEWS__
@interface NSObject (ProbePrivate)
- (void)setLoading:(BOOL)loading status:(NSString *)status;
- (void)windowDidResize:(NSNotification *)n;
- (void)showError:(NSString *)error;
- (void)showQRCodeLink:(NSString *)link;
- (void)updateControls;
@end
static NSUInteger Checks;
static void Require(BOOL v,const char *m){Checks++;if(!v){fprintf(stderr,"Bot utilities: %s\n",m);exit(1);}}
static id V(id c,NSString *key){return [c valueForKey:key];}
static void CheckRoot(NSView *root){
 NSMutableArray *controls=[NSMutableArray array];
 for(NSView *v in [root subviews]){
  if([v isHidden])continue;
  Require(NSContainsRect([root bounds],[v frame]),"visible native root control fits window");
  if([v isKindOfClass:[NSControl class]]||[v isKindOfClass:[NSScrollView class]])[controls addObject:v];
  if([v isKindOfClass:[NSButton class]]&&![v isKindOfClass:[NSPopUpButton class]]){
   NSButton *b=(NSButton *)v;NSFont *font=[b font]?[b font]:[NSFont systemFontOfSize:13];
   if([[b cell] isKindOfClass:[TGPrimaryTextButtonCell class]])font=[NSFont boldSystemFontOfSize:13];
   else if([[b cell] isKindOfClass:[TGSecondaryTextButtonCell class]])font=[NSFont boldSystemFontOfSize:12];
   CGFloat text=[[b title] sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
   Require(text+20<=NSWidth([b frame]),"localized action label fits button");
  }
 }
 for(NSUInteger i=0;i<[controls count];i++)for(NSUInteger j=i+1;j<[controls count];j++){
  NSView *a=[controls objectAtIndex:i],*b=[controls objectAtIndex:j];
  if(NSIntersectsRect([a frame],[b frame]))fprintf(stderr,"Overlap %s %s / %s %s\n",[NSStringFromClass([a class]) UTF8String],[NSStringFromRect([a frame]) UTF8String],[NSStringFromClass([b class]) UTF8String],[NSStringFromRect([b frame]) UTF8String]);
  Require(!NSIntersectsRect([a frame],[b frame]),"independent native controls never overlap after resize");
 }
}
static void SavePreview(NSWindow *w,NSString *file){
 const char *dir=getenv("TG_BOT_UTILITY_PREVIEW_DIR");if(!dir)return;
 Class appearanceClass=NSClassFromString(@"NSAppearance");if(appearanceClass&&[w respondsToSelector:@selector(setAppearance:)]){id a=[appearanceClass performSelector:@selector(appearanceNamed:) withObject:@"NSAppearanceNameAqua"];if(a)[w performSelector:@selector(setAppearance:) withObject:a];}
 NSView *v=[w contentView];NSBitmapImageRep *r=[v bitmapImageRepForCachingDisplayInRect:[v bounds]];[v cacheDisplayInRect:[v bounds] toBitmapImageRep:r];
 [[r representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[[NSString stringWithUTF8String:dir] stringByAppendingPathComponent:file] atomically:YES];
}
int main(int argc,const char **argv){NSAutoreleasePool *p=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 BOOL aqua=argc>1&&strcmp(argv[1],"aqua")==0;[[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){TGSetLanguageCode(language);
  TGBotInteractionWindowController *bot=[[[TGBotInteractionWindowController alloc] initWithClient:nil userID:@1 chatID:@2] autorelease];
  TGBotKeyboardWindowController *keyboard=[[[TGBotKeyboardWindowController alloc] initWithClient:nil chatID:@2 messageID:@3 replyMarkup:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Example action",@"text",[NSDictionary dictionaryWithObject:@"keyboardButtonTypeText" forKey:@"@type"],@"type",nil]]] forKey:@"rows"]] autorelease];
  [bot setValue:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"help",@"command",@"Show available commands",@"description",nil],[NSDictionary dictionaryWithObjectsAndKeys:@"start",@"command",@"Start a conversation",@"description",nil],nil] forKey:@"commands"];
  [V(bot,@"commandTableView") reloadData];
  [V(bot,@"commandTableView") selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  [bot setValue:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Example result",@"title",@"Synthetic result description",@"description",nil]] forKey:@"results"];
  [bot setValue:@88 forKey:@"queryID"];[V(bot,@"resultTableView") reloadData];
  [V(bot,@"resultTableView") selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  [V(keyboard,@"tableView") selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  [bot updateControls];[keyboard updateControls];
  Require([V(bot,@"commandButton") isEnabled]&&[V(bot,@"resultButton") isEnabled]&&[V(keyboard,@"activateButton") isEnabled],"real selection enables the existing command/result/keyboard actions");[V(bot,@"titleField") setStringValue:@"Example bot"];
  [V(bot,@"descriptionField") setStringValue:@"Synthetic bot description. No remote account or messages are used by this layout test."];
  [V(bot,@"targetPopUpButton") addItemWithTitle:@"Synthetic chat"];
  [V(bot,@"targetPopUpButton") selectItemAtIndex:0];
  Require([V(bot,@"commandButton") target]==bot&&[V(bot,@"commandButton") action]==@selector(sendCommandPressed:),"command retains production target/action after Aqua cell replacement");
  Require([V(bot,@"resultButton") target]==bot&&[V(bot,@"resultButton") action]==@selector(sendResultPressed:),"result retains production target/action after Aqua cell replacement");
  Require([V(bot,@"searchButton") target]==bot&&[V(bot,@"searchButton") action]==@selector(searchPressed:),"query retains production target/action after Aqua cell replacement");
  for(NSWindowController *c in [NSArray arrayWithObjects:bot,keyboard,nil]){
   NSWindow *w=[c window];NSSize natural=[[w contentView] bounds].size;
   NSArray *sizes=[NSArray arrayWithObjects:[NSValue valueWithSize:[w contentRectForFrameRect:NSMakeRect(0,0,[w minSize].width,[w minSize].height)].size],[NSValue valueWithSize:natural],[NSValue valueWithSize:[w contentRectForFrameRect:NSMakeRect(0,0,[w maxSize].width,[w maxSize].height)].size],[NSValue valueWithSize:natural],nil];
   NSUInteger sizeIndex=0;
   for(NSValue *size in sizes){[w setContentSize:[size sizeValue]];if(aqua&&c==bot)[c windowDidResize:[NSNotification notificationWithName:NSWindowDidResizeNotification object:w]];CheckRoot([w contentView]);
    if(aqua&&[language isEqual:@"ru"]&&(sizeIndex==0||sizeIndex==2))SavePreview(w,[NSString stringWithFormat:@"aqua-%@-%@.png",c==bot?@"bot-interaction":@"bot-keyboard",sizeIndex==0?@"minimum":@"maximum"]);sizeIndex++;}
   if(c==bot){
    // The two historical regressions, plus the minimum-width variant.
    for(NSNumber *h in [NSArray arrayWithObjects:@620,@748,@508,@600,nil])for(NSNumber *width in [NSArray arrayWithObjects:@660,@720,@940,nil]){
     [w setContentSize:NSMakeSize([width doubleValue],[h doubleValue])];if(aqua)[c windowDidResize:[NSNotification notificationWithName:NSWindowDidResizeNotification object:w]];CheckRoot([w contentView]);
     NSRect commands=[V(bot,@"commandTableView") enclosingScrollView].frame,results=[V(bot,@"resultTableView") enclosingScrollView].frame;
     Require(NSHeight(commands)>=40&&NSHeight(results)>=20,"both real lists retain usable positive viewports");
    }
   }
   [c setLoading:YES status:@"Synthetic long error message that must remain fully available when the status text wraps or the visible area is too small to display every detail."];
   Require(![V(c,c==bot?@"commandButton":@"activateButton") isEnabled],"busy state locks actions against duplicate activation");
   Require([[V(c,@"statusField") toolTip] isEqual:[V(c,@"statusField") stringValue]],"complete long error/status survives truncation via tooltip");
   [c setLoading:NO status:@""];Require([[V(c,@"statusField") stringValue] length]==0&&[[V(c,@"statusField") toolTip] length]==0,"status reset clears tooltip and text");
   Require([V(c,c==bot?@"commandButton":@"activateButton") isEnabled],"completed status restores selected action availability");
   if(aqua){Require([[w contentView] isKindOfClass:[TGAquaUtilityWindowView class]],"Aqua uses shared utility chrome");Require([(TGAquaUtilityWindowView *)[w contentView] headerHeight]==52&&[(TGAquaUtilityWindowView *)[w contentView] footerHeight]==54,"utility rails match shared standard");}
   [w setContentSize:natural];if(aqua&&c==bot)[c windowDidResize:[NSNotification notificationWithName:NSWindowDidResizeNotification object:w]];
   if(aqua&&[language isEqual:@"ru"])SavePreview(w,c==bot?@"aqua-bot-interaction.png":@"aqua-bot-keyboard.png");
  }
  TGQRCodeLoginWindowController *qr=[[[TGQRCodeLoginWindowController alloc] initWithClient:nil] autorelease];
  [qr showQRCodeLink:@"tg://synthetic-audit-not-an-authentication-token"];Require([V(qr,@"qrImageView") image]!=nil,"real QR encoder renders synthetic non-credential input");
  [V(qr,@"spinner") setHidden:YES];CheckRoot([[qr window] contentView]);
  if(aqua&&[language isEqual:@"ru"])SavePreview([qr window],@"aqua-qr-login.png");
  [qr showError:@"Synthetic authentication error. Complete text remains accessible from the status tooltip."];
  Require([V(qr,@"qrImageView") image]==nil&&[[V(qr,@"statusField") toolTip] isEqual:[V(qr,@"statusField") stringValue]],"QR failure clears image and exposes full message");
  for(NSWindowController *controller in [NSArray arrayWithObjects:bot,keyboard,qr,nil]){
   NSWindow *window=[controller window];NSView *natural=[TGUtilityWindowContentView(window) retain];NSSize naturalSize=[natural bounds].size;
   for(NSUInteger cycle=0;cycle<3;cycle++){
    TGFitUtilityWindowToVisibleFrame(window,NSMakeRect(0,0,400,300));
    Require([window contentView]!=natural&&TGUtilityWindowContentView(window)==natural,"small visible screen wraps original natural root instead of compressing it");
    Require(NSEqualSizes([natural bounds].size,naturalSize),"overflow preserves natural form bounds");CheckRoot(natural);
    TGFitUtilityWindowToVisibleFrame(window,NSMakeRect(0,0,1440,1000));
    Require([window contentView]==natural,"large visible screen restores original document root");
    NSSize restored=[window contentRectForFrameRect:[window frame]].size;
    Require(fabs(NSWidth([natural bounds])-restored.width)<1&&fabs(NSHeight([natural bounds])-restored.height)<1,"restored real root follows native content bounds");
    CheckRoot(natural);naturalSize=[natural bounds].size;
   }
   [natural release];
  }
  [[bot window] close];[[keyboard window] close];[[qr window] close];
 }
 printf("Bot utilities %s PASS: %lu real constructor/localization/resize/status checks; no client operations.\n",aqua?"Aqua":"Classic",(unsigned long)Checks);[p drain];return 0;}
'''
views=buttons+'\n'+'\n'.join(impl(path,name) for path,name in [('Sources/UI/TGStatusButtonCells.m','TGPrimaryTextButtonCell'),('Sources/UI/TGStatusButtonCells.m','TGSecondaryTextButtonCell'),('Sources/UI/TGAquaShellViews.m','TGAquaTextButtonCell'),('Sources/UI/TGStatusViewComponents.m','TGUtilityWindowView'),('Sources/UI/TGStatusViewCells.m','TGGroupedCardView')])
source=source.replace('__VIEWS__',views)
folder=tempfile.mkdtemp(prefix='telegraphica-bot-utilities-')
try:
    path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(path,'wb') as f:f.write(source.encode('utf-8'))
    deps=['Sources/UI/TGBotInteractionWindowController.m','Sources/UI/TGBotKeyboardWindowController.m','Sources/UI/TGQRCodeLoginWindowController.m','Sources/UI/TGQRCodeImageGenerator.m','Vendor/qrcodegen/qrcodegen.c','Sources/UI/TGButtonAppearance.m','Sources/UI/TGIconAssets.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGTheme.m','Sources/UI/TGThemeTextField.m','Sources/UI/TGVisualWorldThemeSpec.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGLocalization.m']
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/'+s) for s in ['UI','Core','Services','Media']]+[path]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary])
    for design in ['classic','aqua']:subprocess.check_call([binary,design],env=dict(os.environ,HOME=folder))
finally:shutil.rmtree(folder)
