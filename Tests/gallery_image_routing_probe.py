#!/usr/bin/env python
"""Run actual async static-photo controller callbacks against deterministic loader deliveries."""
from __future__ import print_function
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
with open(os.path.join(ROOT,'Sources/UI/TGStatusWindowController+MediaWindows.inc'),'rb') as handle:
    source=handle.read().decode('utf-8')
start=source.index('- (void)cancelMediaPreviewImageLoad {')
production=source[start:source.index('- (void)openMediaPreviewForMediaItem:',start)]
with open(os.path.join(ROOT,'Sources/UI/TGStatusWindowController+AquaPhotoPreview.inc'),'rb') as handle:
    preview=handle.read().decode('utf-8')
start=preview.index('- (NSImage *)aquaMediaPosterForTransitionContext:')
production+=preview[start:preview.index('- (void)closeAquaMediaViewer:',start)]
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGMediaImageLoader.h"
@class TGTDLibClient;
static NSMutableArray *Requests;
static BOOL MotionAllowed;
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) {(void)view;return MotionAllowed;}
static void Require(BOOL value,const char *text){if(!value){fprintf(stderr,"Gallery routing: %s\n",text);exit(1);}}
@interface TGMediaImageLoadToken () { BOOL _cancelled; }
@end
@implementation TGMediaImageLoadToken
- (void)cancel {_cancelled=YES;}
- (BOOL)isCancelled {return _cancelled;}
@end
TGMediaImageLoadToken *TGLoadOrientedImageFromFileAsync(NSString *path,TGMediaImageLoadCompletion completion) {
    TGMediaImageLoadToken *token=[[[TGMediaImageLoadToken alloc] init] autorelease];
    id copy=[[completion copy] autorelease];
    [Requests addObject:[NSDictionary dictionaryWithObjectsAndKeys:path,@"path",token,@"token",copy,@"completion",nil]];return token;
}
@interface GalleryController : NSObject {
    NSUInteger _mediaPreviewRequestGeneration,_shown,_errors,_sourceResolutions;
    NSView *_messageTableView;
    TGTDLibClient *_client;
    NSDictionary *_selection,*_gallery;
    NSTextField *_statusField;
    NSString *_shownPath;
}
@property(nonatomic,assign) NSUInteger mediaPreviewRequestGeneration,shown,errors,sourceResolutions;
@property(nonatomic,retain) NSView *messageTableView;
@property(nonatomic,retain) TGTDLibClient *client;
@property(nonatomic,retain) NSDictionary *selection,*gallery;
@property(nonatomic,retain) NSTextField *statusField;
@property(nonatomic,copy) NSString *shownPath;
@end
@implementation GalleryController
@synthesize messageTableView=_messageTableView,sourceResolutions=_sourceResolutions,mediaPreviewRequestGeneration=_mediaPreviewRequestGeneration,shown=_shown,errors=_errors,client=_client,selection=_selection,gallery=_gallery,statusField=_statusField,shownPath=_shownPath;
- (BOOL)mediaPreviewSelectionContextIsCurrent:(NSDictionary *)selection {return [selection isEqual:self.selection];}
- (NSDictionary *)aquaPhotoGallery {return self.gallery;}
- (BOOL)aquaPhotoGalleryIsCurrent {return [[self.gallery objectForKey:@"current"] boolValue];}
- (BOOL)showMediaPreviewImage:(NSImage *)image atPath:(NSString *)path preferAnimated:(BOOL)animated {Require(image!=nil && !animated,"decoded static image goes directly to presentation");self.shown++;self.shownPath=path;return YES;}
- (void)appendDetail:(NSString *)text {(void)text;self.errors++;}
- (NSRect)aquaPhotoPreviewSourceScreenRectForContext:(NSDictionary *)context {(void)context;self.sourceResolutions++;return NSZeroRect;}
__PRODUCTION__
- (void)dealloc {[self cancelMediaPreviewImageLoad];[_client release];[_selection release];[_gallery release];[_statusField release];[_shownPath release];[super dealloc];}
@end
static void Deliver(NSUInteger index,NSImage *image) {TGMediaImageLoadCompletion completion=[[Requests objectAtIndex:index] objectForKey:@"completion"];completion(image);}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];Requests=[[NSMutableArray alloc] init];
    GalleryController *c=[[[GalleryController alloc] init] autorelease];c.client=(id)[[[NSObject alloc] init] autorelease];c.selection=[NSDictionary dictionaryWithObject:@1 forKey:@"chat"];c.gallery=[NSDictionary dictionaryWithObject:@YES forKey:@"current"];c.statusField=[[[NSTextField alloc] init] autorelease];c.mediaPreviewRequestGeneration=1;
    NSImage *image=[[[NSImage alloc] initWithSize:NSMakeSize(200,100)] autorelease];
    [c loadStaticMediaPreviewAtPath:@"one" fallbackPath:nil requestGeneration:1 selection:c.selection gallery:c.gallery];Deliver(0,image);Require(c.shown==1 && [c.shownPath isEqual:@"one"],"current callback presents once");
    [c loadStaticMediaPreviewAtPath:@"old" fallbackPath:nil requestGeneration:1 selection:c.selection gallery:c.gallery];c.mediaPreviewRequestGeneration=2;
    [c loadStaticMediaPreviewAtPath:@"new" fallbackPath:nil requestGeneration:2 selection:c.selection gallery:c.gallery];
    Require([[[Requests objectAtIndex:1] objectForKey:@"token"] isCancelled],"new selection cancels previous worker");Deliver(1,image);Require(c.shown==1 && ![[[Requests objectAtIndex:2] objectForKey:@"token"] isCancelled],"stale generation cannot present or cancel the current worker");Deliver(2,image);Require(c.shown==2,"new generation presents");
    [c loadStaticMediaPreviewAtPath:@"account-old" fallbackPath:nil requestGeneration:2 selection:c.selection gallery:c.gallery];c.client=(id)[[[NSObject alloc] init] autorelease];Deliver(3,image);Require(c.shown==2,"old client callback rejected");
    [c loadStaticMediaPreviewAtPath:@"chat-old" fallbackPath:nil requestGeneration:2 selection:c.selection gallery:c.gallery];c.selection=[NSDictionary dictionaryWithObject:@2 forKey:@"chat"];Deliver(4,image);Require(c.shown==2,"changed chat/thread/section context rejected");
    [c loadStaticMediaPreviewAtPath:@"gallery-old" fallbackPath:nil requestGeneration:2 selection:c.selection gallery:c.gallery];c.gallery=[NSDictionary dictionaryWithObject:@NO forKey:@"current"];Deliver(5,image);Require(c.shown==2,"replaced gallery snapshot rejected");
    c.gallery=[NSDictionary dictionaryWithObject:@YES forKey:@"current"];
    [c loadStaticMediaPreviewAtPath:@"broken-full" fallbackPath:@"cached-thumb" requestGeneration:2 selection:c.selection gallery:c.gallery];Deliver(6,nil);Require([Requests count]==8 && [[[Requests objectAtIndex:7] objectForKey:@"path"] isEqual:@"cached-thumb"],"failed full image asynchronously falls back once");Deliver(7,image);Require(c.shown==3 && [c.shownPath isEqual:@"cached-thumb"],"fallback retains current context and displays");
    [c loadStaticMediaPreviewAtPath:@"missing" fallbackPath:@"missing" requestGeneration:2 selection:c.selection gallery:c.gallery];Deliver(8,nil);Require([Requests count]==9 && c.errors==1,"identical missing fallback cannot loop");
    [c loadStaticMediaPreviewAtPath:@"closing" fallbackPath:nil requestGeneration:2 selection:c.selection gallery:c.gallery];[c cancelMediaPreviewImageLoad];c.mediaPreviewRequestGeneration++;Deliver(9,image);Require(c.shown==3 && [[[Requests objectAtIndex:9] objectForKey:@"token"] isCancelled],"close cancels worker and its stale result cannot reopen viewer");
    MotionAllowed=NO;Require([c aquaMediaPosterForTransitionContext:c.selection]==nil && c.sourceResolutions==0,"disabled/economy/inactive motion avoids even source resolution and snapshot admission");
    MotionAllowed=YES;Require([c aquaMediaPosterForTransitionContext:c.selection]==nil && c.sourceResolutions==1,"enabled motion retains normal source resolution");
    printf("Gallery async production routing: generation/client/selection/gallery rejection, replacement cancellation, fallback, close/reopen guards and policy-gated snapshot admission PASS.\n");
    [Requests release];Requests=nil;[pool drain];return 0;
}
'''.replace('__PRODUCTION__',production)
folder=tempfile.mkdtemp(prefix='telegraphica-gallery-routing-')
try:
    src=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(src,'wb') as handle:handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/Media'),src,'-framework','Cocoa','-o',binary]);subprocess.check_call([binary])
finally:shutil.rmtree(folder)
