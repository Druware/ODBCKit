//
//  SchemaDataSource.m
//  ODBCQueryTool
//
//  Created by Andy Satori on 11/14/08.
//  Copyright 2008 Satori & Associates, Inc.. All rights reserved.
//

#import "SchemaDataSource.h"

@implementation SchemaDataSource

- (id)initWithConnection:(ODBCConnection *)connection
{
    if (!(self = [super init])) return nil;
    
    if (self != nil)
	{
		conn = connection;
		tableNames = nil;
		
		// should do the load on a thread, but for now....
		[self refreshSchemaData:nil];
	}
    
    return self;
}


- (SchemaElement *)rootNode
{
	return rootNode;
}

- (NSArray *)tableNames
{
	return tableNames;
}

- (void)refreshSchemaData:(id)sender
{
	// if the connection is invalid, get out
	if (conn == nil) { return ; }
	if (![conn isConnected]) { return; }
    
    // make sure we are connected to a database that has tables
    if ([conn database] == nil) { return; }
    if ([[conn database] length] == 0) { return; }
    
    // FIXME: MSM 18-Jun-12: is this needed? it seemed like a good idea
    if (rootNode != nil) {
        rootNode = nil;
    }
    
    // start building the basic structure
	rootNode = [[SchemaElement alloc] init];
	[rootNode setName:@"Root"];
	[rootNode setElementType:0];
	
	// clean up the current tableNames array if it exists
	if (tableNames != nil) {
        tableNames = nil;
	}
    
    // and set up the names
    tableNames = [[NSMutableArray alloc] init];
		
	// add the tables ----------------------------------------------------------
	SchemaElement *se = [[SchemaElement alloc] init];
	[se setName:@"Tables"];
	[se setElementType:1];
	[[rootNode children] addObject:se];
	
	ODBCRecordset *rsTables = [conn tables];
	while (![rsTables isEOF]) {	
        NSDictionary *tableDict = [rsTables dictionaryFromRecord];
        
        // depending on the driver, the table name may be an NSString or NSData...
        NSString *tableName;
        id nameAsData = [tableDict valueForKey:@"table_name"];
        if ([nameAsData isKindOfClass:[NSString class]]) {
            tableName = (NSString *)nameAsData;
        } else {
            tableName = [NSString stringWithCString:[nameAsData bytes] encoding:[conn defaultEncoding]];
        }
        
        // save it out
		[tableNames addObject:tableName];

        // put that into a schema element, which needs a mutable copy
        NSMutableDictionary *mc = [[NSMutableDictionary alloc] initWithDictionary:tableDict];
		SchemaElement *seTable = [[SchemaElement alloc] init];
		[seTable setName:tableName];
        [seTable setElementType:2];
		[seTable setProperties:mc];
		[[se children] addObject:seTable];
		
		[rsTables moveNext];
	}
	[rsTables close];
	
	// for each table in the array, now populate the columns. (table_name)
/*	int i;
	for (i = 0; i < [allTables count]; i++)
	{
		NSMutableArray *columnList = [[NSMutableArray alloc] init];
		NSMutableDictionary *dictForTable = [allTables objectAtIndex:i];
		[dictForTable setValue:[dictForTable valueForKey:@"table_name"] forKey:@"name"];
		
//		ODBCRecordset *recordsetOfColumns = [conn tableColumns:[dictForTable valueForKey:@"table_name"]];
//		while (![recordsetOfColumns isEOF])
//		{
//			NSDictionary *dictForColumn = [recordsetOfColumns dictionaryFromRecord];
//			[columnList addObject:dictForColumn];
//			[recordsetOfColumns moveNext];
//		}
//		[recordsetOfColumns close];
		
		[dictForTable setObject:columnList forKey:@"children"];
	}
	
	[rootSchema addObject:tablesNode]; // add the tables node to the tree
*/

}

@end
