#!/usr/bin/env python3
"""Compile only Foundation fixtures containing the actual helper methods; no injection."""
import re
import subprocess
import tempfile
from pathlib import Path

folder = Path(__file__).resolve().parent
source = (folder.parent / 'BlueBubblesHelper/BlueBubblesHelper.m').read_text()
masked = re.sub(r'//[^\n]*|/\*[\s\S]*?\*/|@?"(?:\\.|[^"\\])*"', lambda match: ' ' * len(match[0]), source)
methods = []
for signature in ('- (void) addHandleAvailabilityObserver', '- (void) addTypingIndicatorObserver',
                  '- (void)getIMMessageFromGuid:', '- (void)getIMMessagePartChatItemFromGuid:'):
    start = source.index(signature)
    brace = masked.index('{', start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (masked[end] == '{') - (masked[end] == '}')
        end += 1
    methods.append(source[start:end])
with tempfile.TemporaryDirectory(prefix='bb-messages-safety-') as temporary:
    path = Path(temporary)
    (path / 'test.m').write_text((folder / 'MessageSafetyTests.m').read_text().replace('/* SOURCE_METHODS */', '\n\n'.join(methods)))
    subprocess.run(['/usr/bin/xcrun', '--sdk', 'macosx', 'clang', '-fobjc-arc', '-fblocks',
                    '-framework', 'Foundation', str(path / 'test.m'), '-o', str(path / 'tests')], check=True)
    subprocess.run([str(path / 'tests')], check=True)
