#import <Foundation/Foundation.h>

NSString *TGNavigationListPositionKey(NSNumber *accountID, NSNumber *filterID, BOOL archived, NSNumber *forumChatID);
NSString *TGNavigationTranscriptPositionKey(NSNumber *accountID, NSNumber *chatID, NSNumber *threadID, NSString *topicKind);

// Ephemeral, bounded per-account navigation anchors. Never persisted to disk.
@interface TGNavigationPositionStore : NSObject {
    NSMutableDictionary *_positions;
    NSMutableArray *_recency;
    NSString *_pendingListKey;
    NSString *_pendingTranscriptKey;
    NSString *_restoredTranscriptKey;
    NSUInteger _restoredTranscriptGeneration;
}
@property(nonatomic, readonly) NSString *pendingTranscriptKey;
- (void)savePosition:(NSDictionary *)position forKey:(NSString *)key;
- (NSDictionary *)positionForKey:(NSString *)key;
- (void)armKey:(NSString *)key transcript:(BOOL)transcript;
- (NSDictionary *)pendingPositionForKey:(NSString *)key transcript:(BOOL)transcript;
- (NSDictionary *)consumePositionForKey:(NSString *)key transcript:(BOOL)transcript;
- (void)removePositionForKey:(NSString *)key;
- (void)markRestoredTranscriptKey:(NSString *)key generation:(NSUInteger)generation;
- (BOOL)isRestoredTranscriptKey:(NSString *)key generation:(NSUInteger)generation;
- (void)clear;
@end
