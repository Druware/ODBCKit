//
//  MyDocumentMenu.m
//  ODBCQueryTool
//
//  Created by Andy Satori on 9/12/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import "MyDocumentMenu.h"

@implementation MyDocument (MyDocumentMenu)


- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	// onExecuteQuery
    if ( [theItem action] == @selector(onExecuteQuery:) )
	{
        return ([conn isConnected]);
	}
	
	// onConnect
    if ( [theItem action] == @selector(onConnect:) )
	{
        return (![conn isConnected]);
	}
	
	// onDisconnect
    if ( [theItem action] == @selector(onDisconnect:) )
	{
        return ([conn isConnected]);
	}
	
	return YES;
}

@end
