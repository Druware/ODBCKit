//
//  SchemaDataSource.h
//  ODBCQueryTool
//
//  Created by Andy Satori on 11/14/08.
//  Copyright 2008 Satori & Associates, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ODBCConnection.h"
#import "SchemaElement.h"

@interface SchemaDataSource : NSObject <NSOutlineViewDataSource> {
	ODBCConnection			*conn;
	
	SchemaElement			*rootNode;
	NSMutableArray			*tableNames;
}

- (id)initWithConnection:(ODBCConnection *)connection;
- (void)refreshSchemaData:(id)sender;

- (SchemaElement *)rootNode;
- (NSArray *)tableNames;


@end
