//
//  ODBCColumn.m
//  CaseClaims
//
//  Created by Andy Satori on 7/13/06.
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

#import "ODBCColumn.h"

#import "sql.h"
#import "sqlext.h"
#import "sqltypes.h"

@implementation ODBCColumn

-(id)initWithConnection:(void *)henv forDatabase:(void *)hdbc 
          withStatement:(void *)hstmt atIndex:(int)atIndex
          usingEncoding:(NSStringEncoding)encoding
{
    int iBufLen = 256;
	char szBuf[iBufLen];
    
	SQLULEN iLength;
	SQLSMALLINT iNameLen;
	SQLSMALLINT iType;
	SQLSMALLINT iDec;
	SQLSMALLINT iNullable;
	
    self = [super init];
	if (self == nil) { return nil; }
	
	odbcConn = henv;
	odbcDbc = hdbc;
	odbcStmt = hstmt;
	index = atIndex;
	
    
    defaultEncoding = encoding;
	name = nil;
	
	if (SQL_SUCCEEDED(SQLDescribeCol(odbcStmt, index, (unsigned char *)szBuf, iBufLen, 
								  &iNameLen, &iType, &iLength,
								  &iDec, &iNullable)))
	{
		name = [NSString stringWithFormat:@"%s", szBuf];
		type = iType;
		
		size = iLength;
		if (iType != SQL_VARCHAR && (iType < 0 || iType > 8)) {
			size = -1;		
		}
		
		offset = iDec;
		isNullable = (iNullable == SQL_NULLABLE);

		//Get the extended attributes
		SQLUSMALLINT idx = atIndex;
		SQLLEN numericAttribute;
		numericAttribute = 0;		
		if (SQL_SUCCEEDED(SQLColAttribute(odbcStmt, idx, SQL_DESC_AUTO_UNIQUE_VALUE , nil, 0,  nil, (SQLPOINTER)&numericAttribute)))
		{
			isAutoIncrement = numericAttribute == SQL_TRUE;
		}
		numericAttribute = 0;
		if (SQL_SUCCEEDED(SQLColAttribute(odbcStmt, idx, SQL_DESC_UNSIGNED, nil, 0,  nil, (SQLPOINTER)&numericAttribute)))
		{
			isUnsigned = numericAttribute == SQL_TRUE;
		}
		
		// would like to check the keys, to do that, this needs to check the 
		// primary keys based upon the associated table name 
		// (chain lookup  SQLColAttribute and SQLPrimaryKeys)
	}
	
	return self;
}

-(void)dealloc
{
	// clean up things that won't clean themselves up
	if (name != nil)
	{
		name = nil;
	}
    
}

- (NSString *)name {
    return name;
}

-(int)index
{
	return index;
}
-(int)type;
{
	return type;
}
-(long)size
{
	return size;
}
-(int)offset
{
	return offset;
}

-(NSStringEncoding)encoding
{
    return defaultEncoding;
}

-(BOOL)isKey
{
	return NO;
}

-(BOOL)isNullable
{
	return isNullable;
}
-(BOOL)isUnsigned
{
	return isUnsigned;
}
-(BOOL)isAutoIncrement
{
	return isAutoIncrement;
}

@end
