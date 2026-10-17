#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "../Sources/UI/TGDialogPresentation.h"
#include "../Sources/UI/TGUtilityWindowGeometry.inc"
#include <stdio.h>
static NSUInteger checks;
static void Require(BOOL condition,const char *message) {
    checks++; if(!condition){fprintf(stderr,"Utility geometry: %s\n",message);exit(1);}
}
static NSWindow *Window(BOOL resizable,BOOL flipped) {
    NSWindow *window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(120,120,700,600)
        styleMask:NSTitledWindowMask|NSClosableWindowMask|(resizable?NSResizableWindowMask:0)
        backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO];
    if(resizable)[window setMinSize:NSMakeSize(650,550)];
    (void)flipped;
    [[window contentView] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    NSButton *last=[[[NSButton alloc] initWithFrame:NSMakeRect(580,8,100,28)] autorelease];
    [last setTitle:@"Last action"];[[window contentView] addSubview:last];
    return window;
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    for(NSInteger x=-1920;x<=1920;x+=480)for(NSInteger width=160;width<=1600;width+=120)
      for(NSInteger height=120;height<=1000;height+=110) {
        NSRect screen=NSMakeRect(x,32,width,height),input=NSMakeRect(9999,-9999,720,640);
        NSRect result=TGUtilityWindowFrameFittingVisibleFrame(input,screen);
        Require(NSContainsRect(screen,result),"frame contained on small/negative-origin displays");
        Require(NSWidth(result)>0&&NSHeight(result)>0,"fit keeps positive dimensions");
        Require(NSEqualRects(result,TGUtilityWindowFrameFittingVisibleFrame(result,screen)),"fit is idempotent");
    }
    for(NSUInteger resizing=0;resizing<2;resizing++) {
        NSWindow *window=Window(resizing,NO);NSView *natural=[[window contentView] retain];
        NSSize size=[natural bounds].size;NSUInteger mask=[natural autoresizingMask];
        NSRect small=NSMakeRect(-800,30,480,360),large=NSMakeRect(0,30,1440,1000);
        for(NSUInteger cycle=0;cycle<3;cycle++) {
            TGFitUtilityWindowToVisibleFrame(window,small);
            Require(NSContainsRect(small,[window frame]),"small display contains full window frame");
            Require([window contentView]!=natural,"undersized display uses scroll viewport");
            Require(TGUtilityWindowContentView(window)==natural,"controller obtains original natural root");
            Require(NSEqualSizes([natural bounds].size,size),"small screen never compresses fixed-form content");
            NSScrollView *scroll=(NSScrollView *)[window contentView];
            NSView *last=[[natural subviews] lastObject];[last scrollRectToVisible:[last bounds]];
            Require(NSIntersectsRect([[scroll contentView] bounds],[last frame]),"trailing action remains reachable by scrolling");
            TGFitUtilityWindowToVisibleFrame(window,small);
            Require([window contentView]==scroll,"repeated fit does not nest scroll wrappers");
            TGFitUtilityWindowToVisibleFrame(window,large);
            Require([window contentView]==natural,"larger display restores original root");
            Require([natural autoresizingMask]==mask,"unwrapping restores autoresizing");
            Require(NSContainsRect(large,[window frame]),"large screen contains restored window");
            Require(!resizing||NSEqualSizes([window minSize],NSMakeSize(650,550)),"original resize minimum restored");
            size=[natural bounds].size;
        }
        [natural release];[window close];
    }
    printf("Utility screen geometry: %lu checks PASS\n",(unsigned long)checks);[pool drain];return 0;
}
