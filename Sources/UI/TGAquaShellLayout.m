#import "TGAquaShellViews.h"
#include <math.h>

CGFloat TGAquaFooterBaseHeight(void) { return 58.0; }

CGFloat TGAquaFooterHeight(BOOL composerVisible, NSRect composerInputFrame) {
    return composerVisible ? MAX(TGAquaFooterBaseHeight(), NSMaxY(composerInputFrame) + 6.0) : 0.0;
}

CGFloat TGAquaFooterControlY(BOOL composerVisible, NSRect attachFrame) {
    return composerVisible ? NSMinY(attachFrame) : 13.0;
}

TGAquaSourceListGeometry TGAquaSourceListFrames(NSRect sidebar, CGFloat footerTop, CGFloat preferredFolderHeight, NSUInteger folderCount, BOOL collapsed) {
    TGAquaSourceListGeometry result;
    // Leave breathing room below the folder caption without adding empty rows.
    CGFloat folderTopInset = (!collapsed && folderCount > 0) ? 4.0 : 0.0;
    CGFloat top = MAX(NSMinY(sidebar), NSMaxY(sidebar) - 32.0 - folderTopInset);
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

// Icons keep one consistent hit target across languages and available window widths.
NSRect TGAquaToolbarSectionFrame(CGFloat width, CGFloat height, NSUInteger index) {
    CGFloat searchWidth = MIN(200.0, floor(width * 0.18));
    return NSMakeRect(66.0 + searchWidth + index * 54.0, height - 43.0, 48.0, 32.0);
}

TGAquaChatHeaderGeometry TGAquaChatHeaderFrames(NSRect header, BOOL forum) {
    TGAquaChatHeaderGeometry g;
    CGFloat x = NSMinX(header), y = NSMinY(header) + 3.0, width = NSWidth(header);
    g.back = forum ? NSMakeRect(x + 8.0, y, 30.0, 30.0) : NSZeroRect;
    g.refresh = NSMakeRect(x + width - 38.0, y, 30.0, 30.0);
    g.search = NSMakeRect(x + width - 74.0, y, 30.0, 30.0);
    g.compose = NSMakeRect(x + width - 110.0, y, 30.0, 30.0);
    CGFloat titleX = x + (forum ? 46.0 : 10.0);
    g.title = NSMakeRect(titleX, y + 5.0, MAX(0.0, NSMinX(g.compose) - 8.0 - titleX), 20.0);
    return g;
}

// Center each visual group in the same header band, independently of its height.
TGAquaConversationHeaderVerticalGeometry TGAquaConversationHeaderVerticalFrames(NSRect header, BOOL subtitle) {
    TGAquaConversationHeaderVerticalGeometry g;
    CGFloat center = NSMidY(header);
    g.buttonY = floor(center - 15.0);
    g.avatarY = floor(center - 12.0);
    CGFloat textBottom = floor(center - (subtitle ? 33.0 : 17.0) / 2.0);
    g.titleY = textBottom + (subtitle ? 16.0 : 0.0);
    g.subtitleY = subtitle ? textBottom : floor(center - 7.0);
    return g;
}
