// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMDDCONTROLLER_H
#define IMDDCONTROLLER_H

@protocol OS_dispatch_queue;

#import <Foundation/Foundation.h>


@interface IMDDController : NSObject

@property (retain, nonatomic) NSObject<OS_dispatch_queue> *scannerQueue; // ivar: _scannerQueue
@property (nonatomic, readonly) dispatch_queue_t queue;

+(id)sharedInstance;
-(BOOL)_scanAttributedStringWithMessage:(id)arg0 attributedString:(id)arg1 plainText:(id)arg2 ;
-(BOOL)_scanMessageUsingScanner:(id)arg0 attributedString:(id)arg1 ;
-(id)init;
-(struct __DDScanner *)sharedScanner;
-(void)_processLinkInAttributedString:(id)arg0 ;
-(void)scanMessage:(id)arg0 completionBlock:(id)arg1 ;
-(void)scanMessage:(id)arg0 outgoing:(BOOL)arg1 waitUntilDone:(BOOL)arg2 completionBlock:(id)arg3 ;


@end


#endif
