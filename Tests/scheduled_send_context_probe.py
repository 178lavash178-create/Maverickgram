#!/usr/bin/env python
"""Run the production scheduling action against modal-time context changes; no TDLib."""
from __future__ import print_function
import os, subprocess, tempfile, shutil
root=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
with open(os.path.join(root,'Sources/UI/TGStatusWindowController+ComposerMedia.inc'),'rb') as f:
    source=f.read().decode('utf-8')
a=source.index('- (void)scheduleMessage:');b=source.index('\n- (void)sendMessageWithOptions:',a)
method=source[a:b]
harness=r'''
#import <Cocoa/Cocoa.h>
static void (^DuringPicker)(void); static BOOL Cancel,Invalid; static NSUInteger PickerCalls,Checks;
static void Check(BOOL value,const char *reason){Checks++;if(!value){fprintf(stderr,"Schedule context: %s\n",reason);exit(1);}}
NSString *TGLoc(NSString *key){return key;}
@interface ProbeControl:NSObject
@property(nonatomic) BOOL enabled;
@property(nonatomic,copy) NSString *stringValue;
- (BOOL)isEnabled;
@end
@implementation ProbeControl
@synthesize enabled,stringValue;
- (BOOL)isEnabled{return self.enabled;}
- (void)dealloc{[stringValue release];[super dealloc];}
@end
@interface TGDatePickerDialog:NSObject
+ (NSDate *)dateWithTitle:(NSString *)title help:(NSString *)help actionTitle:(NSString *)action initialDate:(NSDate *)initial minDate:(NSDate *)minimum;
@end
@implementation TGDatePickerDialog
+ (NSDate *)dateWithTitle:(NSString *)title help:(NSString *)help actionTitle:(NSString *)action initialDate:(NSDate *)initial minDate:(NSDate *)minimum{
    (void)title;(void)help;(void)action;(void)initial;(void)minimum;PickerCalls++;
    if(DuringPicker)DuringPicker();return Cancel?nil:[NSDate dateWithTimeIntervalSinceNow:Invalid?0:3600];
}
@end
@interface ScheduleRoot:NSObject
@property(nonatomic,retain) id client,replyTargetMessageItem;
@property(nonatomic,retain) NSNumber *selectedChatID,*selectedMessageThreadID,*replyTargetChatID;
@property(nonatomic,copy) NSString *selectedMessageTopicKind,*activeSection,*currentAuthState;
@property(nonatomic,retain) ProbeControl *sendMessageButton,*sendTextField,*statusField;
@property(nonatomic) NSUInteger sends;
@end
@implementation ScheduleRoot
@synthesize client,replyTargetMessageItem,selectedChatID,selectedMessageThreadID,replyTargetChatID,selectedMessageTopicKind,activeSection,currentAuthState,sendMessageButton,sendTextField,statusField,sends;
- (id)init{self=[super init];if(self){self.client=[[[NSObject alloc] init] autorelease];self.selectedChatID=@42;self.activeSection=@"chats";self.currentAuthState=@"ready";self.sendMessageButton=[[[ProbeControl alloc] init] autorelease];self.sendMessageButton.enabled=YES;self.sendTextField=[[[ProbeControl alloc] init] autorelease];self.sendTextField.stringValue=@"Synthetic draft";self.statusField=[[[ProbeControl alloc] init] autorelease];}return self;}
- (void)sendMessageWithOptions:(NSDictionary *)options{Check([[options objectForKey:@"schedule_date"] integerValue]>(NSInteger)[[NSDate date] timeIntervalSince1970]+30,"only a valid future date reaches send");self.sends++;}
__METHOD__
- (void)dealloc{[client release];[replyTargetMessageItem release];[selectedChatID release];[selectedMessageThreadID release];[replyTargetChatID release];[selectedMessageTopicKind release];[activeSection release];[currentAuthState release];[sendMessageButton release];[sendTextField release];[statusField release];[super dealloc];}
@end
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    ScheduleRoot *root=[[[ScheduleRoot alloc] init] autorelease];[root scheduleMessage:nil];Check(root.sends==1,"unchanged context confirms once");
    for(NSString *key in [NSArray arrayWithObjects:@"client",@"selectedChatID",@"selectedMessageThreadID",@"selectedMessageTopicKind",@"activeSection",@"replyTargetMessageItem",@"replyTargetChatID",@"currentAuthState",nil]){
        root=[[[ScheduleRoot alloc] init] autorelease];id replacement=@43;
        if([key isEqual:@"client"]||[key isEqual:@"replyTargetMessageItem"])replacement=[[[NSObject alloc] init] autorelease];
        if([key isEqual:@"activeSection"]||[key isEqual:@"selectedMessageTopicKind"]||[key isEqual:@"currentAuthState"])replacement=@"changed";
        DuringPicker=^{[root setValue:replacement forKey:key];};[root scheduleMessage:nil];Check(root.sends==0,"modal context change never schedules into replacement context");DuringPicker=nil;
    }
    root=[[[ScheduleRoot alloc] init] autorelease];DuringPicker=^{root.sendTextField.stringValue=@"Replacement draft";};[root scheduleMessage:nil];Check(root.sends==0,"replacement draft is not sent");DuringPicker=nil;
    root=[[[ScheduleRoot alloc] init] autorelease];DuringPicker=^{root.sendMessageButton.enabled=NO;};[root scheduleMessage:nil];Check(root.sends==0,"revoked composer permission prevents confirmation");DuringPicker=nil;
    root=[[[ScheduleRoot alloc] init] autorelease];root.sendMessageButton.enabled=NO;NSUInteger before=PickerCalls;[root scheduleMessage:nil];Check(PickerCalls==before && root.sends==0,"disabled action never opens picker");
    root=[[[ScheduleRoot alloc] init] autorelease];Cancel=YES;[root scheduleMessage:nil];Check(root.sends==0 && [root.sendTextField.stringValue isEqual:@"Synthetic draft"],"Cancel keeps draft and performs no send");Cancel=NO;Invalid=YES;[root scheduleMessage:nil];Check(root.sends==0,"expired date never sends");Invalid=NO;[root scheduleMessage:nil];Check(root.sends==1,"valid retry after cancellation or expired date still works");
    printf("Schedule context: %lu modal mutation, cancellation, permission and retry checks PASS.\n",(unsigned long)Checks);[pool drain];return 0;}
'''
build=tempfile.mkdtemp(prefix='telegraphica-schedule-context-')
try:
    path=os.path.join(build,'probe.m')
    with open(path,'wb') as f:f.write(harness.replace('__METHOD__',method).encode('utf-8'))
    clang=os.environ.get('CLANG') or subprocess.check_output(['xcrun','--find','clang']).decode('utf-8').strip()
    command=[clang,'-fblocks','-fno-objc-arc','-arch',os.environ.get('TELEGRAPHICA_TEST_ARCH','x86_64'),'-mmacosx-version-min='+os.environ.get('TELEGRAPHICA_TEST_DEPLOYMENT_TARGET','10.8'),path,'-framework','Cocoa','-o',os.path.join(build,'probe')]
    subprocess.check_call(command);subprocess.check_call([os.path.join(build,'probe')])
finally:shutil.rmtree(build)
