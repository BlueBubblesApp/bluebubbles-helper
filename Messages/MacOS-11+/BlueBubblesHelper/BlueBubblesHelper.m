@import AppKit;

#import <Foundation/Foundation.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import "BlueBubblesHelper.h"
#import "Logging.h"
#import "NetworkController.h"
#import "ZKSwizzle.h"

// import system headers with angle brackets to prevent Xcode analysis
// ChatKit
#import <CKChatController.h>
#import <CKChatItem.h>
#import <CKComposition.h>
#import <CKConversation.h>
#import <CKConversationList.h>
#import <CKCoreChatController.h>
#import <CKMediaObject.h>
#import <CKMediaObjectManager.h>

// Balloon Bundle Plugins
#import <ETiOSMacBalloonPluginDataSource.h>
#import <HWiOSMacBalloonDataSource.h>

// FindMy
#import <FMFLocation.h>
#import <FMFSession.h>
#import <FMFSessionDataManager.h>
#import <FMLHandle.h>
#import <FMLLocation.h>
#import <FMLSession.h>

// IMCore
#import <IDS.h>
#import <IDSDestination-Additions.h>
#import <IDSIDQueryController.h>
#import <IMAccount.h>
#import <IMAccountController.h>
#import <IMAggregateAttachmentMessagePartChatItem.h>
#import <IMChat.h>
#import <IMChatHistoryController.h>
#import <IMChatRegistry.h>
#import <IMCore.h>
#import <IMEmojiTapback.h>
#import <IMFileTransfer.h>
#import <IMFileTransferCenter.h>
#import <IMFMFSession.h>
#import <IMHandle.h>
#import <IMHandleAvailabilityManager.h>
#import <IMHandleRegistrar.h>
#import <IMMessage.h>
#import <IMMessageItem-IMChat_Internal.h>
#import <IMMessageItem.h>
#import <IMNickname.h>
#import <IMNicknameController.h>
#import <IMService.h>
#import <IMTranscriptPluginChatItem.h>

// ShareKit
#import <SKStatusSubscription.h>

@implementation BlueBubblesHelper

static os_log_t logger;
static NetworkController *networkController;
static NSMutableArray* vettedAliases;
static NSMutableDictionary *handleAvailabilityStatuses;

+ (instancetype)sharedInstance {
    static BlueBubblesHelper *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
            logger = os_log_create("BlueBubblesHelper", "helper");
            handleAvailabilityStatuses = [[NSMutableDictionary alloc] init];
        }
    }
    return plugin;
}

/// Class entrypoint
+ (void)load {
    // Create the singleton
    [BlueBubblesHelper sharedInstance];
    
    // Get OS version for debugging purposes
    NSUInteger major = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
    NSUInteger minor = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    os_log(logger, "%{public}@ loaded into %{public}@ on macOS %ld.%ld", [self className], [[NSBundle mainBundle] bundleIdentifier], (long)major, (long)minor);
    
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.MobileSMS"]) {
        // Delay by 5 seconds so the server has a chance to initialize all the socket services
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            os_log(logger, "Injected into iMessage! Connecting to BlueBubbles Server...");
            
            networkController = [NetworkController sharedInstance];
            [networkController connect];
            
            os_log(logger, "Initializing NSNotificationCenter listeners...");
            [[BlueBubblesHelper sharedInstance] addHandleAvailabilityObserver];
            [[BlueBubblesHelper sharedInstance] addFindMyFriendsObserver];
            [[BlueBubblesHelper sharedInstance] addTypingIndicatorObserver];
        });
    } else {
        os_log_error(logger,  "Injected into non-iMessage process %@, aborting.", [[NSBundle mainBundle] bundleIdentifier]);
        return;
    }
}

#pragma mark - Notification Handlers

/// @brief Adds observer for IMHandle availability (focus mode / DND status) using NSNotificationCenter
///
/// @return Sends socket event "focus-status-updated" with data.
///
/// @code
/// {
///     "event": "focus-status-updated",
///     "handle": "<address>",
///     "silenced": "BOOL",
/// }
/// @endcode
- (void) addHandleAvailabilityObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName:@"IMHandleAvailabilityChangedNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        os_log(logger, "Helper caught notification: %@", note.name);
        
        if ([note object] && [[note object] isKindOfClass:NSClassFromString(@"SKStatusSubscription")]) {
            SKStatusSubscription *subscription = (SKStatusSubscription *)[note object];
            
            NSString *contactHandle = [[[subscription ownerHandles] firstObject] handleString];
            NSDictionary *payloadDict = [[[subscription currentStatus] statusPayload] payloadDictionary];
            NSNumber *availabilityValue = payloadDict[@"a"];
            BOOL isFocusModeOn = ![availabilityValue boolValue];
            
            [handleAvailabilityStatuses setValue:@(isFocusModeOn) forKey:contactHandle];
            os_log(logger, "Got focus mode update for handle %@ (%@)", contactHandle, isFocusModeOn ? @"NOT AVAILABLE" : @"AVAILABLE");
            os_log(logger, "Updated focus dict:\r\n%@", handleAvailabilityStatuses);
            
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"focus-status-updated", @"handle": contactHandle, @"silenced": @(isFocusModeOn)}];
        }
    }];
}

/// @brief Adds observer for IMHandle location (FindMy) using NSNotificationCenter
///
/// @return TBD.
///
/// @code
/// {
///
/// }
/// @endcode
- (void) addFindMyFriendsObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName:@"FMFSessionDidUpdateLocationsNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        os_log(logger, "Helper caught notification: %@", note.name);
        

        NSDictionary *userInfo = note.userInfo;
        if (userInfo) {
            // Under the hood, this usually maps to a key named @"locations" containing NSSet/NSArray
            id locations = userInfo[@"locations"];
            os_log(logger, " -> Updated locations payload: %@", locations);
        }
    }];
}

/// @brief Adds observer for chat typing indicators using NSNotificationCenter
///
/// @return Sends socket event "started-typing" or "stopped-typing" with data.
///
/// @code
/// {
///     "event": "started-typing" OR "stopped-typing",
///     "guid": "<chat GUID>",
/// }
/// @endcode
- (void) addTypingIndicatorObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName:@"__kIMChatItemsDidChangeNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        os_log(logger, "Helper caught notification: %@", note.name);
        
        IMChat *chat = (IMChat *)note.object;
            
        if ([[chat lastIncomingMessage] isTypingMessage]) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": [chat guid]}];
            os_log(logger, "%{public}@ started typing in %@", [[chat lastIncomingMessage] senderName], [chat guid]);
        } else {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": [chat guid]}];
            os_log(logger, "%{public}@ stopped typing in %@", [[chat lastIncomingMessage] senderName], [chat guid]);
        }
    }];
}

// try IMAccountAliasesChangedNotification and IMAccountAliasValidationStatusChangedNotification later

#pragma mark - Find Chat / Message Objects

/// @brief Retreives a IMChat instance from a given guid
/// @param guid chat GUID
/// @param transaction transaction ID
/// @return IMChat instance
///
/// Uses the chat registry to get an existing instance of a chat based on the chat guid
- (IMChat *)getIMChatFromGuid:(NSString *)guid transaction:(NSString *)transaction {
    if (guid == nil) {
        [NSException raise:@"MissingValueException" format:@"Provide a chat GUID!"];
    }
    
    IMChat* imChat = [[IMChatRegistry sharedInstance] existingChatWithGUID: guid];
    
    if (imChat == nil) {
        [NSException raise:@"MissingChatException" format:@"Chat does not exist in IMChatRegistry!"];
    }
    return imChat;
}

/// Retreives a CKConversation instance from a given guid
/// @param guid chat GUID
/// @param transaction transaction ID
/// @return CKConversation instance
///
/// Uses the chat-kit conversation list to get an existing instance of a chat based on the chat guid
- (CKConversation *)getCKConversationFromGuid:(NSString *)guid transaction:(NSString *)transaction {
    if (guid == nil) {
        [NSException raise:@"MissingValueException" format:@"Provide a chat GUID!"];
    }
    
    // necessary due to runtime checking (CKConversationList not loaded at time of dylib load)
    Class CKConversationListClass = NSClassFromString(@"CKConversationList");
    id list = [CKConversationListClass performSelector:@selector(sharedConversationList)];
    CKConversation* ckConversation = [list conversationForExistingChatWithGUID: guid];
    
    if (ckConversation == nil) {
        [NSException raise:@"MissingChatException" format:@"Chat does not exist in CKConversationList!"];
    }
    return ckConversation;
}

/// Retreive a CKChatController instance from a given CKConversation
/// @param transaction transaction ID
/// @return CKChatController instance
- (CKChatController *)getCKChatControllerFromConversation:(CKConversation *)conversation transaction:(NSString *)transaction {
    Class CKChatControllerClass = NSClassFromString(@"CKChatController");
    if (CKChatControllerClass == Nil) {
        [NSException raise:@"UnsupportedChatKitException" format:@"CKChatController is unavailable on this version of macOS!"];
    }
    CKChatController* chatController = [[CKChatControllerClass alloc] initWithConversation: conversation];
    
    if (chatController == nil) {
        [NSException raise:NSGenericException format:@"Unable to create CKChatController!"];
    }
    return chatController;
}

/// Retrieve an IMMessage instance from a given message guid
/// @param guid message GUID
/// @param block block which will complete with the IMMessage
/// @return IMMessage instance
- (void)getIMMessageFromGuid:(NSString *)guid completionBlock:(void (^)(IMMessage *message))block {
    [[IMChatHistoryController sharedInstance] loadMessageWithGUID:(guid) completionBlock:^(IMMessage *message) {
        os_log(logger, "Got message with guid %{public}@", guid);
        block(message);
    }];
}

/// Retrieve an IMMessagePartChatItem instance from a given message guid
/// @param guid message GUID
/// @param partIndex index [0, ...] of the message item in the message parts
/// @param block block which will complete with the IMMessage
/// @return IMMessagePartChatItem instance
- (void)getIMMessagePartChatItemFromGuid:(NSString *)guid atPartIndex:(NSUInteger)partIndex completionBlock:(void (^)(IMMessagePartChatItem *messageItem))block {
    [[IMChatHistoryController sharedInstance] loadMessageWithGUID:(guid) completionBlock:^(IMMessage *message) {
        os_log(logger, "Got message with guid %{public}@", guid);
        IMMessageItem *imMessageItem = message._imMessageItem;
        os_log(logger, "Got IMMessageItem for IMMessage: %@", imMessageItem);
        // This can be an array, or a singular IMMessagePartChatItem
        NSObject *chatItems = imMessageItem._newChatItems;
        os_log(logger, "Got IMMessagePartChatItem(s) for IMMessageItem: %@", chatItems);
        IMMessagePartChatItem *chatItem;
        
        if ([chatItems isKindOfClass:[NSArray class]]) {
            NSUInteger arrayCount = [(NSArray *)chatItems count] - 1;
            // usually indicates a photo gallery (IMAggregateAttachmentMessagePartChatItem) which is a single
            // message item but has the subparts within the class
            if (partIndex > arrayCount) {
                os_log(logger, "Part index greater than items in array, checking if type is IMAggregateAttachmentMessage");
                // Only available on macOS 12+, use reference to class loaded at runtime to avoid crashes on macOS 11
                Class cls = NSClassFromString(@"IMAggregateAttachmentMessagePartChatItem");
                if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion > 11 && [[(NSArray *)chatItems firstObject] isKindOfClass:cls]) {
                    IMAggregateAttachmentMessagePartChatItem *aggregate = [(NSArray *)chatItems firstObject];
                    chatItem = [[aggregate aggregateAttachmentParts] objectAtIndex:partIndex];
                    os_log(logger, "Found IMAggregateAttachmentMessage, extracted chat item from subparts!");
                } else {
                    [NSException raise:@"InvalidValueException" format:@"Part index is greater than number of parts in the message!"];
                }
            } else {
                chatItem = [(NSArray *)chatItems objectAtIndex:partIndex];
            }
        } else {
            chatItem = (IMMessagePartChatItem *)chatItems;
        }
        os_log(logger, "Extracted IMMessagePartChatItem at partIndex: %@", chatItem);
        block(chatItem);
    }];
}

#pragma mark - Chat Actions

/// @brief Set the user's typing status on a chat
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "start-typing" OR "stop-typing",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
- (void)handleTypingIndicatorForChat:(NSString *)chatGuid isTyping:(BOOL)isTyping transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction:transaction];
    
    [chat setLocalUserIsTyping:isTyping];
    os_log(logger, "Set local user is typing %d on chat %@", isTyping, chatGuid);
    
    [networkController sendMessage: @{@"transactionId": transaction}];
}

/// @brief Get the typing status of a chat
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "check-typing-status",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "event": "started-typing" OR "stopped-typing"
///     "guid": "<chat GUID>",
/// }
/// @endcode
- (void)checkTypingIndicatorForChat:(NSString *)chatGuid transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction:transaction];
    
    NSString *event = chat.lastIncomingMessage.isTypingMessage == YES ? @"started-typing" : @"stopped-typing";
    
    [networkController sendMessage: @{@"event": event, @"guid": chatGuid}];
}

/// @brief Mark a chat read or unread. Marking unread requires macOS 13+
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "mark-chat-read" OR "mark-chat-unread",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
- (void)handleReadStatusForChat:(NSString *)chatGuid isRead:(BOOL)isRead transaction:(NSString *)transaction {
    CKConversation *conversation = [self getCKConversationFromGuid:chatGuid transaction:transaction];
    
    if (isRead) {
        [conversation markAllMessagesAsRead];
    } else {
        if (@available(macOS 13.0, *)) {
            [conversation markLastMessageAsUnread];
        } else {
            [NSException raise:@"IllegalCommandException" format:@"Marking chats unread requires macOS 13+"];
        }
    }
    
    os_log(logger, "Set chat read status %d on chat %@", isRead, chatGuid);
    
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

/// @brief Set display name / title of a chat (notifies other participants in the chat)
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "set-display-name",
///     "data": {
///         "chatGuid": "<chat GUID>",
///         "newName": "<new name>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
- (void)setDisplayNameForChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    NSString *newName = data[@"newName"];
    
    if (newName == nil) {
        [NSException raise:@"MissingValueException" format:@"Provide a new name for the chat! (newName parameter)"];
    }
    
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction:transaction];
    [chat _setDisplayName:newName];
    
    os_log(logger, "Set new display name '%@' on chat %@", newName, chatGuid);
    
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

/// @brief Add/remove participants from a chat (notifies other participants in the chat)
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "add-participant" OR "remove-participant",
///     "data": {
///         "chatGuid": "<chat GUID>",
///         "address": "<address (e164)>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
- (void)updateParticipantsForChat:(NSString *)chatGuid address:(NSString *)address isAdding:(BOOL)isAdding transaction:(NSString *)transaction {
    if (address == nil) {
        [NSException raise:@"MissingValueException" format:@"Provide an address! (address parameter)"];
    }
    
    CKConversation *chat = [self getCKConversationFromGuid:chatGuid transaction:transaction];
    
    if (isAdding && !chat.canInsertMoreRecipients) {
        [NSException raise:NSGenericException format:@"Cannot add more recipients to the chat!"];
    } else if (!isAdding && chat.recipients.count == 1) {
        [NSException raise:@"MissingValueException" format:@"Cannot remove recipients from the chat!"];
    }
    
    IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(address)];
    
    if (handle == nil) {
        [NSException raise:NSGenericException format:@"Failed to find handle for provided address!"];
    }
    
    if (isAdding) {
        [chat addRecipientHandles:(@[handle])];
    } else {
        [chat removeRecipientHandles:(@[handle])];
    }
    
    os_log(logger, "%@ participant '%@' to chat %{public}@", isAdding ? @"Added" : @"Removed", chatGuid, address);
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

/// @brief Change/remove group photo for a chat (notifies other participants in the chat).
/// To remove the photo, do not pass the "filePath" parameter.
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "update-group-photo",
///     "data": {
///         "chatGuid": "<chat GUID>",
///         "filePath": "<file path>" (OPTIONAL),
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)updateGroupPhotoForChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction:transaction];
    
    if (data[@"filePath"] && data[@"filePath"] != [NSNull null]) {
        NSString *filePath = data[@"filePath"];
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];

        Class CKMediaObjectManagerClass = NSClassFromString(@"CKMediaObjectManager");
        if (CKMediaObjectManagerClass == Nil) {
            [NSException raise:@"UnsupportedChatKitException" format:@"CKMediaObjectManager is unavailable on this version of macOS!"];
        }
        CKMediaObject *mediaObject = [[CKMediaObjectManagerClass sharedInstance] mediaObjectWithFileURL:fileUrl filename:nil transcoderUserInfo:nil];
        [chat sendGroupPhotoUpdate:([mediaObject transferGUID])];
    } else {
        [chat sendGroupPhotoUpdate:nil];
    }
    
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

/// @brief Create a chat and send a message. Select service as iMessage or SMS (use iMessage availability endpoint to query)
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "create-chat",
///     "data": {
///         "addresses": ["<str array of addresses (e164)>"],
///         "service": "iMessage" OR "SMS",
///         "forceNew": "BOOL (optional)",
///         <see docs for sendMessageToChat for other allowable data>
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// see docs for <sendMessageToChat> for socket response
- (void)createChatWithData:(NSDictionary *)data transaction:(NSString *)transaction {
    NSMutableArray<IMHandle*> *handles = [[NSMutableArray alloc] initWithArray:(@[])];
    NSString *service = data[@"service"];
    
    if (service == nil) {
        [NSException raise:@"MissingValueException" format:@"Provide a service! (service parameter)"];
    }
    if (!data[@"addresses"] || data[@"addresses"] == [NSNull null]) {
        [NSException raise:@"MissingValueException" format:@"Provide a list of addresses! (addresses parameter)"];
    }

    for (NSString* str in data[@"addresses"]) {
        IMHandle *handle;
        if ([service isEqualToString:@"iMessage"]) {
            handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:(str)];
        } else {
            handle = [[[IMAccountController sharedInstance] activeSMSAccount] imHandleWithID:(str)];
        }

        if (handle != nil) {
            [handles addObject:handle];
        } else {
            [NSException raise:NSGenericException format:@"Failed to find handle for provided address!"];
        }
    }
    
    // necessary due to runtime checking (CKConversationList not loaded at time of dylib load)
    Class CKConversationListClass = NSClassFromString(@"CKConversationList");
    id list = [CKConversationListClass performSelector:@selector(sharedConversationList)];
    BOOL forceNew = [data[@"forceNew"] isKindOfClass:[NSNumber class]] && [data[@"forceNew"] boolValue];
    CKConversation *newConvo;

    if (forceNew) {
        IMChatRegistry *chatRegistry = [IMChatRegistry sharedInstance];
        SEL forcedSelector = @selector(_ck_chatForHandles:displayName:lastAddressedHandle:lastAddressedSIMID:joinedChatsOnly:findMatchingNamedGroups:createIfNecessary:);
        NSString *creationToken = [data[@"creationToken"] isKindOfClass:[NSString class]] ? data[@"creationToken"] : nil;

        if (![chatRegistry respondsToSelector:forcedSelector]) {
            [NSException raise:NSGenericException format:@"Forced group creation is not supported by this version of IMCore!"];
        }
        if (creationToken == nil || [creationToken length] == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Forced group creation requires a creation token!"];
        }

        // ChatKit uses displayName as matching metadata here, but does not persist it as the
        // chat's visible display name. Reusing a value can return the same unnamed group, while
        // a fresh creation token forces a distinct group without naming it.
        IMChat *newChat = [chatRegistry _ck_chatForHandles:handles
                                               displayName:creationToken
                                       lastAddressedHandle:nil
                                          lastAddressedSIMID:nil
                                          joinedChatsOnly:NO
                                findMatchingNamedGroups:NO
                                        createIfNecessary:YES];
        if (newChat == nil) {
            [NSException raise:NSGenericException format:@"Failed to create chat!"];
        }

        newConvo = [list conversationForExistingChatWithGUID:[newChat guid]];
    } else {
        newConvo = [list conversationForHandles:handles displayName:nil joinedChatsOnly:FALSE create:TRUE];
    }

    if (newConvo == nil || [newConvo chat] == nil) {
        [NSException raise:NSGenericException format:@"Failed to resolve created chat!"];
    }

    NSString *firstMessage = [data[@"message"] isKindOfClass:[NSString class]] ? data[@"message"] : nil;
    if (firstMessage == nil || [firstMessage length] == 0) {
        [[NetworkController sharedInstance] sendMessage:@{@"transactionId": transaction, @"identifier": [[newConvo chat] guid]}];
        return;
    }
    
    [self sendMessageToChat:nil newConversationObject:newConvo withData:data transaction:transaction];
}

// TODO TEST THIS
/// @brief Delete a chat
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "delete-chat",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)deleteChat:(NSString *)chatGuid transaction:(NSString *)transaction {
    CKConversation *chat = [self getCKConversationFromGuid:chatGuid transaction:transaction];
    
    // necessary due to runtime checking (CKConversationList not loaded at time of dylib load)
    Class CKConversationListClass = NSClassFromString(@"CKConversationList");
    id list = [CKConversationListClass performSelector:@selector(sharedConversationList)];
    [list deleteConversation: chat];
    
    os_log(logger, "Deleted chat %{public}@", chatGuid);
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

/// @brief Leave a group chat
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "leave-chat",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)leaveChat:(NSString *)chatGuid transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid: chatGuid transaction:transaction];
    
    if ([chat respondsToSelector:@selector(leave)]) {
        [chat leave];
        os_log(logger, "Left chat %{public}@ using leave method", chatGuid);
    } else if ([chat respondsToSelector:@selector(leaveiMessageGroup)]) {
        [chat leaveiMessageGroup];
        os_log(logger, "Left chat %{public}@ using leaveiMessageGroup method", chatGuid);
    } else {
        [NSException raise:NSGenericException format:@"Failed to find selector to leave chat!"];
    }
    
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

// TODO TEST THIS
/// @brief Check if nickname sharing should be offered
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "should-offer-nickname-sharing",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
///     "share": <BOOL>
/// }
/// @endcode
- (void)shouldOfferNicknameSharingForChat:(NSString *)chatGuid transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction: transaction];
    
    BOOL offer = [[IMNicknameController sharedInstance] shouldOfferNicknameSharingForChat:chat];
    os_log(logger, "Chat %@ %@ offer to share nickname", chatGuid, offer ? @"should" : @"should not");
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"share": @(offer)}];
}

// TODO TEST THIS
/// @brief Share or deny nickname with chat
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "share-nickname" OR "deny-nickname",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)shareNicknameWithChat:(NSString *)chatGuid allow:(BOOL)allow transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction: transaction];
    
    //    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 11) {
    //        [[IMNicknameController sharedInstance] whitelistHandlesForNicknameSharing:[chat participants] forChat:chat];
    //    } else {
    //    }
    
    if (allow) {
        [[IMNicknameController sharedInstance] allowHandlesForNicknameSharing:[chat participants] forChat:chat];
    } else {
        [[IMNicknameController sharedInstance] denyHandlesForNicknameSharing:[chat participants]];
    }
    
    os_log(logger, "%@ sharing nickname with chat %@", allow ? @"Allowed" : @"Denied", chatGuid);
    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
}

# pragma mark Handle/User Actions

/// @brief Check Focus status for a handle (DND) - requires macOS 12+
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "share-nickname" OR "deny-nickname",
///     "data": {
///         "chatGuid": "<chat GUID>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)checkFocusStatusForHandle:(NSString *)address transaction:(NSString *)transaction {
    if (!@available(macOS 12.0, *)) {
        [NSException raise:@"IllegalCommandException" format:@"Checking focus status requires macOS 12+!"];
    }
    IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:address];
    
    // necessary due to runtime checking (IMHandleAvailabilityManager doesn't exist on Big Sur)
    Class cls = NSClassFromString(@"IMHandleAvailabilityManager");
    id instance = [cls sharedInstance];
    if (handle != nil && cls != nil) {
        // 2 possible selectors, find which one to use
        if ([instance respondsToSelector:@selector(fetchUpdatedStatusForHandle:completion:)]) {
            [instance fetchUpdatedStatusForHandle:(handle) completion:^() {
                [instance availabilityForHandle:(handle)];
                
                // after 5 seconds, the latest status should have populated from NSNotificationCenter
                // this only works on cold start of Messages app, afterwards the notification will populate automatically within
                // ~1-5 minutes of the status being changed
                NSTimeInterval delayInSeconds = 5.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    NSNumber *status = handleAvailabilityStatuses[address];
                    
                    if (status != nil) {
                        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"silenced": status}];
                    } else {
                        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"silenced": @"null"}];
                    }
                });
            }];
        } else {
            [instance _fetchUpdatedStatusForHandle:(handle) completion:^() {
                [instance availabilityForHandle:(handle)];
                
                // after 5 seconds, the latest status should have populated from NSNotificationCenter
                // this only works on cold start of Messages app, afterwards the notification will populate automatically within
                // ~1-5 minutes of the status being changed
                NSTimeInterval delayInSeconds = 5.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    NSNumber *status = handleAvailabilityStatuses[address];
                    
                    if (status != nil) {
                        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"silenced": status}];
                    } else {
                        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"silenced": @"null"}];
                    }
                });
            }];
        }
    }
}

/// @brief Check iMessage or FaceTime availability for a handle address
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "check-imessage-availability" OR "check-facetime-availability",
///     "data": {
///         "address": "<e164 phone number or email>",
///         "aliasType": "phone" OR "email",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "available": 1 OR 0,
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)checkServiceAvailabilityForHandle:(NSString *)address addressType:(NSString *)type event:(NSString *)event transaction:(NSString *)transaction {
    NSString* serviceName;
    if ([event isEqualToString:@"check-imessage-availability"]) {
        serviceName = IDSServiceNameiMessage;
    } else if ([event isEqualToString:@"check-facetime-availability"]) {
        serviceName = IDSServiceNameFaceTime;
    }
    
    IDSDestination *destination;
    if ([type isEqualToString:@"phone"]) {
        destination = IDSCopyIDForPhoneNumber((__bridge CFStringRef) address);
    } else {
        destination = IDSCopyIDForEmailAddress((__bridge CFStringRef) address);
    }
    
    [[IDSIDQueryController sharedInstance] forceRefreshIDStatusForDestinations:(@[destination]) service:(serviceName) listenerID:(@"SOIDSListener-com.apple.imessage-rest") queue:(dispatch_queue_create("HandleIDS", NULL)) completionBlock:^(NSDictionary *response) {
        NSInteger status = [response.allValues.firstObject integerValue];
        BOOL available = status == 1;
        os_log(logger, "%@ for %{public}@ is %{public}ld", event, address, (long)available);
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"available": @(available)}];
    }];
}

/// @brief Get nickname info for handle address
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "get-nickname-info",
///     "data": {
///         "address": "<e164 phone number or email>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "name": "<nickname>",
///     "avatar_path": "<absolute path to user avatar>",
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)getNicknameInfoForHandle:(NSString *)address transaction:(NSString *)transaction {
    NSString *name;
    NSString *avatarPath;
    
    if (address == nil) {
        name = [[[IMNicknameController sharedInstance] personalNickname] displayName];
        avatarPath = [[[[IMNicknameController sharedInstance] personalNickname] avatar] imageFilePath];
    } else {
        IMHandle *handle = [[[IMAccountController sharedInstance] activeIMessageAccount] imHandleWithID:address];
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
}

#pragma mark Account Actions

/// @brief Check if current account is enabled (active, registered, operational, and connected)
///
/// @return TRUE/FALSE.
- (BOOL)isAccountEnabled {
    IMAccount *account = [[IMAccountController sharedInstance] activeIMessageAccount];
    return [account isActive] && [account isRegistered] && [account isOperational] && [account isConnected];
}

/// @brief Get vetted aliases for current account
///
/// @return Arrray of vetted aliases with format below:
///
/// @code
/// {
///     "Alias": "<account alias (phone number or email)>",
/// }
/// @endcode
- (NSMutableArray *)getAliasesWithVettedOnly:(BOOL)vetted {
    if ([self isAccountEnabled]) {
        IMAccount *account = [[IMAccountController sharedInstance] activeIMessageAccount];
        NSArray* aliases = @[];
        if (vetted) {
            aliases = [account vettedAliases];
        } else {
            aliases = [account aliases];
        }
        
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
        os_log_error(logger, "Can't get aliases - account not enabled!");
        return [[NSMutableArray alloc] init];
    }
    return [[NSMutableArray alloc] init];
}

/// @brief Get account info for current account
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "get-account-info",
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// see {data} dictionary below
- (void)getAccountInfoWithTransaction:(NSString *)transaction {
    IMAccountController *controller = [IMAccountController sharedInstance];
    IMAccount *account = [controller activeIMessageAccount];
    IMAccount *smsAccount = [controller activeSMSAccount];
    
    NSDictionary *data = @{
        @"transactionId": transaction,
        @"apple_id": [account strippedLogin] ?: [NSNull null],
        @"account_name": [[account loginIMHandle] fullName] ?: [NSNull null],
        @"sms_forwarding_enabled": [NSNumber numberWithBool:[smsAccount allowsSMSRelay] ?: FALSE],
        @"sms_forwarding_capable": [NSNumber numberWithBool:[smsAccount isSMSRelayCapable] ?: FALSE],
        @"vetted_aliases": [self getAliasesWithVettedOnly:true],
        @"aliases": [self getAliasesWithVettedOnly:false],
        @"login_status_message": [account loginStatusMessage] ?: [NSNull null],
        @"active_alias": [account displayName] ?: [NSNull null]
    };
    [[NetworkController sharedInstance] sendMessage: data];
}

/// @brief Set default alias for account
///
/// @return Sends socket message.
///
/// SOCKET MESSAGE:
/// @code
/// {
///     "action": "modify-active-alias",
///     "data": {
///         "address": "<e164 phone number or email>",
///     },
///     "transactionId": "<transaction ID>",
/// }
/// @endcode
///
/// SOCKET RESPONSE:
/// @code
/// {
///     "transactionId": "<Transaction ID>",
/// }
/// @endcode
- (void)changeActiveAliasToAddress:(NSString *)alias transaction:(NSString *)transaction {
    if ([self isAccountEnabled]) {
        IMAccountController *controller = [IMAccountController sharedInstance];
        IMAccount *account = [controller activeIMessageAccount];
        [account setDisplayName:alias];
        
        os_log(logger, "Set active alias to %@", alias);
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
    } else {
        os_log_error(logger, "Can't set aliases - account not enabled!");
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to modify aliases, account not enabled"}];
    }
}

# pragma mark Message Actions

- (void)sendMessageToChat:(NSString *)chatGuid newConversationObject:(CKConversation *)convo withData:(NSDictionary *)data transaction:(NSString *)transaction {
    Class CKCompositionClass = NSClassFromString(@"CKComposition");
    Class CKMediaObjectManagerClass = NSClassFromString(@"CKMediaObjectManager");
    if (CKCompositionClass == Nil) {
        [NSException raise:@"UnsupportedChatKitException" format:@"CKComposition is unavailable on this version of macOS!"];
    }

    // not creating a new chat (use existing guid)
    if (convo == nil) {
        convo = [self getCKConversationFromGuid:chatGuid transaction:transaction];
    }
    
    // audio messages have a simpler pipeline
    if (data[@"isAudioMessage"] && data[@"isAudioMessage"] != [NSNull null] && [data[@"isAudioMessage"] integerValue] == 1) {
        if (CKMediaObjectManagerClass == Nil) {
            [NSException raise:@"UnsupportedChatKitException" format:@"CKMediaObjectManager is unavailable on this version of macOS!"];
        }
        NSString *filePath = data[@"filePath"];
        NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
        
        CKMediaObject *mediaObject = [[CKMediaObjectManagerClass sharedInstance] mediaObjectWithFileURL:fileUrl filename:nil transcoderUserInfo:nil];
        CKComposition* composition = [CKCompositionClass audioCompositionWithMediaObject:mediaObject];
        IMMessage* newMessage = [convo messageWithComposition:composition];
        [convo sendMessage:newMessage newComposition:YES];
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [newMessage guid]}];
        return;
    }
    
    // add subject, if needed
    NSAttributedString *subjectAttributedString = nil;
    if (data[@"subject"] && data[@"subject"] != [NSNull null] && [data[@"subject"] length] != 0) {
        subjectAttributedString = [[NSAttributedString alloc] initWithString: data[@"subject"]];
    }
    
    // initialize with an empty string (helps for multipart messages)
    CKComposition *composition = [[CKCompositionClass alloc] initWithText:[[NSAttributedString alloc] initWithString:@""] subject:subjectAttributedString];
    
    if (data[@"parts"] && data[@"parts"] != [NSNull null]) {
        // if multipart, add the parts in the specified order
        for (NSDictionary *dict in data[@"parts"]) {
            if (dict[@"filePath"] != [NSNull null] && [dict[@"filePath"] length] != 0) {
                if (CKMediaObjectManagerClass == Nil) {
                    [NSException raise:@"UnsupportedChatKitException" format:@"CKMediaObjectManager is unavailable on this version of macOS!"];
                }
                // add attachemnt objects
                NSString *filePath = dict[@"filePath"];
                NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
                CKMediaObject *mediaObject = [[CKMediaObjectManagerClass sharedInstance] mediaObjectWithFileURL:fileUrl filename:nil transcoderUserInfo:nil];
                
                composition = [composition compositionByAppendingMediaObject:mediaObject];
            } else {
                // add text objects (with mentions if needed)
                NSMutableAttributedString *messageStr = [[NSMutableAttributedString alloc] initWithString: dict[@"text"]];
                if (dict[@"mention"] != [NSNull null] && [dict[@"mention"] length] != 0) {
                    [messageStr addAttributes:@{
                        @"__kIMMentionConfirmedMention": dict[@"mention"],
                    } range:NSMakeRange(0, [[messageStr string] length])];
                }
                // TODO probably need to combine back-to-back attributed strings into one, cannot append
                composition = [composition compositionByAppendingText:[messageStr copy]];
            }
        }
    } else {
        // if normal message, attachments should appear before the message string
        if (data[@"filePath"] && data[@"filePath"] != [NSNull null]) {
            if (CKMediaObjectManagerClass == Nil) {
                [NSException raise:@"UnsupportedChatKitException" format:@"CKMediaObjectManager is unavailable on this version of macOS!"];
            }
            NSString *filePath = data[@"filePath"];
            NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
            CKMediaObject *mediaObject = [[CKMediaObjectManagerClass sharedInstance] mediaObjectWithFileURL:fileUrl filename:nil transcoderUserInfo:nil];
            
            composition = [composition compositionByAppendingMediaObject:mediaObject];
        }
        
        // Attachments will not have the message parameter provided, so set an empty string
        NSString *message = (data[@"message"] && data[@"message"] != [NSNull null]) ? data[@"message"] : @"";
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: message];
        composition = [composition compositionByAppendingText:attributedString];
    }
    
    // Effects
    if (data[@"effectId"] && data[@"effectId"] != [NSNull null] && [data[@"effectId"] length] != 0) {
        [composition setExpressiveSendStyleID:data[@"effectId"]];
    }
    
    IMMessage* newMessage = [convo messageWithComposition:composition];
    
    // Replies (macOS 13+)
    // TODO FIX ISSUE OF REPLYING TO EXISTING THREAD ON MULTIPART MSG SHOWS ON THE FIRST PART NOT ON THE SPECIFIED ONE
    if (data[@"selectedMessageGuid"] && data[@"selectedMessageGuid"] != [NSNull null]) {
        [self getIMMessagePartChatItemFromGuid:data[@"selectedMessageGuid"] atPartIndex:[data[@"partIndex"] unsignedIntValue] completionBlock:^(IMMessagePartChatItem *chatItem) {
            NSString *identifier;
            IMMessage *originator;
            // if an existing thread exists, use it's thread identifier, otherwise create a new one
            if (chatItem.threadIdentifier != nil) {
                identifier = chatItem.threadIdentifier;
                originator = [chatItem.threadOriginator message];
            } else if (chatItem != nil) {
                identifier = IMCreateThreadIdentifierForMessagePartChatItem(chatItem);
                originator = [chatItem message];
            }
            
            os_log(logger, "Got thread identifier: %@\r\nthread originator: %@", identifier, originator);
            
            newMessage.threadIdentifier = identifier;
            newMessage.threadOriginator = originator;
            
            [convo sendMessage:newMessage newComposition:YES];
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [newMessage guid]}];
        }];
    // Normal message
    } else {
        [convo sendMessage:newMessage newComposition:YES];
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [newMessage guid]}];
    }
}

- (void)sendTapbackToChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction:transaction];
    
    if (chat != nil) {
        [self getIMMessagePartChatItemFromGuid:data[@"selectedMessageGuid"] atPartIndex:[data[@"partIndex"] unsignedIntValue] completionBlock:^(IMMessagePartChatItem *chatItem) {
            // make a "fake" CKChatItem so the [chat sendTapback] or [chat sendMessageAcknowledgment] selectors can be used
            Class CKChatItemClass = NSClassFromString(@"CKChatItem");
            if (CKChatItemClass == Nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"UnsupportedChatKitException", @"reason": @"CKChatItem is unavailable on this version of macOS!"}];
                return;
            }
            CKChatItem *ckChatItem = nil;
            if ([CKChatItemClass respondsToSelector:@selector(chatItemWithIMChatItem:balloonMaxWidth:)]) {
                ckChatItem = [CKChatItemClass chatItemWithIMChatItem:chatItem balloonMaxWidth:100];
            } else {
                ckChatItem = [CKChatItemClass chatItemWithIMChatItem:chatItem balloonMaxWidth:100 fullMaxWidth:100 transcriptTraitCollection:nil overlayLayout:FALSE];
            }

            // emoji tapbacks (macOS 26+)
            if ([data[@"reactionType"] containsString:@"emoji"]) {
                // necessary due to runtime checking (IMEmojiTapback only exists on macOS 26+)
                Class IMEmojiTapbackClass = NSClassFromString(@"IMEmojiTapback");
                id instance = [IMEmojiTapbackClass alloc];
                id tapback = [instance initWithEmoji:data[@"reactionEmoji"] isRemoved:[data[@"reactionType"] containsString:@"-"]];
                [chat sendTapback:tapback forChatItem:ckChatItem];
            // normal tapbacks
            } else {
                long long reactionLong = [self parseReactionType:data[@"reactionType"]];
                [chat sendMessageAcknowledgment:reactionLong forChatItem:ckChatItem];
            }
            
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastSentMessage] guid]}];
        }];
    }
}

- (void)editMessageInChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    [self getIMMessageFromGuid:data[@"messageGuid"] completionBlock:^(IMMessage *message) {
        IMMessageItem *imMessageItem = message._imMessageItem;

        NSAttributedString *editedString = [[NSAttributedString alloc] initWithString: data[@"editedMessage"]];
        NSInteger partIndex = [data[@"partIndex"] integerValue];
        Class CKCompositionClass = NSClassFromString(@"CKComposition");
        if (CKCompositionClass == Nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"UnsupportedChatKitException", @"reason": @"CKComposition is unavailable on this version of macOS!"}];
            return;
        }
        CKComposition* composition = [[CKCompositionClass alloc] initWithText:editedString subject:nil];
        
        CKConversation* convo = [self getCKConversationFromGuid:chatGuid transaction:transaction];
        if (convo != nil) {
            if ([convo respondsToSelector:@selector(editMessageItem:partIndex:withNewComposition:)]) {
                [convo editMessageItem:imMessageItem partIndex:partIndex withNewComposition:composition];
            } else {
                [convo editMessage:message partIndex:partIndex withNewComposition:composition];
            }
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    }];
}

- (void)unsendMessageInChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    [self getIMMessagePartChatItemFromGuid:data[@"messageGuid"] atPartIndex:[data[@"partIndex"] unsignedIntValue] completionBlock:^(IMMessagePartChatItem *chatItem) {
        CKConversation* convo = [self getCKConversationFromGuid:chatGuid transaction:transaction];
        if (convo != nil) {
            [convo retractMessagePart:chatItem];
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    }];
}

// TODO TEST THIS
- (void)forceNotifyMessageInChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    IMChat *chat = [self getIMChatFromGuid:chatGuid transaction:transaction];
    
    if (chat != nil) {
        [self getIMMessagePartChatItemFromGuid:data[@"messageGuid"] atPartIndex:0 completionBlock:^(IMMessagePartChatItem *chatItem) {
            [chat markChatItemAsNotifyRecipient:chatItem];
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }];
    }
}

// TODO TEST THIS
- (void)deleteMessageInChat:(NSString *)chatGuid withData:(NSDictionary *)data transaction:(NSString *)transaction {
    [self getIMMessageFromGuid:data[@"messageGuid"] completionBlock:^(IMMessage *message) {
        CKConversation *convo = [self getCKConversationFromGuid:chatGuid transaction:transaction];
        CKChatController *controller = [self getCKChatControllerFromConversation:convo transaction:transaction];
        
        IMMessageItem *imMessageItem = message._imMessageItem;
        // This can be an array, or a singular IMMessagePartChatItem
        NSObject *chatItems = imMessageItem._newChatItems;
        
        if ([chatItems isKindOfClass:[NSArray class]]) {
            for (NSObject *chatItem in (NSArray *)chatItems) {
                [controller deleteChatItem:chatItem];
            }
        } else {
            [controller deleteChatItem:chatItems];
        }
        
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
    }];
}

- (void)searchMessagesWithQuery:(NSString *)searchQuery matchType:(NSString *)matchType transaction:(NSString *)transaction {
    // c -> Performs a case-insensitive search.
    // d -> Performs a search that ignores diacritical marks.
    // w -> Matches on word boundaries. This modifier treats transitions from lowercase to uppercase as word boundaries.
    // t -> Performs a search on a tokenized value. For example, a search field can contain tokenized values.
    NSString *queryString = [NSString stringWithFormat:@"kMDItemTextContent=\"%@\"cwdt", searchQuery];
    
    // When "t" is used, the tokens do not need to match the order provided.
    // That's why when the matchType is exact, we exclude it.
    // I'm not sure how to do a true exact match query.
    if ([matchType isEqualToString:@"exact"]) {
        queryString = [NSString stringWithFormat:@"kMDItemTextContent=\"%@\"cwd", searchQuery];
    }
    
    if (!@available(macOS 13.0, *)) {
        os_log_error(logger, "Message searching is not supported before macOS 13.0!");
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Message searching is not supported before macOS 13"}];
        return;
    }
    
    CSSearchQueryContext *queryContext = [[CSSearchQueryContext alloc] init];
    // attributes.uniqueIdentifier -> Message GUID
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
            os_log_error(logger, "Message search error: %@", error.localizedDescription);
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": error.localizedDescription}];
        } else {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"results": results}];
        }
    };
    
    [query start];
}

// TODO TEST THIS
- (void)downloadPurgedAttachment:(NSString *)attachmentGuid transaction:(NSString *)transaction {
    IMFileTransfer* transfer = [[IMFileTransferCenter sharedInstance] transferForGUID:attachmentGuid];
    
    if ([transfer transferState] != 0 || ![transfer isIncoming]) {
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"No need to unpurge!"}];
    } else {
        [[IMFileTransferCenter sharedInstance] registerTransferWithDaemon:[transfer guid]];
        [[IMFileTransferCenter sharedInstance] acceptTransfer:[transfer guid]];
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
    }
}

// TODO TEST THIS
- (void)getBalloonBundleMediaPathForMessage:(NSString *)messageGuid transaction:(NSString *)transaction {
    [self getIMMessagePartChatItemFromGuid:messageGuid atPartIndex:0 completionBlock:^(IMMessagePartChatItem *chatItem) {
        // balloon items will only be an IMTranscriptPluginChatItem
        if ([chatItem isKindOfClass:[IMTranscriptPluginChatItem class]]) {
            NSObject *dataSource = [(IMTranscriptPluginChatItem *)chatItem dataSource];
            // The data source is this weird class, no idea what framework its from. Class methods dumped via _methodDescription on cls
            Class digitalTouchClass = NSClassFromString(@"ETiOSMacBalloonPluginDataSource");
            Class handwrittenClass = NSClassFromString(@"HWiOSMacBalloonDataSource");
            if ([dataSource isKindOfClass:digitalTouchClass]) {
                ETiOSMacBalloonPluginDataSource *digitalTouch = (ETiOSMacBalloonPluginDataSource *)dataSource;
                // Force iMessage to generate the .mov and return the path
                [digitalTouch generateMedia:^() {
                    NSString *path = [(NSURL *)[digitalTouch assetURL] absoluteString];
                    os_log(logger, "Digital Touch generated at path: %@", path);
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"path": path}];
                }];
            } else if ([dataSource isKindOfClass:handwrittenClass]) {
                HWiOSMacBalloonDataSource *digitalTouch = (HWiOSMacBalloonDataSource *)dataSource;
                CGSize size = [digitalTouch sizeThatFits:CGSizeMake(300, 300)];
                [digitalTouch generateImageForSize:size completionHandler:^(NSObject *url) {
                    NSString *path = [(NSURL *)url absoluteString];
                    os_log(logger, "Handwritten Message generated at path: %@", path);
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"path": path}];
                }];
            }
        }
    }];
}

# pragma mark Helpers

-(void) handleServerEvent: (NSString*)event data: (NSDictionary*)data transactionId: (NSString*)transaction {
    if (data == nil) {
        data = [[NSDictionary alloc] init];
    }
    NSString *chatGuid = data[@"chatGuid"];
    NSString *handle = data[@"address"];
    
    if (transaction == nil) {
        os_log_error(logger, "[WARNING] No transaction ID provided! Creating empty transaction...");
        transaction = @"";
    }
    
    if ([event isEqualToString:@"start-typing"]) {
        [self handleTypingIndicatorForChat:chatGuid isTyping:YES transaction:transaction];
    } else if ([event isEqualToString:@"stop-typing"]) {
        [self handleTypingIndicatorForChat:chatGuid isTyping:NO transaction:transaction];
    } else if ([event isEqualToString:@"check-typing-status"]) {
        [self checkTypingIndicatorForChat:chatGuid transaction:transaction];
    } else if ([event isEqualToString:@"mark-chat-read"]) {
        [self handleReadStatusForChat:chatGuid isRead:YES transaction:transaction];
    } else if ([event isEqualToString:@"mark-chat-unread"]) {
        [self handleReadStatusForChat:chatGuid isRead:NO transaction:transaction];
    } else if ([event isEqualToString:@"set-display-name"]) {
        [self setDisplayNameForChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"update-group-photo"]) {
        [self updateGroupPhotoForChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"add-participant"]) {
        [self updateParticipantsForChat:chatGuid address:handle isAdding:YES transaction:transaction];
    } else if ([event isEqualToString:@"remove-participant"]) {
        [self updateParticipantsForChat:chatGuid address:handle isAdding:NO transaction:transaction];
    } else if ([event isEqualToString:@"create-chat"]) {
        [self createChatWithData:data transaction:transaction];
    } else if ([event isEqualToString:@"delete-chat"]) {
        [self deleteChat:chatGuid transaction:transaction];
    } else if ([event isEqualToString:@"leave-chat"]) {
        [self leaveChat:chatGuid transaction:transaction];
    } else if ([event isEqualToString:@"check-focus-status"]) {
        [self checkFocusStatusForHandle:handle transaction:transaction];
    } else if ([event isEqualToString:@"check-imessage-availability"] || [event isEqualToString:@"check-facetime-availability"]) {
        [self checkServiceAvailabilityForHandle:handle addressType:data[@"aliasType"] event:event transaction:transaction];
    } else if ([event isEqualToString:@"get-nickname-info"]) {
        [self getNicknameInfoForHandle:handle transaction:transaction];
    } else if ([event isEqualToString:@"should-offer-nickname-sharing"]) {
        [self shouldOfferNicknameSharingForChat:chatGuid transaction:transaction];
    } else if ([event isEqualToString:@"share-nickname"]) {
        [self shareNicknameWithChat:chatGuid allow:YES transaction:transaction];
    } else if ([event isEqualToString:@"deny-nickname"]) {
        [self shareNicknameWithChat:chatGuid allow:NO transaction:transaction];
    } else if ([event isEqualToString:@"get-account-info"]) {
        [self getAccountInfoWithTransaction:transaction];
    } else if ([event isEqualToString:@"modify-active-alias"]) {
        [self changeActiveAliasToAddress:data[@"alias"] transaction:transaction];
    } else if ([event isEqualToString:@"send-message"] || [event isEqualToString:@"send-attachment"] || [event isEqualToString:@"send-multipart"]) {
        [self sendMessageToChat:chatGuid newConversationObject:nil withData:data transaction:transaction];
    } else if ([event isEqualToString:@"send-reaction"]) {
        [self sendTapbackToChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"edit-message"]) {
        [self editMessageInChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"unsend-message"]) {
        [self unsendMessageInChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"notify-anyway"]) {
        [self forceNotifyMessageInChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"delete-message"]) {
        [self deleteMessageInChat:chatGuid withData:data transaction:transaction];
    } else if ([event isEqualToString:@"download-purged-attachment"]) {
        [self downloadPurgedAttachment:data[@"attachmentGuid"] transaction:transaction];
    } else if ([event isEqualToString:@"balloon-bundle-media-path"]) {
        [self getBalloonBundleMediaPathForMessage:data[@"messageGuid"] transaction:transaction];
    } else if ([event isEqualToString:@"search-messages"]) {
        [self searchMessagesWithQuery:data[@"query"] matchType:data[@"matchType"] transaction:transaction];
    }
    
    if ([event isEqualToString:@"refresh-findmy-friends"]) {
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
                NSInteger type = ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) ? 0 : [location locationType];
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
    } else {
        DLog("BLUEBUBBLESHELPER: Not implemented %{public}@", event);
    }

}

-(long long) parseReactionType:(NSString *)reactionType {
    NSString *lowerCaseType = [reactionType lowercaseString];

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

// Apply text formatting ranges to an attributed string created from the message body.
+(NSMutableAttributedString *) applyTextFormatting:(NSArray *)formatting toMessage:(NSString *)message {
    if (message == nil || message == (id)[NSNull null]) return nil;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: message];
    NSUInteger messageLength = [message length];

    // Text formatting attributes only available on macOS 15 (Sequoia) and later
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 15) {
        return attributedString;
    }
    
    if (messageLength == 0 || formatting == nil || ![formatting isKindOfClass:[NSArray class]] || [formatting count] == 0) {
        return attributedString;
    }

    // Always include the message part attribute across the entire string.
    [attributedString addAttributes:@{
        @"__kIMMessagePartAttributeName": @0
    } range:NSMakeRange(0, messageLength)];

    for (NSDictionary *rangeDict in formatting) {
        if (![rangeDict isKindOfClass:[NSDictionary class]]) continue;
        NSNumber *startNum = rangeDict[@"start"];
        NSNumber *lengthNum = rangeDict[@"length"];
        NSArray *styles = rangeDict[@"styles"];
        if (startNum == nil || lengthNum == nil || ![styles isKindOfClass:[NSArray class]]) continue;

        NSInteger start = [startNum integerValue];
        NSInteger length = [lengthNum integerValue];
        if (start < 0 || length <= 0) continue;
        if ((NSUInteger)(start + length) > messageLength) continue;

        NSRange range = NSMakeRange((NSUInteger)start, (NSUInteger)length);
        if ([styles containsObject:@"bold"]) {
            [attributedString addAttribute:@"__kIMTextBoldAttributeName" value:@1 range:range];
        }
        if ([styles containsObject:@"italic"]) {
            [attributedString addAttribute:@"__kIMTextItalicAttributeName" value:@1 range:range];
        }
        if ([styles containsObject:@"underline"]) {
            [attributedString addAttribute:@"__kIMTextUnderlineAttributeName" value:@1 range:range];
        }
        if ([styles containsObject:@"strikethrough"]) {
            [attributedString addAttribute:@"__kIMTextStrikethroughAttributeName" value:@1 range:range];
        }
    }

    return attributedString;
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
        NSInteger type = ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 13) ? 0 : [location locationType];
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
