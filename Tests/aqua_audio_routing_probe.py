#!/usr/bin/env python
"""Run production inline-audio ownership/layout methods against AppKit views."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
with open(os.path.join(ROOT, 'Sources/UI/TGStatusWindowController+AquaAudioPlayer.inc'), 'rb') as handle:
    controller = handle.read().decode('utf-8')
methods = []
for signature, next_signature in [
    ('- (void)layoutAquaAudioPlayerForContentBounds:', '- (void)presentAquaAudioPlayer'),
    ('- (void)detachAquaAudioPlayerAnimated:', '- (void)closeAquaAudioPlayer:')]:
    start = controller.index(signature)
    end = controller.index(next_signature, start)
    methods.append(controller[start:end])
with open(os.path.join(ROOT, 'Tests/aqua_audio_routing_probe.m'), 'rb') as handle:
    harness = handle.read().decode('utf-8').replace('__PRODUCTION_AUDIO_METHODS__', '\n'.join(methods))
folder = tempfile.mkdtemp(prefix='telegraphica-aqua-audio-routing-')
try:
    source = os.path.join(folder, 'audio-routing.m')
    binary = os.path.join(folder, 'audio-routing')
    with open(source, 'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:] + [source, os.path.join(ROOT, 'Sources/UI/TGAquaAudioPlayerView.m'),
                                        '-I' + os.path.join(ROOT, 'Sources/UI'), '-framework', 'Cocoa', '-o', binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
