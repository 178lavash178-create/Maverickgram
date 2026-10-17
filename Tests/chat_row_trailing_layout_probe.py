#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Actual chat-row renderer: stable trailing columns and non-overlapping titles."""
from __future__ import print_function, unicode_literals
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
base_path=os.path.join(ROOT,'Tests/aqua_chat_row_selection_probe.py')
with open(base_path,'rb') as handle:base=handle.read().decode('utf-8')
namespace={'__file__':base_path,'__name__':'chat_row_layout_fixture'}
eval(compile(base[:base.index("folder=tempfile.mkdtemp(")],base_path,'exec'),namespace)
harness=namespace['harness']
harness=harness[:harness.index('int main(int argc,const char **argv) {')]
harness=harness.replace('name,@"name",ink,@"ink",nil','name,@"name",ink,@"ink",[NSValue valueWithRect:rect],@"rect",nil',1)
harness+=r'''
static NSUInteger Checks,Renders;
static void Require(BOOL value,const char *reason){Checks++;if(!value){fprintf(stderr,"Chat row trailing layout: %s\n",reason);exit(1);}}
static NSRect RowMarker(NSString *name){for(NSDictionary *marker in Markers)if([[marker objectForKey:@"name"] isEqual:name])return [[marker objectForKey:@"rect"] rectValue];return NSZeroRect;}
static BOOL ClearOf(NSRect a,NSRect b){return NSIsEmptyRect(a)||NSIsEmptyRect(b)||!NSIntersectsRect(a,b);}
static void CheckGeometry(void){
 for(CGFloat width=223;width<=620;width+=7)for(CGFloat height=32;height<=40;height+=4)for(NSUInteger unread=0;unread<4;unread++)for(NSUInteger flags=0;flags<4;flags++)for(NSUInteger identity=0;identity<4;identity++){
  NSRect frame=NSMakeRect(7,4,width,height),avatar=NSMakeRect(15,4+floor((height-26)/2),26,26);
  CGFloat badgeWidths[]={0,10,20,40};CGFloat badgeHeight=unread==1?10:(unread?18:0);
  TGChatListRowGeometry g=TGChatListRowFrames(frame,avatar,badgeWidths[unread],badgeHeight,flags&1,flags&2,identity&1,identity&2?64:0);
  Require(NSContainsRect(frame,g.title)&&NSWidth(g.title)>=40,"regular row preserves usable title width at 223 pt and wider");
  Require(NSMinX(g.pin)==NSMaxX(frame)-89 && NSMinX(g.mute)==NSMaxX(frame)-71,"pin and mute stay in exact columns for every badge/identity state");
  Require(fabs(NSMidY(g.pin)-NSMidY(frame))<=.5&&fabs(NSMidY(g.mute)-NSMidY(frame))<=.5,"trailing markers remain vertically centered on crisp pixel positions");
  Require(ClearOf(g.title,g.bot)&&ClearOf(g.title,g.community)&&ClearOf(g.bot,g.community),"identity markers never overlap title or each other");
  if(flags&1)Require(ClearOf(g.title,g.pin)&&ClearOf(g.bot,g.pin)&&ClearOf(g.community,g.pin)&&ClearOf(g.unread,g.pin),"pinned row reserves complete pin column");
  if(flags&2)Require(ClearOf(g.title,g.mute)&&ClearOf(g.bot,g.mute)&&ClearOf(g.community,g.mute)&&ClearOf(g.unread,g.mute),"muted row reserves complete mute column");
  if(unread)Require(NSContainsRect(frame,g.unread)&&ClearOf(g.title,g.unread)&&ClearOf(g.bot,g.unread)&&ClearOf(g.community,g.unread),"numeric badge and manual dot coexist without overlap");
  if(!unread&&!flags&&!identity)Require(NSMaxX(g.title)==NSMaxX(frame)-9,"rows without indicators retain full available title width");
 }
}
static void CheckActualRows(BOOL aqua){
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){
  TGSetLanguageCode(language);
  for(NSNumber *number in [NSArray arrayWithObjects:@223,@240,@292,@320,@480,nil])for(NSUInteger flip=0;flip<2;flip++)for(NSUInteger titleCase=0;titleCase<2;titleCase++)for(NSUInteger unread=0;unread<4;unread++)for(NSUInteger flags=0;flags<4;flags++){
   CGFloat width=[number doubleValue];NSRect frame=NSMakeRect(7,4,width,36),bounds=NSMakeRect(0,0,width+14,44);
   NSString *title=titleCase?([language isEqual:@"en"]?@"A very long synthetic group title that must truncate safely":@"Очень длинное название беседы, которое должно аккуратно сокращаться"):@"A";
   NSNumber *counts[]={@0,@1,@99,@9999};TGChatItem *item=[[[TGChatItem alloc] initWithChatID:@42 title:title typeSummary:@"Private" unreadCount:counts[unread]] autorelease];
   item.pinned=flags&1;item.notificationsMuted=flags&2;item.bot=titleCase;item.community=titleCase&&unread==3;
   NSView *view=flip?[[[FlippedRowView alloc] initWithFrame:bounds] autorelease]:[[[NSView alloc] initWithFrame:bounds] autorelease];
   TGChatListCell *cell=[[[TGChatListCell alloc] initTextCell:@""] autorelease];cell.chatItem=item;[cell setHighlighted:unread&1];
   [Texts removeAllObjects];[Inks removeAllObjects];[Frames removeAllObjects];[Markers removeAllObjects];
   NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:NSWidth(bounds) pixelsHigh:NSHeight(bounds) bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
   [NSGraphicsContext saveGraphicsState];NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flip]];
   if(flip){NSAffineTransform *transform=[NSAffineTransform transform];[transform translateXBy:0 yBy:NSHeight(bounds)];[transform scaleXBy:1 yBy:-1];[transform concat];}
   [cell drawWithFrame:frame inView:view];[NSGraphicsContext restoreGraphicsState];
   NSUInteger titleIndex=[Texts indexOfObject:title];Require(titleIndex!=NSNotFound,"actual renderer paints selected short/long title");NSRect titleRect=[[Frames objectAtIndex:titleIndex] rectValue];
   Require(NSContainsRect(frame,titleRect)&&NSWidth(titleRect)>=40,"actual title rectangle remains readable inside row");
   NSRect pin=RowMarker(@"flag-triangle"),mute=RowMarker(@"sound-off");
   Require(NSIsEmptyRect(pin)==!item.pinned&&NSIsEmptyRect(mute)==!item.notificationsMuted,"renderer preserves exact pin/mute visibility");
   if(item.pinned)Require(NSMinX(pin)==NSMaxX(frame)-89 && ClearOf(titleRect,pin),"actual pin is independent of title length and unread width");
   if(item.notificationsMuted)Require(NSMinX(mute)==NSMaxX(frame)-71 && ClearOf(titleRect,mute),"actual mute is independent of title length and unread width");
   Require(ClearOf(pin,mute),"simultaneous pin and mute do not overlap");
   NSString *badge=unread==3?@"999+":(unread==2?@"99":(unread==1?@"1":nil));
   if(badge){NSUInteger index=[Texts indexOfObject:badge];Require(index!=NSNotFound,"actual unread badge remains visible");NSRect badgeRect=[[Frames objectAtIndex:index] rectValue];Require(ClearOf(badgeRect,pin)&&ClearOf(badgeRect,mute)&&ClearOf(badgeRect,titleRect),"actual badge text cannot collide with title or trailing icons");}
   Renders++;
  }
 }
}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 Texts=[NSMutableArray array];Inks=[NSMutableArray array];Frames=[NSMutableArray array];Markers=[NSMutableArray array];
 Require(TGIconAssetImageNamed(@"flag-triangle")&&TGIconAssetImageNamed(@"sound-off"),"unchanged approved assets are available");
 method_exchangeImplementations(class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:)),class_getInstanceMethod([NSString class],@selector(tgRowDrawInRect:withAttributes:)));
 CheckGeometry();CheckActualRows(YES);CheckActualRows(NO);
 method_exchangeImplementations(class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:)),class_getInstanceMethod([NSString class],@selector(tgRowDrawInRect:withAttributes:)));
 printf("Chat row trailing layout: %lu geometry/production checks, %lu actual row renders; RU/BE/EN, short/long title, 223-620pt, pin/mute/unread combinations, Classic/Aqua and both orientations PASS.\n",(unsigned long)Checks,(unsigned long)Renders);[pool drain];return 0;}
'''
folder=tempfile.mkdtemp(prefix='telegraphica-chat-row-columns-')
try:
    app=os.path.join(folder,'Probe.app');macos=os.path.join(app,'Contents','MacOS');resources=os.path.join(app,'Contents','Resources')
    os.makedirs(macos);os.makedirs(resources);shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(resources,'Icons'))
    source=os.path.join(folder,'probe.m');binary=os.path.join(macos,'probe')
    with open(source,'wb') as handle:handle.write(harness.encode('utf-8'))
    ui=os.path.join(ROOT,'Sources/UI');core=os.path.join(ROOT,'Sources/Core')
    dependencies=['Sources/Core/TGChatItem.m','Sources/UI/TGChatUnreadBadgeAppearance.m','Sources/UI/TGLocalization.m','Sources/UI/TGTheme.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGDialogPresentation.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGVisualWorldThemeSpec.m']
    subprocess.check_call(sys.argv[1:]+['-I'+ui,'-I'+core,source]+[os.path.join(ROOT,path) for path in dependencies]+['-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:shutil.rmtree(folder)
