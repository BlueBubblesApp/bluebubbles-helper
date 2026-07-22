#import "FindMyFriendsRefreshCoordinator.h"

#import <os/log.h>

#import "FindMyFriendPayload.h"

static const long long BBLocationRefreshPriority = 1000;

@interface FindMyFriendsRefreshCoordinator ()
@property(nonatomic, strong) id<FindMyLocateSessionProtocol> session;
@property(nonatomic, copy, nullable) NSString *transactionIdentifier;
@property(nonatomic) NSTimeInterval friendListTimeout;
@property(nonatomic) NSTimeInterval locationRefreshTimeout;
@property(nonatomic, copy) FindMyFriendsRefreshResponseHandler responseHandler;
@property(nonatomic) BOOL friendListResolved;
@end

@implementation FindMyFriendsRefreshCoordinator

static os_log_t refreshLog;

+ (void)initialize {
    if (self == [FindMyFriendsRefreshCoordinator class]) {
        refreshLog = os_log_create("BlueBubblesFindMyHelper", "friends-refresh");
    }
}

- (instancetype)initWithSession:(id<FindMyLocateSessionProtocol>)session
           transactionIdentifier:(nullable NSString *)transactionIdentifier
               friendListTimeout:(NSTimeInterval)friendListTimeout
          locationRefreshTimeout:(NSTimeInterval)locationRefreshTimeout
                 responseHandler:(FindMyFriendsRefreshResponseHandler)responseHandler {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _session = session;
    _transactionIdentifier = [transactionIdentifier copy];
    _friendListTimeout = friendListTimeout;
    _locationRefreshTimeout = locationRefreshTimeout;
    _responseHandler = [responseHandler copy];
    return self;
}

- (nullable id)valueForSelector:(SEL)selector onObject:(nullable id)object {
    if (object == nil || ![object respondsToSelector:selector]) {
        return nil;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [object performSelector:selector];
#pragma clang diagnostic pop
}

- (nullable id)locationHandleForFriend:(nullable id)friendRecord {
    if (friendRecord == nil) {
        return nil;
    }
    Class locationHandleClass = NSClassFromString(@"FMLHandle");
    if (locationHandleClass != Nil) {
        if ([friendRecord isKindOfClass:locationHandleClass]) {
            return friendRecord;
        }
    } else {
        SEL identifierSelector = NSSelectorFromString(@"identifier");
        SEL comparisonIdentifierSelector = NSSelectorFromString(@"comparisonIdentifier");
        if ([friendRecord respondsToSelector:identifierSelector] ||
            [friendRecord respondsToSelector:comparisonIdentifierSelector]) {
            return friendRecord;
        }
    }
    return [self valueForSelector:NSSelectorFromString(@"handle") onObject:friendRecord];
}

- (nullable id)cachedLocationForHandle:(id)locationHandle {
    if ([self.session respondsToSelector:@selector(cachedLocationForHandle:includeAddress:)]) {
        return [self.session cachedLocationForHandle:locationHandle includeAddress:YES];
    }
    if ([self.session respondsToSelector:@selector(cachedLocationForHandle:)]) {
        return [self.session cachedLocationForHandle:locationHandle];
    }
    return nil;
}

- (NSArray *)cachedFriends {
    NSArray *cachedFriends = nil;
    if ([self.session respondsToSelector:@selector(cachedFriendsSharingLocationWithMe)]) {
        cachedFriends = [self.session cachedFriendsSharingLocationWithMe];
    }
    if (cachedFriends == nil && [self.session respondsToSelector:@selector(cachedFriendsSharingLocationsWithMe)]) {
        cachedFriends = [self.session cachedFriendsSharingLocationsWithMe];
    }
    return [cachedFriends isKindOfClass:[NSArray class]] ? cachedFriends : @[];
}

- (void)refreshAndSendLocationsForFriends:(NSArray *)friendRecords friendListTimedOut:(BOOL)friendListTimedOut {
    NSMutableDictionary<NSString *, NSDictionary *> *locationsByFriendIdentifier = [[NSMutableDictionary alloc] init];
    NSMutableSet<NSString *> *pendingFriendIdentifiers = [[NSMutableSet alloc] init];
    NSMutableArray<void (^)(void)> *completeLocationRefreshBlocks = [[NSMutableArray alloc] init];
    dispatch_group_t locationRefreshGroup = dispatch_group_create();
    __block NSUInteger unidentifiedFriendCount = 0;

    for (id friendRecord in friendRecords) {
        id locationHandle = [self locationHandleForFriend:friendRecord];
        NSString *friendIdentifier = [FindMyFriendPayload identifierForHandle:locationHandle];
        if (friendIdentifier == nil) {
            unidentifiedFriendCount += 1;
            continue;
        }

        NSDictionary *cachedLocationPayload = [FindMyFriendPayload
            locationPayloadForLocation:[self cachedLocationForHandle:locationHandle]
                                 handle:locationHandle];
        if (cachedLocationPayload == nil) {
            unidentifiedFriendCount += 1;
            continue;
        }

        __block BOOL shouldRefreshLocation = NO;
        @synchronized (pendingFriendIdentifiers) {
            if (locationsByFriendIdentifier[friendIdentifier] == nil) {
                locationsByFriendIdentifier[friendIdentifier] = cachedLocationPayload;
                [pendingFriendIdentifiers addObject:friendIdentifier];
                shouldRefreshLocation = YES;
            }
        }
        if (!shouldRefreshLocation) {
            continue;
        }

        dispatch_group_enter(locationRefreshGroup);
        __block BOOL locationRefreshCompleted = NO;
        void (^completeLocationRefresh)(void) = ^{
            @synchronized (pendingFriendIdentifiers) {
                if (locationRefreshCompleted) {
                    return;
                }
                locationRefreshCompleted = YES;

                NSDictionary *refreshedLocationPayload = [FindMyFriendPayload
                    locationPayloadForLocation:[self cachedLocationForHandle:locationHandle]
                                         handle:locationHandle];
                if (refreshedLocationPayload != nil) {
                    locationsByFriendIdentifier[friendIdentifier] = refreshedLocationPayload;
                }
                [pendingFriendIdentifiers removeObject:friendIdentifier];
            }
            dispatch_group_leave(locationRefreshGroup);
        };
        [completeLocationRefreshBlocks addObject:completeLocationRefresh];

        if ([self.session respondsToSelector:@selector(startRefreshingLocationForHandles:priority:isFromGroup:reverseGeocode:completion:)]) {
            [self.session startRefreshingLocationForHandles:@[locationHandle]
                                                   priority:BBLocationRefreshPriority
                                                isFromGroup:NO
                                             reverseGeocode:YES
                                                 completion:completeLocationRefresh];
        } else if ([self.session respondsToSelector:@selector(startRefreshingLocationForHandles:priority:isFromGroup:completion:)]) {
            [self.session startRefreshingLocationForHandles:@[locationHandle]
                                                   priority:BBLocationRefreshPriority
                                                isFromGroup:NO
                                                 completion:completeLocationRefresh];
        } else {
            completeLocationRefresh();
        }
    }

    __block BOOL responseSent = NO;
    BOOL (^sendResponseOnce)(void) = ^BOOL {
        NSDictionary *response = nil;
        @synchronized (pendingFriendIdentifiers) {
            if (responseSent) {
                return NO;
            }
            responseSent = YES;
            response = [FindMyFriendPayload
                responseForTransactionIdentifier:self.transactionIdentifier
                     locationsByFriendIdentifier:locationsByFriendIdentifier
                        pendingFriendIdentifiers:pendingFriendIdentifiers
                              friendListTimedOut:friendListTimedOut
                       unidentifiedFriendCount:unidentifiedFriendCount];
        }
        self.responseHandler(response);
        return YES;
    };

    dispatch_group_notify(locationRefreshGroup, dispatch_get_main_queue(), ^{
        sendResponseOnce();
    });

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.locationRefreshTimeout * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            NSUInteger pendingFriendCount = 0;
            @synchronized (pendingFriendIdentifiers) {
                pendingFriendCount = pendingFriendIdentifiers.count;
            }
            if (!sendResponseOnce()) {
                return;
            }
            os_log(refreshLog, "Friend location deadline reached with %lu pending", (unsigned long)pendingFriendCount);
            for (void (^completeLocationRefresh)(void) in completeLocationRefreshBlocks) {
                completeLocationRefresh();
            }
        }
    );
}

- (void)resolveFriendList:(nullable NSArray *)requestedFriends timedOut:(BOOL)timedOut {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.friendListResolved) {
            return;
        }
        self.friendListResolved = YES;

        NSArray *friendRecords = [requestedFriends isKindOfClass:[NSArray class]]
            ? requestedFriends : [self cachedFriends];
        [self refreshAndSendLocationsForFriends:friendRecords friendListTimedOut:timedOut];
    });
}

- (void)start {
    if (![self.session respondsToSelector:@selector(getFriendsSharingLocationsWithMeWithCompletion:)]) {
        [self resolveFriendList:[self cachedFriends] timedOut:NO];
        return;
    }

    [self.session getFriendsSharingLocationsWithMeWithCompletion:^(NSArray *requestedFriends) {
        [self resolveFriendList:requestedFriends timedOut:NO];
    }];

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.friendListTimeout * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            if (self.friendListResolved) {
                return;
            }
            os_log(refreshLog, "Friend list deadline reached; using cached friends");
            [self resolveFriendList:[self cachedFriends] timedOut:YES];
        }
    );
}

@end
