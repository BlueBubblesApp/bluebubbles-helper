// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef FMFHANDLE_H
#define FMFHANDLE_H

@class NSString, NSArray, NSNumber, NSDictionary;

#import <Foundation/Foundation.h>

@interface FMFHandle : NSObject



@property (copy, nonatomic) NSString *_prettyNameInternal; // ivar: __prettyNameInternal
@property (copy, nonatomic) NSArray *aliasServerIds; // ivar: _aliasServerIds
@property (copy, nonatomic) NSNumber *dsid; // ivar: _dsid
@property (copy, nonatomic) NSDictionary *expiresByGroupId; // ivar: _expiresByGroupId
@property (copy, nonatomic) NSNumber *favoriteOrder; // ivar: _favoriteOrder
@property (copy, nonatomic) NSString *hashedDSID; // ivar: _hashedDSID
@property (copy, nonatomic) NSString *identifier; // ivar: _identifier
@property (nonatomic) NSInteger idsStatus; // ivar: _idsStatus
@property (copy, nonatomic) NSArray *invitationSentToIds; // ivar: _invitationSentToIds
@property (nonatomic) BOOL isFamilyMember; // ivar: _isFamilyMember
@property (nonatomic, getter=isPending) BOOL pending; // ivar: _pending
@property (copy, nonatomic) NSString *qualifiedIdentifier; // ivar: _qualifiedIdentifier
@property (nonatomic) BOOL reachable; // ivar: _reachable
@property (copy, nonatomic) NSString *serverId; // ivar: _serverId
@property (copy, nonatomic) NSNumber *trackingTimestamp; // ivar: _trackingTimestamp


+(BOOL)supportsSecureCoding;
+(id)familyHandleWithId:(id)arg0 dsid:(id)arg1 ;
+(id)handleWithId:(id)arg0 ;
+(id)handleWithId:(id)arg0 serverId:(id)arg1 ;
-(BOOL)isEqual:(id)arg0 ;
-(BOOL)isPhoneNumber;
-(BOOL)isSharingThroughGroupId:(id)arg0 ;
-(NSInteger)prettyNameCompare:(id)arg0 ;
-(NSUInteger)hash;
-(id)cachedPrettyName;
-(id)comparisonIdentifier;
-(id)copyWithZone:(struct _NSZone *)arg0 ;
-(id)debugDescription;
-(id)description;
-(id)initWithCoder:(id)arg0 ;
-(id)prettyName;
-(id)recordId;
-(id)sanitizePhoneNumber:(id)arg0 ;
-(void)abPreferencesDidChange;
-(void)addressBookDidChange;
-(void)clearFavoriteOrder;
-(void)encodeWithCoder:(id)arg0 ;
-(void)prettyNameWithCompletion:(id)arg0 ;
-(void)setICloudId:(id)arg0 ;


@end


#endif
