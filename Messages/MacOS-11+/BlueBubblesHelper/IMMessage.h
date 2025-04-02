#import <objc/NSObject.h>

@class IMHandle, IMMessageItem, NSArray, NSAttributedString, NSData, NSDate, NSDictionary, NSError, NSString;

typedef NS_ENUM(NSInteger, IMMessageDescriptionType) {
    IMMessageDescriptionAccessibility,
    IMMessageDescriptionAcknowledgement,
    IMMessageDescriptionConversationList,
    IMMessageDescriptionNotification,
    IMMessageDescriptionSiri,
    IMMessageDescriptionSPI,
};

@interface IMMessage : NSObject
{
    IMHandle *_sender;
    IMHandle *_subject;
    NSAttributedString *_text;
    NSString *_plainBody;
    NSDate *_time;
    NSDate *_timeDelivered;
    NSDate *_timeRead;
    NSDate *_timePlayed;
    NSString *_guid;
    NSAttributedString *_messageSubject;
    NSArray<NSString*> *_fileTransferGUIDs;
    NSError *_error;
    NSString *_balloonBundleID;
    NSData *_payloadData;
    NSString *_expressiveSendStyleID;
    NSDate *_timeExpressiveSendPlayed;
    unsigned long long _flags;
    BOOL _isInvitationMessage;
    long long _messageID;
    char _hasMention;
    long long _associatedMessageType;
    NSDictionary *_messageSummaryInfo;
    NSString *_associatedBalloonBundleID;
    NSString *_sourceApplicationID;
    NSData *_customTypingIndicatorIcon;
    NSString *_notificationIDSTokenURI;
    unsigned long long _sortID;
    struct _NSRange _associatedMessageRange;
}

+ (id)determineRichLinksInMessage:(id)arg1 additionalSupportedSchemes:(id)arg2;
+ (id)determineRichLinksInMessage:(id)arg1;
+ (BOOL)supportedRichLinkURL:(id)arg1 additionalSupportedSchemes:(id)arg2;
+ (BOOL)hasKnownSchemesForRichLinkURL:(id)arg1 additionalSupportedSchemes:(id)arg2;
+ (BOOL)hasKnownSchemesForRichLinkURL:(id)arg1;
+ (Class)richLinksDataSourceClass;
+ (id)messageFromIMMessageItemDictionary:(id)arg1 body:(id)arg2 sender:(id)arg3 subject:(id)arg4;
+ (IMMessage*)messageFromIMMessageItem:(id)arg1 sender:(id)arg2 subject:(id)arg3;
+ (id)fromMeIMHandle:(id)arg1 withText:(id)arg2 fileTransferGUIDs:(id)arg3 flags:(unsigned long long)arg4;
+ (IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 fileTransferGUIDs:(id)arg3 flags:(unsigned long long)arg4 balloonBundleID:(id)arg5 payloadData:(id)arg6 expressiveSendStyleID:(id)arg7;
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 fileTransferGUIDs:(id)arg3 flags:(unsigned long long)arg4;
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 fileTransferGUIDs:(id)arg3 flags:(unsigned long long)arg4 threadIdentifier:(id)arg5 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 flags:(unsigned long long)arg3 expressiveSendStyleID:(id)arg4;
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 flags:(unsigned long long)arg3;
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 flags:(unsigned long long)arg3 threadIdentifier:(NSString*)arg4 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 messageSubject:(id)arg2 flags:(unsigned long long)arg3 threadIdentifier:(NSString*)arg4 associatedMessageGUID:(id)arg5 scheduledDate:(id)arg6;
+ (nonnull IMMessage*)instantMessageWithText:(id)arg1 flags:(unsigned long long)arg2;
+ (id)defaultInvitationMessageFromSender:(id)arg1 flags:(unsigned long long)arg2;
+ (id)locatingMessageWithGuid:(id)arg1 error:(id)arg2;
+ (id)messageWithLocation:(id)arg1 flags:(unsigned long long)arg2 error:(id)arg3 guid:(id)arg4;
+ (id)_vCardDataWithCLLocation:(id)arg1;
+ (id)breadcrumbMessageWithText:(id)arg1 associatedMessageGUID:(id)arg2 balloonBundleID:(id)arg3 fileTransferGUIDs:(id)arg4 payloadData:(id)arg5 ;
+ (id)breadcrumbMessageWithText:(id)arg1 associatedMessageGUID:(id)arg2 balloonBundleID:(id)arg3 fileTransferGUIDs:(id)arg4 payloadData:(id)arg5 threadIdentifier:(id)arg6 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
+ (id)editedMessageWithOriginalMessage:(id)arg1 originalPrefixedGUID:(id)arg2 newBody:(id)arg3;
+ (IMMessage*)instantMessageWithAssociatedMessageContent:(id)arg1 flags:(unsigned long long)arg2 associatedMessageGUID:(id)arg3 associatedMessageType:(long long)arg4 associatedMessageRange:(struct _NSRange)arg5 messageSummaryInfo:(id)arg6 ;
+ (IMMessage*)instantMessageWithAssociatedMessageContent:(id)arg1 flags:(unsigned long long)arg2 associatedMessageGUID:(id)arg3 associatedMessageType:(long long)arg4 associatedMessageRange:(struct _NSRange)arg5 messageSummaryInfo:(id)arg6 threadIdentifier:(id)arg7 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
@property(nonatomic) unsigned long long sortID; // @synthesize sortID=_sortID;
@property(nonatomic) BOOL isSOS; // @synthesize isSOS=_isSOS;
@property(retain, nonatomic) NSString *notificationIDSTokenURI; // @synthesize notificationIDSTokenURI=_notificationIDSTokenURI;
@property(retain, nonatomic) NSData *customTypingIndicatorIcon; // @synthesize customTypingIndicatorIcon=_customTypingIndicatorIcon;
@property(retain, nonatomic) NSDate *timeExpressiveSendPlayed; // @synthesize timeExpressiveSendPlayed=_timeExpressiveSendPlayed;
@property(retain, nonatomic) NSString *expressiveSendStyleID; // @synthesize expressiveSendStyleID=_expressiveSendStyleID;
@property(retain, nonatomic) NSString *sourceApplicationID; // @synthesize sourceApplicationID=_sourceApplicationID;
@property(retain, nonatomic) NSString *associatedBalloonBundleID; // @synthesize associatedBalloonBundleID=_associatedBalloonBundleID;
@property(retain, nonatomic) NSData *payloadData; // @synthesize payloadData=_payloadData;
@property(retain, nonatomic) NSString *balloonBundleID; // @synthesize balloonBundleID=_balloonBundleID;
@property(retain, nonatomic, setter=_updateLocale:) NSString *locale; // @synthesize locale=_locale;
@property(retain, nonatomic, setter=_updateBizIntent:) NSDictionary *bizIntent; // @synthesize bizIntent=_bizIntent;
@property(copy, nonatomic, setter=_messageSummaryInfo:) NSDictionary *messageSummaryInfo; // @synthesize messageSummaryInfo=_messageSummaryInfo;
@property(nonatomic, setter=_associatedMessageRange:) struct _NSRange associatedMessageRange; // @synthesize associatedMessageRange=_associatedMessageRange;
@property(nonatomic, setter=_associatedMessageType:) long long associatedMessageType; // @synthesize associatedMessageType=_associatedMessageType;
@property(copy, nonatomic, setter=_associatedMessageGUID:) NSString *associatedMessageGUID; // @synthesize associatedMessageGUID=_associatedMessageGUID;
@property(retain, nonatomic, setter=_updateTimePlayed:) NSDate *timePlayed; // @synthesize timePlayed=_timePlayed;
@property(retain, nonatomic, setter=_updateTimeRead:) NSDate *timeRead; // @synthesize timeRead=_timeRead;
@property(retain, nonatomic, setter=_updateTimeDelivered:) NSDate *timeDelivered; // @synthesize timeDelivered=_timeDelivered;
@property(copy, nonatomic, setter=_updateFileTransferGUIDs:) NSArray<NSString*> *fileTransferGUIDs; // @synthesize fileTransferGUIDs=_fileTransferGUIDs;
@property(nonatomic) BOOL isInvitationMessage; // @synthesize isInvitationMessage=_isInvitationMessage;
- (char)hasMention;
@property(retain, nonatomic, setter=_updateError:) NSError *error; // @synthesize error=_error;
@property(nonatomic, setter=_updateFlags:) unsigned long long flags; // @synthesize flags=_flags;
@property(nonatomic, setter=_updateMessageID:) long long messageID; // @synthesize messageID=_messageID;
@property(retain, nonatomic, setter=_updateGUID:) NSString *guid; // @synthesize guid=_guid;
@property(retain, nonatomic, setter=_updateText:) NSAttributedString *text; // @synthesize text=_text;
@property(retain, nonatomic, setter=_updateTime:) NSDate *time; // @synthesize time=_time;
@property(readonly, nonatomic) NSAttributedString *messageSubject; // @synthesize messageSubject=_messageSubject;
@property(readonly, nonatomic) IMHandle *subject; // @synthesize subject=_subject;
@property(retain, nonatomic, setter=_updateSender:) IMHandle *sender; // @synthesize sender=_sender;
- (void)_ovverrideGUIDForTest:(id)arg1;
- (id)description;
- (BOOL)isEqual:(id)arg1;
- (id)messagesBySeparatingRichLinks;
@property(readonly, nonatomic) IMMessageItem *_imMessageItem;
- (long long)compare:(id)arg1 comparisonType:(long long)arg2;
- (long long)compare:(id)arg1;
@property(readonly, nonatomic) BOOL wasDataDetected;
@property(readonly, nonatomic) BOOL wasDowngraded;
@property(readonly, nonatomic) BOOL isAlert;
@property(readonly, nonatomic) BOOL isAddressedToMe;
- (void)setIsAddressedToMe:(BOOL)arg1;
@property(readonly, nonatomic) BOOL isSystemMessage;
@property(readonly, nonatomic) BOOL isPlayed;
@property(readonly, nonatomic) BOOL isAudioMessage;
@property(readonly, nonatomic) BOOL isRead;
@property(readonly, nonatomic) BOOL isDelivered;
@property(readonly, nonatomic) BOOL isAutoReply;
@property(readonly, nonatomic) BOOL isReply API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
@property(readonly, nonatomic) BOOL canReply API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
@property(readonly, nonatomic) BOOL isDelayed;
@property(readonly, nonatomic) BOOL isEmpty;
@property(readonly, nonatomic) BOOL isFromMe;
@property(readonly, nonatomic) BOOL isEmote;
@property(readonly, nonatomic) NSArray *inlineAttachmentAttributesArray;
@property(readonly, nonatomic) BOOL hasInlineAttachments;
@property(readonly, nonatomic) BOOL isSent;
@property(readonly, nonatomic) BOOL isLocatingMessage;
@property(readonly, nonatomic) BOOL isTypingMessage;
@property(readonly, nonatomic) BOOL isFinished;
@property(readonly, nonatomic) BOOL hasDataDetectorResults;
@property (assign,nonatomic) char hasMention;
@property(readonly, nonatomic) NSString *summaryString;
@property(readonly, nonatomic) NSString *senderName;
@property(readonly, nonatomic) NSString *plainBody;
- (id)initWithSender:(id)arg1 fileTransfer:(id)arg2;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 associatedMessageGUID:(id)arg10 associatedMessageType:(long long)arg11 associatedMessageRange:(struct _NSRange)arg12 messageSummaryInfo:(id)arg13;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 balloonBundleID:(id)arg10 payloadData:(id)arg11 expressiveSendStyleID:(id)arg12;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 fileTransferGUIDs:(id)arg4 flags:(unsigned long long)arg5 error:(id)arg6 guid:(id)arg7 subject:(id)arg8;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 balloonBundleID:(id)arg10 payloadData:(id)arg11 expressiveSendStyleID:(id)arg12 threadIdentifier:(id)arg13 scheduleType:(unsigned long long)arg14 scheduleState:(unsigned long long)arg15;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 balloonBundleID:(id)arg10 payloadData:(id)arg11 expressiveSendStyleID:(id)arg12 threadIdentifier:(id)arg13 scheduleType:(unsigned long long)arg14 scheduleState:(unsigned long long)arg15 messageSummaryInfo:(id)arg16;

- (id)_initWithSender:(id)arg1 time:(id)arg2 timeRead:(id)arg3 timeDelivered:(id)arg4 timePlayed:(id)arg5 plainText:(id)arg6 text:(id)arg7 messageSubject:(id)arg8 fileTransferGUIDs:(id)arg9 flags:(unsigned long long)arg10 error:(id)arg11 guid:(id)arg12 messageID:(long long)arg13 subject:(id)arg14 balloonBundleID:(id)arg15 payloadData:(id)arg16 expressiveSendStyleID:(id)arg17 timeExpressiveSendPlayed:(id)arg18 associatedMessageGUID:(id)arg19 associatedMessageType:(long long)arg20 associatedMessageRange:(struct _NSRange)arg21 messageSummaryInfo:(id)arg22;
- (id)_initWithSender:(id)arg1 time:(id)arg2 timeRead:(id)arg3 timeDelivered:(id)arg4 timePlayed:(id)arg5 plainText:(id)arg6 text:(id)arg7 messageSubject:(id)arg8 fileTransferGUIDs:(id)arg9 flags:(unsigned long long)arg10 error:(id)arg11 guid:(id)arg12 messageID:(long long)arg13 subject:(id)arg14 balloonBundleID:(id)arg15 payloadData:(id)arg16 expressiveSendStyleID:(id)arg17 timeExpressiveSendPlayed:(id)arg18 associatedMessageGUID:(id)arg19 associatedMessageType:(long long)arg20 associatedMessageRange:(NSRange)arg21 associatedMessageEmoji:(id)arg22 messageSummaryInfo:(id)arg23 threadIdentifier:(id)arg24 dateEdited:(id)arg25 scheduleType:(unsigned long long)arg26 scheduleState:(unsigned long long)arg27;
- (id)_copyWithFlags:(unsigned long long)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (NSString*)descriptionForPurpose:(IMMessageDescriptionType)arg1 inChat:(IMChat*)arg2 senderDisplayName:(NSString*)arg3;
- (NSString*)descriptionForPurpose:(IMMessageDescriptionType)arg1 inChat:(IMChat*)arg2;
- (NSString*)descriptionForPurpose:(IMMessageDescriptionType)arg1;
@property(readonly, nonatomic) BOOL isAssociatedMessage;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 associatedMessageGUID:(id)arg10 associatedMessageType:(long long)arg11 associatedMessageRange:(struct _NSRange)arg12 associatedMessageInfo:(id)arg13;
- (NSString*) threadIdentifier API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
- (void) setThreadIdentifier:(NSString*)arg1 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
- (IMMessage*) threadOriginator API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
- (void) setThreadOriginator:(IMMessage*)arg2 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
- (long long) replyCountsByPart API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
- (void) setReplyCountsByPart:(long long)arg1 API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
- (void)setHasMention:(char)arg1;
- (void)setScheduleType:(unsigned long long)arg1;
- (void)setScheduleState:(unsigned long long)arg1;
@end

