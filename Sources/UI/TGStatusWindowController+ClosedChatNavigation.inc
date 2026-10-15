#include "TGStatusWindowController+ClosedChatSuggestions.inc"

- (void)closeCurrentChatNavigation:(id)sender {
    (void)sender;
    if (![self.currentAuthState isEqualToString:@"ready"] || ![(self.activeSection ? self.activeSection : TGSectionChats) isEqualToString:TGSectionChats]) {
        return;
    }
    if (self.searchPanelVisible) {
        [self closeSearchPanel:sender];
        return;
    }
    NSNumber *previousChatID = [self.selectedChatID retain];
    NSNumber *previousThreadID = [self.selectedMessageThreadID retain];
    NSString *previousTopicKind = [self.selectedMessageTopicKind copy];
    [self saveComposerDraftForChatID:previousChatID
                     messageThreadID:previousThreadID
                    messageTopicKind:previousTopicKind];
    if (self.showingForumTopicList) {
        [self closeForumTopicList:nil];
    }
    self.chatNavigationClosed = YES;
    self.selectedChatID = nil;
    self.selectedChatTitle = nil;
    self.selectedChatTypeSummary = nil;
    self.selectedChatAvatarLocalPath = nil;
    self.selectedChatLastReadOutboxMessageID = nil;
    self.selectedMessageThreadID = nil;
    self.selectedMessageTopicKind = nil;
    self.pinnedMessageItems = [NSArray array];
    self.pinnedMessageItem = nil;
    self.pinnedMessageCarouselIndex = 0;
    self.searchGeneration++;
    [self.messageItems removeAllObjects];
    [self.inlineMediaPlaybackCoordinator removeAllPlayback];
    self.suppressChatSelectionHandling = YES;
    [self.chatTableView deselectAll:nil];
    self.suppressChatSelectionHandling = NO;
    [self.messageTableView reloadData];
    [self setComposerTextWithoutSavingDraft:nil];
    [self clearReplyTarget];
    [self refreshSelectedChatHeaderDisplay];
    [self rebuildClosedChatSuggestions];
    [self updateAuthControlsForState:self.currentAuthState];
    [self updateVisibleSection];
    [self layoutContentView];
    [[TGLogger sharedLogger] log:@"Navigation: current chat closed; showing recent private chat suggestions."];
    [previousChatID release];
    [previousThreadID release];
    [previousTopicKind release];
}

- (void)cancelOperation:(id)sender {
    [self closeCurrentChatNavigation:sender];
}

- (BOOL)isForumTopicAutoOpenSuppressedForChatID:(NSNumber *)chatID {
    return (self.suppressedForumTopicAutoOpenChatID &&
            [chatID respondsToSelector:@selector(longLongValue)] &&
            [self.suppressedForumTopicAutoOpenChatID longLongValue] == [chatID longLongValue]);
}
