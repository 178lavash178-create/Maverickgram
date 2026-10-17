#import <Cocoa/Cocoa.h>
#include <math.h>

/* One contact picker; creation lives in a menu, invitation entry is disclosed
 * only when requested. Geometry is shared by the window and native probes. */
typedef struct {
    NSRect title, create, search, refresh, list, status, spinner;
    NSRect open, inviteToggle, inviteField, join;
} TGChatLifecycleAquaGeometry;

static TGChatLifecycleAquaGeometry TGChatLifecycleAquaFrames(NSSize size, BOOL invitation) {
    TGChatLifecycleAquaGeometry g;
    CGFloat w=MAX(0,size.width), h=MAX(0,size.height);
    CGFloat footer=invitation ? 154.0 : 96.0;
    g.title=NSMakeRect(20,h-40,MAX(0,w-206),24);
    g.create=NSMakeRect(MAX(20,w-170),h-44,150,30);
    g.search=NSMakeRect(20,h-82,MAX(0,w-82),28);
    g.refresh=NSMakeRect(MAX(20,w-50),h-83,30,30);
    g.list=NSMakeRect(18,footer,MAX(0,w-36),MAX(0,h-98-footer));
    g.status=NSMakeRect(20,footer-28,MAX(0,w-68),18);
    g.spinner=NSMakeRect(MAX(20,w-38),footer-27,16,16);
    g.open=NSMakeRect(MAX(20,w-174),20,154,30);
    g.inviteToggle=NSMakeRect(20,20,MAX(0,w-218),30);
    g.inviteField=NSMakeRect(20,74,MAX(0,w-166),28);
    g.join=NSMakeRect(MAX(20,w-136),72,116,30);
    return g;
}
