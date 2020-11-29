//
//  whosTyping.m
//  whosTyping
//
//  Created by Wolfgang Baird on 1/21/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import <objc/runtime.h>

#import "JSRollCall.h"
#import "IMHandle.h"
#import "IMPerson.h"
#import "IMAccount.h"
#import "IMAccountController.h"
#import "IMService-IMService_GetService.h"
#import "IMChat.h"
#import "NetworkController.h"
#import "Logging.h"
#import "ChatDisplayController.h"
#import "SelectorHelper.h"



@interface BlueBubblesHelper : NSObject
+ (instancetype)sharedInstance;
@end

BlueBubblesHelper *plugin;
NSUInteger typingIndicators = 0;

typedef NS_ENUM(NSUInteger, WBWT_StatusBarType) {
    WBWT_StatusBarTypeTyping,
    WBWT_StatusBarTypeRead,
    WBWT_StatusBarTypeEmpty
};

NSString *__kIMChatComposeTyping = @"__kIMChatComposeTyping";




@implementation BlueBubblesHelper

// BlueBubblesHelper is a singleton
+ (instancetype)sharedInstance {
    static BlueBubblesHelper *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

// Called when macforge initializes the plugin
+ (void)load {
    // Create the singleton
    plugin = [BlueBubblesHelper sharedInstance];
    
    // Get OS version for debugging purposes
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    DLog(@"BLUEBUBBLESHELPER: %@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
    
    [plugin initializeNetworkController];
    
}

// Private method to initialize all the things required by the plugin to communicate with the main
// server over a tcp socket
-(void) initializeNetworkController {
    // Get the network controller
    NetworkController *controller = [NetworkController sharedInstance];
    [controller connect];
    
    // If the tcp connection fails, attempt to reconnect every 5 seconds
    controller.connectionFailedBlock = ^(NetworkController *connection) {
        DLog(@"BLUEBUBBLESHELPER: Failed to connect to server, trying again in 5 seconds...");
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DLog(@"BLUEBUBBLESHELPER: Attempting to reconnect");
            [connection connect];
        });
    };
    
    // If the tcp connection closes, attempt to reconnect every 5 seconds
    controller.connectionClosedBlock = ^(NetworkController *connection) {
        DLog(@"BLUEBUBBLESHELPER: Disconnected from server, attempting to reconnect in 5 seconds...");
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DLog(@"BLUEBUBBLESHELPER: Attempting to reconnect");
            [connection connect];
        });
    };
    
    // Debugging to detect when the plugin successfully made a connection
    controller.connectionOpenedBlock = ^(NetworkController *controller) {
        DLog(@"BLUEBUBBLESHELPER: Connected to server!");
    };
    
    // Upon receiving a message
    controller.messageReceivedBlock =  ^(NetworkController *controller, NSString *data) {
        [self handleMessage:controller message: data];
    };
    NSDictionary *message = @{@"event": @"ping", @"message": @"Helper Connected!"};
    [controller sendMessage:message];
}

// Run when receiving a new message from the tcp socket
-(void) handleMessage: (NetworkController*)controller  message:(NSString *)data {
    // The data is in the form of a json string, so we need to convert it to a NSDictionary
    DLog(@"BLUEBUBBLESHELPER: Received raw json: %@", data);
    NSError *error;
    NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    // Event is the type of packet that was sent
    NSString *event = dictionary[@"event"];
    // Data is the actual information that we need in the packet
    NSString *eventData = dictionary[@"data"];

    DLog(@"BLUEBUBBLESHELPER: Message received: %@, %@", event, eventData);
    
    // If the server tells us to start typing
    if([event isEqualToString: @"start-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        // Asynchronous so we have a completion block
        [BlueBubblesHelper getChat:eventData completion:^(id chat) {
            // If we found no chat we can't do anything
            if(chat != nil) {
                // Send a typing event by using the constant __kIMChatComposeTyping and NULL data
                // This was retreived by analyzing the output received from this function normally
                [chat performSelector:@selector(setLocalUserIsComposing:typingIndicatorData:) withObject: __kIMChatComposeTyping withObject: NULL];
            }
        }];
        
    // If the server tells us to stop typing
    } else if([event isEqualToString:@"stop-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        // Asynchronous so we have a completion block
        [BlueBubblesHelper getChat:eventData completion:^(id chat) {
            // If we found no chat we can't do anything
            if(chat != nil) {
                // Stop the typing event by using the constant all NULL data
                // This was retreived by analyzing the output received from this function normally
                [chat performSelector:@selector(setLocalUserIsComposing:typingIndicatorData:) withObject: NULL withObject: NULL];
            }

        }];
        
    // If the server tells us to mark a chat as read
    } else if([event isEqualToString:@"mark-chat-read"]) {
        // Get the IMChat instance for the guid specified in eventData
        // Asynchronous so we have a completion block
        [BlueBubblesHelper getChat:eventData completion:^(id chat) {
            // If we found no chat we can't do anything
            if(chat != nil) {
                // Stop the typing event by using the constant all NULL data
                // This was retreived by analyzing the output received from this function normally
                [chat performSelector:@selector(markAllMessagesAsRead)];
            }

        }];
    // If the event is something that hasn't been implemented, we simply ignore it and put this log
    } else {
        DLog(@"BLUEBUBBLESHELPER: Not implemented %@", event);
    }

}

// Asynchronously retreive a IMChat instance from a given guid
//
// Looks through all of the ChatDisplayControllers by looking at all of the ChatTableCellViews present
// and checking to see if the guid matches
+(void) getChat: (NSString *) guid completion: (void (^)(id chat)) completion{
    // Create a new instance of JSRollCall
    JSRollCall *rc = [JSRollCall new];
    
    // Get all of the ChatTableCellViews asynchronously
    [rc allObjectsOfClassName:@"ChatTableCellView" includeSubclass:YES performBlock:^(id obj) {
        // Get the ChatDisplayController
        id controller = [SelectorHelper getValueForKey:@"chatDisplayController" :obj];
        
        // Get the guid from the controller
        NSString *_guid = [ChatDisplayController getGuid:controller];
        
        // If the guid matches, we are done and can finish with the completion block
        if([_guid isEqualToString: guid]) {
            // Get the IMChat instance
            id chat = [ChatDisplayController getChat:controller];
            completion(chat);

        }
    }];
        
}

@end

// SOTypingIndicator view shows the typing indicator on the chat list
//
// We can call events depending on whether this view is visible or not
ZKSwizzleInterface(WBWT_SOTypingIndicatorView, SOTypingIndicatorView, NSView)
@implementation WBWT_SOTypingIndicatorView

- (void)destroyTypingLayer {
    // Get the guid of the current typing indicator
    id guid = [self getGuid];
    
    // We can't do anything if the guid is nil
    if(guid != nil) {
        // Send a message through the tcp socket that the chat of a certain GUID has stopped typing
        DLog(@"BLUEBUBBLESHELPER: %@ Stopped typing", guid);
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];

    }
    
    ZKOrig(void);
}


- (void)startPulseAnimation {
    // Get the guid of the current typing indicator
    id guid = [self getGuid];
    
    // We can't do anything if the guid is nil
    if(guid != nil) {
        // Send a message through the tcp socket that the chat of a certain GUID has started typing
        DLog(@"BLUEBUBBLESHELPER: %@ Started typing", guid);
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
    
    }
    
    ZKOrig(void);
}

// Helper function to get the current IMChat
//
// This is not an overwritten function
- (id) getChat {
    // Go through the widget tree to find the existingChatDisplayController
    // Uses nil checks on every step to prevent crashes
    NSView *maskedView = self.superview;
    if(maskedView == nil) return nil;
    NSView *maskedViewParent = maskedView.superview;
    if(maskedViewParent == nil) return nil;
    NSView *secondaryMaskedViewParent = maskedViewParent.superview;
    if(secondaryMaskedViewParent == nil) return nil;
    NSView *chatTableCellView = secondaryMaskedViewParent.superview;
    if(chatTableCellView == nil) return nil;
    id existingChatDisplayController = [SelectorHelper getValueForKey:@"chatDisplayController": chatTableCellView ];
    
    // We can't do anything if the chatcontroller is nil
    if(existingChatDisplayController == nil) return nil;
    
    // Get the IMChat based on the existingChatDisplayController
    return [ChatDisplayController getChat:existingChatDisplayController];
}


// Helper function to get the guid
//
// This is not an overwritten function
- (id)getGuid {
    NSView *maskedView = self.superview;
    if(maskedView == nil) return nil;
    NSView *maskedViewParent = maskedView.superview;
    if(maskedViewParent == nil) return nil;
    NSView *secondaryMaskedViewParent = maskedViewParent.superview;
    if(secondaryMaskedViewParent == nil) return nil;
    NSView *chatTableCellView = secondaryMaskedViewParent.superview;
    if(chatTableCellView == nil) return nil;
    id existingChatDisplayController = [SelectorHelper getValueForKey:@"chatDisplayController": chatTableCellView ];

    // We can't do anything if the chatcontroller is nil
    if(existingChatDisplayController == nil) return nil;
    
    return [ChatDisplayController getGuid:existingChatDisplayController];

}


@end


//ZKSwizzleInterface(WBWT_IMMessage, IMMessage, NSObject)
//@implementation WBWT_IMMessage
//
//+ (id)instantMessageWithAssociatedMessageContent:(id)arg1 flags:(unsigned long long)arg2 associatedMessageGUID:(id)arg3 associatedMessageType:(long long)arg4 associatedMessageRange:(struct _NSRange)arg5 messageSummaryInfo:(id)arg6 {
//    /*/
//     BLUEBUBBLESHELPER: instantMessageWithAssociatedMessageContent, Loved “Test”{
//         "__kIMMessagePartAttributeName" = 0;
//     }, 0, p:0/09EF06EB-E67C-47C0-ABBD-26310BF954AE, 2000, {
//         amc = 1;
//         ams = Test;
//     }, (null)
//     associatedMessageType: left -> right 2000 ->
//     */
//
//
//
////    testRange.amc = arg5.amc;
////    testRange.ams = @"Test";
//
//    DLog(@"BLUEBUBBLESHELPER: instantMessageWithAssociatedMessageContent, %@, %llu, %@, %lld, %@, %@", [arg1 class], arg2, [arg3 class], arg4, arg5, arg6);
//    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"TEST REACTION"];
//    return ZKOrig(id, string, arg2, arg3, arg4, arg5, NULL);
//}
//
//@end

//ZKSwizzleInterface(WBWT_IMChat, IMChat, NSObject)
//@implementation WBWT_IMChat
//
//- (void) sendMessage:(id)arg1 {
//    /* REGULAR MESSAGE
//     InstantMessage[from=e:; msg-subject=(null); account:053CB8C2-3D2E-4DA6-8D29-419A2F5D4D49; flags=5; subject='(null)' text='(null)' messageID: 0 GUID:'D5E40A69-68EF-4C5D-8F3C-C1543988666F' sortID: 0 date:'627629434.853740' date-delivered:'0.000000' date-read:'0.000000' date-played:'0.000000' empty: NO finished: YES sent: NO read: NO delivered: NO audio: NO played: NO from-me: YES emote: NO dd-results: NO dd-scanned: NO error: (null) associatedMessageGUID: (null) associatedMessageType: 0 balloonBundleID: (null) expressiveSendStyleID: (null) timeExpressiveSendStylePlayed: 0.000000 bizIntent:(null) locale:(null), ]
//        REACTION
//     IMMessage[from=(null); msg-subject=(null); account:(null); flags=5; subject='(null)' text='(null)' messageID: 0 GUID:'79045C8B-1E6E-480B-8819-37E36C517578' sortID: 0 date:'627629508.210384' date-delivered:'0.000000' date-read:'0.000000' date-played:'0.000000' empty: NO finished: YES sent: NO read: NO delivered: NO audio: NO played: NO from-me: YES emote: NO dd-results: NO dd-scanned: NO error: (null) associatedMessageGUID: p:0/0C14634E-563D-408C-B9D4-805FEF7ADC7B associatedMessageType: 2001 balloonBundleID: (null) expressiveSendStyleID: (null) timeExpressiveSendStylePlayed: 0.000000 bizIntent:(null) locale:(null), ]
//
//     */
//    DLog(@"BLUEBUBBLESHELPER: sendMessage %@", arg1);
//    ZKOrig(void, arg1);
//}
//
//@end






//@interface IMDMessageStore : NSObject
//+ (id)sharedInstance;
//- (id)messageWithGUID:(id)arg1;
//@end
//
//ZKSwizzleInterface(WBWT_IMDServiceSession, IMDServiceSession, NSObject)
//@implementation WBWT_IMDServiceSession
//
//+ (id)sharedInstance {
//    return ZKOrig(id);
//}
//
//- (id)messageWithGUID:(id)arg1 {
//    return ZKOrig(id, arg1);
//}
//
//- (void)didReceiveMessageReadReceiptForMessageID:(NSString *)messageID date:(NSDate *)date completionBlock:(id)completion {
//    ZKOrig(void, messageID, date, completion);
//    Class IMDMS = NSClassFromString(@"IMDMessageStore");
//}
//
//@end

//ZKSwizzleInterface(WBWT_IMMessage, IMMessage, NSObject)
//@implementation WBWT_IMMessage
//
//- (void)_updateTimeRead:(id)arg1 {
//    ZKOrig(void, arg1);
//    DLog(@"typeStatus : _updateTimeRead");
//}
//
//@end


