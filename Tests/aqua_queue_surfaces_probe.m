#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGDownloadCompactPopover.h"
#import "TGScheduledMessagesShelfView.h"
#import "TGScheduledMessagesWindowController.h"
#import "TGDownloadManagerWindowController.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
#import "TGTDLibClient.h"
#import "TGTDLibClient+ScheduledMessages.h"
#import "TGMessageActionDialogs.h"
#import "TGDatePickerDialog.h"
#import "TGDialogPresentation.h"
#import "TGAnimationSupport.h"
#define main ExistingDownloadProbeMain
#include "download_manager_presentation_probe.m"
#undef main

static NSArray *ScheduledFixture;
static NSUInteger ScheduledReads,CapabilityReads,EditCalls;
static BOOL BlockScheduledRead;
static dispatch_semaphore_t ReadGate;
static NSString *EditedOriginal,*EditedValue;
static NSArray *EditedEntities;
static NSUInteger CompactManagerActions;
static NSString *CompactManagerIdentifier;
static void CaptureCompactAction(id self,SEL selector,NSString *identifier) {(void)self;(void)selector;CompactManagerActions++;[CompactManagerIdentifier release];CompactManagerIdentifier=[identifier copy];}
static void CaptureCompactResume(id self,SEL selector,NSString *identifier,TGDownloadCompletionBlock completion) {(void)completion;CaptureCompactAction(self,selector,identifier);}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TGTDLibClient
- (NSDictionary *)sendTDLibRequestAndWaitForExtra:(NSDictionary *)request extraPrefix:(NSString *)prefix timeout:(NSTimeInterval)timeout errorCode:(NSInteger)code error:(NSError **)error {
    (void)prefix;(void)timeout;(void)code;(void)error;
    if([[request objectForKey:@"@type"] isEqual:@"getChatScheduledMessages"]){
        ScheduledReads++;if(BlockScheduledRead)dispatch_semaphore_wait(ReadGate,dispatch_time(DISPATCH_TIME_NOW,10LL*NSEC_PER_SEC));
        return [NSDictionary dictionaryWithObjectsAndKeys:@"messages",@"@type",ScheduledFixture,@"messages",nil];
    }
    Require(NO,"unexpected synthetic TDLib mutation");return nil;
}
- (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code {return [NSError errorWithDomain:@"Probe" code:code userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];}
- (NSString *)messageContentPreviewForObject:(id)content {(void)content;return @"Truncated preview only";}
- (NSDictionary *)messageActionCapabilitiesForChatID:(NSNumber *)chatID messageID:(NSNumber *)messageID timeout:(NSTimeInterval)timeout error:(NSError **)error {(void)chatID;(void)messageID;(void)timeout;(void)error;CapabilityReads++;return [NSDictionary dictionaryWithObject:@YES forKey:@"can_be_edited"];}
- (NSString *)editTextMessageInChatID:(NSNumber *)chatID messageID:(NSNumber *)messageID text:(NSString *)text originalText:(NSString *)original originalEntities:(NSArray *)entities timeout:(NSTimeInterval)timeout error:(NSError **)error {
    (void)chatID;(void)messageID;(void)timeout;(void)error;EditCalls++;[EditedOriginal release];EditedOriginal=[original copy];[EditedValue release];EditedValue=[text copy];[EditedEntities release];EditedEntities=[entities copy];return @"ok";
}
@end
@implementation TGMessageActionDialogs
+ (NSString *)editedTextForCurrentText:(NSString *)text {return [text stringByAppendingString:@" edited"];} // Synthetic dialog only.
@end
@implementation TGDatePickerDialog
+ (NSDate *)dateWithTitle:(NSString *)title help:(NSString *)help actionTitle:(NSString *)actionTitle initialDate:(NSDate *)initialDate minDate:(NSDate *)minDate {(void)title;(void)help;(void)actionTitle;(void)initialDate;(void)minDate;return nil;}
@end
#pragma clang diagnostic pop

@interface TGDownloadCompactPopover (Probe)
- (void)rebuildContent;
- (void)popoverDidClose:(NSNotification *)notification;
@end
@interface TGDownloadManagerWindowController (CompactProbe)
- (void)compactDownloadPerformAction:(NSString *)action identifier:(NSString *)identifier;
@end
@interface TGScheduledMessagesWindowController (ShelfProbe)
- (void)scheduledShelfPerformAction:(NSString *)action messageID:(NSNumber *)messageID;
@end
@interface QueueTarget : NSObject <TGDownloadCompactPopoverTarget,TGScheduledMessagesShelfTarget> { @public NSUInteger downloads,schedules,closed,all,relayouts; }
@end
@implementation QueueTarget
- (void)compactDownloadPerformAction:(NSString *)action identifier:(NSString *)identifier {Require([action length]&&[identifier length],"compact action preserves record identifier");downloads++;}
- (void)compactDownloadShowAll {all++;}
- (void)scheduledLayoutChanged {relayouts++;}
- (void)scheduledShelfPerformAction:(NSString *)action messageID:(NSNumber *)messageID {Require([action length]&&[messageID longLongValue],"shelf action preserves exact message identifier");schedules++;}
- (void)scheduledShelfRequestClose {closed++;}
@end
static void WaitFor(BOOL(^condition)(void)) {
    NSTimeInterval limit=[NSDate timeIntervalSinceReferenceDate]+12;
    while(!condition()&&[NSDate timeIntervalSinceReferenceDate]<limit)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    Require(condition(),"async synthetic deadline");
}
static void CheckSubviews(NSView *view,NSUInteger *buttons) {
    for(NSView *child in [view subviews]){
        if([child isKindOfClass:[NSButton class]]){
            Require(NSContainsRect([view bounds],[child frame]),"queue button stays inside its actual container");(*buttons)++;
            NSButton *button=(NSButton *)child;NSString *title=[button title];
            if([title length])Require([title sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width+16<=NSWidth([button frame]),"localized action fits measured button");
        }
        if([child isKindOfClass:[NSScrollView class]])CheckSubviews([(NSScrollView *)child documentView],buttons);else CheckSubviews(child,buttons);
    }
}
static NSDictionary *Message(NSNumber *identifier,NSString *type,NSString *text) {
    NSDictionary *entity=[NSDictionary dictionaryWithObjectsAndKeys:@0,@"offset",@4,@"length",[NSDictionary dictionaryWithObject:@"textEntityTypeBold" forKey:@"@type"],@"type",nil];
    return [NSDictionary dictionaryWithObjectsAndKeys:identifier,@"id",[NSDictionary dictionaryWithObjectsAndKeys:type,@"@type",[NSDictionary dictionaryWithObjectsAndKeys:text,@"text",[NSArray arrayWithObject:entity],@"entities",nil],@"text",nil],@"content",[NSDictionary dictionaryWithObjectsAndKeys:@"messageSchedulingStateSendAtDate",@"@type",@2000000000,@"send_date",nil],@"scheduling_state",nil];
}
@interface QueueMotionWindow : NSWindow
@end
@implementation QueueMotionWindow
- (BOOL)isVisible {return YES;}
- (BOOL)isMiniaturized {return NO;}
@end
@interface QueueMotionPopover : NSPopover {BOOL _probeShown;NSUInteger _closeCalls;}
@property(nonatomic,assign) BOOL probeShown;
@property(nonatomic,assign) NSUInteger closeCalls;
@end
@implementation QueueMotionPopover
@synthesize probeShown=_probeShown,closeCalls=_closeCalls;
- (BOOL)isShown {return _probeShown;}
- (void)close {_closeCalls++;_probeShown=NO;}
- (void)showRelativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)edge {(void)rect;(void)view;(void)edge;}
@end
static void CheckQueueMotion(QueueTarget *target) {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSDictionary *old=[[defaults volatileDomainForName:NSArgumentDomain] copy];
    NSMutableDictionary *policy=[NSMutableDictionary dictionaryWithDictionary:old];
    [policy setObject:@NO forKey:@"MaverickgramEconomyModeEnabled"];
    [policy setObject:@NO forKey:@"MaverickgramStopAnimationsWhenInactive"];
    [defaults setVolatileDomain:policy forName:NSArgumentDomain];
    QueueMotionWindow *window=[[[QueueMotionWindow alloc] initWithContentRect:NSMakeRect(0,0,700,300) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO];
    TGScheduledMessagesShelfView *shelf=[[[TGScheduledMessagesShelfView alloc] initWithFrame:NSMakeRect(0,0,680,228)] autorelease];
    [[window contentView] addSubview:shelf];[shelf presentAnimated:YES];
    Require(![shelf isHidden] && [shelf alphaValue]<1,"shelf presentation starts existing bounded fade");
    [shelf setFrame:NSMakeRect(0,2,680,220)];Require([shelf alphaValue]==1 && ![shelf isHidden],"shelf geometry change finishes pending fade");
    [shelf presentAnimated:YES];[shelf removeFromSuperview];Require([shelf isHidden] && [shelf alphaValue]==1,"detaching shelf immediately cancels reveal");
    [[window contentView] addSubview:shelf];[shelf presentAnimated:YES];[shelf hideImmediately];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    Require([shelf isHidden] && [shelf alphaValue]==1,"cancelled fade cannot revive dismissed shelf");
    TGDownloadCompactPopover *compact=[[[TGDownloadCompactPopover alloc] initWithTarget:target] autorelease];
    QueueMotionPopover *popover=[[[QueueMotionPopover alloc] init] autorelease];
    [compact setValue:popover forKey:@"popover"];
    [compact setValue:[[[NSViewController alloc] initWithNibName:nil bundle:nil] autorelease] forKey:@"contentController"];
    Require([compact toggleRelativeToView:shelf] && [popover animates],"Downloads animation follows enabled policy");
    [policy setObject:@YES forKey:@"MaverickgramEconomyModeEnabled"];[defaults setVolatileDomain:policy forName:NSArgumentDomain];
    [shelf presentAnimated:YES];Require(![shelf isHidden] && [shelf alphaValue]==1,"Economy mode presents shelf without timer/fade");
    Require([compact toggleRelativeToView:shelf] && ![popover animates],"Downloads reevaluates Economy policy on each presentation");
    [policy setObject:@NO forKey:@"MaverickgramEconomyModeEnabled"];[policy setObject:@YES forKey:@"MaverickgramStopAnimationsWhenInactive"];[defaults setVolatileDomain:policy forName:NSArgumentDomain];
    Require([compact toggleRelativeToView:shelf] && [popover animates]==[NSApp isActive],"Downloads obeys stop-inactive policy");
    NSView *newAnchor=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,40,30)] autorelease];[[window contentView] addSubview:newAnchor];
    [compact close];Require([compact toggleRelativeToView:newAnchor],"popover can reopen before prior animated DidClose");popover.probeShown=YES;
    [compact popoverDidClose:[NSNotification notificationWithName:NSPopoverDidCloseNotification object:popover]];
    Require([compact valueForKey:@"anchor"]==newAnchor,"late close callback preserves reopened anchor");
    NSUInteger closes=popover.closeCalls;[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMiniaturizeNotification object:window];
    Require(popover.closeCalls==closes+1,"reopened popover keeps exactly one parent observer");
    [compact popoverDidClose:[NSNotification notificationWithName:NSPopoverDidCloseNotification object:popover]];
    Require([compact valueForKey:@"anchor"]==nil,"current close clears anchor");
    closes=popover.closeCalls;[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMiniaturizeNotification object:window];
    Require(popover.closeCalls==closes,"current close removes parent observers");
    [compact close];[shelf hideImmediately];[shelf removeFromSuperview];[window close];
    [defaults setVolatileDomain:old forName:NSArgumentDomain];[old release];
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:@"aqua" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];[NSApplication sharedApplication];
    QueueTarget *target=[[[QueueTarget alloc] init] autorelease];NSUInteger layouts=0,buttons=0;
    CheckQueueMotion(target);
    NSArray *rows=[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@11,@"message_id",@"Long scheduled text used for narrow queue layout",@"preview",@"Full editable text",@"editable_text",@2000000000,@"send_date",nil],[NSDictionary dictionaryWithObjectsAndKeys:@12,@"message_id",@"Media preview",@"preview",@YES,@"send_when_online",nil],nil];
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){
        TGSetLanguageCode(language);
        for(NSNumber *width in [NSArray arrayWithObjects:@320,@420,@680,@980,nil]){
            TGScheduledMessagesShelfView *shelf=[[[TGScheduledMessagesShelfView alloc] initWithFrame:NSMakeRect(0,0,[width doubleValue],228)] autorelease];shelf.target=target;[shelf updateWithMessages:rows status:TGLoc(@"scheduled.saved") loading:NO];CheckSubviews(shelf,&buttons);layouts++;
            [shelf updateWithMessages:rows status:TGLoc(@"scheduled.loading") loading:YES];CheckSubviews(shelf,&buttons);layouts++;
        }
        TGDownloadCompactPopover *popover=[[[TGDownloadCompactPopover alloc] initWithTarget:target] autorelease];
        [popover setValue:[[[NSViewController alloc] initWithNibName:nil bundle:nil] autorelease] forKey:@"contentController"];
        [popover setValue:[[[NSPopover alloc] init] autorelease] forKey:@"popover"];
        NSArray *states=[NSArray arrayWithObjects:@"queued",@"downloading",@"paused",@"completed",@"failed",nil];NSMutableArray *downloads=[NSMutableArray array];NSUInteger index=0;
        for(NSString *state in states){NSMutableDictionary *record=[NSMutableDictionary dictionaryWithDictionary:Record(state)];[record setObject:[NSString stringWithFormat:@"row-%lu",(unsigned long)index++] forKey:@"identifier"];if([state isEqual:@"completed"])[record setObject:@"/synthetic/completed.jpg" forKey:@"saved_path"];[record setObject:[NSNumber numberWithBool:![state isEqual:@"completed"]&&![state isEqual:@"failed"]] forKey:@"can_cancel"];[downloads addObject:record];}
        [popover reloadWithItems:downloads];[popover rebuildContent];NSView *body=[[popover valueForKey:@"contentController"] view];CheckSubviews(body,&buttons);Require(NSHeight([body bounds])<=422,"compact download queue caps rows and height");layouts++;
        for(NSDictionary *record in downloads){[popover reloadWithItems:[NSArray arrayWithObject:record]];[popover rebuildContent];CheckSubviews([[popover valueForKey:@"contentController"] view],&buttons);layouts++;}
        Require(![popover toggleRelativeToView:nil],"detached anchor cannot create orphan popover");[popover close];
    }
    Method pauseMethod=class_getInstanceMethod([TGDownloadManager class],@selector(pauseDownloadWithIdentifier:));
    Method resumeMethod=class_getInstanceMethod([TGDownloadManager class],@selector(resumeDownloadWithIdentifier:completion:));
    Method cancelMethod=class_getInstanceMethod([TGDownloadManager class],@selector(cancelDownloadWithIdentifier:));
    IMP originalPause=method_setImplementation(pauseMethod,(IMP)CaptureCompactAction),originalResume=method_setImplementation(resumeMethod,(IMP)CaptureCompactResume),originalCancel=method_setImplementation(cancelMethod,(IMP)CaptureCompactAction);
    NSMutableDictionary *live=[NSMutableDictionary dictionaryWithDictionary:Record(@"downloading")];[live setObject:@"live" forKey:@"identifier"];SetRecords([NSArray arrayWithObject:live]);
    TGDownloadManagerWindowController *manager=[[[TGDownloadManagerWindowController alloc] init] autorelease];
    [manager compactDownloadPerformAction:@"pause" identifier:@"removed"];
    Require(CompactManagerActions==0,"stale compact row cannot route to another transfer");
    [manager compactDownloadPerformAction:@"pause" identifier:@"live"];Require(CompactManagerActions==1 && [CompactManagerIdentifier isEqual:@"live"],"pause routes exact current record");
    [live setObject:@NO forKey:@"can_pause"];SetRecords([NSArray arrayWithObject:live]);[manager compactDownloadPerformAction:@"pause" identifier:@"live"];Require(CompactManagerActions==1,"current capabilities rechecked after stale row display");
    [manager compactDownloadPerformAction:@"resume" identifier:@"live"];[manager compactDownloadPerformAction:@"cancel" identifier:@"live"];Require(CompactManagerActions==3,"resume/cancel preserve existing backend calls and identity");
    method_setImplementation(pauseMethod,originalPause);method_setImplementation(resumeMethod,originalResume);method_setImplementation(cancelMethod,originalCancel);
    TGTDLibClient *client=[[[TGTDLibClient alloc] init] autorelease];ScheduledFixture=[[NSArray alloc] initWithObjects:Message(@11,@"messageText",@"Full editable source with preserved bold"),Message(@12,@"messagePhoto",@"not caption text"),nil];
    NSArray *summaries=[client scheduledMessageSummariesForChatID:@42 timeout:1 error:NULL];Require([[[summaries objectAtIndex:0] objectForKey:@"editable_text"] isEqual:@"Full editable source with preserved bold"] && ![[[summaries objectAtIndex:0] objectForKey:@"preview"] isEqual:[[summaries objectAtIndex:0] objectForKey:@"editable_text"]],"scheduled edit uses full text independent of display preview");Require([[[summaries objectAtIndex:0] objectForKey:@"entities"] count]==1 && [[summaries objectAtIndex:1] objectForKey:@"editable_text"]==nil,"entities preserved and nontext edits unavailable");
    TGScheduledMessagesWindowController *controller=[[[TGScheduledMessagesWindowController alloc] initWithClient:client chatID:@42 title:@"Synthetic chat"] autorelease];
    Require([controller matchesClient:client chatID:@42] && ![controller matchesClient:client chatID:@43],"shelf controller bound to captured chat/client");Require([controller preferredEmbeddedShelfHeight]==120,"empty scheduled shelf uses compact height");
    NSView *host=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,700,400)] autorelease];[host addSubview:[controller embeddedShelfView]];
    [controller setShelfCloseTarget:target action:@selector(scheduledShelfRequestClose)];[controller setShelfLayoutAction:@selector(scheduledLayoutChanged)];
    [controller reloadMessages];WaitFor(^BOOL{return ![[controller valueForKey:@"loading"] boolValue];});
    Require([controller preferredEmbeddedShelfHeight]==228 && target->relayouts>=2,"loaded rows expand shelf and notify owning layout");
    [controller scheduledShelfPerformAction:@"edit" messageID:@11];WaitFor(^BOOL{return ![[controller valueForKey:@"loading"] boolValue];});Require(EditCalls==1 && CapabilityReads==1 && [EditedOriginal isEqual:@"Full editable source with preserved bold"] && [EditedEntities isEqual:[[summaries objectAtIndex:0] objectForKey:@"entities"]] && [EditedValue hasSuffix:@" edited"],"edit rechecks capability and routes original text/entities through existing edit API");
    [controller scheduledShelfPerformAction:@"edit" messageID:@12];Require(EditCalls==1,"media preview cannot be edited as text");
    ReadGate=dispatch_semaphore_create(0);BlockScheduledRead=YES;NSUInteger previousReads=ScheduledReads;[controller reloadMessages];WaitFor(^BOOL{return ScheduledReads>previousReads;});[controller invalidateEmbeddedShelf];[[controller valueForKey:@"statusField"] setStringValue:@"Dismissed marker"];dispatch_semaphore_signal(ReadGate);BlockScheduledRead=NO;
    __block BOOL settled=NO;dispatch_after(dispatch_time(DISPATCH_TIME_NOW,100000000),dispatch_get_main_queue(),^{settled=YES;});WaitFor(^BOOL{return settled;});Require([[controller embeddedShelfView] superview]==nil && [[controller valueForKey:@"embeddedInvalidated"] boolValue] && [[(NSTextField *)[controller valueForKey:@"statusField"] stringValue] isEqual:@"Dismissed marker"],"stale queue reply cannot reattach a dismissed shelf");
    [controller scheduledShelfPerformAction:@"online" messageID:@11];Require(EditCalls==1,"dismissed shelf ignores row actions");
    dispatch_release(ReadGate);[ScheduledFixture release];ScheduledFixture=nil;[EditedOriginal release];[EditedValue release];[EditedEntities release];[CompactManagerIdentifier release];
    printf("Aqua queues: %lu localized compact/wide/loading layouts, %lu button bounds/title checks, 13 motion/reopen policy/lifecycle checks; real summary fulltext/entities, mock edit capability/API, stale reload/dismissal and detached popover guards PASS. No account actions.\n",(unsigned long)layouts,(unsigned long)buttons);
    [pool drain];return 0;
}
