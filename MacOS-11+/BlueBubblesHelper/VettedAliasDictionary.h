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
-(BOOL)isEqual:(VettedAliasDictionary *)object;
-(NSUInteger)hash;
-(NSString *)description;

@end
