//
//  ODBCConnection.m
//  Convert from TrustWin
//
//  Created by Andy Satori on 6/27/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2005-2012, Druware Software Designs 
 All rights reserved. 
 
 Redistribution and use in source or binary forms, with or without modification,
 are permitted provided that the following conditions are met: 
 
 1. Redistributions in source or binary form must reproduce the above copyright 
 notice, this list of conditions and the following disclaimer in the 
 documentation and/or other materials provided with the distribution. 
 2. Neither the name of the Druware Software Designs nor the names of its 
 contributors may be used to endorse or promote products derived from this 
 software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 
 *******************************************************************************/

#import "ODBCConnection.h"

#import "sqltypes.h"
#import "sqlext.h"
#import "sql.h"

static ODBCConnection *globalConnection;

@implementation ODBCConnection

NSString *const GenDBConnectionDidCompleteNotification = @"GenDBConnectionDidCompleteNotification";
NSString *const GenDBCommandDidCompleteNotification = @"GenDBCommandDidCompleteNotification";

NSString *const ODBCConnectionDidCompleteNotification = @"ODBCConnectionDidCompleteNotification";
NSString *const ODBCCommandDidCompleteNotification = @"ODBCCommandDidCompleteNotification";

+(id)defaultConnection
{
	if (globalConnection == nil)
	{
		return nil;
	}
	
	return globalConnection;
}

-(id)init
{
    self = [super init];
    
    // start by calling initSQLEnvironment, which sets up the main data structure
    // for the ODBC driver machinery. only has to be done once, and there's
    // no setup "inside it" to carry out
    isEnvironmentValid = YES;
	if (![self initSQLEnvironment]) {
		NSLog(@"ODBC Environment Failed to initialize, ODBC functions will fail.");
		isEnvironmentValid = NO;
		return self;
	}
	
    // now set everything else to a fresh state
	isConnected	= NO;
	enableCursors = NO;
	
	defaultEncoding = NSISOLatin1StringEncoding;
	
	dsn = nil;
	userName = nil;
	password = nil;
	
	filter = nil;

	lastError = nil;
		
//	preparedStatements = [[NSMutableArray alloc] init];
//	[preparedStatements retain];
	
	if (globalConnection == nil)
	{
		globalConnection = self;
	}
	    
    return self;
}

- (ODBCConnection *)clone
{
    // start with some basic cloning code...
	ODBCConnection *newConnection = [[ODBCConnection alloc] init];
	[newConnection setDsn:dsn];
	[newConnection setUserName:userName];
	[newConnection setPassword:password];
	[newConnection setEnableCursors:enableCursors];
    [newConnection setDefaultEncoding:defaultEncoding];
	
    // but now we re-connect if the original Connection was connected
	if (isConnected)
	{
		[newConnection connect];
	}
	
	return newConnection;
}

-(void)dealloc
{
	[self freeSQLEnvironment];	
	
	if (dsn != nil)
	{
		dsn = nil;
	}

	if (userName != nil)
	{
		userName = nil;
	}

	if (password != nil)
	{
		password = nil;
	}

	if (filter != nil)
	{
		filter = nil;
	}	
	
	/*
	if (preparedStatements != nil)
	{
		int i;
		for (i = [preparedStatements count] - 1; i > 0; i--)
		{
			[preparedStatements removeObjectAtIndex:i];
		}
		[preparedStatements release];
		preparedStatements = nil;
	}*/
	
	
	if (lastError != nil)
	{
		lastError = nil;
	}
	
}

// basically all this does is call the one-shot code to set up the basic
// ODBC environment data structure. if it passes, we try setting the ODBC version
// to 2.x. it checks to see if that succeeded, and frees everything and returns
// FALSE if there was any error
-(BOOL)initSQLEnvironment
{
	henv = 0;
	RETCODE nResult;
	nResult = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
	if (!SQL_SUCCEEDED(nResult))
	{
		return NO;
	}
	
	nResult = SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC2, (long)NULL);
	if (!SQL_SUCCEEDED(nResult))
	{
		// free the env handle in the case of a failure here
		[self freeSQLEnvironment];
		return NO;
	}
	
	return YES;
}

-(BOOL)freeSQLEnvironment
{
	return (SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_ENV, henv)));
}

// alocates an ODBC statement structure
- (HSTMT)allocateStatement
{
	int nResult;
	HSTMT hstmt;
	
	nResult = SQLAllocStmt(hdbc, &hstmt);
	if (!SQL_SUCCEEDED(nResult))
	{
       	[self logError:nResult forStatement:(void *)SQL_NULL_HSTMT];
		return(NULL);
	}
	
	// make the defaults scrollable
	if (enableCursors) {
		usingDriverCursors = NO;
		nResult = SQLSetStmtAttr(hstmt, SQL_ATTR_CURSOR_SCROLLABLE, (SQLPOINTER)SQL_SCROLLABLE, (long)NULL);
		// fall back to psuedo cursors if not supported
		if (SQL_SUCCEEDED(nResult))
		{
			usingDriverCursors = YES;
		}
	} // this will fail with most currrent drivers.  internally, this will be 
	  // addressed using an internal array and load client memory instead of a 
	  // server side cursor.
	
	return hstmt;
}

// basic cover code to gather up the error information, format it, and spit it
// out onto the console, and then store it so other code can get at it
- (void)logError:(RETCODE)resultCode forStatement:(void *)stmt
{
	char	szBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	char	szDispBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
    
    NSMutableString *errorString = [[NSMutableString alloc] init];
	
	// formatted Error text Buffer
	unsigned long	iSize;					// Display Error Text size
	SQLRETURN	nErrResult;		// Return Code from SQLError
	BOOL bErrorFound = FALSE;
	
	szBuffer[0] = '\0';
	
	// continue to bring messageboxes till all errors are displayed.
	// more than one message box may be reqd. as err text has fixed
	// string size.
	
	// initialize display buffer with the string in error text buffer
	strcpy(szDispBuffer, szBuffer);
	
	// call SQLError function with proper ODBC handles, repeatedly until
	// function returns SQL_NO_DATA_FOUND. Concatenate all error strings
	// in the display buffer and display all results.
	UDWORD	dwErrCode;				// Native Error code
	do 
	{
		SWORD 	wErrMsgLen;				// Error message length

		SQLCHAR	szErrState[SQL_SQLSTATE_SIZE+1];	// SQL Error State string
		SQLCHAR	szErrText[SQL_MAX_MESSAGE_LENGTH+1];	// SQL Error Text string
        
        szErrText[0] = '\0';
        szErrState[0] = '\0';
		
		nErrResult = SQLError(henv, hdbc, stmt, szErrState,
							  (SQLINTEGER *)&dwErrCode, szErrText, 
							  SQL_MAX_MESSAGE_LENGTH-1, &wErrMsgLen);
		
		if (dwErrCode != 5701 && dwErrCode != 5703 && dwErrCode != 1805)
		{
			sprintf(szBuffer,
                    SQLERR_FORMAT,
                    (LPSTR)szErrState,
                    dwErrCode, 
					(LPSTR)szErrText);
			iSize = strlen(szDispBuffer);
			if (iSize && (iSize+strlen(szBuffer)+1) >= 1024)
				break;
			if (iSize)
            {
                strcat(szDispBuffer, "\n");
                [errorString appendString:@"\n"];
            }
            
            [errorString appendFormat:@"%s", szErrText];
            strcat(szDispBuffer, szBuffer);
			
            bErrorFound = TRUE;
		}
		
		if (stmt == NULL) {
			break;
		}
		
	} while ((nErrResult == SQL_SUCCESS || nErrResult == SQL_SUCCESS_WITH_INFO) && dwErrCode != SQL_NO_DATA_FOUND);
	
	if (bErrorFound == FALSE)
		return;
	
	if (lastError != nil)
	{
		lastError = nil;
	}
	
	lastError = [[NSString alloc] initWithFormat:@"%s", szDispBuffer];
	NSLog(@"%@",lastError);
}

// cover functions for the connect method below, which simply spools off
// the connect call into a separate thread
- (void)connectAsync
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performConnectThread) toTarget:self withObject:nil];		
}

- (void)performConnectThread
{
	// allocate the thread, begin the connection and send the notification when done
	@autoreleasepool {
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		
		if ([self connect]) {
			[info setValue:nil forKey:@"Error"];
		} else {
			[info setValue:[self lastError] forKey:@"Error"];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:ODBCConnectionDidCompleteNotification
															object:nil
														  userInfo:info];
	}
}

// main connect function, called both async and sync
- (BOOL)connect
{
    RETCODE nResult;
    
    // start by trying to create an ODBC connection handle and put it into hdbc
    NSLog(@"AllocHandle");
	nResult = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);                // Result code
	if (!SQL_SUCCEEDED(nResult)) {
		[self logError:nResult forStatement:(void *)SQL_NULL_HSTMT];
		return NO;
	}
	NSLog(@"SQLSetConnectOption");
	nResult = SQLSetConnectOption(hdbc, SQL_ODBC_CURSORS, SQL_CUR_USE_IF_NEEDED); 
	if (nResult != SQL_SUCCESS && nResult != SQL_SUCCESS_WITH_INFO) {
        [self logError:nResult forStatement:(void *)SQL_NULL_HSTMT];
        return NO;
    }
    
    // ok, this requires some explaination...
    //
    // ODBC clients generally allow you to connect using either a "connection string"
    // with the required key/value pairs in it, or to specify a DSN, which is
    // essentially a "connection string in the registry". Here in ODBCConnect,
    // we refer to both by a single NSString, "dsn". So, then, how does one
    // tell if we got a DSN or a connection string? Well, we look for the "="
    // that indicates the string is a key/value collection...
    	
	// if the DSN is a connection string, the username and password should not 
	// be included. identified by the DRIVER= keyword, use SQLDriverConnect() 
	// instead of the DSN specific SQLConnect()
    
    // FIXED: MSM 13-Jun-12: is this correct? The original comment said it was
    //                      looking for "DRIVER=" but the code below simply looks
    //                      for the "=" and sends in the whole string. I suspect
    //                      that's fine, but it's good to ask..
    //        Dru 14-May-19: yes, it is correct. if ANY = is present, the proper
    //                      usage is to use SQLDriverConnect().
	
	NSRange rangeOfDriver = [[dsn uppercaseString] rangeOfString:@"="];
	if (rangeOfDriver.location < [dsn length]) {
		char *szDSN = malloc(1024);
		SQLSMALLINT cbResultDSNLen;
		
        NSLog(@"DriverConnect");
		nResult = SQLDriverConnect(hdbc, NULL, (UCHAR *)[dsn cStringUsingEncoding:defaultEncoding], SQL_NTS,
								   (UCHAR *)szDSN, 1024, &cbResultDSNLen, SQL_DRIVER_NOPROMPT);
		free(szDSN);
	}
    // if we didn't find a "=" then we assume the string is the name of a DSN,
    // so we use the SQLConnect function to set things up
    else {
		
        NSLog(@"SQLConnect");
        nResult = SQLConnect(hdbc,(UCHAR *)[dsn cStringUsingEncoding:defaultEncoding], SQL_NTS,
						 (UCHAR *)[userName cStringUsingEncoding:defaultEncoding], SQL_NTS,
						 (UCHAR *)[password cStringUsingEncoding:defaultEncoding], SQL_NTS);
	}
	
	// if failed to connect, free the allocated hdbc before return	
	if (nResult != SQL_SUCCESS && nResult != SQL_SUCCESS_WITH_INFO) {
		[self logError:nResult forStatement:SQL_NULL_HSTMT];
		SQLFreeHandle(SQL_HANDLE_DBC, hdbc); 
		return NO;
	}
	
	// display any connection information if driver returns SQL_SUCCESS_WITH_INFO	
	if (nResult == SQL_SUCCESS_WITH_INFO) {
		[self logError:nResult forStatement:SQL_NULL_HSTMT];
	}
	
	isConnected = YES;
	return YES;	
}

- (BOOL)close
{
	if (isConnected)
	{
		SQLDisconnect(hdbc);
		// SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
		isConnected = NO;
	}
	return YES;
}

// returns a list of all ODBC drivers known to the driver manager
- (NSArray *)drivers
{
	NSMutableArray *driverList = [[NSMutableArray alloc] init];
	
	SQLSMALLINT iDescLen;
	char szDesc[SQL_MAX_DSN_LENGTH];
	SQLSMALLINT iAttrLen;
	char szAttr[SQL_MAX_DSN_LENGTH];
	iAttrLen = SQL_MAX_DSN_LENGTH;
	iDescLen = SQL_MAX_DSN_LENGTH;
	
	SQLINTEGER nResult = SQLDrivers(henv, SQL_FETCH_FIRST, (SQLCHAR *)&szDesc, iDescLen, &iDescLen,
										(SQLCHAR *)&szAttr, iAttrLen, &iAttrLen);
	while (!SQL_SUCCEEDED(nResult))
	{
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		NSString *name = [NSString stringWithCString:(char *)&szDesc encoding:defaultEncoding];
		[dict setValue:name forKey:@"description"];
        
        NSString *val =[NSString stringWithCString:(char *)&szAttr encoding:defaultEncoding];
		[dict setValue:val forKey:@"attributes"];
        
		[driverList addObject:dict];
	
		iAttrLen = SQL_MAX_DSN_LENGTH;
		iDescLen = SQL_MAX_DSN_LENGTH;
		nResult = SQLDrivers(henv, SQL_FETCH_NEXT, (SQLCHAR *)&szDesc, iDescLen, &iDescLen,
							 (SQLCHAR *)&szAttr, iAttrLen, &iAttrLen);
	}	
	
	return (NSArray *)driverList;
}

// returns a list of all the DSN's known to the driver manager
- (NSArray *)datasources
{
	NSMutableArray *datasourceList = [[NSMutableArray alloc] init];
	
	SQLSMALLINT iNameLen;
	char szName[SQL_MAX_DSN_LENGTH];
	SQLSMALLINT iDescLen;
	char szDesc[SQL_MAX_DSN_LENGTH];
	iNameLen = SQL_MAX_DSN_LENGTH;
	iDescLen = SQL_MAX_DSN_LENGTH;
	
	SQLINTEGER nResult = SQLDataSources(henv, SQL_FETCH_FIRST, (SQLCHAR *)&szName, iNameLen, &iNameLen,
										(SQLCHAR *)&szDesc, iDescLen, &iDescLen);
	while (SQL_SUCCEEDED(nResult))
	{
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		NSString *name = [NSString stringWithCString:(char *)&szName encoding:defaultEncoding];
		BOOL addItem = YES;
		if (filter != nil)
		{
			NSRange range = [name rangeOfString:filter];
			addItem = (range.location != NSNotFound);
		}

		if (addItem)
		{
			[dict setValue:name
					forKey:@"name"];
			[dict setValue:[NSString stringWithCString:(char *)&szDesc encoding:defaultEncoding] 
					forKey:@"description"];
			[datasourceList addObject:dict];
		}
		
		iNameLen = SQL_MAX_DSN_LENGTH;
		iDescLen = SQL_MAX_DSN_LENGTH;
		nResult = SQLDataSources(henv, SQL_FETCH_NEXT, (SQLCHAR *)&szName, iNameLen, &iNameLen,
								 (SQLCHAR *)&szDesc, iDescLen, &iDescLen);
	}	
	
	return (NSArray *)datasourceList;
}

// looks through the datasources list for the current DSN and returns its driver name 
- (NSString *)driver
{
	int i;
	NSArray *arr = [self datasources];
	for (i = 0; i < [arr count]; i++)
	{
		if ([dsn isEqualToString:[[arr objectAtIndex:i] valueForKey:@"name"]])
		{
			return [[arr objectAtIndex:i] valueForKey:@"description"];
		}
	}
	return nil;
}

// uses SQLGetConnectAttr to find the current catalog (database) name.
// this is a useful integrity check to use before querying results that
// require an active database - like 'tables' below
- (NSString *)database
{
    SQLINTEGER nResult;
    
    // test to see if we are connected
    if (!isConnected) { return nil; }
    
    // first we ask how long the longest catalog name could be
    // this is an optional call, so in a failure, just define it as 100
    SQLINTEGER iMaxLen = 100;
    nResult = SQLGetConnectAttr(hdbc, SQL_MAXIMUM_CATALOG_NAME_LENGTH, &iMaxLen, (SQLINTEGER)0, NULL);
    if (nResult != SQL_SUCCESS) {
        // we really don't care about the error here, but we log it for debug
        // of connection behaviors.
        [self logError:nResult forStatement:SQL_NULL_HSTMT];
    }
    
    // call the ODBC manager to get the catalog
    SQLCHAR szName[iMaxLen];
    SQLSMALLINT iNameLen;
    nResult = SQLGetInfo(hdbc, SQL_DATABASE_NAME, &szName, iMaxLen, &iNameLen);
    if (nResult != SQL_SUCCESS) {
        [self logError:nResult forStatement:SQL_NULL_HSTMT];
    }
    
    // the name might come back as the literal string "null"
    NSString *cat = [NSString stringWithCString:(char *)&szName encoding:[self defaultEncoding]];
    if (cat != nil && [cat length] > 0 && ![cat isEqualToString:@"null"]) {
        return cat;
    } else {
        return nil;
    }
}

// uses SQLGetConnectAttr to see if the current catalog is read-only.
// don't cache this, because it could change at any time
- (BOOL)readOnly
{
	SQLINTEGER iMode;
    SQLINTEGER nResult;
    
    // test to see if we are connected, if not, consider it read only :-)
    if (!isConnected) { return YES; }
    
    // call the ODBC manager to get the catalog
    nResult = SQLGetConnectAttr(hdbc, SQL_ATTR_ACCESS_MODE, &iMode, 0, NULL);
    if (nResult != SQL_SUCCESS)
    {
        [self logError:nResult forStatement:SQL_NULL_HSTMT];
    }
    
    // returns an integer that, according to MS, should be SQL_MODE_READ_ONLY,
    // but sql.h contains the apparently similar SQL_DATA_SOURCE_READ_ONLY
    if (iMode == SQL_DATA_SOURCE_READ_ONLY) {
        return YES;
    } else {
        return NO;
    }
}

// returns a list of tables within a given database
- (ODBCRecordset *)tables
{
	SQLINTEGER cbRowArraySize = 1;
    SQLINTEGER nResult;

	HSTMT   hstmt;	
	hstmt = (HSTMT)([self allocateStatement]);
    
    // test to see if we are connected
    if (!isConnected) { return nil; }
    
    // and if there's an active catalog to query
    if ([self database] == nil) { return nil; }
    
	// ok, get the list of tables
    nResult = SQLTables(hstmt, NULL, 0, NULL, 0, NULL, 0, NULL, 0);
	if (nResult != SQL_SUCCESS) {
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO) {
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}			
	
    // !!!PROBLEM
    // dru 06/20/2012 - it appears that alterations made to address MySQL, 
    //                  SQLLite and Firebird make this unhappy on MSSQL and 
    //                  Oracle ( using ActualTech drivers ).  This will need 
    //                  resolution before the next release.
    //                  
    //                  at issue is the version implementation.  *if* the driver
    //                  is not fully V3.0 compliant, this call will fail.  It is
    //                  not needed by V2.5 or lower drivers, so we can safely 
    //                  ignore the success of failure of the call on non-v3.0+
    //                  drivers.
    
    // testing replacement of SQL_ATTR_ROW_ARRAY_SIZE with SQL_ROWSET_SIZE
    // fixing pointer assignment
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, cbRowArraySize, NULL);
    if (!SQL_SUCCEEDED(nResult)) {
		[self logError:nResult forStatement:hstmt];
		// return (nil);
	}
    
	return [[ODBCRecordset alloc] initWithConnection:henv
                                          forDatabase:hdbc
                                        withStatement:hstmt
                                        enableCursors:enableCursors
                                        usingEncoding:defaultEncoding];
}

// returns a list of columns within a named table
- (ODBCRecordset *)tableColumns:(NSString*)tableName;
{
	HSTMT   hstmt;
	SQLINTEGER cbRowArraySize = 1;
	
    // test to see if we are connected
    if (!isConnected) { return nil; }

    // and if there's an active catalog to query
    if ([self database] == nil) { return nil; }

	hstmt = (HSTMT)([self allocateStatement]);
	
	SQLCHAR * szTableName = (SQLCHAR *)[tableName cStringUsingEncoding:defaultEncoding];
    
	SQLINTEGER nResult = SQLColumns(hstmt, nil, 0, nil, 0, szTableName, strlen((char *)szTableName), nil, 0);
	if (nResult != SQL_SUCCESS)
	{
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}			
	
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, (SQLINTEGER)cbRowArraySize, (SQLINTEGER)NULL);
	if (!SQL_SUCCEEDED(nResult))
	{
		[self logError:nResult forStatement:hstmt];
		return (nil);
	}	
	
	return [[ODBCRecordset alloc] initWithConnection:henv
                                          forDatabase:hdbc
                                        withStatement:hstmt
                                        enableCursors:YES
                                        usingEncoding:defaultEncoding];
}

- (ODBCRecordset *)tablePrimaryKeys:(NSString*)tableName;
{
	HSTMT   hstmt;
	SQLINTEGER cbRowArraySize = 1;
	
    // test to see if we are connected
    if (!isConnected) { return nil; }
    
    // and if there's an active catalog to query
    if ([self database] == nil) { return nil; }

	hstmt = (HSTMT)([self allocateStatement]);
	
	SQLCHAR * szTableName = (SQLCHAR *)[tableName cStringUsingEncoding:defaultEncoding];
	SQLINTEGER nResult = SQLPrimaryKeys(hstmt, nil, 0, nil, 0, szTableName, strlen((char *)szTableName));
	
	if (nResult != SQL_SUCCESS)
	{
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}			
	
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, (SQLINTEGER)cbRowArraySize, (SQLINTEGER)NULL);
	if (!SQL_SUCCEEDED(nResult))
	{
		[self logError:nResult forStatement:hstmt];
		return (nil);
	}	
	
	return [[ODBCRecordset alloc] initWithConnection:henv
                                          forDatabase:hdbc
                                        withStatement:hstmt
                                        enableCursors:enableCursors
                                        usingEncoding:defaultEncoding];

}

- (ODBCRecordset *)tableForeignKeys:(NSString*)tableName;
{
	HSTMT   hstmt;
	SQLINTEGER cbRowArraySize = 1;
	
    // test to see if we are connected
    if (!isConnected) { return nil; }
    
    // and if there's an active catalog to query
    if ([self database] == nil) { return nil; }
    
	hstmt = (HSTMT)([self allocateStatement]);
	
	SQLCHAR * szTableName = (SQLCHAR *)[tableName cStringUsingEncoding:defaultEncoding];
    
	SQLINTEGER nResult = SQLForeignKeys(hstmt, nil, 0, nil, 0, nil, 0, nil, 0, nil, 0, szTableName, strlen((char *)szTableName));
	if (nResult != SQL_SUCCESS)
	{
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}			
	
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, (SQLINTEGER)cbRowArraySize, (SQLINTEGER)NULL);
	if (!SQL_SUCCEEDED(nResult))
	{
		[self logError:nResult forStatement:hstmt];
		return (nil);
	}	
	
	return [[ODBCRecordset alloc] initWithConnection:henv
                                          forDatabase:hdbc
                                        withStatement:hstmt
                                        enableCursors:enableCursors
                                        usingEncoding:defaultEncoding];
}

- (ODBCRecordset *)tableIndexes:(NSString*)tableName;
{
	HSTMT   hstmt;
	SQLINTEGER cbRowArraySize = 1;
	
    // test to see if we are connected
    if (!isConnected) { return nil; }
    
    // and if there's an active catalog to query
    if ([self database] == nil) { return nil; }

	hstmt = (HSTMT)([self allocateStatement]);

	SQLCHAR * szTableName = (SQLCHAR *)[tableName cStringUsingEncoding:defaultEncoding];
	SQLINTEGER nResult = SQLStatistics(hstmt, nil, 0, nil, 0, szTableName, strlen((char *)szTableName), SQL_INDEX_ALL, SQL_QUICK);
	if (nResult != SQL_SUCCESS)
	{
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}			
	
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, (SQLINTEGER)cbRowArraySize, (SQLINTEGER)NULL);
	if (!SQL_SUCCEEDED(nResult))
	{
		[self logError:nResult forStatement:hstmt];
		return (nil);
	}	
	
	return [[ODBCRecordset alloc] initWithConnection:henv
                                          forDatabase:hdbc
                                        withStatement:hstmt
                                        enableCursors:enableCursors
                                        usingEncoding:defaultEncoding];
}

- (ODBCRecordset *)getTypeInfo:(SQLSMALLINT)dataType;
{
	HSTMT   hstmt;
	SQLINTEGER cbRowArraySize = 1;
	
    // test to see if we are connected
    if (!isConnected) { return nil; }
    
    // and if there's an active catalog to query
    if ([self database] == nil) { return nil; }

	hstmt = (HSTMT)([self allocateStatement]);
	
	SQLINTEGER nResult = SQLGetTypeInfo(hstmt, dataType);
	if (nResult != SQL_SUCCESS)
	{
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}			
	
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, (SQLINTEGER)cbRowArraySize, (SQLINTEGER)NULL);
	if (!SQL_SUCCEEDED(nResult))
	{
		[self logError:nResult forStatement:hstmt];
		return (nil);
	}	
	
	return [[ODBCRecordset alloc] initWithConnection:henv
                                          forDatabase:hdbc
                                        withStatement:hstmt
                                        enableCursors:enableCursors
                                        usingEncoding:defaultEncoding];
}

- (void)execCommandAsync:(NSString *)sql
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performExecCommand:) toTarget:self withObject:sql];		
}

- (void)performExecCommand:(id)sqlCommand
{
	@autoreleasepool {
	
		NSString *sql = (NSString *)sqlCommand;
		
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		
		long recordCount = [self execCommand:sql];
		[info setValue:[NSNumber numberWithLong:recordCount] forKey:@"RecordCount"];
		[info setValue:[self lastError] forKey:@"Error"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ODBCCommandDidCompleteNotification
															object:nil
														  userInfo:info];
	}
}

- (long)execCommand:(NSString *)sql
{
	HSTMT   hstmt;
	int nResult;
	long lRowCount;
	
	if (lastError != nil) {
		lastError = nil;
	}
	
	hstmt = (HSTMT)([self allocateStatement]);
	
	UCHAR *sqlString = (UCHAR *)[sql cStringUsingEncoding:defaultEncoding];
	nResult = SQLExecDirect(hstmt, sqlString, (SQLINTEGER)strlen((char *)sqlString));
	if (nResult != SQL_SUCCESS)
	{
		[self logError:nResult forStatement:hstmt];
       	if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return -1;
		}
	}
	lRowCount = -1;
	SQLRowCount(hstmt, &lRowCount);
	SQLFreeStmt(hstmt, SQL_CLOSE);
	
	return lRowCount;
}

- (void)openAsync:(NSString *)sql
{
	// perform the connection on a thread
	[NSThread detachNewThreadSelector:@selector(performOpen:) toTarget:self withObject:sql];		
}

- (void)performOpen:(id)sqlCommand
{
	@autoreleasepool {
	
		NSString *sql = (NSString *)sqlCommand;
		
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		
		ODBCRecordset *rs = [self open:sql];
		[info setValue:rs forKey:@"RecordSet"];
		[info setValue:[self lastError] forKey:@"Error"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ODBCCommandDidCompleteNotification
															object:nil
														  userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:GenDBCommandDidCompleteNotification
															object:nil
														  userInfo:info];
	}
}

// FIXED: MSM 15-Jun-12: this method is used to open a statement session with
//         the driver, which is normally part of a query process. the name is a
//         little confusing, because it appears to imply it's "opening a
//         connection" when its actually "run a query".
//        DRU 17-Jul-12: this is a legacy of the origin and intended audience.
//         both the JDBC and the various OO Layers on ODBC in the Windows world
//         adopted the Open/ExecCommand naming.  For familiarity to developers
//         coming from that background, this naming was retained.
- (ODBCRecordset *)open:(NSString *)sql
{
	int nResult;

	SQLINTEGER cbRowArraySize = 1;
	
    // clean up lastError if there is one
	if (lastError != nil) {
		lastError = nil;
	}
	
    // build a new ODBC statement structure
	HSTMT   hstmt;
	hstmt = (HSTMT)([self allocateStatement]);
	
    // now run the query and log any errors. this has the side effect of
    // setting all sorts of flags and metadata in the hstmt structure,
    // which we use in other code to examine the results
    
    // can the sql be converted to the correct encoding ?
    UCHAR *szSqlString;
    if (![sql canBeConvertedToEncoding:defaultEncoding])
    {
        NSLog(@"Nope, no can do boss");
        
        // so we cannot do this conversion now.  guess we need to figure out why
        szSqlString = (UCHAR *)[sql cStringUsingEncoding:NSASCIIStringEncoding];

    } else {
        szSqlString = (UCHAR *)[sql cStringUsingEncoding:defaultEncoding];
    }
    if (strlen((char *)szSqlString) == 0)
    {
        [self logError:SQL_SUCCESS_WITH_INFO forStatement:nil];
        return nil;
    }
    
	nResult = SQLExecDirect(hstmt, szSqlString, strlen((char *)szSqlString));
	if (nResult != SQL_SUCCESS) {
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO) {
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return nil;
		}
	}

    // tell the statement to return rows one at a time
    // FIXED: MSM 15-Jun-12: this formerly failed to set nResult, but that might
    //        have been deliberate as the test above might pass through to this point
    // FIXED: MSM 18-Jun-12: changed this call on the advice of the SQLite ODBC
    //        author... appears to fix a problem in that DB anyway.
    nResult = SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, (SQLINTEGER)cbRowArraySize, (SQLINTEGER)NULL);
	if ((nResult != SQL_SUCCESS) && (nResult != SQL_SUCCESS_WITH_INFO)) {
       	[self logError:nResult forStatement:hstmt];
		return nil;
	}
	
    // initialize the ODBCRecordset with the results of the query
	ODBCRecordset *rs = [[ODBCRecordset alloc] initWithConnection:henv
                                                       forDatabase:hdbc
                                                     withStatement:hstmt
                                                     enableCursors:enableCursors
                                                     usingEncoding:defaultEncoding];
	
	// if cursors are enabled, use SQLMoreResults() until we have ALL of the 
	// the results (stored in an array of ODBCRecordSets()).
    // if cursors are not enabled, only fetch, only retain the last recordset.
    
	
	return rs;
}

/*- (ODBCPreparedStatement *)preparedStatement
{
	ODBCPreparedStatement *result;
	result = [[ODBCPreparedStatement alloc] initWithConnection:henv forDatabase:hdbc];
	[[result retain] autorelease];
	
	[preparedStatements addObject:result];
	
	return result;
}*/


- (BOOL)isEnvironmentValid {
	return isEnvironmentValid;
}

- (BOOL)isConnected {
	return isConnected;
}

- (NSString *)connectionString {
    return dsn;
}
- (void)setConnectionString:(NSString *)value {
    if (dsn != value) {
        dsn = [value copy];
    }
}
- (NSString *)dsn {
    return dsn;
}
- (void)setDsn:(NSString *)value {
    if (dsn != value) {
        dsn = [value copy];
    }
}

- (NSString *)userName {
    return userName;
}
- (void)setUserName:(NSString *)value {
    if (userName != value) {
        userName = [value copy];
    }
}

- (NSString *)password {
    return password;
}
- (void)setPassword:(NSString *)value {
    if (password != value) {
        password = [value copy];
    }
}

- (NSString *)datasourceFilter
{
    return filter;
}
- (void)setDatasourceFilter:(NSString *)value
{    
	if (filter != value) {
        filter = [value copy];
    }
}

- (BOOL)enableCursors
{
	return enableCursors;
}
- (void)setEnableCursors:(BOOL)value
{
	enableCursors = value;
}

- (NSStringEncoding)defaultEncoding
{
	return defaultEncoding;
}
- (void)setDefaultEncoding:(NSStringEncoding)value
{
    if (defaultEncoding != value) {
        defaultEncoding = value;
    }	
}

- (NSString *)lastError {
    return lastError;
}

@end
