@import AppKit;

#import <Foundation/Foundation.h>

#import "NetworkController.h"
#import "Logging.h"
#import "ZKSwizzle.h"
#import "TUConversationManager.h"
#import "TUConversationLink.h"
#import "TUConversationManagerXPCClient.h"
#import "TUProxyCall.h"
#import "TUAnswerRequest.h"
#import "TUCallCenter.h"
#import "TUConversation.h"
#import "TUConversationJoinRequest.h"
#import "TUConversationMember.h"
#import "CSDConversation.h"
#import "CSDConversationManager.h"
#import "TUCall.h"

@interface BLUEBUBBLESFACETIMEHELPER : NSObject
+ (instancetype)sharedInstance;
@end

// This can be used to dump the methods of any class
@interface NSObject (Private)
- (NSString*)_methodDescription;
@end

BLUEBUBBLESFACETIMEHELPER *plugin;

@implementation BLUEBUBBLESFACETIMEHELPER

// BLUEBUBBLESFACETIMEHELPER is a singleton
+ (instancetype)sharedInstance {
    static BLUEBUBBLESFACETIMEHELPER *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

// Helper method to log a long string
-(void) logString:(NSString*)logString{

        int stepLog = 800;
        NSInteger strLen = [@([logString length]) integerValue];
        NSInteger countInt = strLen / stepLog;

        if (strLen > stepLog) {
        for (int i=1; i <= countInt; i++) {
            NSString *character = [logString substringWithRange:NSMakeRange((i*stepLog)-stepLog, stepLog)];
            DLog("BLUEBUBBLESFACETIMEHELPER: %{public}@", character);

        }
        NSString *character = [logString substringWithRange:NSMakeRange((countInt*stepLog), strLen-(countInt*stepLog))];
            DLog("BLUEBUBBLESFACETIMEHELPER: %{public}@", character);
        } else {

            DLog("BLUEBUBBLESFACETIMEHELPER: %{public}@", logString);
        }

}

// Called when macforge initializes the plugin
+ (void)load {
    // Create the singleton
    plugin = [BLUEBUBBLESFACETIMEHELPER sharedInstance];

    // Get OS version for debugging purposes
    NSUInteger major = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
    NSUInteger minor = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    DLog("BLUEBUBBLESFACETIMEHELPER: %{public}@ loaded into %{public}@ on macOS %ld.%ld", [self className], [[NSBundle mainBundle] bundleIdentifier], (long)major, (long)minor);

    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.FaceTime"] || [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.TelephonyUtilities"]) {
        DLog("BLUEBUBBLESFACETIMEHELPER: Initializing Connection...");
        [plugin initializeNetworkController];
    } else {
        DLog("BLUEBUBBLESFACETIMEHELPER: Injected into non-FaceTime process %@, aborting.", [[NSBundle mainBundle] bundleIdentifier]);
        return;
    }
}

-(void) DumpObjcMethods:(Class) clz {

    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount);

    DLog("BLUEBUBBLESFACETIMEHELPER: Found %d methods on '%s'\n", methodCount, class_getName(clz));

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];

        DLog("\tBLUEBUBBLESFACETIMEHELPER: '%s' has method named '%s' of encoding '%s'\n",
               class_getName(clz),
               sel_getName(method_getName(method)),
               method_getTypeEncoding(method));
    }

    free(methods);
}

// Private method to initialize all the things required by the plugin to communicate with the main
// server over a tcp socket
-(void) initializeNetworkController {
    // Get the network controller
    NetworkController *controller = [NetworkController sharedInstance];
    [controller connect];

    // Upon receiving a message
    controller.messageReceivedBlock =  ^(NetworkController *controller, NSString *data) {
        [self handleMessage:controller message: data];
    };
    NSDictionary *message = @{@"event": @"ping", @"message": @"Helper Connected!"};
    [controller sendMessage:message];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        DLog("BLUEBUBBLESFACETIMEHELPER: Registering call listeners...");

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStatusChanged:) name:@"TUCallCenterVideoCallStatusChangedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStatusChanged:) name:@"TUCallCenterCallStatusChangedNotification" object:nil];
        
        // [self handleMessage:controller message:@"{\"action\":\"invalidate-link\",\"transactionId\":\"bruh\",\"data\":{\"url\":\"https://facetime.apple.com/join#v=1&p=5rYoTVvAEe6LSjJziwUUiw&k=h9yNjziqokL3lLK-JEq-1_uae-KCvqKvayGsrkdNmGg\"}}"];
    });
}

-(void) callStatusChanged: (NSNotification *)notification {
    TUProxyCall *call = [notification object];
    NSDictionary *data = @{
        @"audio_mode": [call audioMode] ?: [NSNull null],
        @"call_status": [NSNumber numberWithInt:[call callStatus]] ?: [NSNull null],
        @"call_uuid": [call callUUID] ?: [NSNull null],
        @"is_conversation": [NSNumber numberWithBool:[call isConversation]] ?: [NSNull null],
        @"disconnected_reason": [NSNumber numberWithInt:[call disconnectedReason]] ?: [NSNull null],
        @"ended_error": [call endedErrorString] ?: [NSNull null],
        @"ended_reason": [call endedReasonString] ?: [NSNull null],
        @"handle": [[call handle] dictionaryRepresentation] ?: [NSNull null],
        @"is_sending_audio": [NSNumber numberWithBool:[call isSendingAudio]] ?: [NSNull null],
        @"is_sending_video": [NSNumber numberWithBool:[call isSendingVideo]] ?: [NSNull null],
        @"is_outgoing": [NSNumber numberWithBool:[call isOutgoing]] ?: [NSNull null],
    };
    [[NetworkController sharedInstance] sendMessage: @{@"event": @"ft-call-status-changed", @"data": data}];
}

// Run when receiving a new message from the tcp socket
-(void) handleMessage: (NetworkController*)controller  message:(NSString *)message {
    // The data is in the form of a json string, so we need to convert it to a NSDictionary
    // for some reason the data is sometimes duplicated, so account for that
    NSRange range = [message rangeOfString:@"}\n{"];
    if(range.location != NSNotFound) {
        message = [message substringWithRange:NSMakeRange(0, range.location + 1)];
    }
    DLog("BLUEBUBBLESFACETIMEHELPER: Received raw json: %{public}@", message);
    NSError *error;
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    // Event is the type of packet that was sent
    NSString *event = dictionary[@"action"];
    // Data is the actual information that we need in the packet
    NSDictionary *data = dictionary[@"data"];
    // Transaction ID enables us to communicate back to the server that the action was complete
    NSString *transaction = nil;
    if ([dictionary objectForKey:(@"transactionId")] != [NSNull null]) {
        transaction = dictionary[@"transactionId"];
    }

    DLog("BLUEBUBBLESFACETIMEHELPER: Message received: %{public}@, %{public}@", event, data);
    
    if ([event isEqualToString:@"answer-call"]) {
        TUCall *call = [[TUCallCenter sharedInstance] callWithCallUUID:(data[@"callUUID"])];
        
        if ([call callStatus] != 4) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Call is not waiting to be answered!"}];
            }
            return;
        }
        
        [[TUCallCenter sharedInstance] answerOrJoinCall:call];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    } else if ([event isEqualToString:@"leave-call"]) {
        TUCall *call = [[TUCallCenter sharedInstance] callWithCallUUID:(data[@"callUUID"])];
        
        if ([call callStatus] != 1) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Call is not waiting to be left!"}];
            }
            return;
        }
        
        [[TUCallCenter sharedInstance] disconnectCall:call];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    } else if ([event isEqualToString:@"generate-link"]) {
        if (data[@"callUUID"] != [NSNull null]) {
            TUCall *call = [[TUCallCenter sharedInstance] callWithCallUUID:(data[@"callUUID"])];
            TUConversation* convo = [[TUCallCenter sharedInstance] activeConversationForCall:call];
            TUConversationManagerXPCClient *manager = [[TUConversationManagerXPCClient alloc] init];
            [manager generateLinkForConversation:convo completionHandler:^(TUConversationLink *arg0, NSError *arg1) {
                DLog("BLUEBUBBLESFACETIMEHELPER: generated link for call %{public}@", [arg0 URL]);
                
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"url": [[arg0 URL] absoluteString]}];
                }
            }];
        } else {
            TUConversationManagerXPCClient *manager = [[TUConversationManagerXPCClient alloc] init];
            [manager generateLinkWithInvitedMemberHandles:@[] linkLifetimeScope:0 completionHandler:^(TUConversationLink *arg0, NSError *arg1) {
                DLog("BLUEBUBBLESFACETIMEHELPER: generated link %{public}@", [arg0 URL]);
                
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"url": [[arg0 URL] absoluteString]}];
                }
            }];
        }
    } else if ([event isEqualToString:@"admit-pending-member"]) {
        TUConversation* convo;
        for (TUConversation* i in [[[TUConversationManager alloc] init] activeConversations]) {
            if ([[[i groupUUID] UUIDString] isEqualToString:(data[@"conversationUUID"])]) {
                convo = i;
                break;
            }
        }
        
        if (convo != nil) {
            for (TUConversationMember *i in [convo pendingMembers]) {
                DLog("BLUEBUBBLESFACETIMEHELPER: found pending member %{public}@", i);
                if ([[[i handle] value] isEqualToString:(data[@"handleUUID"])]) {
                    DLog("BLUEBUBBLESFACETIMEHELPER: approving pending member");
                    [[[TUConversationManager alloc] init] approvePendingMember:i forConversation:convo];
                    if (transaction != nil) {
                        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
                    }
                    break;
                }
            }
        }
    } else if ([event isEqualToString:@"get-active-links"]) {
        NSArray<TUConversationLink*>* links = [[[[TUConversationManager alloc] init] activatedConversationLinks] allObjects];
        
        NSDictionary *data = @{
            @"links": [[NSMutableArray alloc] initWithArray: @[]],
        };
        
        for (TUConversationLink* link in links) {
            NSMutableArray *handleArray = [NSMutableArray array];
            [[[link invitedMemberHandles] allObjects] enumerateObjectsUsingBlock:^(TUHandle* obj, NSUInteger idx, BOOL *stop) {
                [handleArray addObject:[obj dictionaryRepresentation]];
            }];
            NSDictionary* linkData = @{
                @"url": [[link URL] absoluteString] ?: [NSNull null],
                @"creation_date": [NSNumber numberWithDouble:([[link creationDate] timeIntervalSince1970] * 1000)] ?: [NSNull null],
                @"expiration_date": [NSNumber numberWithDouble:([[link expirationDate] timeIntervalSince1970] * 1000)] ?: [NSNull null],
                @"group_uuid": [[link groupUUID] UUIDString] ?: [NSNull null],
                @"name": [link linkName] ?: [NSNull null],
                @"handles": handleArray ?: [NSNull null],
            };
            
            [data[@"links"] addObject:linkData];
        }
        
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"data": data}];
        }
    } else if ([event isEqualToString:@"invalidate-link"]) {
        NSArray<TUConversationLink*>* links = [[[[TUConversationManager alloc] init] activatedConversationLinks] allObjects];
        
        for (TUConversationLink* link in links) {
            if ([[[link URL] absoluteString] isEqualToString:data[@"url"]]) {
                [[[TUConversationManagerXPCClient alloc] init] invalidateLink:link completionHandler:^(char arg0, NSError* arg1) {
                    if (transaction != nil) {
                        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
                    }
                }];
                break;
            }
        }
    } else if ([event isEqualToString:@"start-call"]) {
        
    }
}

@end


//ZKSwizzleInterface(BBH_NSNotificationCenter, NSNotificationCenter, NSObject)
//@implementation BBH_NSNotificationCenter
//
//- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
//    if ([aName isEqualToString:@"CNContactStoreDidChangeNotification"]) {
//        return ZKOrig(void, observer, aSelector, aName, anObject);
//    }
//    DLog("BLUEBUBBLESFACETIMEHELPER: >>>>>>>>>>>>> name %{public}@", aName);
//    DLog("BLUEBUBBLESFACETIMEHELPER: observer %{public}@", observer);
//    DLog("BLUEBUBBLESFACETIMEHELPER: sel %{public}@", NSStringFromSelector(aSelector));
//    DLog("BLUEBUBBLESFACETIMEHELPER: object %{public}@", anObject);
//    return ZKOrig(void, observer, aSelector, aName, anObject);
//}
//
//@end


//ZKSwizzleInterface(WBWT_TUConversationManager, TUConversationManager, NSObject)
//@implementation WBWT_TUConversationManager
//
//-(void)receivedTrackedPendingMember:(TUConversationMember*)member forConversationLink:(TUConversationLink*)link {
//    NSDictionary *data = @{
//        @"letmein_received": [NSNumber numberWithDouble:[[member dateReceivedLetMeIn] timeIntervalSince1970] * 1000] ?: [NSNull null],
//        @"letmein_initiated": [NSNumber numberWithDouble:[[member dateInitiatedLetMeIn] timeIntervalSince1970] * 1000] ?: [NSNull null],
//        @"handle": [[member handle] dictionaryRepresentation],
//        @"name": [member nickname],
//        @"link": [[link URL] absoluteString],
//    };
//    DLog("BLUEBUBBLESFACETIMEHELPER: object %{public}@", [[[TUConversationManager alloc] init] activeConversationWithGroupUUID:([link groupUUID])]);
//    [[NetworkController sharedInstance] sendMessage: @{@"event": @"received-pending-member", @"data": data}];
//    return ZKOrig(void, member, link);
//}
//
//@end
//
//ZKSwizzleInterface(WBWT_NSUserNotification, CSDConversation, NSObject)
//@implementation WBWT_NSUserNotification
//
//- (void)addPendingMembers:(id)arg1 triggeredLocally:(BOOL)arg2 {
//    DLog("BLUEBUBBLESFACETIMEHELPER: got pending member %{public}@", arg1);
////    NSUUID *guid = (NSUUID *)ZKHookIvar(self, NSUUID*, "_groupUUID");
////    DLog("BLUEBUBBLESFACETIMEHELPER: convo %{public}@", guid);
////    //DLog("BLUEBUBBLESFACETIMEHELPER: convo 2 %{public}@", [[[TUConversationManager alloc] init] activeConversations]);
////    DLog("BLUEBUBBLESFACETIMEHELPER: convo %{public}@", NSClassFromString(@"CSDConversationManager"));
//    // [[[TUConversationManagerXPCClient alloc] init] approvePendingMember:[arg1 firstObject] forConversation:([[[[TUConversationManager alloc] init] activeConversationWithGroupUUID:guid] firstObject])];
//    return ZKOrig(void, arg1, arg2);
//}
//
//@end
