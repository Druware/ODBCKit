//
//  ODBCRecord.m
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

#import "ODBCRecord.h"


@implementation ODBCRecord

-(id)initWithConnection:(void *)henv 
			forDatabase:(void *)hdbc 
		  withStatement:(void *)hstmt 
				columns:(NSArray *)columncache
          usingEncoding:(NSStringEncoding)encoding
{
    self = [super init];
	
	odbcConn = henv;
	odbcDbc = hdbc;
	odbcStmt = hstmt;
	columns = columncache;
	
	defaultEncoding = encoding;
	
	// preload the fields rather than wait until they are read this should clearn
	fields = [[NSMutableArray alloc] init];
    
    int x;
	for (x = 0; x < [columns count]; x++)  
	{
		// the analyzer feels that this is a leak, however, the memory is released in the dealloc.
		ODBCField *result = [[ODBCField alloc] initWithConnection:odbcConn 
													  forDatabase:odbcDbc 
													withStatement:odbcStmt 
                                                        forColumn:[columns objectAtIndex:x]
                                                    usingEncoding:defaultEncoding];
		[fields addObject:result];
	}
    
	return self;
}

-(void)dealloc
{
	// clean up things that won't clean themselves up
	// columns is passed in and retained, so it must be relesed
	
	
	if (fields)
	{
		unsigned long i;
		for (i = [fields count] - 1; i > 0; i--)
		{
			[fields removeObjectAtIndex:i];
		}
	}
	
}

-(ODBCField *)fieldByName:(NSString *)fieldName
{
	// find the field index from the columns.
	ODBCField *result= nil;
	
    int x = 0;
	for (x = 0; x < [columns count]; x++)
	{
		if ([[[columns objectAtIndex:x] name] caseInsensitiveCompare:fieldName] == NSOrderedSame)
		{
			result = [fields objectAtIndex:x];
			break;
		}
	}
	return result;
}
	
-(ODBCField *)fieldByIndex:(long)fieldIndex
{
	// find the field index from the columns.
	ODBCField *result = [fields objectAtIndex:fieldIndex];
	return result;
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
