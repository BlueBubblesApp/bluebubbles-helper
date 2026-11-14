import tempfile
import unittest
from pathlib import Path

from check_server_protocol import declared_actions, handled_actions, required_actions


class ServerProtocolTests(unittest.TestCase):
    def test_comments_cannot_hide_a_missing_branch(self):
        source = '''
        - (void)unrelated { if ([event isEqualToString:@"unrelated"]) {} }
        - (void)handleServerEvent:(NSString *)event {
            if ([event isEqualToString:@"active"]) {}
            // if ([event isEqualToString:@"missing"]) {}
            /* if ([event isEqualToString:@"also-missing"]) {} */
        }
        '''
        self.assertEqual(handled_actions(source), {'active'})
        self.assertEqual({'active', 'missing'} - handled_actions(source), {'missing'})

    def test_empty_dispatcher_fails(self):
        with self.assertRaises(ValueError):
            handled_actions('- (void)handleServerEvent:(NSString *)event {}')

    def test_server_comments_and_templates(self):
        source = '''
        // const action = "commented";
        const action = "send-message";
        const action = `${pAction}-participant`;
        '''
        self.assertEqual(declared_actions(source), {'send-message', 'add-participant', 'remove-participant'})

    def test_empty_or_unknown_server_actions_fail(self):
        for source in ('// const action = "commented";', 'const action = newAction;'):
            with self.assertRaises(ValueError):
                declared_actions(source)

    def test_legacy_friends_is_required_but_devices_is_separate(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            api = root / 'packages/server/src/server/api/privateApi/apis'
            api.mkdir(parents=True)
            for name in ('Cloud', 'Chat', 'Handle', 'Message', 'Attachment'):
                (api / ('PrivateApi' + name + '.ts')).write_text('const action = "fixture";')
            (api / 'PrivateApiFindMy.ts').write_text('''
                const action = "refresh-findmy-friends";
                const action = "refresh-findmy-devices";
            ''')
            actions = required_actions(root)
            self.assertIn('refresh-findmy-friends', actions)
            self.assertNotIn('refresh-findmy-devices', actions)


if __name__ == '__main__':
    unittest.main()
