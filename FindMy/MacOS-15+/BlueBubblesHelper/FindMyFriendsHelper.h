#ifndef FindMyFriendsHelper_h
#define FindMyFriendsHelper_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FindMyFriendsHelper : NSObject

+ (instancetype)sharedInstance;

- (void)handleServerAction:(nullable NSString *)action
     transactionIdentifier:(nullable NSString *)transactionIdentifier;

@end

NS_ASSUME_NONNULL_END

#endif
