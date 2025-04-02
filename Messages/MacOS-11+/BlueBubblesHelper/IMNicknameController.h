// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMNICKNAMECONTROLLER_H
#define IMNICKNAMECONTROLLER_H

@class NSSet, NSMutableArray, NSDictionary, IMNickname, NSMutableDictionary, NSMutableSet;

#import <Foundation/Foundation.h>


@interface IMNicknameController : NSObject

@property (retain, nonatomic) NSSet *allowListedHandlesForSharing; // ivar: _allowListedHandlesForSharing
@property (retain, nonatomic) NSSet *denyListedHandlesForSharing; // ivar: _denyListedHandlesForSharing
@property (retain, nonatomic) NSMutableArray *fetchPersonalNicknameCompletionBlocks; // ivar: _fetchPersonalNicknameCompletionBlocks
@property (retain, nonatomic) NSDictionary *handledNicknames; // ivar: _handledNicknames
@property (nonatomic) BOOL isInitialLoad; // ivar: _isInitialLoad
@property (retain, nonatomic) NSDictionary *pendingNicknameUpdates; // ivar: _pendingNicknameUpdates
@property (retain, nonatomic) IMNickname *personalNickname; // ivar: _personalNickname
@property (retain, nonatomic) NSMutableDictionary *responseHandlers; // ivar: _responseHandlers
@property (retain, nonatomic) NSMutableSet *scrutinyNicknameHandles; // ivar: _scrutinyNicknameHandles


+(BOOL)accountsMatchUpToUseNicknames;
+(BOOL)multiplePhoneNumbersTiedToAppleID;
+(id)sharedInstance;
-(BOOL)_canUpdatePersonalNickname;
-(BOOL)_nicknameFeatureEnabled;
-(BOOL)handleIsAllowedForSharing:(id)arg0 ;
-(BOOL)handleIsDeniedForSharing:(id)arg0 ;
-(BOOL)meCardSyncEnabled;
-(BOOL)shouldOfferNicknameSharingForChat:(id)arg0 ;
-(NSUInteger)nicknameUpdateForHandle:(id)arg0 nicknameIfAvailable:(id)arg1 ;
-(id)IMSharedHelperMD5Helper:(id)arg0 ;
-(id)_handleIDsForHandle:(id)arg0 ;
-(id)contactStore;
-(id)daemonController;
-(id)getNicknameHandlesUnderScrutiny;
-(id)handlesForNicknamesUnderScrutiny;
-(id)imageDataForHandle:(id)arg0 ;
-(id)init;
-(id)meCardSharingState;
-(id)nicknameForHandle:(id)arg0 ;
-(id)personNameComponentsForHandle:(id)arg0 ;
-(id)truncateNameIfNeeded:(id)arg0 ;
-(void)_broadcastNicknamePreferencesDidChange:(id)arg0 ;
-(void)_meCardDidChange:(id)arg0 ;
-(void)_updateLocalNicknameStore;
-(void)_updatePersonalNicknameWithMeCardIfNecessary;
-(void)allowHandlesForNicknameSharing:(id)arg0 forChat:(id)arg1 fromHandle:(id)arg2 forceSend:(bool)arg3 ;
-(void)allowHandlesForNicknameSharing:(id)arg0 fromHandle:(id)arg1 forceSend:(bool)arg2 ;
-(void)setAllowListedHandlesForSharing:(id)arg0 ;
-(void)whitelistHandlesForNicknameSharing:(id)arg1 forChat:(id)arg2;
-(void)clearHandleFromScrutiny:(id)arg0 ;
-(void)clearPendingNicknameUpdatesForHandle:(id)arg0 ;
-(void)denyHandlesForNicknameSharing:(id)arg0 ;
-(void)fetchPersonalNicknameWithCompletion:(id)arg0 ;
-(void)handleSharingListsDidChange;
-(void)ignorePendingNicknameUpdatesForHandle:(id)arg0 ;
-(void)markAllAsPending;
-(void)markHandleUnderScrutiny:(id)arg0 ;
-(void)nicknameStoreDidChange;
-(void)setNicknameHandlesUnderScrutiny;
-(void)updatePendingNicknames:(id)arg0 handledNicknames:(id)arg1 ;
-(void)updatePersonalNickname:(id)arg0 ;
-(void)updatePersonalNicknameIfNecessaryWithMeCardSharingResult:(id)arg0 ;
-(void)updateSharingAllowList:(id)arg0 denyList:(id)arg1 ;


@end


#endif
