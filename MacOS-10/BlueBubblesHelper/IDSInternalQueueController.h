// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IDSINTERNALQUEUECONTROLLER_H
#define IDSINTERNALQUEUECONTROLLER_H

@protocol OS_dispatch_queue;

#import <Foundation/Foundation.h>


@interface IDSInternalQueueController : NSObject {
    NSObject<OS_dispatch_queue> *_queue;
}




+(id)sharedInstance;
-(BOOL)assertQueueIsCurrent;
-(BOOL)assertQueueIsNotCurrent;
-(BOOL)isQueueCurrent;
-(id)init;
-(id)initWithQueue:(id)arg0 ;
-(id)queue;
-(void)performBlock:(id)arg0 ;
// -(void)performBlock:(id)arg0 waitUntilDone:(unk)arg1  ;


@end


#endif
