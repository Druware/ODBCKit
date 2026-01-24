//
//  ODBCCommand.h
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
 
 *******************************************************************************/

#import <Cocoa/Cocoa.h>
#import "ODBCRecordset.h"

#import "sql.h"
#import "sqlext.h"
#import "sqltypes.h"

#ifndef SQLERR_FORMAT
#define SQLERR_FORMAT "SQL Error State:%s, Native Error Code: %lX, ODBC Error: %s"
#endif

@interface ODBCPreparedStatement: NSObject {
	void *odbcConn;
	void *odbcDbc;
	void *odbcStmt;	
	
	NSStringEncoding defaultEncoding;
	
	BOOL isPrepared;
	long paramCount;
	
	BOOL enableCursors;
	BOOL usingDriverCursors;
	NSString *lastError;
	
	NSMutableArray *parameters;
	NSString *sql;
}

-(id)initWithConnection:(void *)henv forDatabase:(void *)hdbc;

-(BOOL)prepare;
-(long)execute;
-(ODBCRecordset *)open;

-(NSArray *)parameters;

-(NSString *)sql;
-(void)setSql:(NSString *)value;

-(void)setParameter:(id)value forParameter:(int)paramNumber ofType:(short)iType;
-(void)setBoolean:(BOOL)value forParameter:(int)paramNumber;
-(void)setData:(NSData *)value forParameter:(int)paramNumber;
-(void)setDate:(NSDate *)value forParameter:(int)paramNumber;
-(void)setInt:(int)value forParameter:(int)paramNumber;
-(void)setLong:(long)value forParameter:(int)paramNumber;
-(void)setString:(NSString *)value forParameter:(int)paramNumber;

@end
