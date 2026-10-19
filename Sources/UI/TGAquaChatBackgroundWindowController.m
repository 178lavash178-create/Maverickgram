#import "TGDialogPresentation.h"
#import "TGAquaChatBackgroundWindowController.h"
#import "TGAquaChatBackground.h"
#import "TGAquaAppearance.h"
#import "TGLocalization.h"
#include <math.h>

static NSString *TGAquaBackgroundPresetTitle(NSDictionary *preset) {
    NSString *key = [NSString stringWithFormat:@"title_%@", TGLanguageCode()];
    NSString *title = [preset objectForKey:key];
    if (![title length]) title = [preset objectForKey:@"title_ru"];
    return [title length] ? title : @"";
}

@interface TGAquaBackgroundSwatchCell : NSButtonCell {
    NSDictionary *_configuration;
    BOOL _colorListRow;
}
@property(nonatomic, copy) NSDictionary *configuration;
@property(nonatomic, assign) BOOL colorListRow;
- (NSRect)colorTitleRectForFrame:(NSRect)frame;
- (NSDictionary *)colorTitleAttributes;
@end
@implementation TGAquaBackgroundSwatchCell
@synthesize configuration = _configuration, colorListRow = _colorListRow;
- (id)copyWithZone:(NSZone *)zone {
    TGAquaBackgroundSwatchCell *cell = [super copyWithZone:zone];
    cell->_configuration = [_configuration copy];
    return cell;
}
- (void)dealloc { [_configuration release]; [super dealloc]; }
- (NSDictionary *)colorTitleAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12],NSFontAttributeName,[NSColor colorWithCalibratedWhite:0.16 alpha:1],NSForegroundColorAttributeName,nil];
}
- (NSRect)colorTitleRectForFrame:(NSRect)frame {
    CGFloat height = ceil([@"Ag" sizeWithAttributes:[self colorTitleAttributes]].height);
    return NSMakeRect(NSMinX(frame)+40,floor(NSMidY(frame)-height/2),MAX(0,NSWidth(frame)-46),height);
}
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    if (self.colorListRow) {
        BOOL selected = [self state]==NSOnState;
        NSRect row = NSInsetRect(frame,0.5,0.5);
        if (selected || [self isHighlighted]) {
            NSBezierPath *rowShape = [NSBezierPath bezierPathWithRoundedRect:row xRadius:4 yRadius:4];
            [(selected ? [NSColor colorWithCalibratedRed:0.89 green:0.94 blue:0.99 alpha:1] : [NSColor colorWithCalibratedWhite:0.93 alpha:1]) set];
            [rowShape fill];
            [[NSColor colorWithCalibratedRed:0.42 green:0.60 blue:0.77 alpha:1] set];
            [rowShape setLineWidth:1]; [rowShape stroke];
        }
        NSRect swatch = NSMakeRect(NSMinX(frame)+7,floor(NSMidY(frame)-11),22,22);
        NSBezierPath *shape = [NSBezierPath bezierPathWithRoundedRect:swatch xRadius:3 yRadius:3];
        [NSGraphicsContext saveGraphicsState]; [shape addClip];
        [[TGAquaChatBackgroundStore sharedStore] drawConfiguration:self.configuration clipRect:swatch viewportRect:swatch flipped:[view isFlipped]];
        [NSGraphicsContext restoreGraphicsState];
        [[NSColor colorWithCalibratedWhite:0.55 alpha:1] set]; [shape setLineWidth:1]; [shape stroke];
        // The complete localized name has a dedicated 198pt column. Do not
        // truncate it or substitute an ellipsis as thumbnail captions do.
        [[self title] drawAtPoint:[self colorTitleRectForFrame:frame].origin withAttributes:[self colorTitleAttributes]];
        return;
    }
    CGFloat captionY = [view isFlipped] ? NSMaxY(frame)-14 : NSMinY(frame);
    CGFloat swatchY = [view isFlipped] ? NSMinY(frame)+2 : NSMinY(frame)+17;
    NSRect swatch = NSMakeRect(NSMinX(frame)+2, swatchY, NSWidth(frame)-4, NSHeight(frame)-19);
    NSBezierPath *shape = [NSBezierPath bezierPathWithRoundedRect:swatch xRadius:4 yRadius:4];
    [NSGraphicsContext saveGraphicsState];
    [shape addClip];
    [[TGAquaChatBackgroundStore sharedStore] drawConfiguration:self.configuration clipRect:swatch viewportRect:swatch flipped:[view isFlipped]];
    [NSGraphicsContext restoreGraphicsState];
    BOOL selected = [self state] == NSOnState;
    [(selected ? [NSColor colorWithCalibratedRed:0.14 green:0.34 blue:0.58 alpha:1] : [NSColor colorWithCalibratedWhite:0.55 alpha:1]) set];
    [shape setLineWidth:selected ? 3 : 1]; [shape stroke];
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:NSCenterTextAlignment];
    [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10],NSFontAttributeName,[NSColor colorWithCalibratedWhite:0.16 alpha:1],NSForegroundColorAttributeName,paragraph,NSParagraphStyleAttributeName,nil];
    [[self title] drawInRect:NSMakeRect(NSMinX(frame),captionY,NSWidth(frame),14) withAttributes:attrs];
}
@end

@interface TGAquaBackgroundPreviewView : NSView {
    NSDictionary *_configuration;
}
@property(nonatomic, copy) NSDictionary *configuration;
@end
@implementation TGAquaBackgroundPreviewView
@synthesize configuration = _configuration;
- (void)setConfiguration:(NSDictionary *)configuration {
    if ([_configuration isEqual:configuration]) return;
    [_configuration release]; _configuration = [configuration copy]; [self setNeedsDisplay:YES];
}
- (void)dealloc { [_configuration release]; [super dealloc]; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect bounds = NSInsetRect([self bounds],1,1);
    NSBezierPath *outline = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:7 yRadius:7];
    [NSGraphicsContext saveGraphicsState]; [outline addClip];
    [[TGAquaChatBackgroundStore sharedStore] drawConfiguration:self.configuration clipRect:bounds viewportRect:bounds flipped:[self isFlipped]];
    CGFloat width = MIN(248.0,NSWidth(bounds)-44.0);
    NSRect incoming = NSMakeRect(18,NSHeight(bounds)-124,width,90);
    NSRect outgoing = NSMakeRect(NSWidth(bounds)-width-18,NSHeight(bounds)-222,width,70);
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRoundedRect:incoming xRadius:12 yRadius:12],incoming,TGThemeSurfaceIncoming,[self isFlipped]);
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRoundedRect:outgoing xRadius:12 yRadius:12],outgoing,TGThemeSurfaceOutgoing,[self isFlipped]);
    NSDictionary *nameAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12],NSFontAttributeName,[NSColor colorWithCalibratedRed:0.18 green:0.35 blue:0.51 alpha:1],NSForegroundColorAttributeName,nil];
    [@"Maverickgram" drawAtPoint:NSMakePoint(NSMinX(incoming)+12,NSMaxY(incoming)-23) withAttributes:nameAttrs];
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setLineBreakMode:NSLineBreakByWordWrapping];
    NSDictionary *bodyAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12],NSFontAttributeName,[NSColor colorWithCalibratedWhite:0.13 alpha:1],NSForegroundColorAttributeName,paragraph,NSParagraphStyleAttributeName,nil];
    [TGLoc(@"aqua.background.previewIncoming") drawInRect:NSMakeRect(NSMinX(incoming)+12,NSMinY(incoming)+23,width-24,40) withAttributes:bodyAttrs];
    [TGLoc(@"aqua.background.previewOutgoing") drawInRect:NSMakeRect(NSMinX(outgoing)+12,NSMinY(outgoing)+23,width-24,34) withAttributes:bodyAttrs];
    NSDictionary *timeAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10],NSFontAttributeName,[NSColor colorWithCalibratedWhite:0.35 alpha:1],NSForegroundColorAttributeName,nil];
    [@"13:40" drawAtPoint:NSMakePoint(NSMaxX(incoming)-42,NSMinY(incoming)+7) withAttributes:timeAttrs];
    [@"13:41" drawAtPoint:NSMakePoint(NSMaxX(outgoing)-42,NSMinY(outgoing)+7) withAttributes:timeAttrs];
    [NSGraphicsContext restoreGraphicsState];
    [[NSColor colorWithCalibratedWhite:0.55 alpha:1] set]; [outline setLineWidth:1]; [outline stroke];
}
@end

@interface TGAquaChatBackgroundWindowController ()
- (void)reloadDrafts;
- (void)discardUnusedImports;
- (void)stageImportedConfiguration:(NSDictionary *)configuration;
- (void)refreshPreview;
- (void)scopeChanged:(id)sender;
- (void)colorSelected:(id)sender;
- (void)textureSelected:(id)sender;
- (void)wallpaperSelected:(id)sender;
- (void)modeChanged:(id)sender;
- (void)chooseImage:(id)sender;
- (void)restoreDefault:(id)sender;
- (void)inheritCommon:(id)sender;
- (void)applyChanges:(id)sender;
- (void)cancelChanges:(id)sender;
@end

@implementation TGAquaChatBackgroundWindowController
- (NSTextField *)label:(NSString *)text frame:(NSRect)frame font:(NSFont *)font {
    NSTextField *label = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [label setEditable:NO]; [label setSelectable:NO]; [label setBordered:NO]; [label setDrawsBackground:NO];
    [label setFont:font]; [label setStringValue:text ? text : @""];
    [label setTextColor:[NSColor colorWithCalibratedWhite:0.19 alpha:1]];
    [[[self window] contentView] addSubview:label]; return label;
}
- (NSButton *)button:(NSString *)title frame:(NSRect)frame action:(SEL)action {
    NSButton *button = [[[NSButton alloc] initWithFrame:frame] autorelease];
    [button setTitle:title]; [button setBezelStyle:NSRoundedBezelStyle];
    [button setFont:[NSFont systemFontOfSize:12]]; [button setTarget:self]; [button setAction:action];
    [[[self window] contentView] addSubview:button]; return button;
}
- (NSArray *)presetButtons:(NSArray *)presets inView:(NSView *)parent mode:(NSUInteger)mode action:(SEL)action {
    NSMutableArray *buttons = [NSMutableArray array];
    NSUInteger index = 0;
    for (NSDictionary *preset in presets) {
        NSRect frame;
        if (mode==0) frame = NSMakeRect(0,248-index*30,244,30);
        else if (mode==1) frame = NSMakeRect(0,232-index*55,244,48);
        else {
            CGFloat x = (index%2)*128;
            if (index+1==[presets count] && [presets count]%2) x = 64;
            frame = NSMakeRect(x,214-(index/2)*82,116,72);
        }
        NSButton *button = [[[NSButton alloc] initWithFrame:frame] autorelease];
        TGAquaBackgroundSwatchCell *cell = [[[TGAquaBackgroundSwatchCell alloc] initTextCell:TGAquaBackgroundPresetTitle(preset)] autorelease];
        cell.configuration = [TGAquaChatBackgroundStore configurationForPresetIdentifier:[preset objectForKey:@"id"]];
        cell.colorListRow = (mode==0);
        [button setCell:cell]; [button setButtonType:NSPushOnPushOffButton]; [button setBordered:NO];
        [button setTarget:self]; [button setAction:action]; [button setToolTip:TGAquaBackgroundPresetTitle(preset)];
        [parent addSubview:button]; [buttons addObject:button]; index++;
    }
    return buttons;
}
- (id)initWithAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID chatTitle:(NSString *)chatTitle {
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,760,610) styleMask:(NSTitledWindowMask|NSClosableWindowMask) backing:NSBackingStoreBuffered defer:NO] autorelease];
    self = [super initWithWindow:window];
    if (!self) return nil;
    if ([accountID isKindOfClass:[NSNumber class]] && [accountID longLongValue]>0 && [chatID isKindOfClass:[NSNumber class]] && [chatID longLongValue]!=0) {
        _accountID = [accountID copy]; _chatID = [chatID copy];
    }
    _chatTitle = [([chatTitle length] ? chatTitle : TGLoc(@"chats")) copy];
    _drafts = [[NSMutableDictionary alloc] init]; _changedScopes = [[NSMutableSet alloc] init];
    _importedConfigurations = [[NSMutableArray alloc] init];
    _modeChoices = [[NSMutableDictionary alloc] init];
    [window setTitle:TGLoc(@"aqua.background.windowTitle")]; [window setReleasedWhenClosed:NO]; [window setDelegate:self]; [window center];
    NSView *content = [window contentView];
    [self label:TGLoc(@"aqua.background.scope") frame:NSMakeRect(24,555,58,22) font:[NSFont systemFontOfSize:13]];
    _scopePopUp = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(82,550,654,30) pullsDown:NO] autorelease];
    [_scopePopUp addItemWithTitle:TGLoc(@"aqua.background.scopeCommon")];
    if (_chatID) [_scopePopUp addItemWithTitle:[NSString stringWithFormat:TGLoc(@"aqua.background.scopeChat"),_chatTitle]];
    [_scopePopUp setTarget:self]; [_scopePopUp setAction:@selector(scopeChanged:)]; [content addSubview:_scopePopUp];
    _scopeHint = [self label:@"" frame:NSMakeRect(24,506,712,36) font:[NSFont systemFontOfSize:12]];
    [[_scopeHint cell] setWraps:YES];
    [self label:TGLoc(@"aqua.background.type") frame:NSMakeRect(24,476,244,22) font:[NSFont boldSystemFontOfSize:12]];
    _modeControl = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(24,444,244,28) pullsDown:NO] autorelease];
    NSArray *modeKeys = [NSArray arrayWithObjects:@"aqua.background.colors",@"aqua.background.textures",@"aqua.background.images",nil];
    for (NSString *key in modeKeys) [_modeControl addItemWithTitle:TGLoc(key)];
    [_modeControl setFont:[NSFont systemFontOfSize:12]];
    [[_modeControl cell] setLineBreakMode:NSLineBreakByClipping];
    [_modeControl setTarget:self]; [_modeControl setAction:@selector(modeChanged:)]; [content addSubview:_modeControl];
    _colorPane = [[[NSView alloc] initWithFrame:NSMakeRect(24,150,244,286)] autorelease];
    _texturePane = [[[NSView alloc] initWithFrame:NSMakeRect(24,150,244,286)] autorelease];
    _imagePane = [[[NSView alloc] initWithFrame:NSMakeRect(24,150,244,286)] autorelease];
    [content addSubview:_colorPane]; [content addSubview:_texturePane]; [content addSubview:_imagePane];
    NSMutableArray *colors = [NSMutableArray array], *textures = [NSMutableArray array], *wallpapers = [NSMutableArray array];
    for (NSDictionary *preset in [TGAquaChatBackgroundStore presets]) {
        NSString *kind = [preset objectForKey:@"kind"];
        if ([kind isEqualToString:@"color"]) [colors addObject:preset];
        else if ([kind isEqualToString:@"texture"]) [textures addObject:preset];
        else if ([kind isEqualToString:@"wallpaper"]) [wallpapers addObject:preset];
    }
    _colorButtons = [[self presetButtons:colors inView:_colorPane mode:0 action:@selector(colorSelected:)] retain];
    _textureButtons = [[self presetButtons:textures inView:_texturePane mode:1 action:@selector(textureSelected:)] retain];
    _wallpaperButtons = [[self presetButtons:wallpapers inView:_imagePane mode:2 action:@selector(wallpaperSelected:)] retain];
    NSButton *chooseImage = [self button:TGLoc(@"aqua.background.chooseImage") frame:NSMakeRect(0,2,244,32) action:@selector(chooseImage:)];
    [chooseImage retain]; [chooseImage removeFromSuperview]; [_imagePane addSubview:chooseImage]; [chooseImage release];
    _imageNameField = [self label:@"" frame:NSMakeRect(24,122,244,22) font:[NSFont systemFontOfSize:11]];
    [[_imageNameField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [self label:TGLoc(@"aqua.background.preview") frame:NSMakeRect(292,476,444,22) font:[NSFont boldSystemFontOfSize:12]];
    _previewView = [[[TGAquaBackgroundPreviewView alloc] initWithFrame:NSMakeRect(292,122,444,342)] autorelease];
    [content addSubview:_previewView];
    NSBox *separator = [[[NSBox alloc] initWithFrame:NSMakeRect(24,106,712,1)] autorelease]; [separator setBoxType:NSBoxSeparator]; [content addSubview:separator];
    NSTextField *note = [self label:TGLoc(@"aqua.background.localNote") frame:NSMakeRect(24,62,712,34) font:[NSFont systemFontOfSize:11]];
    [[note cell] setWraps:YES]; [note setTextColor:[NSColor colorWithCalibratedWhite:0.38 alpha:1]];
    [self button:TGLoc(@"aqua.background.restoreWhite") frame:NSMakeRect(24,20,196,32) action:@selector(restoreDefault:)];
    _inheritButton = [self button:TGLoc(@"aqua.background.inherit") frame:NSMakeRect(232,20,258,32) action:@selector(inheritCommon:)];
    NSButton *cancel = [self button:TGLoc(@"cancel") frame:NSMakeRect(504,20,110,32) action:@selector(cancelChanges:)]; [cancel setKeyEquivalent:@"\033"];
    NSButton *apply = [self button:TGLoc(@"apply") frame:NSMakeRect(626,20,110,32) action:@selector(applyChanges:)]; [apply setKeyEquivalent:@"\r"];
    [self reloadDrafts]; return self;
}
- (void)dealloc {
    [[self window] setDelegate:nil];
    [self discardUnusedImports];
    [_importedConfigurations release];
    [_accountID release]; [_chatID release]; [_chatTitle release]; [_drafts release]; [_changedScopes release]; [_colorButtons release]; [_textureButtons release]; [_wallpaperButtons release]; [_modeChoices release];
    [super dealloc];
}
- (void)showWindow:(id)sender { [self reloadDrafts]; TGFitUtilityWindowToVisibleScreen([self window]); [super showWindow:sender]; }
- (NSString *)scopeKey { return [_scopePopUp indexOfSelectedItem]==1 && _chatID ? @"chat" : @"common"; }
- (void)discardUnusedImports {
    for (NSDictionary *configuration in _importedConfigurations) [[TGAquaChatBackgroundStore sharedStore] discardImportedConfiguration:configuration];
    [_importedConfigurations removeAllObjects];
}
- (void)windowWillClose:(NSNotification *)notification { (void)notification; [self discardUnusedImports]; }
- (void)reloadDrafts {
    [self discardUnusedImports];
    [_changedScopes removeAllObjects]; [_drafts removeAllObjects]; [_modeChoices removeAllObjects];
    TGAquaChatBackgroundStore *store = [TGAquaChatBackgroundStore sharedStore];
    [_drafts setObject:([store overrideConfigurationForAccountID:nil chatID:nil] ? [store overrideConfigurationForAccountID:nil chatID:nil] : (id)[NSNull null]) forKey:@"common"];
    if (_chatID) [_drafts setObject:([store overrideConfigurationForAccountID:_accountID chatID:_chatID] ? [store overrideConfigurationForAccountID:_accountID chatID:_chatID] : (id)[NSNull null]) forKey:@"chat"];
    [self refreshPreview];
}
- (NSDictionary *)previewConfiguration {
    id draft = [_drafts objectForKey:[self scopeKey]];
    if (draft==[NSNull null] && [[self scopeKey] isEqualToString:@"chat"]) draft = [_drafts objectForKey:@"common"];
    return [draft isKindOfClass:[NSDictionary class]] ? draft : [TGAquaChatBackgroundStore defaultConfiguration];
}
- (NSInteger)modeForConfiguration:(NSDictionary *)configuration {
    NSString *kind = [configuration objectForKey:@"kind"];
    if ([kind isEqualToString:@"texture"]) return 1;
    return ([kind isEqualToString:@"image"] || [kind isEqualToString:@"wallpaper"]) ? 2 : 0;
}
- (NSString *)modeKey:(NSInteger)mode { return [NSString stringWithFormat:@"%@:%ld",[self scopeKey],(long)mode]; }
- (void)refreshPreview {
    NSDictionary *configuration = [self previewConfiguration];
    [(TGAquaBackgroundPreviewView *)_previewView setConfiguration:configuration];
    BOOL chat = [[self scopeKey] isEqualToString:@"chat"];
    [_scopeHint setStringValue:TGLoc(chat ? @"aqua.background.chatHint" : @"aqua.background.commonHint")];
    [_inheritButton setHidden:!chat];
    NSInteger mode = [self modeForConfiguration:configuration];
    [_modeControl selectItemAtIndex:mode];
    [_colorPane setHidden:mode!=0]; [_texturePane setHidden:mode!=1]; [_imagePane setHidden:mode!=2];
    if (configuration) [_modeChoices setObject:configuration forKey:[self modeKey:mode]];
    NSString *description = nil;
    for (NSArray *buttons in [NSArray arrayWithObjects:_colorButtons,_textureButtons,_wallpaperButtons,nil]) {
        for (NSButton *button in buttons) {
            BOOL selected = [[(TGAquaBackgroundSwatchCell *)[button cell] configuration] isEqual:configuration];
            [button setState:selected ? NSOnState : NSOffState];
            if (selected) description = [button toolTip];
        }
    }
    BOOL inherited = chat && [_drafts objectForKey:@"chat"]==[NSNull null];
    if (inherited) description = TGLoc(@"aqua.background.inherited");
    else if ([[configuration objectForKey:@"kind"] isEqualToString:@"image"]) description = TGLoc(@"aqua.background.customImage");
    [_imageNameField setStringValue:description ? description : TGLoc(@"aqua.background.imageHint")];
}
- (void)stageConfiguration:(NSDictionary *)configuration {
    NSString *scope = [self scopeKey];
    [_drafts setObject:configuration ? (id)configuration : (id)[NSNull null] forKey:scope];
    [_changedScopes addObject:scope]; [self refreshPreview];
}
- (void)scopeChanged:(id)sender { (void)sender; [self refreshPreview]; }
- (void)colorSelected:(id)sender { [self stageConfiguration:[(TGAquaBackgroundSwatchCell *)[sender cell] configuration]]; }
- (void)textureSelected:(id)sender { [self stageConfiguration:[(TGAquaBackgroundSwatchCell *)[sender cell] configuration]]; }
- (void)wallpaperSelected:(id)sender { [self stageConfiguration:[(TGAquaBackgroundSwatchCell *)[sender cell] configuration]]; }
- (void)modeChanged:(id)sender {
    (void)sender; NSInteger mode = [_modeControl indexOfSelectedItem];
    NSDictionary *configuration = [_modeChoices objectForKey:[self modeKey:mode]];
    if (!configuration) {
        NSArray *buttons = mode==1 ? _textureButtons : _wallpaperButtons;
        configuration = mode==0 ? [TGAquaChatBackgroundStore defaultConfiguration] : ([buttons count] ? [(TGAquaBackgroundSwatchCell *)[[buttons objectAtIndex:0] cell] configuration] : nil);
    }
    // Browsing an already selected category must not turn an inherited choice
    // into an unnecessary per-chat override.
    if (configuration && ![configuration isEqual:[self previewConfiguration]]) [self stageConfiguration:configuration];
    else [self refreshPreview];
}

- (void)showError:(NSError *)error title:(NSString *)title {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease]; [alert setMessageText:title];
    [alert setInformativeText:[error localizedDescription] ? [error localizedDescription] : TGLoc(@"aqua.background.errorGeneric")]; TGRunAlert(alert, [self window]);
}
- (void)chooseImage:(id)sender {
    (void)sender;
    // AppKit's modal loop can deliver logout/window-close callbacks. Keep the
    // action target alive, and do not stage a choice after its owner was closed.
    [self retain];
    @try {
        NSOpenPanel *panel = [NSOpenPanel openPanel]; [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"png",@"jpg",@"jpeg",nil]];
        [panel setCanChooseFiles:YES]; [panel setCanChooseDirectories:NO]; [panel setAllowsMultipleSelection:NO];
        NSInteger result = TGRunFilePanel(panel, [self window]);
        if (result!=NSOKButton || ![[self window] isVisible]) return;
        NSError *error = nil;
        NSDictionary *configuration = [[TGAquaChatBackgroundStore sharedStore] importImageAtURL:[panel URL] error:&error];
        if (!configuration) { [self showError:error title:TGLoc(@"aqua.background.importErrorTitle")]; return; }
        [self stageImportedConfiguration:configuration];
    } @finally {
        [self release];
    }
}
- (void)stageImportedConfiguration:(NSDictionary *)configuration {
    [_importedConfigurations addObject:configuration];
    [self stageConfiguration:configuration];
}
- (void)restoreDefault:(id)sender { (void)sender; [self stageConfiguration:[TGAquaChatBackgroundStore defaultConfiguration]]; }
- (void)inheritCommon:(id)sender { (void)sender; if (_chatID) [self stageConfiguration:nil]; }
- (void)applyChanges:(id)sender {
    (void)sender;
    for (NSString *scope in [NSArray arrayWithObjects:@"common",@"chat",nil]) {
        if (![_changedScopes containsObject:scope]) continue;
        id configuration = [_drafts objectForKey:scope];
        NSError *error = nil; BOOL chat = [scope isEqualToString:@"chat"];
        if (![[TGAquaChatBackgroundStore sharedStore] setConfiguration:(configuration==[NSNull null] ? nil : configuration) forAccountID:(chat ? _accountID : nil) chatID:(chat ? _chatID : nil) error:&error]) {
            [self showError:error title:TGLoc(@"aqua.background.saveErrorTitle")]; return;
        }
        [_changedScopes removeObject:scope];
    }
    [self discardUnusedImports];
    [self close];
}
- (void)cancelChanges:(id)sender { (void)sender; [self reloadDrafts]; [self close]; }
@end
