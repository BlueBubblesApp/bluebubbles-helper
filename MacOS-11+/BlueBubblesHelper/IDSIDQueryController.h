// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IDSIDQUERYCONTROLLER_H
#define IDSIDQUERYCONTROLLER_H


#import <Foundation/Foundation.h>

#import "_IDSIDQueryController.h"
#import "IDSInternalQueueController.h"

@interface IDSIDQueryController : NSObject {
    _IDSIDQueryController *_internal;
    IDSInternalQueueController *_queueController;
}




+(instancetype)sharedInstance;
-(BOOL)_flushQueryCacheForService:(id)arg0 ;
-(BOOL)_hasCacheForService:(id)arg0 ;
-(BOOL)_warmupQueryCacheForService:(id)arg0 ;
-(BOOL)currentIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)currentIDStatusForDestination:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(id)arg5 ;
-(BOOL)currentIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)currentIDStatusForDestinations:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(id)arg5 ;
-(BOOL)currentRemoteDevicesForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)forceRefreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)idInfoForDestinations:(id)arg0 service:(id)arg1 infoTypes:(NSUInteger)arg2 options:(id)arg3 listenerID:(id)arg4 queue:(id)arg5 completionBlock:(id)arg6 ;
-(BOOL)participantsForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)refreshIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)refreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)refreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 errorCompletionBlock:(id)arg4 ;
-(BOOL)removeListenerID:(id)arg0 forService:(id)arg1 ;
-(BOOL)requestIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)requestIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)requiredIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(BOOL)requiredIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 completionBlock:(id)arg4 ;
-(NSInteger)_currentCachedIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
-(NSInteger)_currentIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
-(NSInteger)_currentIDStatusForDestination:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 ;
-(NSInteger)_refreshIDStatusForDestination:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
-(id)_currentCachedRemoteDevicesForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
-(id)_currentIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
-(id)_currentIDStatusForDestinations:(id)arg0 service:(id)arg1 respectExpiry:(BOOL)arg2 listenerID:(id)arg3 ;
-(id)_refreshIDStatusForDestinations:(id)arg0 service:(id)arg1 listenerID:(id)arg2 ;
-(id)init;
-(void)_setCurrentIDStatus:(NSInteger)arg0 forDestination:(id)arg1 service:(id)arg2 ;
-(void)addDelegate:(id)arg0 forService:(id)arg1 listenerID:(id)arg2 queue:(id)arg3 ;
-(void)addDelegate:(id)arg0 queue:(id)arg1 ;
-(void)addListenerID:(id)arg0 forService:(id)arg1 ;
-(void)dealloc;
-(void)removeDelegate:(id)arg0 ;
-(void)removeDelegate:(id)arg0 forService:(id)arg1 listenerID:(id)arg2 ;


@end


#endif
