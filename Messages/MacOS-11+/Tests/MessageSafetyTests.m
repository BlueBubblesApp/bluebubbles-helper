#import <Foundation/Foundation.h>
#define os_log(...) ((void)0)
#define os_log_error(...) ((void)0)

@interface NetworkController : NSObject
@property NSMutableArray *sent;
+ (instancetype)sharedInstance;
- (void)sendMessage:(NSDictionary *)message;
@end
@implementation NetworkController
+ (instancetype)sharedInstance { static id value; if (!value) value = [self new]; return value; }
- (instancetype)init { if ((self = [super init])) self.sent = [NSMutableArray new]; return self; }
- (void)sendMessage:(NSDictionary *)message { [self.sent addObject:message]; }
@end

@interface IMMessagePartChatItem : NSObject @end
@implementation IMMessagePartChatItem @end
@interface IMAggregateAttachmentMessagePartChatItem : IMMessagePartChatItem
@property NSArray *aggregateAttachmentParts;
@end
@implementation IMAggregateAttachmentMessagePartChatItem @end
@interface IMMessageItem : NSObject
@property id items;
- (id)_newChatItems __attribute__((objc_method_family(none)));
@end
@implementation IMMessageItem
- (id)_newChatItems { return self.items; }
@end
@interface IMMessage : NSObject
@property IMMessageItem *_imMessageItem;
@property BOOL typing;
- (BOOL)isTypingMessage;
@end
@implementation IMMessage
- (BOOL)isTypingMessage { return self.typing; }
@end
@interface IMChat : NSObject
@property NSString *guid;
@property IMMessage *lastIncomingMessage;
@end
@implementation IMChat @end
@interface IMChatHistoryController : NSObject
@property(copy) void (^pending)(IMMessage *);
+ (instancetype)sharedInstance;
- (void)loadMessageWithGUID:(NSString *)guid completionBlock:(void (^)(IMMessage *))block;
- (void)complete:(IMMessage *)message;
@end
@implementation IMChatHistoryController
+ (instancetype)sharedInstance { static id value; if (!value) value = [self new]; return value; }
- (void)loadMessageWithGUID:(NSString *)guid completionBlock:(void (^)(IMMessage *))block { self.pending = block; }
- (void)complete:(IMMessage *)message { void (^block)(IMMessage *) = self.pending; self.pending = nil; block(message); }
@end

@interface SKHandle : NSObject
@property NSString *handleString;
@end
@implementation SKHandle @end
@interface SKStatusPayload : NSObject
@property NSDictionary *payloadDictionary;
@end
@implementation SKStatusPayload @end
@interface SKPublishedStatus : NSObject
@property SKStatusPayload *statusPayload;
@end
@implementation SKPublishedStatus @end
@interface SKStatusSubscription : NSObject
@property NSArray *ownerHandles;
@property SKPublishedStatus *currentStatus;
@end
@implementation SKStatusSubscription @end

static NSMutableDictionary *handleAvailabilityStatuses;
@interface BlueBubblesHelper : NSObject
- (void)getIMMessageFromGuid:(NSString *)guid transaction:(NSString *)transaction completionBlock:(void (^)(IMMessage *))block;
- (void)getIMMessagePartChatItemFromGuid:(NSString *)guid atPartIndex:(NSUInteger)index transaction:(NSString *)transaction completionBlock:(void (^)(IMMessagePartChatItem *))block;
- (void)addHandleAvailabilityObserver;
- (void)addTypingIndicatorObserver;
@end
@implementation BlueBubblesHelper
/* SOURCE_METHODS */
@end

static int checks;
static void Check(BOOL value, NSString *message) { checks++; if (!value) { fprintf(stderr, "%s\n", message.UTF8String); exit(1); } }
static IMMessage *Message(id items) { IMMessage *m = [IMMessage new]; m._imMessageItem = [IMMessageItem new]; m._imMessageItem.items = items; return m; }
static NSDictionary *Last(void) { return [NetworkController sharedInstance].sent.lastObject; }
static void Clear(void) { [[NetworkController sharedInstance].sent removeAllObjects]; }

int main(void) { @autoreleasepool {
    BlueBubblesHelper *helper = [BlueBubblesHelper new];
    IMChatHistoryController *history = [IMChatHistoryController sharedInstance];
    handleAvailabilityStatuses = [NSMutableDictionary new];
    __block BOOL completed = NO;
    [helper getIMMessageFromGuid:@"fixture" transaction:@"missing" completionBlock:^(IMMessage *m) { completed = YES; }];
    Check(Last() == nil, @"History lookup must complete asynchronously in this fixture");
    [history complete:nil];
    Check(!completed && [Last()[@"error"] isEqual:@"MissingMessageException"] && [Last()[@"transactionId"] isEqual:@"missing"], @"Missing history must reject its transaction instead of invoking a nil-message callback");

    for (id items in @[@[], @[ [IMMessagePartChatItem new] ]]) {
        Clear();
        [helper getIMMessagePartChatItemFromGuid:@"fixture" atPartIndex:99 transaction:@"bad-index" completionBlock:^(IMMessagePartChatItem *part) { completed = YES; }];
        [history complete:Message(items)];
        Check([Last()[@"error"] isEqual:@"InvalidValueException"] && [Last()[@"transactionId"] isEqual:@"bad-index"], @"Empty or out-of-range parts must become a transaction error outside the dispatch-time catch");
    }
    Clear();
    [helper getIMMessagePartChatItemFromGuid:@"fixture" atPartIndex:0 transaction:@"no-item" completionBlock:^(IMMessagePartChatItem *part) { completed = YES; }];
    [history complete:Message(nil)];
    Check([Last()[@"error"] isEqual:@"MissingMessagePartException"], @"Missing chat item must fail safely");

    Clear(); IMMessagePartChatItem *part = [IMMessagePartChatItem new]; __block id selected;
    [helper getIMMessagePartChatItemFromGuid:@"fixture" atPartIndex:0 transaction:@"valid" completionBlock:^(IMMessagePartChatItem *item) { selected = item; }];
    [history complete:Message(@[part])];
    Check(selected == part && Last() == nil, @"Valid message-part lookup must keep its original behavior");
    IMAggregateAttachmentMessagePartChatItem *aggregate = [IMAggregateAttachmentMessagePartChatItem new];
    aggregate.aggregateAttachmentParts = @[[IMMessagePartChatItem new], part];
    [helper getIMMessagePartChatItemFromGuid:@"fixture" atPartIndex:1 transaction:@"gallery" completionBlock:^(IMMessagePartChatItem *item) { selected = item; }];
    [history complete:Message(@[aggregate])];
    Check(selected == part && Last() == nil, @"Valid aggregate fallback must still work");
    [helper getIMMessagePartChatItemFromGuid:@"fixture" atPartIndex:9 transaction:@"gallery-bad" completionBlock:^(IMMessagePartChatItem *item) {}];
    [history complete:Message(@[aggregate])];
    Check([Last()[@"error"] isEqual:@"InvalidValueException"], @"Aggregate bounds must also fail safely");

    Clear();
    [helper getIMMessageFromGuid:@"fixture" transaction:nil completionBlock:^(IMMessage *m) { [NSException raise:@"FixtureFailure" format:@"delayed failure"]; }];
    [history complete:Message(@[part])];
    Check([Last()[@"error"] isEqual:@"FixtureFailure"] && Last()[@"transactionId"] == [NSNull null], @"Delayed operation exceptions must retain a safe response even without a transaction value");

    Clear(); [helper addTypingIndicatorObserver];
    for (id object in @[[NSNull null], [NSObject new], [IMChat new]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"__kIMChatItemsDidChangeNotification" object:object];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"__kIMChatItemsDidChangeNotification" object:nil];
    Check(Last() == nil, @"Invalid typing notifications must not build a dictionary with a nil GUID");
    IMChat *chat = [IMChat new]; chat.guid = @"fixture-chat"; chat.lastIncomingMessage = [IMMessage new]; chat.lastIncomingMessage.typing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"__kIMChatItemsDidChangeNotification" object:chat];
    Check([Last()[@"event"] isEqual:@"started-typing"] && [Last()[@"guid"] isEqual:chat.guid], @"Valid typing notifications must preserve the Server event shape");
    chat.lastIncomingMessage.typing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"__kIMChatItemsDidChangeNotification" object:chat];
    Check([Last()[@"event"] isEqual:@"stopped-typing"], @"Stop-typing notifications must remain compatible");

    Clear(); [helper addHandleAvailabilityObserver];
    SKStatusSubscription *subscription = [SKStatusSubscription new];
    subscription.ownerHandles = @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IMHandleAvailabilityChangedNotification" object:subscription];
    Check(Last() == nil, @"An empty owner-handle list must not crash notification delivery");
    SKHandle *handle = [SKHandle new]; handle.handleString = @"fixture-handle"; subscription.ownerHandles = @[handle];
    subscription.currentStatus = [SKPublishedStatus new]; subscription.currentStatus.statusPayload = [SKStatusPayload new];
    subscription.currentStatus.statusPayload.payloadDictionary = @{};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IMHandleAvailabilityChangedNotification" object:subscription];
    Check(Last() == nil, @"A missing availability value must not be reported as Focus enabled");
    subscription.currentStatus.statusPayload.payloadDictionary = @{@"a": @1};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IMHandleAvailabilityChangedNotification" object:subscription];
    Check([Last()[@"event"] isEqual:@"focus-status-updated"] && [Last()[@"handle"] isEqual:handle.handleString] && [Last()[@"silenced"] isEqual:@NO], @"Valid Focus notifications must preserve their event fields");
    printf("PASS: %d Messages transaction/notification safety checks using actual helper methods and synthetic objects\n", checks);
} return 0; }
