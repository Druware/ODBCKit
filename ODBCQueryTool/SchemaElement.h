//
//  SchemaElement.h
//  ODBCQueryTool
//
//  Created by Andy Satori on 3/12/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SchemaElement : NSObject <NSOutlineViewDataSource> {
	NSString			*_name;
	NSMutableArray		*_children;
	NSMutableDictionary *_properties;
	
	int					 _elementType;
}

-(void)setName:(NSString *)value;
-(NSString *)name;
-(void)setChildren:(NSMutableArray *)value;
-(NSMutableArray *)children;
-(void)setProperties:(NSMutableDictionary *)value;
-(NSMutableDictionary *)properties;
-(void)setElementType:(int)value;
-(int)elementType;

@end
