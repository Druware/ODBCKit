//
//  ODBCRecordset.m
//  Convert from TrustWin
//
//  Created by Andy Satori on 7/7/06.
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
 
 *******************************************************************************/

#import "ODBCRecordset.h"

#import "sqltypes.h"
#import "sqlext.h"
#import "sql.h"

#ifndef SQLERR_FORMAT
#define SQLERR_FORMAT "SQL Error State:%s, Native Error Code: %lX, ODBC Error: %s"
#endif
 
@implementation ODBCRecordset

- (void)logError:(RETCODE)result forStatement:(void *)stmt
{
	UCHAR	szErrState[SQL_SQLSTATE_SIZE+1];	// SQL Error State string
	UCHAR	szErrText[SQL_MAX_MESSAGE_LENGTH+1];	// SQL Error Text string
	char	szBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	char	szDispBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	
	// formatted Error text Buffer
	SWORD 	wErrMsgLen;				// Error message length
	UDWORD	dwErrCode;				// Native Error code
	long	iSize;					// Display Error Text size
	SQLRETURN	nErrResult;				// Return Code from SQLError
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

-(BOOL)connectionSupportsCursors
{
	int nResult;
	SQLINTEGER value;
	SQLINTEGER cbValue;
	
	nResult = SQLGetStmtAttr(odbcStmt, SQL_ATTR_CURSOR_SCROLLABLE, (SQLPOINTER) &value, SQL_IS_INTEGER, &cbValue);
	if (nResult != SQL_SUCCESS)
	{
		[self logError:nResult forStatement:odbcStmt];
	}

	return (value != 0);
}

-(id)initWithConnection:(void *)henv 
			forDatabase:(void *)hdbc 
		  withStatement:(void *)hstmt  
		  enableCursors:(BOOL)enableCursors
          usingEncoding:(NSStringEncoding)encoding
{
    self = [super init];
	
	isOpen = YES;
	isEOF = YES;
	
	odbcConn = henv;
	odbcDbc = hdbc;
	odbcStmt = hstmt;
	
    // set the default to what was passed in
	defaultEncoding = encoding;
	
	// does the consumer want cursors?
	cursorsEnabled = enableCursors;
	
	// does the driver support cursors?
	if (cursorsEnabled) {
		usePsuedoCursors = (![self connectionSupportsCursors]);		
	}
    
    // ask the results for the number of rows that were returned
	if (!SQL_SUCCEEDED(SQLRowCount(odbcStmt, (SQLLEN *)&rowCount))) {
		rowCount = 0;
	}
    
    // and set the current position to the top of the set
    currentPosition = 0;
	
	// cache the column list for faster data access via lookups by name
	// Loop through and get the fields into Field Item Classes
	columns = [[NSMutableArray alloc] init];
    
    // ask the statement how many cols are in the results
	SQLSMALLINT iCols;	
	if (!SQL_SUCCEEDED(SQLNumResultCols(odbcStmt, &iCols))) {	
		iCols = 0;
	}
    // FIXME: MSM 15-Jun-12: moved this up, otherwise the for loop is called with nothing
    if (iCols == 0) {
		isEOF = YES;
		return self;
	}
	
    // now we loop over the columns and cache the data about each one into the columns collection
    ODBCColumn *column;
    int i;
    for (i = 1; i <= iCols; i++) {
		// the analyzer feels that this is a leak, however, the memory is released in the dealloc.
		column = [[ODBCColumn alloc] initWithConnection:odbcConn 
                                            forDatabase:odbcDbc 
                                          withStatement:odbcStmt
                                                atIndex:i
                                          usingEncoding:defaultEncoding];
		[columns addObject:column];
	}
	
	isEOF = NO;
	
	// if cursors are disabled, create a psuedo cursor and fetch all the rows
    // here and put them into the psuedoCursorResults array
	if (cursorsEnabled) {
		if (usePsuedoCursors) {
			psuedoCursorResults = [[NSMutableArray alloc] init];
            
			// create the recordset array and allocate set the current position to 0;
			ODBCRecord *result;
			while (![self isEOF]) {
				if (currentRecord != nil) {
					currentRecord = nil;
				}
				
				long nResult;
				nResult = SQLFetch(odbcStmt);
				if (!SQL_SUCCEEDED(nResult)) {
					if (nResult == SQL_NO_DATA_FOUND) {
						break;
					} else {
						[self logError:nResult forStatement:odbcStmt];
						break;
					}
				}
                
				result = [[ODBCRecord alloc] initWithConnection:odbcConn
                                                    forDatabase:odbcDbc
                                                  withStatement:odbcStmt
                                                        columns:columns
                                                  usingEncoding:defaultEncoding];	
				
				[psuedoCursorResults addObject:result];
			}
			isEOF = NO;
			currentPosition = 0;
			currentRecord = [psuedoCursorResults objectAtIndex:0];
		}
		
	} else {
		currentRecord = [self moveNext];
	}
	
    return self;
}

-(void)dealloc
{
	// clean up things
	[self close];

}

-(ODBCField *)fieldByName:(NSString *)fieldName
{
	if (currentRecord != nil) {
		return [currentRecord fieldByName:fieldName];		
	}
	return nil;
}

-(ODBCField *)fieldByIndex:(long)fieldIndex
{
	if (currentRecord != nil) {
		return [currentRecord fieldByIndex:fieldIndex];
	}
	return nil;
}

- (NSArray *)columns
{
	return columns;
}

-(SQLROWCOUNT)rowCount
{
	// if using psuedoCursors we have a count in memory that is more accurate 
	// than rowcount is.  Use that instead.
	if ((cursorsEnabled) & (usePsuedoCursors)) {
		return [psuedoCursorResults count];
	}
	return rowCount;
}

- (ODBCRecord *)movePrevious
{
	if (!cursorsEnabled) {
		lastError = @"Only forward reading allowed";
		return nil;
	}
	
	if (usePsuedoCursors) {
		// use the psuedoCursorArray
		currentPosition--;
		currentRecord = [psuedoCursorResults objectAtIndex:currentPosition];
		return currentRecord;
	} else {
		if (!cursorsEnabled) {
			lastError = @"Only forward reading allowed";
			return nil;
		}
		
		long nResult;
		currentPosition--;
		nResult = SQLSetPos(odbcStmt, currentPosition, SQL_REFRESH, SQL_LOCK_NO_CHANGE);
		if (!SQL_SUCCEEDED(nResult))
		{
			if (nResult == SQL_NO_DATA_FOUND)
			{
				isEOF = YES;
			} else {
				[self logError:nResult forStatement:odbcStmt];
			}
		}
		
		ODBCRecord *result = [[ODBCRecord alloc] initWithConnection:odbcConn
														forDatabase:odbcDbc
													  withStatement:odbcStmt
															columns:columns
                                                      usingEncoding:defaultEncoding];
		[result setDefaultEncoding:defaultEncoding];
		
		if (currentRecord != nil)
		{
			currentRecord = nil;
		}
		currentRecord = result;
		return currentRecord;
	}
	return nil;
}

- (ODBCRecord *)moveNext
{
    // if we are using psuedoCursors then we simply return the next item in the array
	if (usePsuedoCursors) {
		// use the psuedoCursorArray
		currentPosition++;
		if (currentPosition >= [psuedoCursorResults count]) {
			isEOF = YES;
			return nil;
		}
		currentRecord = [psuedoCursorResults objectAtIndex:currentPosition];
		return currentRecord;
	}
    
    // otherwise we're going to use the SQL cursor machinery to do this for us
    else {
		long nResult;
		currentPosition++;
		
        // dispose of any existing currentRecord
		if (currentRecord != nil) {
			currentRecord = nil;
		}
        
		// the open method uses SQLExecute to send the query to the server, but
        // it does not directly return data. one of the variety of SQLFetch
        // statements is used for that...
		nResult = SQLFetch(odbcStmt);
		if (nResult != SQL_SUCCESS) {
			if (nResult == SQL_NO_DATA_FOUND) {
				isEOF = YES;
				return nil;
			} else {
				[self logError:nResult forStatement:odbcStmt];
				return nil;
			}
		}
		
        // ... and this code reads the results back out of the statement
        // structure and into our oun storage
		ODBCRecord *result = [[ODBCRecord alloc] initWithConnection:odbcConn
														forDatabase:odbcDbc
													  withStatement:odbcStmt
															columns:columns
                                                      usingEncoding:defaultEncoding];	
		currentRecord = result;
		return currentRecord;
	}
	return nil;
}

- (ODBCRecord *)moveFirst
{
	if (usePsuedoCursors) {
		// use the psuedoCursorArray
		currentPosition = 0;
		if (currentPosition >= [psuedoCursorResults count]) {
			isEOF = YES;
			return nil;
		}
		currentRecord = [psuedoCursorResults objectAtIndex:currentPosition];
		return currentRecord;
	} else {
		if (!cursorsEnabled) {
			lastError = @"Only forward reading allowed";
			return nil;
		}
		
        // dispose any current record
		if (currentRecord != nil) {
			currentRecord = nil;
		}

        // set the position at the top of the records
        // FIXME: MSM 21-Jun-12: do we have an off-by-one here?
		currentPosition = 0;
		
        long nResult;	
		//nResult = SQLFetchScroll(odbcStmt, SQL_FETCH_FIRST, 1);
        nResult = SQLSetPos(odbcStmt, 1, SQL_POSITION, SQL_LOCK_NO_CHANGE);
		if (!SQL_SUCCEEDED(nResult)) {
			if (nResult == SQL_NO_DATA_FOUND) {
				isEOF = YES;
			} else {
				[self logError:nResult forStatement:odbcStmt];
			}
		}
				
		ODBCRecord *result = [[ODBCRecord alloc] initWithConnection:odbcConn
														forDatabase:odbcDbc
													  withStatement:odbcStmt
															columns:columns
                                                      usingEncoding:defaultEncoding];	

		[result setDefaultEncoding:defaultEncoding];
		currentRecord = result;
		return currentRecord;
		
	}
	return nil;
}

- (ODBCRecord *)moveLast
{
	if (usePsuedoCursors) {
		// use the psuedoCursorArray
		currentPosition = [psuedoCursorResults count] - 1;
		if (currentPosition >= [psuedoCursorResults count]) {
			isEOF = YES;
			return nil;
		}
		currentRecord = [psuedoCursorResults objectAtIndex:currentPosition];
		return currentRecord;
	} else {
		if (!cursorsEnabled) {
			lastError = @"Only forward reading allowed";
			return nil;
		}
		
        // dispose any current record
		if (currentRecord != nil) {
			currentRecord = nil;
		}
				
        // fetch and set the currentPosition to the last row in the table
		long nResult;
		nResult = SQLRowCount(odbcStmt, (SQLLEN *)&currentPosition);
		if (!SQL_SUCCEEDED(nResult)) {
			[self logError:nResult forStatement:odbcStmt];
			return nil;
		}
        
        // FIXME: MSM 21-Jun-12: SQLRowCount returns -1 for Firebird, which is a problem
        //        this code should be removed if a fix is found for that problem
        if (currentPosition <= 0) {
			[self logError:-1 forStatement:odbcStmt];
			return nil;
        }
		
        // now set the cursor position to that row
		nResult = SQLSetPos(odbcStmt, currentPosition, SQL_REFRESH, SQL_LOCK_NO_CHANGE);
		if (!SQL_SUCCEEDED(nResult)) {
			if (nResult == SQL_NO_DATA_FOUND) {
				isEOF = YES;
			} else {
				[self logError:nResult forStatement:odbcStmt];
			}
		}
		
        // now fetch and store the record at that location, and return it
		ODBCRecord *result = [[ODBCRecord alloc] initWithConnection:odbcConn
														forDatabase:odbcDbc
													  withStatement:odbcStmt
															columns:columns
                                                      usingEncoding:defaultEncoding];	
		currentRecord = result;
		return currentRecord;
	}
	return nil;
}

-(void)close
{
	if (isOpen) {
		if (usePsuedoCursors)
		{
			if (psuedoCursorResults)
			{
				long i;
				for (i = [psuedoCursorResults count] - 1; i > 0; i--)
				{
					[psuedoCursorResults removeObjectAtIndex:i];
				}
			}
			psuedoCursorResults = nil;
		} 
		
		if (!usePsuedoCursors)
		{
			if (currentRecord != nil)
			{
				currentRecord = nil;
			}
		}

		// columns
		if (columns != nil)
		{
			long x;
			for (x = [columns count] - 1; x > 0; x--)
			{
				[columns removeObjectAtIndex:x];
			}
			columns = nil;
		}

		SQLFreeStmt(odbcStmt, SQL_CLOSE);	
	}
	isOpen = NO;
}

-(BOOL)isEOF
{
	return isEOF;
}

-(NSDictionary *)dictionaryFromRecord
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	long i;
	for (i = 0; i < [columns count]; i++)
	{
		ODBCColumn *column = [columns objectAtIndex:i];
		// for each column, add the value for the key.
		switch ([column type])
		{
			case SQL_UNKNOWN_TYPE:
				[dict setValue:[[self fieldByName:[column name]] asData] forKey:[[column name] lowercaseString]];
				break;				
			case SQL_CHAR:
			case SQL_VARCHAR:
				[dict setValue:[[self fieldByName:[column name]] asString] forKey:[[column name] lowercaseString]];
				break;
			case SQL_NUMERIC:
			case SQL_DECIMAL:
			case SQL_INTEGER:
			case SQL_SMALLINT:
			case SQL_FLOAT:
			case SQL_REAL:
			case SQL_DOUBLE:
				[dict setValue:[[self fieldByName:[column name]] asNumber] forKey:[[column name] lowercaseString]];
				break;
			case SQL_DATETIME:
			case SQL_TIMESTAMP:
				[dict setValue:[[self fieldByName:[column name]] asDate] forKey:[[column name] lowercaseString]];
				break;
			default:
				[dict setValue:[[self fieldByName:[column name]] asData] forKey:[[column name] lowercaseString]];
				break;
		}
	}
	NSDictionary *result = [[NSDictionary alloc] initWithDictionary:dict];
	return result;
}

- (NSString *)lastError {
    return lastError;
}

-(NSStringEncoding)defaultEncoding
{
	return defaultEncoding;
}
-(void)setDefaultEncoding:(NSStringEncoding)value
{
    if (defaultEncoding != value) {
        defaultEncoding = value;
    }
}

@end
