#import <Foundation/Foundation.h>

#import "FindMyFriendPayload.h"
#import "FindMyFriendsHelper.h"
#import "FindMyFriendsRefreshCoordinator.h"
#import "ServerConnection.h"

@interface FMLHandle : NSObject
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *comparisonIdentifier;
@end

@implementation FMLHandle
@end

@interface BBMockFriendRecord : NSObject
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, strong) FMLHandle *handle;
@end

@implementation BBMockFriendRecord
@end

@interface BBMockLocation : NSObject
@property(nonatomic) double altitude;
@property(nonatomic, copy) NSString *coarseAddressLabel;
@property(nonatomic) double horizontalAccuracy;
@property(nonatomic, copy) NSArray *labels;
@property(nonatomic) double latitude;
@property(nonatomic) long long locationType;
@property(nonatomic) double longitude;
@property(nonatomic) double speed;
@property(nonatomic) double timestamp;
@property(nonatomic) double verticalAccuracy;
@end

@implementation BBMockLocation
@end

@interface BBMockFindMySession : NSObject <FindMyLocateSessionProtocol>
@property(nonatomic, copy) NSArray *friends;
@property(nonatomic, copy) NSArray *cachedFriends;
@property(nonatomic, strong) NSMutableDictionary<NSString *, id> *locationsByIdentifier;
@property(nonatomic, strong) NSMutableDictionary<NSString *, FindMyCompletion> *pendingRefreshes;
@property(nonatomic, copy) NSSet<NSString *> *immediateRefreshIdentifiers;
@property(nonatomic) BOOL withholdFriendList;
@property(nonatomic) BOOL duplicateImmediateRefreshCallbacks;
@end

@implementation BBMockFindMySession

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _friends = @[];
        _cachedFriends = @[];
        _locationsByIdentifier = [[NSMutableDictionary alloc] init];
        _pendingRefreshes = [[NSMutableDictionary alloc] init];
        _immediateRefreshIdentifiers = [NSSet set];
    }
    return self;
}

- (nullable NSArray *)cachedFriendsSharingLocationsWithMe {
    return self.cachedFriends;
}

- (nullable id)cachedLocationForHandle:(id)locationHandle includeAddress:(BOOL)includeAddress {
    NSString *identifier = [FindMyFriendPayload identifierForHandle:locationHandle];
    return identifier == nil ? nil : self.locationsByIdentifier[identifier];
}

- (void)getFriendsSharingLocationsWithMeWithCompletion:(FindMyFriendsCompletion)completion {
    if (!self.withholdFriendList) {
        completion(self.friends);
    }
}

- (void)startRefreshingLocationForHandles:(NSArray *)locationHandles
                                  priority:(long long)priority
                               isFromGroup:(BOOL)isFromGroup
                            reverseGeocode:(BOOL)reverseGeocode
                                completion:(FindMyCompletion)completion {
    NSString *identifier = [FindMyFriendPayload identifierForHandle:locationHandles.firstObject];
    if ([self.immediateRefreshIdentifiers containsObject:identifier]) {
        completion();
        if (self.duplicateImmediateRefreshCallbacks) {
            completion();
        }
        return;
    }
    if (identifier != nil) {
        self.pendingRefreshes[identifier] = [completion copy];
    }
}

@end

@interface BBRecordingSocket : GCDAsyncSocket
@property(nonatomic, strong) NSMutableArray<NSData *> *recordedWrites;
@property(nonatomic) BOOL reportsDisconnected;
@end

@implementation BBRecordingSocket

- (instancetype)init {
    self = [super initWithDelegate:nil delegateQueue:dispatch_get_main_queue()];
    if (self != nil) {
        _recordedWrites = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isDisconnected {
    return self.reportsDisconnected;
}

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag {
    [self.recordedWrites addObject:[data copy]];
}

@end

@implementation FindMyFriendsHelper

+ (instancetype)sharedInstance {
    static FindMyFriendsHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

- (void)handleServerAction:(nullable NSString *)action
     transactionIdentifier:(nullable NSString *)transactionIdentifier {
}

@end

static void BBAssert(BOOL condition, NSString *message) {
    if (condition) {
        return;
    }

    NSLog(@"FAIL: %@", message);
    exit(1);
}

static BOOL BBWaitUntil(BOOL (^condition)(void), NSTimeInterval timeout) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!condition() && deadline.timeIntervalSinceNow > 0) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    }
    return condition();
}

static FMLHandle *BBHandleWithIdentifier(NSString *identifier) {
    FMLHandle *findMyHandle = [[FMLHandle alloc] init];
    findMyHandle.identifier = identifier;
    return findMyHandle;
}

static NSDictionary *BBDecodeMessage(NSData *messageData) {
    NSError *error = nil;
    NSDictionary *message = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:&error];
    BBAssert(message != nil && error == nil, @"framed socket messages must contain valid JSON");
    return message;
}

static void BBTestPayload(void) {
    BBAssert([FindMyFriendPayload identifierForHandle:nil] == nil, @"nil handles must not gain an identity");

    FMLHandle *comparisonHandle = [[FMLHandle alloc] init];
    comparisonHandle.comparisonIdentifier = @"comparison-id";
    BBAssert([[FindMyFriendPayload identifierForHandle:comparisonHandle] isEqualToString:@"comparison-id"],
             @"comparisonIdentifier must be the explicit fallback");

    FMLHandle *aliceHandle = BBHandleWithIdentifier(@"alice@example.com");
    NSDictionary *missingLocationPayload = [FindMyFriendPayload locationPayloadForLocation:nil handle:aliceHandle];
    BBAssert([missingLocationPayload[@"coordinates"] isEqual:[NSNull null]], @"missing coordinates must stay null");
    BBAssert([missingLocationPayload[@"handle"] isEqualToString:@"alice@example.com"], @"handle must be stable");
    BBAssert(missingLocationPayload[@"description"] == nil && missingLocationPayload[@"friend"] == nil,
             @"opaque private descriptions must not be exported");

    BBMockLocation *liveLocation = [[BBMockLocation alloc] init];
    liveLocation.latitude = 47.61;
    liveLocation.longitude = -122.33;
    liveLocation.timestamp = 1234.567;
    liveLocation.locationType = 2;
    liveLocation.coarseAddressLabel = @"Seattle, WA";
    liveLocation.labels = @[@42, @"Alice"];
    liveLocation.horizontalAccuracy = 6.5;
    liveLocation.verticalAccuracy = 9.0;
    liveLocation.speed = 1.25;
    liveLocation.altitude = 32.0;

    NSDictionary *liveLocationPayload = [FindMyFriendPayload locationPayloadForLocation:liveLocation handle:aliceHandle];
    BBAssert([liveLocationPayload[@"coordinates"] isEqual:@[@47.61, @-122.33]], @"coordinates must be preserved");
    BBAssert([liveLocationPayload[@"title"] isEqualToString:@"Alice"], @"the first string label must become the title");
    BBAssert([liveLocationPayload[@"long_address"] isEqualToString:@"Seattle, WA"], @"address must use an explicit string field");
    BBAssert([liveLocationPayload[@"last_updated"] isEqual:@1234567], @"timestamps must be converted to milliseconds");
    BBAssert([liveLocationPayload[@"status"] isEqualToString:@"live"], @"location type 2 must map to live");

    NSDictionary *locationsByFriendIdentifier = @{
        @"bob@example.com": [FindMyFriendPayload
            locationPayloadForLocation:nil
                                 handle:BBHandleWithIdentifier(@"bob@example.com")],
        @"alice@example.com": liveLocationPayload,
    };
    NSDictionary *completeResponse = [FindMyFriendPayload
        responseForTransactionIdentifier:@"transaction"
             locationsByFriendIdentifier:locationsByFriendIdentifier
                pendingFriendIdentifiers:[NSSet set]
                      friendListTimedOut:NO
               unidentifiedFriendCount:1];
    NSArray *completeLocations = completeResponse[@"locations"];
    BBAssert([completeResponse[@"partial"] isEqual:@NO], @"completed refreshes must not be partial");
    BBAssert([completeLocations[0][@"handle"] isEqualToString:@"alice@example.com"],
             @"responses must be sorted by stable handle");
    BBAssert([completeResponse[@"skippedFriends"] isEqual:@1], @"skipped friend count must be retained");
}

static void BBTestFriendListTimeout(void) {
    FMLHandle *aliceHandle = BBHandleWithIdentifier(@"alice@example.com");
    BBMockFindMySession *session = [[BBMockFindMySession alloc] init];
    session.withholdFriendList = YES;
    session.cachedFriends = @[aliceHandle];
    session.immediateRefreshIdentifiers = [NSSet setWithObject:aliceHandle.identifier];

    __block NSMutableArray<NSDictionary *> *responses = [[NSMutableArray alloc] init];
    FindMyFriendsRefreshCoordinator *coordinator = [[FindMyFriendsRefreshCoordinator alloc]
        initWithSession:session
        transactionIdentifier:@"friend-list-timeout"
        friendListTimeout:0.01
        locationRefreshTimeout:0.05
        responseHandler:^(NSDictionary *response) {
            [responses addObject:response];
        }];
    [coordinator start];

    BBAssert(BBWaitUntil(^BOOL { return responses.count == 1; }, 0.2), @"friend-list timeout must return a response");
    NSDictionary *response = responses.firstObject;
    BBAssert([response[@"partial"] isEqual:@YES], @"friend-list timeout must mark the response partial");
    BBAssert([response[@"friendListTimedOut"] isEqual:@YES], @"friend-list timeout must be explicit");
    BBAssert([response[@"locations"] count] == 1, @"cached friends must survive a friend-list timeout");
}

static void BBTestLocationTimeoutAndLateCallbacks(void) {
    FMLHandle *aliceHandle = BBHandleWithIdentifier(@"alice@example.com");
    FMLHandle *bobHandle = BBHandleWithIdentifier(@"bob@example.com");
    BBMockFindMySession *session = [[BBMockFindMySession alloc] init];
    session.friends = @[aliceHandle, bobHandle];
    session.immediateRefreshIdentifiers = [NSSet setWithObject:aliceHandle.identifier];

    __block NSMutableArray<NSDictionary *> *responses = [[NSMutableArray alloc] init];
    FindMyFriendsRefreshCoordinator *coordinator = [[FindMyFriendsRefreshCoordinator alloc]
        initWithSession:session
        transactionIdentifier:@"location-timeout"
        friendListTimeout:0.05
        locationRefreshTimeout:0.01
        responseHandler:^(NSDictionary *response) {
            [responses addObject:response];
        }];
    [coordinator start];

    BBAssert(BBWaitUntil(^BOOL { return responses.count == 1; }, 0.2), @"location timeout must return a response");
    NSDictionary *response = responses.firstObject;
    BBAssert([response[@"partial"] isEqual:@YES], @"location timeout must mark the response partial");
    BBAssert([response[@"locations"] count] == 2, @"timed-out friends must remain in the response");
    BBAssert([response[@"timedOutHandles"] isEqual:@[@"bob@example.com"]], @"timed-out handles must be retained");

    FindMyCompletion lateCompletion = session.pendingRefreshes[bobHandle.identifier];
    BBAssert(lateCompletion != nil, @"the delayed refresh callback must be captured");
    lateCompletion();
    lateCompletion();
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    BBAssert(responses.count == 1, @"late or duplicate callbacks must not send another response");
}

static void BBTestDuplicateImmediateCallback(void) {
    FMLHandle *aliceHandle = BBHandleWithIdentifier(@"alice@example.com");
    BBMockFriendRecord *friendRecord = [[BBMockFriendRecord alloc] init];
    friendRecord.identifier = @"friend-record-identifier";
    friendRecord.handle = aliceHandle;
    BBMockFindMySession *session = [[BBMockFindMySession alloc] init];
    session.friends = @[friendRecord];
    session.immediateRefreshIdentifiers = [NSSet setWithObject:aliceHandle.identifier];
    session.duplicateImmediateRefreshCallbacks = YES;

    __block NSMutableArray<NSDictionary *> *responses = [[NSMutableArray alloc] init];
    FindMyFriendsRefreshCoordinator *coordinator = [[FindMyFriendsRefreshCoordinator alloc]
        initWithSession:session
        transactionIdentifier:@"duplicate-callback"
        friendListTimeout:0.05
        locationRefreshTimeout:0.05
        responseHandler:^(NSDictionary *response) {
            [responses addObject:response];
        }];
    [coordinator start];

    BBAssert(BBWaitUntil(^BOOL { return responses.count == 1; }, 0.2), @"duplicate callbacks must complete once");
    BBAssert([responses.firstObject[@"partial"] isEqual:@NO], @"duplicate callbacks must not create a partial response");
}

static void BBTestReconnectQueue(void) {
    ServerConnection *connection = [[ServerConnection alloc] init];
    [connection sendMessage:@{@"transactionId": @"queued-before-connect"}];

    BBRecordingSocket *firstSocket = [[BBRecordingSocket alloc] init];
    [connection setValue:firstSocket forKey:@"socket"];
    [connection socket:firstSocket didConnectToHost:@"localhost" port:45675];

    BBAssert(firstSocket.recordedWrites.count == 2, @"connect must send a ping before the queued response");
    BBAssert([BBDecodeMessage(firstSocket.recordedWrites[0])[@"event"] isEqualToString:@"ping"],
             @"the first reconnect message must register the helper");
    BBAssert([BBDecodeMessage(firstSocket.recordedWrites[1])[@"transactionId"]
        isEqualToString:@"queued-before-connect"], @"queued response must follow registration");

    [connection socketDidDisconnect:firstSocket withError:nil];
    [connection sendMessage:@{@"transactionId": @"queued-during-disconnect"}];

    BBRecordingSocket *secondSocket = [[BBRecordingSocket alloc] init];
    [connection setValue:secondSocket forKey:@"socket"];
    [connection socket:secondSocket didConnectToHost:@"localhost" port:45675];

    BBAssert(secondSocket.recordedWrites.count == 2, @"reconnect must flush one queued response after its ping");
    BBAssert([BBDecodeMessage(secondSocket.recordedWrites[0])[@"event"] isEqualToString:@"ping"],
             @"reconnect must register before flushing responses");
    BBAssert([BBDecodeMessage(secondSocket.recordedWrites[1])[@"transactionId"]
        isEqualToString:@"queued-during-disconnect"], @"in-flight response must survive a disconnect");

    [connection socket:firstSocket didConnectToHost:@"localhost" port:45675];
    BBAssert(firstSocket.recordedWrites.count == 2, @"a stale socket callback must not register or flush again");
}

int main(void) {
    @autoreleasepool {
        BBTestPayload();
        BBTestFriendListTimeout();
        BBTestLocationTimeoutAndLateCallbacks();
        BBTestDuplicateImmediateCallback();
        BBTestReconnectQueue();
        NSLog(@"PASS: FindMyFriendsTests");
    }

    return 0;
}
