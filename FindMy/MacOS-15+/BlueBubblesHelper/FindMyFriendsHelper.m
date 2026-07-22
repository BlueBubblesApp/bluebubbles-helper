#import "FindMyFriendsHelper.h"

#import <os/log.h>

#import "FindMyLocateSession.h"
#import "FindMyFriendsRefreshCoordinator.h"
#import "ServerConnection.h"

static const NSTimeInterval BBConnectionDelaySeconds = 5.0;
static const NSTimeInterval BBFriendListTimeoutSeconds = 5.0;
static const NSTimeInterval BBLocationRefreshTimeoutSeconds = 8.0;

@interface FindMyFriendsHelper ()
@property(nonatomic, strong, nullable) FindMyLocateSession *activeLocateSession;
@property(nonatomic, strong) NSMutableSet<FindMyFriendsRefreshCoordinator *> *activeRefreshes;
- (nullable FindMyLocateSession *)locateSession;
- (void)handleFriendsRefreshForTransactionIdentifier:(nullable NSString *)transactionIdentifier;
- (void)sendError:(NSString *)errorMessage transactionIdentifier:(nullable NSString *)transactionIdentifier;
@end

@implementation FindMyFriendsHelper

static os_log_t helperLog;

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _activeRefreshes = [[NSMutableSet alloc] init];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static FindMyFriendsHelper *sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[self alloc] init];
        helperLog = os_log_create("BlueBubblesFindMyHelper", "friends-helper");
    });
    return sharedHelper;
}

+ (void)load {
    [FindMyFriendsHelper sharedInstance];

    NSString *hostBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (![hostBundleIdentifier isEqualToString:@"com.apple.findmy"]) {
        os_log_error(helperLog, "Refusing injection into %{public}@", hostBundleIdentifier);
        return;
    }

    NSOperatingSystemVersion operatingSystemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    os_log(
        helperLog,
        "Loaded on macOS %ld.%ld.%ld",
        (long)operatingSystemVersion.majorVersion,
        (long)operatingSystemVersion.minorVersion,
        (long)operatingSystemVersion.patchVersion
    );

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BBConnectionDelaySeconds * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            [[ServerConnection sharedInstance] connect];
        }
    );
}

- (void)handleServerAction:(nullable NSString *)action
     transactionIdentifier:(nullable NSString *)transactionIdentifier {
    if ([action isEqualToString:@"refresh-findmy-friends"]) {
        [self handleFriendsRefreshForTransactionIdentifier:transactionIdentifier];
        return;
    }

    if (action == nil) {
        os_log(helperLog, "Ignoring Private API action without a name");
        return;
    }

    NSRange findMyMarker = [action rangeOfString:@"findmy" options:NSCaseInsensitiveSearch];
    if (findMyMarker.location == NSNotFound) {
        os_log(helperLog, "Ignoring unrelated Private API action: %{public}@", action);
        return;
    }

    NSString *errorMessage = [NSString stringWithFormat:@"Find My action not implemented: %@", action];
    [self sendError:errorMessage transactionIdentifier:transactionIdentifier];
}

- (void)sendError:(NSString *)errorMessage transactionIdentifier:(nullable NSString *)transactionIdentifier {
    os_log_error(helperLog, "%{public}@", errorMessage);
    if (transactionIdentifier == nil) {
        return;
    }
    [[ServerConnection sharedInstance] sendMessage:@{
        @"transactionId": transactionIdentifier,
        @"error": errorMessage,
    }];
}

- (nullable FindMyLocateSession *)locateSession {
    if (self.activeLocateSession != nil) {
        return self.activeLocateSession;
    }

    Class locateSessionClass = NSClassFromString(@"FindMyLocateSession");
    if (locateSessionClass == nil) {
        NSError *frameworkLoadError = nil;
        NSBundle *wrapperFramework = [NSBundle
            bundleWithPath:@"/System/Library/PrivateFrameworks/FindMyLocateObjCWrapper.framework"];
        if (![wrapperFramework loadAndReturnError:&frameworkLoadError]) {
            os_log_error(helperLog, "Unable to load FindMyLocateObjCWrapper: %{public}@", frameworkLoadError);
        }
        locateSessionClass = NSClassFromString(@"FindMyLocateSession");
    }

    if (locateSessionClass == nil) {
        os_log_error(helperLog, "FindMyLocateSession is unavailable");
        return nil;
    }

    self.activeLocateSession = [[locateSessionClass alloc] init];

    if ([self.activeLocateSession respondsToSelector:@selector(startUpdatingFriendsWithInitialUpdates:completion:)]) {
        [self.activeLocateSession startUpdatingFriendsWithInitialUpdates:YES completion:^{
            os_log(helperLog, "Find My friend updates started");
        }];
    }

    if ([self.activeLocateSession respondsToSelector:@selector(startMonitoringActiveLocationSharingDeviceChangeWithCompletion:)]) {
        [self.activeLocateSession startMonitoringActiveLocationSharingDeviceChangeWithCompletion:^{
            os_log(helperLog, "Find My active-device monitoring started");
        }];
    }

    return self.activeLocateSession;
}

- (void)handleFriendsRefreshForTransactionIdentifier:(nullable NSString *)transactionIdentifier {
    FindMyLocateSession *session = [self locateSession];
    if (session == nil) {
        [self sendError:@"FindMyLocateSession is unavailable" transactionIdentifier:transactionIdentifier];
        return;
    }

    __weak typeof(self) weakSelf = self;
    __block __weak FindMyFriendsRefreshCoordinator *weakCoordinator = nil;
    FindMyFriendsRefreshCoordinator *coordinator = [[FindMyFriendsRefreshCoordinator alloc]
        initWithSession:session
        transactionIdentifier:transactionIdentifier
        friendListTimeout:BBFriendListTimeoutSeconds
        locationRefreshTimeout:BBLocationRefreshTimeoutSeconds
        responseHandler:^(NSDictionary *response) {
            [[ServerConnection sharedInstance] sendMessage:response];
            FindMyFriendsHelper *strongSelf = weakSelf;
            if (strongSelf != nil && weakCoordinator != nil) {
                [strongSelf.activeRefreshes removeObject:weakCoordinator];
            }
        }];
    weakCoordinator = coordinator;
    [self.activeRefreshes addObject:coordinator];
    [coordinator start];
}

@end
