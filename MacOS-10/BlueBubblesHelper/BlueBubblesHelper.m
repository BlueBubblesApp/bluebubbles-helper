//
//  whosTyping.m
//  whosTyping
//
//  Created by Wolfgang Baird on 1/21/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import <Foundation/Foundation.h>

#import "IMTextMessagePartChatItem.h"
#import "IMHandle.h"
#import "IMPerson.h"
#import "IMAccount.h"
#import "IMAccountController.h"
#import "IMService-IMService_GetService.h"
#import "IMChat.h"
#import "IMMessage.h"
#import "IMMessageChatItem.h"
#import "IMMessageItem-IMChat_Internal.h"
#import "IMChatRegistry.h"
#import "NetworkController.h"
#import "Logging.h"
#import "ChatDisplayController.h"
#import "SelectorHelper.h"
#import "IMHandleRegistrar.h"
#import "IMChatHistoryController.h"
#import "IMChatItem.h"

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

// Helper method to log a long string
-(void) logString:(NSString*)logString{

        int stepLog = 800;
        NSInteger strLen = [@([logString length]) integerValue];
        NSInteger countInt = strLen / stepLog;

        if (strLen > stepLog) {
        for (int i=1; i <= countInt; i++) {
            NSString *character = [logString substringWithRange:NSMakeRange((i*stepLog)-stepLog, stepLog)];
            NSLog(@"BLUEBUBBLESHELPER: %@", character);

        }
        NSString *character = [logString substringWithRange:NSMakeRange((countInt*stepLog), strLen-(countInt*stepLog))];
        NSLog(@"BLUEBUBBLESHELPER: %@", character);
        } else {

        NSLog(@"BLUEBUBBLESHELPER: %@", logString);
        }

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

    // Upon receiving a message
    controller.messageReceivedBlock =  ^(NetworkController *controller, NSString *data) {
        [self handleMessage:controller message: data];
    };
    NSDictionary *message = @{@"event": @"ping", @"message": @"Helper Connected!"};
    [controller sendMessage:message];
    
    // DEVELOPMENT ONLY, COMMENT OUT FOR RELEASE
    // Quickly test a message event
    //     [self handleMessage:controller message:@"{\"action\":\"send-message\",\"data\":{\"chatGuid\":\"iMessage;-;elliotnash@gmail.com\",\"subject\":\"\",\"message\":\"Elliot\",\"attributedBody\":{\"runs\":[{\"attributes\":{\"__kIMMessagePartAttributeName\":0,\"__kIMMentionConfirmedMention\":\"elliotnash@gmail.com\"},\"range\":[0,6]}],\"string\":\"Elliot\"},\"effectsId\":\"com.apple.MobileSMS.expressivesend.impact\",\"selectedMessageGuid\":null}}"];
}

// Run when receiving a new message from the tcp socket
-(void) handleMessage: (NetworkController*)controller  message:(NSString *)message {
    // The data is in the form of a json string, so we need to convert it to a NSDictionary
    // for some reason the data is sometimes duplicated, so account for that
    NSRange range = [message rangeOfString:@"}\n{"];
    if(range.location != NSNotFound){
     message = [message substringWithRange:NSMakeRange(0, range.location + 1)];
    }
    DLog(@"BLUEBUBBLESHELPER: Received raw json: %@", message);
    NSError *error;
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    // Event is the type of packet that was sent
    NSString *event = dictionary[@"action"];
    // Data is the actual information that we need in the packet
    NSDictionary *data = dictionary[@"data"];
    // Transaction ID enables us to communicate back to the server that the action was complete
    NSString *transaction = nil;
    if ([dictionary objectForKey:(@"transactionId")] != [NSNull null]) {
        transaction = dictionary[@"transactionId"];
    }

    DLog(@"BLUEBUBBLESHELPER: Message received: %@, %@", event, data);

    if([event isEqualToString:@"send-reaction"]) {
        DLog(@"BLUEBUBBLESHELPER: REACTION INCOMING %@", data.description);

        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        if(chat != nil) {
            //Map the reaction type
            long long reactionLong = [BlueBubblesHelper parseReactionType:(data[@"reactionType"])];

            // Get the messageItem
            [BlueBubblesHelper getMessageItem:(chat) :(data[@"selectedMessageGuid"]) completionBlock:^(IMMessage *message) {
                IMMessageItem *imMessage = (IMMessageItem *)message._imMessageItem;
                NSObject *items = imMessage._newChatItems;
                IMChatItem *item;
                // sometimes items is an array so we need to account for that
                if ([items isKindOfClass:[NSArray class]]) {
                    for(IMChatItem* imci in (NSArray *)items) {
                        if([[[imci _item] guid] isEqualToString:(data[@"selectedMessageGuid"])]) {
                            DLog(@"BLUEBUBBLESHELPER: %@", data[@"selectedMessageGuid"]);
                            item = imci;
                        }
                    }
                } else {
                    item = (IMChatItem *)items;
                }
                DLog(@"BLUEBUBBLESHELPER: %@", [imMessage message]);
                //Build the message summary
                NSDictionary *messageSummary = @{@"amc":@1,@"ams":[[imMessage message] plainBody]};

                DLog(@"BLUEBUBBLESHELPER: Reaction Long: %lld", reactionLong);
                // Send the tapback
                // check if the body happens to be an object (ie an attachment) and send the tapback accordingly to show the proper summary
                NSData *dataenc = [[[imMessage message] plainBody] dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                NSString *encodevalue = [[NSString alloc]initWithData:dataenc encoding:NSUTF8StringEncoding];
                if ([encodevalue isEqualToString:@"\\ufffc"]) {
                    [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(@{})];
                } else {
                    [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(messageSummary)];
                }
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastMessage] guid]}];
                }
                DLog(@"BLUEBUBBLESHELPER: sent reaction");
            }];
        }
    }
    // If the server tells us to start typing
     if([event isEqualToString: @"start-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        if(chat != nil) {
            // If the IMChat instance is not null, start typing
            [chat setLocalUserIsTyping:YES];
        }

    // If the server tells us to stop typing
    } else if([event isEqualToString:@"stop-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        if(chat != nil) {
            // If the IMChat instance is not null, stop typing
            [chat setLocalUserIsTyping:NO];
        }

    // If the server tells us to mark a chat as read
    } else if([event isEqualToString:@"mark-chat-read"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        if(chat != nil) {
            // If the IMChat instance is not null, mark everything as read
            [chat markAllMessagesAsRead];
        }
    } else if([event isEqualToString:@"check-typing-status"]) {
        if(data[@"chatGuid"] != [NSNull null]) {
            [BlueBubblesHelper getTypingStatus:data[@"chatGuid"] transaction:(transaction)];
        }
    // If server tells us to change the display name
    } else if ([event isEqualToString:@"set-display-name"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        if(chat != nil) {
            // Set the display name
            [chat _setDisplayName:(data[@"newName"])];
        }
        DLog(@"BLUEBUBBLESHELPER: Setting display name of chat %@ to %@", data[@"chatGuid"], data[@"newName"]);
    // If the server tells us to add a participant
    } else if ([event isEqualToString:@"add-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        NSArray<IMHandle*> *handles = [[IMHandleRegistrar sharedInstance] getIMHandlesForID:(data[@"address"])];

        if (handles != nil) {
            IMAccountController *sharedAccountController = [IMAccountController sharedInstance];
            IMAccount *myAccount = [sharedAccountController mostLoggedInAccount];
            IMHandle *handle = [[IMHandle alloc] initWithAccount:(myAccount) ID:(data[@"address"]) alreadyCanonical:(YES)];
            handles = @[handle];
        }

        if(chat != nil && [chat canAddParticipants:(handles)]) {
            [chat inviteParticipantsToiMessageChat:(handles) reason:(0)];
            DLog(@"BLUEBUBBLESHELPER: Added participant to chat %@: %@", data[@"chatGuid"], data[@"address"]);
        } else {
            DLog(@"BLUEBUBBLESHELPER: Couldn't add participant to chat %@: %@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to remove a participant
    } else if ([event isEqualToString:@"remove-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
        NSArray<IMHandle*> *handles = [[IMHandleRegistrar sharedInstance] getIMHandlesForID:(data[@"address"])];
        
        if(chat != nil && [chat canAddParticipants:(handles)]) {
            [chat removeParticipantsFromiMessageChat:(handles) reason:(0)];
            DLog(@"BLUEBUBBLESHELPER: Removed participant from chat %@: %@", data[@"chatGuid"], data[@"address"]);
        } else {
            DLog(@"BLUEBUBBLESHELPER: Couldn't remove participant from chat %@: %@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to send a message
    } else if ([event isEqualToString:@"send-message"]) {
        [BlueBubblesHelper sendMessage:(data) transaction:(transaction)];
    // If the server tells us to create a chat
    } else if ([event isEqualToString:@"create-chat"]) {
        IMAccountController *sharedAccountController = [IMAccountController sharedInstance];
        IMAccount *myAccount = [sharedAccountController mostLoggedInAccount];

        NSMutableArray<IMHandle*> *handles = [[NSMutableArray alloc] initWithArray:(@[])];
        for (NSString* str in data[@"addresses"]) {
            NSArray<IMHandle*> *handlesToAdd = [[IMHandleRegistrar sharedInstance] getIMHandlesForID:(str)];
            if (handlesToAdd == nil) {
                IMHandle *handle = [[IMHandle alloc] initWithAccount:(myAccount) ID:(str) alreadyCanonical:(YES)];
                handlesToAdd = @[handle];
            }
            [handles addObjectsFromArray:(handlesToAdd)];
        }
        IMChat *chat;
        if (handles.count > 1) {
            chat = [[IMChatRegistry sharedInstance] chatForIMHandles:(handles)];
        } else {
            chat = [[IMChatRegistry sharedInstance] chatForIMHandle:(handles[0])];
        }
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": chat.guid}];
        }
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

    DLog(@"BLUEBUBBLESHELPER: %@", lowerCaseType);

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

+(void) getMessageItem:(IMChat *)chat :(NSString *)actionMessageGuid completionBlock:(void (^)(IMMessage *message))block {
    [[IMChatHistoryController sharedInstance] loadMessageWithGUID:(actionMessageGuid) completionBlock:^(IMMessage *message) {
        DLog(@"BLUEBUBBLESHELPER: Got message for guid %@", actionMessageGuid);
        block(message);
    }];
}

+(BOOL) isTyping: (NSString *)guid{
    IMChat *chat = [BlueBubblesHelper getChat:guid];
    return chat.lastIncomingMessage.isTypingMessage;
}

+(void) getTypingStatus: (NSString *) guid transaction:(NSString *) transaction {
    IMChat *chat = [BlueBubblesHelper getChat:guid];
    // Send out the correct response over the tcp socket
    if(chat.lastIncomingMessage.isTypingMessage == YES) {
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"data": @"started-typing", @"guid": guid}];
        }else{
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
        }
        
        DLog(@"BLUEBUBBLESHELPER: %@ started typing", guid);
    } else {
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"data": @"stopped-typing", @"guid": guid}];
        }else{
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
        }
        DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
    }
}

+(void) sendMessage: (NSDictionary *) data transaction:(NSString *) transaction {
    IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"]];
    if (chat == nil) {
        NSLog(@"BLUEBUBBLESHELPER: chat is null, aborting");
        //TODO send socket error
        return;
    }
    
    // TODO make sure this is safe from exceptions
    // now we will deserialize the attributedBody if it exists
    NSDictionary *attributedDict = data[@"attributedBody"];
    // we'll create the NSMutableAttributedString with the associatedBody string if we can,
    // else we'll fall back to using the message text
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: data[@"message"]];
    // if associateBody exists, we iterate through it
    if (attributedDict != NULL && attributedDict != (NSDictionary*)[NSNull null]) {
        attributedString = [[NSMutableAttributedString alloc] initWithString: attributedDict[@"string"]];
        NSArray *attrs = attributedDict[@"runs"];
        for(NSDictionary *dict in attrs)
        {
            // construct range and attributes from dict and add to NSMutableAttributedString
            NSArray *rangeArray = dict[@"range"];
            NSRange range = NSMakeRange([(NSNumber*)[rangeArray objectAtIndex:0] intValue], [(NSNumber*)[rangeArray objectAtIndex:1] intValue]);
            NSDictionary *attrsDict = dict[@"attributes"];
            [attributedString addAttributes:attrsDict range:range];
        }
    }
    
    NSMutableAttributedString *subjectAttributedString = nil;
    if (data[@"subject"] != [NSNull null] && [data[@"subject"] length] != 0) {
        subjectAttributedString = [[NSMutableAttributedString alloc] initWithString: data[@"subject"]];
    }
    NSString *effectId = nil;
    if (data[@"effectId"] != [NSNull null] && [data[@"effectId"] length] != 0) {
        effectId = data[@"effectId"];
    }
    
    void (^createMessage)(NSAttributedString*, NSAttributedString*, NSString*, NSString*) = ^(NSAttributedString *message, NSAttributedString *subject, NSString *effectId, NSString *threadIdentifier) {
        IMMessage *messageToSend = [[IMMessage alloc] init];
        messageToSend = [messageToSend initWithSender:(nil) time:(nil) text:(message) messageSubject:(subject) fileTransferGUIDs:(nil) flags:(100005) error:(nil) guid:(nil) subject:(nil) balloonBundleID:(nil) payloadData:(nil) expressiveSendStyleID:(effectId)];
        [chat sendMessage:(messageToSend)];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastMessage] guid]}];
        }
    };
    
    createMessage(attributedString, subjectAttributedString, effectId, nil);
}

@end


// Credit to mrsylerpowers
// Handles all events
ZKSwizzleInterface(BBH_IMChat, IMChat, NSObject)
@implementation BBH_IMChat

- (BOOL)_handleIncomingItem:(id)arg1 {
    IMMessageItem* imMessageItem = arg1;
    IMMessage *imMessage = [imMessageItem message];
    //Complete the normal functions like writing to database and everything
    BOOL isSystemMessage = [imMessageItem isSystemMessage];
    if(isSystemMessage)
    DLog(@"BLUEBUBBLESHELPER: Recieved System Message ");

    BOOL isIncomingTypingOrCancel = [imMessageItem isIncomingTypingOrCancelTypingMessage];
    BOOL isTypingMessageOrCancel  = [imMessageItem isTypingOrCancelTypingMessage];
    if(isIncomingTypingOrCancel){
        
        BOOL incomingTypingMessage = [imMessageItem isIncomingTypingMessage];
    if(incomingTypingMessage){
        DLog(@"BLUEBUBBLESHELPER: Incoming Typing Message.....");
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": [imMessage guid]}];
    }else{
        DLog(@"BLUEBUBBLESHELPER: Incoming Cancel Typing Message");
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": [imMessage guid]}];
        DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", [imMessage guid]);
    }
        
    }
    if (isTypingMessageOrCancel){
        
            BOOL cancelTypingMessage = [imMessageItem isCancelTypingMessage];
        if(cancelTypingMessage){
            DLog(@"BLUEBUBBLESHELPER: Cancel typing");
            
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": [imMessage guid]}];
            DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", [imMessage guid]);
        }else{
            DLog(@"BLUEBUBBLESHELPER: Typing...");
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": [imMessage guid]}];
        }
    }
    //Complete the normal functions like writing to database and everything
    BOOL hasBeenHandled = ZKOrig(BOOL, arg1);
    if (!(isTypingMessageOrCancel || isIncomingTypingOrCancel)){
    DLog(@"BLUEBUBBLESHELPER: Recieved Message Update From Listener %@" ,[imMessageItem message]);
    [[NetworkController sharedInstance] sendMessage: @{@"event": @"message-update", @"guid": [[imMessageItem message] guid]}];
    }
    return hasBeenHandled;

}

@end

// Credit to w0lf
// Handles all of the incoming typing events
//ZKSwizzleInterface(BBH_IMMessageItem, IMMessageItem, NSObject)
//@implementation BBH_IMMessageItem

//- (BOOL)isCancelTypingMessage {
//    // isCancelTypingMessage seems to also have some timing issues and adding a delay would fix this
//    // But I would rather not rely on delays to have this program work properly
//    //
//    // We would rather that the typing message be cancelled prematurely rather
//    // than having the typing indicator stuck permanently
//    NSString *guid = [self getGuid];
//
//    if(guid != nil) {
//
//        if([self isLatestMessage]) {
//            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
//            DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
//        }
//    }
//    return ZKOrig(BOOL);
//}

//- (BOOL)isIncomingTypingMessage {
//    // We do this because the isIncomingTypingMessage seems to have some timing
//    // issues and will sometimes notify after the isCancelTypingMessage so we need to confirm
//    // that the sender actually is typing
//    [self updateTypingState];
//
//    // This is here to ensure that no infinite typing occurs
//    // If for whatever reason the isCancelTypingMessage does not occur,
//    // this should catch the error in 2 seconds
//    double delayInSeconds = 2.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        if(self != nil) {
//            NSString *guid = [self getGuid];
//            if(guid != nil) {
//                if([BlueBubblesHelper isTyping:guid] == NO) {
//                    [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
//                    DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
//                }
//            }
//        }
//
//    });
//
//    return ZKOrig(BOOL);
//}

// Check to see if this IMMessageItem matches the last IMChat's message
// This helps to avoid spamming of the tcp socket
//- (BOOL) isLatestMessage {
//    NSString *guid = [self getGuid];
//    // Fetch the current IMChat to get the IMMessage
//    IMChat *chat = [BlueBubblesHelper getChat:guid];
//    IMMessageItem *item = (IMMessageItem*) self;
//    IMMessage *message = item.message;
//    if(message.isFromMe) return NO;
//
//    // If the IMChat's last message matches our own IMMessage, then we can proceed
//    // this should avoid spamming of the tcp socket
//    return chat.lastIncomingMessage.guid == message.guid;
//}

// Update the typing state by checking the message state
//- (void) updateTypingState {
//    if(![self isLatestMessage]) return;
//
//    NSString *guid = [self getGuid];
//
//    // If we failed to get the guid for whatever reason, then we can't do anything
//    if(guid != nil) {
//        [BlueBubblesHelper updateTypingStatus:guid transaction: nil];
//    }
//}

//- (NSString *) getGuid {
//    IMMessageItem *item = (IMMessageItem*)self;
//    if(item == nil) return nil;
//    IMMessage *message = item.message;
//    if(message == nil) return nil;
//
//
//    // Get the guid of the message???
//    IMHandle *handle = message.sender;
//    if(handle == nil) return nil;
//    IMChat *chat = [[IMChatRegistry sharedInstance] existingChatForIMHandle: handle];
//    if(chat == nil) return nil;
//
//
//
//    return chat.guid;
//}
//
//@end

//ZKSwizzleInterface(WBWT_IMChat, IMChat, NSObject)
//@implementation WBWT_IMChat
//-(void)_setDisplayName:(id)arg1 {
//    DLog(@"BLUEBUBBLESHELPER: %@", [arg1 className]);
//}
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


