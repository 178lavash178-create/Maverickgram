#import <Cocoa/Cocoa.h>

#pragma GCC visibility push(default)

NSImage *TGIconAssetImageNamed(NSString *name);
NSImage *TGTemplateIconAssetImage(NSString *name, NSSize size, NSColor *color, CGFloat alpha);
void TGDrawTemplateIconAsset(NSString *name, NSRect rect, NSColor *color, CGFloat alpha, BOOL flipped);

NSImage *TGOutlinedTemplateIconAssetImage(NSString *name, NSSize size, NSColor *fill, NSColor *outline, CGFloat width);
void TGDrawOutlinedTemplateIconAsset(NSString *name, NSRect rect, NSColor *fill, NSColor *outline, CGFloat width, BOOL flipped);

#pragma GCC visibility pop
