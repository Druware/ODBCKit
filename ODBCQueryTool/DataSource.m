//
//  DataSource.m
//
//  Created by Andy Satori on Sun 02/08/04 05:38 PM
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"

@implementation DataSource

- (id)init
{
    if (!(self = [super init])) return nil;
    
    items = [[NSMutableArray alloc] init];
    
    return self;
}

// collection management

- (void)clear
{
	[items removeAllObjects];
}

- (NSMutableDictionary *)addItem
{
    NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
    
    [items addObject: newItem];
    return newItem;    
}

- (void)removeItemAtIndex:(int)index
{
    [items removeObjectAtIndex:index];
}

- (NSMutableDictionary *)itemAtIndex:(int)index
{
    return [items objectAtIndex:index];
}

- (int)count
{
    return [items count];
}

// table view data source methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [items count];
}

- (id)tableView:(NSTableView *)aTableView 
    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
    row:(NSInteger)rowIndex 
{
    NSString *ident = [aTableColumn identifier];
    NSMutableDictionary *anItem = [items objectAtIndex:rowIndex];
    return [anItem valueForKey:ident];
}

@end
