#!/usr/bin/env python3
"""Check Messages dispatcher action names against Server action declarations."""
import argparse
import json
import re
from pathlib import Path

TOKENS = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|@?"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|`(?:\\.|[^`\\])*`')


def without_comments(source):
    return TOKENS.sub(lambda match: ' ' * len(match[0]) if match[0].startswith(('//', '/*')) else match[0], source)


def handled_actions(source):
    source = without_comments(source)
    signature = re.search(r'-\s*\(void\)\s*handleServerEvent\s*:', source)
    if signature is None:
        raise ValueError('Messages dispatcher was not found')
    masked = TOKENS.sub(lambda match: ' ' * len(match[0]), source)
    start = masked.index('{', signature.end())
    end, depth = start + 1, 1
    while depth and end < len(masked):
        depth += (masked[end] == '{') - (masked[end] == '}')
        end += 1
    if depth:
        raise ValueError('Messages dispatcher has unmatched braces')
    actions = set(re.findall(r'\[event\s+isEqualToString\s*:\s*@"([^"]+)"\s*\]', source[start:end]))
    if not actions:
        raise ValueError('No executable Messages action branches were found')
    return actions


def declared_actions(source):
    actions = set()
    for expression in re.findall(r'\bconst\s+action\s*=\s*([^;]+);', without_comments(source)):
        expression = expression.strip()
        literal = re.fullmatch(r'([\'"`])([a-z-]+)\1', expression)
        if literal:
            actions.add(literal[2])
        elif expression == '`${pAction}-participant`':
            actions.update(('add-participant', 'remove-participant'))
        else:
            raise ValueError('Unrecognized Server action expression: ' + expression)
    if not actions:
        raise ValueError('No Server action declarations were found')
    return actions


def required_actions(server_root):
    api = server_root / 'packages/server/src/server/api/privateApi/apis'
    actions = set()
    for name in ('Cloud', 'Chat', 'Handle', 'Message', 'Attachment', 'FindMy'):
        actions.update(declared_actions((api / ('PrivateApi' + name + '.ts')).read_text()))
    # Friends still routes through Messages on macOS 11-13. Devices uses the dedicated Find My helper.
    return actions - {'refresh-findmy-devices'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--server-root', required=True, type=Path)
    args = parser.parse_args()
    helper = (Path(__file__).resolve().parents[1] / 'BlueBubblesHelper/BlueBubblesHelper.m').read_text()
    try:
        actions = required_actions(args.server_root)
        missing = sorted(actions - handled_actions(helper))
    except (ValueError, OSError) as error:
        parser.error(str(error))
    print(json.dumps({'actions_checked': len(actions), 'unhandled_actions': missing}))
    return bool(missing)


if __name__ == '__main__':
    raise SystemExit(main())
