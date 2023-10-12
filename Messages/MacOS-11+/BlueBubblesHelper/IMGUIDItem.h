#import <Foundation/Foundation.h>

@protocol IMGUIDItem
@property(copy, nonatomic, setter=_setGUID:) NSString *guid; // @synthesize guid=_guid;
@end
