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

@class GCDAsyncSocket;

@interface NetworkController : NSObject<GCDAsyncSocketDelegate> {
    GCDAsyncSocket *asyncSocket;
}

// Singleton instance
+ (NetworkController*)sharedInstance;

// Methods
- (void)connect;
- (void)sendMessage:(NSDictionary*)message;

@end
#endif /* NetworkController_h */
