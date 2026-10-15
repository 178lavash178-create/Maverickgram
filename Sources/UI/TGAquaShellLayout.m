#import "TGAquaShellViews.h"
#include <math.h>

TGAquaSourceListGeometry TGAquaSourceListFrames(NSRect sidebar, CGFloat footerTop, CGFloat preferredFolderHeight, BOOL collapsed) {
    TGAquaSourceListGeometry result;
    CGFloat top = NSMaxY(sidebar) - 32.0;
    CGFloat bottom = MAX(NSMinY(sidebar), footerTop) + 4.0;
    CGFloat available = MAX(0.0, top - bottom);
    CGFloat maximum = MAX(0.0, MIN(340.0, available - 180.0));
    CGFloat folderHeight = collapsed ? 0.0 : MIN(maximum, MAX(76.0, preferredFolderHeight));
    result.folders = NSMakeRect(NSMinX(sidebar) + 1.0, top - folderHeight, MAX(0.0, NSWidth(sidebar) - 2.0), folderHeight);
    result.divider = NSMakeRect(NSMinX(sidebar), NSMinY(result.folders) - 10.0, NSWidth(sidebar), 10.0);
    result.chatHeader = NSMakeRect(NSMinX(sidebar), NSMinY(result.divider) - 36.0, NSWidth(sidebar), 36.0);
    result.chats = NSMakeRect(NSMinX(sidebar) + 4.0, bottom, MAX(0.0, NSWidth(sidebar) - 8.0), MAX(0.0, NSMinY(result.chatHeader) - bottom));
    return result;
}

