//
//  ODBCDynamicQueryAction.h
//  ODBCDynamicQueryAction
//
//  Created by Andy Satori on 12/26/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>
#import "ODBCKit.h"

@interface ODBCDynamicQueryAction : AMBundleAction 
{
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
