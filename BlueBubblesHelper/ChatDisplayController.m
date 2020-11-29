//
//  ChatDisplayController.m
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/29/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatDisplayController.h"

@implementation ChatDisplayController
// Helper function to get the guid given a chat controller
+(NSString *) getGuid: (id) existingChatDisplayController {
    // Unfortunately, a regular selector does not work here, I'm not sure why
    // Thus I am forced to do this shit which basically requires that we loop through every
    // property of the existingChatDisplayController and find the one that we need, which is "chat"
    
    // Arbitrary number, we just need to loop through a bunch
    unsigned int outCount = 100, i;
    
    // Get all of the properties of the existingChatDisplayController
    objc_property_t *properties = class_copyPropertyList([existingChatDisplayController superclass], &outCount);
    
    // Loop through a bunch of times until we find what we need
    for(i = 0; i < outCount; i++) {
        // Get the property and property name
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        
        // If we have a propertyname that is not nil...
        if(propName) {
            // We convert the property name to an NSString
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            
            // If the property matches what we want, also known as "chat", we can return the chat
            if([propertyName isEqual:@"chat"]) {
                // Now we can do a regular selector for some reason
                id chat = [existingChatDisplayController valueForKey:propertyName];
                
                // Clean up
                free(properties);
                return [chat valueForKey:@"guid"];

            }
        }
    }
    // Clean up
    free(properties);
    
    // If we found nothing, we return nil
    return nil;
}

// Get an IMChat from a ChatDisplayController
+(id) getChat: (id) existingChatDisplayController {
    // Unfortunately, a regular selector does not work here, I'm not sure why
    // Thus I am forced to do this shit which basically requires that we loop through every
    // property of the existingChatDisplayController and find the one that we need, which is "chat"
    
    // Arbitrary number, we just need to loop through a bunch
    unsigned int outCount = 100, i;

    // Get all of the properties of the existingChatDisplayController
    objc_property_t *properties = class_copyPropertyList([existingChatDisplayController superclass], &outCount);
    
    // Loop through a bunch of times until we find what we need
    for(i = 0; i < outCount; i++) {
        // Get the property and property name
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        
        // If we have a propertyname that is not nil...
        if(propName) {
            // We convert the property name to an NSString
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            
            // If the property matches what we want, also known as "chat", we can return the chat
            if([propertyName isEqual:@"chat"]) {
                // Now we can do a regular selector for some reason
                id chat = [existingChatDisplayController valueForKey:propertyName];
                
                // Clean up
                free(properties);
                return chat;

            }
        }
    }
    
    // Clean up
    free(properties);
    
    // If we found nothing, we return nil
    return nil;
}
@end
