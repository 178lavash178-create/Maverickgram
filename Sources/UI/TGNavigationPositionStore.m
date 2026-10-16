#import "TGNavigationPositionStore.h"
#include <math.h>

static BOOL TGNavigationValidID(NSNumber *value, BOOL positive) {
    return [value isKindOfClass:[NSNumber class]] && (positive ? [value longLongValue]>0 : [value longLongValue]!=0);
}
NSString *TGNavigationListPositionKey(NSNumber *account, NSNumber *filter, BOOL archived, NSNumber *forum) {
    if (!TGNavigationValidID(account,YES)) return nil;
    NSString *folder=archived ? @"archive" : (filter ? [NSString stringWithFormat:@"filter:%lld",[filter longLongValue]] : @"main");
    return [NSString stringWithFormat:@"%lld|list|%@|%@",[account longLongValue],folder,forum ? [NSString stringWithFormat:@"forum:%lld",[forum longLongValue]] : @"root"];
}
NSString *TGNavigationTranscriptPositionKey(NSNumber *account, NSNumber *chat, NSNumber *thread, NSString *kind) {
    if (!TGNavigationValidID(account,YES) || !TGNavigationValidID(chat,NO)) return nil;
    return [NSString stringWithFormat:@"%lld|transcript|%lld|%lld|%@",[account longLongValue],[chat longLongValue],[thread longLongValue],[kind length] ? kind : @"chat"];
}
@implementation TGNavigationPositionStore
- (id)init { if((self=[super init])) { _positions=[[NSMutableDictionary alloc] init];_recency=[[NSMutableArray alloc] init]; } return self; }
- (void)dealloc { [_positions release];[_recency release];[_pendingListKey release];[_pendingTranscriptKey release];[_restoredTranscriptKey release];[super dealloc]; }
- (NSString *)pendingTranscriptKey { return _pendingTranscriptKey; }
- (void)savePosition:(NSDictionary *)position forKey:(NSString *)key {
    if (![key length] || [key length]>256 || ![position isKindOfClass:[NSDictionary class]]) return;
    id anchor=[position objectForKey:@"anchor"];
    if (![anchor isKindOfClass:[NSNumber class]] && !([anchor isKindOfClass:[NSString class]] && [anchor length]<=256)) return;
    double offset=[[position objectForKey:@"offset"] doubleValue],origin=[[position objectForKey:@"origin"] doubleValue];
    if (!isfinite(offset) || !isfinite(origin)) return;
    NSDictionary *saved=[NSDictionary dictionaryWithObjectsAndKeys:anchor,@"anchor",[NSNumber numberWithDouble:MAX(-10000,MIN(10000,offset))],@"offset",[NSNumber numberWithDouble:MAX(0,MIN(1e9,origin))],@"origin",[NSNumber numberWithBool:[[position objectForKey:@"nearEnd"] boolValue]],@"nearEnd",[NSNumber numberWithUnsignedInteger:MIN((NSUInteger)500,[[position objectForKey:@"loadedCount"] unsignedIntegerValue])],@"loadedCount",nil];
    [_positions setObject:saved forKey:key];[_recency removeObject:key];[_recency addObject:key];
    while([_recency count]>64) { NSString *old=[[_recency objectAtIndex:0] retain];[self removePositionForKey:old];[old release]; }
}
- (NSDictionary *)positionForKey:(NSString *)key { return key ? [_positions objectForKey:key] : nil; }
- (void)armKey:(NSString *)key transcript:(BOOL)transcript {
    NSString **slot=transcript ? &_pendingTranscriptKey : &_pendingListKey;
    NSDictionary *position=[self positionForKey:key];
    NSString *next=(position && (!transcript || ![[position objectForKey:@"nearEnd"] boolValue])) ? [key copy] : nil;
    [*slot release];*slot=next;
}
- (NSDictionary *)pendingPositionForKey:(NSString *)key transcript:(BOOL)transcript {
    NSString *pending=transcript ? _pendingTranscriptKey : _pendingListKey;
    return [key length] && [pending isEqual:key] ? [self positionForKey:key] : nil;
}
- (NSDictionary *)consumePositionForKey:(NSString *)key transcript:(BOOL)transcript {
    NSDictionary *position=[[[self pendingPositionForKey:key transcript:transcript] retain] autorelease];
    if (position) { NSString **slot=transcript ? &_pendingTranscriptKey : &_pendingListKey;[*slot release];*slot=nil; }
    return position;
}
- (void)removePositionForKey:(NSString *)key {
    if (!key) return;[_positions removeObjectForKey:key];[_recency removeObject:key];
    if ([_pendingTranscriptKey isEqual:key]) { [_pendingTranscriptKey release];_pendingTranscriptKey=nil; }
    if ([_restoredTranscriptKey isEqual:key]) { [_restoredTranscriptKey release];_restoredTranscriptKey=nil;_restoredTranscriptGeneration=0; }
    if ([_pendingListKey isEqual:key]) { [_pendingListKey release];_pendingListKey=nil; }
}
- (void)markRestoredTranscriptKey:(NSString *)key generation:(NSUInteger)generation {
    NSString *next=[key copy];[_restoredTranscriptKey release];_restoredTranscriptKey=next;_restoredTranscriptGeneration=generation;
}
- (BOOL)isRestoredTranscriptKey:(NSString *)key generation:(NSUInteger)generation {
    return [key length] && [_restoredTranscriptKey isEqual:key] && _restoredTranscriptGeneration==generation;
}
- (void)clear { [_positions removeAllObjects];[_recency removeAllObjects];[_pendingListKey release];_pendingListKey=nil;[_pendingTranscriptKey release];_pendingTranscriptKey=nil;[_restoredTranscriptKey release];_restoredTranscriptKey=nil;_restoredTranscriptGeneration=0; }
@end
