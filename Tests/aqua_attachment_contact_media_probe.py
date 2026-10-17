#!/usr/bin/env python
"""Native production constructors: caption scrolling, contact picker, image-first media."""
from __future__ import print_function, unicode_literals
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as f: return f.read().decode('utf-8')
def method(source,start,end):
    first=source.index(start); return source[first:source.index(end,first)]
lifecycle=read('Sources/UI/TGChatLifecycleWindowController.m')
media=read('Sources/UI/TGStatusWindowController+MediaWindows.inc')
constructors=read('Sources/UI/TGStatusWindowController+AttachmentPreview.inc')
composer=read('Sources/UI/TGStatusWindowController+ComposerMedia.inc')
# The native reset under test must serve both entry points, not remain unused.
assert '[self resetAttachmentCaption];' in method(composer,'- (void)presentAttachmentPreviewForDescriptors:','- (void)presentAttachmentPreviewForDescriptor:')
assert '[self resetAttachmentCaption];' in method(composer,'- (void)cancelPendingPhotoSend:','- (void)submitPhotoAtPath:')
aqua=read('Sources/UI/TGChatLifecycleWindowController+Aqua.inc')
selection=method(lifecycle,'- (void)updateSelectionActions {','- (void)controlTextDidChange:')
focus=method(lifecycle,'- (void)focusInviteLink {','\n@end')
grid=method(media,'- (void)buildMediaCenterGridRowsWithItems:','- (void)buildMediaCenterListRowsWithItems:')
specs=[('NSPopUpButton *','createPopUpButton'),('NSTextField *','aquaTitleField'),('NSView *','aquaListCard'),('NSScrollView *','aquaListScrollView'),('NSButton *','inviteDisclosureButton'),('BOOL','aquaInvitationVisible'),('NSSearchField *','searchField'),('NSButton *','refreshButton'),('NSTableView *','tableView'),('NSTextField *','statusField'),('NSProgressIndicator *','spinner'),('NSButton *','openButton'),('NSButton *','groupButton'),('NSButton *','secretButton'),('NSTextField *','inviteField'),('NSButton *','joinButton'),('BOOL','loading'),('NSArray *','selected'),('NSWindow *','photoSendPreviewWindow'),('NSTextField *','photoSendTitleField'),('NSImageView *','photoSendPreviewImageView'),('NSView *','photoSendCaptionBackgroundView'),('NSTextView *','photoSendCaptionField'),('NSScrollView *','photoSendCaptionScrollView'),('NSTextField *','photoSendErrorField'),('NSButton *','photoSendSendButton'),('NSView *','mediaCenterResultsView')]
fields='\n'.join(typ+' _'+name+';' for typ,name in specs)
properties='\n'.join('@property(nonatomic,'+('retain' if '*' in typ else 'assign')+') '+typ+' '+name+';' for typ,name in specs)
synthesis='\n'.join('@synthesize '+name+'=_'+name+';' for typ,name in specs)
releases='\n'.join('[_'+name+' release];' for typ,name in specs if '*' in typ)
harness=read('Tests/aqua_attachment_contact_media_probe.m')
for token,value in [('__FIELDS__',fields),('__PROPERTIES__',properties),('__SYNTHESIS__',synthesis),('__RELEASE__',releases),('__PRODUCTION_METHODS__',constructors+'\n'+aqua+'\n'+selection+'\n'+focus+'\n'+grid)]: harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-composition-')
try:
    source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(source,'wb') as f: f.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+[source,'-I'+os.path.join(ROOT,'Sources/UI'),'-Wno-incomplete-implementation',os.path.join(ROOT,'Sources/UI/TGLocalization.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally: shutil.rmtree(folder)
