//
//  MyDocumentMenu.h
//  ODBCQueryTool
//
//  Created by Andy Satori on 9/12/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface MyDocument (MyDocumentMenu)

- (BOOL)validateMenuItem:(NSMenuItem *)theItem;

@end
