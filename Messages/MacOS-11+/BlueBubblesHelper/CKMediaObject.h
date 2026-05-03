//
//  CKMediaObject.h
//  BlueBubblesHelper DyLib
//
//  Created by Tanay Neotia on 5/2/26.
//  Copyright © 2026 BlueBubbleMessaging. All rights reserved.
//


// Headers generated with ktool v2.0.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.5.0 | SDK: 16.5.0


#ifndef CKMEDIAOBJECT_H
#define CKMEDIAOBJECT_H

@class NSString, NSURL, NSData, NSDate, NSDictionary, UITraitCollection;
@protocol QLPreviewItem, OS_dispatch_group, CKFileTransfer;


#import "CKMessageContext.h"

@interface CKMediaObject : NSObject 



@property (readonly, copy, nonatomic) NSString *UTIType;
@property (copy, nonatomic) NSURL *alternateShareURL; // ivar: _alternateShareURL
@property (retain, nonatomic) NSURL *cachedHighQualityFileURL; // ivar: _cachedHighQualityFileURL
@property (nonatomic) BOOL cachedValidPreviewExists; // ivar: _cachedValidPreviewExists
@property (readonly, nonatomic) BOOL canShareItem;
@property (readonly, nonatomic) NSInteger commSafetySensitive;
@property (readonly, copy, nonatomic) NSData *data;
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (readonly, copy, nonatomic) NSURL *fileURL;
@property (readonly, copy, nonatomic) NSString *filename;
@property (nonatomic) BOOL forceInlinePreviewGeneration; // ivar: _forceInlinePreviewGeneration
@property (readonly, nonatomic) BOOL generatePreviewOutOfProcess;
@property (readonly) NSUInteger hash;
@property (retain, nonatomic) NSObject *highQualityFetchInProgressGroup; // ivar: _highQualityFetchInProgressGroup
@property (readonly, nonatomic) BOOL isFromMe;
@property (readonly, nonatomic) BOOL isPhotosCompatible;
@property (readonly, nonatomic) int mediaType;
@property (copy, nonatomic) CKMessageContext *messageContext; // ivar: _messageContext
@property (readonly, nonatomic) NSString *metricsCollectorMediaType;
@property (readonly, copy, nonatomic) NSString *mimeType;
@property (readonly, nonatomic) BOOL needsAnimation;
@property (nonatomic) NSUInteger oopPreviewRequestCount; // ivar: _oopPreviewRequestCount
@property (readonly, copy, nonatomic) NSString *previewFilenameExtension;
@property (readonly, nonatomic) NSString *previewItemTitle;
@property (readonly, nonatomic) NSURL *previewItemURL;
@property (readonly, nonatomic) BOOL shouldSuppressPreview;
@property (readonly) Class superclass;
@property (readonly, nonatomic) BOOL supportsUnknownSenderPreview; // ivar: _supportsUnknownSenderPreview
@property (readonly, nonatomic) NSString *syndicationIdentifier;
@property (retain, nonatomic) NSDate *time; // ivar: _time
@property (readonly, copy, nonatomic) NSDictionary *transcoderUserInfo;
@property (retain, nonatomic) UITraitCollection *transcriptTraitCollection; // ivar: _transcriptTraitCollection
@property (retain, nonatomic) NSObject *transfer; // ivar: _transfer
@property (readonly, copy, nonatomic) NSString *transferGUID;
@property (readonly, nonatomic) BOOL validatePreviewFormat;


+(BOOL)canGeneratePreviewInMVSHostProcess;
+(BOOL)isPreviewable;
+(BOOL)shouldScaleUpPreview;
+(BOOL)shouldShadePreview;
+(BOOL)shouldUseTranscoderGeneratedPreviewSize;
+(Class)__ck_attachmentItemClass;
+(id)fallbackFilenamePrefix;
+(id)iconCache;
+(id)mediaClasses;
-(BOOL)canExport;
-(BOOL)canPerformQuickAction;
-(BOOL)isDirectory;
-(BOOL)isEqual:(id)arg0 ;
-(BOOL)isPreviewable;
-(BOOL)isPromisedItem;
-(BOOL)shouldBeQuickLooked;
-(BOOL)shouldShowDisclosure;
-(BOOL)shouldShowViewer;
-(BOOL)transcoderPreviewGenerationFailed;
-(BOOL)validPreviewExistsAtURL:(id)arg0 ;
-(CGFloat)defaultPreviewWidth;
-(Class)balloonViewClass;
-(Class)balloonViewClassForWidth:(CGFloat)arg0 orientation:(char)arg1 ;
-(Class)inlineStickerBalloonViewClass;
-(Class)placeholderBalloonViewClass;
-(Class)previewBalloonViewClass;
-(id)ASTCDataFromImage:(id)arg0 ;
-(id)JPEGDataFromImage:(id)arg0 ;
-(id)_balloonViewForClassWithWidth:(CGFloat)arg0 orientation:(char)arg1 ;
-(id)_composeImageForBalloonView:(id)arg0 colorType:(char)arg1 traitCollection:(id)arg2 ;
-(id)_generateIconWithSize:(struct CGSize )arg0 scale:(CGFloat)arg1 ;
-(id)_qlThumbnailGeneratorSharedGenerator;
-(id)_transcodeControllerSharedInstance;
-(id)attachmentSummary:(NSUInteger)arg0 ;
-(id)bbPreviewFillToSize:(struct CGSize )arg0 ;
-(id)composeImagesForEntryContentViewWidth:(CGFloat)arg0 traitCollection:(id)arg1 ;
-(id)fileManager;
-(id)fileSizeString;
-(id)generatePreviewFromThumbnail:(id)arg0 width:(CGFloat)arg1 orientation:(char)arg2 ;
-(id)generateThumbnailFillToSize:(struct CGSize )arg0 contentAlignmentInsets:(struct UIEdgeInsets )arg1 ;
-(id)generateThumbnailForWidth:(CGFloat)arg0 orientation:(char)arg1 ;
-(id)icon;
-(id)image:(id)arg0 withBackgroundColor:(id)arg1 ;
-(id)initWithTransfer:(id)arg0 context:(id)arg1 forceInlinePreview:(BOOL)arg2 ;
-(id)invisibleInkEffectImageWithPreview:(id)arg0 ;
-(id)location;
-(id)pasteboardItemProvider;
-(id)previewCacheKeyWithOrientation:(char)arg0 ;
-(id)previewCachesFileURLWithOrientation:(char)arg0 extension:(id)arg1 generateIntermediaries:(BOOL)arg2 ;
-(id)previewDispatchCache;
-(id)previewForWidth:(CGFloat)arg0 orientation:(char)arg1 ;
-(id)richIcon;
-(id)rtfDocumentItemsWithFormatString:(id)arg0 selectedTextRange:(struct _NSRange )arg1 ;
-(id)savedPreviewFromURL:(id)arg0 forOrientation:(char)arg1 ;
-(id)subtitle;
-(id)title;
-(struct CGSize )bbSize;
-(struct CGSize )transcoderGeneratedSizeForConstraints:(struct IMPreviewConstraints )arg0 ;
-(struct CGSize )transcodingPreviewPxSize;
-(struct IMPreviewConstraints )_previewConstraintsForWidth:(CGFloat)arg0 ;
-(struct IMPreviewConstraints )transcodingPreviewConstraints;
-(void)_sampleImageEdges:(id)arg0 usingRect:(struct CGRect )arg1 forMostlyWhitePixels:(NSUInteger)arg2 otherPixels:(NSUInteger)arg3 ;
-(void)cacheAndPersistPreview:(id)arg0 orientation:(char)arg1 ;
-(void)dealloc;
-(void)fetchHighQualityFile:(id)arg0 ;
-(void)generateOOPPreviewForWidth:(CGFloat)arg0 orientation:(char)arg1 ;
-(void)prewarmPreviewForWidth:(CGFloat)arg0 orientation:(char)arg1 ;
-(void)savePreview:(id)arg0 toURL:(id)arg1 forOrientation:(char)arg2 ;


@end


#endif
