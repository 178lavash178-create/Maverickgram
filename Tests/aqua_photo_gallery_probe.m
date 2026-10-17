#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGAquaMediaViewerView.h"
#include <assert.h>

/* Execute the production gallery independently of TDLib and user files. */
@interface TGMessageItem : NSObject {
    NSNumber *_chatID,*_messageID; NSArray *_mediaItems;
}
@property(nonatomic,retain) NSNumber *chatID,*messageID;
@property(nonatomic,retain) NSArray *mediaItems;
@end
@implementation TGMessageItem
@synthesize chatID=_chatID,messageID=_messageID,mediaItems=_mediaItems;
- (void)dealloc { [_chatID release];[_messageID release];[_mediaItems release];[super dealloc]; }
@end
BOOL TGInterfaceDesignIsAqua(void) { return YES; }
BOOL TGAquaPhotoTransitionIsStaticPhoto(NSDictionary *media) { return [[media objectForKey:@"content_type"] isEqual:@"messagePhoto"]; }
NSNumber *TGMediaItemFullFileID(NSDictionary *media) { return [media objectForKey:@"file"]; }
static NSComparisonResult TGMediaCenterCompareItems(TGMessageItem *a,TGMessageItem *b,NSInteger order) { return order ? [[b messageID] compare:[a messageID]] : [[a messageID] compare:[b messageID]]; }
NSString *TGLoc(NSString *key) { (void)key;return @"Photo"; }
NSString *TGLanguageCode(void) {return @"ru";}
NSString *TGMediaItemFullLocalPath(NSDictionary *media) { return [media objectForKey:@"full_local_path"]; }
NSString *TGMediaItemLocalPath(NSDictionary *media) { return [media objectForKey:@"local_path"]; }
static unsigned long long TGMediaCenterFileSizeAtPath(NSString *path) {return [path isEqual:@"/synthetic/second.jpg"] ? 8192:0;}
static NSString *TGMediaCenterReadableSize(unsigned long long value) { return [NSString stringWithFormat:@"%llu KB",value/1024]; }
static NSString *TGMediaCenterDateStringForItem(TGMessageItem *item) { (void)item;return @"17.10.2026"; }
void TGAquaPhotoTransitionClear(NSWindow *window) { (void)window; }
@implementation TGAquaMediaViewerView
- (void)setGalleryIndex:(NSUInteger)index count:(NSUInteger)count { (void)index;(void)count; }
- (void)setMediaTitle:(NSString *)title detail:(NSString *)detail { (void)title;(void)detail; }
@end
@interface GalleryWindow : NSObject { id _delegate;BOOL _visible;NSUInteger _fullscreen; }
@property(nonatomic,assign) id delegate;
@property(nonatomic,assign) BOOL visible;
@property(nonatomic,assign) NSUInteger fullscreen;
@end
@implementation GalleryWindow
@synthesize delegate=_delegate,visible=_visible,fullscreen=_fullscreen;
- (BOOL)isVisible { return _visible; }
- (id)contentView { return nil; }
- (void)setAlphaValue:(CGFloat)value { (void)value; }
- (void)toggleFullScreen:(id)sender { (void)sender;_fullscreen++; }
@end
@interface GallerySort : NSObject { NSInteger _order; }
@property(nonatomic,assign) NSInteger order;
@end
@implementation GallerySort
@synthesize order=_order;
- (NSInteger)indexOfSelectedItem { return _order; }
@end
@interface GalleryOwner : NSObject {
    NSWindow *_mediaPreviewWindow;NSImageView *_mediaPreviewImageView;
    NSArray *_messageItems,*_mediaCenterItems;NSPopUpButton *_mediaCenterSortPopUpButton;
    NSNumber *_selectedChatID;BOOL _mediaCenterVisible;NSUInteger _mediaCenterGeneration;
    NSDictionary *_selection,*_opened,*_source;
}
@property(nonatomic,retain) NSWindow *mediaPreviewWindow;
@property(nonatomic,retain) NSImageView *mediaPreviewImageView;
@property(nonatomic,retain) NSArray *messageItems,*mediaCenterItems;
@property(nonatomic,retain) NSPopUpButton *mediaCenterSortPopUpButton;
@property(nonatomic,retain) NSNumber *selectedChatID;
@property(nonatomic,assign) BOOL mediaCenterVisible;
@property(nonatomic,assign) NSUInteger mediaCenterGeneration;
@property(nonatomic,retain) NSDictionary *selection,*opened,*source;
@end
@implementation GalleryOwner
@synthesize mediaPreviewWindow=_mediaPreviewWindow,mediaPreviewImageView=_mediaPreviewImageView,messageItems=_messageItems,mediaCenterItems=_mediaCenterItems,mediaCenterSortPopUpButton=_mediaCenterSortPopUpButton,selectedChatID=_selectedChatID,mediaCenterVisible=_mediaCenterVisible,mediaCenterGeneration=_mediaCenterGeneration,selection=_selection,opened=_opened,source=_source;
- (NSDictionary *)mediaPreviewSelectionContext { return _selection; }
- (BOOL)mediaPreviewSelectionContextIsCurrent:(NSDictionary *)context { return [context isEqual:_selection]; }
- (void)setAquaPhotoPreviewSourceContext:(NSDictionary *)context { self.source=context; }
- (void)openMediaPreviewForMediaItem:(NSDictionary *)media { self.opened=media; }
#include "TGStatusWindowController+AquaPhotoGallery.inc"
- (void)dealloc { [_mediaPreviewWindow release];[_mediaPreviewImageView release];[_messageItems release];[_mediaCenterItems release];[_mediaCenterSortPopUpButton release];[_selectedChatID release];[_selection release];[_opened release];[_source release];[super dealloc]; }
@end

static NSDictionary *Photo(NSInteger file) { return [NSDictionary dictionaryWithObjectsAndKeys:@"messagePhoto",@"content_type",[NSNumber numberWithInteger:file],@"file",[NSString stringWithFormat:@"photo-%ld.jpg",(long)file],@"file_name",[NSNumber numberWithInteger:file*1024],@"file_size",nil]; }
static TGMessageItem *Message(NSInteger chat,NSInteger message,NSArray *media) {
 TGMessageItem *item=[[[TGMessageItem alloc] init] autorelease];item.chatID=[NSNumber numberWithInteger:chat];item.messageID=[NSNumber numberWithInteger:message];item.mediaItems=media;return item;
}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];NSUInteger checks=0;
 GalleryOwner *owner=[[[GalleryOwner alloc] init] autorelease];GalleryWindow *window=[[[GalleryWindow alloc] init] autorelease];
 window.delegate=owner;window.visible=YES;owner.mediaPreviewWindow=(id)window;owner.selectedChatID=@7;
 owner.selection=[NSDictionary dictionaryWithObjectsAndKeys:@1,@"account",@7,@"chat",@11,@"thread",@"chats",@"section",nil];
 NSMutableDictionary *albumSecond=[[Photo(11) mutableCopy] autorelease];
 TGMessageItem *first=Message(7,1,[NSArray arrayWithObjects:Photo(10),albumSecond,nil]);
 TGMessageItem *second=Message(7,2,[NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:@"messageVideo" forKey:@"content_type"],Photo(12),nil]);
 TGMessageItem *foreign=Message(8,3,[NSArray arrayWithObject:Photo(13)]);
 owner.messageItems=[NSArray arrayWithObjects:first,second,foreign,nil];
 [owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(11) gridSender:nil];
 assert([owner aquaPhotoGalleryIsCurrent]);checks++;
 assert([[[owner aquaPhotoGallery] objectForKey:@"entries"] count]==3);checks++;
 assert([[[owner aquaPhotoGallery] objectForKey:@"index"] unsignedIntegerValue]==1);checks++;
 NSDictionary *entry=[[[owner aquaPhotoGallery] objectForKey:@"entries"] objectAtIndex:1];
 assert([[entry objectForKey:@"title"] isEqual:@"photo-11.jpg"]);checks++;
 assert([[entry objectForKey:@"detail"] isEqual:@"11 KB · 17.10.2026"]);checks++;
 NSDictionary *albumFirst=[[[owner aquaPhotoGallery] objectForKey:@"entries"] objectAtIndex:0];
 assert([[albumFirst objectForKey:@"title"] isEqual:@"photo-10.jpg"] && [[albumFirst objectForKey:@"detail"] isEqual:@"10 KB · 17.10.2026"]);checks++;
 assert(![[entry objectForKey:@"detail"] isEqual:[albumFirst objectForKey:@"detail"]]);checks++;
 NSDictionary *fallback=[owner aquaPhotoGalleryMetadataForMedia:[NSDictionary dictionaryWithObject:@"/synthetic/second.jpg" forKey:@"full_local_path"] message:first];
 assert([[fallback objectForKey:@"title"] isEqual:@"second.jpg"]&&[[fallback objectForKey:@"detail"] isEqual:@"8 KB · 17.10.2026"]);checks++;
 fallback=[owner aquaPhotoGalleryMetadataForMedia:[NSDictionary dictionary] message:first];
 assert([[fallback objectForKey:@"title"] isEqual:@"Photo"]&&[[fallback objectForKey:@"detail"] isEqual:@"17.10.2026"]);checks++;
 NSMutableDictionary *changing=[[Photo(11) mutableCopy] autorelease];
 [changing setObject:@640 forKey:@"width"];[changing setObject:@480 forKey:@"height"];
 fallback=[owner aquaPhotoGalleryMetadataForMedia:changing message:first];
 assert([[fallback objectForKey:@"detail"] isEqual:@"11 KB · 640 × 480 · 17.10.2026"]);checks++;
 [albumSecond setObject:@"later.jpg" forKey:@"file_name"];[albumSecond setObject:@99999 forKey:@"file_size"];
 assert([[entry objectForKey:@"title"] isEqual:@"photo-11.jpg"]&&[[entry objectForKey:@"detail"] isEqual:@"11 KB · 17.10.2026"]);checks++;
 [changing setObject:[NSNumber numberWithDouble:1] forKey:@"date"];
 fallback=[owner aquaPhotoGalleryMetadataForMedia:changing message:first];
 assert([[fallback objectForKey:@"detail"] rangeOfString:@"17.10.2026"].location==NSNotFound);checks++;
 assert([[fallback objectForKey:@"detail"] hasPrefix:@"11 KB · 640 × 480 · "]);checks++;
 [owner nextAquaPhoto:nil];assert([owner.opened isEqual:Photo(12)]);checks++;
 [owner nextAquaPhoto:nil];assert([[[owner aquaPhotoGallery] objectForKey:@"index"] unsignedIntegerValue]==2);checks++;
 [owner previousAquaPhoto:nil];[owner previousAquaPhoto:nil];[owner previousAquaPhoto:nil];assert([owner.opened isEqual:Photo(10)]);checks++;
 for(NSString *key in [NSArray arrayWithObjects:@"account",@"chat",@"thread",@"section",nil]) {
  [owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(11) gridSender:nil];NSDictionary *original=[[owner.selection copy] autorelease];
  NSMutableDictionary *changed=[[owner.selection mutableCopy] autorelease];[changed setObject:@999 forKey:key];owner.selection=changed;
  owner.opened=nil;assert(![owner aquaPhotoGalleryIsCurrent]);[owner nextAquaPhoto:nil];assert(!owner.opened && ![owner aquaPhotoGallery]);checks+=2;owner.selection=original;
 }
 owner.mediaCenterVisible=YES;
 /* A transcript click remains a transcript snapshot while a wide Media
  * Center panel is also visible. */
 [owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(11) gridSender:nil];
 assert([[[owner aquaPhotoGallery] objectForKey:@"entries"] count]==3);checks++;
 TGMessageItem *fourth=Message(7,4,[NSArray arrayWithObject:Photo(14)]),*fifth=Message(7,5,[NSArray arrayWithObject:Photo(15)]);
 owner.mediaCenterItems=[NSArray arrayWithObjects:fifth,second,first,fourth,foreign,nil];
 [owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(10) gridSender:window];
 assert([[[owner aquaPhotoGallery] objectForKey:@"entries"] count]==3);checks++;
 [owner nextAquaPhoto:nil];assert([owner.opened isEqual:Photo(14)]);checks++;
 [owner nextAquaPhoto:nil];assert([owner.opened isEqual:Photo(15)]);checks++;
 GallerySort *sort=[[[GallerySort alloc] init] autorelease];sort.order=1;owner.mediaCenterSortPopUpButton=(id)sort;
 [owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(10) gridSender:window];
 assert([[[owner aquaPhotoGallery] objectForKey:@"index"] unsignedIntegerValue]==2);checks++;
 [owner previousAquaPhoto:nil];assert([owner.opened isEqual:Photo(14)]);checks++;
 owner.mediaCenterGeneration++;assert(![owner aquaPhotoGalleryIsCurrent]);owner.opened=nil;[owner nextAquaPhoto:nil];assert(!owner.opened);checks+=2;
 owner.mediaCenterVisible=NO;[owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(11) gridSender:nil];window.visible=NO;owner.opened=nil;
 [owner nextAquaPhoto:nil];assert(!owner.opened && ![owner aquaPhotoGallery]);checks++;
 window.visible=YES;[owner prepareAquaPhotoGalleryForMessage:first mediaItem:Photo(11) gridSender:nil];window.delegate=nil;[owner nextAquaPhoto:nil];assert(![owner aquaPhotoGallery]);checks++;
 window.delegate=owner;[owner toggleAquaPhotoFullscreen:nil];assert(window.fullscreen==1);checks++;
 [owner prepareAquaPhotoGalleryForMessage:first mediaItem:[NSDictionary dictionaryWithObject:@"messageAnimation" forKey:@"content_type"] gridSender:nil];assert(![owner aquaPhotoGallery]);checks++;
 printf("PASS: %lu production photo gallery origin/order/boundary/context/lifecycle/fullscreen checks\n",(unsigned long)checks);
 [pool drain];return 0;
}
