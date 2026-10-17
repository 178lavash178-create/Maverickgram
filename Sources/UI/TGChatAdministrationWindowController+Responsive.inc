- (void)layoutResponsiveViews {
    if(!self.responsiveLayout)return;
    NSSize size=TGUtilityRestoreResponsiveLayout(self.responsiveLayout);CGFloat w=size.width,h=size.height;
    [TGUtilityResponsiveView(self.responsiveLayout,@"title") setFrame:NSMakeRect(24,h-48,w-148,28)];
    [self.expirationPopUpButton setFont:[NSFont systemFontOfSize:13]];
    BOOL actionTitlesNeedRoom=TGUtilityResponsiveButtonWidth(self.copyLinkButton,12)>50||TGUtilityResponsiveButtonWidth(self.revokeLinkButton,12)>52||TGUtilityResponsiveButtonWidth(self.createLinkButton,12)>96;
    if(w<900||actionTitlesNeedRoom){
        CGFloat column=floor((w-116)/2),rightX=w-34-column;
        CGFloat lift=MIN(24,MAX(0,590-h));
        CGFloat cardBottom=h-390+lift;
        [TGUtilityResponsiveView(self.responsiveLayout,@"linksCard") setFrame:NSMakeRect(20,cardBottom,column+28,324-lift)];
        [TGUtilityResponsiveView(self.responsiveLayout,@"requestsCard") setFrame:NSMakeRect(rightX-14,cardBottom,column+28,324-lift)];
        [TGUtilityResponsiveView(self.responsiveLayout,@"linksTitle") setFrame:NSMakeRect(38,h-96,column-8,18)];
        [TGUtilityResponsiveView(self.responsiveLayout,@"requestsTitle") setFrame:NSMakeRect(rightX+4,h-96,column-8,18)];
        [[self.linksTableView enclosingScrollView] setFrame:NSMakeRect(34,h-184+lift,column,80-lift)];
        [self.linkNameField setFrame:NSMakeRect(34,h-216+lift,column,24)];
        CGFloat half=floor((column-8)/2);
        [self.expirationPopUpButton setFont:[NSFont systemFontOfSize:11]];
        CGFloat expiryWidth=MAX(96,ceil([[self.expirationPopUpButton cell] cellSize].width));
        [self.expirationPopUpButton setFrame:NSMakeRect(34,h-286+lift,expiryWidth,28)];
        [self.memberLimitField setFrame:NSMakeRect(34,h-248+lift,column,24)];
        CGFloat approvalWidth=MAX(TGUtilityResponsiveButtonWidth(self.joinRequestButton,24),ceil([[self.joinRequestButton cell] cellSize].width));
        CGFloat parameterGap=MAX(4,MIN(8,column-expiryWidth-approvalWidth));
        [self.joinRequestButton setFrame:NSMakeRect(34+expiryWidth+parameterGap,h-282+lift,column-expiryWidth-parameterGap,22)];
        NSArray *buttons=[NSArray arrayWithObjects:self.createLinkButton,self.copyLinkButton,self.revokeLinkButton,nil];
        for(NSUInteger i=0;i<3;i++)[[buttons objectAtIndex:i] setFrame:NSMakeRect(34+(i%2)*(half+8),h-318+lift-(i/2)*36,half,28)];
        [[self.requestsTableView enclosingScrollView] setFrame:NSMakeRect(rightX,h-318+lift,column,214-lift)];
        [self.declineButton setFrame:NSMakeRect(rightX,h-354+lift,half,30)];
        [self.approveButton setFrame:NSMakeRect(rightX+half+8,h-354+lift,column-half-8,30)];
        CGFloat eventsTop=cardBottom-16;
        [TGUtilityResponsiveView(self.responsiveLayout,@"eventsCard") setFrame:NSMakeRect(20,54,w-40,eventsTop-54)];
        [TGUtilityResponsiveView(self.responsiveLayout,@"eventsTitle") setFrame:NSMakeRect(38,eventsTop-32,w-76,18)];
        [[self.eventsTableView enclosingScrollView] setFrame:NSMakeRect(34,104,w-68,MAX(30,eventsTop-144))];
    }
    [self.statusField setFrame:NSMakeRect(24,24,w-72,18)];
    [self.spinner setFrame:NSMakeRect(w-42,24,16,16)];
    TGUtilitySizeResponsiveTable(self.linksTableView);TGUtilitySizeResponsiveTable(self.requestsTableView);TGUtilitySizeResponsiveTable(self.eventsTableView);
}
- (void)windowDidResize:(NSNotification *)notification {
    if([notification object]==[self window])[self layoutResponsiveViews];
}
