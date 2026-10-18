#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Packaged approved glyph loading, tint raster and pinned provenance checks."""
from __future__ import print_function, unicode_literals
import hashlib,json,os,shutil,subprocess,sys,tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
 with open(os.path.join(ROOT,path),'rb') as f:return f.read()
def require(value,message):
 if not value:raise AssertionError(message)
manifest=json.loads(read('Sources/Resources/Icons/Phosphor/SOURCE_MANIFEST.json').decode('utf-8'))
require(manifest['version']=='2.1.1' and manifest['commit']=='2b75f3ad12b420c9504ef05df8d2564a28f8500e','Phosphor assets remain pinned to reviewed official revision')
require(set(manifest['assets'])==set(['poll','list','back','forward','pin','folder-import']),'all six reviewed symbols are bundled')
for name,item in manifest['assets'].items():
 for ext,key,folder in [('svg','svg_sha256','source/'),('png','png_sha256','')]:
  path='Sources/Resources/Icons/Phosphor/'+folder+name+'.'+ext
  require(hashlib.sha256(read(path)).hexdigest()==item[key],path+' exact source/conversion hash')
 require('/'+manifest['commit']+'/' in item['upstream'],'asset URL uses immutable source revision')
require(hashlib.sha256(read('Sources/Resources/Icons/Phosphor/LICENSE.txt')).hexdigest()==manifest['license_sha256'],'unmodified bundled MIT license')
legacy=json.loads(read('Sources/Resources/Icons/LEGACY_ASSET_INVENTORY.json').decode('utf-8'))
flat=set(name for name in os.listdir(os.path.join(ROOT,'Sources/Resources/Icons')) if name.endswith('.png'))
require(flat==set(legacy['assets']),'inventory covers every pre-existing flat PNG')
for name,item in legacy['assets'].items():
 require(hashlib.sha256(read('Sources/Resources/Icons/'+name)).hexdigest()==item['sha256'],'legacy project asset remains unchanged: '+name)
 require(item['license'] is None and item['upstream_source'] is None,'unknown provenance must not be invented')
menus=read('Sources/UI/TGStatusWindowController+MessageMenus.inc').decode('utf-8')
for old in ['reload','poll','chats']:
 require('TGTemplateIconAssetImage(@"'+old+'",' not in menus,'missing menu lookup removed: '+old)
for name in ['refresh','chat','Phosphor/poll']:
 require('TGTemplateIconAssetImage(@"'+name+'",' in menus,'menu uses bundled resource: '+name)
require('arrayWithObjects:@"Phosphor/folder-import"' in read('Sources/UI/TGChatFolderManagementWindowController+Aqua.inc').decode('utf-8'),'actual Aqua folder toolbar uses inward import symbol')
for p in ['TGMessageFooterMetadata.inc','TGAquaPinnedStripView.inc','TGStatusViewCells.m']:
 require('TGDrawTemplateIconAsset(@"Phosphor/pin"' in read('Sources/UI/'+p).decode('utf-8'),'shared pin semantics: '+p)
source=r'''
#import <Cocoa/Cocoa.h>
#import "TGIconAssets.h"
#include <math.h>
static NSUInteger Checks=0;
static void Check(BOOL value,const char *message){Checks++;if(!value){fprintf(stderr,"Aqua icon assets: %s\n",message);exit(1);}}
static NSBitmapImageRep *Bitmap(NSUInteger side){return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:side pixelsHigh:side bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 NSArray *names=[NSArray arrayWithObjects:@"refresh",@"chat",@"Phosphor/poll",@"Phosphor/list",@"Phosphor/back",@"Phosphor/forward",@"Phosphor/pin",@"Phosphor/folder-import",nil];
 NSArray *colors=[NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:.15 alpha:1],[NSColor whiteColor],[NSColor colorWithCalibratedWhite:.45 alpha:.5],nil];
 for(NSString *name in names){NSImage *raw=TGIconAssetImageNamed(name);Check(raw!=nil,"nested packaged icon loads through production NSBundle loader");
  for(NSUInteger side=12;side<=26;side+=2)for(NSColor *color in colors)for(NSUInteger flip=0;flip<2;flip++){
   NSImage *rendered=TGTemplateIconAssetImage(name,NSMakeSize(side,side),color,1);Check(rendered!=nil&&NSEqualSizes([rendered size],NSMakeSize(side,side)),"template preserves requested point dimensions");
   NSBitmapImageRep *bitmap=Bitmap(side+8);memset([bitmap bitmapData],0,[bitmap bytesPerRow]*[bitmap pixelsHigh]);
   [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
   TGDrawTemplateIconAsset(name,NSMakeRect(4,4,side,side),color,1,flip);[NSGraphicsContext restoreGraphicsState];
   NSUInteger ink=0;for(NSUInteger y=0;y<side+8;y++)for(NSUInteger x=0;x<side+8;x++){
    NSColor *pixel=[[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if([pixel alphaComponent]>.08){ink++;Check(x>=4&&x<side+4&&y>=4&&y<side+4,"icon ink remains inside allocated rect");
     Check(fabs([pixel redComponent]-[pixel greenComponent])<.02&&fabs([pixel redComponent]-[pixel blueComponent])<.02,"tint remains neutral, including white selected and disabled states");
     if(color==[colors objectAtIndex:1])Check([pixel redComponent]>.95,"selected tint is white");}
   }
   Check(ink>side,"real icon raster has visible antialiased ink at small legacy sizes");
  }
 }
 NSString *directory=[[[NSProcessInfo processInfo] environment] objectForKey:@"TG_ICON_PREVIEW_DIR"];
 if([directory length]){[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
  NSBitmapImageRep *sheet=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:640 pixelsHigh:240 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
  [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:sheet]];[[NSColor whiteColor] set];NSRectFill(NSMakeRect(0,0,640,240));
  NSUInteger i=0;for(NSString *name in names){CGFloat x=12+(i%4)*160,y=128-(i/4)*112;
   [name drawAtPoint:NSMakePoint(x,y+65) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]];
   CGFloat offset=0;for(NSNumber *size in [NSArray arrayWithObjects:@16,@20,@26,nil]){TGDrawTemplateIconAsset(name,NSMakeRect(x+offset,y+24,[size doubleValue],[size doubleValue]),[NSColor colorWithCalibratedWhite:.2 alpha:1],1,NO);offset+=44;}
   i++;
  }[NSGraphicsContext restoreGraphicsState];[[sheet representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[directory stringByAppendingPathComponent:@"approved-action-icons.png"] atomically:YES];
 }
 printf("Aqua icon assets PASS: %lu packaged resource, size, ink, tint and clipping checks; pinned MIT source + all 98 legacy asset hashes verified.\n",(unsigned long)Checks);[pool drain];return 0;}
'''
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-icons-')
try:
 app=os.path.join(folder,'Probe.app');contents=os.path.join(app,'Contents');os.makedirs(os.path.join(contents,'MacOS'));os.makedirs(os.path.join(contents,'Resources'))
 shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(contents,'Resources/Icons'))
 with open(os.path.join(contents,'Info.plist'),'w') as f:f.write('<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>probe</string><key>CFBundleIdentifier</key><string>local.telegraphica.icon-asset-probe</string></dict></plist>')
 path=os.path.join(folder,'probe.m');binary=os.path.join(contents,'MacOS','probe')
 with open(path,'wb') as f:f.write(source.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),path,os.path.join(ROOT,'Sources/UI/TGIconAssets.m'),'-framework','Cocoa','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
