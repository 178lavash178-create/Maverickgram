#import <Cocoa/Cocoa.h>
#import "TGAquaShellViews.h"
#include <assert.h>
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSUInteger count = 0;
    CGFloat heights[] = {544, 620, 746, 900};
    CGFloat widths[] = {270, 292, 360, 420};
    CGFloat footers[] = {52, 76, 130};
    CGFloat requested[] = {0, 76, 210, 340, 1000};
    for (NSUInteger h=0;h<4;h++) for (NSUInteger w=0;w<4;w++) for(NSUInteger f=0;f<3;f++) for(NSUInteger r=0;r<5;r++) for(NSUInteger c=0;c<2;c++) {
        NSRect sidebar = NSMakeRect(0,0,widths[w],heights[h]);
        TGAquaSourceListGeometry g = TGAquaSourceListFrames(sidebar,footers[f],requested[r],c);
        assert(NSMinY(g.chats)>=footers[f]);
        assert(NSHeight(g.chats)>=130);
        assert(NSMaxY(g.chats)<=NSMinY(g.chatHeader));
        assert(NSMaxY(g.chatHeader)<=NSMinY(g.divider));
        assert(NSMaxY(g.divider)<=NSMinY(g.folders));
        assert(NSMaxY(g.folders)<=NSMaxY(sidebar)-32);
        assert(NSWidth(g.folders)<=NSWidth(sidebar));
        assert(!c || NSHeight(g.folders)==0);
        count++;
    }
    printf("Aqua source list geometry: %lu cases PASS\n",(unsigned long)count);
    [pool drain]; return 0;
}
