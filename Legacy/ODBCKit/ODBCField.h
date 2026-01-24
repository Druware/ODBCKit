//
//  ODBCField.h
//  CaseClaims
//
//  Created by Andy Satori on 7/13/06.
//  Copyright 2006-2011 Druware Software Designs. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "ODBCColumn.h"
#import "GenDBProtocol.h"

/*!
    @class
    @abstract    Object Representation of a field in a recordset
    @discussion  The ODBCField represents the data contained in a single column 
				 of a a single row in a recordset.  In order to make it easier 
				 to consume, it stores the data internally an NSData object, and
				 will do the conversions to the the appropriate type (where 
				 possible) using the various ‘as’ properties.
				
				 ODBCField Conforms to the GenDBField Protocol.  Reference it 
                 for more information about implementation details.
*/
@interface ODBCField : NSObject <GenDBField> {
	void *odbcConn;
	void *odbcDbc;
	void *odbcStmt;
	
	NSData *data;
	
	ODBCColumn *column;
	
	NSStringEncoding defaultEncoding;
}

/*!
    @function
    @abstract   base initializer, this class does not implement an init with no
				parameters, as it is not intended for use outside of the 
	            recordset implementation.
    @discussion Init a field using the current connection and resultset contents
                based upon the current column in the result.
 
    @param      henv is the ODBC Environment Handle that is associated with 
				every ODBC call
	@param      hdbc is the connection handle associated with every ODBC call
	@param      hstmt is the reference to the currently executing statement in 
				the ODBC call
	@param      forColumn is the column that defines the results for the current
				field.
    @result     the id result of the command is either nil for a failed init or
                a pointer to the newly instantiated and populated ODBCField,
				complete with data (if present).
*/
-(id)initWithConnection:(void *)henv 
			forDatabase:(void *)hdbc 
		  withStatement:(void *)hstmt  
			  forColumn:(ODBCColumn *)forColumn
          usingEncoding:(NSStringEncoding)encoding;

-(NSString *)asString;
-(NSString *)asString:(NSStringEncoding)encoding;
-(NSNumber *)asNumber;
-(short)asShort;
-(long)asLong;
-(NSDate *)asDate;
-(NSDate *)asDateWithGMTOffset:(NSString *)gmtOffset;
-(NSData *)asData;
-(BOOL)isNull;

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

@end
