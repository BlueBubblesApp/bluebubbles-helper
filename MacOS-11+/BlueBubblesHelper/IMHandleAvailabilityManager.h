// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMHANDLEAVAILABILITYMANAGER_H
#define IMHANDLEAVAILABILITYMANAGER_H

@class NSMutableDictionary, NSString, NSMutableSet, SKStatusSubscriptionService;
@protocol OS_dispatch_queue;

#import <Foundation/Foundation.h>

#import "SKStatusSubscriptionServiceDelegate-Protocol.h"

@interface IMHandleAvailabilityManager : NSObject <SKStatusSubscriptionServiceDelegate>



@property (nonatomic) NSInteger currentCacheGeneration; // ivar: _currentCacheGeneration
@property (retain, nonatomic) NSMutableDictionary *currentSubscriptionCache; // ivar: _currentSubscriptionCache
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly) NSUInteger hash;
@property (retain, nonatomic) NSMutableDictionary *lastKnownSubscriptionCache; // ivar: _lastKnownSubscriptionCache
@property (retain, nonatomic) NSMutableSet *pendingFetchesForCacheKeys; // ivar: _pendingFetchesForCacheKeys
@property (retain, nonatomic) NSObject<OS_dispatch_queue> *privateWorkQueue; // ivar: _privateWorkQueue
@property (retain, nonatomic) SKStatusSubscriptionService *subscriptionService; // ivar: _subscriptionService
@property (readonly) Class superclass;


+(id)sharedInstance;
-(NSInteger)_availablityFromStatusSubscription:(id)arg0 handleID:(id)arg1 ;
-(NSInteger)availabilityForHandle:(id)arg0 ;
-(id)_cachedStatusSubscriptionForIMHandle:(id)arg0 fromCache:(id)arg1 cacheDescription:(id)arg2 cacheMiss:(BOOL)arg3 ;
-(id)_skHandleForIMHandle:(id)arg0 ;
-(id)_skHandleForString:(id)arg0 ;
-(id)_subscriptionCacheKeyForHandle:(id)arg0 ;
-(id)availabilityStatusPublishedDateForHandle:(id)arg0 ;
-(id)init;
-(id)statusSubscriptionForHandle:(id)arg0 ;
-(void)_clearCurrentSubscriptionCache;
-(void)_fetchUpdatedStatusForHandle:(id)arg0 completion:(id)arg1 ;
-(void)_postNotificationForUpdatedStatusWithSubscription:(id)arg0 ;
-(void)beginObservingAvailabilityForHandle:(id)arg0 ;
-(void)endObservingAvailabilityForHandle:(id)arg0 ;
-(void)fetchPersonalAvailabilityWithCompletion:(id)arg0 ;
-(void)fetchUpdatedStatusAndUpdateCachesForHandle:(id)arg0 lastKnownStatus:(id)arg1 ;
-(void)subscriptionInvitationReceived:(id)arg0 ;
-(void)subscriptionReceivedStatusUpdate:(id)arg0 ;
-(void)subscriptionServiceDaemonDisconnected:(id)arg0 ;
-(void)subscriptionStateChanged:(id)arg0 ;


@end


#endif
