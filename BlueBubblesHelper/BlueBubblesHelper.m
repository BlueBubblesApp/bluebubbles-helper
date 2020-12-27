//
//  whosTyping.m
//  whosTyping
//
//  Created by Wolfgang Baird on 1/21/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import <objc/runtime.h>

#import "IMTextMessagePartChatItem.h"
#import "IMHandle.h"
#import "IMPerson.h"
#import "IMAccount.h"
#import "IMAccountController.h"
#import "IMService-IMService_GetService.h"
#import "IMChat.h"
#import "IMMessage.h"
#import "IMMessageItem-IMChat_Internal.h"
#import "IMChatRegistry.h"
#import "NetworkController.h"
#import "Logging.h"
#import "ChatDisplayController.h"
#import "SelectorHelper.h"



@interface BlueBubblesHelper : NSObject
+ (instancetype)sharedInstance;
@end

BlueBubblesHelper *plugin;


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
    
    DLog(@"BLUEBUBBLESHELPER: Initializing Connection in 5 seconds");
    
    // I delay here for 5 seconds because there is a strange bug where
    // the plugin will spam think that a user starts and stops typing.
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [plugin initializeNetworkController];
    });
    
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
    
    if([event isEqualToString:@"send-reaction"]) {
        NSArray *eventDataArr = [eventData componentsSeparatedByString:(@",")];
        
        DLog(@"BLUEBUBBLESHELPER: REACTION INCOMING %@", eventData);
        
        IMChat *chat = [BlueBubblesHelper getChat: eventDataArr[0]];
        if(chat != nil) {
            //Map the reaction type
            long long reactionLong = [BlueBubblesHelper parseReactionType:(eventDataArr[2])];
            
            DLog(@"BLUEBUBBLESHELPER: %lld", reactionLong);

            // Get the messageItem
            NSArray *messageItemInfo = [BlueBubblesHelper getMessageItem:(chat) :(eventDataArr[1])];

//            DLog(@"BLUEBUBBLESHELPER: %@", [[[messageItem message] messageSummaryInfo] valueForKey:@"ust"]);

            //Build the message summary
            NSDictionary *messageSummary = @{@"amc":messageItemInfo[1], @"ams":[[messageItemInfo[0] message] plainBody]};

            DLog(@"BLUEBUBBLESHELPER: %lld", reactionLong);
            DLog(@"BLUEBUBBLESHELPER: %@", messageItemInfo[0]);
            DLog(@"BLUEBUBBLESHELPER: %@", messageSummary);

            // Send the tapback
            [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(messageItemInfo[0]) withMessageSummaryInfo:(messageSummary)];

            DLog(@"BLUEBUBBLESHELPER: sent reaction");
        }
    } else if([event isEqualToString: @"send-message"]) {
        // Index 0 is chat guid, index 1 is the message text, index 2 is the tempguid
        NSArray *eventDataArr = [eventData componentsSeparatedByString:(@",")];
        NSAttributedString* textBody = [[NSAttributedString alloc] initWithString:eventDataArr[1]];


//        IMAccountController *sharedAccountController = [IMAccountController sharedInstance];
//
//        IMAccount *activeAccount = [sharedAccountController activeIMessageAccount];
//
//        if(activeAccount == nil) {
//            activeAccount = [sharedAccountController activeSMSAccount];
//        }
        
        IMChat *activeChat = [BlueBubblesHelper getChat:eventDataArr[0]];
        
        IMMessage* myMessage;
        if(activeChat != nil) {
            myMessage = [IMMessage instantMessageWithText:textBody flags:1048581];
            [activeChat sendMessage:myMessage];
            DLog(@"BLUEBUBBLESHELPER: sent message");
            [BlueBubblesHelper updateMessage:eventDataArr[0] :eventDataArr[2] :[myMessage guid]];
        }
        
    // If the server tells us to start typing
    } else if([event isEqualToString: @"start-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: eventData];
        
        if(chat != nil) {
            // If the IMChat instance is not null, start typing
            [chat setLocalUserIsTyping:YES];
        }
        
    // If the server tells us to stop typing
    } else if([event isEqualToString:@"stop-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: eventData];
        if(chat != nil) {
            // If the IMChat instance is not null, stop typing
            [chat setLocalUserIsTyping:NO];
        }
        
    // If the server tells us to mark a chat as read
    } else if([event isEqualToString:@"mark-chat-read"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: eventData];
        if(chat != nil) {
            // If the IMChat instance is not null, mark everything as read
            [chat markAllMessagesAsRead];
        }
    } else if([event isEqualToString:@"check-typing-status"]) {
        if(eventData != nil) {
            [BlueBubblesHelper updateTypingStatus:eventData];
        }
    // If server tells us to change the display name
    } else if ([event isEqualToString:@"set-display-name"]) {
        NSArray *eventDataArr = [eventData componentsSeparatedByString:(@",")];
        
        IMChat *chat = [BlueBubblesHelper getChat: eventDataArr[0]];
        if(chat != nil) {
            // Set the display name
            [chat _setDisplayName:(eventDataArr[1])];
        }
        DLog(@"BLUEBUBBLESHELPER: Setting display name of chat %@ to %@", eventDataArr[0], eventDataArr[1]);
    // If the event is something that hasn't been implemented, we simply ignore it and put this log
    } else {
        DLog(@"BLUEBUBBLESHELPER: Not implemented %@", event);
    }

}

// Retreive a IMChat instance from a given guid
//
// Uses the chat registry to get an existing instance of a chat based on the chat guid
+(IMChat *) getChat: (NSString *) guid {
    if(guid == nil) return nil;
    
    IMChat* imChat = [[IMChatRegistry sharedInstance] existingChatWithGUID: guid];
    return imChat;
}

+(long long) parseReactionType:(NSString *)reactionType {
    NSString *lowerCaseType = [reactionType lowercaseString];
    
    DLog(@"BLUBUBBLESHELPER: %@", lowerCaseType);
    
    if([@"love" isEqualToString:(lowerCaseType)]) return 2000;
    if([@"like" isEqualToString:(lowerCaseType)]) return 2001;
    if([@"dislike" isEqualToString:(lowerCaseType)]) return 2002;
    if([@"laugh" isEqualToString:(lowerCaseType)]) return 2003;
    if([@"emphasize" isEqualToString:(lowerCaseType)]) return 2004;
    if([@"question" isEqualToString:(lowerCaseType)]) return 2005;
    if([@"-love" isEqualToString:(lowerCaseType)]) return 3000;
    if([@"-like" isEqualToString:(lowerCaseType)]) return 3001;
    if([@"-dislike" isEqualToString:(lowerCaseType)]) return 3002;
    if([@"-laugh" isEqualToString:(lowerCaseType)]) return 3003;
    if([@"-emphasize" isEqualToString:(lowerCaseType)]) return 3004;
    if([@"-question" isEqualToString:(lowerCaseType)]) return 3005;
    return 0;
}

+(NSArray *) getMessageItem:(IMChat *)chat :(NSString *)actionMessageGuid {
    if(chat == nil) return nil;
    
    NSArray *items = [chat chatItems];
    
    for(id item in items) {
        // If the class is an attachment
        if([NSStringFromClass([item class]) isEqualToString: @"IMAttachmentMessagePartChatItem"]) {
            if([[[item message] guid] isEqualToString:(actionMessageGuid)]) {
                
                DLog(@"BLUEBUBBLESHELPER: %@", [[item message] guid]);

                return @[item, @"3"];
            }
        // If the class is a text message
        } else if([NSStringFromClass([item class]) isEqualToString: @"IMTextMessagePartChatItem"]) {
            if([[[item message] guid] isEqualToString:(actionMessageGuid)]) {
                
                DLog(@"BLUEBUBBLESHELPER: %@", [[item message] guid]);

                return @[item, @"1"];
            }
        // If the class is handwritten or link
        } else if([NSStringFromClass([item class]) isEqualToString: @"IMTranscriptPluginChatItem"]) {
            if([[[item message] guid] isEqualToString:(actionMessageGuid)]) {
                
                DLog(@"BLUEBUBBLESHELPER: %@", [[item message] guid]);

                return @[item, @"3"];
            }
        // If its an audio message
        } else if([NSStringFromClass([item class]) isEqualToString: @"IMAudioMessageChatItem"]) {
            if([[[item message] guid] isEqualToString:(actionMessageGuid)]) {
                
                DLog(@"BLUEBUBBLESHELPER: %@", [[item message] guid]);

                return @[item, @"2"];
            }
        }
    }
    
    return nil;
}

+(BOOL) isTyping: (NSString *)guid {
    IMChat *chat = [BlueBubblesHelper getChat:guid];
    return chat.lastIncomingMessage.isTypingMessage;
}

+(void) updateTypingStatus: (NSString *) guid {
    IMChat *chat = [BlueBubblesHelper getChat:guid];
    // Send out the correct response over the tcp socket
    if(chat.lastIncomingMessage.isTypingMessage == YES) {
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
        DLog(@"BLUEBUBBLESHELPER: %@ started typing", guid);
    } else {
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
        DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
    }
}

+(void) updateMessage:(NSString *)chatGuid :(NSString *)tempGuid :(NSString *)newGuid {
    [[NetworkController sharedInstance] sendMessage: @{@"event": @"message-match", @"chatGuid": chatGuid, @"tempGuid": tempGuid, @"newGuid": newGuid}];
    
    DLog(@"BLUEBUBBLESHELPER: %@ updated message guid", newGuid);
}

@end


// Credit to w0lf
// Handles all of the incoming typing events
ZKSwizzleInterface(BBH_IMMessageItem, IMMessageItem, NSObject)
@implementation BBH_IMMessageItem

- (BOOL)isCancelTypingMessage {
    // isCancelTypingMessage seems to also have some timing issues and adding a delay would fix this
    // But I would rather not rely on delays to have this program work properly
    //
    // We would rather that the typing message be cancelled prematurely rather
    // than having the typing indicator stuck permanently
    NSString *guid = [self getGuid];
    
    if(guid != nil) {

        if([self isLatestMessage]) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
            DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
        }
    }
    return ZKOrig(BOOL);
}

- (BOOL)isIncomingTypingMessage {
    // We do this because the isIncomingTypingMessage seems to have some timing
    // issues and will sometimes notify after the isCancelTypingMessage so we need to confirm
    // that the sender actually is typing
    [self updateTypingState];
    
    // This is here to ensure that no infinite typing occurs
    // If for whatever reason the isCancelTypingMessage does not occur,
    // this should catch the error in 2 seconds
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(self != nil) {
            NSString *guid = [self getGuid];
            if(guid != nil) {
                if([BlueBubblesHelper isTyping:guid] == NO) {
                    [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
                    DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
                }
            }
        }
            
    });
    
    return ZKOrig(BOOL);
}

// Check to see if this IMMessageItem matches the last IMChat's message
// This helps to avoid spamming of the tcp socket
- (BOOL) isLatestMessage {
    NSString *guid = [self getGuid];
    // Fetch the current IMChat to get the IMMessage
    IMChat *chat = [BlueBubblesHelper getChat:guid];
    IMMessageItem *item = (IMMessageItem*) self;
    IMMessage *message = item.message;
    if(message.isFromMe) return NO;
    
    // If the IMChat's last message matches our own IMMessage, then we can proceed
    // this should avoid spamming of the tcp socket
    return chat.lastIncomingMessage.guid == message.guid;
}

// Update the typing state by checking the message state
- (void) updateTypingState {
    if(![self isLatestMessage]) return;
    
    NSString *guid = [self getGuid];
    
    // If we failed to get the guid for whatever reason, then we can't do anything
    if(guid != nil) {
        [BlueBubblesHelper updateTypingStatus:guid];
    }
}

- (NSString *) getGuid {
    IMMessageItem *item = (IMMessageItem*)self;
    if(item == nil) return nil;
    IMMessage *message = item.message;
    if(message == nil) return nil;
    
    
    // Get the guid of the message???
    IMHandle *handle = message.sender;
    if(handle == nil) return nil;
    IMChat *chat = [[IMChatRegistry sharedInstance] existingChatForIMHandle: handle];
    if(chat == nil) return nil;
    
    
    
    return chat.guid;
}

@end

//ZKSwizzleInterface(WBWT_IMChat, IMChat, NSObject)
//@implementation WBWT_IMChat
//- (void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 {
//    DLog(@"BLUEBUBBLESHELPER:arg1 %llu", arg1);
//    DLog(@"BLUEBUBBLESHELPER:arg2 %@", arg2);
//    DLog(@"BLUEBUBBLESHELPER:arg3 %@", arg3);
//}
//
//@end
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withAssociatedMessageInfo:(id)arg3 withGuid:(id)arg4 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 1");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withAssociatedMessageInfo:(id)arg3 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 2");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 withGuid:(id)arg4 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 3");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 4");
//    DLog(@"BLUEBUBBLESHELPER: %lld", arg1);
//    DLog(@"BLUEBUBBLESHELPER: %@", arg2);
//    DLog(@"BLUEBUBBLESHELPER: %@", arg3);
//
//
//    return;
//}
//
//@end

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


