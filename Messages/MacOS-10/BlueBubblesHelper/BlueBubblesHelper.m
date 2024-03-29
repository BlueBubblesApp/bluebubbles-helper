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
#import "IMFileTransfer.h"
#import "IMFileTransferCenter.h"
#import "IMDPersistentAttachmentController.h"
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
#import "SocialAppsCore/SOAccountRegistrationController.h"
#import "SocialAppsCore/SOAccountAliasController.h"
#import "SocialAppsCore/SOAccountAlias.h"
#import "ZKSwizzle.h"
#import "IDSIDQueryController.h"
#import "IDS.h"
#import "IDSDestination-Additions.h"
#import "IMDDController.h"

@interface BlueBubblesHelper : NSObject
+ (instancetype)sharedInstance;
@end

// This can be used to dump the methods of any class
@interface NSObject (Private)
- (NSString*)_methodDescription;
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
    // [self handleMessage:controller message:@"{\"action\":\"send-message\",\"transactionId\":\"bruh\",\"data\":{\"chatGuid\":\"iMessage;+;chat748046387255158516\",\"ddScan\":0,\"message\":\"https://google.com\"}}"];
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

        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            //Map the reaction type
            long long reactionLong = [BlueBubblesHelper parseReactionType:(data[@"reactionType"])];

            // Get the messageItem
            [BlueBubblesHelper getMessageItem:(chat) :(data[@"selectedMessageGuid"]) completionBlock:^(IMMessage *message) {
                IMMessageItem *imMessage = (IMMessageItem *)message._imMessageItem;
                NSObject *items = imMessage._newChatItems;
                IMMessagePartChatItem *item;
                // sometimes items is an array so we need to account for that
                if ([items isKindOfClass:[NSArray class]]) {
                    for (IMMessagePartChatItem *i in (NSArray *) items) {
                        if ([i index] == [data[@"partIndex"] integerValue]) {
                            item = i;
                            break;
                        }
                    }
                } else {
                    item = (IMMessagePartChatItem *)items;
                }
                NSDictionary *messageSummary;
                if (item != nil) {
                    NSAttributedString *text = [item text];
                    if (text == nil) {
                        text = [message text];
                    }
                    messageSummary = @{@"amc":@1,@"ams":text.string};
                    // Send the tapback
                    // check if the body happens to be an object (ie an attachment) and send the tapback accordingly to show the proper summary
                    NSData *dataenc = [text.string dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                    NSString *encodevalue = [[NSString alloc]initWithData:dataenc encoding:NSUTF8StringEncoding];
                    if ([encodevalue isEqualToString:@"\\ufffc"]) {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(@{})];
                    } else {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(messageSummary)];
                    }
                } else {
                    messageSummary = @{@"amc":@1,@"ams":message.text.string};
                    // Send the tapback
                    // check if the body happens to be an object (ie an attachment) and send the tapback accordingly to show the proper summary
                    NSData *dataenc = [[message text].string dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                    NSString *encodevalue = [[NSString alloc]initWithData:dataenc encoding:NSUTF8StringEncoding];
                    if ([encodevalue isEqualToString:@"\\ufffc"]) {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(@{})];
                    } else {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(messageSummary)];
                    }
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
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, start typing
            [chat setLocalUserIsTyping:YES];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }

    // If the server tells us to stop typing
    } else if([event isEqualToString:@"stop-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, stop typing
            [chat setLocalUserIsTyping:NO];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }

    // If the server tells us to mark a chat as read
    } else if([event isEqualToString:@"mark-chat-read"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, mark everything as read
            [chat markAllMessagesAsRead];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    } else if([event isEqualToString:@"check-typing-status"]) {
        if(data[@"chatGuid"] != [NSNull null]) {
            [BlueBubblesHelper updateTypingStatus:data[@"chatGuid"]];
        }
    // If server tells us to change the display name
    } else if ([event isEqualToString:@"set-display-name"]) {
        if (data[@"newName"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide a new name for the chat!"}];
            }
            return;
        }

        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // Set the display name
            [chat _setDisplayName:(data[@"newName"])];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
        DLog(@"BLUEBUBBLESHELPER: Setting display name of chat %@ to %@", data[@"chatGuid"], data[@"newName"]);
    // If the server tells us to add a participant
    } else if ([event isEqualToString:@"add-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (data[@"address"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide an address to add!"}];
            }
            return;
        }
        IMHandle *handle = [[[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)] imHandleWithID:(data[@"address"])];

        if (handle != nil && chat != nil && [chat canAddParticipant:(handle)]) {
            [chat inviteParticipantsToiMessageChat:(@[handle]) reason:(0)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            DLog(@"BLUEBUBBLESHELPER: Added participant to chat %@: %@", data[@"chatGuid"], data[@"address"]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to add address to chat!"}];
            }
            DLog(@"BLUEBUBBLESHELPER: Couldn't add participant to chat %@: %@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to remove a participant
    } else if ([event isEqualToString:@"remove-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (data[@"address"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide an address to add!"}];
            }
            return;
        }
        IMHandle *handle = [[[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)] imHandleWithID:(data[@"address"])];

        if (handle != nil && chat != nil && [chat canAddParticipant:(handle)]) {
            [chat removeParticipantsFromiMessageChat:(@[handle]) reason:(0)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            DLog(@"BLUEBUBBLESHELPER: Removed participant from chat %@: %@", data[@"chatGuid"], data[@"address"]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to remove address from chat!"}];
            }
            DLog(@"BLUEBUBBLESHELPER: Couldn't remove participant from chat %@: %@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to send a message
    } else if ([event isEqualToString:@"send-message"]) {
        [BlueBubblesHelper sendMessage:(data) transfers:nil attributedString:nil transaction:(transaction)];
    // If the server tells us to create a chat
    // currently unused method
    } else if ([event isEqualToString:@"create-chat"]) {
        NSMutableArray<IMHandle*> *handles = [[NSMutableArray alloc] initWithArray:(@[])];
        BOOL failed = false;
        for (NSString* str in data[@"addresses"]) {
            IMHandle *handle;
            if ([data[@"service"] isEqualToString:@"iMessage"]) {
                handle = [[[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)] imHandleWithID:(str)];
            } else {
                handle = [[[IMAccountController sharedInstance] bestAccountForService:(IMService.smsService)] imHandleWithID:(str)];
            }

            if (handle != nil) {
                [handles addObject:handle];
            } else {
                failed = true;
                break;
            }
        }

        if (failed) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to find all handles for specified service!"}];
            return;
        }
        
        IMChat *chat;
        if (handles.count > 1) {
            chat = [[IMChatRegistry sharedInstance] chatForIMHandles:(handles)];
        } else {
            chat = [[IMChatRegistry sharedInstance] chatForIMHandle:(handles[0])];
        }
        NSMutableDictionary *mutableData = [[NSMutableDictionary alloc] initWithDictionary:data];
        [mutableData setValue:[chat guid] forKey:@"chatGuid"];
        [BlueBubblesHelper sendMessage:(mutableData) transfers:nil attributedString:nil transaction:(transaction)];
    // If server tells us to delete a chat
    } else if ([event isEqualToString:@"delete-chat"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (chat != nil) {
            [[IMChatRegistry sharedInstance] _chat_remove:(chat)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
        // If server tells us to delete a message
    } else if ([event isEqualToString:@"delete-message"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (chat != nil) {
            [BlueBubblesHelper getMessageItem:(chat) :(data[@"messageGuid"]) completionBlock:^(IMMessage *message) {
                IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
                NSObject *items = messageItem._newChatItems;
                // sometimes items is an array so we need to account for that
                if ([items isKindOfClass:[NSArray class]]) {
                    [chat deleteChatItems:(items)];
                } else {
                    [chat deleteChatItems:(@[items])];
                }
            }];
            
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    // If the server tells us to send an attachment
    } else if ([event isEqualToString:@"send-attachment"]) {
        NSString *filePath = data[@"filePath"];
        NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
        IMFileTransfer* fileTransfer = [BlueBubblesHelper prepareFileTransferForAttachment:fileUrl filename:[fileUrl lastPathComponent]];
        NSMutableAttributedString *attachmentStr = [[NSMutableAttributedString alloc] initWithString: @"\ufffc"];
        [attachmentStr addAttributes:@{
            @"__kIMBaseWritingDirectionAttributeName": @"-1",
            @"__kIMFileTransferGUIDAttributeName": fileTransfer.guid,
            @"__kIMFilenameAttributeName": [fileUrl lastPathComponent],
            @"__kIMMessagePartAttributeName": @0,
        } range:NSMakeRange(0, 1)];
        [BlueBubblesHelper sendMessage:(data) transfers:@[[fileTransfer guid]] attributedString:attachmentStr transaction:(transaction)];
    // If the server tells us to send a single attachment
    } else if ([event isEqualToString:@"send-multipart"]) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: @""];
        NSMutableArray<NSString*> *transfers = [[NSMutableArray alloc] init];
        NSUInteger index = 0;
        for (NSDictionary *dict in data[@"parts"]) {
            if (dict[@"filePath"] != [NSNull null] && [dict[@"filePath"] length] != 0) {
                NSString *filePath = dict[@"filePath"];
                NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
                IMFileTransfer* fileTransfer = [BlueBubblesHelper prepareFileTransferForAttachment:fileUrl filename:[fileUrl lastPathComponent]];
                [transfers addObject:[fileTransfer guid]];
                NSMutableAttributedString *attachmentStr = [[NSMutableAttributedString alloc] initWithString: @"\ufffc"];
                [attachmentStr addAttributes:@{
                    @"__kIMBaseWritingDirectionAttributeName": @"-1",
                    @"__kIMFileTransferGUIDAttributeName": fileTransfer.guid,
                    @"__kIMFilenameAttributeName": [fileUrl lastPathComponent],
                    @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                } range:NSMakeRange(0, 1)];
                [attributedString appendAttributedString:attachmentStr];
            } else {
                if (dict[@"mention"] != [NSNull null] && [dict[@"mention"] length] != 0) {
                    NSMutableAttributedString *beforeStr = [[NSMutableAttributedString alloc] initWithString: [(NSString *) dict[@"text"] substringWithRange:NSMakeRange(0, [[dict[@"range"] firstObject] integerValue])]];
                    [beforeStr addAttributes:@{
                        @"__kIMBaseWritingDirectionAttributeName": @"-1",
                        @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                    } range:NSMakeRange(0, [[beforeStr string] length])];
                    NSMutableAttributedString *mentionStr = [[NSMutableAttributedString alloc] initWithString: [(NSString *) dict[@"text"] substringWithRange:NSMakeRange([[dict[@"range"] firstObject] integerValue], [[dict[@"range"] lastObject] integerValue])]];
                    [mentionStr addAttributes:@{
                        @"__kIMBaseWritingDirectionAttributeName": @"-1",
                        @"__kIMMentionConfirmedMention": dict[@"mention"],
                        @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                    } range:NSMakeRange(0, [[mentionStr string] length])];
                    NSUInteger begin = [[dict[@"range"] firstObject] integerValue] + [[dict[@"range"] lastObject] integerValue];
                    NSUInteger end = [dict[@"text"] length] - begin;
                    NSMutableAttributedString *afterStr = [[NSMutableAttributedString alloc] initWithString: [(NSString *) dict[@"text"] substringWithRange:NSMakeRange(begin, end)]];
                    [afterStr addAttributes:@{
                        @"__kIMBaseWritingDirectionAttributeName": @"-1",
                        @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                    } range:NSMakeRange(0, [[afterStr string] length])];
                    if ([[beforeStr string] length] != 0) {
                        [attributedString appendAttributedString:beforeStr];
                    }
                    if ([[mentionStr string] length] != 0) {
                        [attributedString appendAttributedString:mentionStr];
                    }
                    if ([[afterStr string] length] != 0) {
                        [attributedString appendAttributedString:afterStr];
                    }
                } else {
                    NSMutableAttributedString *messageStr = [[NSMutableAttributedString alloc] initWithString: dict[@"text"]];
                    [messageStr addAttributes:@{
                        @"__kIMBaseWritingDirectionAttributeName": @"-1",
                        @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                    } range:NSMakeRange(0, [[messageStr string] length])];
                    [attributedString appendAttributedString:messageStr];
                }
            }
            index++;
        }
        [BlueBubblesHelper sendMessage:(data) transfers:[transfers copy] attributedString:attributedString transaction:(transaction)];
    // If server tells us to leave a chat
    } else if ([event isEqualToString:@"leave-chat"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (chat != nil && [chat canLeaveChat]) {
            [chat leaveiMessageGroup];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    // If the server tells us to check iMessage availability
    } else if ([event isEqualToString:@"check-imessage-availability"] || [event isEqualToString:@"check-facetime-availability"]) {
        NSString *type = data[@"aliasType"];
        IDSDestination *dest;
        NSString* serviceName;
        
        if ([event isEqualToString:@"check-imessage-availability"]) {
            serviceName = IDSServiceNameiMessage;
        } else {
            serviceName = IDSServiceNameFaceTime;
        }
        
        if ([type isEqualToString:@"phone"]) {
            dest = IDSCopyIDForPhoneNumber((__bridge CFStringRef)data[@"address"]);
        } else {
            dest = IDSCopyIDForEmailAddress((__bridge CFStringRef)data[@"address"]);
        }
        
        [[IDSIDQueryController sharedInstance] refreshIDStatusForDestinations:(@[dest]) service:(serviceName) listenerID:(@"SOIDSListener-com.apple.imessage-rest") queue:(dispatch_queue_create("HandleIDS", NULL)) completionBlock:^(NSDictionary *response) {
            NSInteger *status = [response.allValues.firstObject integerValue];
            BOOL available = status == 1;
            DLog(@"BLUEBUBBLESHELPER: Status for %@ is %ld", data[@"address"], (long)available);
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"available": [NSNumber numberWithBool:(available)]}];
            }
        }];
    // If the server tells us to get the current account info
    } else if ([event isEqualToString:@"get-account-info"]) {
        IMAccount *account = [[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)];
        IMAccount *smsAccount = [[IMAccountController sharedInstance] bestAccountForService:(IMService.smsService)];

        if (transaction != nil) {
            NSDictionary *data = @{
                @"transactionId": transaction,
                @"apple_id": [account strippedLogin] ?: [NSNull null],
                @"account_name": [[account loginIMHandle] fullName] ?: [NSNull null],
                @"sms_forwarding_enabled": [NSNumber numberWithBool:[smsAccount allowsSMSRelay] ?: FALSE],
                @"sms_forwarding_capable": [NSNumber numberWithBool:[smsAccount isSMSRelayCapable] ?: FALSE],
                @"vetted_aliases": [BlueBubblesHelper getAliases:true],
                @"aliases": [BlueBubblesHelper getAliases:false],
                @"login_status_message": [account loginStatusMessage] ?: [NSNull null],
            };
            [[NetworkController sharedInstance] sendMessage: data];
        }
    // If the server tells us to modify the active alias used to start chats
    } else if ([event isEqualToString:@"modify-active-alias"]) {
        NSString* alias = data[@"alias"];

        if ([BlueBubblesHelper isAccountEnabled]) {
            IMAccount *account = [[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)];
            [account setDisplayName:alias];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        } else {
            DLog(@"BLUEBUBBLESHELPER: Can't modify aliases, account not enabled");
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to modify alias"}];
            }
        }
    // If the event is something that hasn't been implemented, we simply ignore it and put this log
    } else {
        DLog(@"BLUEBUBBLESHELPER: Not implemented %@", event);
    }

}

// Retreive a IMChat instance from a given guid
//
// Uses the chat registry to get an existing instance of a chat based on the chat guid
+(IMChat *) getChat: (NSString *) guid :(NSString *) transaction {
    if(guid == nil) {
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide a chat GUID!"}];
        }
        return nil;
    }

    IMChat* imChat = [[IMChatRegistry sharedInstance] existingChatWithGUID: guid];

    if (imChat == nil && transaction != nil) {
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Chat does not exist!"}];
    }
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

+(BOOL) isTyping: (NSString *)guid {
    IMChat *chat = [BlueBubblesHelper getChat:guid :nil];
    return chat.lastIncomingMessage.isTypingMessage;
}

+(void) updateTypingStatus: (NSString *) guid {
    IMChat *chat = [BlueBubblesHelper getChat:guid :nil];
    // Send out the correct response over the tcp socket
    if(chat.lastIncomingMessage.isTypingMessage == YES) {
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
        DLog(@"BLUEBUBBLESHELPER: %@ started typing", guid);
    } else {
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
        DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
    }
}

/**
 Creates a new file transfer & moves file to attachment location
 @param originalPath The url of the file to be transferred ( Must be in a location IMessage.app has permission to access )
 @param filename The filename of the transfer to show in IMessage.app
 @return The IMFileTransfer registered with IMessage.app or nil if unable to properly create file transfer
 @warning The `originalPath` must be a URL that IMessage.app can access even with Full Disk Access some locations are off limits. One location that is safe is always safe is `~/Library/Messages`
 */
+(IMFileTransfer *) prepareFileTransferForAttachment:(NSURL *) originalPath filename:(NSString *) filename {
    // Creates the initial guid for the file transfer (cannot use for sending)
    NSString *transferInitGuid = [[IMFileTransferCenter sharedInstance] guidForNewOutgoingTransferWithLocalURL:originalPath];
    DLog(@"BLUEBUBBLESHELPER: Transfer GUID: %@", transferInitGuid);

    // Creates the initial transfer object
    IMFileTransfer *newTransfer = [[IMFileTransferCenter sharedInstance] transferForGUID:transferInitGuid];
    // Get location of where attachments should be placed
    NSString *persistentPath;
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion > 12) {
        persistentPath = [[IMDPersistentAttachmentController sharedInstance] _persistentPathForTransfer:newTransfer filename:filename highQuality:TRUE];
    } else {
        // Use a different method on macOS Sierra (10.12)
        persistentPath = [[IMDPersistentAttachmentController sharedInstance] _persistentPathForTransfer:newTransfer];
    }
    DLog(@"BLUEBUBBLESHELPER: Requested persistent path: %@", persistentPath);

    if (persistentPath) {
        NSError *folder_creation_error;
        NSError *file_move_error;
        NSURL *persistentURL = [NSURL fileURLWithPath:persistentPath];

        // Create the attachment location
        [[NSFileManager defaultManager] createDirectoryAtURL:[persistentURL URLByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:&folder_creation_error];
        // Handle error and exit
        if (folder_creation_error) {
            DLog(@"BLUEBUBBLESHELPER:  Failed to create folder: %@", folder_creation_error);
            return nil;
        }

        // Copy the file to the attachment location
        [[NSFileManager defaultManager] copyItemAtURL:originalPath toURL:persistentURL error:&file_move_error];
        // Handle error and exit
        if (file_move_error) {
            DLog(@"BLUEBUBBLESHELPER:  Failed to move file: %@", file_move_error);
            return nil;
        }

        // We updated the transfer location
        [[IMFileTransferCenter sharedInstance] retargetTransfer:[newTransfer guid] toPath:persistentPath];
        // Update the local url inside of the transfer
        newTransfer.localURL = persistentURL;
    }

    // Register the transfer (The file must be in correct location before this)
    // *Warning* Can fail but gives only warning in console that failed
    [[IMFileTransferCenter sharedInstance] registerTransferWithDaemon:[newTransfer guid]];
    DLog(@"BLUEBUBBLESHELPER: Transfer registered successfully!");
    return newTransfer;
}

/**
 Get the account enabled state
 @return True if the account enabled state is 4 or false if else or not signed in
 */
+(BOOL) isAccountEnabled {
    IMAccount *account = [[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)];
    return [account isActive] && [account isRegistered] && [account isOperational] && [account isConnected];
}

/**
  Gets the active alias associated with the signed account
  @return The active alias's names if not logged in returns a empty list
  */
+(NSMutableArray *) getAliases:(BOOL)vetted {
    if ([self isAccountEnabled]) {
        IMAccount *account = [[IMAccountController sharedInstance] bestAccountForService:(IMService.iMessageService)];
        NSArray* aliases = @[];
        if (vetted) {
            aliases = [account vettedAliases];
        } else {
            aliases = [account aliases];
        }
        DLog(@"BLUEBUBBLESHELPER: Vetted Aliases %@", aliases);

        NSMutableArray* returnedAliases = [[NSMutableArray alloc] init];
        for (NSObject* alias in aliases) {
            NSDictionary* info = [account _aliasInfoForAlias:(alias)];
            if (info == nil) {
                [returnedAliases addObject: @{@"Alias": alias}];
            } else {
                [returnedAliases addObject: info];
            }
        }

        return returnedAliases;
    } else {
        DLog(@"BLUEBUBBLESHELPER: Can't get aliases - account not enabled");
        return [[NSMutableArray alloc] initWithArray:@[]];
    }
    return [[NSMutableArray alloc] initWithArray:@[]];
}

+(void) sendMessage: (NSDictionary *) data transfers: (NSArray *) transfers attributedString:(NSMutableAttributedString *) attributedString transaction:(NSString *) transaction {
    IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
    if (chat == nil) {
        DLog(@"BLUEBUBBLESHELPER: chat is null, aborting");
        return;
    }
    
    // If we didn't get a multipart message, create a simple attributed string
    if (attributedString == nil) {
        NSString *message = data[@"message"];
        // Tapbacks will not have message text, but messages sent must have some sort of text
        if (message == nil) {
            message = @"TEMP";
        }
        attributedString = [[NSMutableAttributedString alloc] initWithString: message];
    }

    NSMutableAttributedString *subjectAttributedString = nil;
    if (data[@"subject"] != [NSNull null] && [data[@"subject"] length] != 0) {
        subjectAttributedString = [[NSMutableAttributedString alloc] initWithString: data[@"subject"]];
    }
    NSString *effectId = nil;
    if (data[@"effectId"] != [NSNull null] && [data[@"effectId"] length] != 0) {
        effectId = data[@"effectId"];
    }
    
    BOOL isAudioMessage = false;
    if (data[@"isAudioMessage"] != [NSNull null]) {
        isAudioMessage = [data[@"isAudioMessage"] integerValue] == 1;
    }
    
    BOOL ddScan = false;
    if (data[@"ddScan"] != [NSNull null]) {
        ddScan = [data[@"ddScan"] integerValue] == 1;
    }

    void (^createMessage)(NSAttributedString*, NSAttributedString*, NSString*, NSString*, NSArray*, BOOL, BOOL) = ^(NSAttributedString *message, NSAttributedString *subject, NSString *effectId, NSString *threadIdentifier, NSArray *transferGUIDs, BOOL isAudioMessage, BOOL ddScan) {
        IMMessage *messageToSend = [[IMMessage alloc] init];
        messageToSend = [messageToSend initWithSender:(nil) time:(nil) text:(message) messageSubject:(subject) fileTransferGUIDs:(transferGUIDs) flags:(isAudioMessage ? 0x300005 : (subject ? 0x10000d : 0x100005)) error:(nil) guid:(nil) subject:(nil) balloonBundleID:(nil) payloadData:(nil) expressiveSendStyleID:(effectId)];
        [chat sendMessage:(messageToSend)];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastFinishedMessage] guid]}];
        }
    };

    createMessage(attributedString, subjectAttributedString, effectId, nil, transfers, isAudioMessage, ddScan);
}

@end

ZKSwizzleInterface(BBH_IMAccount, IMAccount, NSObject)
@implementation BBH_IMAccount

- (void)_registrationStatusChanged:(id)arg1 {
    NSNotification *notif = arg1;
    IMAccount* acct = [notif object];
    NSDictionary *info = [notif userInfo];
    if ([[acct serviceName] isEqualToString:@"iMessage"] && [info objectForKey:@"__kIMAccountAliasesRemovedKey"]) {
        DLog(@"BLUEBUBBLESHELPER: alias updated %@", notif);
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"aliases-removed", @"data": info}];
    }
    return ZKOrig(void, arg1);
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
    IMChat *chat = [BlueBubblesHelper getChat:guid :nil];
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


