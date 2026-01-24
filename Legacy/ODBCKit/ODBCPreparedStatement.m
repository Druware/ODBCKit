//
//  ODBCCommand.m
//  ODBCKit
//
//  Created by Andy Satori on 9/15/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2005-2009, Druware Software Designs 
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
 
 ******************************************************************************/

#import "ODBCPreparedStatement.h"


/* Executing a Prepared Statement

    1. SQLPrepare()
    2. SQLNumParams() // not required
    3. SQLDescribeParam() // not required
    4. SQLBindParam() // 
    5. pop data into bound parameter buffer
    6. SQLExecute()
    7. Repeate 5 and 6.
 
    or http://msdn.microsoft.com/en-us/library/aa215454(SQL.80).aspx
	for SQLBindParameter() docs and examples: 
		http://msdn.microsoft.com/en-us/library/ms710963(VS.85).aspx
 */

@implementation ODBCPreparedStatement

- (void)logError:(RETCODE)result forStatement:(void *)stmt
{
	UCHAR	szErrState[SQL_SQLSTATE_SIZE+1];	// SQL Error State string
	UCHAR	szErrText[SQL_MAX_MESSAGE_LENGTH+1];	// SQL Error Text string
	char	szBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	char	szDispBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	
	// formatted Error text Buffer
	SWORD 	wErrMsgLen;				// Error message length
	UDWORD	dwErrCode;				// Native Error code
	int	iSize;					// Display Error Text size
	SQLRETURN	nErrResult;				// Return Code from SQLError
// 	int	fFirstRun;				// If it was first msg box
	BOOL bErrorFound = FALSE;
	
	// fFirstRun = TRUE;
	szBuffer[0] = '\0';
	
	// continue to bring messageboxes till all errors are displayed.
	// more than one message box may be reqd. as err text has fixed
	// string size.
	
	// initialize display buffer with the string in error text buffer
	
	strcpy(szDispBuffer, szBuffer);
	
	// call SQLError function with proper ODBC handles, repeatedly until
	// function returns SQL_NO_DATA_FOUND. Concatenate all error strings
	// in the display buffer and display all results.
	
	nErrResult = SQLError(odbcConn, odbcDbc, stmt, szErrState, 
						  (SQLINTEGER *)&dwErrCode, szErrText, SQL_MAX_MESSAGE_LENGTH-1, 
						  &wErrMsgLen);
	while ((nErrResult == SQL_SUCCESS || nErrResult == SQL_SUCCESS_WITH_INFO) && dwErrCode != SQL_NO_DATA_FOUND)
	{
		if (dwErrCode != 5701 && dwErrCode != 5703 && dwErrCode != 1805)
		{
			sprintf(szBuffer, SQLERR_FORMAT, (LPSTR)szErrState, dwErrCode, 
					(LPSTR)szErrText);
			iSize = strlen(szDispBuffer);
			if (iSize && (iSize+strlen(szBuffer)+1) >= 1024)
				break;
			if (iSize)
				strcat(szDispBuffer, "\n");
			strcat(szDispBuffer, szBuffer);
			bErrorFound = TRUE;
		}
		
		nErrResult = SQLError(odbcConn, odbcDbc, stmt, szErrState, 
							  (SQLINTEGER *)&dwErrCode, szErrText, SQL_MAX_MESSAGE_LENGTH-1, 
							  &wErrMsgLen);
	}
	if (bErrorFound == FALSE)
		return;
	NSLog(@"%s", szDispBuffer);
}

#pragma mark -
#pragma mark Constructor / Destructor

-(id)initWithConnection:(void *)henv forDatabase:(void *)hdbc;
{
    self = [super init];
	if (self)
	{
		odbcConn = henv;
		odbcDbc = hdbc;
		odbcStmt = nil;	
		
        // FIXME: MSM 19-Jul-12: change this when this code is re-activated
		defaultEncoding = NSLatin1StringEncoding;
		
		isPrepared = NO;
	}
	return self;
}	

#pragma mark -
#pragma mark Private Methods

- (id)allocateStatement 
{
	int nResult;
	HSTMT hstmt;
	
	nResult = SQLAllocStmt(odbcDbc, &hstmt);
	if (!SQL_SUCCEEDED(nResult))
	{
       	[self logError:nResult forStatement:SQL_NULL_HSTMT];
		return(NULL);
	}
	
	// make the defaults scrollable
	if (enableCursors) {
		usingDriverCursors = NO;
		nResult = SQLSetStmtAttr(odbcStmt, SQL_ATTR_CURSOR_SCROLLABLE , (SQLPOINTER)SQL_SCROLLABLE, (long)NULL);
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

#pragma mark -
#pragma mark Public Methods

-(BOOL)prepare
{
	// if a statement handle already exists, return NO and exit, as we do not
	// want re-prepare a prepared statement.
	if (isPrepared)
	{
		if (lastError == nil)
		{
			lastError = [[[NSString alloc] initWithString:@"Cannot prepare a statement twice"] autorelease];
			return NO;
		}
	}
	
	odbcStmt = [self allocateStatement];
	
	// cannot prepare and empty statement
	if (sql == nil) return NO; 
	if ([sql length] <= 0) return NO;
	
	// SQLPrepare()
	long nResult;
	nResult = SQLPrepare(odbcStmt, (SQLCHAR *)[sql cStringUsingEncoding:defaultEncoding], strlen([sql cStringUsingEncoding:defaultEncoding]));
	if (!SQL_SUCCEEDED(nResult))
	{
		[self logError:nResult forStatement:odbcStmt];
		return NO;	
	}
	
	SQLNumParams(odbcStmt, (SQLSMALLINT *)&paramCount);
	
	return NO;
}

-(BOOL)bindParameters
{
	// if the parameters array and the paramCount do not match, return false
	if (paramCount == [parameters count])
	{
		lastError = [[NSString alloc] initWithString:@"Parameters count mismatch"];
		[lastError retain];
		return NO;
	}
	
    //	(id)value forParameter:(int)paramNumber ofType:(short)iType;
	
	int i;
	for (i = 0; i < [parameters count]; i++)
	{
		NSDictionary *dict = [parameters objectAtIndex:i];
		
		SQLSMALLINT paramNumber = [[dict objectForKey:@"number"] intValue]; 
		SQLSMALLINT valueCDataType = [self getCDataType:dict]; 
		SQLSMALLINT paramSqlType = [self getParameterType:dict]; 
		SQLULEN     columnSize = [self precisionForType:dict]; 
		SQLSMALLINT decimalDigits = [self scaleForType:dict];
		
		SQLPOINTER  parameterValuePtr = [self pointerForValue:dict];
		SQLLEN      bufferLength;
		SQLLEN		actualLength;
		
		// for a BLOB, this is a SQL_C_BINARY / SQLCHAR *()

		RETCODE nResult;
		nResult = SQLBindParameter(odbcStmt, paramNumber, SQL_PARAM_INPUT,
								   valueCDataType, paramSqlType, columnSize,
								   decimalDigits, parameterValuePtr, 
								   bufferLength, &actualLength);
		if (!SQL_SUCCEEDED(nResult))
		{
			[self logError:nResult forStatement:(void *)SQL_NULL_HSTMT];
			return NO;
		}
	}

	return YES;
}


- (SQLULEN)precisionForType:(NSDictionary *)forParameter
{
	NSString *paramType = [forParameter objectForKey:@"type"];
	
	if ([paramType isEqualToString:@"NSString"]) 
	{
		int precision = 255;
		if ([forParameter objectForKey:@"precision"] != nil)
		{
			precision = [[forParameter objectForKey:@"precision"] intValue];
		}
		return precision;
	}
	
	if ([paramType isEqualToString:@"NSData"]) 
	{ 
		int precision = 255;
		if ([forParameter objectForKey:@"precision"] != nil)
		{
			precision = [[forParameter objectForKey:@"precision"] intValue];
		}
		return precision;		
	}
	if ([paramType isEqualToString:@"NSDate"]) 
	{ 
		return SQL_C_TYPE_TIMESTAMP; 
	}
	if ([paramType isEqualToString:@"NSNumber"]) 
	{ 
		// the depends upon the precisoin and scale
		int precision = 4;
		if ([forParameter objectForKey:@"precision"] != nil)
		{
			precision = [[forParameter objectForKey:@"precision"] intValue];
		}
		int scale = 0;
		if ([forParameter objectForKey:@"scale"] != nil)
		{
			scale = [[forParameter objectForKey:@"scale"] intValue];
		}
		
		if (scale > 0) 
		{
			// a floating point value of some form
			if (precision <= sizeof(SQL_C_FLOAT)) { return sizeof(SQL_C_FLOAT); }
			if (precision <= sizeof(SQL_C_DOUBLE)) { return sizeof(SQL_C_DOUBLE); }
			if (precision <= sizeof(SQL_C_NUMERIC)) { return sizeof(SQL_C_NUMERIC); }
		}
		
		if (precision <= sizeof(SQL_C_STINYINT)) { return sizeof(SQL_C_STINYINT); }
		if (precision <= sizeof(SQL_C_UTINYINT)) { return sizeof(SQL_C_UTINYINT); }
		if (precision <= sizeof(SQL_C_SSHORT)) { return sizeof(SQL_C_SSHORT); }
		if (precision <= sizeof(SQL_C_USHORT)) { return sizeof(SQL_C_USHORT); }
		if (precision <= sizeof(SQL_C_SLONG)) { return sizeof(SQL_C_SLONG); }
		if (precision <= sizeof(SQL_C_ULONG)) { return sizeof(SQL_C_ULONG); }
		if (precision <= sizeof(SQL_C_SBIGINT)) { return sizeof(SQL_C_SBIGINT); }
		if (precision <= sizeof(SQL_C_UBIGINT)) { return sizeof(SQL_C_UBIGINT); }
	}
	
	return 255;
}

- (SQLSMALLINT)scaleForType:(NSDictionary *)forParameter
{
	NSString *paramType = [forParameter objectForKey:@"type"];
	
	if ([paramType isEqualToString:@"NSNumber"]) 
	{ 
		// the depends upon the precisoin and scale
		int scale = 0;
		if ([forParameter objectForKey:@"scale"] != nil)
		{
			scale = [[forParameter objectForKey:@"scale"] intValue];
			return scale;
		}
	}
	
	return 0;
}

- (SQLPOINTER)pointerForValue:(NSDictionary *)forParameter
{
	// SQLPOINTER valueReference;
    
    // FIXME: get rid of this
    return NULL;
	
	// allocate the memory, 
	// depending upon the type, get the data and stuff it into the buffer
	// return the newly allocated point.
	
}

- (SQLSMALLINT)getCDataType:(NSDictionary *)forParameter
{
	NSString *paramType = [forParameter objectForKey:@"type"];

	if ([paramType isEqualToString:@"NSString"]) { return SQL_C_CHAR; }
	if ([paramType isEqualToString:@"NSData"]) { return SQL_C_CHAR; }
	if ([paramType isEqualToString:@"NSDate"]) { return SQL_C_TYPE_TIMESTAMP; }
	if ([paramType isEqualToString:@"NSNumber"]) 
	{ 
		// the depends upon the precisoin and scale
		int precision = 4;
		if ([forParameter objectForKey:@"precision"] != nil)
		{
			precision = [[forParameter objectForKey:@"precision"] intValue];
		}
		int scale = 0;
		if ([forParameter objectForKey:@"scale"] != nil)
		{
			scale = [[forParameter objectForKey:@"scale"] intValue];
		}
		
		if (scale > 0) 
		{
			// a floating point value of some form
			if (precision <= sizeof(SQL_C_FLOAT)) { return SQL_C_FLOAT; }
			if (precision <= sizeof(SQL_C_DOUBLE)) { return SQL_C_DOUBLE; }
			if (precision <= sizeof(SQL_C_NUMERIC)) { return SQL_C_NUMERIC; }
		}

		if (precision <= sizeof(SQL_C_STINYINT)) { return SQL_C_STINYINT; }
		if (precision <= sizeof(SQL_C_UTINYINT)) { return SQL_C_UTINYINT; }
		if (precision <= sizeof(SQL_C_SSHORT)) { return SQL_C_SSHORT; }
		if (precision <= sizeof(SQL_C_USHORT)) { return SQL_C_USHORT; }
		if (precision <= sizeof(SQL_C_SLONG)) { return SQL_C_SLONG; }
		if (precision <= sizeof(SQL_C_ULONG)) { return SQL_C_ULONG; }
		if (precision <= sizeof(SQL_C_SBIGINT)) { return SQL_C_SBIGINT; }
		if (precision <= sizeof(SQL_C_UBIGINT)) { return SQL_C_UBIGINT; }
	}
	
	return SQL_C_CHAR;
}

- (SQLSMALLINT)getParameterType:(NSDictionary *)forParameter
{
	NSString *paramType = [forParameter objectForKey:@"type"];
	
	if ([paramType isEqualToString:@"NSString"]) { return SQL_VARCHAR; }
	if ([paramType isEqualToString:@"NSData"]) { return SQL_VARBINARY; }
	if ([paramType isEqualToString:@"NSDate"]) { return SQL_TYPE_TIMESTAMP; }
	if ([paramType isEqualToString:@"NSNumber"]) 
	{ 
		// the depends upon the precisoin and scale
		int precision = 4;
		if ([forParameter objectForKey:@"precision"] != nil)
		{
			precision = [[forParameter objectForKey:@"precision"] intValue];
		}
		int scale = 0;
		if ([forParameter objectForKey:@"scale"] != nil)
		{
			scale = [[forParameter objectForKey:@"scale"] intValue];
		}
		
		if (scale > 0) 
		{
			// a floating point value of some form
			if (precision <= sizeof(SQL_C_FLOAT)) { return SQL_FLOAT; }
			if (precision <= sizeof(SQL_C_DOUBLE)) { return SQL_DOUBLE; }
			if (precision <= sizeof(SQL_C_NUMERIC)) { return SQL_NUMERIC; }
		}
		
		if (precision <= sizeof(SQL_C_UTINYINT)) { return SQL_TINYINT; }
		if (precision <= sizeof(SQL_C_USHORT)) { return SQL_SMALLINT; }
		if (precision <= sizeof(SQL_C_ULONG)) { return SQL_INTEGER; }
		if (precision <= sizeof(SQL_C_UBIGINT)) { return SQL_BIGINT; }
	}
	return SQL_VARCHAR; 
}

- (ODBCRecordset *)open
{
	if (isPrepared) {
		// execute the prepared statement
		
		
	}
	
	
	// if the command is not prepared, prepared it.
	/*
	
	int nResult;
	SQLINTEGER cbRowArraySize = 1;
	
	if (lastError != nil) {
		[lastError release];
		lastError = nil;
	}
	
	// bind the parameters to the command using SQLBindParameter;
	
	
	nResult = SQLExecDirect(hstmt, (UCHAR *)[sql cString], [sql length]);
	if (nResult != SQL_SUCCESS)
	{
       	[self logError:nResult forStatement:hstmt];
		if (nResult != SQL_SUCCESS_WITH_INFO)
		{
			SQLFreeStmt(hstmt, SQL_CLOSE);
			return(nil);
		}
	}
	
	SQLSetStmtAttr(hstmt, SQL_ROWSET_SIZE, &cbRowArraySize, (int)NULL);
	if (nResult != SQL_SUCCESS)
	{
       	//DisplayError(nResult, henv, m_hdbc, m_hstmt);
		return (nil);
	}	
	
	return [[[[ODBCRecordset alloc] initWithConnection:henv forDatabase:hdbc withStatement:hstmt  enableCursors:enableCursors] retain] autorelease];
	*/
	return nil;
}

- (long)execute
{
	// if not prepared (prepared statmt handle is nil)
/*	
	HSTMT   hstmt;
	int nResult;
	long lRowCount;
	
	if (lastError != nil) {
		[lastError release];
		lastError = nil;
	}
	
	hstmt = [self allocateStatement];
	
	UCHAR *sqlString = (UCHAR *)[sql cStringUsingEncoding:NSMacOSRomanStringEncoding];
	nResult = SQLExecDirect(hstmt, sqlString, strlen((char *)sqlString));
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
	
 */
	return 0;
}

#pragma mark -
#pragma mark Simple Accessors

-(NSStringEncoding)defaultEncoding
{
	return defaultEncoding;
}

-(void)setDefaultEncoding:(NSStringEncoding)value
{
	defaultEncoding = value;
}

- (NSString *)sql
{
    return [[sql retain] autorelease];
}

- (void)setSql:(NSString *)value
{    
	if (sql != value) {
        [sql release];
        sql = [value copy];
    }
}

-(void)setParameter:(id)value forParameter:(int)paramNumber ofType:(short)iType
{
	if (parameters == nil) { 
		parameters = [[[NSMutableArray alloc] init] autorelease];
	}
	
	// if the paramNumber < the array size, then pad the array to the correct size
	while (paramNumber >= [parameters count])
	{
		[parameters addObject:@""];
	}
	
	// create an NSNumber for the type
	NSNumber *typeNumber = [[[NSNumber alloc] initWithShort:iType] autorelease];
	NSNumber *paramIndex = [[[NSNumber alloc] initWithInt:paramNumber] autorelease];
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	[dict setObject:paramIndex forKey:@"number"];
	[dict setObject:value forKey:@"value"];
	[dict setObject:typeNumber forKey:@"type"];
	
	// set the parameter to the correct number
	[parameters replaceObjectAtIndex:paramNumber withObject:dict];	
}

-(NSArray *)parameters
{
	NSArray *result = [[NSArray alloc] initWithArray:parameters];
	[result autorelease];
	return result;
}

-(void)setBoolean:(BOOL)value forParameter:(int)paramNumber
{
	NSNumber *boolNumber = nil;
	if (value) {
		boolNumber = [[[NSNumber alloc] initWithShort:1] autorelease];
	} else {
		boolNumber = [[[NSNumber alloc] initWithShort:0] autorelease];
	}
	[self setParameter:boolNumber forParameter:paramNumber ofType:SQL_SMALLINT];
}

-(void)setData:(NSData *)value forParameter:(int)paramNumber
{
	[self setParameter:value forParameter:paramNumber ofType:SQL_UNKNOWN_TYPE];
}

-(void)setDate:(NSDate *)value forParameter:(int)paramNumber
{
	[self setParameter:value forParameter:paramNumber ofType:SQL_DATETIME];
}

-(void)setInt:(int)value forParameter:(int)paramNumber
{
	NSNumber *valueNumber = [[[NSNumber alloc] initWithInt:value] autorelease];
	[self setParameter:valueNumber forParameter:paramNumber ofType:SQL_INTEGER];
}

-(void)setLong:(long)value forParameter:(int)paramNumber
{
	NSNumber *valueNumber = [[[NSNumber alloc] initWithLong:value] autorelease];
	[self setParameter:valueNumber forParameter:paramNumber ofType:SQL_NUMERIC];
}

-(void)setString:(NSString *)value forParameter:(int)paramNumber
{
	[self setParameter:value forParameter:paramNumber ofType:SQL_VARCHAR];
}

@end
