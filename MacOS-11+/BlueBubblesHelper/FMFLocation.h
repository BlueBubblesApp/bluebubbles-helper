// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef FMFLOCATION_H
#define FMFLOCATION_H

@class NSString, UIImage, CLLocation, FMAccuracyOverlay, NSDate, UIColor;

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "FMFHandle.h"

@interface FMFLocation : NSObject



@property (nonatomic) CGFloat TTL; // ivar: _TTL
@property (nonatomic) NSInteger activityState; // ivar: _activityState
@property (retain, nonatomic) NSString *age; // ivar: _age
@property (nonatomic) CLLocationCoordinate2D coordinate; // ivar: _coordinate
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (nonatomic) CGFloat distance; // ivar: _distance
@property (retain, nonatomic) NSString *distanceDescription; // ivar: _distanceDescription
@property (nonatomic) CGFloat distanceFromUser; // ivar: _distanceFromUser
@property (retain, nonatomic) FMFHandle *handle; // ivar: _handle
@property (readonly) NSUInteger hash;
@property (nonatomic) CGFloat horizontalAccuracy; // ivar: _horizontalAccuracy
@property (nonatomic) BOOL isBorderEnabled; // ivar: _isBorderEnabled
@property (retain, nonatomic) NSString *label; // ivar: _label
@property (retain, nonatomic) NSObject *largeAnnotationIcon; // ivar: _largeAnnotationIcon
@property (retain, nonatomic) NSObject *largeOverlayIcon; // ivar: _largeOverlayIcon
@property (nonatomic, getter=isLocatingInProgress) BOOL locatingInProgress; // ivar: _locatingInProgress
@property (retain, nonatomic) CLLocation *location; // ivar: _location
@property (nonatomic) NSInteger locationType; // ivar: _locationType
@property (copy, nonatomic) NSString *longAddress; // ivar: _longAddress
@property (nonatomic) CGFloat maxLocatingInterval; // ivar: _maxLocatingInterval
@property (retain, nonatomic) NSObject *overlay; // ivar: _overlay
@property (retain, nonatomic) NSObject *placemark; // ivar: _placemark
@property (readonly, copy, nonatomic) NSString *shortAddress;
@property (copy, nonatomic) NSString *shortAddressString; // ivar: _shortAddressString
@property (retain, nonatomic) NSObject *smallAnnotationIcon; // ivar: _smallAnnotationIcon
@property (retain, nonatomic) NSObject *smallOverlayIcon; // ivar: _smallOverlayIcon
@property (readonly, copy, nonatomic) NSString *subtitle;
@property (readonly) Class superclass;
@property (copy, nonatomic) NSDate *timestamp; // ivar: _timestamp
@property (retain, nonatomic) NSObject *tintColor; // ivar: _tintColor
@property (readonly, copy, nonatomic) NSString *title;


+(BOOL)supportsSecureCoding;
-(BOOL)conformsToProtocol:(id)arg0 ;
-(BOOL)hasKnownLocation;
-(BOOL)isEqual:(id)arg0 ;
-(BOOL)isMoreRecentThan:(id)arg0 ;
-(BOOL)isThisDevice;
-(BOOL)isValid;
-(NSInteger)distanceThenNameCompare:(id)arg0 ;
-(id)agingItemTimestamp;
-(id)copyWithZone:(struct _NSZone *)arg0 ;
-(id)initWithCoder:(id)arg0 ;
-(id)initWithDictionary:(id)arg0 forHandle:(id)arg1 maxLocatingInterval:(CGFloat)arg2 TTL:(CGFloat)arg3 ;
-(id)initWithHandle:(id)arg0 locationType:(NSInteger)arg1 location:(id)arg2 activityState:(NSInteger)arg3 label:(id)arg4 locatingInProgress:(BOOL)arg5 shortAddress:(id)arg6 longAddress:(id)arg7 placemark:(id)arg8 ;
-(id)initWithLatitude:(CGFloat)arg0 longitude:(CGFloat)arg1 ;
-(void)_updateLocation:(id)arg0 ;
-(void)encodeWithCoder:(id)arg0 ;
-(void)resetLocateInProgress:(id)arg0 ;
-(void)resetLocateInProgressTimer;
-(void)updateHandle:(id)arg0 ;
-(void)updateLocation:(id)arg0 ;
-(void)updateLocationForCache:(id)arg0 ;


@end


#endif
