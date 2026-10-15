#import <Cocoa/Cocoa.h>
#import "TGAquaFolderDrawer.h"
#import "TGAquaShellViews.h"
#include <assert.h>
#include <math.h>
static NSString *Language = @"en";
NSString *TGLanguageCode(void) { return Language; }
NSColor *TGColorFromHex(NSUInteger hex) { return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1]; }
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *ink,CGFloat alpha,BOOL flipped) { (void)name;(void)rect;(void)ink;(void)alpha;(void)flipped; }
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release];[super dealloc]; }
@end
@interface ProbeTarget : NSObject { @public NSUInteger actions,placements; }
- (void)act:(id)sender;
- (void)placement:(NSNotification *)notification;
@end
@implementation ProbeTarget
- (void)act:(id)sender { (void)sender;actions++; }
- (void)placement:(NSNotification *)notification { (void)notification;placements++; }
@end
static void Spin(void) { NSDate *end=[NSDate dateWithTimeIntervalSinceNow:0.5];while([end timeIntervalSinceNow]>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; }
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 NSUInteger cases=0;
 NSRect screens[]={ { {0,0},{1440,900} }, { {-1920,20},{1920,1060} } };
 for(NSUInteger screen=0;screen<2;screen++) for(NSUInteger count=0;count<=64;count++) for(NSUInteger full=0;full<2;full++) {
  NSRect visible=screens[screen];
  NSRect parents[]={ NSMakeRect(NSMinX(visible)+300,100,700,600),NSMakeRect(NSMinX(visible)+20,100,700,600),NSMakeRect(NSMinX(visible)+200,100,NSWidth(visible)-400,600) };
  for(NSUInteger p=0;p<3;p++) {
   TGAquaFolderDrawerGeometry g=TGAquaFolderDrawerPlacement(parents[p],visible,570,count,full);
   BOOL expected=count>0 && !full && p<2;
   assert(g.canShow==expected);
   if(expected) { assert(g.edge==(p==0 ? NSMinXEdge : NSMaxXEdge));assert(g.contentSize.width==240);assert(g.contentSize.height==MIN(554.0,50+count*32.0)); }
   cases++;
  }
 }
 assert(!TGAquaFolderDrawerPlacement(NSZeroRect,NSMakeRect(0,0,1000,800),600,5,NO).canShow);
 assert(!TGAquaFolderDrawerPlacement(NSMakeRect(300,20,600,600),NSMakeRect(0,0,1440,900),97,5,NO).canShow);
 NSUInteger shifts=0;
 for(NSUInteger display=0;display<2;display++) for(NSUInteger full=0;full<2;full++) {
  NSRect visible=screens[display];
  CGFloat widths[]={380,NSWidth(visible)-528,NSWidth(visible)-527,NSWidth(visible)-400,NSWidth(visible)-264,NSWidth(visible)-200,NSWidth(visible)};
  for(NSUInteger w=0;w<7;w++) for(NSUInteger position=0;position<5;position++) {
   CGFloat centerX=NSMidX(visible)-widths[w]/2;
   CGFloat x=position==0 ? NSMinX(visible)+20 : (position==1 ? centerX : (position==2 ? NSMaxX(visible)-widths[w]-20 : centerX+(position==3 ? -17 : 17)));
   NSRect original=NSMakeRect(x,NSMinY(visible)+17,widths[w],600);
   NSRect prepared=TGAquaFolderDrawerPreparedParentFrame(original,visible,full);
   assert(NSEqualSizes(prepared.size,original.size) && prepared.origin.y==original.origin.y);
   if(!NSEqualRects(prepared,original)) {
    assert(!full && widths[w]+264<=NSWidth(visible));
    assert(NSMinX(prepared)>=NSMinX(visible) && NSMaxX(prepared)<=NSMaxX(visible));
    assert(TGAquaFolderDrawerPlacement(prepared,visible,570,5,NO).canShow);
    CGFloat leftDistance=fabs(NSMinX(visible)+264-NSMinX(original));
    CGFloat rightDistance=fabs(NSMaxX(visible)-widths[w]-264-NSMinX(original));
    assert(fabs(fabs(prepared.origin.x-original.origin.x)-MIN(leftDistance,rightDistance))<0.001);
   } else {
    assert(full || widths[w]+264>NSWidth(visible) || NSMinX(original)-NSMinX(visible)>=264 || NSMaxX(visible)-NSMaxX(original)>=264);
   }
   shifts++;
  }
 }
 assert(NSEqualRects(TGAquaFolderDrawerPreparedParentFrame(NSZeroRect,screens[0],NO),NSZeroRect));
 NSRect invalid=NSMakeRect(NAN,0,800,600);assert(isnan(TGAquaFolderDrawerPreparedParentFrame(invalid,screens[0],NO).origin.x));
 NSScreen *screen=[NSScreen mainScreen]; NSRect visible=[screen visibleFrame];
 CGFloat parentWidth=MIN(500.0,NSWidth(visible)-300);
 NSWindow *parent=[[[NSWindow alloc] initWithContentRect:NSMakeRect(NSMinX(visible)+280,NSMinY(visible)+50,parentWidth,400) styleMask:NSTitledWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
 [parent setReleasedWhenClosed:NO];[parent orderFront:nil];
 NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSMakeRect(4,4,200,100)] autorelease];[scroll setHasVerticalScroller:YES];[scroll setHasHorizontalScroller:NO];
 NSView *document=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,180,500)] autorelease];[scroll setDocumentView:document];[[parent contentView] addSubview:scroll];
 ProbeTarget *target=[[[ProbeTarget alloc] init] autorelease];
 NSMutableArray *buttons=[NSMutableArray array];
 for(NSUInteger i=0;i<12;i++) { NSButton *button=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[button setTag:i+10];[button setTarget:target];[button setAction:@selector(act:)];[document addSubview:button];[buttons addObject:button]; }
 NSRect inlineFrame=[scroll frame];
 TGAquaFolderDrawer *helper=[[TGAquaFolderDrawer alloc] initWithParentWindow:parent folderScrollView:scroll editTarget:target editAction:@selector(act:)];
 [[NSNotificationCenter defaultCenter] addObserver:target selector:@selector(placement:) name:TGAquaFolderDrawerPlacementDidChangeNotification object:helper];
 [helper setFolderButtons:buttons];[helper layout];
 assert([scroll superview]==[parent contentView] && NSEqualRects([scroll frame],inlineFrame));
 NSRect centered=[parent frame];centered.origin.x=NSMinX(visible)+200;centered.size.width=NSWidth(visible)-400;
 [parent setFrame:centered display:YES];[helper layout];
 assert(![helper canShowExternally]);
 assert([helper prepareToOpen] && ![helper isOpen]);
 NSRect prepared=[parent frame];
 assert(prepared.origin.x==NSMinX(visible)+264 && NSEqualSizes(prepared.size,centered.size) && prepared.origin.y==centered.origin.y);
 [helper setVisible:YES];Spin();
 assert([helper isOpen] && [scroll superview]==[helper contentView]);
 assert([[helper drawer] parentWindow]==parent);
 for(NSUInteger i=0;i<[buttons count];i++) { NSButton *button=[buttons objectAtIndex:i]; assert([button tag]==i+10 && [button target]==target && [button action]==@selector(act:));assert(NSHeight([button frame])==32 && NSMinY([button frame])==i*32); }
 [[buttons objectAtIndex:0] performClick:nil];assert(target->actions==1);

 CGFloat originalHeight=[helper.drawer contentSize].height;
 [helper setFolderButtons:[buttons subarrayWithRange:NSMakeRange(0,1)]];[helper layout];Spin();
 assert([helper.drawer contentSize].height==82 && originalHeight>82);
 NSUInteger notifications=target->placements;[helper layout];[helper layout];assert(target->placements==notifications);
 NSRect originalFrame=[parent frame];
 [parent setFrameOrigin:NSMakePoint(NSMinX(visible)+20,NSMinY(originalFrame))];Spin();
 assert([helper canShowExternally] && [helper isOpen] && [helper.drawer edge]==NSMaxXEdge);
 assert(target->placements==notifications);
 [parent setFrame:NSMakeRect(NSMinX(visible)+8,NSMinY(originalFrame),NSWidth(visible)-16,NSHeight(originalFrame)) display:YES];Spin();
 assert(![helper canShowExternally] && ![helper isOpen] && target->placements==notifications+1);
 [parent setFrame:originalFrame display:YES];Spin();
 assert([helper canShowExternally] && [helper isOpen] && target->placements==notifications+2);
 [parent close];Spin();assert(![helper isOpen]);
 NSRect hiddenFrame=[parent frame];assert(![helper prepareToOpen] && NSEqualRects(hiddenFrame,[parent frame]));
 [helper setVisible:YES];Spin();assert(![helper isOpen] && ![parent isVisible]);
 [parent orderFront:nil];[helper setVisible:YES];Spin();
 assert([helper isOpen] && [helper.drawer parentWindow]==parent);
 Language=@"ru";[helper refreshLocalization];
 [helper detachFolderScrollView];Spin();assert(![helper isOpen] && ![scroll superview]);
 [[parent contentView] addSubview:scroll];
 [[NSNotificationCenter defaultCenter] removeObserver:target];
 [helper release];assert([scroll superview]==[parent contentView]);
 [parent close];Spin();
 printf("Aqua native folder drawer: %lu placement cases,%lu explicit shift cases; real NSDrawer open/close, capped rows, same button actions, no inline mutation, detachment/ownership PASS.\n",(unsigned long)cases,(unsigned long)shifts);
 [pool drain];return 0;
}
