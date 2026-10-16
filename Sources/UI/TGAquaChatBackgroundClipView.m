#import "TGAquaChatBackgroundClipView.h"
#import "TGAquaChatBackground.h"
#import "TGStatusViewCells.h"

void TGAquaConfigureTranscriptViewport(NSScrollView *scrollView, TGScrollSurfaceView *surfaceView) {
    [surfaceView setSquareEdges:YES];
    [surfaceView setDrawsInterior:NO];
    [scrollView setScrollerStyle:NSScrollerStyleOverlay];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView tile];
}

@implementation TGAquaChatBackgroundClipView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setCopiesOnScroll:NO];
        [self setDrawsBackground:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(backgroundDidChange:)
            name:TGAquaChatBackgroundDidChangeNotification object:nil];
    }
    return self;
}

- (void)setBackgroundAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID {
    if ((_backgroundAccountID == accountID || [_backgroundAccountID isEqual:accountID]) &&
        (_backgroundChatID == chatID || [_backgroundChatID isEqual:chatID])) return;
    [_backgroundAccountID release];
    _backgroundAccountID = [accountID copy];
    [_backgroundChatID release];
    _backgroundChatID = [chatID copy];
    [self setNeedsDisplay:YES];
    [[self documentView] setNeedsDisplay:YES];
}

- (void)backgroundDidChange:(NSNotification *)notification {
    (void)notification;
    [self setNeedsDisplay:YES];
    [[self documentView] setNeedsDisplay:YES];
}

- (BOOL)isOpaque { return YES; }

- (void)drawRect:(NSRect)dirtyRect {
    [[TGAquaChatBackgroundStore sharedStore] drawBackgroundInClipRect:dirtyRect
        viewportRect:[self bounds] flipped:[self isFlipped]
        accountID:_backgroundAccountID chatID:_backgroundChatID];
}

- (void)setBoundsOrigin:(NSPoint)newOrigin {
    BOOL changed = !NSEqualPoints([self bounds].origin, newOrigin);
    [super setBoundsOrigin:newOrigin];
    if (changed) {
        [self setNeedsDisplay:YES];
        [[self documentView] setNeedsDisplay:YES];
    }
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self setNeedsDisplay:YES];
    [[self documentView] setNeedsDisplay:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_backgroundAccountID release];
    [_backgroundChatID release];
    [super dealloc];
}
@end
