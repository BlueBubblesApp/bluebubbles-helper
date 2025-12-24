    } else if ([event isEqualToString:@"leave-chat"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if (chat != nil) {
            @try {
                if ([chat respondsToSelector:@selector(leave)]) {
                    [chat leave];
                } else if ([chat respondsToSelector:@selector(leaveiMessageGroup)]) {
                    [chat leaveiMessageGroup];
                }
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
                }
            } @catch (NSException *e) {
                DLog("BLUEBUBBLESHELPER: Leave chat exception: %@", e);
            }
        }
