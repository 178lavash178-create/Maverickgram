#import "TGDialogPresentation.h"
#import "TGInterfaceDesign.h"
#import "TGLocalization.h"
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

NSString * const TGInterfaceDesignDefaultsKey = @"TelegraphicaInterfaceDesign";
NSString * const TGInterfaceDesignClassic = @"classic";
NSString * const TGInterfaceDesignAqua = @"aqua";

NSString *TGInterfaceDesignIdentifier(void) {
    static NSString *identifier = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:TGInterfaceDesignDefaultsKey];
        identifier = [([saved isEqualToString:TGInterfaceDesignAqua] ? TGInterfaceDesignAqua : TGInterfaceDesignClassic) copy];
    });
    return identifier;
}
BOOL TGInterfaceDesignIsAqua(void) { return [TGInterfaceDesignIdentifier() isEqualToString:TGInterfaceDesignAqua]; }

static NSString *TGInterfaceText(NSString *ru, NSString *be, NSString *en) {
    NSString *language = TGLanguageCode();
    return [language isEqualToString:@"be"] ? be : ([language isEqualToString:@"en"] ? en : ru);
}
static NSError *TGInterfaceError(NSInteger code, NSString *description) {
    return [NSError errorWithDomain:@"Telegraphica.InterfaceDesign" code:code
        userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
}

/* Only constant shell source is executed. Paths and PID are positional arguments,
 * never shell source. The helper cannot launch until will-terminate arms it AND
 * the exact old process exits. A canceled/deferred termination removes its gate.
 * Two bounded waits also cover failed shutdowns without killing the application. */
static NSString *TGInterfaceRestartScript(void) {
    return @"pid=$1\nbundle=$2\ngate=$3\n"
        "cleanup() { /bin/rm -f \"$gate/ready\" \"$gate/go\"; /bin/rmdir \"$gate\" 2>/dev/null; }\n"
        "trap cleanup EXIT\n"
        "[ -d \"$gate\" ] || exit 1\n"
        ": > \"$gate/ready\" || exit 1\n"
        "i=0\nwhile [ $i -lt 60 ]; do\n"
        "  [ -d \"$gate\" ] || exit 0\n"
        "  [ -f \"$gate/go\" ] && break\n"
        "  /bin/kill -0 \"$pid\" 2>/dev/null || exit 0\n"
        "  /bin/sleep 1\n  i=$((i + 1))\ndone\n"
        "[ -f \"$gate/go\" ] || exit 0\n"
        "i=0\nwhile /bin/kill -0 \"$pid\" 2>/dev/null; do\n"
        "  [ -d \"$gate\" ] || exit 0\n"
        "  [ $i -lt 60 ] || exit 0\n"
        "  /bin/sleep 1\n  i=$((i + 1))\ndone\n"
        "[ -f \"$gate/go\" ] || exit 0\n"
        "/usr/bin/open \"$bundle\"\n";
}
static NSArray *TGInterfaceRestartArguments(pid_t pid, NSString *bundlePath, NSString *gate) {
    return [NSArray arrayWithObjects:@"-c", TGInterfaceRestartScript(), @"telegraphica-interface-restart",
        [NSString stringWithFormat:@"%ld", (long)pid], bundlePath, gate, nil];
}

@interface TGInterfaceRestartRequest : NSObject {
    NSString *_identifier;
    NSString *_gate;
    id _previousPreference;
    NSTask *_helper;
    BOOL _committed;
}
- (id)initWithIdentifier:(NSString *)identifier;
- (BOOL)prepareForBundlePath:(NSString *)bundlePath error:(NSError **)error;
- (BOOL)stagePreference:(NSError **)error;
- (void)requestTermination;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (void)disarm;
@end
static TGInterfaceRestartRequest *TGInterfacePendingRestart = nil;

@implementation TGInterfaceRestartRequest
- (id)initWithIdentifier:(NSString *)identifier {
    if ((self=[super init])) { _identifier=[identifier copy]; }
    return self;
}
- (BOOL)prepareForBundlePath:(NSString *)bundlePath error:(NSError **)error {
    NSBundle *bundle=[NSBundle bundleWithPath:bundlePath];
    NSString *executable=[bundle executablePath];
    if (![[bundlePath pathExtension] isEqualToString:@"app"] || ![bundlePath isAbsolutePath] ||
        ![[NSFileManager defaultManager] isExecutableFileAtPath:executable]) {
        if (error) { *error=TGInterfaceError(2,TGInterfaceText(@"Не удалось найти приложение для перезапуска.",@"Не ўдалося знайсці праграму для перазапуску.",@"The application could not be found for restarting.")); }
        return NO;
    }
    NSString *templatePath=[NSTemporaryDirectory() stringByAppendingPathComponent:@"Telegraphica-interface.XXXXXX"];
    char *buffer=strdup([templatePath fileSystemRepresentation]);
    char *created=mkdtemp(buffer);
    if (created) { _gate=[[[NSFileManager defaultManager] stringWithFileSystemRepresentation:created length:strlen(created)] copy]; }
    free(buffer);
    if (!_gate) {
        if (error) { *error=TGInterfaceError(3,TGInterfaceText(@"Не удалось подготовить перезапуск.",@"Не ўдалося падрыхтаваць перазапуск.",@"Could not prepare the restart.")); }
        return NO;
    }
    _helper=[[NSTask alloc] init];
    [_helper setLaunchPath:@"/bin/sh"];
    [_helper setArguments:TGInterfaceRestartArguments(getpid(),bundlePath,_gate)];
    [_helper setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [_helper setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [_helper setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    @try { [_helper launch]; }
    @catch (NSException *exception) {
        (void)exception;
        [self disarm];
        if (error) { *error=TGInterfaceError(4,TGInterfaceText(@"Не удалось запустить помощник перезапуска.",@"Не ўдалося запусціць памочнік перазапуску.",@"Could not start the restart helper.")); }
        return NO;
    }
    NSString *ready=[_gate stringByAppendingPathComponent:@"ready"];
    // Startup handshake only: at most two seconds, usually a few milliseconds.
    NSUInteger attempt;
    for (attempt=0;attempt<200;attempt++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:ready]) { break; }
        if (![_helper isRunning]) { break; }
        [NSThread sleepForTimeInterval:0.01];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:ready] || ![_helper isRunning]) {
        [self disarm];
        if (error) { *error=TGInterfaceError(5,TGInterfaceText(@"Помощник перезапуска не ответил.",@"Памочнік перазапуску не адказаў.",@"The restart helper did not respond.")); }
        return NO;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)
        name:NSApplicationWillTerminateNotification object:NSApp];
    return YES;
}
- (BOOL)stagePreference:(NSError **)error {
    if (![_helper isRunning]) {
        if (error) { *error=TGInterfaceError(6,TGInterfaceText(@"Помощник перезапуска остановился.",@"Памочнік перазапуску спыніўся.",@"The restart helper stopped.")); }
        return NO;
    }
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [_previousPreference release];
    _previousPreference=[[defaults objectForKey:TGInterfaceDesignDefaultsKey] retain];
    [defaults setObject:_identifier forKey:TGInterfaceDesignDefaultsKey];
    _committed=YES;
    if (![defaults synchronize]) {
        [self disarm];
        if (error) { *error=TGInterfaceError(7,TGInterfaceText(@"Не удалось сохранить оформление. Приложение останется открытым.",@"Не ўдалося захаваць афармленне. Праграма застанецца адкрытай.",@"Could not save the design. The application will remain open.")); }
        return NO;
    }
    return YES;
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    if (!_committed || ![_helper isRunning]) { return; }
    if (![[NSData data] writeToFile:[_gate stringByAppendingPathComponent:@"go"] atomically:YES]) { [self disarm]; }
}
- (void)requestTermination {
    [NSApp terminate:self];
    // A normal successful termination never returns. Disarm on Cancel or Later;
    // a subsequent unrelated quit must never launch a second application.
    [self disarm];
    [TGInterfacePendingRestart release]; TGInterfacePendingRestart=nil;
}
- (void)disarm {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_committed) {
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        if (_previousPreference) { [defaults setObject:_previousPreference forKey:TGInterfaceDesignDefaultsKey]; }
        else { [defaults removeObjectForKey:TGInterfaceDesignDefaultsKey]; }
        [defaults synchronize]; _committed=NO;
    }
    if (_gate) {
        NSFileManager *files=[NSFileManager defaultManager];
        [files removeItemAtPath:[_gate stringByAppendingPathComponent:@"go"] error:NULL];
        [files removeItemAtPath:[_gate stringByAppendingPathComponent:@"ready"] error:NULL];
        [files removeItemAtPath:_gate error:NULL];
    }
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_identifier release]; [_gate release]; [_previousPreference release]; [_helper release];
    [super dealloc];
}
@end

BOOL TGRequestInterfaceDesignChange(NSString *identifier, NSWindow *parentWindow, NSError **error) {
    if (error) { *error=nil; }
    if (![NSThread isMainThread] || (![identifier isEqualToString:TGInterfaceDesignClassic] && ![identifier isEqualToString:TGInterfaceDesignAqua])) {
        if (error) { *error=TGInterfaceError(1,TGInterfaceText(@"Не удалось изменить оформление.",@"Не ўдалося змяніць афармленне.",@"Could not change the interface design.")); }
        return NO;
    }
    if ([identifier isEqualToString:TGInterfaceDesignIdentifier()]) { return YES; }
    if (TGInterfacePendingRestart) {
        if (error) { *error=TGInterfaceError(8,TGInterfaceText(@"Перезапуск уже подготовлен.",@"Перазапуск ужо падрыхтаваны.",@"A restart is already scheduled.")); }
        return NO;
    }
    NSAlert *alert=[[[NSAlert alloc] init] autorelease];
    [alert setMessageText:TGInterfaceText(@"Перезапустить Telegraphica?",@"Перазапусціць Telegraphica?",@"Restart Telegraphica?")];
    [alert setInformativeText:TGInterfaceText(@"Новое оформление появится после перезапуска. Перезапустить сейчас?",@"Новае афармленне з’явіцца пасля перазапуску. Перазапусціць зараз?",@"The new design will appear after restarting. Restart now?")];
    [alert addButtonWithTitle:TGInterfaceText(@"Да, перезапустить",@"Так, перазапусціць",@"Yes, restart")];
    [alert addButtonWithTitle:TGInterfaceText(@"Нет",@"Не",@"No")];
    [[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\e"];
    if (parentWindow) { [parentWindow makeKeyAndOrderFront:nil]; }
    if (TGRunAlert(alert, parentWindow)!=NSAlertFirstButtonReturn) { return NO; }
    TGInterfaceRestartRequest *request=[[[TGInterfaceRestartRequest alloc] initWithIdentifier:identifier] autorelease];
    if (![request prepareForBundlePath:[[NSBundle mainBundle] bundlePath] error:error]) { return NO; }
    if (![request stagePreference:error]) { [request disarm]; return NO; }
    TGInterfacePendingRestart=[request retain];
    [request performSelector:@selector(requestTermination) withObject:nil afterDelay:0.0];
    return YES;
}
