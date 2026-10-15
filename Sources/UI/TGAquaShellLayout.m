#import "TGAquaShellViews.h"
#include <math.h>

CGFloat TGAquaFooterHeight(BOOL composerVisible, NSRect composerInputFrame) {
    return composerVisible ? MAX(52.0, NSMaxY(composerInputFrame) + 6.0) : 52.0;
}

CGFloat TGAquaFooterControlY(BOOL composerVisible, NSRect attachFrame) {
    return composerVisible ? NSMinY(attachFrame) : 10.0;
}

TGAquaSourceListGeometry TGAquaSourceListFrames(NSRect sidebar, CGFloat footerTop, CGFloat preferredFolderHeight, NSUInteger folderCount, BOOL collapsed) {
    TGAquaSourceListGeometry result;
    CGFloat top = MAX(NSMinY(sidebar), NSMaxY(sidebar) - 32.0);
    CGFloat bottom = MIN(top, MAX(NSMinY(sidebar), footerTop));
    CGFloat available = MAX(0.0, top - bottom);
    CGFloat headerHeight = MIN(36.0, available);
    CGFloat dividerHeight = (!collapsed && folderCount > 0) ? MIN(18.0, available - headerHeight) : 0.0;
    // Reserve a usable chat viewport before allocating any space to folders.
    // A short list must never stretch into an empty pane below its final row.
    CGFloat maximum = MAX(0.0, MIN(340.0, available - headerHeight - dividerHeight - 130.0));
    CGFloat contentHeight = (CGFloat)folderCount * 32.0;
    CGFloat requested = isfinite(preferredFolderHeight) ? MAX(76.0, preferredFolderHeight) : 76.0;
    CGFloat folderHeight = collapsed ? 0.0 : MIN(contentHeight, MIN(maximum, requested));
    CGFloat width = MAX(0.0, NSWidth(sidebar));
    CGFloat folderInset = MIN(1.0, width / 2.0), chatInset = 0.0;
    result.folders = NSMakeRect(NSMinX(sidebar) + folderInset, top - folderHeight, MAX(0.0, width - 2.0 * folderInset), folderHeight);
    result.divider = NSMakeRect(NSMinX(sidebar), NSMinY(result.folders) - dividerHeight, width, dividerHeight);
    result.chatHeader = NSMakeRect(NSMinX(sidebar), NSMinY(result.divider) - headerHeight, width, headerHeight);
    result.chats = NSMakeRect(NSMinX(sidebar) + chatInset, bottom, MAX(0.0, width - 2.0 * chatInset), MAX(0.0, NSMinY(result.chatHeader) - bottom));
    return result;
}
