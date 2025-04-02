//
//  whosTyping.m
//  whosTyping
//
//  Created by Wolfgang Baird on 1/21/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import <Foundation/Foundation.h>
#import <CoreSpotlight/CoreSpotlight.h>

#import "IMTextMessagePartChatItem.h"
#import "IMHandle.h"
#import "IMPerson.h"
#import "IMAccount.h"
#import "IMAccountController.h"
#import "IMService.h"
#import "IMChat.h"
#import "IMMessage.h"
#import "IMMessageItem.h"
#import "IMMessageItem-IMChat_Internal.h"
#import "IMChatRegistry.h"
#import "NetworkController.h"
#import "Logging.h"
#import "IMHandleRegistrar.h"
#import "IMCore.h"
#import "IMChatHistoryController.h"
#import "IMPinnedConversationsController.h"
#import "IMDPersistentAttachmentController.h"
#import "IMFileTransfer.h"
#import "IMFileTransferCenter.h"
#import "IMAggregateAttachmentMessagePartChatItem.h"
#import "ZKSwizzle.h"
#import "IMTranscriptPluginChatItem.h"
#import "ETiOSMacBalloonPluginDataSource.h"
#import "HWiOSMacBalloonDataSource.h"
#import "IMHandleAvailabilityManager.h"
#import "IDSIDQueryController.h"
#import "IDS.h"
#import "IDSDestination-Additions.h"
#import "IMDDController.h"
#import "IMNicknameController.h"
#import "IMNickname.h"
#import "IMNicknameAvatarImage.h"
#import "IMFMFSession.h"
#import "FMFSession.h"
#import "FMFLocation.h"
#import "FMLSession.h"
#import "CTBlockDescription.h"
#import "FMLHandle.h"
#import "FMLLocation.h"
#import "FMFSessionDataManager.h"

@interface BlueBubblesHelper : NSObject
+ (instancetype)sharedInstance;
@end

// This can be used to dump the methods of any class
@interface NSObject (Private)
- (NSString*)_methodDescription;
@end

BlueBubblesHelper *plugin;
NSMutableArray* vettedAliases;

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
            DLog("BLUEBUBBLESHELPER: %{public}@", character);

        }
        NSString *character = [logString substringWithRange:NSMakeRange((countInt*stepLog), strLen-(countInt*stepLog))];
            DLog("BLUEBUBBLESHELPER: %{public}@", character);
        } else {

            DLog("BLUEBUBBLESHELPER: %{public}@", logString);
        }

}

// Called when macforge initializes the plugin
+ (void)load {
    // Create the singleton
    plugin = [BlueBubblesHelper sharedInstance];

    // Get OS version for debugging purposes
    NSUInteger major = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
    NSUInteger minor = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    DLog("BLUEBUBBLESHELPER: %{public}@ loaded into %{public}@ on macOS %ld.%ld", [self className], [[NSBundle mainBundle] bundleIdentifier], (long)major, (long)minor);

    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.MobileSMS"]) {
        // Delay by 5 seconds so the server has a chance to initialize all the socket services
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DLog("BLUEBUBBLESHELPER: Initializing Connection...");
            [plugin initializeNetworkController];
        });
    } else {
        DLog("BLUEBUBBLESHELPER: Injected into non-iMessage process %@, aborting.", [[NSBundle mainBundle] bundleIdentifier]);
        return;
    }
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

    // DEVELOPMENT ONLY, COMMENT OUT FOR RELEASE
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//         [self handleMessage:controller message:@"{\"action\":\"send-multipart\",\"data\":{\"chatGuid\":\"iMessage;-;tanay@neotia.in\",\"subject\":\"SUBJECT\",\"parts\":[{\"text\":\"PART 1\",\"mention\":\"tanay@neotia.in\",\"range\":[0,4]},{\"text\":\"PART 3\"}],\"effectId\":\"com.apple.MobileSMS.expressivesend.impact\",\"selectedMessageGuid\":null}}"];
//         [self handleMessage:controller message:@"{\"action\":\"send-attachment\",\"data\":{\"filePath\":\"/Users/tanay/Library/Messages/Attachments/BlueBubbles/1668779053637.jpg\",\"chatGuid\":\"iMessage;-;zshames2@icloud.com\",\"isAudioMessage\":0}}"];
//    });
}

-(void) DumpObjcMethods:(Class) clz {

    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount);

    DLog("BLUEBUBBLESHELPER: Found %d methods on '%s'\n", methodCount, class_getName(clz));

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];

        DLog("\tBLUEBUBBLESHELPER: '%s' of encoding '%s'\n",
               sel_getName(method_getName(method)),
               method_getTypeEncoding(method));
    }

    free(methods);
}

// Run when receiving a new message from the tcp socket
-(void) handleMessage: (NetworkController*)controller  message:(NSString *)message {
    // The data is in the form of a json string, so we need to convert it to a NSDictionary
    // for some reason the data is sometimes duplicated, so account for that
    NSRange range = [message rangeOfString:@"}\n{"];
    if(range.location != NSNotFound){
     message = [message substringWithRange:NSMakeRange(0, range.location + 1)];
    }
    DLog("BLUEBUBBLESHELPER: Received raw json: %{public}@", message);
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

    DLog("BLUEBUBBLESHELPER: Message received: %{public}@, %{public}@", event, data);

    // If the server tells us to start typing
     if([event isEqualToString: @"start-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            NSLog(@"Start typing on %@", data[@"chatGuid"]);
            [chat setTypingGUID: data[@"chatGuid"]];
            [chat setLocalUserIsTyping:YES];
            NSTimeInterval interval = 4.0;
            [chat setLatestTypingIndicatorTimeInterval:interval];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }

    // If the server tells us to stop typing
    } else if([event isEqualToString:@"stop-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            NSLog(@"Stop typing on %@", data[@"chatGuid"]);
            [chat setTypingGUID:nil];
            [chat setLocalUserIsTyping:NO];
            NSTimeInterval interval = 0.0;
            [chat setLatestTypingIndicatorTimeInterval:interval];
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
    // If the server tells us to mark a chat as unread
    } else if([event isEqualToString:@"mark-chat-unread"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, mark last message unread
            [chat markLastMessageAsUnread];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    } else if([event isEqualToString:@"check-typing-status"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :nil];
        // Send out the correct response over the tcp socket
        if(chat.lastIncomingMessage.isTypingMessage == YES) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": chat.guid}];
            DLog("BLUEBUBBLESHELPER: %{public}@ started typing", chat.guid);
        } else {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": chat.guid}];
            DLog("BLUEBUBBLESHELPER: %{public}@ stopped typing", chat.guid);
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
        DLog("BLUEBUBBLESHELPER: Setting display name of chat %{public}@ to %{public}@", data[@"chatGuid"], data[@"newName"]);
    // If the server tells us to add a participant
    } else if ([event isEqualToString:@"add-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (data[@"address"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide an address to add!"}];
            }
            return;
        }
        IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(data[@"address"])];

        if (handle != nil && chat != nil && [chat canAddParticipant:(handle)]) {
            [chat inviteParticipantsToiMessageChat:(@[handle]) reason:(0)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            DLog("BLUEBUBBLESHELPER: Added participant to chat %{public}@: %{public}@", data[@"chatGuid"], data[@"address"]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to add address to chat!"}];
            }
            DLog("BLUEBUBBLESHELPER: Couldn't add participant to chat %{public}@: %{public}@", data[@"chatGuid"], data[@"address"]);
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

        IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(data[@"address"])];

        if (handle != nil && chat != nil && [chat canAddParticipant:(handle)]) {
            [chat removeParticipantsFromiMessageChat:(@[handle]) reason:(0)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            DLog("BLUEBUBBLESHELPER: Removed participant from chat %{public}@: %{public}@", data[@"chatGuid"], data[@"address"]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to remove address from chat!"}];
            }
            DLog("BLUEBUBBLESHELPER: Couldn't remove participant from chat %{public}@: %{public}@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to send a message or tapback
    } else if ([event isEqualToString:@"send-message"] || [event isEqualToString:@"send-reaction"]) {
        [BlueBubblesHelper sendMessage:(data) transfers:nil attributedString:nil transaction:(transaction)];
    // If the server tells us to edit a message
    } else if ([event isEqualToString:@"edit-message"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        [BlueBubblesHelper getMessageItem:(chat) :(data[@"messageGuid"]) completionBlock:^(IMMessage *message) {
            NSMutableAttributedString *editedString = [[NSMutableAttributedString alloc] initWithString: data[@"editedMessage"]];
            NSMutableAttributedString *bcString = [[NSMutableAttributedString alloc] initWithString: data[@"backwardsCompatibilityMessage"]];

            if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 14) {
                IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
                [chat editMessageItem:(messageItem) atPartIndex:([data[@"partIndex"] longValue]) withNewPartText:(editedString) backwardCompatabilityText:(bcString)];
            } else {
                [chat editMessage:(message) atPartIndex:([data[@"partIndex"] integerValue]) withNewPartText:(editedString) backwardCompatabilityText:(bcString)];
            }
        }];

        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    // If the server tells us to unsend a message
    } else if ([event isEqualToString:@"unsend-message"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        
        [BlueBubblesHelper getMessageItem:(chat) :(data[@"messageGuid"]) completionBlock:^(IMMessage *message) {
            IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
            NSObject *items = messageItem._newChatItems;
            IMMessagePartChatItem *item;
            // sometimes items is an array so we need to account for that
            if ([items isKindOfClass:[NSArray class]]) {
                for (IMMessagePartChatItem *i in (NSArray *) items) {
                    // IMAggregateAttachmentMessagePartChatItem is a photo gallery and has subparts
                    // Only available Monterey+, use reference to class loaded at runtime to avoid crashes on Big Sur
                    Class cls = NSClassFromString(@"IMAggregateAttachmentMessagePartChatItem");
                    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion > 11 && [i isKindOfClass:cls]) {
                        IMAggregateAttachmentMessagePartChatItem *aggregate = i;
                        for (IMMessagePartChatItem *i2 in [aggregate aggregateAttachmentParts]) {
                            if ([i2 index] == [data[@"partIndex"] integerValue]) {
                                item = i2;
                                break;
                            }
                        }
                    } else {
                        if ([i index] == [data[@"partIndex"] integerValue]) {
                            item = i;
                            break;
                        }
                    }
                }
            } else {
                item = (IMMessagePartChatItem *)items;
            }
            
            [chat retractMessagePart:(item)];
        }];
        
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    // If the server tells us to cancel a scheduled message
    } else if ([event isEqualToString:@"cancel-scheduled-message"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        [BlueBubblesHelper getMessageItem:(chat) :(data[@"messageGuid"]) completionBlock:^(IMMessage *message) {
            IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
            [chat cancelScheduledMessageItem:(messageItem) cancelType:(nil)]
        }];

        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    // If the server tells us to mark a chat as read
    } else if ([event isEqualToString:@"update-chat-pinned"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if (!chat.isPinned) {
            NSArray* arr = [[[IMPinnedConversationsController sharedInstance] pinnedConversationIdentifierSet] array];
            NSMutableArray<NSString*>* chatArr = [[NSMutableArray alloc] initWithArray:(arr)];
            [chatArr addObject:(chat.pinningIdentifier)];
            NSArray<NSString*>* finalArr = [chatArr copy];
            IMPinnedConversationsController* controller = [IMPinnedConversationsController sharedInstance];
            [controller setPinnedConversationIdentifiers:(finalArr) withUpdateReason:(@"contextMenu")];
        } else {
            NSArray* arr = [[[IMPinnedConversationsController sharedInstance] pinnedConversationIdentifierSet] array];
            NSMutableArray<NSString*>* chatArr = [[NSMutableArray alloc] initWithArray:(arr)];
            [chatArr removeObject:(chat.pinningIdentifier)];
            NSArray<NSString*>* finalArr = [chatArr copy];
            IMPinnedConversationsController* controller = [IMPinnedConversationsController sharedInstance];
            [controller setPinnedConversationIdentifiers:(finalArr) withUpdateReason:(@"contextMenu")];
        }
    // If the server tells us to create a chat
    } else if ([event isEqualToString:@"create-chat"]) {
        NSMutableArray<IMHandle*> *handles = [[NSMutableArray alloc] initWithArray:(@[])];
        BOOL failed = false;
        for (NSString* str in data[@"addresses"]) {
            IMHandle *handle;
            if ([data[@"service"] isEqualToString:@"iMessage"]) {
                handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(str)];
            } else {
                handle = [[[IMAccountController sharedInstance] activeSMSAccount] imHandleWithID:(str)];
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
                IMMessagePartChatItem *item;
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
    // If the server tells us to send a single attachment
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
        for (NSDictionary *dict in data[@"parts"]) {
            NSUInteger index = [dict[@"partIndex"] integerValue];
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
                    NSMutableAttributedString *mentionStr = [[NSMutableAttributedString alloc] initWithString: dict[@"text"]];
                    [mentionStr addAttributes:@{
                        @"__kIMBaseWritingDirectionAttributeName": @"-1",
                        @"__kIMMentionConfirmedMention": dict[@"mention"],
                        @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                    } range:NSMakeRange(0, [[mentionStr string] length])];
                    [attributedString appendAttributedString:mentionStr];
                } else {
                    NSMutableAttributedString *messageStr = [[NSMutableAttributedString alloc] initWithString: dict[@"text"]];
                    [messageStr addAttributes:@{
                        @"__kIMBaseWritingDirectionAttributeName": @"-1",
                        @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:index],
                    } range:NSMakeRange(0, [[messageStr string] length])];
                    [attributedString appendAttributedString:messageStr];
                }
            }
        }
        [BlueBubblesHelper sendMessage:(data) transfers:[transfers copy] attributedString:attributedString transaction:(transaction)];
    // If the server wants to get media for a balloon bundle item
    } else if ([event isEqualToString:@"balloon-bundle-media-path"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        [BlueBubblesHelper getMessageItem:(chat) :(data[@"messageGuid"]) completionBlock:^(IMMessage *message) {
            IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
            NSObject *items = messageItem._newChatItems;
            // balloon items will only be an IMTranscriptPluginChatItem
            if ([items isKindOfClass:[IMTranscriptPluginChatItem class]]) {
                IMTranscriptPluginChatItem *item = (IMTranscriptPluginChatItem *) items;
                NSObject *temp = [item dataSource];
                // The data source is this weird class, no idea what framework its from. Class methods dumped via _methodDescription on cls
                Class digitalTouchClass = NSClassFromString(@"ETiOSMacBalloonPluginDataSource");
                Class handwrittenClass = NSClassFromString(@"HWiOSMacBalloonDataSource");
                if ([temp isKindOfClass:digitalTouchClass]) {
                    ETiOSMacBalloonPluginDataSource *digitalTouch = (ETiOSMacBalloonPluginDataSource *)[item dataSource];
                    // Force iMessage to generate the .mov and return the path
                    [digitalTouch generateMedia:^() {
                        NSString *path = [(NSURL *)[digitalTouch assetURL] absoluteString];
                        DLog("BLUEBUBBLESHELPER: Digital Touch generated! %@", path);
                        if (transaction != nil) {
                            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"path": path}];
                        }
                    }];
                } else if ([temp isKindOfClass:handwrittenClass]) {
                    HWiOSMacBalloonDataSource *digitalTouch = (HWiOSMacBalloonDataSource *)[item dataSource];
                    CGSize size = [digitalTouch sizeThatFits:CGSizeMake(300, 300)];
                    [digitalTouch generateImageForSize:size completionHandler:^(NSObject *url) {
                        NSString *path = [(NSURL *)url absoluteString];
                        DLog("BLUEBUBBLESHELPER: Handwritten Message generated! %@", path);
                        if (transaction != nil) {
                            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"path": path}];
                        }
                    }];
                }
            }
        }];
    // If the server requests us to update the group photo
    } else if ([event isEqualToString:@"update-group-photo"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if (data[@"filePath"] != [NSNull null] && [data[@"filePath"] length] != 0) {
            NSURL * fileUrl = [NSURL fileURLWithPath: data[@"filePath"]];
            IMFileTransfer* fileTransfer = [BlueBubblesHelper prepareFileTransferForAttachment:fileUrl filename:[fileUrl lastPathComponent]];
            [chat sendGroupPhotoUpdate:([fileTransfer guid])];
        } else {
            [chat sendGroupPhotoUpdate:nil];
        }
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    // If server tells us to leave a chat
    } else if ([event isEqualToString:@"leave-chat"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (chat != nil && [chat canLeaveChat]) {
            [chat leaveiMessageGroup];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    // If the server asks us to check the focus status of a user
    } else if ([event isEqualToString:@"check-focus-status"]) {
        IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(data[@"address"])];
        // Use reference to class since it doesn't exist on Big Sur
        Class cls = NSClassFromString(@"IMHandleAvailabilityManager");
        if (handle != nil && cls != nil) {
            if ([cls instancesRespondToSelector:NSSelectorFromString(@"_fetchUpdatedStatusForHandle:completion:")]) {
                [[cls sharedInstance] _fetchUpdatedStatusForHandle:(handle) completion:^() {
                    // delay for 1 second to ensure we have latest status
                    NSTimeInterval delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        NSInteger *status = [[cls sharedInstance] availabilityForHandle:(handle)];
                        DLog("BLUEBUBBLESHELPER: Found status %{public}ld for %{public}@", (long)status, data[@"address"]);
                        if (transaction != nil) {
                            BOOL silenced = status == 2;
                            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"silenced": [NSNumber numberWithBool:silenced]}];
                        }
                    });
                }];
            } else {
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Selector not found!"}];
                }
            }
        }
    } else if ([event isEqualToString:@"notify-anyways"]) {
        IMChat *chat = [BlueBubblesHelper getChat:data[@"chatGuid"] :transaction];

        [BlueBubblesHelper getMessageItem:(chat) :(data[@"messageGuid"]) completionBlock:^(IMMessage *message) {
            IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
            NSObject *items = messageItem._newChatItems;
            IMMessagePartChatItem *item;
            // sometimes items is an array so we need to account for that
            if ([items isKindOfClass:[NSArray class]]) {
                item = [(NSArray*) items firstObject];
            } else {
                item = (IMMessagePartChatItem *)items;
            }

            if (item != nil) {
                [chat markChatItemAsNotifyRecipient:item];
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
                }
            }
        }];
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

        [[IDSIDQueryController sharedInstance] forceRefreshIDStatusForDestinations:(@[dest]) service:(serviceName) listenerID:(@"SOIDSListener-com.apple.imessage-rest") queue:(dispatch_queue_create("HandleIDS", NULL)) completionBlock:^(NSDictionary *response) {
            NSInteger *status = [response.allValues.firstObject integerValue];
            BOOL available = status == 1;
            DLog("BLUEBUBBLESHELPER: Status for %{public}@ is %{public}ld", data[@"address"], (long)available);
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"available": [NSNumber numberWithBool:(available)]}];
            }
        }];
    // If the server tells us to download a purged attachment
    } else if ([event isEqualToString:@"download-purged-attachment"]) {
        IMFileTransfer* transfer = [[IMFileTransferCenter sharedInstance] transferForGUID:(data[@"attachmentGuid"])];
        if ([transfer transferState] != 0 || ![transfer isIncoming]) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"No need to unpurge!"}];
            }
        }

        [[IMFileTransferCenter sharedInstance] registerTransferWithDaemon:([transfer guid])];
        [[IMFileTransferCenter sharedInstance] acceptTransfer:([transfer guid])];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    // If the server asks us if the chat can have a nickname shared
    } else if ([event isEqualToString:@"should-offer-nickname-sharing"]) {
        IMChat *chat = [BlueBubblesHelper getChat:data[@"chatGuid"] :transaction];

        BOOL offer = [[IMNicknameController sharedInstance] shouldOfferNicknameSharingForChat:chat];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"share": [NSNumber numberWithBool:offer]}];
        }
    // If the server tells us to share a nickname
    } else if ([event isEqualToString:@"share-nickname"]) {
        IMChat *chat = [BlueBubblesHelper getChat:data[@"chatGuid"] :transaction];

        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion == 11) {
            [[IMNicknameController sharedInstance] whitelistHandlesForNicknameSharing:[chat participants] forChat:chat];
        } else {
            IMAccount *account = [[IMAccountController sharedInstance] activeIMessageAccount];
            [[IMNicknameController sharedInstance] allowHandlesForNicknameSharing:[chat participants] fromHandle:[account displayName] forceSend:TRUE];
        }
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    // If the server tells us to get nickname info
    } else if ([event isEqualToString:@"get-nickname-info"]) {
        NSString *address = data[@"address"];
        NSString *name;
        NSString *avatarPath;
        
        if (address == [NSNull null]) {
            name = [[[IMNicknameController sharedInstance] personalNickname] displayName];
            avatarPath = [[[[IMNicknameController sharedInstance] personalNickname] avatar] imageFilePath];
        } else {
            IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(data[@"address"])];
            IMNickname *nickname = [[IMNicknameController sharedInstance] nicknameForHandle:(handle)];
            name = [nickname displayName];
            avatarPath = [[nickname avatar] imageFilePath];
        }
        
        if (transaction != nil) {
            NSDictionary *data = @{
                @"transactionId": transaction,
                @"name": name ?: [NSNull null],
                @"avatar_path": avatarPath ?: [NSNull null],
            };
            [[NetworkController sharedInstance] sendMessage:data];
        }
    // If the server tells us to get the current account info
    } else if ([event isEqualToString:@"get-account-info"]) {
        IMAccountController *controller = [IMAccountController sharedInstance];
        IMAccount *account = [controller activeIMessageAccount];
        IMAccount *smsAccount = [controller activeSMSAccount];
        
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
                @"active_alias": [account displayName] ?: [NSNull null]
            };
            [[NetworkController sharedInstance] sendMessage: data];
        }
    // If the server tells us to modify the active alias used to start chats
    } else if ([event isEqualToString:@"modify-active-alias"]) {
        NSString* alias = data[@"alias"];

        if ([BlueBubblesHelper isAccountEnabled]) {
            IMAccountController *controller = [IMAccountController sharedInstance];
            IMAccount *account = [controller activeIMessageAccount];
            [account setDisplayName:alias];
            
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        } else {
            DLog("BLUEBUBBLESHELPER: Can't modify aliases, account not enabled");
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to modify alias"}];
            }
        }
    // If the server tells us to get findmy friends locations
    } else if ([event isEqualToString:@"refresh-findmy-friends"]) {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion > 13) {
            FindMyLocateSession *session = [[IMFMFSession sharedInstance] fmlSession];
            DLog("BLUEBUBBLESHELPER: block 1: %@", [session locationUpdateCallback]);
            //            [self logString:[[[[CTBlockDescription alloc] initWithBlock:[session locationUpdateCallback]] blockSignature] debugDescription]];
            //            NSObject *block = ^(FMLLocation *test, FMLHandle *test2) {
            //                DLog("BLUEBUBBLESHELPER: test2: %@", test);
            //                DLog("BLUEBUBBLESHELPER: test2: %@", [test className]);
            //            };
            //            DLog("BLUEBUBBLESHELPER: setting block: %@", block);
            //            DLog("BLUEBUBBLESHELPER: setting block: %@", [[[[CTBlockDescription alloc] initWithBlock:block] blockSignature] debugDescription]);
            //            [session setLocationUpdateCallback:block];
            //            DLog("BLUEBUBBLESHELPER: block 2: %@", [session locationUpdateCallback]);
            //            DLog("BLUEBUBBLESHELPER: block 2: %@", [[[[CTBlockDescription alloc] initWithBlock:[session locationUpdateCallback]] blockSignature] debugDescription]);
            [session getFriendsSharingLocationsWithMeWithCompletion:^(NSArray *friends) {
                for (NSObject* friend in friends) {
                    NSObject* handle = [friend performSelector:(NSSelectorFromString(@"handle"))];
                    DLog("BLUEBUBBLESHELPER: test: %@", handle);
                    [session startRefreshingLocationForHandles:@[handle] priority:(1000) isFromGroup:FALSE reverseGeocode:TRUE completion:^() {
                        NSObject *test = [session cachedLocationForHandle:handle includeAddress:TRUE];
                        DLog("BLUEBUBBLESHELPER: test: %@", test);
                        DLog("BLUEBUBBLESHELPER: test: %@", [test className]);
                    }];
                }
            }];
            
            if (transaction != nil) {
                NSDictionary *data = @{
                    @"transactionId": transaction,
                    @"locations": @[],
                };
                [[NetworkController sharedInstance] sendMessage: data];
            }
        } else {
            FMFSession *session = [[IMFMFSession sharedInstance] session];
            NSArray* handles = [session getHandlesSharingLocationsWithMe];
            DLog("BLUEBUBBLESHELPER: Found FMF Handles: %{public}@", handles);
            
            // Send the current cached locations to the server just in case
            NSMutableArray* locations = [[NSMutableArray alloc] initWithArray:@[]];
            for (NSObject* handle in handles) {
                FMFLocation* location = [[IMFMFSession sharedInstance] locationForFMFHandle:handle];
                NSInteger* type = ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) ? 0 : [location locationType];
                NSDictionary* locDetails = @{
                    @"handle": [[location handle] identifier] ?: [NSNull null],
                    @"coordinates": @[@([location coordinate].latitude), @([location coordinate].longitude)],
                    @"long_address": [location longAddress] ?: [NSNull null],
                    @"short_address": [location shortAddress] ?: [NSNull null],
                    @"subtitle": [location subtitle] ?: [NSNull null],
                    @"title": [location title] ?: [NSNull null],
                    @"last_updated": [NSNumber numberWithDouble:round([[location timestamp] timeIntervalSince1970])*1000],
                    @"is_locating_in_progress": [NSNumber numberWithBool:[location isLocatingInProgress]] ?: [NSNull null],
                    @"status": (type == 0) ? @"legacy" : (type == 2) ? @"live" : @"shallow"
                };
                [locations addObject:locDetails];
            }
            
            if (transaction != nil) {
                NSDictionary *data = @{
                    @"transactionId": transaction,
                    @"locations": locations,
                };
                [[NetworkController sharedInstance] sendMessage: data];
            }
            
            [session removeHandles:[session handles]];
            [session addHandles:handles];
            [session forceRefresh];
        }
    } else if ([event isEqualToString:@"search-messages"]) {
        NSString* query = data[@"query"];
        NSString* matchType = data[@"matchType"];
        [self searchMessages:query matchType:matchType completionBlock:^(NSArray<NSString *> *results) {
            if (results) {
                if (transaction != nil) {
                    NSDictionary *data = @{
                        @"transactionId": transaction,
                        @"results": results,
                    };
                    [[NetworkController sharedInstance] sendMessage: data];
                }
            } else {
                if (transaction != nil) {
                    NSDictionary *data = @{
                        @"transactionId": transaction,
                        @"error": @"Failed to execute search! Search returned null.",
                    };
                    [[NetworkController sharedInstance] sendMessage: data];
                }
            }
        } errorBlock:^(NSString *err) {
            if (transaction != nil) {
                NSDictionary *data = @{
                    @"transactionId": transaction,
                    @"error": err,
                };
                [[NetworkController sharedInstance] sendMessage: data];
            }
        }];
    // If the event is something that hasn't been implemented, we simply ignore it and put this log
    } else {
        DLog("BLUEBUBBLESHELPER: Not implemented %{public}@", event);
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

    DLog("BLUEBUBBLESHELPER: %{public}@", lowerCaseType);

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

+(NSString *) reactionToVerb:(NSString *)reactionType {
    NSString *lowerCaseType = [reactionType lowercaseString];

    if([@"love" isEqualToString:(lowerCaseType)]) return @"Loved ";
    if([@"like" isEqualToString:(lowerCaseType)]) return @"Liked ";
    if([@"dislike" isEqualToString:(lowerCaseType)]) return @"Disliked ";
    if([@"laugh" isEqualToString:(lowerCaseType)]) return @"Laughed at ";
    if([@"emphasize" isEqualToString:(lowerCaseType)]) return @"Emphasized ";
    if([@"question" isEqualToString:(lowerCaseType)]) return @"Questioned ";
    if([@"-love" isEqualToString:(lowerCaseType)]) return @"Removed a heart from ";
    if([@"-like" isEqualToString:(lowerCaseType)]) return @"Removed a like from ";
    if([@"-dislike" isEqualToString:(lowerCaseType)]) return @"Removed a dislike from ";
    if([@"-laugh" isEqualToString:(lowerCaseType)]) return @"Removed a laugh from ";
    if([@"-emphasize" isEqualToString:(lowerCaseType)]) return @"Removed an exclamation from ";
    if([@"-question" isEqualToString:(lowerCaseType)]) return @"Removed a question mark from ";
    return @"";
}

+(void) getMessageItem:(IMChat *)chat :(NSString *)actionMessageGuid completionBlock:(void (^)(IMMessage *message))block {
    [[IMChatHistoryController sharedInstance] loadMessageWithGUID:(actionMessageGuid) completionBlock:^(IMMessage *message) {
        DLog("BLUEBUBBLESHELPER: Got message for guid %{public}@", actionMessageGuid);
        block(message);
    }];
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
    DLog("BLUEBUBBLESHELPER: Transfer GUID: %{public}@", transferInitGuid);

    // Creates the initial transfer object
    IMFileTransfer *newTransfer = [[IMFileTransferCenter sharedInstance] transferForGUID:transferInitGuid];
    // Get location of where attachments should be placed
    NSString *persistentPath = [[IMDPersistentAttachmentController sharedInstance] _persistentPathForTransfer:newTransfer filename:filename highQuality:TRUE chatGUID:nil storeAtExternalPath:TRUE];
    DLog("BLUEBUBBLESHELPER: Requested persistent path: %{public}@", persistentPath);

    if (persistentPath) {
        NSError *folder_creation_error;
        NSError *file_move_error;
        NSURL *persistentURL = [NSURL fileURLWithPath:persistentPath];

        // Create the attachment location
        [[NSFileManager defaultManager] createDirectoryAtURL:[persistentURL URLByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:&folder_creation_error];
        // Handle error and exit
        if (folder_creation_error) {
            DLog("BLUEBUBBLESHELPER:  Failed to create folder: %{public}@", folder_creation_error);
            return nil;
        }

        // Copy the file to the attachment location
        [[NSFileManager defaultManager] copyItemAtURL:originalPath toURL:persistentURL error:&file_move_error];
        // Handle error and exit
        if (file_move_error) {
            DLog("BLUEBUBBLESHELPER:  Failed to move file: %{public}@", file_move_error);
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
    DLog("BLUEBUBBLESHELPER: Transfer registered successfully!");
    return newTransfer;
}

+ (NSDateFormatter *)iso8601FormatterWithFormat:(NSString *)format {
    static NSMutableDictionary<NSString *, NSDateFormatter *> *formatters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatters = [NSMutableDictionary new];
    });
    
    @synchronized (formatters) {
        NSDateFormatter *formatter = formatters[format];
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
            formatter.dateFormat = format;
            formatters[format] = formatter;
        }
        return formatter;
    }
}

+(void) sendMessage: (NSDictionary *) data transfers: (NSArray *) transfers attributedString:(NSMutableAttributedString *) attributedString transaction:(NSString *) transaction {
    IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
    if (chat == nil) {
        DLog("BLUEBUBBLESHELPER: chat is null, aborting");
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
    
    NSDate *scheduledDate = nil;
    if (data[@"scheduled"] != [NSNull null] && [data[@"scheduled"] length] != 0) {
        NSString *scheduledString = data[@"scheduled"];
        NSLog(@"Found scheduled string: %@", scheduledString);
        NSArray *dateFormats = @[
            @"yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            @"yyyy-MM-dd'T'HH:mm:ssXXXXX"
        ];

        for (NSString *format in dateFormats) {
            NSDateFormatter *formatter = [self iso8601FormatterWithFormat:format];
            scheduledDate = [formatter dateFromString:scheduledString];
            if (scheduledDate != nil) { break; }
        }

        if (scheduledDate == nil) {
            NSLog(@"Failed to parse scheduled date string: %@", scheduledString);
        } else {
            NSLog(@"Scheduled date object: %@", scheduledDate);
        }
    }
    
    BOOL isAudioMessage = false;
    if (data[@"isAudioMessage"] != [NSNull null]) {
        isAudioMessage = [data[@"isAudioMessage"] integerValue] == 1;
    }
    
    BOOL ddScan = false;
    if (data[@"ddScan"] != [NSNull null]) {
        ddScan = [data[@"ddScan"] integerValue] == 1;
    }

    void (^createMessage)(NSAttributedString*, NSAttributedString*, NSString*, NSString*, NSString*, long long*, NSRange, NSDictionary*, NSArray*, BOOL, BOOL) = ^(NSAttributedString *message, NSAttributedString *subject, NSString *effectId, NSString *threadIdentifier, NSString *associatedMessageGuid, long long *reaction, NSRange range, NSDictionary *summaryInfo, NSArray *transferGUIDs, BOOL isAudioMessage, BOOL ddScan) {
        IMMessage *messageToSend;
        
        if (scheduledDate != nil) {
            messageToSend = [IMMessage instantMessageWithText:(message) messageSubject:(subject) flags:(isAudioMessage ? 0x300005 : (subject ? 0x10000d : 0x100005)) threadIdentifier:(threadIdentifier) associatedMessageGUID:(associatedMessageGuid) scheduledDate:(scheduledDate)];
        } else {
            messageToSend = [[IMMessage alloc] init];
            
            if (reaction == nil) {
                messageToSend = [messageToSend initWithSender:(nil) time:(nil) text:(message) messageSubject:(subject) fileTransferGUIDs:(transferGUIDs) flags:(isAudioMessage ? 0x300005 : (subject ? 0x10000d : 0x100005)) error:(nil) guid:(nil) subject:(nil) balloonBundleID:(nil) payloadData:(nil) expressiveSendStyleID:(effectId)];
                messageToSend.threadIdentifier = threadIdentifier;
            } else {
                messageToSend = [messageToSend initWithSender:(nil) time:(nil) text:(message) messageSubject:(subject) fileTransferGUIDs:(nil) flags:(0x5) error:(nil) guid:(nil) subject:(nil) associatedMessageGUID:(associatedMessageGuid) associatedMessageType:*(reaction) associatedMessageRange:(range) messageSummaryInfo:(summaryInfo)];
            }
        }
        
        if (ddScan) {
            __strong typeof(messageToSend) strongMessage = messageToSend;
            __strong typeof(chat) strongChat = chat;
            
            [[IMDDController sharedInstance] scanMessage:strongMessage outgoing:TRUE waitUntilDone:TRUE completionBlock:^(NSInteger status, BOOL success, id result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongChat sendMessage:(strongMessage)];
                    if (transaction != nil) {
                        [[NetworkController sharedInstance]sendMessage:@{@"transactionId": transaction, @"identifier": [[strongChat lastSentMessage] guid]}];
                    }
                });
             }];
        } else {
            [chat sendMessage:(messageToSend)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastSentMessage] guid]}];
            }
        }
    };

    if (data[@"selectedMessageGuid"] != [NSNull null] && [data[@"selectedMessageGuid"] length] != 0) {
        [BlueBubblesHelper getMessageItem:(chat) :(data[@"selectedMessageGuid"]) completionBlock:^(IMMessage *message) {
            IMMessageItem *messageItem = (IMMessageItem *)message._imMessageItem;
            NSObject *items = messageItem._newChatItems;
            IMMessagePartChatItem *item;
            // sometimes items is an array so we need to account for that
            if ([items isKindOfClass:[NSArray class]]) {
                for (IMMessagePartChatItem *i in (NSArray *) items) {
                    // IMAggregateAttachmentMessagePartChatItem is a photo gallery and has subparts
                    // Only available Monterey+, use reference to class loaded at runtime to avoid crashes on Big Sur
                    Class cls = NSClassFromString(@"IMAggregateAttachmentMessagePartChatItem");
                    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion > 11 && [i isKindOfClass:cls]) {
                        IMAggregateAttachmentMessagePartChatItem *aggregate = i;
                        for (IMMessagePartChatItem *i2 in [aggregate aggregateAttachmentParts]) {
                            if ([i2 index] == [data[@"partIndex"] integerValue]) {
                                item = i2;
                                break;
                            }
                        }
                    } else {
                        if ([i index] == [data[@"partIndex"] integerValue]) {
                            item = i;
                            break;
                        }
                    }
                }
            } else {
                item = (IMMessagePartChatItem *)items;
            }
            if (data[@"reactionType"] != [NSNull null] && [data[@"reactionType"] length] != 0) {
                NSString *reaction = data[@"reactionType"];
                long long reactionLong = [BlueBubblesHelper parseReactionType:(reaction)];
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
                        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString: [[BlueBubblesHelper reactionToVerb:(reaction)] stringByAppendingString:(@"an attachment")]];
                        createMessage(newAttributedString, subjectAttributedString, effectId, nil, [NSString stringWithFormat:@"p:%@/%@", data[@"partIndex"], [message guid]], &reactionLong, [item messagePartRange], @{}, nil, false, ddScan);
                    } else {
                        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString: [[BlueBubblesHelper reactionToVerb:(reaction)] stringByAppendingString:([NSString stringWithFormat:(@"“%@”"), text.string])]];
                        if ([item text] == nil) {
                            createMessage(newAttributedString, subjectAttributedString, effectId, nil, [NSString stringWithFormat:@"bp:%@", [message guid]], &reactionLong, [item messagePartRange], messageSummary, nil, false, ddScan);
                        } else {
                            createMessage(newAttributedString, subjectAttributedString, effectId, nil, [NSString stringWithFormat:@"p:%@/%@", data[@"partIndex"], [message guid]], &reactionLong, [item messagePartRange], messageSummary, nil, false, ddScan);
                        }
                    }
                } else {
                    messageSummary = @{@"amc":@1,@"ams":message.text.string};
                    // Send the tapback
                    // check if the body happens to be an object (ie an attachment) and send the tapback accordingly to show the proper summary
                    NSData *dataenc = [[message text].string dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                    NSString *encodevalue = [[NSString alloc]initWithData:dataenc encoding:NSUTF8StringEncoding];
                    NSRange range = NSMakeRange(0, [message text].string.length);
                    if ([encodevalue isEqualToString:@"\\ufffc"] || [encodevalue length] == 0) {
                        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString: [[BlueBubblesHelper reactionToVerb:(reaction)] stringByAppendingString:(@"an attachment")]];
                        createMessage(newAttributedString, subjectAttributedString, effectId, nil, [message guid], &reactionLong, range, @{}, nil, false, ddScan);
                    } else {
                        NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString: [[BlueBubblesHelper reactionToVerb:(reaction)] stringByAppendingString:([NSString stringWithFormat:(@"“%@”"), [message text].string])]];
                        createMessage(newAttributedString, subjectAttributedString, effectId, nil, [message guid], &reactionLong, range, messageSummary, nil, false, ddScan);
                    }
                }
            } else {
                NSString *identifier = @"";
                // either reply to an existing thread or create a new thread
                if (message.threadIdentifier != nil) {
                    identifier = message.threadIdentifier;
                } else if (item != nil) {
                    identifier = IMCreateThreadIdentifierForMessagePartChatItem(item);
                }
                createMessage(attributedString, subjectAttributedString, effectId, identifier, nil, nil, NSMakeRange(0, 0), nil, transfers, isAudioMessage, ddScan);
            }
        }];
    } else {
        createMessage(attributedString, subjectAttributedString, effectId, nil, nil, nil, NSMakeRange(0, 0), nil, transfers, isAudioMessage, ddScan);
    }
}

+(void) cancelMessage: (NSString *) guid {
    
}

- (void)searchMessages:(NSString *)searchQuery matchType:(NSString *)matchType completionBlock:(void (^)(NSMutableArray<NSString *> *results))onComplete errorBlock:(void (^)(NSString *err))onError {
    NSString *queryString = [NSString stringWithFormat:@"kMDItemTextContent=\"%@\"cwdt", searchQuery];
    
    // c -> Performs a case-insensitive search.
    // d -> Performs a search that ignores diacritical marks.
    // w -> Matches on word boundaries. This modifier treats transitions from lowercase to uppercase as word boundaries.
    // t -> Performs a search on a tokenized value. For example, a search field can contain tokenized values.
    
    // When "t" is used, the tokens do not need to match the order provided.
    // That's why when the matchType is exact, we exclude it.
    // I'm not sure how to do a true exact match query.
    if ([matchType isEqualToString:@"exact"]) {
        queryString = [NSString stringWithFormat:@"kMDItemTextContent=\"%@\"cwd", searchQuery];
    }
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) {
        DLog("BLUEBUBBLESHELPER: Message searching is not supported before macOS 13.0");
        if (onError) {
            onError(@"Message searching is not supported before macOS 13.0");
        }
        
        return;
    }
    
    // Create a query context if needed, otherwise pass nil
    CSSearchQueryContext *queryContext = [[CSSearchQueryContext alloc] init];
    
    // uniqueIdentifier -> Message GUID
    // attributes.domainIdentifier -> Chat GUID
    // attributes.displayName -> Group Chat Name (null if none)
    // Leaving empty unless we want something specific...
    queryContext.fetchAttributes = @[];
    CSSearchQuery *query = [[CSSearchQuery alloc] initWithQueryString:queryString queryContext:queryContext];

    NSMutableArray<NSString *> *results = [NSMutableArray array];
    query.foundItemsHandler = ^(NSArray<CSSearchableItem *> * _Nonnull items) {
        for (CSSearchableItem *item in items) {
            // Add the unique identifier to the results array
            [results addObject:item.uniqueIdentifier];
        }
    };
    
    query.completionHandler = ^(NSError * _Nullable error) {
        if (error) {
            DLog("BLUEBUBBLESHELPER: Message search error: %@", error.localizedDescription);
            if (onError) {
                onError(error.localizedDescription);
            }
        } else {
            if (onComplete) {
                onComplete([results copy]);
            }
        }
    };
    
    [query start];
}

/**
 Get the account enabled state
 @return True if the account enabled state is 4 or false if else or not signed in
 */
+(BOOL) isAccountEnabled {
    IMAccount *account = [[IMAccountController sharedInstance] activeIMessageAccount];
    return [account isActive] && [account isRegistered] && [account isOperational] && [account isConnected];
}

/**
  Gets the active alias associated with the signed account
  @return The active alias's names if not logged in returns a empty list
  */
+(NSMutableArray *) getAliases:(BOOL)vetted {
    if ([self isAccountEnabled]) {
        IMAccount *account = [[IMAccountController sharedInstance] activeIMessageAccount];
        NSArray* aliases = @[];
        if (vetted) {
            aliases = [account vettedAliases];
        } else {
            aliases = [account aliases];
        }
        DLog("BLUEBUBBLESHELPER: Vetted Aliases %{public}@", aliases);

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
        DLog("BLUEBUBBLESHELPER: Can't get aliases - account not enabled");
        return [[NSMutableArray alloc] initWithArray:@[]];
    }
    return [[NSMutableArray alloc] initWithArray:@[]];
}

@end

ZKSwizzleInterface(BBH_IMChat, IMChat, NSObject)
@implementation BBH_IMChat

- (BOOL)_handleIncomingItem:(id)arg1 {
    IMMessageItem* item = arg1;
    //Complete the normal functions like writing to database and everything
    BOOL hasBeenHandled = ZKOrig(BOOL, arg1);
    NSString *guid = (NSString *)ZKHookIvar(self, NSString*, "_guid");
    if (guid != nil) {
        // check if incoming item is a typing indicator or not, and update the status accordingly. check if the class responds to the selector to avoid crashes
        if ([item respondsToSelector:@selector(isIncomingTypingMessage)] && [item isIncomingTypingMessage]) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
            DLog("BLUEBUBBLESHELPER: %{public}@ started typing", guid);
        } else if ([item respondsToSelector:@selector(isCancelTypingMessage)] && [item isCancelTypingMessage]) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
            DLog("BLUEBUBBLESHELPER: %{public}@ stopped typing", guid);
        } else if ([item respondsToSelector:@selector(isTypingMessage)] && [[item message] isTypingMessage] == NO) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
            DLog("BLUEBUBBLESHELPER: %{public}@ stopped typing", guid);
        }
    }
    return hasBeenHandled;
}

@end

ZKSwizzleInterface(BBH_FindMyLocateSession, FindMyLocateSession, NSObject)
@implementation BBH_FindMyLocateSession

- (id /* block */)locationUpdateCallback {
    DLog("BLUEBUBBLESHELPER: fired");
    return ZKOrig(id);
}

@end

// Handle FindMy data changes
ZKSwizzleInterface(BBH_FMFSessionDataManager, FMFSessionDataManager , NSObject)
@implementation BBH_FMFSessionDataManager

- (void)setLocations:(id)arg1 {
    Class class = NSClassFromString(@"FMFSessionDataManager");
    NSSet* locations = [[class sharedInstance] locations];
    DLog("BLUEBUBBLESHELPER: Got new locations: %{public}@", locations);
    
    for (FMFLocation* location in locations) {
        NSInteger* type = ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) ? 0 : [location locationType];
        NSMutableDictionary* locDetails = [[NSMutableDictionary alloc] initWithDictionary: @{
            @"handle": [[location handle] identifier] ?: [NSNull null],
            @"coordinates": @[@([location coordinate].latitude), @([location coordinate].longitude)],
            @"long_address": [location longAddress] ?: [NSNull null],
            @"short_address": [location shortAddress] ?: [NSNull null],
            @"subtitle": [location subtitle] ?: [NSNull null],
            @"title": [location title] ?: [NSNull null],
            @"last_updated": [NSNumber numberWithDouble:round([[location timestamp] timeIntervalSince1970])*1000],
            @"is_locating_in_progress": [NSNumber numberWithBool:[location isLocatingInProgress]] ?: [NSNull null],
            @"status": (type == 0) ? @"legacy" : (type == 2) ? @"live" : @"shallow"
        }];
        
        if ([location coordinate].latitude == 0 && [location coordinate].longitude == 0 && [location longAddress] != nil) {
            DLog("BLUEBUBBLESHELPER: Geocoding location for %{public}@", [[location handle] identifier]);
            [[[CLGeocoder alloc] init] geocodeAddressString:[location longAddress] completionHandler:^(NSArray<CLPlacemark*>* placemarks, NSError* error) {
                if (placemarks.count > 0) {
                    CLLocation* coords = [[placemarks firstObject] location];
                    [locDetails setValue:@[@([coords coordinate].latitude), @([coords coordinate].longitude)] forKey:@"coordinates"];
                }

                NSDictionary *data = @{
                    @"event": @"new-findmy-location",
                    @"data": @[locDetails],
                };
                [[NetworkController sharedInstance] sendMessage: data];
            }];
        } else {
            NSDictionary *data = @{
                @"event": @"new-findmy-location",
                @"data": @[locDetails],
            };
            [[NetworkController sharedInstance] sendMessage: data];
        }
    }
    return ZKOrig(void, arg1);
}

@end

ZKSwizzleInterface(BBH_IMAccount, IMAccount, NSObject)
@implementation BBH_IMAccount

- (void)_registrationStatusChanged:(id)arg1 {
    NSNotification *notif = arg1;
    IMAccount* acct = [notif object];
    NSDictionary *info = [notif userInfo];
    if ([info objectForKey:@"__kIMAccountAliasesRemovedKey"] != nil && [[acct serviceName] isEqualToString:@"iMessage"]) {
        DLog("BLUEBUBBLESHELPER: alias updated %{public}@", notif);
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"aliases-removed", @"data": info}];
    }
    return ZKOrig(void, arg1);
}

@end

//ZKSwizzleInterface(BBH_NSNotificationCenter, NSNotificationCenter, NSObject)
//@implementation BBH_NSNotificationCenter
//
//- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
//    if ([aName isEqualToString:@"CNContactStoreDidChangeNotification"]) {
//        return ZKOrig(void, observer, aSelector, aName, anObject);
//    }
//    DLog("BLUEBUBBLESFACETIMEHELPER: >>>>>>>>>>>>> name %{public}@", aName);
//    DLog("BLUEBUBBLESFACETIMEHELPER: observer %{public}@", observer);
//    DLog("BLUEBUBBLESFACETIMEHELPER: sel %{public}@", NSStringFromSelector(aSelector));
//    DLog("BLUEBUBBLESFACETIMEHELPER: object %{public}@", anObject);
//    return ZKOrig(void, observer, aSelector, aName, anObject);
//}
//
//@end
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withAssociatedMessageInfo:(id)arg3 withGuid:(id)arg4 {
//    DLog("BLUEBUBBLESHELPER: sending reaction 1");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withAssociatedMessageInfo:(id)arg3 {
//    DLog("BLUEBUBBLESHELPER: sending reaction 2");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 withGuid:(id)arg4 {
//    DLog("BLUEBUBBLESHELPER: sending reaction 3");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 {
//    DLog("BLUEBUBBLESHELPER: sending reaction 4");
//    DLog("BLUEBUBBLESHELPER: %lld", arg1);
//    DLog("BLUEBUBBLESHELPER: %{public}@", arg2);
//    DLog("BLUEBUBBLESHELPER: %{public}@", arg3);
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
//    DLog("BLUEBUBBLESHELPER: sendMessage %{public}@", arg1);
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
//    DLog("typeStatus : _updateTimeRead");
//}
//
//@end
