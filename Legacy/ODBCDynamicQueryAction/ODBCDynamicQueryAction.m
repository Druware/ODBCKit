//
//  ODBCDynamicQueryAction.m
//  ODBCDynamicQueryAction
//
//  Created by Andy Satori on 12/26/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import "ODBCDynamicQueryAction.h"


@implementation ODBCDynamicQueryAction

- (id)initWithDefinition:(NSDictionary *)dict fromArchive:(BOOL)archived
{
	self = [super initWithDefinition:dict fromArchive:archived];
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
	NSString *password = [dict valueForKey:@"password"];
	
	ODBCConnection *odbcConnection = [[ODBCConnection alloc] init];
	[odbcConnection setDsn:dsn];
	[odbcConnection setUserName:user];
	[odbcConnection setPassword:password];
	
	NSMutableArray *result = [[NSMutableArray alloc] init];
	
	if ([odbcConnection connect])
	{
        // input is an array of strings, we assume single item
        // but may wish to loop through them
        
        
		NSString *query = [NSString stringWithString:[input objectAtIndex:0]];
		ODBCRecordset *rs = [odbcConnection open:query];
		
        if (rs)
        {
            while (![rs isEOF])
            {
                [result addObject:[rs dictionaryFromRecord]];
                [rs moveNext];
            }
            [rs close];
        }
	
	} else {
		// setup the error dictionary 
		return nil;
	}

	[odbcConnection close];
	odbcConnection = nil;
	
	return result;
}

@end
