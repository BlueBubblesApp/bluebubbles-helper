// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMFMFSESSION_H
#define IMFMFSESSION_H

@class FMFDevice, NSString, FMFSession;

#import <Foundation/Foundation.h>

#import "FMFSessionDelegate-Protocol.h"

@interface IMFMFSession : NSObject <FMFSessionDelegate>



@property (retain, nonatomic) FMFDevice *activeDevice; // ivar: _activeDevice
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly, nonatomic) BOOL disableLocationSharing;
@property (retain, nonatomic) NSString *establishingAccountID; // ivar: _establishingAccountID
@property (nonatomic) NSUInteger fmfProvisionedState; // ivar: _fmfProvisionedState
@property (readonly) NSUInteger hash;
@property (readonly, nonatomic) BOOL restrictLocationSharing;
@property (retain, nonatomic) FMFSession *session; // ivar: _session
@property (readonly) Class superclass;


+(id)sharedInstance;
-(BOOL)allChatParticipantsFollowingMyLocation:(id)arg0 ;
-(BOOL)allChatParticipantsSharingLocationWithMe:(id)arg0 ;
-(BOOL)chatHasParticipantsFollowingMyLocation:(id)arg0 ;
-(BOOL)chatHasParticipantsSharingLocationWithMe:(id)arg0 ;
-(BOOL)chatHasSiblingParticipantsSharingLocationWithMe:(id)arg0 ;
-(BOOL)fmfHandleIsFollowingMyLocation:(id)arg0 ;
-(BOOL)fmfHandleIsSharingLocationWithMe:(id)arg0 ;
-(BOOL)handleIsFollowingMyLocation:(id)arg0 ;
-(BOOL)handleIsSharingLocationWithMe:(id)arg0 ;
-(BOOL)imIsProvisionedForLocationSharing;
-(Class)__FMFSessionClass;
-(id)_accountStore;
-(id)_bestAccountForAddresses:(id)arg0 ;
-(id)_callerIDForChat:(id)arg0 ;
-(id)allSiblingFMFHandlesForChat:(id)arg0 ;
-(id)fmfGroupIdGroup;
-(id)fmfGroupIdOneToOne;
-(id)fmfHandlesForChat:(id)arg0 ;
-(id)fmfOpenURLStringForChat:(id)arg0 ;
-(id)init;
-(id)locationForFMFHandle:(id)arg0 ;
-(id)locationForHandle:(id)arg0 ;
-(id)locationForHandleOrSibling:(id)arg0 ;
-(id)timedOfferExpirationForChat:(id)arg0 ;
-(void)_accountStoreDidChangeNotification:(id)arg0 ;
-(void)_postNotification:(id)arg0 object:(id)arg1 userInfo:(id)arg2 ;
-(void)_postRelationshipStatusDidChangeNotificationWithHandle:(id)arg0 ;
-(void)_startSharingWithFMFHandles:(id)arg0 inChat:(id)arg1 untilDate:(id)arg2 ;
-(void)_stopSharingWithFMFHandles:(id)arg0 inChat:(id)arg1 ;
-(void)_updateActiveDevice;
-(void)dealloc;
-(void)didChangeActiveLocationSharingDevice:(id)arg0 ;
-(void)didReceiveLocation:(id)arg0 ;
-(void)didStartAbilityToGetLocationForHandle:(id)arg0 ;
-(void)didStartSharingMyLocationWithHandle:(id)arg0 ;
-(void)didStopAbilityToGetLocationForHandle:(id)arg0 ;
-(void)didStopSharingMyLocationWithHandle:(id)arg0 ;
-(void)didUpdateHidingStatus:(BOOL)arg0 ;
-(void)friendshipRequestReceived:(id)arg0 ;
-(void)friendshipWasRemoved:(id)arg0 ;
-(void)makeThisDeviceActiveDevice;
-(void)refreshLocationForChat:(id)arg0 ;
-(void)refreshLocationForHandle:(id)arg0 inChat:(id)arg1 ;
-(void)sendMappingPacket:(id)arg0 toHandle:(id)arg1 ;
-(void)startSharingWithChat:(id)arg0 untilDate:(id)arg1 ;
-(void)startSharingWithHandle:(id)arg0 inChat:(id)arg1 untilDate:(id)arg2 ;
-(void)startTrackingLocationForChat:(id)arg0 ;
-(void)startTrackingLocationForHandle:(id)arg0 ;
-(void)stopSharingWithChat:(id)arg0 ;
-(void)stopSharingWithHandle:(id)arg0 inChat:(id)arg1 ;
-(void)stopTrackingLocationForChat:(id)arg0 ;
-(void)stopTrackingLocationForHandle:(id)arg0 ;


@end


#endif
