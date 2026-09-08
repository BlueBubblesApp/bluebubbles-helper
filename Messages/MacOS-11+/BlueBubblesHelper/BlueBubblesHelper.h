//
//  BlueBubblesHelper.h
//  BlueBubblesHelper
//
//  Created by Tanay Neotia on 5/3/26.
//  Copyright © 2026 BlueBubbleMessaging. All rights reserved.
//

#ifndef BlueBubblesHelper_h
#define BlueBubblesHelper_h

#import "NetworkController.h"

@interface BlueBubblesHelper : NSObject

// Singleton instance
+(instancetype) sharedInstance;

// Methods
-(void) handleServerEvent: (NSString*)event data: (NSDictionary*)data transactionId: (NSString*)transaction;

// Read-receipt suppression used by "mark-chat-read" (suppressReceipt option)
+(void) suppressReceiptsForChat:(NSString *)chatGuid;
+(BOOL) shouldSuppressReceiptForChat:(NSString *)chatGuid;

@end

#endif /* BlueBubblesHelper_h */
