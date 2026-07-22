#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^FindMyDevicesDataSourceProvider)(void);
typedef NSDictionary * _Nonnull (^FindMyDevicesSnapshotProvider)(id dataSource);
typedef void (^FindMyDevicesRefreshResponseHandler)(NSDictionary *response);

@interface FindMyDevicesRefreshCoordinator : NSObject

- (instancetype)initWithTransactionIdentifier:(nullable NSString *)transactionIdentifier
                             dataSourceTimeout:(NSTimeInterval)dataSourceTimeout
                                  pollInterval:(NSTimeInterval)pollInterval
                            dataSourceProvider:(FindMyDevicesDataSourceProvider)dataSourceProvider
                              snapshotProvider:(FindMyDevicesSnapshotProvider)snapshotProvider
                               responseHandler:(FindMyDevicesRefreshResponseHandler)responseHandler;

- (void)start;

@end

NS_ASSUME_NONNULL_END
