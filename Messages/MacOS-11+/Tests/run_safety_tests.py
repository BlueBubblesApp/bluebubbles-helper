#!/usr/bin/env python3
"""Compile only Foundation fixtures containing the actual helper methods; no injection."""
import re
import subprocess
import tempfile
from pathlib import Path

folder = Path(__file__).resolve().parent


def extract_methods(filename, signatures):
    source = (folder.parent / 'BlueBubblesHelper' / filename).read_text()
    masked = re.sub(r'//[^\n]*|/\*[\s\S]*?\*/|@?"(?:\\.|[^"\\])*"',
                    lambda match: ' ' * len(match[0]), source)
    methods = []
    for signature in signatures:
        start = source.index(signature)
        brace = masked.index('{', start)
        depth = 1
        end = brace + 1
        while depth:
            depth += (masked[end] == '{') - (masked[end] == '}')
            end += 1
        methods.append(source[start:end])
    return '\n\n'.join(methods)


methods = extract_methods('BlueBubblesHelper.m', (
    '- (void) addHandleAvailabilityObserver', '- (void) addTypingIndicatorObserver',
    '- (void)getIMMessageFromGuid:', '- (void)getIMMessagePartChatItemFromGuid:'))
network_methods = extract_methods('NetworkController.m', (
    '- (NSDictionary*) jsonDecode:', '- (void)socket:(GCDAsyncSocket*)sock didReadData:'))
dispatcher = extract_methods('BlueBubblesHelper.m', ('-(void) handleServerEvent:',))
dispatcher_prelude = dispatcher[dispatcher.index('{') + 1:dispatcher.index('if (transaction == nil)')]
with tempfile.TemporaryDirectory(prefix='bb-messages-safety-') as temporary:
    path = Path(temporary)
    fixture = (folder / 'MessageSafetyTests.m').read_text()
    (path / 'test.m').write_text(fixture.replace('/* SOURCE_METHODS */', methods)
                               .replace('/* NETWORK_SOURCE_METHODS */', network_methods)
                               .replace('/* DISPATCH_SOURCE_PRELUDE */', dispatcher_prelude))
    subprocess.run(['/usr/bin/xcrun', '--sdk', 'macosx', 'clang', '-fobjc-arc', '-fblocks',
                    '-framework', 'Foundation', str(path / 'test.m'), '-o', str(path / 'tests')], check=True)
    subprocess.run([str(path / 'tests')], check=True)
