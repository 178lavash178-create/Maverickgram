#import "TGThemeTextField.h"
#import "TGTheme.h"

@implementation TGThemeTextField
@synthesize themeSurface=_themeSurface, detailInk=_detailInk, errorInk=_errorInk;
- (id)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) {
        _themeSurface=TGThemeSurfaceCard;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDefaultsChanged:)
            name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}
- (void)themeDefaultsChanged:(NSNotification *)notification {
    (void)notification;
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(themeDefaultsChanged:) withObject:nil waitUntilDone:NO]; return;
    }
    if (![_lastTheme isEqual:TGCurrentThemeIdentifier()]) {
        [[[self window] contentView] setNeedsDisplay:YES];
        [self refreshThemeInk]; [self setNeedsDisplay:YES];
    }
}
- (void)refreshThemeInk {
    NSColor *preferred = _errorInk ? [NSColor colorWithCalibratedRed:0.76 green:0.12 blue:0.10 alpha:1.0] :
        (_detailInk ? TGClassicCardMutedInkColor() : TGClassicCardInkColor());
    NSColor *ink=TGThemeSurfaceInkColor(preferred,_themeSurface,4.5);
    if (![[self textColor] isEqual:ink]) { [self setTextColor:ink]; }
    if (![_lastTheme isEqual:TGCurrentThemeIdentifier()]) {
        [_lastTheme release]; _lastTheme=[TGCurrentThemeIdentifier() copy];
    }
}
- (void)drawRect:(NSRect)dirtyRect { [self refreshThemeInk]; [super drawRect:dirtyRect]; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [_lastTheme release]; [super dealloc]; }
@end

@implementation TGThemeSwitchButton
- (id)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) {
        [self setButtonType:NSSwitchButton];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDefaultsChanged:)
            name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}
- (void)themeDefaultsChanged:(NSNotification *)notification {
    (void)notification;
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(themeDefaultsChanged:) withObject:nil waitUntilDone:NO]; return;
    }
    [self refreshThemeInk];
}
- (void)refreshThemeInk {
    NSColor *ink=TGThemeSurfaceInkColor(TGClassicCardInkColor(),TGThemeSurfaceCard,4.5);
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:ink,NSForegroundColorAttributeName,
        [self font] ? [self font] : [NSFont systemFontOfSize:12.0],NSFontAttributeName,nil];
    NSAttributedString *title=[[[NSAttributedString alloc] initWithString:[self title] attributes:attributes] autorelease];
    if (![[self attributedTitle] isEqualToAttributedString:title]) {
        [self setAttributedTitle:title]; [self setAttributedAlternateTitle:title];
        [self setNeedsDisplay:YES];
    }
}
- (void)drawRect:(NSRect)dirtyRect { [self refreshThemeInk]; [super drawRect:dirtyRect]; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [super dealloc]; }
@end
