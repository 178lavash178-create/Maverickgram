#import "TGAquaFolderPresentation.h"
#import "TGLocalization.h"

NSString * const TGAquaFolderPresentationDefaultsKey = @"MaverickgramAquaFoldersUseDrawer";
NSString * const TGAquaFolderPresentationDidChangeNotification = @"TGAquaFolderPresentationDidChangeNotification";

BOOL TGAquaFoldersUseDrawer(void) {
    id saved = [[NSUserDefaults standardUserDefaults] objectForKey:TGAquaFolderPresentationDefaultsKey];
    return [saved isKindOfClass:[NSNumber class]] ? [saved boolValue] : YES;
}
void TGAquaSetFoldersUseDrawer(BOOL useDrawer) {
    if (TGAquaFoldersUseDrawer()==useDrawer) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:useDrawer forKey:TGAquaFolderPresentationDefaultsKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:TGAquaFolderPresentationDidChangeNotification
                                                      object:nil
                                                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:useDrawer] forKey:@"usesDrawer"]];
}

@implementation TGAquaFolderPresentationSettingsView
+ (CGFloat)minimumWidth { return 326.0; }
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _label = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [_label setEditable:NO]; [_label setSelectable:NO]; [_label setBordered:NO]; [_label setDrawsBackground:NO];
    [_label setFont:[NSFont systemFontOfSize:13]];
    [_label setTextColor:[NSColor colorWithCalibratedWhite:0.19 alpha:1]];
    [self addSubview:_label];
    _popUpButton = [[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    [_popUpButton setFont:[NSFont systemFontOfSize:12]];
    [[_popUpButton cell] setLineBreakMode:NSLineBreakByClipping];
    [_popUpButton setTarget:self]; [_popUpButton setAction:@selector(selectionChanged:)];
    [self addSubview:_popUpButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferenceDidChange:) name:TGAquaFolderPresentationDidChangeNotification object:nil];
    [self refreshAppearance];
    [self resizeSubviewsWithOldSize:NSZeroSize];
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    CGFloat height = NSHeight([self bounds]);
    [_label setFrame:NSMakeRect(0,MAX(0,(height-22)/2),88,22)];
    CGFloat popupWidth = MAX(230.0,MIN(290.0,NSWidth([self bounds])-96.0));
    [_popUpButton setFrame:NSMakeRect(96,MAX(0,(height-28)/2),popupWidth,28)];
}
- (void)refreshAppearance {
    [_label setStringValue:TGLoc(@"aqua.folders.presentationLabel")];
    [_popUpButton removeAllItems];
    [_popUpButton addItemsWithTitles:[NSArray arrayWithObjects:TGLoc(@"aqua.folders.drawer"),TGLoc(@"aqua.folders.insideWindow"),nil]];
    [_popUpButton selectItemAtIndex:TGAquaFoldersUseDrawer() ? 0 : 1];
    [_popUpButton setToolTip:TGLoc(@"aqua.folders.presentationHint")];
}
- (void)preferenceDidChange:(NSNotification *)notification { (void)notification; [self refreshAppearance]; }
- (void)selectionChanged:(id)sender {
    (void)sender;
    TGAquaSetFoldersUseDrawer([_popUpButton indexOfSelectedItem]==0);
}
@end
