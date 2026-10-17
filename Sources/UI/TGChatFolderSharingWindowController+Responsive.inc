- (void)layoutResponsiveViews {
    if(!self.responsiveLayout)return;
    NSSize size=TGUtilityRestoreResponsiveLayout(self.responsiveLayout);CGFloat w=size.width,h=size.height;
    CGFloat left=338+(w-760)/2,rightX=388+(w-760)/2,right=w-28-rightX;
    NSArray *buttons=[NSArray arrayWithObjects:self.linkCopyButton,self.createButton,self.renameButton,self.deleteButton,nil];
    CGFloat actionWidth=24;for(NSButton *button in buttons)actionWidth+=TGUtilityResponsiveButtonWidth(button,24);
    BOOL compact=actionWidth>left;
    CGFloat bottom=compact?266:230,tableHeight=MAX(64,h-110-bottom);
    [[self.linkTableView enclosingScrollView] setFrame:NSMakeRect(28,bottom,left,tableHeight)];
    [[self.recommendedTableView enclosingScrollView] setFrame:NSMakeRect(rightX,bottom,right,tableHeight)];
    [TGUtilityResponsiveView(self.responsiveLayout,@"linksLabel") setFrame:NSMakeRect(30,h-106,left-4,18)];
    [TGUtilityResponsiveView(self.responsiveLayout,@"recommendedLabel") setFrame:NSMakeRect(rightX+2,h-106,right-4,18)];
    [TGUtilityResponsiveView(self.responsiveLayout,@"title") setFrame:NSMakeRect(24,h-40,w-148,26)];
    [TGUtilityResponsiveView(self.responsiveLayout,@"subtitle") setFrame:NSMakeRect(24,h-60,w-148,17)];
    if(compact){CGFloat bw=floor((left-8)/2);for(NSUInteger i=0;i<4;i++)[[buttons objectAtIndex:i] setFrame:NSMakeRect(28+(i%2)*(bw+8),230-(i/2)*36,bw,28)];}
    else {CGFloat x=28;for(NSButton *button in buttons){CGFloat bw=TGUtilityResponsiveButtonWidth(button,24);[button setFrame:NSMakeRect(x,194,bw,28)];x+=bw+8;}}
    CGFloat addWidth=MIN(right,MAX(122,[[self.addRecommendedButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:13] forKey:NSFontAttributeName]].width+24));
    [self.addRecommendedButton setFrame:NSMakeRect(w-28-addWidth,194,addWidth,28)];
    CGFloat dismissWidth=MAX(120,TGUtilityResponsiveButtonWidth(self.dismissNewChatsButton,24));
    CGFloat newWidth=MAX(116,TGUtilityResponsiveButtonWidth(self.addNewChatsButton,24));
    CGFloat actionsX=w-28-dismissWidth-8-newWidth;
    [self.addNewChatsButton setFrame:NSMakeRect(actionsX,146,newWidth,28)];
    [self.dismissNewChatsButton setFrame:NSMakeRect(w-28-dismissWidth,146,dismissWidth,28)];
    [self.pendingChatsField setFrame:NSMakeRect(28,152,actionsX-40,18)];
    [self.pendingChatsField setToolTip:[self.pendingChatsField stringValue]];
    [self.limitsField setFrame:NSMakeRect(28,112,w-56,32)];
    [self.statusField setFrame:NSMakeRect(28,70,w-104,20)];
    [self.spinner setFrame:NSMakeRect(w-66,72,16,16)];
    TGUtilitySizeResponsiveTable(self.linkTableView);TGUtilitySizeResponsiveTable(self.recommendedTableView);
}
- (void)windowDidResize:(NSNotification *)notification {
    if([notification object]==[self window])[self layoutResponsiveViews];
}
