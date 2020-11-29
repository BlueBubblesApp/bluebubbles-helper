//
//  Logging.h
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/29/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//

#ifndef Logging_h
#define Logging_h

#ifdef DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif

#endif /* Logging_h */
