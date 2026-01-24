//
//  ODBCQueryAction.h
//  ODBCQueryAction
//
//  Created by Andy Satori on 9/14/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>
#import <ODBCKit/ODBCKit.h>

@interface ODBCQueryAction : AMBundleAction 
{
	
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
