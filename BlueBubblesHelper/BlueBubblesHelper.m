//
//  whosTyping.m
//  whosTyping
//
//  Created by Wolfgang Baird on 1/21/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import <objc/runtime.h>

#import "JSRollCall.h"
#import "IMHandle.h"
#import "IMPerson.h"
#import "IMAccount.h"
#import "IMAccountController.h"
#import "IMService-IMService_GetService.h"
#import "IMChat.h"
#import "NetworkController.h"

#ifdef DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif

@interface blueBubblesHelper : NSObject
+ (instancetype)sharedInstance;
@end

blueBubblesHelper *plugin;
NSUInteger typingIndicators = 0;

typedef NS_ENUM(NSUInteger, WBWT_StatusBarType) {
    WBWT_StatusBarTypeTyping,
    WBWT_StatusBarTypeRead,
    WBWT_StatusBarTypeEmpty
};

NSString *__kIMChatComposeTyping = @"__kIMChatComposeTyping";

@interface ChatDisplayController : NSObject
+(NSString *) getGuid: (id) existingChatDisplayController;
@end
    

@implementation ChatDisplayController
+(NSString *) getGuid: (id) existingChatDisplayController {
    unsigned int outCount = 100, i;

    
   objc_property_t *properties = class_copyPropertyList([existingChatDisplayController superclass], &outCount);
   for(i = 0; i < outCount; i++) {
       objc_property_t property = properties[i];
       const char *propName = property_getName(property);
       if(propName) {
           NSString *propertyName = [NSString stringWithUTF8String:propName];
           if([propertyName isEqual:@"chat"]) {
               id chat = [existingChatDisplayController valueForKey:propertyName];
               return [chat valueForKey:@"guid"];

           }
       }
   }
   free(properties);
    return nil;
}
+(id) getChat: (id) existingChatDisplayController {
    unsigned int outCount = 100, i;

    
   objc_property_t *properties = class_copyPropertyList([existingChatDisplayController superclass], &outCount);
   for(i = 0; i < outCount; i++) {
       objc_property_t property = properties[i];
       const char *propName = property_getName(property);
       if(propName) {
           NSString *propertyName = [NSString stringWithUTF8String:propName];
           if([propertyName isEqual:@"chat"]) {
               id chat = [existingChatDisplayController valueForKey:propertyName];
               return chat;

           }
       }
   }
   free(properties);
    return nil;
}
@end


@implementation blueBubblesHelper

+ (instancetype)sharedInstance {
    static blueBubblesHelper *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

+ (void)load {
    plugin = [blueBubblesHelper sharedInstance];
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    DLog(@"BLUEBUBBLESHELPER: %@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
    NetworkController *controller = [NetworkController sharedInstance];
    [controller connect];
    controller.connectionFailedBlock = ^(NetworkController *connection) {
        DLog(@"BLUEBUBBLESHELPER: Failed to connect to server, trying again in 5 seconds...");
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DLog(@"BLUEBUBBLESHELPER: Attempting to reconnect");
            [connection connect];
        });
    };
    
    controller.connectionClosedBlock = ^(NetworkController *connection) {
        DLog(@"BLUEBUBBLESHELPER: Disconnected from server, attempting to reconnect in 5 seconds...");
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DLog(@"BLUEBUBBLESHELPER: Attempting to reconnect");
            [connection connect];
        });
    };
    controller.connectionOpenedBlock = ^(NetworkController *controller) {
        DLog(@"BLUEBUBBLESHELPER: Connected to server!");
    };
    controller.messageReceivedBlock =  ^(NetworkController *controller, NSString *data) {
        DLog(@"BLUEBUBBLESHELPER: Received raw json: %@", data);
        NSError *error;
        NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];

        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

        
        NSString *event = dictionary[@"event"];
        NSString *eventData = dictionary[@"data"];
        DLog(@"BLUEBUBBLESHELPER: Message received: %@, %@", event, eventData);
        if([event isEqualToString: @"start-typing"]) {
            [blueBubblesHelper getChat:eventData completion:^(id chat) {
                if(chat != nil) {
                    DLog(@"BLUEBUBBLESHELPER: Sending typing event");
                    [chat performSelector:@selector(setLocalUserIsComposing:typingIndicatorData:) withObject: __kIMChatComposeTyping withObject: NULL];
                } else {
                    DLog(@"BLUEBUBBLESHELPER: Chat is nil... %@", event);
                }
            }];
            

        } else if([event isEqualToString:@"stop-typing"]) {
            [self getChat:eventData completion:^(id chat) {
                if(chat != nil)

                [chat performSelector:@selector(setLocalUserIsComposing:typingIndicatorData:) withObject: NULL withObject: NULL];
            }];

        } else {
            DLog(@"BLUEBUBBLESHELPER: Not implemented %@", event);
        }


    };
    NSDictionary *message = @{@"event": @"ping", @"message": @"Helper Connected!"};
    [controller sendMessage:message];
}

+(void) getChat: (NSString *) guid completion: (void (^)(id chat)) completion{
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
           JSRollCall *rc = [JSRollCall new];
    
        [rc allObjectsOfClassName:@"ChatTableCellView" includeSubclass:YES performBlock:^(id obj) {
             id controller = [blueBubblesHelper getValueForKey:@"chatDisplayController" :obj];
            [controllers addObject:controller];
             NSString *_guid = [ChatDisplayController getGuid:controller];
             if([_guid isEqualToString: guid]) {
                 id chat = [ChatDisplayController getChat:controller];
                 completion(chat);

             }
         }];
        
}

-(void) sendMessage: (NSDictionary*) payload {
//    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"BLUEBUBBLESHELPER" object:nil userInfo: payload];

}

+(id) getValueForKey: (NSString *) key: (id) class {
    unsigned int outCount = 100, i;

    
   objc_property_t *properties = class_copyPropertyList([class class], &outCount);
   for(i = 0; i < outCount; i++) {
       objc_property_t property = properties[i];
       const char *propName = property_getName(property);
       if(propName) {
           NSString *propertyName = [NSString stringWithUTF8String:propName];
           if([propertyName  isEqual: key]) {
               id value = [class valueForKey: propertyName];
               return value;
            
           }
       }
   }
   free(properties);
    return nil;
}


@end


ZKSwizzleInterface(WBWT_IMMessage, IMMessage, NSObject)
@implementation WBWT_IMMessage

+ (id)instantMessageWithAssociatedMessageContent:(id)arg1 flags:(unsigned long long)arg2 associatedMessageGUID:(id)arg3 associatedMessageType:(long long)arg4 associatedMessageRange:(struct _NSRange)arg5 messageSummaryInfo:(id)arg6 {
    /*/
     BLUEBUBBLESHELPER: instantMessageWithAssociatedMessageContent, Loved “Test”{
         "__kIMMessagePartAttributeName" = 0;
     }, 0, p:0/09EF06EB-E67C-47C0-ABBD-26310BF954AE, 2000, {
         amc = 1;
         ams = Test;
     }, (null)
     associatedMessageType: left -> right 2000 ->
     */
    
    

//    testRange.amc = arg5.amc;
//    testRange.ams = @"Test";
    
    DLog(@"BLUEBUBBLESHELPER: instantMessageWithAssociatedMessageContent, %@, %llu, %@, %lld, %@, %@", [arg1 class], arg2, [arg3 class], arg4, arg5, arg6);
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"TEST REACTION"];
    return ZKOrig(id, string, arg2, arg3, arg4, arg5, NULL);
}

@end

ZKSwizzleInterface(WBWT_IMChat, IMChat, NSObject)
@implementation WBWT_IMChat

- (void) sendMessage:(id)arg1 {
    /* REGULAR MESSAGE
     InstantMessage[from=e:; msg-subject=(null); account:053CB8C2-3D2E-4DA6-8D29-419A2F5D4D49; flags=5; subject='(null)' text='(null)' messageID: 0 GUID:'D5E40A69-68EF-4C5D-8F3C-C1543988666F' sortID: 0 date:'627629434.853740' date-delivered:'0.000000' date-read:'0.000000' date-played:'0.000000' empty: NO finished: YES sent: NO read: NO delivered: NO audio: NO played: NO from-me: YES emote: NO dd-results: NO dd-scanned: NO error: (null) associatedMessageGUID: (null) associatedMessageType: 0 balloonBundleID: (null) expressiveSendStyleID: (null) timeExpressiveSendStylePlayed: 0.000000 bizIntent:(null) locale:(null), ]
        REACTION
     IMMessage[from=(null); msg-subject=(null); account:(null); flags=5; subject='(null)' text='(null)' messageID: 0 GUID:'79045C8B-1E6E-480B-8819-37E36C517578' sortID: 0 date:'627629508.210384' date-delivered:'0.000000' date-read:'0.000000' date-played:'0.000000' empty: NO finished: YES sent: NO read: NO delivered: NO audio: NO played: NO from-me: YES emote: NO dd-results: NO dd-scanned: NO error: (null) associatedMessageGUID: p:0/0C14634E-563D-408C-B9D4-805FEF7ADC7B associatedMessageType: 2001 balloonBundleID: (null) expressiveSendStyleID: (null) timeExpressiveSendStylePlayed: 0.000000 bizIntent:(null) locale:(null), ]
     
     */
    DLog(@"BLUEBUBBLESHELPER: sendMessage %@", arg1);
    ZKOrig(void, arg1);
}

@end


ZKSwizzleInterface(WBWT_SOTypingIndicatorView, SOTypingIndicatorView, NSView)
@implementation WBWT_SOTypingIndicatorView

- (void)destroyTypingLayer {
    id guid = [self getGuid];
    if(guid != nil) {
        DLog(@"BLUEBUBBLESHELPER: %@ Stopped typing", guid);
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
        id chat = [self getChat];
        DLog(@"BLUEBUBBLESHELPER: CurrentChat %@", chat);
        [chat performSelector:@selector(setLocalUserIsComposing:typingIndicatorData:) withObject: NULL withObject: NULL];

    }
    
    ZKOrig(void);
}


- (void)startPulseAnimation {
    id guid = [self getGuid];
    if(guid != nil) {
        DLog(@"BLUEBUBBLESHELPER: %@ Started typing", guid);
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
    
    }
    
    ZKOrig(void);
}
- (id) getChat {
    NSView *maskedView = self.superview;
    NSView *maskedViewParent = maskedView.superview;
    NSView *secondaryMaskedViewParent = maskedViewParent.superview;
    NSView *chatTableCellView = secondaryMaskedViewParent.superview;
    id existingChatDisplayController = [blueBubblesHelper getValueForKey:@"chatDisplayController": chatTableCellView ];
    return [ChatDisplayController getChat:existingChatDisplayController];
}

- (id)getGuid {
    NSView *maskedView = self.superview;
    NSView *maskedViewParent = maskedView.superview;
    NSView *secondaryMaskedViewParent = maskedViewParent.superview;
    NSView *chatTableCellView = secondaryMaskedViewParent.superview;
    id existingChatDisplayController = [blueBubblesHelper getValueForKey:@"chatDisplayController": chatTableCellView ];

    return [ChatDisplayController getGuid:existingChatDisplayController];

}


@end



@interface IMDMessageStore : NSObject
+ (id)sharedInstance;
- (id)messageWithGUID:(id)arg1;
@end

ZKSwizzleInterface(WBWT_IMDServiceSession, IMDServiceSession, NSObject)
@implementation WBWT_IMDServiceSession

+ (id)sharedInstance {
    return ZKOrig(id);
}

- (id)messageWithGUID:(id)arg1 {
    return ZKOrig(id, arg1);
}

- (void)didReceiveMessageReadReceiptForMessageID:(NSString *)messageID date:(NSDate *)date completionBlock:(id)completion {
    ZKOrig(void, messageID, date, completion);
    Class IMDMS = NSClassFromString(@"IMDMessageStore");
//    [plugin WBWT_SetStatus:WBWT_StatusBarTypeRead :[[[IMDMS sharedInstance] messageWithGUID:messageID] valueForKey:@"handle"]];
//    HBTSPostMessage(HBTSMessageTypeReadReceipt, [[%c(IMDMessageStore) sharedInstance] messageWithGUID:messageID].handle, NO);
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([userDefaults doubleForKey:kWBWT_PreferencesDurationKey] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [plugin WBWT_SetStatus:WBWT_StatusBarTypeEmpty :nil];
//    });
}

@end

//ZKSwizzleInterface(WBWT_IMMessage, IMMessage, NSObject)
//@implementation WBWT_IMMessage
//
//- (void)_updateTimeRead:(id)arg1 {
//    ZKOrig(void, arg1);
//    DLog(@"typeStatus : _updateTimeRead");
//}
//
//@end


