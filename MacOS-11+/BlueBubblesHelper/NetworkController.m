//
//  NetworkController.m
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/20/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkController.h"
#import "GCDAsyncSocket.h"
#import "Logging.h"

@implementation NetworkController

@synthesize messageReceivedBlock;


#pragma mark - Singleton

static id sharedInstance = nil;

+ (void)initialize {
  if (self == [NetworkController class]) {
    sharedInstance = [[self alloc] init];
  }
}

+ (NetworkController*)sharedInstance {
  return sharedInstance;
}


#pragma mark - Public methods

- (void)connect {
    // we need to get the port to open the server on (to allow multiple users to use the bundle)
    // we'll base this off the users uid (a unique id for each user, starting from 501)
    // we'll subtract 501 to get an id starting at 0, incremented for each user
    // then we add this to the base port to get a unique port for the socket
    int port = 45670 + getuid()-501;
    // connect to socket
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if (![asyncSocket connectToHost:@"localhost" onPort:port error:&err]) {
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        DLog(@"BLUEBUBBLESHELPER: Error connecting to socket: %@", err);
    }
    // initiate the 1st read request in anticipation
    [asyncSocket readDataWithTimeout:(-1) tag:(1)];
}



- (void)disconnect {
    [asyncSocket disconnect];
}

- (void)sendMessage:(NSDictionary*)data {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    // add a newline to the message so back-to-back messages are split and sent correctly
    NSString *jsonMessage = [NSString stringWithFormat:(@"%@\r\n"), message];
    NSData* finalData = [jsonMessage dataUsingEncoding:NSUTF8StringEncoding];
    DLog(@"BLUEBUBBLESHELPER: data: %@", data[@"event"]);
    [asyncSocket writeData:(finalData) withTimeout:(-1) tag:(1)];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    DLog(@"BLUEBUBBLESHELPER: socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    NSDictionary *message = @{@"event": @"ping", @"message": @"Helper Connected!"};
    [self sendMessage:message];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    DLog(@"BLUEBUBBLESHELPER: socketDidSecure:%p", sock);
}

// called when a message is sent to the server
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    DLog(@"BLUEBUBBLESHELPER: socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DLog(@"BLUEBUBBLESHELPER: event: %@ socket:%p didReadData:withTag:%ld", str, sock, tag);
    // initiate a new read request for the next data item
    [asyncSocket readDataWithTimeout:(-1) tag:(1)];
    // send the data to the handler
    messageReceivedBlock(self, str);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    DLog(@"BLUEBUBBLESHELPER: Disconnected from server, attempting to reconnect in 5 seconds...");
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        DLog(@"BLUEBUBBLESHELPER: Attempting to reconnect");
        [self connect];
    });
}

@end
