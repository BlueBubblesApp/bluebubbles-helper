#!/usr/bin/env python3
"""Check that every Messages-facing Server action has a helper dispatcher branch."""
import argparse
import json
import re
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--server-root', required=True, type=Path)
args = parser.parse_args()
helper = (Path(__file__).resolve().parents[1] / 'BlueBubblesHelper/BlueBubblesHelper.m').read_text()
handled = set(re.findall(r'event isEqualToString:@"([^"]+)"', helper))
api = args.server_root / 'packages/server/src/server/api/privateApi/apis'
actions = set()
for name in ('Cloud', 'Chat', 'Handle', 'Message', 'Attachment'):
    text = (api / ('PrivateApi' + name + '.ts')).read_text()
    actions.update(re.findall(r'const action = "([^"]+)"', text))
    if '${pAction}-participant' in text:
        actions.update(('add-participant', 'remove-participant'))
missing = sorted(actions - handled)
print(json.dumps({'actions_checked': len(actions), 'unhandled_actions': missing}))
raise SystemExit(bool(missing))
