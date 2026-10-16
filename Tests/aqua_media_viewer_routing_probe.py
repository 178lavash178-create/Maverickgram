#!/usr/bin/env python
"""Exercise the actual photo/video window constructors and layout methods."""
from __future__ import print_function
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
with open(os.path.join(ROOT,'Sources/UI/TGStatusWindowController+MediaWindows.inc'),'rb') as f: source=f.read().decode('utf-8')
methods=[]
for first,last in [
 ('- (void)ensureMediaPlaybackWindow {','- (NSTimeInterval)secondsFromMediaPlaybackTime:'),
 ('- (void)layoutMediaPlaybackChromeForAudioOnly:','- (void)updateMediaPlaybackButton {'),
 ('- (void)layoutMediaPreviewWindowControls {','- (void)resizeMediaPreviewWindowForImage:'),
 ('- (void)ensureMediaPreviewWindow {','#include "TGStatusWindowController+MediaPreviewZoom.inc"')]:
 a=source.index(first);b=source.index(last,a);methods.append(source[a:b])
specs=[('NSWindow *','mediaPlaybackWindow'),('NSView *','mediaPlaybackContainerView'),('NSTextField *','mediaPlaybackTitleField'),('NSButton *','mediaPlaybackPlayPauseButton'),('NSSlider *','mediaPlaybackProgressSlider'),('NSTextField *','mediaPlaybackTimeField'),('NSPopUpButton *','mediaPlaybackRatePopUpButton'),('NSButton *','mediaPlaybackCloseButton'),('BOOL','mediaPlaybackAudioOnly'),('BOOL','mediaPlaybackVideoNote'),('double','mediaPlaybackRate'),('NSWindow *','mediaPreviewWindow'),('NSView *','mediaPreviewPanelView'),('NSView *','mediaPreviewSurfaceView'),('NSView *','mediaPreviewToolbarView'),('NSScrollView *','mediaPreviewScrollView'),('NSImageView *','mediaPreviewImageView'),('NSButton *','mediaPreviewZoomOutButton'),('NSButton *','mediaPreviewFitButton'),('NSButton *','mediaPreviewZoomInButton')]
fields='\n'.join('    '+typ+' _'+name+';' for typ,name in specs)
properties='\n'.join('@property(nonatomic,'+('retain' if '*' in typ else 'assign')+') '+typ+' '+name+';' for typ,name in specs)
synthesis='\n'.join('@synthesize '+name+'=_'+name+';' for typ,name in specs)
release='\n'.join('    [_'+name+' release];' for typ,name in specs if '*' in typ)
with open(os.path.join(ROOT,'Tests/aqua_media_viewer_routing_probe.m'),'rb') as f: harness=f.read().decode('utf-8')
for token,value in [('__FIELDS__',fields),('__PROPERTIES__',properties),('__SYNTHESIS__',synthesis),('__RELEASE__',release),('__PRODUCTION_METHODS__','\n'.join(methods))]:harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-media-viewer-routing-')
try:
 path=os.path.join(folder,'probe.m');app=os.path.join(folder,'Probe.app');contents=os.path.join(app,'Contents');os.makedirs(os.path.join(contents,'MacOS'));os.makedirs(os.path.join(contents,'Resources'));binary=os.path.join(contents,'MacOS','probe')
 shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(contents,'Resources/Icons'))
 with open(os.path.join(contents,'Info.plist'),'w') as f:f.write('<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>probe</string><key>CFBundleIdentifier</key><string>local.telegraphica.media-probe</string></dict></plist>')
 with open(path,'wb') as f:f.write(harness.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+[path,os.path.join(ROOT,'Sources/UI/TGAquaMediaViewerView.m'),os.path.join(ROOT,'Sources/UI/TGIconAssets.m'),'-I'+os.path.join(ROOT,'Sources/UI'),'-framework','Cocoa','-framework','QuartzCore','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
