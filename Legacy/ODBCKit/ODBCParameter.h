//
//  ODBCParameter.h
//  ODBCKit
//
//  Created by Andy Satori on 4/6/11.
//  Copyright 2011 Satori & Associates, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ODBCParameter : NSObject {
	NSString *name;
	int index;
	int type;
	int size;
	int offset;
		
	NSData *data;
}

-(NSString *)name;
-(void)setName:(NSString *)value;
-(int)index;	// number
-(void)setIndex:(int)value;
-(int)type;		// type (SQL)
-(void)setType:(int)value;
-(int)size;		// precision
-(void)setSize:(int)value;
-(int)offset;	// scale
-(void)setOffset:(int)value;
-(NSData *)data;
-(void)setData:(NSData *)data;


@end
