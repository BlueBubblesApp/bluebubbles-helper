//
//  IDS.h
//  BlueBubblesHelper
//
//  Created by Tanay Neotia on 7/8/23.
//  Copyright © 2023 BlueBubbleMessaging. All rights reserved.
//

#import "IDSDestination-Additions.h"

IDSDestination* IDSCopyIDForPhoneNumber(CFStringRef);
IDSDestination* IDSCopyIDForEmailAddress(CFStringRef);
IDSDestination* IDSCopyIDForBusinessID(CFStringRef);

extern NSString* IDSServiceNameiMessage;
extern NSString* IDSServiceNameSMSRelay;
extern NSString* IDSServiceNameFaceTime;
extern NSString* IDSServiceNameFaceTimeMultiway;
extern NSString* IDSServiceNameFaceTimeMulti;
extern NSString* IDSServiceNameQuickRelayFaceTime;
extern NSString* IDSServiceNameCalling;
extern NSString* IDSServiceNameSpringBoardNotificationSync;
extern NSString* IDSServiceNamePhotoStream;
extern NSString* IDSServiceNameMaps;
extern NSString* IDSServiceNameScreenSharing;
extern NSString* IDSServiceNameMultiplex1;
extern NSString* IDSServiceNameiMessageForBusiness;
