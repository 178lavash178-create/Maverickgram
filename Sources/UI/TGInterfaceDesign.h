#import <Cocoa/Cocoa.h>

extern NSString * const TGInterfaceDesignDefaultsKey;
extern NSString * const TGInterfaceDesignClassic;
extern NSString * const TGInterfaceDesignAqua;

/* Latched on first access for the lifetime of this process. */
NSString *TGInterfaceDesignIdentifier(void);
BOOL TGInterfaceDesignIsAqua(void);

/* Main-thread only. YES means unchanged or confirmed and restart scheduled.
 * NO with nil error means the user declined; other failures return an error.
 * The setting is staged only after the helper is ready and persistence succeeds.
 * If normal termination is canceled/deferred, the setting is restored and the
 * restart is disarmed. The helper opens the app only after actual process exit. */
BOOL TGRequestInterfaceDesignChange(NSString *identifier, NSWindow *parentWindow, NSError **error);
