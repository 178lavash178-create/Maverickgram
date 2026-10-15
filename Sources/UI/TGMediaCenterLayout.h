#import <Cocoa/Cocoa.h>
#include <math.h>

/* Aqua media-center geometry is independent of loading and row construction. */
typedef struct {
    NSUInteger columns;
    NSUInteger rows;
    CGFloat buttonWidth;
    CGFloat startX;
    CGFloat firstY;
    CGFloat extraHeight;
} TGAquaMediaCenterTabs;

static TGAquaMediaCenterTabs TGAquaMediaCenterTabGeometry(CGFloat width, CGFloat height,
                                                         NSUInteger count, CGFloat minimumWidth) {
    TGAquaMediaCenterTabs layout = {0, 0, 0, 0, height - 242.0, 0};
    if (count == 0) return layout;
    CGFloat available = MAX(1.0, width - 48.0);
    minimumWidth = MAX(72.0, minimumWidth);
    NSUInteger capacity = MAX((NSUInteger)1, (NSUInteger)floor((available + 6.0) / (minimumWidth + 6.0)));
    capacity = MIN(count, capacity);
    layout.rows = (count + capacity - 1) / capacity;
    layout.columns = (count + layout.rows - 1) / layout.rows;
    layout.buttonWidth = MAX(1.0, floor((available - 6.0 * (CGFloat)(layout.columns - 1)) / (CGFloat)layout.columns));
    layout.startX = floor((width - (layout.buttonWidth * layout.columns + 6.0 * (layout.columns - 1))) / 2.0);
    layout.extraHeight = 36.0 * (CGFloat)(layout.rows - 1);
    return layout;
}

static NSRect TGAquaMediaCenterTabFrame(TGAquaMediaCenterTabs layout, NSUInteger index) {
    if (layout.columns == 0) return NSZeroRect;
    return NSMakeRect(layout.startX + (layout.buttonWidth + 6.0) * (index % layout.columns),
                      layout.firstY - 36.0 * (CGFloat)(index / layout.columns), layout.buttonWidth, 30.0);
}

/* Resize the existing row views in place. Their content and request ownership stay intact. */
static void TGAquaMediaCenterReflowResults(NSView *results, CGFloat width, BOOL grid, BOOL empty) {
    width = MAX(1.0, floor(width));
    if (fabs(NSWidth([results frame]) - width) < 0.5) return;
    NSArray *rows = [results subviews];
    CGFloat contentHeight = NSHeight([results frame]);
    if (empty) {
        for (NSView *label in rows) {
            NSRect frame = [label frame];
            frame.size.width = MAX(1.0, width - NSMinX(frame) - 18.0);
            [label setFrame:frame];
        }
        contentHeight = 100.0;
    } else if (grid) {
        NSUInteger columns = MAX((NSUInteger)2, (NSUInteger)floor((width + 8.0) / 120.0));
        CGFloat tileWidth = MIN(132.0, floor((width - 8.0 * (CGFloat)(columns + 1)) / (CGFloat)columns));
        tileWidth = MAX(1.0, tileWidth);
        NSUInteger index = 0;
        for (NSView *tile in rows) {
            [tile setFrame:NSMakeRect(8.0 + (tileWidth + 8.0) * (index % columns),
                                      8.0 + 144.0 * (CGFloat)(index / columns), tileWidth, 136.0)];
            index++;
        }
        NSUInteger rowCount = ([rows count] + columns - 1) / columns;
        contentHeight = MAX(100.0, 8.0 + 144.0 * (CGFloat)rowCount);
    } else {
        for (NSView *row in rows) {
            NSRect frame = [row frame];
            frame.size.width = MAX(1.0, width - 16.0);
            [row setFrame:frame];
        }
    }
    [results setFrame:NSMakeRect(0.0, 0.0, width, contentHeight)];
}
