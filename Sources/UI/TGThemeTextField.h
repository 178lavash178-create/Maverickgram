#import <Cocoa/Cocoa.h>
#import "TGThemeContrast.h"

/* Explicit-surface utility labels; editable native fields keep native colors. */
@interface TGThemeTextField : NSTextField {
    TGThemeSurfaceRole _themeSurface;
    BOOL _detailInk;
    BOOL _errorInk;
    NSString *_lastTheme;
}
@property(nonatomic, assign) TGThemeSurfaceRole themeSurface;
@property(nonatomic, assign) BOOL detailInk;
@property(nonatomic, assign) BOOL errorInk;
- (void)refreshThemeInk;
@end

/* Native checkbox geometry and behavior, with an explicit card-surface title. */
@interface TGThemeSwitchButton : NSButton
- (void)refreshThemeInk;
@end
