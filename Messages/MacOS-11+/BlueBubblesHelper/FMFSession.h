// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef FMFSESSION_H
#define FMFSESSION_H

@class NSMutableDictionary, NSSet, NSXPCConnection, NSString, NSOperationQueue, NSMutableSet, FMFuture;
@protocol OS_dispatch_queue;

#import <Foundation/Foundation.h>

#import "FMFXPCInternalClientProtocol-Protocol.h"
#import "FMFSessionDelegate-Protocol.h"

@interface FMFSession : NSObject <FMFXPCInternalClientProtocol>



@property (retain, nonatomic) NSMutableDictionary *cachedCanShareLocationWithHandleByHandle; // ivar: _cachedCanShareLocationWithHandleByHandle
@property (retain, nonatomic) NSSet *cachedGetHandlesFollowingMyLocation; // ivar: _cachedGetHandlesFollowingMyLocation
@property (retain, nonatomic) NSSet *cachedGetHandlesSharingLocationsWithMe; // ivar: _cachedGetHandlesSharingLocationsWithMe
@property (retain, nonatomic) NSMutableDictionary *cachedLocationForHandleByHandle; // ivar: _cachedLocationForHandleByHandle
@property (retain, nonatomic) NSMutableDictionary *cachedOfferExpirationForHandleByHandle; // ivar: _cachedOfferExpirationForHandleByHandle
@property (retain, nonatomic) NSXPCConnection *connection; // ivar: _connection
@property (retain, nonatomic) NSObject<OS_dispatch_queue> *connectionQueue; // ivar: _connectionQueue
@property (readonly, copy) NSString *debugDescription;
@property (weak, nonatomic) NSObject<FMFSessionDelegate> *delegate; // ivar: _delegate
@property (retain, nonatomic) NSOperationQueue *delegateQueue; // ivar: _delegateQueue
@property (readonly, copy) NSString *description;
@property (copy, nonatomic) NSSet *handles;
@property (retain, nonatomic) NSObject<OS_dispatch_queue> *handlesQueue; // ivar: _handlesQueue
@property (readonly) NSUInteger hash;
@property (retain, nonatomic) NSMutableSet *internalHandles; // ivar: _internalHandles
@property (nonatomic) BOOL isModelInitialized; // ivar: _isModelInitialized
@property (retain, nonatomic) FMFuture *sessionInterruptionFuture; // ivar: _sessionInterruptionFuture
@property (retain, nonatomic) FMFuture *sessionInvalidationFuture; // ivar: _sessionInvalidationFuture
@property (readonly) Class superclass;


+(BOOL)FMFAllowed;
+(BOOL)FMFRestricted;
+(BOOL)isAnyAccountManaged;
+(BOOL)isProvisionedForLocationSharing;
+(id)sharedInstance;
-(BOOL)_isNoMappingPacketReturnedError:(id)arg0 ;
-(BOOL)canGetLocationForHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 ;
-(BOOL)canShareLocationWithHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 ;
-(BOOL)hasModelInitialized;
-(BOOL)is5XXError:(id)arg0 ;
-(BOOL)isMyLocationEnabled;
-(BOOL)shouldHandleErrorInFWK:(id)arg0 ;
-(CGFloat)maxLocatingInterval;
-(id)cachedLocationForHandle:(id)arg0 ;
-(id)getActiveLocationSharingDevice;
-(id)getAllDevices;
-(id)getFavoritesSharingLocationWithMe;
-(id)getHandlesFollowingMyLocation;
-(id)getHandlesSharingLocationsWithMe;
-(id)getHandlesWithPendingOffers;
-(id)getOfferExpirationForHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 ;
-(id)init;
-(id)initWithDelegate:(id)arg0 ;
-(id)initWithDelegate:(id)arg0 delegateQueue:(id)arg1 ;
-(id)serverProxy;
-(id)verifyRestrictionsAndShowDialogIfRequired;
-(void)_checkAndDisplayMeDeviceSwitchAlert;
-(void)_daemonDidLaunch;
-(void)_registerForApplicationLifecycleEvents;
-(void)_registerForFMFDLaunchedNotification;
-(void)_sendAutoSwitchMeDevice;
-(void)_sendFriendshipOfferToHandles:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 endDate:(id)arg3 completion:(id)arg4 ;
-(void)abDidChange;
-(void)abPreferencesDidChange;
-(void)addFavorite:(id)arg0 completion:(id)arg1 ;
-(void)addFence:(id)arg0 completion:(id)arg1 ;
-(void)addHandles:(id)arg0 ;
-(void)addInterruptionHander:(id)arg0 ;
-(void)addInvalidationHander:(id)arg0 ;
-(void)applicationDidEnterBackground;
-(void)applicationWillEnterForeground;
-(void)approveFriendshipRequest:(id)arg0 completion:(id)arg1 ;
-(void)canGetLocationForHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 completion:(id)arg3 ;
-(void)canOfferToHandles:(id)arg0 completion:(id)arg1 ;
-(void)canShareLocationWithHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 completion:(id)arg3 ;
-(void)contactForPayload:(id)arg0 completion:(id)arg1 ;
-(void)crashDaemon;
-(void)dataForPayload:(id)arg0 completion:(id)arg1 ;
-(void)dealloc;
-(void)declineFriendshipRequest:(id)arg0 completion:(id)arg1 ;
-(void)decryptPayload:(id)arg0 withToken:(id)arg1 completion:(id)arg2 ;
-(void)deleteFence:(id)arg0 completion:(id)arg1 ;
-(void)didAddFollowerHandle:(id)arg0 ;
-(void)didChangeActiveLocationSharingDevice:(id)arg0 ;
-(void)didReceiveFriendshipRequest:(id)arg0 ;
-(void)didReceiveServerError:(id)arg0 ;
-(void)didRemoveFollowerHandle:(id)arg0 ;
-(void)didStartFollowingHandle:(id)arg0 ;
-(void)didStopFollowingHandle:(id)arg0 ;
-(void)didUpdateActiveDeviceList:(id)arg0 ;
-(void)didUpdateFavorites:(id)arg0 ;
-(void)didUpdateFences:(id)arg0 ;
-(void)didUpdateFollowers:(id)arg0 ;
-(void)didUpdateFollowing:(id)arg0 ;
-(void)didUpdateHideFromFollowersStatus:(BOOL)arg0 ;
-(void)didUpdateLocations:(id)arg0 ;
-(void)didUpdatePendingOffersForHandles:(id)arg0 ;
-(void)didUpdatePreferences:(id)arg0 ;
-(void)dispatchOnDelegateQueue:(id)arg0 ;
-(void)dumpStateWithCompletion:(id)arg0 ;
-(void)encryptPayload:(id)arg0 completion:(id)arg1 ;
-(void)exit5XXGracePeriod;
-(void)extendFriendshipOfferToHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 endDate:(id)arg3 completion:(id)arg4 ;
-(void)failedToGetLocationForHandle:(id)arg0 error:(id)arg1 ;
-(void)favoritesForMaxCount:(id)arg0 completion:(id)arg1 ;
-(void)fencesForHandles:(id)arg0 completion:(id)arg1 ;
-(void)forceRefresh;
-(void)forceRefreshWithCompletion:(id)arg0 ;
-(void)getAccountEmailAddress:(id)arg0 ;
-(void)getActiveLocationSharingDevice:(id)arg0 ;
-(void)getAllDevices:(id)arg0 ;
-(void)getAllLocations:(id)arg0 ;
-(void)getDataForPerformanceRequest:(id)arg0 ;
-(void)getFavoritesWithCompletion:(id)arg0 ;
-(void)getFences:(id)arg0 ;
-(void)getHandlesFollowingMyLocation:(id)arg0 ;
-(void)getHandlesFollowingMyLocationWithGroupId:(id)arg0 completion:(id)arg1 ;
-(void)getHandlesSharingLocationsWithMe:(id)arg0 ;
-(void)getHandlesSharingLocationsWithMeWithGroupId:(id)arg0 completion:(id)arg1 ;
-(void)getHandlesWithPendingOffers:(id)arg0 ;
-(void)getOfferExpirationForHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 completion:(id)arg3 ;
-(void)getPendingFriendshipRequestsWithCompletion:(id)arg0 ;
-(void)getPendingMappingPacketsForHandle:(id)arg0 groupId:(id)arg1 completion:(id)arg2 ;
-(void)getPrettyNameForHandle:(id)arg0 completion:(id)arg1 ;
-(void)getRecordIdForHandle:(id)arg0 completion:(id)arg1 ;
-(void)getThisDeviceAndCompanion:(id)arg0 ;
-(void)handleAndLocationForPayload:(id)arg0 completion:(id)arg1 ;
-(void)handleIncomingAirDropURL:(id)arg0 completion:(id)arg1 ;
-(void)iCloudAccountNameWithCompletion:(id)arg0 ;
-(void)includeDeviceInAutomations:(id)arg0 ;
-(void)invalidate;
-(void)isAllowFriendRequestsEnabled:(id)arg0 ;
-(void)isIn5XXGracePeriodWithCompletion:(id)arg0 ;
-(void)isMyLocationEnabled:(id)arg0 ;
-(void)locatingInProgressChanged:(id)arg0 ;
-(void)locationForHandle:(id)arg0 completion:(id)arg1 ;
-(void)mappingPacketSendFailed:(id)arg0 toHandle:(id)arg1 withError:(id)arg2 ;
-(void)modelDidLoad;
-(void)muteFencesForHandle:(id)arg0 untilDate:(id)arg1 completion:(id)arg2 ;
-(void)nearbyLocationsWithCompletion:(id)arg0 ;
-(void)networkReachabilityUpdated:(BOOL)arg0 ;
-(void)receivedMappingPacket:(id)arg0 completion:(id)arg1 ;
-(void)refreshLocationForHandle:(id)arg0 callerId:(id)arg1 priority:(NSInteger)arg2 completion:(id)arg3 ;
-(void)refreshLocationForHandles:(id)arg0 callerId:(id)arg1 priority:(NSInteger)arg2 completion:(id)arg3 ;
-(void)reloadDataIfNotLoaded;
-(void)removeDevice:(id)arg0 completion:(id)arg1 ;
-(void)removeFavorite:(id)arg0 completion:(id)arg1 ;
-(void)removeHandles:(id)arg0 ;
-(void)restoreClientConnection;
-(void)sendFriendshipInviteToHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 endDate:(id)arg3 completion:(id)arg4 ;
-(void)sendFriendshipOfferToHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 endDate:(id)arg3 completion:(id)arg4 ;
-(void)sendFriendshipOfferToHandles:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 endDate:(id)arg3 completion:(id)arg4 ;
-(void)sendIDSMessage:(id)arg0 toIdentifier:(id)arg1 completion:(id)arg2 ;
-(void)sendIDSPacket:(id)arg0 toHandle:(id)arg1 ;
-(void)sendMappingPacket:(id)arg0 toHandle:(id)arg1 ;
-(void)sendNotNowToHandle:(id)arg0 callerId:(id)arg1 completion:(id)arg2 ;
-(void)sessionHandleReport:(id)arg0 ;
-(void)setActiveDevice:(id)arg0 completion:(id)arg1 ;
-(void)setAllowFriendRequestsEnabled:(BOOL)arg0 completion:(id)arg1 ;
-(void)setDebugContext:(id)arg0 ;
-(void)setExpiredInitTimestamp;
-(void)setHideMyLocationEnabled:(BOOL)arg0 completion:(id)arg1 ;
-(void)setLocations:(id)arg0 ;
-(void)showMeDeviceAlert;
-(void)showShareMyLocationRestrictedAlert;
-(void)showShareMyLocationiCloudSettingsOffAlert;
-(void)stopSharingMyLocationWithHandle:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 completion:(id)arg3 ;
-(void)stopSharingMyLocationWithHandles:(id)arg0 groupId:(id)arg1 callerId:(id)arg2 completion:(id)arg3 ;
-(void)triggerWithUUID:(id)arg0 forFenceWithID:(id)arg1 withStatus:(id)arg2 forDate:(id)arg3 completion:(id)arg4 ;
-(void)triggerWithUUID:(id)arg0 forFenceWithID:(id)arg1 withStatus:(id)arg2 forDate:(id)arg3 triggerLocation:(id)arg4 completion:(id)arg5 ;


@end


#endif
