//
//  MyDocumentToolbar.h
//  ODBCQueryTool
//
//  Created by Andy Satori on 9/12/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface MyDocument (MyDocumentToolbar)

-(void)setupToolbar;
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag;

@end
