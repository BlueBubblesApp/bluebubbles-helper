//
//  ChatDisplayController.h
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/29/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#ifndef ChatDisplayController_h
#define ChatDisplayController_h

// Helper class that includes all of the important info of ChatDisplayController locally here
// Most of this was extracted by looking at FScriptObject Browser
// This is NOT an overrided class that we are injecting into,
// it is just a helper class to make things easier
@interface ChatDisplayController : NSObject
+(NSString *) getGuid: (id) existingChatDisplayController;
+(id) getChat: (id) existingChatDisplayController;
@end

#endif /* ChatDisplayController_h */
