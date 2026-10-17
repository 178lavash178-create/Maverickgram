#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Extract the approved production avatar renderer for bounded native UI probes."""
from __future__ import print_function, unicode_literals
import os, sys

def write_avatar_support(destination):
    root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
    with open(os.path.join(root,'Sources/UI/TGMessageLayoutSupport.m'),'rb') as handle:
        source=handle.read().decode('utf-8')
    start=source.index('NSString *TGInitialsForTitle(')
    end=source.index('NSString *TGShortTimeStringFromDateValue(',start)
    imports='''#import <Cocoa/Cocoa.h>
#import "TGMessageLayoutSupport.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGInterfaceDesign.h"
#import "TGMediaImageLoader.h"
#include <math.h>
'''
    with open(destination,'wb') as handle:
        handle.write((imports+source[start:end]).encode('utf-8'))

if __name__=='__main__':
    write_avatar_support(sys.argv[1])
