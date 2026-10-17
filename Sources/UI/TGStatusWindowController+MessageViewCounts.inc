// Read-only group viewer counts. At most one request per window is in flight;
// only actually visible candidates are drained gradually, with a bounded TTL cache.
static char TGMessageViewCountStateKey;
- (void)refreshVisibleMessageViewCounts {
    if (![self conversationAllowsAutomaticRead] ||
        !([self.selectedChatTypeSummary isEqualToString:@"Group"] || [self.selectedChatTypeSummary isEqualToString:@"Supergroup"] ||
          [self.selectedChatTypeSummary isEqualToString:@"Forum"] || [self.selectedChatTypeSummary isEqualToString:@"Forum topic"] ||
          [self.selectedChatTypeSummary isEqualToString:@"Message thread"])) return;
    NSMutableDictionary *state = objc_getAssociatedObject(self,&TGMessageViewCountStateKey);
    if (!state) {
        state = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableDictionary dictionary],@"cache",nil];
        objc_setAssociatedObject(self,&TGMessageViewCountStateKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if ([[state objectForKey:@"busy"] boolValue]) return;
    NSString *context = [NSString stringWithFormat:@"%p|%@|%@|%@|%@|%lu",self.client,self.profileUserID,self.selectedChatID,self.selectedMessageThreadID,self.selectedMessageTopicKind,(unsigned long)self.automaticReadGeneration];
    NSMutableDictionary *cache = [state objectForKey:@"cache"];
    NSRange rows = [self.messageTableView rowsInRect:[[self.messageScrollView contentView] bounds]];
    if (rows.location == NSNotFound || !rows.length) return;
    NSUInteger end = MIN(NSMaxRange(rows),[self.messageItems count]);
    NSUInteger begin = MIN(rows.location,end);
    // Never evict a still-visible batch midway through draining it.
    NSUInteger capacity = MAX((NSUInteger)256,end-begin+32);
    if ([cache count] > capacity) [cache removeAllObjects];
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSMutableIndexSet *cachedChanges = [NSMutableIndexSet indexSet];
    TGMessageItem *candidate = nil;
    NSString *candidateKey = nil;
    for (NSUInteger cursor = end; cursor > begin; cursor--) {
        TGMessageItem *item = [self.messageItems objectAtIndex:cursor-1];
        if (![item outgoing] || [item sending] || [item failedToSend] || [item isChannelPost] ||
            [[item messageID] longLongValue] <= 0 || ![[item chatID] isEqual:self.selectedChatID] ||
            [[item messageViewCount] longLongValue] > 0) continue;
        NSString *key = [NSString stringWithFormat:@"%p|%@|%@|%@",self.client,self.profileUserID,[item chatID],[item messageID]];
        NSDictionary *entry = [cache objectForKey:key];
        id value = [entry objectForKey:@"value"];
        if (entry && now-[[entry objectForKey:@"at"] doubleValue] < (value == [NSNull null] ? 120.0 : 60.0)) {
            NSNumber *cachedCount = [value isKindOfClass:[NSNumber class]] ? value : nil;
            if ([item messageViewerCount] != cachedCount && ![[item messageViewerCount] isEqual:cachedCount]) {
                [item setMessageViewerCount:cachedCount];
                [cachedChanges addIndex:cursor-1];
            }
            continue;
        }
        if (!candidate) { candidate = item; candidateKey = key; }
    }
    // Height callbacks can synchronously replace the row models or selection.
    // Snapshot the request target and owner before notifying AppKit.
    BOOL needsLookup = candidate != nil;
    NSNumber *chat = [[candidate chatID] retain], *message = [[candidate messageID] retain];
    NSString *contextCopy = [context copy], *keyCopy = [candidateKey copy];
    TGTDLibClient *client = [self.client retain];
    if ([cachedChanges count]) {
        // Fresh row models can acquire a wider footer from a cached count.
        // Reflow the affected rows even though no network request is needed.
        // Height notifications may synchronously trigger scroll observers.
        [state setObject:@YES forKey:@"busy"];
        [self.messageTableView noteHeightOfRowsWithIndexesChanged:cachedChanges];
        [self.messageTableView setNeedsDisplay:YES];
        [state removeObjectForKey:@"busy"];
    }
    NSString *afterReflow = [NSString stringWithFormat:@"%p|%@|%@|%@|%@|%lu",self.client,self.profileUserID,self.selectedChatID,self.selectedMessageThreadID,self.selectedMessageTopicKind,(unsigned long)self.automaticReadGeneration];
    if (!needsLookup || ![contextCopy isEqual:afterReflow]) {
        [contextCopy release]; [keyCopy release]; [chat release]; [message release]; [client release];
        if (needsLookup) [self refreshVisibleMessageViewCounts];
        return;
    }
    [state setObject:@YES forKey:@"busy"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSNumber *count = [[client messageViewerCountForChatID:chat messageID:message timeout:2.0] retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [state removeObjectForKey:@"busy"];
            NSString *current = [NSString stringWithFormat:@"%p|%@|%@|%@|%@|%lu",self.client,self.profileUserID,self.selectedChatID,self.selectedMessageThreadID,self.selectedMessageTopicKind,(unsigned long)self.automaticReadGeneration];
            if ([contextCopy isEqual:current] && [self conversationAllowsAutomaticRead]) {
                [cache setObject:[NSDictionary dictionaryWithObjectsAndKeys:count ? (id)count : (id)[NSNull null],@"value",[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]],@"at",nil] forKey:keyCopy];
                NSMutableIndexSet *changed = [NSMutableIndexSet indexSet];
                NSUInteger row = 0;
                for (TGMessageItem *item in self.messageItems) {
                    if ([[item chatID] isEqual:chat] && [[item messageID] isEqual:message] &&
                        [item messageViewerCount] != count && ![[item messageViewerCount] isEqual:count]) {
                        [item setMessageViewerCount:count]; [changed addIndex:row];
                    }
                    row++;
                }
                if ([changed count]) {
                    [self.messageTableView noteHeightOfRowsWithIndexesChanged:changed];
                    [self.messageTableView setNeedsDisplay:YES];
                }
            }
            // A completed old context must not starve the newly visible chat.
            [self refreshVisibleMessageViewCounts];
            [count release]; [contextCopy release]; [keyCopy release]; [chat release]; [message release]; [client release];
        });
        [pool drain];
    });
}
