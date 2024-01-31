// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef FMFSESSIONDATAMANAGER_H
#define FMFSESSIONDATAMANAGER_H

@class NSSet, NSMutableDictionary;

#import <Foundation/Foundation.h>


@interface FMFSessionDataManager : NSObject

@property (retain, nonatomic) NSSet *fences; // ivar: _fences
@property (retain, nonatomic) NSSet *followers; // ivar: _followers
@property (retain, nonatomic) NSSet *following; // ivar: _following
@property (retain, nonatomic) NSSet *locations; // ivar: _locations
@property (retain, nonatomic) NSMutableDictionary *locationsCache; // ivar: _locationsCache


+(id)sharedInstance;
-(id)favoritesOrdered;
-(id)followerForHandle:(id)arg0 ;
-(id)followingForHandle:(id)arg0 ;
-(id)locationForHandle:(id)arg0 ;
-(id)offerExpirationForHandle:(id)arg0 groupId:(id)arg1 ;
-(void)abDidChange;
-(void)abPreferencesDidChange;


@end


#endif
