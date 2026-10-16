#!/usr/bin/env python
"""Render the production missing-avatar function without account/media backends."""
from __future__ import print_function
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
with open(os.path.join(ROOT,'Sources/UI/TGMessageLayoutSupport.m'),'rb') as f:source=f.read().decode('utf-8')
parts=[]
for start,end in [('NSString *TGInitialsForTitle(', 'void TGDrawImageInRect('),('void TGDrawImageInRect(', 'void TGDrawImageAspectFillInRect('),('void TGDrawAvatarImageInRect(', 'NSString *TGShortTimeStringFromDateValue(')]:
 a=source.index(start); b=source.index(end,a);parts.append(source[a:b])
with open(os.path.join(ROOT,'Tests/aqua_avatar_contrast_probe.m'),'rb') as f:harness=f.read().decode('utf-8').replace('__PRODUCTION_AVATAR__','\n'.join(parts))
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-avatar-contrast-')
try:
 path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
 with open(path,'wb') as f:f.write(harness.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+[path,'-I'+os.path.join(ROOT,'Sources/UI'),'-framework','Cocoa','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
