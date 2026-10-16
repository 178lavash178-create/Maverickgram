#import <Cocoa/Cocoa.h>
#import <ImageIO/ImageIO.h>
#import "TGMediaImageLoader.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// This fixture uses JPEG only; WebP has its own production decoder probes.
NSImage *TGWebPImageFromFile(NSString *path) { (void)path; return nil; }
NSImage *TGWebPImageFromData(NSData *data) { (void)data; return nil; }
static NSUInteger DecodeCalls, MainDecodeCalls, PreparedDraws, MainPreparedDraws, ActiveDecodes, MaximumActiveDecodes;
static BOOL GateEntered;
static dispatch_semaphore_t DecodeGate;

static void Require(BOOL value,const char *message) {
    if (!value) { fprintf(stderr,"Gallery image loader: %s\n",message); exit(1); }
}
static void BeginDecode(void) {
    dispatch_semaphore_t gate = NULL;
    @synchronized([NSImage class]) {
        DecodeCalls++; if ([NSThread isMainThread]) MainDecodeCalls++;
        ActiveDecodes++;MaximumActiveDecodes=MAX(MaximumActiveDecodes,ActiveDecodes);
        if (DecodeGate) { gate=DecodeGate;DecodeGate=NULL;GateEntered=YES; }
    }
    if (gate) Require(dispatch_semaphore_wait(gate,dispatch_time(DISPATCH_TIME_NOW,20LL*NSEC_PER_SEC))==0,"decode gate timed out");
}
static void EndDecode(void) { @synchronized([NSImage class]) { ActiveDecodes--; } }
CGImageRef TGProbeCreateThumbnail(CGImageSourceRef source,size_t index,CFDictionaryRef options) {
    BeginDecode();CGImageRef result=CGImageSourceCreateThumbnailAtIndex(source,index,options);EndDecode();return result;
}
CGImageRef TGProbeCreateImage(CGImageSourceRef source,size_t index,CFDictionaryRef options) {
    BeginDecode();CGImageRef result=CGImageSourceCreateImageAtIndex(source,index,options);EndDecode();return result;
}
void TGProbeDrawImage(CGContextRef context,CGRect rect,CGImageRef image) {
    @synchronized([NSImage class]) { PreparedDraws++;if([NSThread isMainThread])MainPreparedDraws++; }
    CGContextDrawImage(context,rect,image);
}
static BOOL Entered(void) { @synchronized([NSImage class]) { return GateEntered; } }
static void WaitFor(BOOL(^condition)(void)) {
    NSTimeInterval deadline=[NSDate timeIntervalSinceReferenceDate]+30;
    while(!condition() && [NSDate timeIntervalSinceReferenceDate]<deadline)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    Require(condition(),"async completion deadline");
}
static void MakeSyntheticPhoto(NSString *path) {
    const size_t width=6000,height=4000;
    CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap=CGBitmapContextCreate(NULL,width,height,8,width*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);Require(bitmap!=NULL,"synthetic source allocation");
    unsigned char *pixels=CGBitmapContextGetData(bitmap);
    for(size_t y=0;y<height;y++) for(size_t x=0;x<width;x++) {
        unsigned char *pixel=pixels+y*width*4+x*4;
        pixel[0]=(unsigned char)((x/17+y/31)%256);pixel[1]=(unsigned char)((x/7)%256);pixel[2]=(unsigned char)((y/11)%256);pixel[3]=255;
    }
    CGImageRef image=CGBitmapContextCreateImage(bitmap);CGContextRelease(bitmap);
    CGImageDestinationRef destination=CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path],CFSTR("public.jpeg"),1,NULL);
    Require(destination!=NULL,"synthetic JPEG destination");
    NSDictionary *metadata=[NSDictionary dictionaryWithObjectsAndKeys:@6,(NSString *)kCGImagePropertyOrientation,@0.85,(NSString *)kCGImageDestinationLossyCompressionQuality,nil];
    CGImageDestinationAddImage(destination,image,(CFDictionaryRef)metadata);CGImageRelease(image);
    Require(CGImageDestinationFinalize(destination),"synthetic JPEG encode");CFRelease(destination);
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSString *directory=[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    Require([[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:NULL],"fixture folder");
    NSString *photo=[directory stringByAppendingPathComponent:@"synthetic-large.jpg"],*other=[directory stringByAppendingPathComponent:@"synthetic-other.jpg"];
    MakeSyntheticPhoto(photo);Require([[NSFileManager defaultManager] copyItemAtPath:photo toPath:other error:NULL],"second independent cache identity");
    TGMediaImageLoaderClearCache();
    __block BOOL done=NO;__block NSImage *cold=nil;
    NSTimeInterval began=[NSDate timeIntervalSinceReferenceDate];
    TGLoadOrientedImageFromFileAsync(photo,^(NSImage *image){Require([NSThread isMainThread],"completion delivered on main");cold=[image retain];done=YES;});
    NSTimeInterval enqueue=[NSDate timeIntervalSinceReferenceDate]-began;
    WaitFor(^BOOL{return done;});NSTimeInterval coldTime=[NSDate timeIntervalSinceReferenceDate]-began;
    Require(cold!=nil && [cold size].height==2200 && fabs([cold size].width-1467)<=1,"existing2200pixel bound and EXIF rotation preserved");
    Require(DecodeCalls==1 && MainDecodeCalls==0 && PreparedDraws==1 && MainPreparedDraws==0,"one cold decode and RGBA preparation, all off main");
    Require(TGImageWithCorrectOrientationFromFile(photo)==cold,"synchronous path reuses already prepared cache object");
    NSUInteger calls=DecodeCalls,draws=PreparedDraws;__block NSUInteger warmed=0;
    began=[NSDate timeIntervalSinceReferenceDate];
    for(NSUInteger i=0;i<8;i++) TGLoadOrientedImageFromFileAsync(photo,^(NSImage *image){Require(image==cold,"warm navigation shares prepared cached pixels");warmed++;});
    WaitFor(^BOOL{return warmed==8;});NSTimeInterval warmTime=[NSDate timeIntervalSinceReferenceDate]-began;
    Require(DecodeCalls==calls && PreparedDraws==draws,"eight warm navigations perform zero new decode or preparation");
    // Metadata identity still invalidates the same bounded cache after replacement.
    Require([[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSDate dateWithTimeIntervalSinceNow:5] forKey:NSFileModificationDate] ofItemAtPath:photo error:NULL],"fixture timestamp change");
    done=NO;TGLoadOrientedImageFromFileAsync(photo,^(NSImage *image){Require(image!=nil && image!=cold,"replaced file cannot reuse stale prepared pixels");done=YES;});WaitFor(^BOOL{return done;});
    Require(DecodeCalls==calls+1,"changed file signature causes exactly one fresh decode");
    [cold release];cold=nil;
    TGMediaImageLoaderClearCache();calls=DecodeCalls;
    dispatch_semaphore_t gate=dispatch_semaphore_create(0);DecodeGate=gate;GateEntered=NO;
    __block NSUInteger cancelledCallbacks=0;
    TGMediaImageLoadToken *blocker=[TGLoadOrientedImageFromFileAsync(photo,^(NSImage *image){(void)image;cancelledCallbacks++;}) retain];
    WaitFor(^BOOL{return Entered();});
    TGMediaImageLoadToken *cancelled=[TGLoadOrientedImageFromFileAsync(other,^(NSImage *image){(void)image;cancelledCallbacks++;}) retain];
    [cancelled cancel];[blocker cancel];
    __block BOOL mainPing=NO;dispatch_async(dispatch_get_main_queue(),^{mainPing=YES;});WaitFor(^BOOL{return mainPing;});
    Require(ActiveDecodes==1,"main queue stays responsive while one cold decode is blocked on worker");
    dispatch_semaphore_signal(gate);
    done=NO;TGLoadOrientedImageFromFileAsync([directory stringByAppendingPathComponent:@"missing.jpg"],^(NSImage *image){Require(image==nil,"missing file completes with nil");done=YES;});WaitFor(^BOOL{return done;});
    Require(cancelledCallbacks==0 && DecodeCalls==calls+1,"in-flight cancel suppresses callback; queued cancel starts zero decodes");
    Require(MaximumActiveDecodes==1 && MainDecodeCalls==0 && MainPreparedDraws==0,"serial queue bounds concurrent full-photo work to one");
    [blocker release];[cancelled release];dispatch_release(gate);
    NSUInteger rgbaBytes=1467*2200*4;
    printf("Synthetic gallery6000x4000 JPEG/EXIF6: cold %.2fms total, enqueue %.3fms;8warm %.2fms total; coldImageIO1, warmImageIO0, cancelledQueuedImageIO0, mainImageIO0, mainRGBA0, maximumConcurrent1, preparedRGBA~%lu bytes. PASS.\n",coldTime*1000,enqueue*1000,warmTime*1000,(unsigned long)rgbaBytes);
    TGMediaImageLoaderClearCache();Require([[NSFileManager defaultManager] removeItemAtPath:directory error:NULL],"fixture cleanup");
    [pool drain];return 0;
}
