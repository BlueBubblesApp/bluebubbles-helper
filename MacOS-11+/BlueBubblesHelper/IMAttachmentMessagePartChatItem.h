// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMATTACHMENTMESSAGEPARTCHATITEM_H
#define IMATTACHMENTMESSAGEPARTCHATITEM_H

@class NSString;


#import "IMMessagePartChatItem.h"

@interface IMAttachmentMessagePartChatItem : IMMessagePartChatItem

@property (nonatomic) BOOL needsReloadForCommSafetyStateChange; // ivar: _needsReloadForCommSafetyStateChange
@property (nonatomic) NSUInteger numberOfMomentSharePhotos; // ivar: _numberOfMomentSharePhotos
@property (nonatomic) NSUInteger numberOfMomentShareSavedAssets; // ivar: _numberOfMomentShareSavedAssets
@property (nonatomic) NSUInteger numberOfMomentShareVideos; // ivar: _numberOfMomentShareVideos
@property (readonly, nonatomic) BOOL parentChatIsSpam;
@property (readonly, copy, nonatomic) NSString *transferGUID; // ivar: _transferGUID
@property (readonly, nonatomic) BOOL wantsAttachmentContiguous; // ivar: _wantsAttachmentContiguous


-(BOOL)_wantsAttachmentContiguousForType:(id)arg0 ;
-(BOOL)isAttachmentContiguousWithChatItem:(id)arg0 ;
-(NSInteger)syndicationBehavior;
-(id)_initWithItem:(id)arg0 text:(id)arg1 index:(NSInteger)arg2 messagePartRange:(struct _NSRange )arg3 transferGUID:(id)arg4 chatContext:(id)arg5 ;
-(id)_initWithItem:(id)arg0 text:(id)arg1 index:(NSInteger)arg2 messagePartRange:(struct _NSRange )arg3 transferGUID:(id)arg4 chatContext:(id)arg5 visibleAssociatedMessageChatItems:(id)arg6 ;
-(id)copyWithZone:(struct _NSZone *)arg0 ;
-(id)description;
-(id)layoutGroupIdentifier;
-(id)messageSummaryInfo;
-(id)replyContextPreviewChatItemForReply:(id)arg0 chatContext:(id)arg1 ;
-(unsigned char)contentType;


@end


#endif
