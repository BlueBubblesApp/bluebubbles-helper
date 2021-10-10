#import <Foundation/Foundation.h>
// #import "IMItemsController.h"
// #import "IMMessage.h"
// #import "IMInlineReplyChatItemRules.h"
// #import "IMChat.h"
#import "IMItem.h"

@class IMItemsController, IMMessage, IMInlineReplyChatItemRules, IMChat;

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
@interface IMInlineReplyController: IMItemsController
-(IMInlineReplyController*)initWithChat:(id)arg1 threadIdentifier:(id)arg2 threadOriginator:(id)arg3;
-(IMMessage*)firstMessage;
-(IMMessage*)lastMessage;
-(id)chatItems;
-(id)insertHistoricalMessages:(id)arg1 queryID:(id)arg2 hasMessagesBefore:(id)arg4 hasMessagesAfter:(id)arg5 isReplacingItems:(id)arg6;
-(void)_itemsDidChange:(NSArray<IMItem*>*)arg1;
-(void)insertItem:(IMItem*)item;
-(void)removeItem:(IMItem*)item;
-(void)replaceItems:(NSArray<IMItem*>*)items;
-(BOOL)itemMatchesThread:(IMItem*)item;
-(void)itemsMatchingThread:(id)arg1 guids:(NSArray<NSString*>*)arg2;
-(void)updateChatItemsIfNeeded;
-(void)performActionDisallowingItemInsert:(id)arg1;
-(void)_updateChatItems;
-(void)_updateChatItemsWithReason:(id)arg1 block:(id)arg2;
-(void)_updateChatItemsWithReason:(id)arg1 block:(id)arg2 shouldPost:(BOOL)arg3;
-(void)_replaceStaleChatItems;
-(void)_postIMChatItemsDidChangeNotificationWithInserted:(id)arg1 removed:(id)arg2 reload:(id)arg3 regenerate:(id)arg4 oldChatItems:(id)arg5 shouldLog:(BOOL)arg6;
-(void)_setupChatItemRules;
-(NSString*)threadIdentifier;
-(void)setThreadIdentifier:(NSString*)arg1;
-(IMChat*)chat;
-(void)setChat:(IMChat*)chat;
-(id)threadOriginator;
-(void)setThreadOriginator:(id)arg1;
-(BOOL)hasEarlierMessagesToLoad;
-(void)setHasEarlierMessagesToLoad:(BOOL)arg1;
-(BOOL)hasRecentMessagesToLoad;
-(void)setHasRecentMessagesToLoad:(BOOL)arg1;
-(BOOL)disableItemInserts;
-(void)setDisableItemInserts:(BOOL)arg1;
-(IMInlineReplyChatItemRules*)chatItemRules;
-(void)setChatItemRules:(IMInlineReplyChatItemRules*)arg1;
-(BOOL)isUpdatingChatItems;
-(void)setIsUpdatingChatItems:(BOOL)arg1;
@end
