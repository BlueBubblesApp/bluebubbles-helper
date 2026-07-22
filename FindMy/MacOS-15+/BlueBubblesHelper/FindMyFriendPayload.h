#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FindMyFriendPayload : NSObject

+ (nullable NSString *)identifierForHandle:(nullable id)handle;

+ (nullable NSDictionary *)locationPayloadForLocation:(nullable id)location
                                                handle:(nullable id)handle;

+ (NSDictionary *)responseForTransactionIdentifier:(nullable NSString *)transactionIdentifier
                       locationsByFriendIdentifier:(NSDictionary<NSString *, NSDictionary *> *)locationsByFriendIdentifier
                          pendingFriendIdentifiers:(NSSet<NSString *> *)pendingFriendIdentifiers
                               friendListTimedOut:(BOOL)friendListTimedOut
                        unidentifiedFriendCount:(NSUInteger)unidentifiedFriendCount;

@end

NS_ASSUME_NONNULL_END
