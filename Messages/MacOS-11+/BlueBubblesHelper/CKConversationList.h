//
//  CKConversationList.h
//  BlueBubblesHelper DyLib
//
//  Created by Tanay Neotia on 5/3/26.
//  Copyright © 2026 BlueBubbleMessaging. All rights reserved.
//


// Headers generated with ktool v2.0.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.5.0 | SDK: 16.5.0


#ifndef CKCONVERSATIONLIST_H
#define CKCONVERSATIONLIST_H

@class NSArray, NSMutableDictionary, NSMutableArray;

#import "CKConversation.h"

__attribute__((objc_runtime_name("CKConversationList")))
@interface CKConversationList : NSObject

@property (readonly, copy, nonatomic) NSArray *conversations;
@property (retain, nonatomic) NSMutableDictionary *conversationsDictionary; // ivar: _conversationsDictionary
@property (readonly, nonatomic) BOOL hasActiveConversations;
@property (nonatomic, getter=isHoldingWasKnownSenderUpdates) BOOL holdingWasKnownSenderUpdates; // ivar: _holdingWasKnownSenderUpdates
@property (readonly, nonatomic) BOOL loadedConversations; // ivar: _loadedConversations
@property (nonatomic) BOOL loadedPinnedConversations; // ivar: _loadedPinnedConversations
@property (readonly, nonatomic) BOOL loadingConversations; // ivar: _loadingConversations
@property (retain, nonatomic) CKConversation *pendingConversation; // ivar: _pendingConversation
@property (retain, nonatomic) NSArray *pinnedConversations; // ivar: _pinnedConversations
@property (nonatomic) BOOL remergingConversations; // ivar: _remergingConversations
@property (nonatomic) NSInteger simFilterIndex; // ivar: _simFilterIndex
@property (retain, nonatomic) NSMutableArray *trackedConversations; // ivar: _trackedConversations


+(id)conversationListAlertSuppressionContextForFilterMode:(NSUInteger)arg0 ;
+(id)sharedConversationList;
+(void)_handleRegistryDidLoadNotification:(id)arg0 ;
+(void)initialize;
-(BOOL)_chatHasRelevantUnreadLastMessage:(id)arg0 ;
-(BOOL)_isParentWithSubfoldersForFilterMode:(NSUInteger)arg0 ;
-(BOOL)_isUnreadChat:(id)arg0 ignoringMessages:(id)arg1 ;
-(BOOL)_messageSIMFilteringEnabled;
-(BOOL)_messageSpamFilteringEnabled;
-(BOOL)_messageUnknownFilteringEnabled;
-(BOOL)_shouldBailBeginTrackingForCurrentProcess;
-(BOOL)_shouldFilterForParticipants:(id)arg0 ;
-(BOOL)_shouldShowInboxUI;
-(BOOL)_shouldTreatConversationAsNonSMSCategorized:(id)arg0 ;
-(BOOL)conversation:(id)arg0 includedInFilterMode:(NSUInteger)arg1 ;
-(NSInteger)unreadCountForFilterMode:(NSUInteger)arg0 ;
-(NSInteger)unreadFilteredConversationCountIgnoringMessages:(id)arg0 ;
-(NSUInteger)_filterModeForConversationAsNonSMSCategorized:(id)arg0 ;
-(NSUInteger)primaryFilterModeForConversation:(id)arg0 ;
-(id)_alreadyTrackedConversationForChat:(id)arg0 ;
-(id)_beginTrackingConversationWithChatIndirect:(id)arg0 ;
-(id)_conversationForChat:(id)arg0 ;
-(id)_conversationSortComparator:(SEL)arg0 ;
-(id)_copyEntitiesForAddressStrings:(id)arg0 ;
-(id)_emptyConversationsDictionaryWithConversationsCount:(NSUInteger)arg0 ;
-(id)_filterConversations:(id)arg0 byHandleID:(id)arg1 ;
-(id)_filterConversationsByFocus:(id)arg0 ;
-(id)_filterConversationsWithoutiMessageJunk:(id)arg0 ;
-(id)_handleIDForSIMFilterIndex:(NSInteger)arg0 ;
-(id)_nonPlaceholderConversations;
-(id)_recoverableSortComparator:(SEL)arg0 ;
-(id)_testingTrackedConversations;
-(id)conversationForExistingChat:(id)arg0 ;
-(id)conversationForExistingChatWithChatIdentifier:(id)arg0 ;
-(id)conversationForExistingChatWithDeviceIndependentID:(id)arg0 ;
-(id)conversationForExistingChatWithGUID:(id)arg0 ;
-(id)conversationForExistingChatWithGroupID:(id)arg0 ;
-(id)conversationForExistingChatWithPersonCentricID:(id)arg0 ;
-(id)conversationForExistingChatWithPinningIdentifier:(id)arg0 ;
-(id)conversationForHandles:(id)arg0 displayName:(id)arg1 joinedChatsOnly:(BOOL)arg2 create:(BOOL)arg3 ;
-(id)conversationForHandles:(id)arg0 displayName:(id)arg1 lastAddressedHandle:(id)arg2 lastAddressedSIMID:(id)arg3 joinedChatsOnly:(BOOL)arg4 create:(BOOL)arg5 ;
-(id)conversationsForFilterMode:(NSUInteger)arg0 ;
-(id)description;
-(id)firstUnreadFilteredConversationIgnoringMessages:(id)arg0 ;
-(id)identifiersSetForConversations:(id)arg0 ;
-(id)init;
-(id)pinningIdentifierMap;
-(id)relevantUnreadLastMessages;
-(id)subclassifiedConversationsForFilterMode:(NSUInteger)arg0 ;
-(id)topMostConversation;
-(void)_abChanged:(id)arg0 ;
-(void)_abPartialChanged:(id)arg0 ;
-(void)_beginTrackingAllExistingChatsIfNeeded;
-(void)_beginTrackingConversationWithChat:(id)arg0 completion:(id)arg1 ;
-(void)_chatItemsDidChange:(id)arg0 ;
-(void)_chatPropertiesChanged:(id)arg0 ;
-(void)_configureForOscarEnabledUnsortedConversationList;
-(void)_configureForUnsortedConversationList;
-(void)_handleChatJoinStateDidChange:(id)arg0 ;
-(void)_handleChatParticipantsDidChange:(id)arg0 ;
-(void)_handleChatsDidRemergeNotification:(id)arg0 ;
-(void)_handleChatsWillRemergeNotification:(id)arg0 ;
-(void)_handleEngroupFinishedUpdating:(id)arg0 ;
-(void)_handleGroupNameChanged:(id)arg0 ;
-(void)_handleGroupPhotoChanged:(id)arg0 ;
-(void)_handleMemoryWarning:(id)arg0 ;
-(void)_handlePreferredServiceChangedNotification:(id)arg0 ;
-(void)_handleRegistryDidRegisterChatNotification:(id)arg0 ;
-(void)_handleRegistryWillUnregisterChatNotification:(id)arg0 ;
-(void)_insertConversationIntoSortedConversationList:(id)arg0 ;
-(void)_invalidateABCaches:(id)arg0 ;
-(void)_invalidatePartialABCaches:(id)arg0 ;
-(void)_postConversationListChangedNotification;
-(void)_postConversationListUpdateVisibleConversationsNotificationForUID:(id)arg0 ;
-(void)_removeConversationsFromRecentlyDeleted:(id)arg0 ;
-(void)_trackSendEventForMySenderID:(id)arg0 andParticipants:(id)arg1 ;
-(void)_updatePinnedConversationsControllerForRemovedConversations:(id)arg0 ;
-(void)beginTrackingConversation:(id)arg0 forChat:(id)arg1 ;
-(void)beginWasKnownSenderHold;
-(void)clearHoldInUnreadFilter;
-(void)deleteConversation:(id)arg0 ;
-(void)deleteConversations:(id)arg0 ;
-(void)logConversationsTopCount:(NSInteger)arg0 bottomCount:(NSInteger)arg1 ;
-(void)permanentlyDeleteRecoverableMessagesInConversations:(id)arg0 synchronousQuery:(BOOL)arg1 completionHandler:(id)arg2 ;
-(void)postFinishedInitalPinLoadIfNecessary;
-(void)recoverDeletedMessagesInConversations:(id)arg0 synchronousQuery:(BOOL)arg1 completionHandler:(id)arg2 ;
-(void)recoverJunkMessagesInConversations:(id)arg0 ;
-(void)recoverableDeleteForConversations:(id)arg0 deleteDate:(id)arg1 synchronousQuery:(BOOL)arg2 completionHandler:(id)arg3 ;
-(void)releaseWasKnownSenderHold;
-(void)removeConversation:(id)arg0 ;
-(void)resetCaches;
-(void)resort;
-(void)setNeedsReload;
-(void)stopTrackingConversation:(id)arg0 ;
-(void)unpendConversation;
-(void)updateConversationFilteredFlagsAndReportSpam;
-(void)updateConversationListsAndSortIfEnabled;
-(void)updateConversationsForNewPinnedConversations:(id)arg0 ;
-(void)updateConversationsWasKnownSender;
-(void)updateEarliestMessageDateForConversations:(id)arg0 ;
-(void)updateFilteredByFocusStateForConversations:(id)arg0 ;
-(void)updatePinnedConversationsFromDataSource;
-(void)updateRecoverableConversationList;


@end


#endif
