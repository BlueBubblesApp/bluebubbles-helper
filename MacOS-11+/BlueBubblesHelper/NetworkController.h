//
//  NetworkController.h
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/20/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#ifndef NetworkController_h
#define NetworkController_h

// Block typedefs
@class NetworkController;
typedef void (^ConnectionBlock)(NetworkController*);
typedef void (^MessageBlock)(NetworkController*,NSString*);


@interface NetworkController : NSObject<NSStreamDelegate> {
  // Connection info
  NSString* host;
  int port;
  
  // Input
  NSInputStream* inputStream;
  NSMutableData* inputBuffer;
  BOOL isInputStreamOpen;
  
  // Output
  NSOutputStream* outputStream;
  NSMutableData* outputBuffer;
  BOOL isOutputStreamOpen;
  
  // Event handlers
  MessageBlock messageReceivedBlock;
  ConnectionBlock connectionOpenedBlock;
  ConnectionBlock connectionFailedBlock;
  ConnectionBlock connectionClosedBlock;
}

// Singleton instance
+ (NetworkController*)sharedInstance;

// Methods
- (void)connect;
- (void)disconnect;
- (void)sendMessage:(NSDictionary*)message;

// Properties
@property (copy) MessageBlock messageReceivedBlock;
@property (copy) ConnectionBlock connectionOpenedBlock;
@property (copy) ConnectionBlock connectionFailedBlock;
@property (copy) ConnectionBlock connectionClosedBlock;

@end
#endif /* NetworkController_h */
