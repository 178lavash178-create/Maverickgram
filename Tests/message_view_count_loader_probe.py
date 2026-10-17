#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Production visible-viewer loader: serialized async ownership, cache and scope."""
from __future__ import print_function
import os, subprocess, sys, tempfile, shutil
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
with open(os.path.join(root,'Sources/UI/TGStatusWindowController+MessageViewCounts.inc'),'rb') as f:
    implementation=f.read().decode('utf-8')
props=[('id','client','retain'),('NSNumber *','profileUserID','retain'),('NSNumber *','selectedChatID','retain'),('NSNumber *','selectedMessageThreadID','retain'),('NSString *','selectedMessageTopicKind','copy'),('NSString *','selectedChatTypeSummary','copy'),('NSMutableArray *','messageItems','retain'),('id','messageTableView','retain'),('id','messageScrollView','retain'),('NSUInteger','automaticReadGeneration','assign'),('BOOL','visible','assign')]
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGMessageItem.h"
static NSMutableArray *Workers,*Completions;
static NSUInteger checks;
static void Require(BOOL yes,const char *why) { checks++;if(!yes){fprintf(stderr,"View-count loader: %s\n",why);exit(1);} }
static void Queue(dispatch_queue_t queue,dispatch_block_t block) { id copied=[block copy];[(queue==dispatch_get_main_queue()?Completions:Workers) addObject:copied];[copied release]; }
static void One(NSMutableArray *queue) {Require([queue count]>0,"queued async operation exists");dispatch_block_t block=[[queue objectAtIndex:0] copy];[queue removeObjectAtIndex:0];block();[block release];}
@interface TGTDLibClient:NSObject
@property(nonatomic) NSUInteger calls;
@property(nonatomic,retain) NSNumber *answer;
@end
@implementation TGTDLibClient
@synthesize calls=_calls,answer=_answer;
- (void)dealloc {[_answer release];[super dealloc];}
- (NSNumber *)messageViewerCountForChatID:(NSNumber *)chat messageID:(NSNumber *)message timeout:(NSTimeInterval)timeout {(void)chat;(void)message;Require(timeout<=2,"viewer lookup has bounded timeout");self.calls++;return self.answer;}
@end
@interface ProbeTable:NSObject
@property(nonatomic) NSRange rows;
@property(nonatomic) NSUInteger heightUpdates;
@property(nonatomic,retain) NSIndexSet *lastHeightRows;
@end
@implementation ProbeTable
@synthesize rows=_rows,heightUpdates=_heightUpdates,lastHeightRows=_lastHeightRows;
- (void)dealloc {[_lastHeightRows release];[super dealloc];}
- (NSRange)rowsInRect:(NSRect)rect {(void)rect;return self.rows;}
- (void)setNeedsDisplay:(BOOL)yes {(void)yes;}
- (void)noteHeightOfRowsWithIndexesChanged:(NSIndexSet *)rows {Require([rows count]<=20,"only actually changed visible message heights are invalidated");self.lastHeightRows=rows;self.heightUpdates++;}
- (id)contentView {return self;}
- (NSRect)bounds {return NSMakeRect(0,0,600,500);}
@end
@interface Probe:NSObject {
__IVARS__
}
__PROPS__
- (void)refreshVisibleMessageViewCounts;
- (BOOL)conversationAllowsAutomaticRead;
@end
@implementation Probe
__SYNTH__
- (void)dealloc {__RELEASES__[super dealloc];}
- (BOOL)conversationAllowsAutomaticRead {return self.visible;}
#define dispatch_async Queue
__IMPLEMENTATION__
#undef dispatch_async
@end
static TGMessageItem *Item(long long identifier) {return [[[TGMessageItem alloc] initWithChatID:@-42 messageID:[NSNumber numberWithLongLong:identifier] date:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] outgoing:YES preview:@"Synthetic"] autorelease];}
static void Drain(void) {NSUInteger attempts=0;while([Workers count]||[Completions count]){Require(++attempts<40,"visible loader converges without unbounded polling");if([Workers count])One(Workers);if([Completions count])One(Completions);Require([Workers count]<=1 && [Completions count]<=1,"one worker and one completion maximum");}}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];Workers=[[NSMutableArray alloc] init];Completions=[[NSMutableArray alloc] init];
 Probe *p=[[[Probe alloc] init] autorelease];TGTDLibClient *client=[[[TGTDLibClient alloc] init] autorelease];client.answer=@3;
 ProbeTable *table=[[[ProbeTable alloc] init] autorelease];table.rows=NSMakeRange(0,20);p.client=client;p.profileUserID=@1;p.selectedChatID=@-42;p.selectedChatTypeSummary=@"Supergroup";p.messageTableView=table;p.messageScrollView=table;p.visible=YES;p.messageItems=[NSMutableArray array];
 for(NSUInteger i=0;i<30;i++)[p.messageItems addObject:Item(i+1)];
 [p refreshVisibleMessageViewCounts];[p refreshVisibleMessageViewCounts];Require([Workers count]==1,"repeated scroll signals cannot queue parallel lookups");Drain();
 Require(client.calls==20,"every eligible visible candidate fetched gradually, never parallel");
 Require([[[p.messageItems objectAtIndex:0] messageViewerCount] isEqual:@3] && [[[p.messageItems objectAtIndex:19] messageViewerCount] isEqual:@3],"only eligible visible items receive server count");
 [p refreshVisibleMessageViewCounts];Require(![Workers count] && client.calls==20,"success TTL prevents network polling");
 Require(![[p.messageItems lastObject] messageViewerCount],"offscreen loaded history creates no viewer request");
 // A history reload creates fresh models: cached readership must reflow all
 // changed visible rows without a second request. The native footer probe
 // separately confirms that this added metadata can force an extra footer row.
 NSMutableArray *fresh=[NSMutableArray array];
 for(TGMessageItem *old in p.messageItems){TGMessageItem *row=[[old copy] autorelease];[row setMessageViewerCount:nil];[row setReactionSummary:@"❤️ 1"];[fresh addObject:row];}
 p.messageItems=fresh;NSUInteger heightsBefore=table.heightUpdates;
 [p refreshVisibleMessageViewCounts];
 Require(client.calls==20 && ![Workers count],"fresh row models reuse TTL cache without a request");
 Require(table.heightUpdates==heightsBefore+1 && [table.lastHeightRows isEqual:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,20)]],"cache replay invalidates every changed visible row height and no offscreen rows");
 [p refreshVisibleMessageViewCounts];Require(table.heightUpdates==heightsBefore+1,"unchanged cache replay does not cause repeated reflow");
 TGMessageItem *copy=[[[p.messageItems objectAtIndex:19] copy] autorelease];Require([[copy messageViewerCount] isEqual:@3],"message copy preserves cached readership");
 NSMutableDictionary *state=objc_getAssociatedObject(p,&TGMessageViewCountStateKey),*cache=[state objectForKey:@"cache"];
 for(NSString *key in [[[cache allKeys] copy] autorelease]){NSDictionary *entry=[cache objectForKey:key];[cache setObject:[NSDictionary dictionaryWithObjectsAndKeys:[entry objectForKey:@"value"],@"value",[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]-61],@"at",nil] forKey:key];}
 [p refreshVisibleMessageViewCounts];Require([Workers count]==1,"expired positive TTL allows explicit subsequent refresh");One(Workers);p.profileUserID=@2;p.automaticReadGeneration++;One(Completions);Require(table.heightUpdates==21,"old account completion cannot relayout or replace current values");Drain();Require(client.calls==41,"new context is not starved by old in-flight request");
 p.visible=NO;NSUInteger before=client.calls;[p refreshVisibleMessageViewCounts];Require(![Workers count] && client.calls==before,"hidden transcript performs no viewer lookup");p.visible=YES;
 p.selectedChatTypeSummary=@"Private";p.profileUserID=@3;[p refreshVisibleMessageViewCounts];Require(![Workers count],"private and self chat never request group readership");
 p.selectedChatTypeSummary=@"Forum topic";p.messageItems=[NSMutableArray arrayWithObject:Item(99)];table.rows=NSMakeRange(0,1);client.answer=nil;[p refreshVisibleMessageViewCounts];Drain();Require(![[p.messageItems lastObject] messageViewerCount],"unsupported or unavailable response stays unknown");before=client.calls;[p refreshVisibleMessageViewCounts];Require(![Workers count] && client.calls==before,"negative TTL prevents unsupported runtime hammering");
 p.profileUserID=@4;client.answer=@0;[p refreshVisibleMessageViewCounts];Drain();Require([[[p.messageItems lastObject] messageViewerCount] isEqual:@0],"confirmed empty viewer list is preserved as known zero");
 p.profileUserID=@5;[[p.messageItems lastObject] setOutgoing:NO];[p refreshVisibleMessageViewCounts];Require(![Workers count],"incoming group messages do not fabricate a viewer capability");
 printf("View-count loader PASS: %lu production ownership/cache/scope checks.\n",(unsigned long)checks);[Workers release];[Completions release];[pool drain];return 0;}
'''
replacements={'__IVARS__':'\n'.join(' %s _%s;'%(t,n) for t,n,a in props),'__PROPS__':'\n'.join('@property(nonatomic,%s) %s %s;'%(a,t,n) for t,n,a in props),'__SYNTH__':'\n'.join('@synthesize %s=_%s;'%(n,n) for t,n,a in props),'__RELEASES__':''.join('[_%s release];'%n for t,n,a in props if a!='assign'),'__IMPLEMENTATION__':implementation}
for token,value in replacements.items():harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-viewer-count-')
try:
 source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
 with open(source,'wb') as f:f.write(harness.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(root,'Sources/Core'),source,os.path.join(root,'Sources/Core/TGMessageItem.m'),'-framework','Cocoa','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
