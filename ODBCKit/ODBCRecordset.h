//
//  ODBCRecordset.h
//  Convert from TrustWin
//
//  Created by Andy Satori on 7/7/06.
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

#import <Cocoa/Cocoa.h>
#import "ODBCColumn.h"
#import "ODBCRecord.h"
#import "ODBCField.h"
#import "GenDBProtocol.h"

@interface ODBCRecordset : NSObject <GenDBRecordset> {
	void *odbcConn;
	void *odbcDbc;
	void *odbcStmt;
	
	BOOL isEOF;
	BOOL isOpen;
	
	NSString *lastError;
	
	// internal behaviors
	BOOL cursorsEnabled;
	BOOL usePsuedoCursors;
	long currentPosition;
	NSMutableArray *psuedoCursorResults;

	long rowCount;
	
	NSMutableArray *columns;
	
	ODBCRecord *currentRecord;
	
	NSStringEncoding defaultEncoding;

}

-(id)initWithConnection:(void *)henv 
			forDatabase:(void *)hdbc 
		  withStatement:(void *)hstmt  
		  enableCursors:(BOOL)enableCursors
          usingEncoding:(NSStringEncoding)encoding
;

-(ODBCField *)fieldByIndex:(long)fieldIndex;
-(ODBCField *)fieldByName:(NSString *)fieldName;
-(void)close;

-(NSArray *)columns;
@property (assign, nonatomic, readonly) NSArray *Columns;
-(unsigned long)rowCount;
@property (assign, nonatomic, readonly) unsigned long RowCount;

-(ODBCRecord *)moveFirst;
-(ODBCRecord *)movePrevious;
-(ODBCRecord *)moveNext;	
-(ODBCRecord *)moveLast;

-(BOOL)isEOF;
@property (assign, nonatomic, readonly, getter=isEOF) BOOL IsEOF;

-(NSDictionary *)dictionaryFromRecord;

-(NSString *)lastError;
@property (assign, nonatomic, readonly) NSString *LastError;

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

@end
