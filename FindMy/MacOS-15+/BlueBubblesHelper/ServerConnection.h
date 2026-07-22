#ifndef ServerConnection_h
#define ServerConnection_h

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface ServerConnection : NSObject <GCDAsyncSocketDelegate>

+ (instancetype)sharedInstance;

- (void)connect;
- (void)sendMessage:(NSDictionary *)message;

@end

NS_ASSUME_NONNULL_END

#endif
