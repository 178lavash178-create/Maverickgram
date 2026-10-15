#import <Foundation/Foundation.h>

/* nil means unknown: never grant notification permission from missing settings. */
@interface TGNotificationMuteState : NSObject {
    NSLock *_lock;
    NSMutableDictionary *_chats;
    NSMutableDictionary *_scopes;
}
- (void)recordTDLibObject:(NSDictionary *)object atUnixTime:(NSTimeInterval)now;
- (void)recordScopeSettingsIfUnknown:(NSDictionary *)settings type:(NSString *)type atUnixTime:(NSTimeInterval)now;
- (NSNumber *)mutedForChatID:(NSNumber *)chatID atUnixTime:(NSTimeInterval)now;
- (NSNumber *)mutedForScopeType:(NSString *)type atUnixTime:(NSTimeInterval)now;
@end
NSString *TGNotificationScopeForChatType(id type);
