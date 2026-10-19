#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>

extern BOOL BBEmojiTapbacksSupportedForRuntime(NSInteger majorVersion, Class emoji, Class chat);
extern BOOL BBSupportsEmojiTapbacks(void);
extern NSString *BBEmojiTapbackRequestError(NSDictionary *data, BOOL supported);

@interface TestEmoji : NSObject
- (instancetype)initWithEmoji:(NSString *)emoji isRemoved:(BOOL)removed;
@end
@implementation TestEmoji
- (instancetype)initWithEmoji:(NSString *)emoji isRemoved:(BOOL)removed { return [super init]; }
@end
@interface TestChat : NSObject
- (void)sendTapback:(id)tapback forChatItem:(id)item;
@end
@implementation TestChat
- (void)sendTapback:(id)tapback forChatItem:(id)item {}
@end
static void check(BOOL passed, const char *message) {
    if (!passed) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
int main(void) {
    @autoreleasepool {
        check(!BBEmojiTapbacksSupportedForRuntime(25, TestEmoji.class, TestChat.class), "older OS");
        check(!BBEmojiTapbacksSupportedForRuntime(26, Nil, TestChat.class), "missing emoji class");
        check(!BBEmojiTapbacksSupportedForRuntime(26, TestEmoji.class, Nil), "missing chat class");
        check(!BBEmojiTapbacksSupportedForRuntime(26, NSObject.class, TestChat.class), "missing initializer");
        check(!BBEmojiTapbacksSupportedForRuntime(26, TestEmoji.class, NSObject.class), "missing send selector");
        check(BBEmojiTapbacksSupportedForRuntime(26, TestEmoji.class, TestChat.class), "supported runtime");
        check(BBEmojiTapbacksSupportedForRuntime(27, TestEmoji.class, TestChat.class), "newer runtime");
        // Foundation-only process: IMCore/ChatKit is not loaded here.
        check(!BBSupportsEmojiTapbacks(), "unavailable private runtime fails closed");
        for (NSString *name in @[@"love", @"like", @"dislike", @"laugh", @"emphasize", @"question"]) {
            for (NSString *prefix in @[@"", @"-"]) {
                check(BBEmojiTapbackRequestError(@{@"reactionType":[prefix stringByAppendingString:name]}, NO) == nil, "classic compatibility");
            }
        }
        for (NSString *emoji in @[@"💙", @"👀", @"👍🏽", @"👩🏽‍💻", @"🇺🇸", @"1️⃣"]) {
            for (NSString *kind in @[@"emoji", @"-emoji"]) {
                NSDictionary *request = @{@"reactionType":kind, @"reactionEmoji":emoji};
                check(BBEmojiTapbackRequestError(request, YES) == nil, "supported Unicode add/remove");
                check(BBEmojiTapbackRequestError(request, NO) != nil, "unsupported runtime rejected");
            }
        }
        for (id value in @[@"", @123, [NSNull null], @"🔥\n", @"hello", @"🔥🔥", [@"🔥" stringByPaddingToLength:300 withString:@"🔥" startingAtIndex:0]]) {
            check(BBEmojiTapbackRequestError(@{@"reactionType":@"emoji", @"reactionEmoji":value}, YES) != nil, "malformed payload");
        }
        for (id value in @[@"not-emoji", @123, [NSNull null]]) {
            check(BBEmojiTapbackRequestError(@{@"reactionType":value}, YES) != nil, "invalid reaction type");
        }
        puts("Emoji Tapback capability and request validation passed");
    }
}
