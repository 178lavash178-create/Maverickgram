#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real constructor/resize checks for sharing, administration and chat info."""
from __future__ import print_function,unicode_literals
import os,sys,tempfile,subprocess,shutil
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
def read(p):
 with open(os.path.join(ROOT,p),'rb') as f:return f.read().decode('utf-8')
def impl(p,name):
 s=read(p);i=s.index('@implementation '+name+'\n');return s[i:s.index('\n@end',i)+5]
buttons=read('Sources/UI/TGStatusButtonCells.m');buttons=buttons[:buttons.index('\n@implementation TGDrawerButtonCell')]
source=r'''
#import <Cocoa/Cocoa.h>
#import "TGChatFolderSharingWindowController.h"
#import "TGChatAdministrationWindowController.h"
#import "TGChatInfoWindowController.h"
#import "TGBotInteractionWindowController.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGStatusButtonCells.h"
#import "TGTheme.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
#import "TGDialogPresentation.h"
@implementation TGBotInteractionWindowController
@end
// External alerts and presentation are isolated here. The full real window
// constructors, data rendering, controls and resize delegates are compiled.
NSInteger TGRunAlert(NSAlert *a,NSWindow *w){(void)a;(void)w;return NSAlertSecondButtonReturn;}
void TGFitUtilityWindowToVisibleScreen(NSWindow *w){(void)w;}
__VIEWS__
@interface NSObject (ProbePrivate)
- (void)layoutResponsiveViews;
- (void)renderSummary;
- (void)updateSummaryFields;
- (void)updateControls;
- (void)windowDidResize:(NSNotification *)n;
@end
static NSUInteger Checks;
static void Require(BOOL v,const char *m){Checks++;if(!v){fprintf(stderr,"Responsive utilities: %s\n",m);exit(1);}}
static id V(id c,NSString *key){return [c valueForKey:key];}
static void CheckRoot(NSView *root){
 NSMutableArray *controls=[NSMutableArray array];
 for(NSView *v in [root subviews]){
  if([v isHidden])continue;
  Require(NSContainsRect([root bounds],[v frame]),"visible real root control stays inside content bounds");
  if([v isKindOfClass:[NSControl class]]||[v isKindOfClass:[NSScrollView class]])[controls addObject:v];
  if([v isKindOfClass:[NSPopUpButton class]]){NSPopUpButton *popup=(NSPopUpButton *)v;CGFloat needed=[[popup cell] cellSize].width;if(needed>NSWidth([v frame]))fprintf(stderr,"Popup %s native cell needs%g width%g\n",[[popup titleOfSelectedItem] UTF8String],needed,NSWidth([v frame]));Require(needed<=NSWidth([v frame]),"native popup cell fits localized menu title and system indicator");}
  if([v isKindOfClass:[NSButton class]]&&! [v isKindOfClass:[NSPopUpButton class]]){
   NSButton *b=(NSButton *)v;NSFont *font=[b font]?[b font]:[NSFont systemFontOfSize:13];CGFloat padding=24;
   if([[b cell] isKindOfClass:[TGPrimaryTextButtonCell class]])font=[NSFont boldSystemFontOfSize:13];
   else if([[b cell] isKindOfClass:[TGSecondaryTextButtonCell class]]){font=[NSFont boldSystemFontOfSize:12];padding=20;}
   CGFloat text=[[b title] sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
   if(text+padding>NSWidth([b frame]))fprintf(stderr,"Button %s text%g width%g font%g\n",[[b title] UTF8String],text,NSWidth([b frame]),[[b font] pointSize]);
   Require(text+padding<=NSWidth([b frame]),"localized real button title fits its frame");
  }
 }
 for(NSUInteger i=0;i<[controls count];i++)for(NSUInteger j=i+1;j<[controls count];j++){
  NSView *a=[controls objectAtIndex:i],*b=[controls objectAtIndex:j];
  if(NSIntersectsRect([a frame],[b frame])){fprintf(stderr,"Intersection %s %s / %s %s\n",[[a description] UTF8String],[NSStringFromRect([a frame]) UTF8String],[[b description] UTF8String],[NSStringFromRect([b frame]) UTF8String]);Require(NO,"visible real controls do not overlap after native resize");}
  Checks++;
 }
}
int main(int argc,const char **argv){NSAutoreleasePool *p=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 BOOL aqua=argc>1&&strcmp(argv[1],"aqua")==0;[[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
 for(NSString *lang in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){TGSetLanguageCode(lang);
  TGChatFolderSharingWindowController *sharing=[[[TGChatFolderSharingWindowController alloc] initWithClient:nil] autorelease];[sharing updateSummaryFields];
  TGChatAdministrationWindowController *admin=[[[TGChatAdministrationWindowController alloc] initWithClient:nil chatID:@1 title:@"Synthetic group"] autorelease];
  TGChatInfoWindowController *info=[[[TGChatInfoWindowController alloc] initWithClient:nil chatID:@1 title:@"Synthetic group"] autorelease];
  for(NSNumber *width in [NSArray arrayWithObjects:@600,@660,@680,@720,@760,@820,@900,@1100,@600,@900,nil]){
   for(NSWindowController *c in [NSArray arrayWithObjects:sharing,admin,info,nil]){
    NSWindow *w=[c window];CGFloat height=NSHeight([w contentRectForFrameRect:NSMakeRect(0,0,[w minSize].width,[w minSize].height)]);
    Class appearanceClass=NSClassFromString(@"NSAppearance");if(appearanceClass&&[w respondsToSelector:@selector(setAppearance:)]){id appearance=[appearanceClass performSelector:@selector(appearanceNamed:) withObject:@"NSAppearanceNameAqua"];if(appearance)[w performSelector:@selector(setAppearance:) withObject:appearance];}
[w setContentSize:NSMakeSize([width doubleValue],height)];[c windowDidResize:[NSNotification notificationWithName:NSWindowDidResizeNotification object:w]];
    Require([w delegate]==(id)c,"real constructor installs its resize delegate");
    if(c==info){
     for(NSString *kind in [NSArray arrayWithObjects:@"supergroup",@"secret",nil]){
      [info setValue:[NSDictionary dictionaryWithObjectsAndKeys:kind,@"kind",@"Synthetic group",@"title",@"Synthetic description",@"description",[NSDictionary dictionaryWithObject:@"01234567 89ABCDEF 01234567 89ABCDEF 01234567 89ABCDEF 01234567 89ABCDEF" forKey:@"key_fingerprint"],@"secret_chat",nil] forKey:@"chatSummary"];
      [info renderSummary];[info updateControls];CheckRoot([w contentView]);
     }
    }else CheckRoot([w contentView]);
    const char *preview=getenv("TG_UTILITY_RESPONSIVE_PREVIEW_DIR");
    if(preview&&aqua&&[lang isEqual:@"ru"]&&[width integerValue]==600){NSView *root=[w contentView];NSBitmapImageRep *bitmap=[root bitmapImageRepForCachingDisplayInRect:[root bounds]];[root cacheDisplayInRect:[root bounds] toBitmapImageRep:bitmap];NSString *path=[[NSString stringWithUTF8String:preview] stringByAppendingPathComponent:[NSStringFromClass([c class]) stringByAppendingString:@".png"]];[[bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:path atomically:YES];}
    // Native tables must track the real viewport after narrowing and widening.
    for(NSString *key in c==sharing?[NSArray arrayWithObjects:@"linkTableView",@"recommendedTableView",nil]:c==admin?[NSArray arrayWithObjects:@"linksTableView",@"requestsTableView",@"eventsTableView",nil]:[NSArray arrayWithObject:@"memberTableView"]){NSTableView *t=V(c,key);Require(fabs([[[t tableColumns] lastObject] width]-NSWidth([[[t enclosingScrollView] contentView] bounds]))<1,"actual table column follows viewport width");}
   }
  }
  [[sharing window] close];[[admin window] close];[[info window] close];
 }
 printf("Responsive utilities %s PASS: %lu real constructor/localization/resize/control checks; no client or remote operations.\n",aqua?"Aqua":"Classic",(unsigned long)Checks);[p drain];return 0;}
'''
views=buttons+'\n'+'\n'.join(impl(path,name) for path,name in [('Sources/UI/TGStatusButtonCells.m','TGPrimaryTextButtonCell'),('Sources/UI/TGStatusButtonCells.m','TGSecondaryTextButtonCell'),('Sources/UI/TGStatusViewComponents.m','TGUtilityWindowView'),('Sources/UI/TGStatusViewComponents.m','TGUtilityPanelView'),('Sources/UI/TGStatusViewCells.m','TGGroupedCardView')])
source=source.replace('__VIEWS__',views)
folder=tempfile.mkdtemp(prefix='telegraphica-responsive-utilities-')
try:
 path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
 with open(path,'wb') as f:f.write(source.encode('utf-8'))
 deps=['Sources/UI/TGChatFolderSharingWindowController.m','Sources/UI/TGChatAdministrationWindowController.m','Sources/UI/TGChatInfoWindowController.m','Sources/Core/TGSecretChatKey.m','Sources/Core/TGTDLibCapabilities.m','Sources/UI/TGButtonAppearance.m','Sources/UI/TGIconAssets.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGTheme.m','Sources/UI/TGThemeTextField.m','Sources/UI/TGVisualWorldThemeSpec.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGLocalization.m']
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/'+s) for s in ['UI','Core','Services','Media']]+[path]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary])
 for design in ['classic','aqua']:subprocess.check_call([binary,design],env=dict(os.environ,HOME=folder))
finally:shutil.rmtree(folder)
