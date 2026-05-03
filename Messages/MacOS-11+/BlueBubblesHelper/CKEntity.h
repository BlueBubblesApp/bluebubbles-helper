//
//  CKEntity.h
//  BlueBubblesHelper DyLib
//
//  Created by Tanay Neotia on 5/2/26.
//  Copyright © 2026 BlueBubbleMessaging. All rights reserved.
//


// Headers generated with ktool v2.0.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.5.0 | SDK: 16.5.0


#ifndef CKENTITY_H
#define CKENTITY_H

@class NSString, IMChat, IMAccount, CNContact, IMHandle, UIImage;



@interface CKEntity : NSObject

@property (readonly, copy, nonatomic) NSString *IDSCanonicalAddress;
@property (readonly, copy, nonatomic) NSString *abbreviatedDisplayName;
@property (retain, nonatomic) IMChat *chat; // ivar: _chat
@property (retain, nonatomic) IMAccount *chatAccount; // ivar: _chatAccount
@property (retain, nonatomic) CNContact *cnContact; // ivar: _cnContact
@property (readonly, nonatomic) IMHandle *defaultIMHandle;
@property (nonatomic) BOOL enlargedContactImage; // ivar: _enlargedContactImage
@property (readonly, copy, nonatomic) NSString *fullName;
@property (retain, nonatomic) IMHandle *handle; // ivar: _handle
@property (readonly, nonatomic) BOOL isMe;
@property (readonly, nonatomic) UIImage *locationMapViewContactImage;
@property (readonly, nonatomic) UIImage *locationShareBalloonContactImage;
@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, copy, nonatomic) NSString *originalAddress;
@property (readonly, nonatomic) NSString *propertyType;
@property (readonly, copy, nonatomic) NSString *rawAddress;
@property (readonly, copy, nonatomic) NSString *textToneIdentifier;
@property (readonly, copy, nonatomic) NSString *textVibrationIdentifier;
@property (readonly, nonatomic) UIImage *transcriptContactImage; // ivar: _transcriptContactImage
@property (readonly, nonatomic) UIImage *transcriptDrawerContactImage; // ivar: _transcriptDrawerContactImage


+(BOOL)string:(id)arg0 hasPrefix:(id)arg1 ;
+(id)_copyEntityForAddressString:(id)arg0 onAccount:(id)arg1 ;
+(id)copyEntityForAddressString:(id)arg0 ;
+(id)entityForAddress:(id)arg0 ;
-(BOOL)_allowedByScreenTime;
-(BOOL)isEqual:(id)arg0 ;
-(NSUInteger)hash;
-(id)_croppedImageFromImageData:(id)arg0 ;
-(id)cnContactWithKeys:(id)arg0 ;
-(id)cnContactWithKeys:(id)arg0 shouldFetchSuggestedContact:(BOOL)arg1 ;
-(id)description;
-(id)displayNameMatchingInputText:(id)arg0 ;
-(id)initWithChat:(id)arg0 imHandle:(id)arg1 ;
-(id)initWithIMHandle:(id)arg0 ;
-(id)mentionTokens;
-(id)mentionsHandleID;
-(id)personViewControllerWithDelegate:(id)arg0 isUnknown:(BOOL)arg1 ;
-(id)personViewControllerWithDelegate:(id)arg0 isUnknown:(BOOL)arg1 contactStoreProvider:(id)arg2 ;
-(id)pinnedConversationContactItemIdentifier;
-(void)_invalidateContactStoreCache:(id)arg0 ;
-(void)_invalidatePartialContactStoreCache:(id)arg0 ;
-(void)_setBusinessInfoForMutableContact:(id)arg0 enlargedImageData:(id)arg1 ;
-(void)addToken:(id)arg0 ifAvailableToTokens:(id)arg1 ;


@end


#endif
