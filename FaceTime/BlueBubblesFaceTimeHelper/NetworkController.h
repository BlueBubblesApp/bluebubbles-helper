//
//  NetworkController.h
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/20/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#ifndef NetworkController_h
#define NetworkController_h
#import "GCDAsyncSocket.h"

// Block typedefs
@class GCDAsyncSocket;
typedef void (^MessageBlock)(id,NSString*);

@interface NetworkController : NSObject<GCDAsyncSocketDelegate> {
    GCDAsyncSocket *asyncSocket;
    MessageBlock messageReceivedBlock;
}

// Singleton instance
+ (NetworkController*)sharedInstance;

// Methods
- (void)connect;
- (void)disconnect;
- (void)sendMessage:(NSDictionary*)message;

@property (copy) MessageBlock messageReceivedBlock;

@end
#endif /* NetworkController_h */
