// Headers generated with ktool v2.0.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.5.0 | SDK: 16.5.0


#ifndef CKCONVERSATION_H
#define CKCONVERSATION_H

@class CNGroupIdentity, NSNumber, IMHandle, IMChat, NSString, NSDate, NSArray, NSAttributedString, NSSet, IMService;
@protocol NSItemProviderWriting;

#import "CKEntity.h"
#import "CKComposition.h"

@interface CKConversation : NSObject


@property (retain, nonatomic) CNGroupIdentity *_conversationVisualIdentity; // ivar: __conversationVisualIdentity
@property (nonatomic) BOOL allowedByPersonListInActiveFocus; // ivar: _allowedByPersonListInActiveFocus
@property (retain, nonatomic) NSNumber *businessConversation; // ivar: _businessConversation
@property (retain, nonatomic) IMHandle *businessHandle; // ivar: _businessHandle
@property (readonly, nonatomic) char buttonColor;
@property (readonly, nonatomic) BOOL canLeave;
@property (retain, nonatomic) IMChat *chat; // ivar: _chat
@property (retain, nonatomic) NSString *conversationListCollectionViewJunkItemIdentifier; // ivar: _conversationListCollectionViewJunkItemIdentifier
@property (retain, nonatomic) NSString *conversationListCollectionViewListItemIdentifier; // ivar: _conversationListCollectionViewListItemIdentifier
@property (retain, nonatomic) NSString *conversationListCollectionViewPinnedItemIdentifier; // ivar: _conversationListCollectionViewPinnedItemIdentifier
@property (retain, nonatomic) NSString *conversationListCollectionViewRecentlyDeletedListItemIdentifier; // ivar: _conversationListCollectionViewRecentlyDeletedListItemIdentifier
@property (retain, nonatomic) NSDate *dateLastViewed; // ivar: _dateLastViewed
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly, nonatomic) NSString *deviceIndependentID;
@property (readonly, nonatomic) NSUInteger disclosureAtomStyle;
@property (retain, nonatomic) NSString *displayName;
@property (nonatomic) BOOL forceMMS;
@property (readonly, nonatomic) NSArray *frequentReplies;
@property (readonly, nonatomic, getter=isGroupConversation) BOOL groupConversation;
@property (readonly, nonatomic) NSString *groupID;
@property (retain, nonatomic) NSString *groupIdentityUpdateHandleID; // ivar: _groupIdentityUpdateHandleID
@property (readonly, nonatomic) NSAttributedString *groupName; // ivar: _groupName
@property (readonly, nonatomic) NSArray *handles;
@property (readonly, nonatomic) BOOL hasDisplayName;
@property (nonatomic) BOOL hasLoadedAllMessages; // ivar: _hasLoadedAllMessages
@property (nonatomic) BOOL hasSetWasKnownSender; // ivar: _hasSetWasKnownSender
@property (readonly, nonatomic) BOOL hasUnreadMessages;
@property (readonly) NSUInteger hash;
@property (nonatomic, getter=shouldHoldInUnreadFilter) BOOL holdInUnreadFilter; // ivar: _holdInUnreadFilter
@property (nonatomic, getter=isIgnoringTypingUpdates) BOOL ignoringTypingUpdates;
@property (readonly, nonatomic) BOOL isPinned;
@property (readonly, nonatomic) BOOL isPreviewTextForAttachment;
@property (nonatomic) BOOL isReportedAsSpam; // ivar: _isReportedAsSpam
@property (readonly, nonatomic) BOOL isToEmailAddress;
@property (readonly, nonatomic) NSString *lastAddressedHandle;
@property (readonly, nonatomic) NSString *lastAddressedSIMID;
@property (readonly, nonatomic, getter=hasLeft) BOOL left;
@property (readonly, nonatomic, getter=hasLeftGroupChat) BOOL leftGroupChat;
@property (nonatomic) unsigned int limitToLoad; // ivar: _limitToLoad
@property (copy, nonatomic) NSString *localUserIsComposing;
@property (nonatomic) BOOL localUserIsRecording;
@property (nonatomic) BOOL localUserIsTyping;
@property (readonly, nonatomic) NSSet *mergedPinningIdentifiers;
@property (readonly, nonatomic, getter=isMuted) BOOL muted;
@property (retain, nonatomic) NSString *name; // ivar: _name
@property (readonly, nonatomic) BOOL needsReload; // ivar: _needsReload
@property (nonatomic) BOOL needsUpdatedContactsForVisualIdentity; // ivar: _needsUpdatedContactsForVisualIdentity
@property (nonatomic) BOOL needsUpdatedGroupNameForVisualIdentity; // ivar: _needsUpdatedGroupNameForVisualIdentity
@property (nonatomic) BOOL needsUpdatedGroupPhotoForVisualIdentity; // ivar: _needsUpdatedGroupPhotoForVisualIdentity
@property (readonly, nonatomic, getter=isPending) BOOL pending;
@property (readonly, copy, nonatomic) NSArray *pendingEntities;
@property (copy, nonatomic) NSArray *pendingHandles; // ivar: _pendingHandles
@property (retain, nonatomic) NSSet *pendingRecipients; // ivar: _pendingRecipients
@property (readonly, nonatomic) NSString *pinningIdentifier;
@property (copy, nonatomic) NSAttributedString *previewText; // ivar: _previewText
@property (readonly, nonatomic) NSString *rawAddressedName;
@property (readonly, nonatomic, getter=isReadOnlyChat) BOOL readOnlyChat;
@property (readonly, nonatomic) CKEntity *recipient;
@property (readonly, nonatomic) NSUInteger recipientCount;
@property (readonly, copy, nonatomic) NSArray *recipientStrings;
@property (retain, nonatomic) NSArray *recipients; // ivar: _recipients
@property (retain, nonatomic) NSString *selectedLastAddressedHandle; // ivar: _selectedLastAddressedHandle
@property (retain, nonatomic) NSString *selectedLastAddressedSIMID; // ivar: _selectedLastAddressedSIMID
@property (readonly, nonatomic, getter=shouldSendReadReceipts) BOOL sendReadReceipts;
@property (readonly, copy, nonatomic) NSString *senderIdentifier;
@property (readonly, nonatomic) IMService *sendingService;
@property (readonly, nonatomic) NSString *serviceDisplayName;
@property (readonly, nonatomic) BOOL shouldShowCharacterCount;
@property (nonatomic) BOOL shouldShowGroupNameUpdateBanner; // ivar: _shouldShowGroupNameUpdateBanner
@property (nonatomic) BOOL shouldShowGroupPhotoUpdateBanner; // ivar: _shouldShowGroupPhotoUpdateBanner
@property (readonly, nonatomic) NSInteger spamCategory;
@property (readonly, nonatomic) NSInteger spamSubCategory;
@property (readonly, nonatomic, getter=isStewieConversation) BOOL stewieConversation;
@property (readonly) Class superclass;
@property (readonly, nonatomic) BOOL supportsMessageEditing;
@property (readonly, nonatomic) BOOL supportsMutatingGroupMembers;
@property (readonly, nonatomic) NSUInteger unreadCount;
@property (retain, nonatomic) CKComposition *unsentComposition;
@property (readonly, nonatomic, getter=isUserDeletable) BOOL userDeletable;
@property (nonatomic) int wasDetectedAsSMSCategory; // ivar: _wasDetectedAsSMSCategory
@property (nonatomic) int wasDetectedAsSMSSpam; // ivar: _wasDetectedAsSMSSpam
@property (nonatomic) int wasDetectedAsSpam; // ivar: _wasDetectedAsSpam
@property (nonatomic) int wasDetectedAsiMessageSpam; // ivar: _wasDetectedAsiMessageSpam
@property (nonatomic) BOOL wasKnownSender; // ivar: _wasKnownSender
@property (readonly, copy, nonatomic) NSArray *writableTypeIdentifiersForItemProvider;


+(BOOL)_iMessage_canAcceptMediaObjectType:(int)arg0 givenMediaObjects:(id)arg1 ;
+(BOOL)_iMessage_canSendComposition:(id)arg0 lastAddressedHandle:(id)arg1 lastAddressedSIMID:(id)arg2 currentService:(id)arg3 forceSMS:(BOOL)arg4 error:(*id)arg5 ;
+(BOOL)_iMessage_canSendMessageWithMediaObjectTypes:(*int)arg0 ;
+(BOOL)_iMessage_canSendMessageWithMediaObjectTypes:(*int)arg0 errorCode:(*NSInteger)arg1 ;
+(BOOL)_sms_canAcceptMediaObjectType:(int)arg0 givenMediaObjects:(id)arg1 phoneNumber:(id)arg2 simID:(id)arg3 ;
+(BOOL)_sms_canSendComposition:(id)arg0 lastAddressedHandle:(id)arg1 lastAddressedSIMID:(id)arg2 error:(*id)arg3 ;
+(BOOL)_sms_canSendMessageWithMediaObjectTypes:(*int)arg0 phoneNumber:(id)arg1 simID:(id)arg2 ;
+(BOOL)_sms_canSendMessageWithMediaObjectTypes:(*int)arg0 phoneNumber:(id)arg1 simID:(id)arg2 errorCode:(*NSInteger)arg3 ;
+(BOOL)_sms_mediaObjectPassesDurationCheck:(id)arg0 ;
+(BOOL)_sms_mediaObjectPassesRestriction:(id)arg0 ;
+(BOOL)isSMSSpamFilteringEnabled;
+(CGFloat)_iMessage_maxTrimDurationForMediaType:(int)arg0 ;
+(CGFloat)_sms_maxTrimDurationForMediaType:(int)arg0 ;
+(NSInteger)_iMessage_maxAttachmentCount;
+(NSInteger)_sms_maxAttachmentCountForPhoneNumber:(id)arg0 simID:(id)arg1 ;
+(NSUInteger)_iMessage_maxTransferFileSizeForWiFi:(BOOL)arg0 ;
+(id)_iMessage_localizedErrorForReason:(NSInteger)arg0 ;
+(id)_sms_localizedErrorForReason:(NSInteger)arg0 ;
+(id)conversationForAddresses:(id)arg0 allowRetargeting:(BOOL)arg1 candidateConversation:(id)arg2 ;
+(id)conversationForContacts:(id)arg0 candidateConversation:(id)arg1 ;
+(id)newPendingConversation;
-(BOOL)_allowedByScreenTime;
-(BOOL)_contactsForVisualIdentityHaveKeys:(id)arg0 ;
-(BOOL)_earlyReturnHistoryLoad;
-(BOOL)_handleIsForThisConversation:(id)arg0 ;
-(BOOL)_iMessage_canSendToRecipients:(id)arg0 alertIfUnable:(BOOL)arg1 ;
-(BOOL)_iMessage_supportsCharacterCountForAddresses:(id)arg0 ;
-(BOOL)_sms_canSendToRecipients:(id)arg0 alertIfUnable:(BOOL)arg1 ;
-(BOOL)_sms_supportsCharacterCountForAddresses:(id)arg0 ;
-(BOOL)_sms_willSendMMSByDefaultForAddresses:(id)arg0 ;
-(BOOL)_unknownFilteringEnabled;
-(BOOL)allowsMentions;
-(BOOL)canAcceptMediaObjectType:(int)arg0 givenMediaObjects:(id)arg1 ;
-(BOOL)canInsertMoreRecipients;
-(BOOL)canMuteStateBeToggled;
-(BOOL)canReadStateBeToggled;
-(BOOL)canSendComposition:(id)arg0 error:(*id)arg1 ;
-(BOOL)canSendToRecipients:(id)arg0 alertIfUnable:(BOOL)arg1 ;
-(BOOL)containsHandleWithUID:(id)arg0 ;
-(BOOL)hasLoadedFromSpotlight;
-(BOOL)hasReplyEnabled;
-(BOOL)hasVerifiedBusiness;
-(BOOL)isAdHocGroupConversation;
-(BOOL)isAppleConversation;
-(BOOL)isBlockedByCommunicationLimits;
-(BOOL)isBusinessChatDisabled;
-(BOOL)isBusinessConversation;
-(BOOL)isDowngraded;
-(BOOL)isKnownSender;
-(BOOL)isMakoConversation;
-(BOOL)isPlaceholder;
-(BOOL)noAvailableServices;
-(BOOL)supportsSurf;
-(CGFloat)maxTrimDurationForMedia:(id)arg0 ;
-(NSInteger)compareBySequenceNumberAndDateDescending:(id)arg0 ;
-(NSInteger)maximumRecipientsForSendingService;
-(char)outgoingBubbleColor;
-(char)sendButtonColor;
-(id)_backwardCompatabilityTextForEditedMessagePartText:(id)arg0 ;
-(id)_contactsForVisualIdentityWithKeys:(id)arg0 numberOfContacts:(NSUInteger)arg1 ;
-(id)_conversationList;
-(id)_groupPhotoFileURL;
-(id)_headerTitleForPendingMediaObjects:(id)arg0 subject:(id)arg1 onService:(id)arg2 ;
-(id)_headerTitleForService:(id)arg0 shouldListParticipants:(BOOL)arg1 ;
-(id)_nameForHandle:(id)arg0 ;
-(id)activityForNewScene;
-(id)contactNameByHandle;
-(id)conversationVisualIdentityWithKeys:(id)arg0 requestedNumberOfContactsToFetch:(NSUInteger)arg1 ;
-(id)copyForPendingConversation;
-(id)date;
-(id)displayNameForMediaObjects:(id)arg0 subject:(id)arg1 shouldListParticipants:(BOOL)arg2 ;
-(id)ensureMessageWithGUIDIsLoaded:(id)arg0 ;
-(id)entityMatchingHandle:(id)arg0 ;
-(id)fastPreviewTextIgnoringPluginContent;
-(id)groupPhotoData;
-(id)init;
-(id)initWithChat:(id)arg0 ;
-(id)loadDataWithTypeIdentifier:(id)arg0 forItemProviderCompletionHandler:(id)arg1 ;
-(id)messageWithComposition:(id)arg0 ;
-(id)messagesFromComposition:(id)arg0 ;
-(id)nameWithRawAddresses:(BOOL)arg0 ;
-(id)orderedContactsForAvatar3DTouchUIWithKeysToFetch:(id)arg0 ;
-(id)orderedContactsForAvatarView;
-(id)orderedContactsWithMaxCount:(NSUInteger)arg0 keysToFetch:(id)arg1 ;
-(id)pinnedConversationDisplayNamePreferringShortName:(BOOL)arg0 ;
-(id)shortDescription;
-(id)uniqueIdentifier;
-(void)_chatItemsDidChange:(id)arg0 ;
-(void)_chatPropertiesChanged:(id)arg0 ;
-(void)_clearTypingIndicatorsIfNecessary;
-(void)_createConversationVisualIdentityWithKeys:(id)arg0 numberOfContacts:(NSUInteger)arg1 ;
-(void)_deleteAllMessagesAndRemoveGroup:(BOOL)arg0 ;
-(void)_handleChatJoinStateDidChange:(id)arg0 ;
-(void)_handleChatParticipantsDidChange:(id)arg0 ;
-(void)_handleEngroupFinishedUpdating:(id)arg0 ;
-(void)_handlePreferredServiceChangedNotification:(id)arg0 ;
-(void)_invalidateApplicationSnapshotIfNeeded;
-(void)_updateContactsForVisualIdentityWithKeys:(id)arg0 numberOfContacts:(NSUInteger)arg1 ;
-(void)_updateGroupNameForVisualIdentity;
-(void)_updateGroupPhotoForVisualIdentity;
-(void)acceptTransfer:(id)arg0 ;
-(void)addRecipientHandles:(id)arg0 ;
-(void)canShareFocusStatusWithCompletion:(id)arg0 ;
-(void)clearConversationLoadFromSpotlight;
-(void)dealloc;
-(void)deleteAllMessages;
-(void)deleteAllMessagesAndRemoveGroup;
-(void)didBecomeActive;
-(void)editMessage:(id)arg0 partIndex:(NSInteger)arg1 withNewComposition:(id)arg2 ;
-(void)enumerateMessagesWithOptions:(NSUInteger)arg0 usingBlock:(id)arg1 ;
-(void)fetchAllMessages:(id)arg0 ;
-(void)fetchMoreMessages:(id)arg0 ;
-(void)fetchMoreMessagesAfterLastMessage:(id)arg0 ;
-(void)fetchMoreMessagesBeforeFirstMessage:(id)arg0 ;
-(void)fetchSuggestedNameIfNecessary;
-(void)loadAllMessages;
-(void)loadAllUnreadMessagesUpToMessageGUID:(id)arg0 ;
-(void)loadFrequentReplies;
-(void)loadMoreMessages;
-(void)loadMoreMessagesAfterLastMessage;
-(void)loadMoreMessagesBeforeFirstMessage;
-(void)markAllMessagesAsRead;
-(void)markLastMessageAsUnread;
-(void)prepareForRecoverableDeletionWithDeleteDate:(id)arg0 ;
-(void)recoverableDeleteAllMessagesGivenDeleteDate:(id)arg0 ;
-(void)refreshServiceForSending;
-(void)reloadIfNeeded;
-(void)removeRecipientHandles:(id)arg0 ;
-(void)resendEditedMessage:(id)arg0 forPartIndex:(NSInteger)arg1 ;
-(void)resetCaches;
-(void)resortMessagesIfNecessary;
-(void)retractMessagePart:(id)arg0 ;
-(void)sendMessage:(id)arg0 newComposition:(BOOL)arg1 ;
-(void)sendMessage:(id)arg0 onService:(id)arg1 newComposition:(BOOL)arg2 ;
-(void)setLoadedMessageCount:(NSUInteger)arg0 ;
-(void)setLoadedMessageCount:(NSUInteger)arg0 loadImmediately:(BOOL)arg1 ;
-(void)setNeedsUpdatedContactOrderForVisualIdentity;
-(void)unmute;
-(void)updateConversationVisualIdentityDisplayNameWithSender:(id)arg0 ;
-(void)updateConversationVisualIdentityGroupPhotoWithSender:(id)arg0 ;
-(void)updateDisplayNameIfSMSSpam;
-(void)updateUnsentCompositionByAppendingComposition:(id)arg0 ;
-(void)updateUserActivity;
-(void)updateWasKnownSender;
-(void)willBecomeInactive;


@end


#endif
