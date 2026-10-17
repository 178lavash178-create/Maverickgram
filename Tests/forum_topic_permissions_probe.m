#import <Foundation/Foundation.h>
#import "TGForumTopicPermissions.h"
#import "TGTDLibClient+ForumTopics.h"
static NSUInteger Checks;
static void Check(BOOL value,const char *reason) { Checks++; if(!value){fprintf(stderr,"Forum permissions: %s\n",reason);exit(1);} }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TGTDLibClient
@end
#pragma clang diagnostic pop
@interface ForumClient:TGTDLibClient
@property(nonatomic,copy) NSDictionary *status,*chatPermissions,*topicInfo;
@property(nonatomic,retain) NSMutableArray *requests;
@property(nonatomic) BOOL missingTopic;
@end
@implementation ForumClient
@synthesize status,chatPermissions,topicInfo,requests,missingTopic;
- (id)init{if((self=[super init]))self.requests=[NSMutableArray array];return self;}
- (void)dealloc{[status release];[chatPermissions release];[topicInfo release];[requests release];[super dealloc];}
- (NSError *)errorWithDescription:(NSString *)text code:(NSInteger)code{return [NSError errorWithDomain:@"fixture" code:code userInfo:[NSDictionary dictionaryWithObject:text forKey:NSLocalizedDescriptionKey]];}
- (NSDictionary *)sendTDLibRequestAndWaitForExtra:(NSDictionary *)request extraPrefix:(NSString *)extra timeout:(NSTimeInterval)timeout errorCode:(NSInteger)code error:(NSError **)error{
    (void)extra;(void)timeout;(void)code;(void)error;[requests addObject:request];NSString *type=[request objectForKey:@"@type"];
    if([type isEqual:@"getChat"])return [NSDictionary dictionaryWithObjectsAndKeys:@"chat",@"@type",[NSDictionary dictionaryWithObjectsAndKeys:@"chatTypeSupergroup",@"@type",@30,@"supergroup_id",nil],@"type",(chatPermissions?chatPermissions:[NSDictionary dictionary]),@"permissions",nil];
    if([type isEqual:@"getSupergroup"])return [NSDictionary dictionaryWithObjectsAndKeys:@"supergroup",@"@type",(status?status:[NSDictionary dictionary]),@"status",nil];
    if([type isEqual:@"getForumTopic"])return missingTopic?nil:[NSDictionary dictionaryWithObjectsAndKeys:@"forumTopic",@"@type",(topicInfo?topicInfo:[NSDictionary dictionary]),@"info",nil];
    return [NSDictionary dictionaryWithObject:@"ok" forKey:@"@type"];
}
@end
static NSDictionary *Context(NSString *type,NSDictionary *rights){return [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:type,@"@type",(rights?rights:[NSDictionary dictionary]),@"rights",nil] forKey:@"status"];}
static BOOL Allowed(NSDictionary *context,NSDictionary *topic,NSNumber *topicID,NSString *action){return TGForumPermissionFlag(TGForumTopicActionPermissions(context,topic,topicID),action);}
static NSUInteger MutationCount(ForumClient *client){NSUInteger count=0;for(NSDictionary *r in client.requests)if(![[r objectForKey:@"@type"] hasPrefix:@"get"])count++;return count;}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSArray *actions=[NSArray arrayWithObjects:@"create",@"rename",@"close",@"reopen",@"pin",@"unpin",@"delete",nil];
    NSDictionary *owned=[NSDictionary dictionaryWithObject:@YES forKey:@"is_outgoing"];
    for(NSString *action in actions){Check(!Allowed(nil,nil,@66,action),"unknown rights fail closed");Check(!Allowed(Context(@"chatMemberStatusMember",nil),nil,@66,action),"ordinary member cannot manage someone else's topic");}
    for(NSString *action in actions){BOOL expected=[action isEqual:@"rename"]||[action isEqual:@"close"]||[action isEqual:@"reopen"];Check(Allowed(Context(@"chatMemberStatusMember",nil),owned,@66,action)==expected,"owned topics only allow documented ownership operations");}
    NSDictionary *manage=Context(@"chatMemberStatusAdministrator",[NSDictionary dictionaryWithObject:@YES forKey:@"can_manage_topics"]);
    Check(Allowed(manage,nil,@66,@"rename") && Allowed(manage,nil,@66,@"pin"),"topic manager can rename and pin");Check(!Allowed(manage,nil,@66,@"delete"),"manage_topics does not imply delete_messages");
    NSDictionary *remove=Context(@"chatMemberStatusAdministrator",[NSDictionary dictionaryWithObject:@YES forKey:@"can_delete_messages"]);
    Check(Allowed(remove,nil,@66,@"delete")&&!Allowed(remove,nil,@66,@"rename"),"delete right does not imply topic management");
    NSDictionary *creator=Context(@"chatMemberStatusCreator",nil);
    for(NSString *action in actions)Check(Allowed(creator,nil,@66,action),"creator permits supported topic operations");
    Check(!Allowed(creator,nil,@1,@"pin")&&!Allowed(creator,nil,@1,@"delete")&&Allowed(creator,nil,@1,@"rename"),"General is editable but cannot be pinned or deleted");
    Check(!Allowed(creator,[NSDictionary dictionaryWithObject:@YES forKey:@"is_general"],@66,@"delete"),"explicit General identity is respected");
    Check(!Allowed(Context(@"chatMemberStatusLeft",nil),owned,@66,@"rename"),"left member does not retain ownership privileges");
    Check(!Allowed(Context(@"chatMemberStatusBanned",nil),owned,@66,@"close"),"banned member cannot close topic");
    Check(!Allowed(creator,nil,@0,@"rename"),"zero topic identifier fails closed");
    Check(!Allowed((id)[NSNull null],(id)[NSNull null],(id)[NSNull null],@"rename"),"malformed snapshot is safe");
    NSDictionary *legacy=[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"chatMemberStatusAdministrator",@"@type",@YES,@"can_manage_topics",nil] forKey:@"status"];
    Check(Allowed(legacy,nil,@66,@"rename"),"legacy flat administrator fields remain supported");
    ForumClient *client=[[[ForumClient alloc] init] autorelease];client.status=[creator objectForKey:@"status"];client.topicInfo=[NSDictionary dictionaryWithObject:@66 forKey:@"forum_topic_id"];
    NSDictionary *serverContext=[client forumTopicRightsForChatID:@(-100) timeout:1];
    Check([[TGForumTopicActionPermissions(serverContext,nil,@66) objectForKey:@"supergroup_id"] isEqual:@30],"actual rights lookup preserves server group identity for later role updates");
    Check([client renameForumTopicInChatID:@(-100) topicID:@66 name:@"New name" timeout:1 error:NULL],"actual mutation revalidates fresh rights");
    Check(MutationCount(client)==1,"permitted rename dispatches one mutation");NSDictionary *last=[client.requests lastObject];Check([[last objectForKey:@"forum_topic_id"] isEqual:@66]&&[[last objectForKey:@"message_thread_id"] isEqual:@66],"modern and legacy mutation keep exact topic target");
    client.status=[Context(@"chatMemberStatusMember",nil) objectForKey:@"status"];[client.requests removeAllObjects];
    Check(![client renameForumTopicInChatID:@(-100) topicID:@66 name:@"Forbidden" timeout:1 error:NULL]&&MutationCount(client)==0,"revoked rights cannot mutate even from a stale menu");
    client.status=[creator objectForKey:@"status"];client.missingTopic=YES;[client.requests removeAllObjects];
    Check(![client deleteForumTopicInChatID:@(-100) topicID:@66 timeout:1 error:NULL]&&MutationCount(client)==0,"missing topic aborts before mutation");
    client.missingTopic=NO;[client.requests removeAllObjects];
    Check(![client deleteForumTopicInChatID:@(-100) topicID:@1 timeout:1 error:NULL]&&MutationCount(client)==0,"actual General delete is rejected");
    [client.requests removeAllObjects];client.topicInfo=[NSDictionary dictionaryWithObject:@67 forKey:@"forum_topic_id"];
    Check(![client renameForumTopicInChatID:@(-100) topicID:@66 name:@"Wrong topic" timeout:1 error:NULL]&&MutationCount(client)==0,"mismatched topic response is never trusted");
    [client.requests removeAllObjects];client.topicInfo=[NSDictionary dictionaryWithObjectsAndKeys:@66,@"forum_topic_id",@(-200),@"chat_id",nil];
    Check(![client renameForumTopicInChatID:@(-100) topicID:@66 name:@"Wrong chat" timeout:1 error:NULL]&&MutationCount(client)==0,"mismatched parent response is never trusted");
    printf("Forum permissions: %lu capability, General, legacy and fresh permission checks PASS.\n",(unsigned long)Checks);[pool drain];return 0;}
