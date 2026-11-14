#import "FindMyDevicesDataSourceCapture.h"

#import <objc/runtime.h>

typedef NSInteger (*FindMyDevicesRowCountImplementation)(id, SEL, id, NSInteger);

static FindMyDevicesRowCountImplementation originalDevicesRowCountImplementation = NULL;

@interface FindMyDevicesDataSourceCapture ()
@property(nonatomic, weak, readwrite, nullable) id devicesDataSource;
@property(nonatomic) BOOL isCaptureInstalled;
- (void)recordDevicesDataSource:(id)dataSource;
@end

static NSInteger CaptureDevicesDataSourceAndCountRows(id dataSource, SEL selector, id tableView, NSInteger section) {
    [[FindMyDevicesDataSourceCapture sharedInstance] recordDevicesDataSource:dataSource];
    if (originalDevicesRowCountImplementation == NULL) {
        return 0;
    }
    return originalDevicesRowCountImplementation(dataSource, selector, tableView, section);
}

@implementation FindMyDevicesDataSourceCapture

+ (instancetype)sharedInstance {
    static FindMyDevicesDataSourceCapture *sharedCapture = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCapture = [[self alloc] init];
    });
    return sharedCapture;
}

- (void)installCapture {
    @synchronized (self) {
        if (self.isCaptureInstalled) {
            return;
        }

        NSArray<NSString *> *dataSourceClassNames = @[
            @"FindMy.FMDevicesListDataSource",
            @"_TtC6FindMy23FMDevicesListDataSource",
            @"FMDevicesListDataSource",
        ];
        SEL rowCountSelector = NSSelectorFromString(@"tableView:numberOfRowsInSection:");

        for (NSString *className in dataSourceClassNames) {
            Class dataSourceClass = NSClassFromString(className);
            Method rowCountMethod = dataSourceClass == Nil
                ? NULL
                : class_getInstanceMethod(dataSourceClass, rowCountSelector);
            if (rowCountMethod == NULL) {
                continue;
            }

            IMP currentImplementation = method_getImplementation(rowCountMethod);
            const char *typeEncoding = method_getTypeEncoding(rowCountMethod);
            BOOL addedOverride = class_addMethod(
                dataSourceClass,
                rowCountSelector,
                (IMP)CaptureDevicesDataSourceAndCountRows,
                typeEncoding
            );
            if (!addedOverride) {
                currentImplementation = method_setImplementation(
                    rowCountMethod,
                    (IMP)CaptureDevicesDataSourceAndCountRows
                );
            }

            originalDevicesRowCountImplementation = (FindMyDevicesRowCountImplementation)currentImplementation;
            self.isCaptureInstalled = YES;
            return;
        }
    }
}

- (void)recordDevicesDataSource:(id)dataSource {
    self.devicesDataSource = dataSource;
}

@end
