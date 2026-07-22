#import "FindMyDevicesRefreshCoordinator.h"

@interface FindMyDevicesRefreshCoordinator ()
@property(nonatomic, copy, nullable) NSString *transactionIdentifier;
@property(nonatomic) NSTimeInterval dataSourceTimeout;
@property(nonatomic) NSTimeInterval pollInterval;
@property(nonatomic, copy) FindMyDevicesDataSourceProvider dataSourceProvider;
@property(nonatomic, copy) FindMyDevicesSnapshotProvider snapshotProvider;
@property(nonatomic, copy) FindMyDevicesRefreshResponseHandler responseHandler;
@property(nonatomic, strong, nullable) NSDate *deadline;
@property(nonatomic) BOOL responseSent;
@end

@implementation FindMyDevicesRefreshCoordinator

- (instancetype)initWithTransactionIdentifier:(nullable NSString *)transactionIdentifier
                             dataSourceTimeout:(NSTimeInterval)dataSourceTimeout
                                  pollInterval:(NSTimeInterval)pollInterval
                            dataSourceProvider:(FindMyDevicesDataSourceProvider)dataSourceProvider
                              snapshotProvider:(FindMyDevicesSnapshotProvider)snapshotProvider
                               responseHandler:(FindMyDevicesRefreshResponseHandler)responseHandler {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _transactionIdentifier = [transactionIdentifier copy];
    _dataSourceTimeout = dataSourceTimeout;
    _pollInterval = pollInterval;
    _dataSourceProvider = [dataSourceProvider copy];
    _snapshotProvider = [snapshotProvider copy];
    _responseHandler = [responseHandler copy];
    return self;
}

- (void)start {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self start];
        });
        return;
    }

    self.deadline = [NSDate dateWithTimeIntervalSinceNow:self.dataSourceTimeout];
    [self attemptSnapshot];
}

- (void)attemptSnapshot {
    if (self.responseSent) {
        return;
    }

    id dataSource = self.dataSourceProvider();
    if (dataSource != nil) {
        NSDictionary *snapshot = self.snapshotProvider(dataSource);
        [self sendResponse:snapshot];
        return;
    }

    if (self.deadline.timeIntervalSinceNow <= 0) {
        [self sendResponse:@{
            @"error": @"Find My Devices data source did not become available before the refresh timeout",
        }];
        return;
    }

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pollInterval * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            [self attemptSnapshot];
        }
    );
}

- (void)sendResponse:(NSDictionary *)snapshot {
    if (self.responseSent) {
        return;
    }
    self.responseSent = YES;

    NSMutableDictionary *response = [[NSMutableDictionary alloc] initWithDictionary:snapshot];
    response[@"transactionId"] = self.transactionIdentifier ?: [NSNull null];
    self.responseHandler([response copy]);
}

@end
