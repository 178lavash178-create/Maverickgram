#import <Cocoa/Cocoa.h>
@class TGMessageItem;

// Frames use a top-down local coordinate system, independent of view flipping.
NSArray *TGReactionChipLayoutForItem(TGMessageItem *item, CGFloat innerWidth);
CGFloat TGReactionChipsMinimumWidthForItem(TGMessageItem *item);
CGFloat TGReactionChipsHeightForItem(TGMessageItem *item, CGFloat innerWidth);
void TGDrawReactionChipsForItem(TGMessageItem *item, NSRect bandRect, BOOL flipped);

NSColor *TGReactionChipBackgroundColor(BOOL chosen);
NSColor *TGReactionChipInkColor(BOOL chosen);

// Centers visible glyph ink, including legacy emoji fallback text.
void TGDrawReactionTextVerticallyCentered(NSString *text, NSFont *font, NSColor *color, NSRect rect, BOOL flipped);
