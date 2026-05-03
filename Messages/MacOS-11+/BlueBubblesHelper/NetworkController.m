//
//  NetworkController.m
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/20/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <os/log.h>
#import "NetworkController.h"
#import "GCDAsyncSocket.h"
#import "Logging.h"
#import "BlueBubblesHelper.h"

@implementation NetworkController


#pragma mark - Singleton

static id sharedInstance = nil;
os_log_t logger;

+ (void)initialize {
  if (self == [NetworkController class]) {
      sharedInstance = [[self alloc] init];
      logger = os_log_create("BlueBubblesHelper", "network-socket");
  }
}

+ (NetworkController*)sharedInstance {
  return sharedInstance;
}


#pragma mark - Public methods

#define CLAMP(x, low, high) (MAX(low, MIN(x, high)))

- (void)connect {
    // we need to get the port to open the server on (to allow multiple users to use the bundle)
    // we'll base this off the users uid (a unique id for each user, starting from 501)
    // we'll subtract 501 to get an id starting at 0, incremented for each user
    // then we add this to the base port to get a unique port for the socket
    int port = CLAMP(45670 + getuid()-501, 45670, 65535);
    os_log(logger, "Connecting to socket on port %d...", port);
    
    // connect to socket
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *err = nil;
    if (![asyncSocket connectToHost:@"localhost" onPort:port error:&err]) {
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        os_log_error(logger, "Failed to connect to socket! %@", err);
    }
    
    // initiate the 1st read request in anticipation
    [asyncSocket readDataWithTimeout:(-1) tag:(1)];
}

- (void)sendMessage:(NSDictionary*)data {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if (error) {
        os_log_error(logger, "Failed to serialize data! %@", error);
    } else {
        NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        // add a newline to the message so back-to-back messages are split and sent correctly
        NSString *jsonMessage = [NSString stringWithFormat:(@"%@\r\n"), message];
        NSData* finalData = [jsonMessage dataUsingEncoding:NSUTF8StringEncoding];
        
        os_log(logger, "Sending data to server:\r\n%@", data);
        [asyncSocket writeData:(finalData) withTimeout:(-1) tag:(1)];
    }
}

#pragma mark - Socket state change handlers

- (void)socket:(GCDAsyncSocket*)sock didConnectToHost:(NSString*)host port:(UInt16)port {
    os_log(logger, "Helper socket connected on port:%{public}hu", port);
    
    NSDictionary *message = @{
        @"event": @"ping",
        @"message": @"Helper Connected!",
        @"process": [[NSBundle mainBundle] bundleIdentifier],
    };
    [self sendMessage:message];
}

- (void)socket:(GCDAsyncSocket*)sock didReadData:(NSData*)data withTag:(long)tag {
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    os_log(logger, "Received data from server:\r\n%{public}@\r\nwith tag: %{public}ld", str, tag);
    // initiate a new read request for the next data item
    [asyncSocket readDataWithTimeout:(-1) tag:(1)];
    // send the data to the handler
    [[BlueBubblesHelper sharedInstance] handleMessage:self message:str];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    os_log_error(logger, "Disconnected from server, attempting to reconnect in 5 seconds...\r\n(%{public}@)", err);
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self connect];
    });
}

@end
