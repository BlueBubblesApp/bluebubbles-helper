#import <Foundation/Foundation.h>

#import "FindMyLocateSession.h"
#import "ServerConnection.h"

#if __has_include("FindMyHelper.h")
#import "FindMyHelper.h"
#import "FindMyDevicesDataSourceCapture.h"
#import "FindMyDeviceSnapshotBridge.h"
#define BBHelper FindMyHelper
#define BBFriendRefreshesKey @"activeFriendRefreshes"
#define BB_HAS_DEVICES 1
#else
#import "FindMyFriendsHelper.h"
#define BBHelper FindMyFriendsHelper
#define BBFriendRefreshesKey @"activeRefreshes"
#define BB_HAS_DEVICES 0
#endif

// Compile the production helper and coordinators. Only the external transport
// and private-framework providers are fakes; no socket or Apple account is used.
static NSMutableArray<NSDictionary *> *messages;
static NSUInteger connectionAttempts;
static NSUInteger sessionStarts;
static BOOL returnFriendList = YES;
static NSUInteger checks;

@implementation ServerConnection
+ (instancetype)sharedInstance {
    static ServerConnection *connection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ connection = [[self alloc] init]; });
    return connection;
}
- (void)connect { connectionAttempts += 1; }
- (void)sendMessage:(NSDictionary *)message { [messages addObject:message]; }
@end

@implementation FindMyLocateSession
- (NSArray *)cachedFriendsSharingLocationWithMe { return @[]; }
- (void)getFriendsSharingLocationsWithMeWithCompletion:(FindMyFriendsCompletion)completion {
    completion(returnFriendList ? @[] : nil);
}
- (void)startUpdatingFriendsWithInitialUpdates:(BOOL)includeInitialUpdates
                                    completion:(FindMyCompletion)completion {
    (void)includeInitialUpdates;
    sessionStarts += 1;
    completion();
}
- (void)startMonitoringActiveLocationSharingDeviceChangeWithCompletion:(FindMyCompletion)completion {
    completion();
}
@end

#if BB_HAS_DEVICES
static id devicesDataSource;
static NSUInteger captureAttempts;
@implementation FindMyDevicesDataSourceCapture
+ (instancetype)sharedInstance {
    static FindMyDevicesDataSourceCapture *capture;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ capture = [[self alloc] init]; });
    return capture;
}
- (id)devicesDataSource { return devicesDataSource; }
- (void)installCapture { captureAttempts += 1; }
@end

@implementation FindMyDeviceSnapshotBridge
+ (NSDictionary *)snapshotForDataSource:(id)dataSource {
    (void)dataSource;
    return @{ @"devices": @[], @"partial": @NO, @"skippedDevices": @0 };
}
@end
#endif

static void Check(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        exit(1);
    }
    checks += 1;
}

static void WaitUntil(BOOL (^condition)(void), NSTimeInterval timeout, NSString *message) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!condition() && deadline.timeIntervalSinceNow > 0) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
    Check(condition(), message);
}

static NSDictionary *Response(NSString *transactionIdentifier) {
    for (NSDictionary *message in messages) {
        if ([message[@"transactionId"] isEqual:transactionIdentifier]) {
            return message;
        }
    }
    return nil;
}

static NSUInteger ActiveRefreshes(BBHelper *helper, NSString *key) {
    return [[helper valueForKey:key] count];
}

int main(void) {
    @autoreleasepool {
        messages = [[NSMutableArray alloc] init];
        BBHelper *helper = [BBHelper sharedInstance];
        Check(![[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.findmy"],
              @"test must run outside Find My");
        Check(connectionAttempts == 0, @"wrong-host +load must not connect");
#if BB_HAS_DEVICES
        Check(captureAttempts == 0, @"wrong-host +load must not install capture");
#endif
        [helper handleServerAction:@"start-typing" transactionIdentifier:@"messages-action"];
        [helper handleServerAction:nil transactionIdentifier:@"missing-action"];
        [helper handleServerAction:@"refresh-FINDMY-unknown" transactionIdentifier:nil];
        Check(messages.count == 0, @"unrelated, nil and uncorrelated unknown actions must not reply");
        [helper handleServerAction:@"refresh-FINDMY-unknown" transactionIdentifier:@"unknown"];
        Check([Response(@"unknown")[@"error"] isEqual:@"Find My action not implemented: refresh-FINDMY-unknown"],
              @"unknown Find My actions must preserve the transaction and report an error");

        [helper handleServerAction:@"refresh-findmy-friends" transactionIdentifier:@"friends-empty"];
        WaitUntil(^BOOL { return Response(@"friends-empty") != nil; }, 1, @"Friends dispatch must respond");
        NSDictionary *friends = Response(@"friends-empty");
        Check([friends[@"locations"] isEqual:@[]] && [friends[@"partial"] isEqual:@NO] &&
              [friends[@"friendListTimedOut"] isEqual:@NO], @"successful empty Friends snapshot is complete");
        Check(ActiveRefreshes(helper, BBFriendRefreshesKey) == 0, @"completed Friends coordinator must be removed");

        NSUInteger beforeUncorrelated = messages.count;
        [helper handleServerAction:@"refresh-findmy-friends" transactionIdentifier:nil];
        WaitUntil(^BOOL { return messages.count == beforeUncorrelated + 1; }, 1,
                  @"uncorrelated Friends refresh must still complete");
        Check([messages.lastObject[@"transactionId"] isEqual:[NSNull null]], @"nil transaction must serialize as null");
        Check(sessionStarts == 1, @"production helper must reuse its locate session");
        Check(ActiveRefreshes(helper, BBFriendRefreshesKey) == 0, @"uncorrelated refresh must be removed");

#if BB_HAS_DEVICES
        devicesDataSource = [[NSObject alloc] init];
        [helper handleServerAction:@"refresh-findmy-devices" transactionIdentifier:@"devices-empty"];
        NSDictionary *devices = Response(@"devices-empty");
        Check([devices[@"devices"] isEqual:@[]] && [devices[@"partial"] isEqual:@NO],
              @"Devices dispatch must forward the complete empty snapshot with its transaction");
        Check(ActiveRefreshes(helper, @"activeDeviceRefreshes") == 0, @"completed Devices coordinator must be removed");
        Check(captureAttempts > 0, @"Devices dispatch must request data-source capture");
        devicesDataSource = nil;
        [helper handleServerAction:@"refresh-findmy-devices" transactionIdentifier:@"devices-timeout"];
        Check(ActiveRefreshes(helper, @"activeDeviceRefreshes") == 1, @"pending Devices refresh must be retained");
#endif
        returnFriendList = NO;
        [helper handleServerAction:@"refresh-findmy-friends" transactionIdentifier:@"friends-timeout"];
        Check(ActiveRefreshes(helper, BBFriendRefreshesKey) == 1, @"pending Friends refresh must be retained");
        WaitUntil(^BOOL {
            return Response(@"friends-timeout") != nil
#if BB_HAS_DEVICES
                && Response(@"devices-timeout") != nil
#endif
                ;
        }, 7, @"production refresh deadlines must complete without provider data");
        NSDictionary *timedOutFriends = Response(@"friends-timeout");
        Check([timedOutFriends[@"locations"] isEqual:@[]] && [timedOutFriends[@"partial"] isEqual:@YES] &&
              [timedOutFriends[@"friendListTimedOut"] isEqual:@YES], @"Friends deadline must mark cached response partial");
        Check(ActiveRefreshes(helper, BBFriendRefreshesKey) == 0, @"timed-out Friends coordinator must be removed");
#if BB_HAS_DEVICES
        Check([Response(@"devices-timeout")[@"error"] isEqual:
              @"Find My Devices data source did not become available before the refresh timeout"],
              @"Devices deadline must return the correlated production error");
        Check(ActiveRefreshes(helper, @"activeDeviceRefreshes") == 0, @"timed-out Devices coordinator must be removed");
#endif
        Check(connectionAttempts == 0, @"wrong-host +load must not schedule a delayed connection");
        Check(messages.count == (BB_HAS_DEVICES ? 6U : 4U), @"each handled transaction must reply exactly once");
        Check([NSJSONSerialization isValidJSONObject:messages], @"all dispatched responses must be JSON-safe");
        printf("Find My production dispatch: %lu checks passed (%s)\n", (unsigned long)checks,
               BB_HAS_DEVICES ? "Friends + Devices" : "Friends");
    }
    return 0;
}
