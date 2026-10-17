#import <Cocoa/Cocoa.h>

// Keep the original springs-and-struts layout as the wide-window baseline.
// Narrow overrides are applied from these immutable frames, so resizing back
// and forth never accumulates rounding or leaves a compact-row arrangement.
static NSDictionary *TGUtilityCaptureResponsiveLayout(NSView *root, NSDictionary *namedViews) {
    NSMutableArray *entries=[NSMutableArray array];
    for (NSView *view in [root subviews]) {
        [entries addObject:[NSArray arrayWithObjects:view,[NSValue valueWithRect:[view frame]],
            [NSNumber numberWithUnsignedInteger:[view autoresizingMask]],nil]];
        [view setAutoresizingMask:NSViewNotSizable];
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:root,@"root",[NSValue valueWithSize:[root bounds].size],@"size",entries,@"entries",namedViews,@"named",nil];
}
static NSView *TGUtilityResponsiveView(NSDictionary *layout,NSString *name) {
    return [[layout objectForKey:@"named"] objectForKey:name];
}
static NSSize TGUtilityRestoreResponsiveLayout(NSDictionary *layout) {
    NSSize size=[[layout objectForKey:@"root"] bounds].size;
    NSSize original=[[layout objectForKey:@"size"] sizeValue];
    CGFloat dx=size.width-original.width,dy=size.height-original.height;
    for (NSArray *entry in [layout objectForKey:@"entries"]) {
        NSView *view=[entry objectAtIndex:0];NSRect frame=[[entry objectAtIndex:1] rectValue];
        NSUInteger mask=[[entry objectAtIndex:2] unsignedIntegerValue];
        if(mask&NSViewWidthSizable)frame.size.width=MAX(1,frame.size.width+dx);
        else if(mask&NSViewMinXMargin)frame.origin.x+=dx;
        if(mask&NSViewHeightSizable)frame.size.height=MAX(1,frame.size.height+dy);
        else if(mask&NSViewMinYMargin)frame.origin.y+=dy;
        [view setFrame:frame];
    }
    return size;
}
static void TGUtilitySizeResponsiveTable(NSTableView *table) {
    NSScrollView *scroll=[table enclosingScrollView];[scroll tile];
    CGFloat width=NSWidth([[scroll contentView] bounds]);
    [[[table tableColumns] lastObject] setWidth:MAX(1,width)];
    [table setFrameSize:NSMakeSize(width,MAX(NSHeight([[scroll contentView] bounds]),[table numberOfRows]*([table rowHeight]+[table intercellSpacing].height)))];
}

static CGFloat TGUtilityResponsiveButtonWidth(NSButton *button,CGFloat padding) {
    NSFont *font=[button font] ? [button font] : [NSFont systemFontOfSize:13];
    if([[button cell] isKindOfClass:NSClassFromString(@"TGPrimaryTextButtonCell")]){font=[NSFont boldSystemFontOfSize:13];padding=MAX(padding,24);}
    else if([[button cell] isKindOfClass:NSClassFromString(@"TGSecondaryTextButtonCell")]){font=[NSFont boldSystemFontOfSize:12];padding=MAX(padding,20);}
    else padding=MAX(padding,24);
    return ceil([[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width+padding);
}
