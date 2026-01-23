//
//  ODBCQueryAction.m
//  ODBCQueryAction
//
//  Created by Andy Satori on 9/14/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import "ODBCQueryAction.h"


@implementation ODBCQueryAction

- (id)initWithDefinition:(NSDictionary *)dict fromArchive:(BOOL)archived
{
	self = [super initWithDefinition:dict fromArchive:archived];
    NSLog(@"Got Init");
	if (self != nil)
	{
		ODBCConnection *odbcConnection = [[ODBCConnection alloc] init];
		[[self parameters] setObject:[odbcConnection datasources] forKey:@"dataSourceList"];
		odbcConnection = nil;
	}
	
	return self;
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	// Add your code here, returning the data to be passed to the next action.
	NSMutableDictionary *dict = [self parameters];
	
	NSString *user = [dict valueForKey:@"userName"];
	NSString *dsn = [dict valueForKey:@"dataSource"];
	NSString *query = [dict valueForKey:@"query"];
	NSString *password = [dict valueForKey:@"password"];
	
    ODBCConnection *odbcConnection = [[ODBCConnection alloc] init];
	[odbcConnection setDsn:dsn];
	[odbcConnection setUserName:user];
	[odbcConnection setPassword:password];
	if ([odbcConnection connect])
	{
		ODBCRecordset *rs = [odbcConnection open:query];
		
		NSMutableArray *result = [[NSMutableArray alloc] init];
		while (![rs isEOF])
		{
			[result addObject:[rs dictionaryFromRecord]];
			[rs moveNext];
		}
		[rs close];
		[odbcConnection close];
        odbcConnection = nil;
        
		return result;		
	} else {
		// setup the error dictionary 
	}

    odbcConnection = nil;
	
    return nil;
}

@end
