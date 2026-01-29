#import <Foundation/Foundation.h>

@interface IMDServiceController : NSObject
+ (id)sharedController;
- (BOOL)_bundleAllowedToLoadWithProperties:(id)a3;
- (id)init;
- (id)allServices;
- (id)serviceCapabilityCache;
- (id)servicesSupportingCapability:(id)a3;
- (void)registerSessionClassWithBundle:(id)a3;
- (void)setServiceCapabilityCache:(id)a3;
- (void)setServiceNameCapabilityCache:(id)a3;
- (void)setServices:(id)a3;
@end
