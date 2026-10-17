#import <Cocoa/Cocoa.h>
#include <math.h>

/* Regular source-list rows use fixed trailing columns. The maximum existing
 * unread label is 999+ at 10 pt; its reserved lane keeps pin/mute stationary
 * when badges appear or change width. Avatar-only compact rows keep their
 * existing overlay layout. Decorative identity badges yield before the title. */
typedef struct {
    NSRect title, unread, pin, mute, bot, community;
} TGChatListRowGeometry;

static inline TGChatListRowGeometry TGChatListRowFrames(NSRect frame, NSRect avatar,
    CGFloat unreadWidth, CGFloat unreadHeight, BOOL pinned, BOOL muted, BOOL bot,
    CGFloat communityWidth) {
    TGChatListRowGeometry g = {NSZeroRect,NSZeroRect,NSZeroRect,NSZeroRect,NSZeroRect,NSZeroRect};
    CGFloat edge = NSMaxX(frame)-9.0;
    CGFloat laneLeft = edge-40.0;
    g.mute = NSMakeRect(laneLeft-22.0,
        NSMinY(frame)+floor((NSHeight(frame)-15.0)/2.0),15.0,15.0);
    g.pin = NSMakeRect(NSMinX(g.mute)-18.0,
        NSMinY(frame)+floor((NSHeight(frame)-12.0)/2.0),12.0,12.0);
    if (unreadWidth>0.0 && unreadHeight>0.0)
        g.unread = NSMakeRect(edge-MIN(40.0,unreadWidth),
            NSMinY(frame)+floor((NSHeight(frame)-unreadHeight)/2.0),MIN(40.0,unreadWidth),unreadHeight);
    CGFloat titleX = NSMaxX(avatar)+9.0, right = edge;
    if (unreadWidth>0.0) right = MIN(right,laneLeft-12.0);
    if (muted) right = MIN(right,NSMinX(g.mute)-8.0);
    if (pinned) right = MIN(right,NSMinX(g.pin)-8.0);
    if (bot && right-titleX>=59.0) {
        g.bot=NSMakeRect(right-15.0,NSMinY(frame)+floor((NSHeight(frame)-15.0)/2.0),15.0,15.0);
        right=NSMinX(g.bot)-4.0;
    }
    communityWidth=MIN(64.0,MAX(0.0,communityWidth));
    if (communityWidth>0.0 && right-titleX>=communityWidth+44.0) {
        g.community=NSMakeRect(right-communityWidth,NSMinY(frame)+floor((NSHeight(frame)-16.0)/2.0),communityWidth,16.0);
        right=NSMinX(g.community)-4.0;
    }
    g.title=NSMakeRect(titleX,NSMinY(frame)+floor((NSHeight(frame)-15.0)/2.0),MAX(0.0,right-titleX),16.0);
    return g;
}
