// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMNICKNAME_H
#define IMNICKNAME_H

#import <Foundation/Foundation.h>
#import "IMNicknameAvatarImage.h"


@interface IMNickname : NSObject

@property (copy, nonatomic) NSString* firstName;
@property (copy, nonatomic) NSString* lastName;
@property (retain, nonatomic) IMNicknameAvatarImage* avatar;
@property (retain, nonatomic) NSString* displayName;
@property (retain, nonatomic) NSString* handle;
@property (retain, nonatomic) NSString* recordID;
@property (readonly, nonatomic) NSString* nameHash;
@property (readonly, nonatomic) NSString* imageHash;

- (BOOL) isEqual:(id)arg1;
- (id) copyWithZone:(struct _NSZone*)arg1;
- (id) init;
- (id) description;
- (id) handle;
- (void) encodeWithCoder:(id)arg1;
- (id) initWithCoder:(id)arg1;
- (id) dataRepresentation;
- (id) displayName;
- (id) dictionaryRepresentation;
- (void) setDisplayName:(id)arg1;
- (id) firstName;
- (id) initWithDictionaryRepresentation:(id)arg1;
- (id) recordID;
- (void) setHandle:(id)arg1;
- (void) setRecordID:(id)arg1;
- (id) lastName;
- (void) setFirstName:(id)arg1;
- (void) setLastName:(id)arg1;
- (id) avatar;
- (void) setAvatar:(id)arg1;
- (id) imageHash;
- (id) publicDictionaryRepresentation;
- (id) initWithFirstName:(id)arg1 lastName:(id)arg2 avatar:(id)arg3;
- (id) _imageHashCreatedInChunks;
- (id) nameHash;
- (id) initWithMeContact:(id)arg1;
- (id) initWithPublicDictionaryRepresentationWithoutAvatar:(id)arg1;
- (id) publicDictionaryRepresentationWithoutAvatar;
- (id) _sharingState;
- (BOOL) isUpdateFromNickname:(id)arg1 withOptions:(unsigned long)arg2;
- (void) updateNameFromContact:(id)arg1;


+ (BOOL) supportsSecureCoding;
+ (id) uniqueFilePathForWritingImageData;
+ (id) nameHashWithFirstName:(id)arg1 lastName:(id)arg2;


@end


#endif
