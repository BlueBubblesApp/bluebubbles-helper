//
//  VettedAliasDictionary.m
//  BlueBubblesHelper
//
//  Created by Tanay Neotia on 2/3/23.
//  Copyright © 2023 BlueBubbleMessaging. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VettedAliasDictionary : NSObject
@property NSDictionary *dictionary;
-(instancetype)initWithDictionary: (NSDictionary *)dict;
@end

@implementation VettedAliasDictionary

-(instancetype)initWithDictionary: (NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.dictionary = dict;
    }
    return self;
}

-(BOOL)isEqual:(VettedAliasDictionary *)object
{
    return [self.dictionary[@"name"] isEqual: object.dictionary[@"name"]];
}

-(NSUInteger)hash
{
    // implementation to get a "hash" from string
    NSString* name =  self.dictionary[@"name"];
    int h = 0;
    for (int i = 0; i < (int)name.length; i++) {
        h = (31 * h) + [name characterAtIndex: i];
    }
    return h;
}

-(NSString *)description
{
    return [self.dictionary description];
}

@end
