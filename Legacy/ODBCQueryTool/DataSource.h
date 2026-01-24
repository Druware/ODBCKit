//
//  DataSource.h
//
//  Created by Andy Satori on Sun 02/08/04 05:38 PM
//  Copyright (c) 2004 Druware Software Designs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataSource : NSObject <NSTableViewDataSource>
{
        NSMutableArray *items;
}

- (void)clear;
- (NSMutableDictionary *)addItem;
- (void)removeItemAtIndex:(int)index;
- (NSMutableDictionary *)itemAtIndex:(int)index;
- (int)count;

@end
