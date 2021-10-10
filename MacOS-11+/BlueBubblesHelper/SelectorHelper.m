//
//  SelectorHelper.m
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/29/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SelectorHelper.h"

@implementation SelectorHelper : NSObject
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
