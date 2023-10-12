// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0



@protocol FMFSessionDelegate



@optional
-(void)connectionError:(id)arg0 ;
-(void)didChangeActiveLocationSharingDevice:(id)arg0 ;
-(void)didFailToFetchLocationForHandle:(id)arg0 withError:(id)arg1 ;
-(void)didFailToHandleMappingPacket:(id)arg0 error:(id)arg1 ;
-(void)didReceiveFriendshipRequest:(id)arg0 ;
-(void)didReceiveLocation:(id)arg0 ;
-(void)didReceiveServerError:(id)arg0 ;
-(void)didStartAbilityToGetLocationForHandle:(id)arg0 ;
-(void)didStartSharingMyLocationWithHandle:(id)arg0 ;
-(void)didStopAbilityToGetLocationForHandle:(id)arg0 ;
-(void)didStopSharingMyLocationWithHandle:(id)arg0 ;
-(void)didUpdateActiveDeviceList:(id)arg0 ;
-(void)didUpdateFavoriteHandles:(id)arg0 ;
-(void)didUpdateFences:(id)arg0 ;
-(void)didUpdateHidingStatus:(BOOL)arg0 ;
-(void)didUpdatePendingOffersForHandles:(id)arg0 ;
-(void)didUpdatePreferences:(id)arg0 ;
-(void)mappingPacketProcessingCompleted:(id)arg0 ;
-(void)networkReachabilityUpdated:(BOOL)arg0 ;
-(void)sendMappingPacket:(id)arg0 toHandle:(id)arg1 ;
@end
