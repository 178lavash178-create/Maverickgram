#import "TGDialogPresentation.h"
#import "TGDatePickerDialog.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
#import "TGTheme.h"

// Keep calendar arithmetic together: the selected day and wall-clock time
// form one date in the current calendar/time zone, including DST changes.
@interface TGAquaDatePickerView : NSView {
    NSDatePicker *_calendarPicker;
    NSDatePicker *_timePicker;
    NSTextField *_summary;
    NSDate *_minimumDate;
    NSButton *_confirmationButton;
}
- (id)initWithDate:(NSDate *)date minimum:(NSDate *)minimum button:(NSButton *)button;
- (NSDate *)selectedDate;
- (void)selectionChanged:(id)sender;
@end

@implementation TGAquaDatePickerView
- (NSTextField *)label:(NSString *)text frame:(NSRect)frame {
    NSTextField *label=[[[NSTextField alloc] initWithFrame:frame] autorelease];
    [label setStringValue:text]; [label setEditable:NO]; [label setSelectable:NO];
    [label setBezeled:NO]; [label setDrawsBackground:NO];
    [label setFont:[NSFont systemFontOfSize:12]]; [label setTextColor:TGClassicCardInkColor()];
    [self addSubview:label]; return label;
}
- (id)initWithDate:(NSDate *)date minimum:(NSDate *)minimum button:(NSButton *)button {
    self=[super initWithFrame:NSMakeRect(0,0,420,244)];
    if(self) {
        _minimumDate=[minimum retain]; _confirmationButton=button;
        NSLocale *locale=[[[NSLocale alloc] initWithLocaleIdentifier:TGLanguageCode()] autorelease];
        if(minimum && [date compare:minimum]==NSOrderedAscending) date=minimum;
        [self label:TGLoc(@"composer.schedule.date") frame:NSMakeRect(12,222,230,18)];
        [self label:TGLoc(@"composer.schedule.time") frame:NSMakeRect(266,222,142,18)];
        _calendarPicker=[[NSDatePicker alloc] initWithFrame:NSMakeRect(12,54,232,164)];
        [_calendarPicker setDatePickerStyle:NSClockAndCalendarDatePickerStyle];
        [_calendarPicker setDatePickerElements:NSYearMonthDayDatePickerElementFlag];
        [_calendarPicker setLocale:locale];
        [_calendarPicker setDateValue:date];
        if(minimum) {
            NSCalendar *calendar=[NSCalendar currentCalendar];
            NSDate *day=[calendar dateFromComponents:[calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:minimum]];
            [_calendarPicker setMinDate:day];
        }
        [_calendarPicker setTarget:self]; [_calendarPicker setAction:@selector(selectionChanged:)];
        [self addSubview:_calendarPicker];
        _timePicker=[[NSDatePicker alloc] initWithFrame:NSMakeRect(266,184,142,28)];
        [_timePicker setDatePickerStyle:NSTextFieldAndStepperDatePickerStyle];
        [_timePicker setDatePickerElements:NSHourMinuteDatePickerElementFlag];
        [_timePicker setLocale:locale];
        [_timePicker setFont:[NSFont systemFontOfSize:16]]; [_timePicker setDateValue:date];
        [_timePicker setTarget:self]; [_timePicker setAction:@selector(selectionChanged:)];
        [self addSubview:_timePicker];
        _summary=[[self label:@"" frame:NSMakeRect(266,64,142,100)] retain];
        [[_summary cell] setWraps:YES]; [[_summary cell] setUsesSingleLineMode:NO];
        [_summary setFont:[NSFont systemFontOfSize:12]];
        [self selectionChanged:nil];
    }
    return self;
}
- (NSDate *)selectedDate {
    NSCalendar *calendar=[NSCalendar currentCalendar];
    NSDateComponents *parts=[calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[_calendarPicker dateValue]];
    NSDateComponents *time=[calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[_timePicker dateValue]];
    [parts setHour:[time hour]]; [parts setMinute:[time minute]];
    return [calendar dateFromComponents:parts];
}
- (void)selectionChanged:(id)sender {
    (void)sender; NSDate *date=[self selectedDate];
    BOOL valid=date && (!_minimumDate || [date compare:_minimumDate]!=NSOrderedAscending);
    [_confirmationButton setEnabled:valid];
    NSDateFormatter *format=[[[NSDateFormatter alloc] init] autorelease];
    [format setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:TGLanguageCode()] autorelease]];
    [format setDateStyle:NSDateFormatterLongStyle]; [format setTimeStyle:NSDateFormatterShortStyle];
    [_summary setStringValue:valid ? [format stringFromDate:date] : TGLoc(@"composer.schedule.invalid")];
    [_summary setTextColor:valid ? TGClassicMutedInkColor() : TGClassicCardInkColor()];
}
- (void)dealloc {
    [_calendarPicker release]; [_timePicker release]; [_summary release]; [_minimumDate release];
    [super dealloc];
}
@end

@implementation TGDatePickerDialog

+ (NSDate *)dateWithTitle:(NSString *)title
                     help:(NSString *)help
              actionTitle:(NSString *)actionTitle
              initialDate:(NSDate *)initialDate
                  minDate:(NSDate *)minDate {
    if(TGInterfaceDesignIsAqua()) {
        NSAlert *alert=[[[NSAlert alloc] init] autorelease];
        [alert setMessageText:title ? title : @""];
        [alert setInformativeText:help ? help : @""];
        NSButton *confirm=[alert addButtonWithTitle:actionTitle ? actionTitle : @"OK"];
        [alert addButtonWithTitle:TGLoc(@"cancel")];
        TGAquaDatePickerView *view=[[[TGAquaDatePickerView alloc] initWithDate:initialDate ? initialDate : [NSDate date] minimum:minDate button:confirm] autorelease];
        [alert setAccessoryView:view];
        if(TGRunAlert(alert,nil)!=NSAlertFirstButtonReturn) return nil;
        [view selectionChanged:nil];
        return [confirm isEnabled] ? [[[view selectedDate] retain] autorelease] : nil;
    }
    NSView *accessory = [[[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 360.0, 48.0)] autorelease];
    NSDatePicker *picker = [[[NSDatePicker alloc] initWithFrame:NSMakeRect(0.0, 10.0, 360.0, 28.0)] autorelease];
    [picker setDatePickerStyle:NSTextFieldAndStepperDatePickerStyle];
    [picker setDatePickerElements:(NSYearMonthDayDatePickerElementFlag |
                                   NSHourMinuteDatePickerElementFlag)];
    [picker setMinDate:minDate];
    [picker setDateValue:initialDate ? initialDate : [NSDate date]];
    [picker setAutoresizingMask:NSViewWidthSizable];
    [accessory addSubview:picker];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:title ? title : @""];
    [alert setInformativeText:help ? help : @""];
    [alert setAccessoryView:accessory];
    [alert addButtonWithTitle:actionTitle ? actionTitle : @"OK"];
    [alert addButtonWithTitle:TGLoc(@"cancel")];
    if (TGRunAlert(alert, nil) != NSAlertFirstButtonReturn) {
        return nil;
    }
    return [[[picker dateValue] retain] autorelease];
}

@end
