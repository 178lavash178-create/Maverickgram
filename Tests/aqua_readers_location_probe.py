#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function
import os,shutil,subprocess,sys,tempfile
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
build=tempfile.mkdtemp(prefix='telegraphica-readers-location-')
try:
 app=os.path.join(build,'Probe.app','Contents');os.makedirs(os.path.join(app,'MacOS'))
 shutil.copytree(os.path.join(root,'Sources','Resources','Textures'),os.path.join(app,'Resources','Textures'))
 exe=os.path.join(app,'MacOS','probe')
 sources=['Tests/aqua_readers_location_probe.m','Sources/UI/TGMessageViewersWindowController.m','Sources/UI/TGLocationPickerWindowController.m','Sources/UI/TGLocationStaticMapView.m','Sources/UI/TGLocalization.m','Sources/UI/TGTheme.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGDialogPresentation.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGVisualWorldThemeSpec.m','Sources/UI/TGStatusButtonCells.m','Sources/UI/TGButtonAppearance.m','Sources/UI/TGIconAssets.m','Sources/UI/TGIconDrawing.m']
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(root,'Sources',d) for d in ['UI','Core','Media','Services']]+[os.path.join(root,s) for s in sources]+['-framework','Cocoa','-framework','QuartzCore','-framework','MapKit','-framework','CoreLocation','-o',exe])
 env=dict(os.environ);env['HOME']=os.path.join(build,'home');os.makedirs(env['HOME'])
 for mode in ['classic','aqua']:subprocess.check_call([exe,mode],env=env)
finally:shutil.rmtree(build)
