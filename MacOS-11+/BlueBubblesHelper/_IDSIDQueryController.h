// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef _IDSIDQUERYCONTROLLER_H
#define _IDSIDQUERYCONTROLLER_H

@class NSMutableDictionary, NSString, NSMapTable;
@protocol OS_xpc_object, OS_dispatch_queue;

#import <Foundation/Foundation.h>

@interface _IDSIDQueryController : NSObject

 {
    NSMutableDictionary *_listeners;
    NSMutableDictionary *_idStatusCache;
    NSMutableDictionary *_transactionIDToBlockMap;
    NSObject<OS_xpc_object> *_connection;
    NSObject<OS_dispatch_queue> *_connectionQueue;
    NSObject<OS_dispatch_queue> *_queue;
    NSString *_serviceToken;
    NSMapTable *_delegateToInfo;
    NSMutableDictionary *_listenerIDToServicesMap;
}


@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly) NSUInteger hash;
@property (readonly) Class superclass;


+(id)_createXPCConnectionOnQueue:(id)arg0 ;
+(void)initialize;
-(BOOL)_currentRemoteDevicesForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 waitForReply:(BOOL)arg4 completionBlock:(id)arg5 ;
-(BOOL)_flushQueryCacheForService:(id)arg0 ;
-(BOOL)_hasCacheForService:(id)arg0 ;
-(BOOL)_isListenerWithID:(id)arg0 listeningToService:(id)arg1 ;
-(BOOL)_refreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 allowRefresh:(BOOL)arg3 respectExpiry:(BOOL)arg4 waitForReply:(BOOL)arg5 forceRefresh:(BOOL)arg6 bypassLimit:(BOOL)arg7 queue:(id)arg8 completionBlock:(id)arg9 ;
-(BOOL)_sync_currentIDStatusForDestinations:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)_sync_currentRemoteDevicesForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 completionBlock:(id)arg3 ;
-(BOOL)_sync_refreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 completionBlock:(id)arg3 ;
-(BOOL)_warmupQueryCacheForService:(id)arg0 ;
-(BOOL)currentIDStatusForDestination:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(id)arg5 ;
-(BOOL)currentIDStatusForDestinations:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(id)arg5 ;
-(BOOL)currentRemoteDevicesForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)idInfoForDestinations:(id)arg0 service:(id)arg1 infoTypes:(NSUInteger)arg2 options:(id)arg3 listenerID:(id)arg4 queue:(id)arg5 completionBlock:(id)arg6 ;
-(BOOL)refreshIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)refreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 forceRefresh:(BOOL)arg3 queue:(id)arg4 completionBlock:(id)arg5 ;
-(BOOL)removeListenerID:(id)arg0 forService:(id)arg1 ;
-(BOOL)requiredIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)requiredIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(NSInteger)_currentCachedIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
// -(id)__sendMessage:(id)arg0 queue:(id)arg1 reply:(id)arg2 failBlock:(unk)arg3 waitForReply:(id)arg4  ;
-(id)_cacheForService:(id)arg0 ;
-(id)_cachedStatusForDestination:(id)arg0 service:(id)arg1 ;
-(id)_delegateMapForListenerID:(id)arg0 service:(id)arg1 ;
-(id)init;
-(id)initWithDelegateContext:(id)arg0 queueController:(id)arg1 ;
-(void)IDQueryCompletedWithFromURI:(id)arg0 idStatusUpdates:(id)arg1 service:(id)arg2 success:(BOOL)arg3 error:(id)arg4 ;
-(void)___oldDealloc;
-(void)_callDelegatesWithBlock:(id)arg0 ;
// -(void)_callDelegatesWithBlock:(id)arg0 delegateMap:(unk)arg1  ;
-(void)_connect;
-(void)_disconnectFromQueryService;
-(void)_idStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 allowRenew:(BOOL)arg3 respectExpiry:(BOOL)arg4 waitForReply:(BOOL)arg5 forceRefresh:(BOOL)arg6 bypassLimit:(BOOL)arg7 completionBlock:(id)arg8 ;
-(void)_purgeIDStatusCache;
-(void)_purgeIDStatusCacheAfter:(CGFloat)arg0 ;
-(void)_requestCacheForService:(id)arg0 completionBlock:(id)arg1 ;
-(void)_requestCachedStatusForDestinations:(id)arg0 service:(id)arg1 waitForReply:(BOOL)arg2 respectExpiry:(BOOL)arg3 listenerID:(id)arg4 completionBlock:(id)arg5 ;
-(void)_requestIDInfoForDestinations:(id)arg0 service:(id)arg1 infoTypes:(NSUInteger)arg2 options:(id)arg3 listenerID:(id)arg4 queue:(id)arg5 completionBlock:(id)arg6 ;
-(void)_requestRemoteDevicesForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 waitForReply:(BOOL)arg3 completionBlock:(id)arg4 ;
-(void)_requestStatusForDestinations:(id)arg0 service:(id)arg1 waitForReply:(BOOL)arg2 forceRefresh:(BOOL)arg3 bypassLimit:(BOOL)arg4 listenerID:(id)arg5 completionBlock:(id)arg6 ;
-(void)_setCurrentIDStatus:(NSInteger)arg0 forDestination:(id)arg1 service:(id)arg2 ;
-(void)_updateCacheWithDictionary:(id)arg0 service:(id)arg1 ;
-(void)addDelegate:(id)arg0 forService:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 ;
-(void)addDelegate:(id)arg0 queue:(id)arg1 ;
-(void)addListenerID:(id)arg0 forService:(id)arg1 ;
-(void)daemonDisconnected;
-(void)dealloc;
-(void)removeDelegate:(id)arg0 ;
-(void)removeDelegate:(id)arg0 forService:(id)arg1 listenerID:(id)arg2 ;


@end


#endif
