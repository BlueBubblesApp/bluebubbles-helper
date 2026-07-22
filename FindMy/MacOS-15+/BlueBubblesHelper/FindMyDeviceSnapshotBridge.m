#import "FindMyDeviceSnapshotBridge.h"

extern void *BlueBubblesFindMyCopyDevicesSnapshot(void *dataSource);

@implementation FindMyDeviceSnapshotBridge

+ (NSDictionary *)snapshotForDataSource:(id)dataSource {
    void *snapshotPointer = BlueBubblesFindMyCopyDevicesSnapshot((__bridge void *)dataSource);
    if (snapshotPointer == NULL) {
        return @{
            @"error": @"Find My Devices snapshot generation failed",
        };
    }

    id snapshot = CFBridgingRelease(snapshotPointer);
    if (![snapshot isKindOfClass:[NSDictionary class]]) {
        return @{
            @"error": @"Find My Devices snapshot had an invalid response type",
        };
    }
    return snapshot;
}

@end
