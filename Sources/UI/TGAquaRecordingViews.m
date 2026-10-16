#import "TGAquaRecordingViews.h"
#import "TGAquaShellViews.h"

@implementation TGAquaRecordingDisplayView
- (BOOL)isOpaque { return NO; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect rect=NSInsetRect([self bounds],1,1);
    NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:rect xRadius:8 yRadius:8];
    [NSGraphicsContext saveGraphicsState]; [path addClip];
    NSGradient *finish=[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.11 alpha:1]
        endingColor:[NSColor colorWithCalibratedWhite:0.22 alpha:1]] autorelease];
    [finish drawInRect:rect angle:-90];
    // Reuse the approved downloaded linen, rather than synthesizing a texture.
    static NSColor *linen=nil; static BOOL loaded=NO;
    if(!loaded) {
        loaded=YES; NSString *file=[[NSBundle mainBundle] pathForResource:@"black-Linen" ofType:@"png" inDirectory:@"Textures"];
        NSImage *image=file ? [[[NSImage alloc] initWithContentsOfFile:file] autorelease] : nil;
        if(image) linen=[[NSColor colorWithPatternImage:image] retain];
    }
    if(linen) { CGContextSetAlpha((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],0.32); [linen set]; NSRectFillUsingOperation(rect,NSCompositeSourceOver); }
    [NSGraphicsContext restoreGraphicsState];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.7] set];[path setLineWidth:1];[path stroke];
}
@end
NSTextField *TGAquaRecordingLabel(NSRect frame,NSString *text,NSFont *font,BOOL displayInk) {
    NSTextField *label=[[[NSTextField alloc] initWithFrame:frame] autorelease];
    [label setEditable:NO];[label setSelectable:NO];[label setBezeled:NO];[label setDrawsBackground:NO];
    [label setFont:font];[label setAlignment:NSCenterTextAlignment];[label setStringValue:text ? text : @""];
    [label setTextColor:displayInk ? [NSColor colorWithCalibratedRed:0.91 green:0.96 blue:0.91 alpha:1] : [NSColor colorWithCalibratedWhite:0.17 alpha:1]];
    [[label cell] setLineBreakMode:NSLineBreakByTruncatingTail];return label;
}
NSButton *TGAquaRecordingButton(NSRect frame,NSString *title,id target,SEL action,BOOL primary) {
    NSButton *button=[[[NSButton alloc] initWithFrame:frame] autorelease];
    TGAquaTextButtonCell *cell=[[[TGAquaTextButtonCell alloc] initTextCell:title] autorelease];[cell setAccented:primary];
    [button setCell:cell];[button setTitle:title];[button setTarget:target];[button setAction:action];
    [button setBordered:NO];[button setFont:[NSFont boldSystemFontOfSize:12]];[button setToolTip:title];return button;
}
void TGAquaRecordingConfigureClock(NSTextField *clock,CGFloat size) {
    NSFont *font=[NSFont fontWithName:@"Menlo-Bold" size:size];
    [clock setFont:font ? font : [NSFont userFixedPitchFontOfSize:size]];
    [clock setTextColor:[NSColor colorWithCalibratedRed:0.91 green:0.96 blue:0.91 alpha:1]];
    [clock setDrawsBackground:NO];[clock setAlignment:NSCenterTextAlignment];
}
NSRect TGAquaVoiceRecordingClockFrame(void) { return NSMakeRect(120,140,360,38); }
