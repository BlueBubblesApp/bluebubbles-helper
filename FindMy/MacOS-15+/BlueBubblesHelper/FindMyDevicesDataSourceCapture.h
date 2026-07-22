#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FindMyDevicesDataSourceCapture : NSObject

@property(nonatomic, weak, readonly, nullable) id devicesDataSource;

+ (instancetype)sharedInstance;

- (void)installCapture;

@end

NS_ASSUME_NONNULL_END
