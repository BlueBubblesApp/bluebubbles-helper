#import "IMMessagePartChatItem.h"

#ifndef IMCORE_TYPES

#define IMCORE_TYPES

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
NSString* IMCreateThreadIdentifierForMessagePartChatItem(IMMessagePartChatItem* chatItem);

#endif
