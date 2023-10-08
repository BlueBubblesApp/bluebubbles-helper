//
//  Logging.h
//  BlueBubblesHelper
//
//  Created by Samer Shihabi on 11/29/20.
//  Copyright © 2020 BlueBubbleMessaging. All rights reserved.
//
#include <os/log.h>
#ifndef Logging_h
#define Logging_h


#ifdef DEBUG
#    define ELog(N, ...) os_log_with_type(os_log_create("com.bluebubbles.messaging", "DEBUG"),OS_LOG_TYPE_ERROR,N,##__VA_ARGS__)
#else
#    define ELog(...) /* */
#endif
#ifdef DEBUG
#    define DLog(N, ...) os_log_with_type(os_log_create("com.bluebubbles.messaging", "DEBUG"),OS_LOG_TYPE_DEFAULT,N ,##__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif


#endif /* Logging_h */
