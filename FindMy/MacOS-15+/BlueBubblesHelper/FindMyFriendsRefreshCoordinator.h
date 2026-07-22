#import <Foundation/Foundation.h>

#import "FindMyLocateSession.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FindMyFriendsRefreshResponseHandler)(NSDictionary *response);

@interface FindMyFriendsRefreshCoordinator : NSObject

- (instancetype)initWithSession:(id<FindMyLocateSessionProtocol>)session
           transactionIdentifier:(nullable NSString *)transactionIdentifier
               friendListTimeout:(NSTimeInterval)friendListTimeout
          locationRefreshTimeout:(NSTimeInterval)locationRefreshTimeout
                 responseHandler:(FindMyFriendsRefreshResponseHandler)responseHandler;

- (void)start;

@end

NS_ASSUME_NONNULL_END
