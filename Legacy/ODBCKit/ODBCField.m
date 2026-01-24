//
//  ODBCField.m
//  CaseClaims
//
//  Created by Andy Satori on 7/13/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2006-2011, Druware Software Designs 
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

#import "ODBCField.h"

#import "sqltypes.h"
#import "sqlext.h"
#import "sql.h"

#ifndef SQLERR_FORMAT
#define SQLERR_FORMAT "SQL Error State:%s, Native Error Code: %lX, ODBC Error: %s"
#endif

@implementation ODBCField

- (void)logError:(RETCODE)result forStatement:(void *)stmt
{
	UCHAR	szErrState[SQL_SQLSTATE_SIZE+1];	// SQL Error State string
	UCHAR	szErrText[SQL_MAX_MESSAGE_LENGTH+1];	// SQL Error Text string
	char	szBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	char	szDispBuffer[SQL_SQLSTATE_SIZE+SQL_MAX_MESSAGE_LENGTH+ 1024 +1];
	
	// formatted Error text Buffer
	SWORD 	wErrMsgLen;				// Error message length
	UDWORD	dwErrCode;				// Native Error code
	unsigned long	iSize;                      // Display Error Text size
	SQLRETURN	nErrResult;			// Return Code from SQLError
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
	
	nErrResult = SQLError(odbcConn, odbcDbc, stmt, szErrState, (SQLINTEGER *)&dwErrCode, szErrText, SQL_MAX_MESSAGE_LENGTH-1,  &wErrMsgLen);
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
		
		// continue processing errors
		nErrResult = SQLError(odbcConn, odbcDbc, stmt, szErrState, (SQLINTEGER *)&dwErrCode, szErrText, SQL_MAX_MESSAGE_LENGTH-1,  &wErrMsgLen);			
	}
	if (bErrorFound == FALSE)
		return;
	NSLog(@"%s", szDispBuffer);
}

-(id)initWithConnection:(void *)henv forDatabase:(void *)hdbc 
          withStatement:(void *)hstmt forColumn:(ODBCColumn *)forColumn
          usingEncoding:(NSStringEncoding)encoding
{
	self = [super init];
	
	if (self != nil) {
		odbcConn = henv;
		odbcDbc = hdbc;
		odbcStmt = hstmt;
		data = nil;
		
		defaultEncoding = encoding;
	
		long nResult;
		int iLen;
		char *szBuf;

		column = forColumn;
	
		// bail if column size is zero
		if ([column size] == 0)
		{
			return self;
		}
	
		// if the column size is -1, this will need to load the data in chunks and 
		// append it to an NSMutableData which is used to create the NSData that we
		// store.  it may be slower, but will get ALL of the data.
		iLen = [column size];
		
        // due to an oddity in most drivers with regard to double-byte string 
        // encodings it is necessary to double the length of the read buffer
        // to deal with multi-byte encodings.  It appears to be possible to
        // use SQLGetDescField() with the SQL_DESC_OCTET_LENGTH paramter to 
        // get the actual data length from the driver, but it does not appear
        // to have universal driver support, so the quick hack may actually 
        // provide a more robust short term solution.
		if ([column type] == SQL_VARCHAR || [column type] == SQL_CHAR ) {
			iLen = [column size] * 2;
		}
		
		if ([column size] == -1) {
			if ((SQLGetData(hstmt, [column index], SQL_C_DEFAULT, NULL, 0, 
									  (long *)&iLen)) != SQL_SUCCESS)
			{
				iLen = 32767;
			}
		}

		szBuf = (char *)malloc(iLen + 1);
		szBuf[0] = 0;

		nResult = SQLGetData(odbcStmt, ([column index]), SQL_C_CHAR, szBuf, iLen, 
							 (long *)&iLen);		
		if (!SQL_SUCCEEDED(nResult))
		{
			[self logError:nResult forStatement:odbcStmt];
		} 
		else {
			// NSLog(@"DEBUG Field Data: %s", szBuf);
			if (iLen > 0) {
				data = [[NSData alloc] initWithBytes:szBuf length:iLen];
			}
		}
		free(szBuf);
	}
	
	return self;
}

-(void)dealloc
{
	// clean up things that won't clean themselves up
	
	if (data != nil)
	{
		data = nil;
	}
    
}

#pragma mark GenDB Method Implementations

-(NSString *)asString
{	
	@try
	{
		if (data != nil) {
			if ([data length] <= 0)
			{
				return nil;
			}
			return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:defaultEncoding];	
		}
	}
	@catch (NSException* ex)
	{
		NSLog(@"Error %@", ex);
	}
	return @""; 
}

-(NSString *)asString:(NSStringEncoding)encoding
{	
	@try
	{
		if (data != nil) {
			if ([data length] <= 0)
			{
				return nil;
			}
			return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:encoding];	
		}
	}
	@catch (NSException* ex)
	{
		NSLog(@"Error %@", ex);
	}
	return @""; 
}

-(NSNumber *)asNumber
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		NSString *temp = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:defaultEncoding];
		NSNumber *value = [[NSNumber alloc] initWithFloat:[temp floatValue]];
		return value;
	}
	return nil;
}

-(short)asShort
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return 0;
		}
		
		NSString *value = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:defaultEncoding];
		
		return (short)[[NSNumber numberWithFloat:[value floatValue]] shortValue];
	}
	return 0; 

}

-(long)asLong
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return 0;
		}
		
		NSString *value = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:defaultEncoding];
		
		return (long)[[NSNumber numberWithFloat:[value floatValue]] longValue];
	}
	return 0; 
}

-(NSDate *)asDate
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		NSString *value = [NSString stringWithCString:(char *)[data bytes]
											 encoding:defaultEncoding];
		if ([value rangeOfString:@"."].location != NSNotFound)
		{
			value = [NSString stringWithFormat:@"%@ +0000", [value substringToIndex:[value rangeOfString:@"."].location]];
		} else {
			
			value = [NSString stringWithFormat:@"%@ +0000", value];
		}
        // replaced initWithString
		// NSDate *newDate = [[NSDate alloc] initWithString:value];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        NSDate *newDate = [df dateFromString:value];
        
        
		return newDate;
	}
	return nil; 	
}

// https://sourceforge.net/tracker/?func=detail&aid=2108119&group_id=177561&atid=881726
-(NSDate *)asDateWithGMTOffset:(NSString *)gmtOffset // +/-0500
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		// should validate the gmtOffset with a Regex.
		
		NSString *value = [NSString stringWithCString:(char *)[data bytes]
											 encoding:defaultEncoding];
		if ([value rangeOfString:@"."].location != NSNotFound)
		{
			value = [NSString stringWithFormat:@"%@ %@", 
					 [value substringToIndex:[value rangeOfString:@"."].location],
					 gmtOffset];
		} else {
			
			value = [NSString stringWithFormat:@"%@ %@", value, gmtOffset];
		}
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        
        NSDate *newDate = [df dateFromString:value];
		
		return newDate;
	}
	return nil; 	
}

-(NSData *)asData
{
	if (data != nil) {
		if ([data length] <= 0)
		{
			return nil;
		}
		
		return [[NSData alloc] initWithData:data];
	}
	return nil; 	
}

-(BOOL)isNull
{
    return (data != nil);
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
