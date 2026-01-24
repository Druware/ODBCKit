//
//  SchemaElement.m
//  ODBCQueryTool
//
//  Created by Andy Satori on 3/12/09.
//  Copyright 2009 Druware Software Designs. All rights reserved.
//

#import "SchemaElement.h"

@implementation SchemaElement

-(id)init
{
	self = [super init];
	if (self)
	{
		_name = nil;
		_children = nil;;
		_properties = nil;
		_elementType = 0;
		
	}
	return self;
}

-(NSString *)name
{
	return _name;
}
-(void)setName:(NSString *)value
{
	if (_name)
	{
		_name = nil;
	}
	_name = [[NSString alloc] initWithString:value];
}

-(NSMutableArray *)children
{
	if (_children == nil)
	{
		_children = [[NSMutableArray alloc] init];
	}
	return _children;
}
-(void)setChildren:(NSMutableArray *)value
{
	if (_children)
	{
		_children = nil;
	}
	_children = [[NSMutableArray alloc] initWithArray:value];
}

-(NSMutableDictionary *)properties
{
	if (_properties == nil)
	{
		_properties = [[NSMutableDictionary alloc] init];
	}
	return _properties;
}
-(void)setProperties:(NSMutableDictionary *)value
{
	if (_properties)
	{
		_properties = nil;
	}
	_properties = [[NSMutableDictionary alloc] initWithDictionary:value];
}

-(int)elementType
{
	return _elementType;
}
-(void)setElementType:(int)value
{
	_elementType = value;
}

// outline implementation

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	return (item == nil) ? nil : (id)[item name];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item) 
	{
		return [[item children] count];
	} else {
		return [_children count];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item) {
		return ([[item children] count] > 0);
	} else {
		return ([_children count] > 0) ;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item)
	{
		return [[item children] objectAtIndex:index];
	} else {
		return [_children objectAtIndex:index];
	}
	
	return nil;
}

@end
