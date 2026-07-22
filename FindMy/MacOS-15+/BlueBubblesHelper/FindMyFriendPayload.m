#import "FindMyFriendPayload.h"

#import <math.h>

@protocol BBFindMyLocation <NSObject>
- (double)altitude;
- (id)coarseAddressLabel;
- (double)horizontalAccuracy;
- (id)labels;
- (double)latitude;
- (long long)locationType;
- (double)longitude;
- (double)speed;
- (double)timestamp;
- (double)verticalAccuracy;
@end

@implementation FindMyFriendPayload

+ (nullable id)valueForSelector:(SEL)selector onObject:(nullable id)object {
    if (object == nil || ![object respondsToSelector:selector]) {
        return nil;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [object performSelector:selector];
#pragma clang diagnostic pop
}

+ (nullable NSString *)nonEmptyString:(nullable id)value {
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSString *trimmedString = [(NSString *)value
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedString.length > 0 ? trimmedString : nil;
}

+ (nullable NSString *)firstStringInArray:(nullable id)value {
    if (![value isKindOfClass:[NSArray class]]) {
        return nil;
    }

    for (id label in (NSArray *)value) {
        NSString *nonEmptyLabel = [self nonEmptyString:label];
        if (nonEmptyLabel != nil) {
            return nonEmptyLabel;
        }
    }

    return nil;
}

+ (id)numberForFiniteValue:(double)value {
    return isfinite(value) ? @(value) : [NSNull null];
}

+ (NSString *)statusForLocationType:(long long)locationType {
    if (locationType == 2) {
        return @"live";
    }
    if (locationType == 0) {
        return @"legacy";
    }
    return @"shallow";
}

+ (nullable NSString *)identifierForHandle:(nullable id)handle {
    SEL identifierSelector = NSSelectorFromString(@"identifier");
    NSString *primaryIdentifier = [self nonEmptyString:[self valueForSelector:identifierSelector onObject:handle]];
    if (primaryIdentifier != nil) {
        return primaryIdentifier;
    }

    SEL comparisonIdentifierSelector = NSSelectorFromString(@"comparisonIdentifier");
    return [self nonEmptyString:[self valueForSelector:comparisonIdentifierSelector onObject:handle]];
}

+ (nullable NSDictionary *)locationPayloadForLocation:(nullable id)location handle:(nullable id)handle {
    NSString *friendIdentifier = [self identifierForHandle:handle];
    if (friendIdentifier == nil) {
        return nil;
    }

    if (location == nil) {
        return @{
            @"handle": friendIdentifier,
            @"coordinates": [NSNull null],
            @"long_address": [NSNull null],
            @"short_address": [NSNull null],
            @"subtitle": [NSNull null],
            @"title": [NSNull null],
            @"last_updated": [NSNull null],
            @"is_locating_in_progress": @NO,
            @"status": @"legacy",
            @"location_type": [NSNull null],
            @"horizontal_accuracy": [NSNull null],
            @"vertical_accuracy": [NSNull null],
            @"speed": [NSNull null],
            @"altitude": [NSNull null],
        };
    }

    id<BBFindMyLocation> findMyLocation = (id<BBFindMyLocation>)location;
    BOOL providesCoordinates = [findMyLocation respondsToSelector:@selector(latitude)] &&
        [findMyLocation respondsToSelector:@selector(longitude)];
    id coordinates = [NSNull null];
    if (providesCoordinates) {
        double latitude = [findMyLocation latitude];
        double longitude = [findMyLocation longitude];
        if (isfinite(latitude) && isfinite(longitude)) {
            coordinates = @[@(latitude), @(longitude)];
        }
    }

    double timestampSeconds = [findMyLocation respondsToSelector:@selector(timestamp)]
        ? [findMyLocation timestamp] : 0;
    BOOL providesLocationType = [findMyLocation respondsToSelector:@selector(locationType)];
    long long locationType = providesLocationType ? [findMyLocation locationType] : 0;
    NSString *coarseAddress = [self nonEmptyString:
        [self valueForSelector:@selector(coarseAddressLabel) onObject:findMyLocation]];
    NSString *firstLocationLabel = [self firstStringInArray:
        [self valueForSelector:@selector(labels) onObject:findMyLocation]];

    return @{
        @"handle": friendIdentifier,
        @"coordinates": coordinates,
        @"long_address": coarseAddress ?: [NSNull null],
        @"short_address": coarseAddress ?: [NSNull null],
        @"subtitle": coarseAddress ?: [NSNull null],
        @"title": firstLocationLabel ?: [NSNull null],
        @"last_updated": timestampSeconds > 0 && isfinite(timestampSeconds)
            ? @(llround(timestampSeconds * 1000.0)) : [NSNull null],
        @"is_locating_in_progress": @NO,
        @"status": [self statusForLocationType:locationType],
        @"location_type": providesLocationType ? @(locationType) : [NSNull null],
        @"horizontal_accuracy": [findMyLocation respondsToSelector:@selector(horizontalAccuracy)]
            ? [self numberForFiniteValue:[findMyLocation horizontalAccuracy]] : [NSNull null],
        @"vertical_accuracy": [findMyLocation respondsToSelector:@selector(verticalAccuracy)]
            ? [self numberForFiniteValue:[findMyLocation verticalAccuracy]] : [NSNull null],
        @"speed": [findMyLocation respondsToSelector:@selector(speed)]
            ? [self numberForFiniteValue:[findMyLocation speed]] : [NSNull null],
        @"altitude": [findMyLocation respondsToSelector:@selector(altitude)]
            ? [self numberForFiniteValue:[findMyLocation altitude]] : [NSNull null],
    };
}

+ (NSDictionary *)responseForTransactionIdentifier:(nullable NSString *)transactionIdentifier
                       locationsByFriendIdentifier:(NSDictionary<NSString *, NSDictionary *> *)locationsByFriendIdentifier
                          pendingFriendIdentifiers:(NSSet<NSString *> *)pendingFriendIdentifiers
                               friendListTimedOut:(BOOL)friendListTimedOut
                        unidentifiedFriendCount:(NSUInteger)unidentifiedFriendCount {
    NSArray<NSString *> *sortedFriendIdentifiers = [[locationsByFriendIdentifier allKeys]
        sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<NSDictionary *> *orderedLocations = [[NSMutableArray alloc]
        initWithCapacity:sortedFriendIdentifiers.count];
    for (NSString *friendIdentifier in sortedFriendIdentifiers) {
        NSDictionary *locationPayload = locationsByFriendIdentifier[friendIdentifier];
        if (locationPayload != nil) {
            [orderedLocations addObject:locationPayload];
        }
    }

    NSArray<NSString *> *timedOutFriendIdentifiers = [[pendingFriendIdentifiers allObjects]
        sortedArrayUsingSelector:@selector(compare:)];
    BOOL responseIsPartial = friendListTimedOut || timedOutFriendIdentifiers.count > 0;

    return @{
        @"transactionId": transactionIdentifier ?: [NSNull null],
        @"locations": orderedLocations,
        @"partial": @(responseIsPartial),
        @"friendListTimedOut": @(friendListTimedOut),
        @"timedOutHandles": timedOutFriendIdentifiers,
        @"skippedFriends": @(unidentifiedFriendCount),
    };
}

@end
