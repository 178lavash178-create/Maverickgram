static NSTextField *TGProfileEditLabel(NSString *title, NSRect frame) {
    NSTextField *label = [[[TGThemeTextField alloc] initWithFrame:frame] autorelease];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label setDrawsBackground:NO];
    [label setFont:[NSFont systemFontOfSize:12.0]];
    [(TGThemeTextField *)label setDetailInk:YES];
    [(TGThemeTextField *)label refreshThemeInk];
    [label setStringValue:title ? title : @""];
    return label;
}

static NSTextField *TGProfileEditInput(NSRect frame) {
    NSTextField *field = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [field setFont:[NSFont systemFontOfSize:13.0]];
    [field setTextColor:[NSColor controlTextColor]];
    [field setBackgroundColor:[NSColor whiteColor]];
    [field setBezeled:YES];
    [field setBezelStyle:NSTextFieldRoundedBezel];
    [field setFocusRingType:NSFocusRingTypeNone];
    return field;
}

