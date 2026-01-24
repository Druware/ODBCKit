//
//  ODBCConnection.h
//  ODBCKit
//
//  Created by Andy Satori on 6/27/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2005-2011, Druware Software Designs 
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

/* There remains alot of work to be done here, particularly for dealing with 
 * Parameters & BLOB's.  The primary focus of the next few days 
 */ 

#import <Cocoa/Cocoa.h>

#import "ODBCRecordset.h"
//#import "ODBCPreparedStatement.h"
#import "GenDBProtocol.h"



#ifndef SQLERR_FORMAT
#define SQLERR_FORMAT "SQL Error State:%s, Native Error Code: %lX, ODBC Error: %s"
#endif

// static HENV henv;

@interface ODBCConnection: NSObject <GenDBConnection> {
	BOOL isEnvironmentValid;	
	BOOL isConnected;
	
	NSString *dsn;
	NSString *userName;
	NSString *password;
	
	NSStringEncoding defaultEncoding;
	
	BOOL enableCursors;
	BOOL usingDriverCursors;
	
	//NSMutableArray *preparedStatements;
	
	NSString *filter;
	
	NSString *lastError;
	
	void *	henv;
	void *	hdbc;			// hdbc
}

/*!
 @function
 @abstract   clones the connection and re-connects if the conenction was active
 @result     ODBCConnection
 */
- (ODBCConnection *)clone;

- (BOOL)initSQLEnvironment;
- (void *)allocateStatement;
// - (void)logError:(RETCODE)resultCode forStatement:(void *)stmt;
- (BOOL)freeSQLEnvironment;

- (NSArray *)datasources;
- (NSArray *)drivers;
- (NSString *)driver;
- (NSString *)database;
- (BOOL)readOnly;

// Methods for interrogating the schema details
- (ODBCRecordset *)tables;
- (ODBCRecordset *)tableColumns:(NSString*)tableName;
- (ODBCRecordset *)tableForeignKeys:(NSString*)tableName;
- (ODBCRecordset *)tablePrimaryKeys:(NSString*)tableName;
- (ODBCRecordset *)tableIndexes:(NSString*)tableName;
- (ODBCRecordset *)getTypeInfo:(signed short)dataType;

- (BOOL)close;
- (BOOL)connect;
- (void)connectAsync;
- (long)execCommand:(NSString *)sql;
- (void)execCommandAsync:(NSString *)sql;
- (ODBCRecordset *)open:(NSString *)sql;
- (void)openAsync:(NSString *)sql;

- (NSString *)lastError;
@property (assign, nonatomic, readonly, getter=lastError) NSString *LastError;

//- (ODBCPreparedStatement *)preparedStatement;
//- (ODBCCommand *)commandWithDictionary:(NSMutableDictionary *)dict;

- (BOOL)isEnvironmentValid;
@property (assign, nonatomic, readonly, getter=isEnvironmentValid) BOOL IsEnvironmentValid;
- (BOOL)isConnected;
@property (assign, nonatomic, readonly, getter=isConnected) BOOL IsConnected;

- (NSString *)connectionString;
- (void)setConnectionString:(NSString *)value;
@property (assign, nonatomic) NSString *ConnectionString;

- (NSString *)dsn;
- (void)setDsn:(NSString *)value;
@property (assign, nonatomic) NSString *Dsn;

- (NSString *)userName;
- (void)setUserName:(NSString *)value;
@property (assign, nonatomic) NSString *UserName;

- (NSString *)password;
- (void)setPassword:(NSString *)value;
@property (assign, nonatomic) NSString *Password;

- (NSString *)datasourceFilter;
- (void)setDatasourceFilter:(NSString *)value;
@property (assign, nonatomic) NSString *DatasourceFilter;

- (BOOL)enableCursors;
- (void)setEnableCursors:(BOOL)value;
@property (assign, nonatomic) BOOL EnableCursors;

/*!
	@function
	@abstract   Get the connection's defaultEncoding for all string operations 
				returning.
	@discussion The default setting is NSUTF8StringEncoding.  
	@result     returns the defaultEncoding as an NSSTringEncoding ( 
				http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )
 */
-(NSStringEncoding)defaultEncoding;

/*!
	@function
	@abstract   Set the defaultEncoding for all string operations on the current
				connection
	@discussion The default setting is NSUTF8StringEncoding.
	@param      value the defaultEncoding as an NSSTringEncoding ( 
				http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/c_ref/NSStringEncoding )

	@result     void
 */
-(void)setDefaultEncoding:(NSStringEncoding)value;
@property (assign, nonatomic) NSStringEncoding DefaultEncoding;

FOUNDATION_EXPORT NSString * const ODBCConnectionDidCompleteNotification;
FOUNDATION_EXPORT NSString * const ODBCCommandDidCompleteNotification;

@end






