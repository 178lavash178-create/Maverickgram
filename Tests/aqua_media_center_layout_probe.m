#import <Cocoa/Cocoa.h>
#import "TGMediaCenterLayout.h"
#include <assert.h>

@interface TGMediaReflowProbeView : NSView
@property(nonatomic, assign) NSUInteger geometryChanges;
@end
@implementation TGMediaReflowProbeView
@synthesize geometryChanges;
- (void)setFrame:(NSRect)frame { self.geometryChanges++; [super setFrame:frame]; }
@end

static void TGCheckChildrenFit(NSView *row) {
    for (NSView *child in [row subviews]) {
        assert(NSMinX([child frame]) >= 0);
        assert(NSMaxX([child frame]) <= NSWidth([row bounds]) + 0.001);
    }
}

int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    NSArray *titles = [NSArray arrayWithObjects:@"Медиа", @"Файлы", @"Ссылки", @"Музыка", @"Голос", @"GIF", @"Опросы", @"Группы", @"Groups", @"Музыка", @"Спасылкі", nil];
    CGFloat minimumWidth = 72.0;
    for (NSString *title in titles) minimumWidth = MAX(minimumWidth, ceil([title sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:13] forKey:NSFontAttributeName]].width) + 24.0);
    NSUInteger layouts = 0;
    for (CGFloat width = 300; width <= 1100; width += 7) {
        TGAquaMediaCenterTabs g = TGAquaMediaCenterTabGeometry(width, 600, 8, minimumWidth);
        for (NSUInteger i = 0; i < 8; i++) {
            NSRect frame = TGAquaMediaCenterTabFrame(g, i);
            assert(NSMinX(frame) >= 24 && NSMaxX(frame) <= width - 23);
            assert(NSWidth(frame) >= minimumWidth);
            assert(NSHeight(frame) == 30);
            for (NSUInteger j = 0; j < i; j++) assert(!NSIntersectsRect(frame, TGAquaMediaCenterTabFrame(g, j)));
            assert(NSMinY(frame) >= 600 - 242 - g.extraHeight);
        }
        NSRect last = TGAquaMediaCenterTabFrame(g, 7);
        CGFloat statusTop = 600 - 274 - g.extraHeight + 18;
        CGFloat refreshTop = 600 - 282 - g.extraHeight + 30;
        assert(statusTop <= NSMinY(last) - 14);
        assert(refreshTop <= NSMinY(last) - 10);
        layouts++;
    }
    assert(TGAquaMediaCenterTabGeometry(454, 600, 8, minimumWidth).rows == 2);
    assert(TGAquaMediaCenterTabGeometry(674, 600, 8, 72).rows == 1);
    assert(TGAquaMediaCenterTabGeometry(1100, 600, 8, minimumWidth).rows == 1);
    assert(TGAquaMediaCenterTabGeometry(454, 600, 0, minimumWidth).rows == 0);

    TGMediaReflowProbeView *document = [[[TGMediaReflowProbeView alloc] initWithFrame:NSMakeRect(0, 0, 650, 420)] autorelease];
    NSView *row = [[[NSView alloc] initWithFrame:NSMakeRect(8, 8, 634, 74)] autorelease];
    NSView *text = [[[NSView alloc] initWithFrame:NSMakeRect(76, 16, 540, 22)] autorelease];
    [text setAutoresizingMask:NSViewWidthSizable]; [row addSubview:text];
    NSView *hit = [[[NSView alloc] initWithFrame:[row bounds]] autorelease];
    [hit setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable]; [row addSubview:hit];
    [document addSubview:row];
    for (CGFloat width = 260; width < 800; width += 11) {
        TGAquaMediaCenterReflowResults(document, width, NO, NO);
        assert([[document subviews] objectAtIndex:0] == row);
        assert([[row subviews] objectAtIndex:0] == text);
        assert(NSWidth([document frame]) == floor(width));
        assert(NSWidth([row frame]) == floor(width) - 16);
        TGCheckChildrenFit(row);
        assert(NSEqualRects([hit frame], [row bounds]));
        NSUInteger changes = document.geometryChanges;
        TGAquaMediaCenterReflowResults(document, width, NO, NO);
        assert(document.geometryChanges == changes);
    }
    [row removeFromSuperview];
    NSMutableArray *tiles = [NSMutableArray array];
    for (NSUInteger i = 0; i < 17; i++) {
        NSView *tile = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 112, 136)] autorelease];
        NSView *preview = [[[NSView alloc] initWithFrame:NSMakeRect(8, 8, 96, 86)] autorelease];
        [preview setAutoresizingMask:NSViewWidthSizable]; [tile addSubview:preview];
        [document addSubview:tile]; [tiles addObject:tile];
    }
    for (CGFloat width = 260; width < 800; width += 11) {
        TGAquaMediaCenterReflowResults(document, width, YES, NO);
        for (NSUInteger i = 0; i < [tiles count]; i++) {
            NSView *tile = [tiles objectAtIndex:i];
            assert([[document subviews] objectAtIndex:i] == tile);
            assert(NSMinX([tile frame]) >= 8);
            assert(NSMaxX([tile frame]) <= floor(width) - 7);
            assert(NSMaxY([tile frame]) <= NSHeight([document frame]));
            TGCheckChildrenFit(tile);
            for (NSUInteger j = 0; j < i; j++) assert(!NSIntersectsRect([tile frame], [[tiles objectAtIndex:j] frame]));
        }
    }
    NSArray *previous = [[document subviews] copy];
    for (NSView *tile in previous) [tile removeFromSuperview];
    [previous release];
    NSView *empty = [[[NSView alloc] initWithFrame:NSMakeRect(18, 34, 600, 20)] autorelease]; [document addSubview:empty];
    TGAquaMediaCenterReflowResults(document, 365, NO, YES);
    assert(NSWidth([empty frame]) == 329 && NSHeight([document frame]) == 100);
    printf("Aqua media center: %lu full-label tab layouts; in-place list/grid/empty resize and unchanged-width no-op PASS\n", (unsigned long)layouts);
    [pool drain]; return 0;
}
