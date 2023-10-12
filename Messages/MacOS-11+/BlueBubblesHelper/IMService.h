// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMSERVICE_H
#define IMSERVICE_H


#import <Foundation/Foundation.h>


@interface IMService : NSObject



+(BOOL)isEmailAddress:(id)arg0 inDomains:(id)arg1 ;
+(NSUInteger)myStatus;
+(id)aimService;
+(id)allServices;
+(id)allServicesNonBlocking;
+(id)callService;
+(id)canonicalFormOfID:(id)arg0 withIDSensitivity:(int)arg1 ;
+(id)facetimeService;
+(id)iMessageService;
+(id)imageNameForStatus:(NSUInteger)arg0 ;
+(id)imageURLForStatus:(NSUInteger)arg0 ;
+(id)jabberService;
+(id)myIdleTime;
+(id)notificationCenter;
+(id)serviceWithName:(id)arg0 ;
+(id)smsService;
+(id)subnetService;
+(void)forgetStatusImageAppearance;
-(BOOL)initialSyncPerformed;
-(BOOL)isEnabled;
-(NSUInteger)status;
-(id)canonicalFormOfID:(id)arg0 ;
-(id)copyWithZone:(struct _NSZone *)arg0 ;
-(id)infoForAllPeople;
-(id)infoForAllScreenNames;
-(id)infoForDisplayedPeople;
-(id)infoForPerson:(id)arg0 ;
-(id)infoForPreferredScreenNames;
-(id)infoForScreenName:(id)arg0 ;
-(id)localizedName;
-(id)localizedShortName;
-(id)myScreenNames;
-(id)name;
-(id)peopleWithScreenName:(id)arg0 ;
-(id)screenNamesForPerson:(id)arg0 ;
-(void)login;
-(void)logout;


@end


#endif
