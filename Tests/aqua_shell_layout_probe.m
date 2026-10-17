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
        CGFloat top=MAX(NSMinY(sidebar),NSMaxY(sidebar)-32-((!c && folders[n]>0) ? 4 : 0));
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
    assert(NSHeight(closed.chats)==NSHeight(few.chats)+64+18+4);
    // Hidden composer frames are stale state: neither a draft nor a previous
    // section may enlarge the navigation footer or move its controls.
    NSRect inputs[] = {NSZeroRect,NSMakeRect(300,14,400,30),NSMakeRect(300,14,400,94),NSMakeRect(300,1000,400,94)};
    for (NSUInteger i=0;i<sizeof(inputs)/sizeof(inputs[0]);i++) {
        assert(TGAquaFooterHeight(NO,inputs[i])==0);
        assert(TGAquaFooterControlY(NO,inputs[i])==13);
        CGFloat expanded=TGAquaFooterHeight(YES,inputs[i]);
        assert(expanded>=58 && expanded>=NSMaxY(inputs[i])+6);
        assert(TGAquaFooterControlY(YES,inputs[i])==NSMinY(inputs[i]));
        TGAquaSourceListGeometry footerList=TGAquaSourceListFrames(sidebar,expanded,210,20,NO);
        assert(NSMinY(footerList.chats)==MIN(NSMaxY(sidebar)-36,expanded));
        assert(NSMinX(footerList.chats)==NSMinX(sidebar));
        assert(NSWidth(footerList.chats)==NSWidth(sidebar));
    }
    // The composer retains its single-line baseline; utility pages have no footer.
    for (CGFloat input=20; input<=30; input++) {
        CGFloat composerHeight=MAX(42.0,input+16.0);
        CGFloat backgroundY=8.0+floor((composerHeight-input-10.0)/2.0);
        NSRect background=NSMakeRect(300,backgroundY,400,input+10);
        assert(TGAquaFooterHeight(YES,background)==58 && TGAquaFooterHeight(NO,background)==0);
    }
    // Moving Settings to the toolbar returns the former 58pt dock to chats.
    TGAquaSourceListGeometry full=TGAquaSourceListFrames(sidebar,0,210,20,NO);
    TGAquaSourceListGeometry dock=TGAquaSourceListFrames(sidebar,58,210,20,NO);
    assert(NSMinY(full.chats)==0 && NSHeight(full.chats)==NSHeight(dock.chats)+58);
    for (CGFloat width=760; width<=1600; width+=20) {
        TGAquaToolbarGeometry toolbar=TGAquaToolbarFrames(width,700);
        NSRect bar=NSMakeRect(0,700-TGAquaToolbarHeight(),width,TGAquaToolbarHeight());
        assert(TGAquaToolbarHeight()==64);
        AssertContained(toolbar.avatar,bar);AssertContained(toolbar.account,bar);
        AssertContained(toolbar.search,bar);AssertContained(toolbar.downloads,bar);
        assert(NSMinX(toolbar.account)>=NSMaxX(toolbar.avatar)+6);
        NSRect previous=toolbar.account;
        for (NSUInteger i=0;i<4;i++) {
            NSRect frame=TGAquaToolbarSectionFrame(width,700,i);
            assert(NSEqualRects(frame,toolbar.sections[i]));AssertContained(frame,bar);
            assert(NSMinX(frame)>=NSMaxX(previous));
            assert(NSWidth(frame)>=64 && NSHeight(frame)==52);
            previous=frame;
        }
        assert(NSEqualRects(toolbar.sections[4],NSZeroRect) && NSEqualRects(TGAquaToolbarSectionFrame(width,700,4),NSZeroRect));
        assert(NSMaxX(previous)+12<=NSMinX(toolbar.search));
        assert(NSWidth(toolbar.search)>=106 && NSMaxX(toolbar.search)+12<=NSMinX(toolbar.downloads));
    }
    for (CGFloat width=200; width<=420; width+=10) for (NSUInteger forum=0;forum<2;forum++) {
        NSRect area=NSMakeRect(0,200,width,36);
        TGAquaChatHeaderGeometry header=TGAquaChatHeaderFrames(area,forum);
        AssertContained(header.title,area); AssertContained(header.compose,area);
        assert(NSEqualRects(header.search,NSZeroRect)); AssertContained(header.refresh,area);
        assert(NSMaxX(header.title)+8<=NSMinX(header.compose));
        assert(NSMaxX(header.compose)+6==NSMinX(header.refresh));
        if(forum) {
            AssertContained(header.back,area);
            assert(NSMinX(header.back)==8 && NSMaxX(header.back)+8==NSMinX(header.title));
        } else assert(NSEqualRects(header.back,NSZeroRect));
    }
    for (CGFloat origin=0;origin<=900;origin+=10) for (NSUInteger subtitle=0;subtitle<2;subtitle++) {
        NSRect band=NSMakeRect(300,origin,500,40);
        TGAquaConversationHeaderVerticalGeometry g=TGAquaConversationHeaderVerticalFrames(band,subtitle);
        CGFloat center=NSMidY(band);
        assert(fabs(g.buttonY+15-center)<=0.5);
        assert(fabs(g.avatarY+12-center)<=0.5);
        if(subtitle) {
            assert(fabs((g.subtitleY+g.titleY+17)/2-center)<=0.5);
            assert(g.subtitleY+14+2==g.titleY);
        } else assert(fabs(g.titleY+8.5-center)<=0.5);
        assert(g.titleY+17<=NSMaxY(band) && g.titleY>=NSMinY(band));
    }
    NSUInteger searchCases=0;
    for(CGFloat w=260;w<=1100;w+=20) for(CGFloat h=340;h<=800;h+=30)
    for(NSUInteger scope=0;scope<2;scope++) for(NSUInteger results=0;results<2;results++) {
        NSRect area=NSMakeRect(13,29,w,h);
        TGAquaSearchGeometry g=TGAquaSearchFrames(area,scope,results);
        AssertContained(g.query,area); AssertContained(g.close,area); AssertContained(g.filter,area);
        AssertContained(g.advanced,area); AssertContained(g.status,area); AssertContained(g.navigation,area);
        AssertContained(g.results,area);
        assert(NSMaxX(g.query)+5<=NSMinX(g.close));
        assert(NSMaxX(g.filter)+5<=NSMinX(g.advanced));
        assert(NSMaxY(g.navigation)+3<=NSMinY(g.results));
        assert(NSMaxY(g.results)+3<=NSMinY(g.status));
        assert(NSMaxY(g.status)+3<=NSMinY(g.filter));
        if(!scope) { AssertContained(g.scope,area); assert(!NSIntersectsRect(g.scope,g.filter)); }
        assert(g.height<=h && h-g.height>=166-0.01); searchCases++;
    }
    printf("Aqua compact search: %lu contained nonoverlapping layouts, conversation >=160pt after gap PASS\n",(unsigned long)searchCases);
    printf("Aqua conversation header: avatar, actions, single/title+typing groups centered PASS\n");
    printf("Aqua icon toolbar, forum header, reclaimed sidebar and composer-only footer PASS\n");
    printf("Aqua source list geometry: %lu cases plus count-change/collapse PASS\n",(unsigned long)count);
    [pool drain]; return 0;
}
