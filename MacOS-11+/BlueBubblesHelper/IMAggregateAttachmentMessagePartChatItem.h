// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMAGGREGATEATTACHMENTMESSAGEPARTCHATITEM_H
#define IMAGGREGATEATTACHMENTMESSAGEPARTCHATITEM_H

@class NSArray;


#import "IMAttachmentMessagePartChatItem.h"

@interface IMAggregateAttachmentMessagePartChatItem : IMAttachmentMessagePartChatItem

@property (copy, nonatomic) NSArray *aggregateAttachmentParts; // ivar: _aggregateAttachmentParts
@property (readonly, copy, nonatomic) NSArray *transferGUIDs; // ivar: _transferGUIDs


-(BOOL)isAttachmentContiguousWithChatItem:(id)arg0 ;
-(id)_initWithItem:(id)arg0 text:(id)arg1 index:(NSInteger)arg2 messagePartRange:(struct _NSRange )arg3 transferGUIDs:(id)arg4 chatContext:(id)arg5 ;
-(id)_initWithItem:(id)arg0 text:(id)arg1 index:(NSInteger)arg2 messagePartRange:(struct _NSRange )arg3 transferGUIDs:(id)arg4 chatContext:(id)arg5 visibleAssociatedMessageChatItems:(id)arg6 ;
-(id)copyWithZone:(struct _NSZone *)arg0 ;
-(id)description;
-(id)replyContextPreviewChatItemForReply:(id)arg0 chatContext:(id)arg1 ;


@end


#endif
