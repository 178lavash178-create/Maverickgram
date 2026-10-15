#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#include <sys/stat.h>
#include <unistd.h>
#import "../Sources/UI/TGInterfaceDesign.m"

NSString *TGLanguageCode(void) { return @"en"; }
// Isolate preference state from the user's app domain and make failed persistence
// deterministic even when this probe runs in a filesystem sandbox.
@interface ProbeDefaults : NSUserDefaults { NSMutableDictionary *_values; }
@property(nonatomic,assign) BOOL persistenceWorks;
@end
@implementation ProbeDefaults
@synthesize persistenceWorks=_persistenceWorks;
- (id)init { if ((self=[super init])) { _values=[[NSMutableDictionary alloc] init]; _persistenceWorks=YES; } return self; }
- (id)objectForKey:(NSString *)key { return [_values objectForKey:key]; }
- (NSString *)stringForKey:(NSString *)key { return [_values objectForKey:key]; }
- (void)setObject:(id)value forKey:(NSString *)key { [_values setObject:value forKey:key]; }
- (void)removeObjectForKey:(NSString *)key { [_values removeObjectForKey:key]; }
- (BOOL)synchronize { return _persistenceWorks; }
- (void)dealloc { [_values release]; [super dealloc]; }
@end
static ProbeDefaults *IsolatedDefaults;
static id StandardProbeDefaults(id self, SEL selector) { (void)self; (void)selector; return IsolatedDefaults; }
static void Require(BOOL value, const char *label) {
    if (!value) { fprintf(stderr,"Interface design probe failed: %s\n",label); exit(1); }
}
static NSInteger DeclineAlert(id self, SEL selector) { (void)self; (void)selector; return NSAlertSecondButtonReturn; }
static NSTask *RunHelper(NSString *script, pid_t pid, NSString *bundle, NSString *gate) {
    NSMutableArray *arguments=[NSMutableArray arrayWithArray:TGInterfaceRestartArguments(pid,bundle,gate)];
    [arguments replaceObjectAtIndex:1 withObject:script];
    NSTask *task=[[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/bin/sh"]; [task setArguments:arguments];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    [task launch]; return task;
}
static void MakeGate(NSString *gate) {
    Require([[NSFileManager defaultManager] createDirectoryAtPath:gate withIntermediateDirectories:NO attributes:nil error:NULL],"create test gate");
}
int main(int argc, const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    IsolatedDefaults=[[ProbeDefaults alloc] init];
    Method defaultsMethod=class_getClassMethod([NSUserDefaults class],@selector(standardUserDefaults));
    IMP defaultsOriginal=method_setImplementation(defaultsMethod,(IMP)StandardProbeDefaults);
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    id saved=[[defaults objectForKey:TGInterfaceDesignDefaultsKey] retain];
    id themeSaved=[[defaults objectForKey:@"TelegraphicaThemeIdentifier"] retain];
    if (argc>1 && !strcmp(argv[1],"aqua")) {
        [defaults setObject:@"aqua" forKey:TGInterfaceDesignDefaultsKey];
        Require(TGInterfaceDesignIsAqua(),"Aqua startup choice");
        [defaults setObject:@"classic" forKey:TGInterfaceDesignDefaultsKey];
        Require(TGInterfaceDesignIsAqua(),"Aqua stays immutable");
    } else {
        [defaults setObject:@"unknown" forKey:TGInterfaceDesignDefaultsKey];
        Require(!TGInterfaceDesignIsAqua(),"unknown/default choice is Classic");
        [defaults setObject:@"aqua" forKey:TGInterfaceDesignDefaultsKey];
        Require(!TGInterfaceDesignIsAqua(),"Classic stays immutable");
    }
    [defaults setObject:@"classic" forKey:TGInterfaceDesignDefaultsKey];
    [defaults setObject:@"notebook-sentinel" forKey:@"TelegraphicaThemeIdentifier"];
    NSError *error=nil;
    Require(!TGRequestInterfaceDesignChange(@"invalid",nil,&error) && error!=nil,"invalid choice rejected");
    Method method=class_getInstanceMethod([NSAlert class],@selector(runModal));
    IMP original=method_setImplementation(method,(IMP)DeclineAlert);
    NSString *other=TGInterfaceDesignIsAqua() ? @"classic" : @"aqua";
    error=nil;
    Require(!TGRequestInterfaceDesignChange(other,nil,&error) && !error,"No cancels without error");
    Require([[defaults stringForKey:TGInterfaceDesignDefaultsKey] isEqual:@"classic"],"No preserves preference");
    method_setImplementation(method,original);

    char rootTemplate[]="/private/tmp/telegraphica-interface-probe.XXXXXX";
    char *created=mkdtemp(rootTemplate); Require(created!=NULL,"private test directory");
    NSString *root=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:created length:strlen(created)];
    NSString *bundle=[root stringByAppendingPathComponent:@"Aqua ' $() ` ; test.app"];
    NSString *contents=[bundle stringByAppendingPathComponent:@"Contents"];
    NSString *macOS=[contents stringByAppendingPathComponent:@"MacOS"];
    [[NSFileManager defaultManager] createDirectoryAtPath:macOS withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSDictionary dictionaryWithObjectsAndKeys:@"Probe",@"CFBundleExecutable",@"APPL",@"CFBundlePackageType",@"local.telegraphica.interface-probe",@"CFBundleIdentifier",nil]
        writeToFile:[contents stringByAppendingPathComponent:@"Info.plist"] atomically:YES];
    NSString *executable=[macOS stringByAppendingPathComponent:@"Probe"];
    [@"#!/bin/sh\nexit 0\n" writeToFile:executable atomically:YES encoding:NSUTF8StringEncoding error:NULL]; chmod([executable fileSystemRepresentation],0700);
    TGInterfaceRestartRequest *bad=[[[TGInterfaceRestartRequest alloc] initWithIdentifier:@"aqua"] autorelease];
    error=nil; Require(![bad prepareForBundlePath:@"/missing/Telegraphica.app" error:&error] && error!=nil,"missing bundle fails safely");
    Require([[defaults stringForKey:TGInterfaceDesignDefaultsKey] isEqual:@"classic"],"prepare failure never persists");
    TGInterfaceRestartRequest *request=[[[TGInterfaceRestartRequest alloc] initWithIdentifier:@"aqua"] autorelease];
    error=nil; Require([request prepareForBundlePath:bundle error:&error],"actual helper ready handshake");
    Require([[defaults stringForKey:TGInterfaceDesignDefaultsKey] isEqual:@"classic"],"prepared helper alone never persists");
    [IsolatedDefaults setPersistenceWorks:NO];
    Require(![request stagePreference:&error] && error!=nil,"persistence failure returns before termination");
    Require([[defaults stringForKey:TGInterfaceDesignDefaultsKey] isEqual:@"classic"],"persistence failure restores preference");
    Require(![[NSFileManager defaultManager] fileExistsAtPath:[[request valueForKey:@"gate"] stringByAppendingPathComponent:@"go"]],"persistence failure never arms helper");
    [IsolatedDefaults setPersistenceWorks:YES];
    request=[[[TGInterfaceRestartRequest alloc] initWithIdentifier:@"aqua"] autorelease];
    Require([request prepareForBundlePath:bundle error:&error],"prepare subsequent restart after failed save");
    Require([request stagePreference:&error],"stage preference after helper readiness");
    Require([[defaults stringForKey:TGInterfaceDesignDefaultsKey] isEqual:@"aqua"],"prepared restart stages choice");
    Require(![[NSFileManager defaultManager] fileExistsAtPath:[[request valueForKey:@"gate"] stringByAppendingPathComponent:@"go"]],"staged choice alone cannot relaunch");
    [request applicationWillTerminate:nil];
    Require([[NSFileManager defaultManager] fileExistsAtPath:[[request valueForKey:@"gate"] stringByAppendingPathComponent:@"go"]],"will-terminate arms helper");
    [request disarm];
    Require([[defaults stringForKey:TGInterfaceDesignDefaultsKey] isEqual:@"classic"],"canceled termination rolls back");
    Require([[defaults stringForKey:@"TelegraphicaThemeIdentifier"] isEqual:@"notebook-sentinel"],"classic palette remains unchanged");

    NSArray *arguments=TGInterfaceRestartArguments(getpid(),bundle,root);
    Require([[arguments objectAtIndex:4] isEqual:bundle] && [[arguments objectAtIndex:5] isEqual:root],"exact paths are separate argv entries");
    Require([[arguments objectAtIndex:1] rangeOfString:bundle].location==NSNotFound,"no path interpolated into shell source");
    // Run the production wait/gate script, replacing only its final launch with
    // a marker write; this probe must never open another application.
    NSString *script=[TGInterfaceRestartScript() stringByReplacingOccurrencesOfString:@"/usr/bin/open" withString:@"/usr/bin/touch"];
    NSString *marker=[root stringByAppendingPathComponent:@"opened ' $() ` ; exact"];
    NSString *gate=[root stringByAppendingPathComponent:@"actual-exit"];
    MakeGate(gate); [[NSData data] writeToFile:[gate stringByAppendingPathComponent:@"go"] atomically:YES];
    NSTask *old=[[[NSTask alloc] init] autorelease]; [old setLaunchPath:@"/bin/sleep"]; [old setArguments:[NSArray arrayWithObject:@"2"]]; [old launch];
    NSTask *helper=RunHelper(script,[old processIdentifier],marker,gate);
    [NSThread sleepForTimeInterval:0.2];
    Require(![[NSFileManager defaultManager] fileExistsAtPath:marker],"no open while original PID is alive");
    [old waitUntilExit]; [helper waitUntilExit];
    Require([helper terminationStatus]==0 && [[NSFileManager defaultManager] fileExistsAtPath:marker],"one exact-path open after real PID exit");
    [[NSFileManager defaultManager] removeItemAtPath:marker error:NULL];
    gate=[root stringByAppendingPathComponent:@"cancel"];
    MakeGate(gate); helper=RunHelper(script,getpid(),marker,gate);
    [NSThread sleepForTimeInterval:0.1]; [[NSFileManager defaultManager] removeItemAtPath:gate error:NULL];
    [helper waitUntilExit]; Require(![[NSFileManager defaultManager] fileExistsAtPath:marker],"cancellation cannot reopen later");
    gate=[root stringByAppendingPathComponent:@"timeout"]; MakeGate(gate);
    [[NSData data] writeToFile:[gate stringByAppendingPathComponent:@"go"] atomically:YES];
    NSString *shortScript=[script stringByReplacingOccurrencesOfString:@"-lt 60" withString:@"-lt 1"];
    helper=RunHelper(shortScript,getpid(),marker,gate); [helper waitUntilExit];
    Require(![[NSFileManager defaultManager] fileExistsAtPath:marker],"bounded live-PID timeout never opens");
    [[NSFileManager defaultManager] removeItemAtPath:root error:NULL];
    if (saved) { [defaults setObject:saved forKey:TGInterfaceDesignDefaultsKey]; } else { [defaults removeObjectForKey:TGInterfaceDesignDefaultsKey]; }
    if (themeSaved) { [defaults setObject:themeSaved forKey:@"TelegraphicaThemeIdentifier"]; } else { [defaults removeObjectForKey:@"TelegraphicaThemeIdentifier"]; }
    [defaults synchronize]; [saved release]; [themeSaved release];
    puts("Interface design: immutable startup, cancel/prefs, helper handshake, literal arguments, real PID exit and bounded cancellation PASS.");
    method_setImplementation(defaultsMethod,defaultsOriginal);
    [IsolatedDefaults release]; IsolatedDefaults=nil;
    [pool drain]; return 0;
}
