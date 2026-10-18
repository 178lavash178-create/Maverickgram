#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real Calls/Contacts constructors and localized resize; no account/transport."""
from __future__ import print_function
import os,sys,subprocess,tempfile,shutil
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
def read(p):
 with open(os.path.join(ROOT,p),'rb') as f:return f.read().decode('utf-8')
def impl(p,name):
 s=read(p);a=s.index('@implementation '+name+'\n');return s[a:s.index('\n@end',a)+5]
source=r'''
#import <Cocoa/Cocoa.h>
#import "TGCallsPlaceholderView.h"
#import "TGContactsViewController.h"
#import "TGContactProfileView.h"
#import "TGContactManagementDialogs.h"
#import "TGCallAudioEngine.h"
#import "TGCallCoordinator.h"
#import "TGStatusViewComponents.h"
#import "TGStatusButtonCells.h"
#import "TGTheme.h"
#import "TGInterfaceDesign.h"
#import "TGAquaAppearance.h"
#import "TGLocalization.h"
#import "TGIconAssets.h"
static CGFloat const TGPanelCornerRadius=8,TGPanelHeaderHeight=40;
__VIEWS__
// External services and avatar I/O are isolated; actual controllers, form,
// profile content, row cells, base materials and native metrics are compiled.
NSString * const TGCallCoordinatorDidFinishCallNotification=@"FixtureCallFinished";
@implementation TGCallAudioEngine
+ (BOOL)isOperatingSystemSupported{return YES;}
@end
static BOOL Available=YES;
@implementation TGCallCoordinator
- (BOOL)transportAvailable{return Available;}
@end
@implementation TGContactManagementDialogs
+ (NSDictionary *)contactToAdd{return nil;}
+ (NSString *)phoneNumberForInvitation{return nil;}
+ (BOOL)confirmRemovalOfContactNamed:(NSString *)s{(void)s;return NO;}
@end
void TGDrawAvatarInRect(NSString *path,NSString *name,NSRect rect,BOOL selected,BOOL flipped){(void)path;(void)name;TGDrawTemplateIconAsset(@"user",rect,selected?[NSColor whiteColor]:TGClassicCardMutedInkColor(),1,flipped);}
@implementation TGProfileAvatarView
@synthesize displayName=_displayName,avatarLocalPath=_avatarLocalPath;
- (void)drawRect:(NSRect)r{(void)r;TGDrawTemplateIconAsset(@"user",NSInsetRect([self bounds],8,8),TGClassicCardMutedInkColor(),1,[self isFlipped]);}
- (void)dealloc{[_displayName release];[_avatarLocalPath release];[super dealloc];}
@end
@interface NSObject (ProbePrivate)
- (void)layoutContent;
- (void)applyTransportAvailability;
@end
static NSUInteger Checks;
static void Require(BOOL yes,const char *message){Checks++;if(!yes){fprintf(stderr,"Lists composition: %s\n",message);exit(1);}}
static id V(id c,NSString *key){return [c valueForKey:key];}
static void Check(NSView *root){
 NSMutableArray *controls=[NSMutableArray array];
 for(NSView *v in [root subviews]){
  if([v isHidden])continue;
  if(!NSContainsRect([root bounds],[v frame]))fprintf(stderr,"Outside %s %s parent%s\n",[NSStringFromClass([v class]) UTF8String],[NSStringFromRect([v frame]) UTF8String],[NSStringFromRect([root bounds]) UTF8String]);
  Require(NSContainsRect([root bounds],[v frame]),"every visible root element contained");
  if([v isKindOfClass:[NSControl class]]||[v isKindOfClass:[NSScrollView class]])[controls addObject:v];
  if([v isKindOfClass:[NSButton class]]&&![v isKindOfClass:[NSPopUpButton class]]&&![[((NSButton *)v) cell] isKindOfClass:[TGHeaderIconButtonCell class]]){
   NSButton *button=(NSButton *)v;NSFont *font=[[button cell] isKindOfClass:[TGPrimaryTextButtonCell class]]?[NSFont boldSystemFontOfSize:13]:[NSFont boldSystemFontOfSize:12];
   if(NSWidth([button frame])<[[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width+20)fprintf(stderr,"Short button %s width%g\n",[[button title] UTF8String],NSWidth([button frame]));
   Require(NSWidth([button frame])>=[[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width+20,"localized button text fits");
  }
 }
 for(NSUInteger i=0;i<[controls count];i++)for(NSUInteger j=i+1;j<[controls count];j++){
  NSView *a=[controls objectAtIndex:i],*b=[controls objectAtIndex:j];
  if(NSIntersectsRect([a frame],[b frame]))fprintf(stderr,"Overlap %s %s / %s %s\n",[NSStringFromClass([a class]) UTF8String],[NSStringFromRect([a frame]) UTF8String],[NSStringFromClass([b class]) UTF8String],[NSStringFromRect([b frame]) UTF8String]);
  Require(!NSIntersectsRect([a frame],[b frame]),"visible independent controls never overlap");
 }
}
static void Preview(NSView *root,NSString *name){const char *p=getenv("TG_LISTS_PREVIEW_DIR");if(!p)return;NSBitmapImageRep *rep=[root bitmapImageRepForCachingDisplayInRect:[root bounds]];[root cacheDisplayInRect:[root bounds] toBitmapImageRep:rep];[[rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[[NSString stringWithUTF8String:p] stringByAppendingPathComponent:name] atomically:YES];}
int main(int argc,const char **argv){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];BOOL aqua=argc>1&&strcmp(argv[1],"aqua")==0;
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
 TGCallCoordinator *transport=[[[TGCallCoordinator alloc] init] autorelease];
 TGCallsPlaceholderView *calls=[[[TGCallsPlaceholderView alloc] initWithFrame:NSMakeRect(0,0,760,560) client:nil coordinator:transport] autorelease];
 TGContactsViewController *contacts=[[[TGContactsViewController alloc] initWithClient:nil] autorelease];
 NSDictionary *person=[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic contact with a deliberately long name",@"display_name",@"fixture",@"username",@"Synthetic profile biography",@"bio",nil];
 [V(contacts,@"profileView") showContact:person];
 [calls setValue:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic outgoing call",@"display_name",@YES,@"is_outgoing",@90,@"duration",@1700000000,@"date",nil],[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic missed call",@"display_name",@"callDiscardReasonMissed",@"discard_reason",nil],nil] forKey:@"recentCalls"];
 [V(calls,@"tableView") reloadData];
 for(NSString *lang in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){TGSetLanguageCode(lang);[calls refreshLocalizedText];[contacts refreshLocalizedText];
  if(aqua){TGContactProfileView *profile=V(contacts,@"profileView");Require([[V(profile,@"_usernameTitleField") stringValue] isEqual:TGLoc(@"profile.username")],"open profile field headings follow current language");[profile showLoadingForContact:person];[contacts refreshLocalizedText];Require([[V(profile,@"_statusField") stringValue] isEqual:TGLoc(@"contacts.profileLoading")],"language refresh preserves profile loading state");[profile showError:@"Synthetic error" contact:person];[contacts refreshLocalizedText];Require([[V(profile,@"_statusField") stringValue] isEqual:@"Synthetic error"],"language refresh preserves server error");[profile showContact:person];}
  for(NSNumber *width in [NSArray arrayWithObjects:@420,@620,@719,@720,@980,@420,@980,nil])for(NSNumber *height in [NSArray arrayWithObjects:@420,@560,@760,nil]){
   NSSize size=NSMakeSize([width doubleValue],[height doubleValue]);
   [calls setFrameSize:size];
   [[contacts view] setFrameSize:size];[contacts layoutContent];
   if(!aqua){Require(![V(calls,@"cardView") isHidden],"Classic retains original call card");Require(![V(contacts,@"listCardView") isHidden],"Classic retains original contact card");Require(![[calls viewWithTag:602] isHidden],"Classic retains legacy section heading");}
   if(aqua){Check(calls);Check([contacts view]);
    if(NSWidth([V(calls,@"tableView") frame])>NSWidth([[V(calls,@"historyScrollView") contentView] bounds]))fprintf(stderr,"Table%g viewport%g column%g root%g\n",NSWidth([V(calls,@"tableView") frame]),NSWidth([[V(calls,@"historyScrollView") contentView] bounds]),[[[V(calls,@"tableView") tableColumns] lastObject] width],NSWidth([calls bounds]));
    Require(NSWidth([V(calls,@"tableView") frame])<=NSWidth([[V(calls,@"historyScrollView") contentView] bounds]),"resized call document follows actual viewport width");
    Require([[calls viewWithTag:602] isHidden]&&[V(calls,@"cardView") isHidden],"Aqua has one recent heading and no outer card");
    Require([V(contacts,@"listCardView") isHidden],"Aqua source list is not another rounded card");
    Require([V(calls,@"titleField") font].pointSize==14&&[V(contacts,@"titleField") font].pointSize==14,"both section headings use utility typography");
    if(![V(contacts,@"profileView") isHidden])Check(V(contacts,@"profileView"));
    Available=NO;[calls applyTransportAvailability];Check(calls);Available=YES;[calls applyTransportAvailability];Require([[calls viewWithTag:602] isHidden],"availability cannot restore duplicate heading");
   }
  }
 }
 if(aqua){TGSetLanguageCode(@"ru");[calls refreshLocalizedText];[contacts refreshLocalizedText];[V(contacts,@"profileView") showContact:person];for(NSNumber *width in [NSArray arrayWithObjects:@420,@980,nil]){NSSize size=NSMakeSize([width doubleValue],560);[calls setFrameSize:size];[[contacts view] setFrameSize:size];[contacts layoutContent];Preview(calls,[NSString stringWithFormat:@"calls-%@.png",width]);Preview([contacts view],[NSString stringWithFormat:@"contacts-%@.png",width]);}}
 printf("Lists composition %s: %lu actual constructor/localized geometry checks PASS; no accounts/calls used.\n",aqua?"Aqua":"Classic",(unsigned long)Checks);[pool drain];return 0;}
'''
views='\n'.join(impl('Sources/UI/TGStatusViewCells.m',n) for n in ['TGPanelView','TGGroupedCardView','TGRepresentedObjectCell'])
source=source.replace('__VIEWS__',views)
folder=tempfile.mkdtemp(prefix='telegraphica-lists-composition-')
try:
 app=os.path.join(folder,'Probe.app');mac=os.path.join(app,'Contents','MacOS');resources=os.path.join(app,'Contents','Resources');os.makedirs(mac);os.makedirs(resources);shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(resources,'Icons'))
 path=os.path.join(folder,'probe.m');binary=os.path.join(mac,'probe')
 with open(path,'wb') as f:f.write(source.encode('utf-8'))
 deps=['TGCallsPlaceholderView.m','TGContactsViewController.m','TGContactProfileView.m','TGStatusButtonCells.m','TGButtonAppearance.m','TGIconAssets.m','TGIconDrawing.m','TGAquaAppearance.m','TGTheme.m','TGVisualWorldThemeSpec.m','TGInterfaceDesign.m','TGLocalization.m','TGDialogPresentation.m']
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources',s) for s in ['UI','Core','Calls']]+[path]+[os.path.join(ROOT,'Sources/UI',p) for p in deps]+['-framework','Cocoa','-o',binary])
 for design in ['classic','aqua']:subprocess.check_call([binary,design],env=dict(os.environ,HOME=folder))
finally:shutil.rmtree(folder)
