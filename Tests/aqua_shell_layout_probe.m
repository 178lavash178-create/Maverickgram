#import <Cocoa/Cocoa.h>
#import "TGAquaShellViews.h"
#include <assert.h>
#include <math.h>
static void AssertContained(NSRect inner, NSRect outer) {
    assert(NSWidth(inner)>=0 && NSHeight(inner)>=0);
    assert(NSMinX(inner)>=NSMinX(outer)-0.001 && NSMaxX(inner)<=NSMaxX(outer)+0.001);
    assert(NSMinY(inner)>=NSMinY(outer)-0.001 && NSMaxY(inner)<=NSMaxY(outer)+0.001);
}
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSUInteger count = 0;
    CGFloat heights[] = {0,48,120,180,300,544,620,746,900};
    CGFloat widths[] = {0,1,80,270,292,360,420};
    CGFloat footers[] = {0,52,76,130,1000};
    CGFloat requested[] = {-100,0,76,210,340,1000,NAN};
    NSUInteger folders[] = {0,1,2,10,20,64};
    for (NSUInteger h=0;h<9;h++) for (NSUInteger w=0;w<7;w++) for(NSUInteger f=0;f<5;f++) for(NSUInteger r=0;r<7;r++) for(NSUInteger n=0;n<6;n++) for(NSUInteger c=0;c<2;c++) {
        NSRect sidebar = NSMakeRect(11,17,widths[w],heights[h]);
        TGAquaSourceListGeometry g = TGAquaSourceListFrames(sidebar,footers[f],requested[r],folders[n],c);
        AssertContained(g.folders,sidebar); AssertContained(g.divider,sidebar);
        AssertContained(g.chatHeader,sidebar); AssertContained(g.chats,sidebar);
        CGFloat top=MAX(NSMinY(sidebar),NSMaxY(sidebar)-32);
        CGFloat bottom=MIN(top,MAX(NSMinY(sidebar),footers[f]));
        CGFloat available=top-bottom;
        assert(NSMinY(g.chats)>=bottom);
        if(available>=184) assert(NSHeight(g.chats)>=130);
        assert(NSMaxY(g.chats)<=NSMinY(g.chatHeader)+0.001);
        assert(NSMaxY(g.chatHeader)<=NSMinY(g.divider)+0.001);
        assert(NSMaxY(g.divider)<=NSMinY(g.folders)+0.001);
        assert(NSMaxY(g.folders)<=top+0.001);
        assert(NSHeight(g.folders)<=folders[n]*32.0 && NSHeight(g.folders)<=340);
        assert(!c || NSHeight(g.folders)==0);
        if(c || folders[n]==0) assert(NSHeight(g.divider)==0);
        else if(available>=54) assert(NSHeight(g.divider)==18);
        if(!c && available>=184+folders[n]*32 && folders[n]<=2)
            assert(NSHeight(g.folders)==folders[n]*32);
        count++;
    }
    // Resizing a tall pane or changing a 20-folder account to two folders must
    // discard the old empty space, without changing the stored preference.
    NSRect sidebar=NSMakeRect(0,0,270,746);
    TGAquaSourceListGeometry many=TGAquaSourceListFrames(sidebar,52,340,20,NO);
    TGAquaSourceListGeometry few=TGAquaSourceListFrames(sidebar,52,340,2,NO);
    TGAquaSourceListGeometry closed=TGAquaSourceListFrames(sidebar,52,340,2,YES);
    assert(NSHeight(many.folders)==340 && NSHeight(few.folders)==64);
    assert(NSHeight(few.chats)>NSHeight(many.chats));
    assert(NSHeight(closed.chats)==NSHeight(few.chats)+64+18);
    // Hidden composer frames are stale state: neither a draft nor a previous
    // section may enlarge the navigation footer or move its controls.
    NSRect inputs[] = {NSZeroRect,NSMakeRect(300,14,400,30),NSMakeRect(300,14,400,94),NSMakeRect(300,1000,400,94)};
    for (NSUInteger i=0;i<sizeof(inputs)/sizeof(inputs[0]);i++) {
        assert(TGAquaFooterHeight(NO,inputs[i])==52);
        assert(TGAquaFooterControlY(NO,inputs[i])==10);
        CGFloat expanded=TGAquaFooterHeight(YES,inputs[i]);
        assert(expanded>=52 && expanded>=NSMaxY(inputs[i])+6);
        assert(TGAquaFooterControlY(YES,inputs[i])==NSMinY(inputs[i]));
        TGAquaSourceListGeometry footerList=TGAquaSourceListFrames(sidebar,expanded,210,20,NO);
        assert(NSMinY(footerList.chats)==MIN(NSMaxY(sidebar)-32,expanded));
        assert(NSMinX(footerList.chats)==NSMinX(sidebar));
        assert(NSWidth(footerList.chats)==NSWidth(sidebar));
    }
    printf("Aqua footer hidden/visible composer and flush list geometry PASS\n");
    printf("Aqua source list geometry: %lu cases plus count-change/collapse PASS\n",(unsigned long)count);
    [pool drain]; return 0;
}
