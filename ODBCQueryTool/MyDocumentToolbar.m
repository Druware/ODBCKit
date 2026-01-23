//
//  MyDocumentToolbar.m
//  ODBCQueryTool
//
//  Created by Andy Satori on 9/12/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import "MyDocumentToolbar.h"

@implementation MyDocument (MyDocumentToolbar)

- (void)setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"sqlToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [documentWindow setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:@"Connect"] ) {
        [item setLabel:@"Connect"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"connect_32"]];
        [item setTarget:self];
        [item setAction:@selector(onConnect:)];
    }
	
    if ( [itemIdentifier isEqualToString:@"Disconnect"] ) {
        [item setLabel:@"Disconnect"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"disconnect_32"]];
        [item setTarget:self];
        [item setAction:@selector(onDisconnect:)];
    }
	
    if ( [itemIdentifier isEqualToString:@"Execute"] ) {
        [item setLabel:@"Execute"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"run_script_32"]];
        [item setTarget:self];
        [item setAction:@selector(onExecuteQuery:)];
    }
		
	return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Connect", @"Execute",
		@"SelectDB",
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        @"Connect", @"Execute", @"SelectDB",
        NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	// onConnect
    if ( [theItem action] == @selector(onConnect:) )
	{
		if (conn == nil) 
		{
			[theItem setLabel:@"Connect"];
			[theItem setImage:[NSImage imageNamed:@"connect_32"]];	
		}
		
		if ([conn isConnected]) {
			// disconnect        
			[theItem setLabel:@"Disconnect"];
			[theItem setImage:[NSImage imageNamed:@"disconnect_32"]];			
		} else {
			// connect
			[theItem setLabel:@"Connect"];
			[theItem setImage:[NSImage imageNamed:@"connect_32"]];	
		}
        
		return YES;
	}

	
    if ( [theItem action] == @selector(onExecuteQuery:) )
	{
        return ([conn isConnected]);
	}	

		
	return YES;
}

@end
