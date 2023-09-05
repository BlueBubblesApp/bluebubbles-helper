// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMNICKNAMEAVATARIMAGE_H
#define IMNICKNAMEAVATARIMAGE_H

#import <Foundation/Foundation.h>


@interface IMNicknameAvatarImage : NSObject

@property (readonly, nonatomic) BOOL hasImage;
@property (copy, nonatomic) NSString* imageName;
@property (copy, nonatomic) NSString* imageFilePath;
@property (readonly, nonatomic) BOOL imageExists;

- (id) copyWithZone:(struct _NSZone*)arg1;
- (id) init;
- (id) description;
- (void) encodeWithCoder:(id)arg1;
- (id) initWithCoder:(id)arg1;
- (id) imageData;
- (id) dictionaryRepresentation;
- (id) initWithDictionaryRepresentation:(id)arg1;
- (id) imageName;
- (void) setImageName:(id)arg1;
- (BOOL) hasImage;
- (id) imageFilePath;
- (void) setImageFilePath:(id)arg1;
- (id) initWithImageName:(id)arg1 imageFilePath:(id)arg2;
- (id) initWithImageName:(id)arg1 imageData:(id)arg2 imageFilePath:(id)arg3 error:(id*)arg4;
- (BOOL) _writeImageData:(id)arg1 path:(id)arg2 error:(id*)arg3;
- (id) initWithPublicDictionaryMetadataRepresentation:(id)arg1;
- (id) initWithImageName:(id)arg1 imageData:(id)arg2 imageFilePath:(id)arg3;
- (id) initWithPublicDictionaryMetadataRepresentation:(id)arg1 imageData:(id)arg2 imageFilePath:(id)arg3 error:(id*)arg4;
- (id) publicDictionaryRepresentation;
- (id) publicDictionaryMetadataRepresentation;
- (id) loadAndReturnImageData;
- (BOOL) imageExists;


+ (BOOL) supportsSecureCoding;


@end


#endif
