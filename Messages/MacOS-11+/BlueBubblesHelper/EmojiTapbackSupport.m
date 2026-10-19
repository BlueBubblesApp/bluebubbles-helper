#import <Foundation/Foundation.h>

// Keep the runtime probe separate so it can be tested without private frameworks
// or injecting the helper into Messages. No private class symbols are linked.
BOOL BBEmojiTapbacksSupportedForRuntime(NSInteger majorVersion, Class emoji, Class chat) {
    return majorVersion >= 26 && emoji != Nil && chat != Nil &&
        [emoji instancesRespondToSelector:NSSelectorFromString(@"initWithEmoji:isRemoved:")] &&
        [chat instancesRespondToSelector:NSSelectorFromString(@"sendTapback:forChatItem:")];
}

BOOL BBSupportsEmojiTapbacks(void) {
    return BBEmojiTapbacksSupportedForRuntime(
        [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion,
        NSClassFromString(@"IMEmojiTapback"), NSClassFromString(@"IMChat"));
}

NSString *BBEmojiTapbackRequestError(NSDictionary *data, BOOL supported) {
    NSString *reaction = [data isKindOfClass:[NSDictionary class]] ? data[@"reactionType"] : nil;
    if (![reaction isKindOfClass:[NSString class]]) return @"Tapback reactionType must be a string";
    BOOL custom = [reaction isEqual:@"emoji"] || [reaction isEqual:@"-emoji"];
    if (!custom) {
        NSArray *classic = @[@"love", @"like", @"dislike", @"laugh", @"emphasize", @"question"];
        NSString *name = [reaction hasPrefix:@"-"] ? [reaction substringFromIndex:1] : reaction;
        return [classic containsObject:name] ? nil : @"Unsupported Tapback reaction type";
    }
    if (!supported) return @"Emoji Tapbacks require a compatible Messages runtime on macOS 26+";
    NSString *emoji = data[@"reactionEmoji"];
    if (![emoji isKindOfClass:[NSString class]] || emoji.length == 0 ||
        [emoji lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 0 ||
        [emoji lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > 256 ||
        [emoji rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
        return @"Emoji Tapbacks require a nonempty bounded Unicode emoji string";
    }
    if ([emoji rangeOfComposedCharacterSequenceAtIndex:0].length != emoji.length ||
        [emoji canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        return @"Emoji Tapbacks require a single Unicode grapheme";
    }
    // Do not reject Unicode format characters: valid emoji use ZWJ and tags.
    for (NSUInteger index = 0; index < emoji.length; index++) {
        unichar value = [emoji characterAtIndex:index];
        if (value < 0x20 || value == 0x7f) return @"Emoji Tapbacks cannot contain ASCII controls";
    }
    // The server validates the complete single-emoji grapheme before dispatch.
    return nil;
}
