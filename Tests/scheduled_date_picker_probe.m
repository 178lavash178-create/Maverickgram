#import <Cocoa/Cocoa.h>
#import "TGDatePickerDialog.h"
#import "TGLocalization.h"
#import "TGTheme.h"
static BOOL Aqua=YES,Accept=NO;
static NSUInteger Checks=0;
static void Check(BOOL ok,const char *reason){Checks++;if(!ok){fprintf(stderr,"Date picker: %s\n",reason);exit(1);}}
BOOL TGInterfaceDesignIsAqua(void){return Aqua;}
NSColor *TGClassicCardInkColor(void){return [NSColor blackColor];}
NSColor *TGClassicMutedInkColor(void){return [NSColor grayColor];}
@interface NSObject (DateProbe)
- (NSDate *)selectedDate;
- (void)selectionChanged:(id)sender;
@end
static NSDate *Date(NSInteger year,NSInteger month,NSInteger day,NSInteger hour,NSInteger minute){
    NSDateComponents *parts=[[[NSDateComponents alloc] init] autorelease];[parts setYear:year];[parts setMonth:month];[parts setDay:day];[parts setHour:hour];[parts setMinute:minute];return [[NSCalendar currentCalendar] dateFromComponents:parts];
}
NSInteger TGRunAlert(NSAlert *alert,NSWindow *parent){
    (void)parent; NSView *view=[alert accessoryView];
    if(Aqua){
        Check(NSWidth([view frame])==420 && NSHeight([view frame])==244,"Aqua uses compact calendar accessory");
        NSDatePicker *calendar=[view valueForKey:@"calendarPicker"],*time=[view valueForKey:@"timePicker"];
        Check([calendar datePickerStyle]==NSClockAndCalendarDatePickerStyle,"real AppKit calendar, no hand-drawn calendar");
        Check([time datePickerElements]==NSHourMinuteDatePickerElementFlag,"time has its own native editor");
        Check([[[calendar locale] localeIdentifier] hasPrefix:TGLanguageCode()] && [[[time locale] localeIdentifier] hasPrefix:TGLanguageCode()],"calendar and time follow the application language rather than the host language");
        Check(!NSIntersectsRect([calendar frame],[time frame]),"day and time controls do not overlap");
        for(NSView *child in [view subviews])Check(NSContainsRect([view bounds],[child frame]),"all labels and pickers fit accessory");
        Check([[[alert buttons] objectAtIndex:0] isEnabled],"valid initial future date enables confirmation");
        const char *directory=getenv("TG_SCHEDULE_PREVIEW_DIR");
        if(directory){
            [alert layout]; NSView *root=[[alert window] contentView]; NSRect bounds=[root bounds];
            NSBitmapImageRep *rep=[root bitmapImageRepForCachingDisplayInRect:bounds];[root cacheDisplayInRect:bounds toBitmapImageRep:rep];
            NSString *path=[[NSString stringWithUTF8String:directory] stringByAppendingPathComponent:[NSString stringWithFormat:@"scheduled-picker-%@.png",TGLanguageCode()]];
            [[rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:path atomically:YES];
        }
        [calendar setDateValue:Date(2034,1,1,0,0)];[time setDateValue:Date(2033,12,31,23,45)];[view selectionChanged:time];
        Check([[view selectedDate] isEqualToDate:Date(2034,1,1,23,45)],"combines selected day and time across year boundary");
        [calendar setDateValue:Date(2033,12,31,0,0)];[time setDateValue:Date(2033,12,31,9,0)];[view selectionChanged:time];
        Check(![[[alert buttons] objectAtIndex:0] isEnabled],"earlier time on the minimum day cannot be confirmed");
        [time setDateValue:Date(2033,12,31,17,30)];[view selectionChanged:time];
        Check([[[alert buttons] objectAtIndex:0] isEnabled],"later time restores confirmation");
    }else Check(NSHeight([view frame])==48,"Classic date dialog remains unchanged");
    return Accept ? NSAlertFirstButtonReturn : NSAlertSecondButtonReturn;
}
int main(void){
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]){
        TGSetLanguageCode(language);Accept=NO;
        Check([TGDatePickerDialog dateWithTitle:TGLoc(@"composer.schedule.title") help:TGLoc(@"composer.schedule.help") actionTitle:TGLoc(@"composer.schedule.confirm") initialDate:Date(2033,12,31,15,0) minDate:Date(2033,12,31,10,0)]==nil,"Cancel returns no scheduled date");
        Accept=YES;NSDate *selected=[TGDatePickerDialog dateWithTitle:@"Schedule" help:@"" actionTitle:@"Schedule" initialDate:Date(2033,12,31,15,0) minDate:Date(2033,12,31,10,0)];
        Check([selected isEqualToDate:Date(2033,12,31,17,30)],"accept returns edited date and time only");
    }
    Aqua=NO;Accept=NO;Check([TGDatePickerDialog dateWithTitle:@"Classic" help:@"" actionTitle:@"OK" initialDate:[NSDate date] minDate:nil]==nil,"Classic cancellation preserved");
    printf("Scheduled picker: %lu native calendar/time, minimum date, year-boundary, cancel/accept and RU/BE/EN layout checks PASS.\n",(unsigned long)Checks);[pool drain];return 0;
}
