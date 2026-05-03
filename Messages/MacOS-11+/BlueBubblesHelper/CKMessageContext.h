//
//  CKMessageContext.h
//  BlueBubblesHelper DyLib
//
//  Created by Tanay Neotia on 5/2/26.
//  Copyright © 2026 BlueBubbleMessaging. All rights reserved.
//


// Headers generated with ktool v2.0.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.5.0 | SDK: 16.5.0


#ifndef CKMESSAGECONTEXT_H
#define CKMESSAGECONTEXT_H

@class IMChatContext;
@protocol NSCopying, NSMutableCopying;


@interface CKMessageContext : NSObject 



@property (readonly, nonatomic, getter=isAudioMessage) BOOL audioMessage; // ivar: _audioMessage
@property (readonly, copy, nonatomic) IMChatContext *chatContext; // ivar: _chatContext
@property (readonly, nonatomic, getter=isFromMe) BOOL fromMe; // ivar: _fromMe
@property (readonly, nonatomic, getter=isSenderUnauthenticated) BOOL senderUnauthenticated; // ivar: _senderUnauthenticated
@property (readonly, nonatomic, getter=isSenderUnknown) BOOL senderUnknown; // ivar: _senderUnknown
@property (readonly, nonatomic, getter=isSpam) BOOL spam; // ivar: _spam


+(id)selfContext;
-(id)_copyWithClass:(Class)arg0 zone:(struct _NSZone *)arg1 ;
-(id)copyWithZone:(struct _NSZone *)arg0 ;
-(id)description;
-(id)mutableCopyWithZone:(struct _NSZone *)arg0 ;


@end


#endif
