#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Production one-time Aqua offer: no real dialog, defaults mutation or restart."""
from __future__ import print_function
import os, subprocess, sys, tempfile, shutil
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
with open(os.path.join(root,'Sources/UI/TGStatusWindowController+AquaSuggestion.inc'),'rb') as f:
    implementation=f.read().decode('utf-8')
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
static NSUInteger checks,alerts;
static BOOL Aqua;
static NSInteger answer;
static dispatch_block_t DuringAlert;
static void Require(BOOL yes,const char *why){checks++;if(!yes){fprintf(stderr,"Aqua suggestion: %s\n",why);exit(1);}}
static BOOL TGInterfaceDesignIsAqua(void){return Aqua;}
static NSString *TGLoc(NSString *key){return key;}
@interface ProbeDefaults:NSObject
@property(nonatomic,retain) NSMutableDictionary *values;
+ (id)standardUserDefaults;
@end
@implementation ProbeDefaults
@synthesize values=_values;
+ (id)standardUserDefaults {static ProbeDefaults *defaults;if(!defaults){defaults=[[self alloc] init];defaults.values=[NSMutableDictionary dictionary];}return defaults;}
- (BOOL)boolForKey:(NSString *)key{return [[self.values objectForKey:key] boolValue];}
- (void)setBool:(BOOL)value forKey:(NSString *)key{[self.values setObject:[NSNumber numberWithBool:value] forKey:key];}
- (BOOL)synchronize{return YES;}
- (void)dealloc{[_values release];[super dealloc];}
@end
@interface ProbeApp:NSObject
@property(nonatomic) BOOL active;
@property(nonatomic,retain) id modalWindow;
@end
@implementation ProbeApp
@synthesize active=_active,modalWindow=_modalWindow;
- (BOOL)isActive{return self.active;}
- (void)dealloc{[_modalWindow release];[super dealloc];}
@end
static ProbeApp *TestApp;
@interface ProbeWindow:NSObject
@property(nonatomic) BOOL visible,miniaturized,liveResize;
@property(nonatomic,retain) id attachedSheet;
@end
@implementation ProbeWindow
@synthesize visible=_visible,miniaturized=_miniaturized,liveResize=_liveResize,attachedSheet=_attachedSheet;
- (BOOL)isVisible{return self.visible;}
- (BOOL)isMiniaturized{return self.miniaturized;}
- (BOOL)inLiveResize{return self.liveResize;}
- (void)dealloc{[_attachedSheet release];[super dealloc];}
@end
@interface ProbeField:NSObject
@property(nonatomic,copy) NSString *stringValue;
@end
@implementation ProbeField
@synthesize stringValue=_stringValue;
- (void)dealloc{[_stringValue release];[super dealloc];}
@end
@interface ProbeAlert:NSObject
@property(nonatomic,copy) NSString *messageText,*informativeText;
@property(nonatomic,retain) NSMutableArray *buttons;
@end
@implementation ProbeAlert
@synthesize messageText=_messageText,informativeText=_informativeText,buttons=_buttons;
- (id)init{if((self=[super init]))self.buttons=[NSMutableArray array];return self;}
- (void)addButtonWithTitle:(NSString *)title{[self.buttons addObject:title];}
- (void)dealloc{[_messageText release];[_informativeText release];[_buttons release];[super dealloc];}
@end
@interface ProbeRoute:NSObject
@property(nonatomic) NSInteger tag;
@end
@implementation ProbeRoute
@synthesize tag=_tag;
- (id)initWithFrame:(NSRect)rect{(void)rect;return [self init];}
@end
static NSInteger RunAlert(ProbeAlert *alert,NSWindow *window){
 Require(window!=nil,"offer is attached to its owner");
 Require([alert.messageText isEqual:@"aqua.offer.title"] && [alert.informativeText isEqual:@"aqua.offer.message"],"localized explanatory copy is used");
 Require([alert.buttons isEqual:[NSArray arrayWithObjects:@"aqua.offer.open",@"aqua.offer.later",nil]],"offer has explicit open-settings and later choices");
 alerts++;if(DuringAlert)DuringAlert();return answer;
}
@interface Probe:NSObject
@property(nonatomic,copy) NSString *currentAuthState;
@property(nonatomic,retain) ProbeWindow *owner;
@property(nonatomic,retain) ProbeField *sendTextField;
@property(nonatomic) BOOL controlsBusy;
@property(nonatomic) NSUInteger scheduled,routes;
@property(nonatomic) NSInteger routeTag;
- (NSWindow *)window;
- (void)queueAquaSuggestionIfNeeded;
- (void)offerAquaSuggestion;
@end
@implementation Probe
@synthesize currentAuthState=_currentAuthState,owner=_owner,sendTextField=_sendTextField,controlsBusy=_controlsBusy,scheduled=_scheduled,routes=_routes,routeTag=_routeTag;
- (void)dealloc{[_currentAuthState release];[_owner release];[_sendTextField release];[super dealloc];}
- (NSWindow *)window{return (NSWindow *)self.owner;}
- (void)performSelector:(SEL)selector withObject:(id)object afterDelay:(NSTimeInterval)delay{Require(selector==@selector(offerAquaSuggestion)&&object==nil&&delay==3,"only one delayed safe offer is scheduled");self.scheduled++;}
- (void)navigationChanged:(id)sender{self.routes++;self.routeTag=[sender tag];}
#define NSUserDefaults ProbeDefaults
#undef NSApp
#define NSApp TestApp
#define NSAlert ProbeAlert
#define NSButton ProbeRoute
#define TGRunAlert RunAlert
__IMPLEMENTATION__
#undef NSUserDefaults
#undef NSApp
#undef NSAlert
#undef NSButton
#undef TGRunAlert
@end
static void Reset(Probe *p){
 [[[ProbeDefaults standardUserDefaults] values] removeAllObjects];
 objc_setAssociatedObject(p,@selector(offerAquaSuggestion),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
 p.currentAuthState=@"ready";p.controlsBusy=NO;p.sendTextField.stringValue=@"";p.owner.visible=YES;p.owner.miniaturized=NO;p.owner.liveResize=NO;p.owner.attachedSheet=nil;
 TestApp.active=YES;TestApp.modalWindow=nil;Aqua=NO;DuringAlert=nil;answer=NSAlertSecondButtonReturn;
 p.scheduled=0;p.routes=0;alerts=0;
}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];TestApp=[[ProbeApp alloc] init];Probe *p=[[[Probe alloc] init] autorelease];p.owner=[[[ProbeWindow alloc] init] autorelease];p.sendTextField=[[[ProbeField alloc] init] autorelease];Reset(p);
 [p queueAquaSuggestionIfNeeded];[p queueAquaSuggestionIfNeeded];Require(p.scheduled==1 && objc_getAssociatedObject(p,@selector(offerAquaSuggestion))!=nil,"repeated layout/auth events retain one pending offer");
 [p offerAquaSuggestion];Require(alerts==1 && p.routes==0 && [[ProbeDefaults standardUserDefaults] boolForKey:TGAquaSuggestionSeenKey],"Later consumes offer once without changing design or route");
 [p queueAquaSuggestionIfNeeded];[p offerAquaSuggestion];Require(alerts==1 && p.scheduled==1,"seen offer never repeats");
 Reset(p);Aqua=YES;[p queueAquaSuggestionIfNeeded];Require(p.scheduled==0,"current Aqua users are not prompted");
 Reset(p);p.currentAuthState=@"waitCode";[p queueAquaSuggestionIfNeeded];Require(p.scheduled==0,"unauthorized users are not scheduled");
 for(NSUInteger guard=0;guard<11;guard++){
  Reset(p);[p queueAquaSuggestionIfNeeded];
  if(guard==0)p.currentAuthState=@"closing";
  if(guard==1)TestApp.active=NO;
  if(guard==2)p.owner.visible=NO;
  if(guard==3)p.owner.miniaturized=YES;
  if(guard==4)p.owner.liveResize=YES;
  if(guard==5)p.owner.attachedSheet=@1;
  if(guard==6)TestApp.modalWindow=@1;
  if(guard==7)p.controlsBusy=YES;
  if(guard==8)p.sendTextField.stringValue=@"Unsent synthetic draft";
  if(guard==9)Aqua=YES;
  if(guard==10)[[ProbeDefaults standardUserDefaults] setBool:YES forKey:TGAquaSuggestionSeenKey];
  [p offerAquaSuggestion];Require(alerts==0 && p.routes==0,"guard prevents an intrusive dialog or navigation");
  Require(objc_getAssociatedObject(p,@selector(offerAquaSuggestion))==nil,"deferred guard releases pending scheduling ownership");
  if(guard!=10)Require(![[ProbeDefaults standardUserDefaults] boolForKey:TGAquaSuggestionSeenKey],"blocked offer is not falsely marked as displayed");
 }
 Reset(p);answer=NSAlertFirstButtonReturn;[p offerAquaSuggestion];Require(alerts==1 && p.routes==1 && p.routeTag==3 && !Aqua,"accept opens existing Settings route without switching or restarting automatically");
 Reset(p);answer=NSAlertFirstButtonReturn;DuringAlert=^{p.currentAuthState=@"closing";};[p offerAquaSuggestion];Require(alerts==1 && p.routes==0,"authorization loss during modal loop prevents stale settings route");
 Reset(p);p.sendTextField.stringValue=@"Draft";[p queueAquaSuggestionIfNeeded];[p offerAquaSuggestion];p.sendTextField.stringValue=@"";[p queueAquaSuggestionIfNeeded];Require(p.scheduled==2,"once draft guard clears, a later safe UI event can schedule offer again");[p offerAquaSuggestion];Require(alerts==1,"postponed offer eventually appears in idle safe context");
 printf("Aqua suggestion PASS: %lu production guards/once/routing checks, in-memory defaults only.\n",(unsigned long)checks);DuringAlert=nil;[TestApp release];[pool drain];return 0;}
'''
harness=harness.replace('__IMPLEMENTATION__',implementation)
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-offer-')
try:
 source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
 with open(source,'wb') as f:f.write(harness.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+[source,'-framework','Cocoa','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
