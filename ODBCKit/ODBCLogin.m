//
//  ODBCLogin.m
//  ODBCKit
//
//  Created by Andy Satori on 8/6/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2005-2009, Druware Software Designs 
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

#import "ODBCLogin.h"

// #define USE_SYNC_CONNECT 1

@implementation ODBCLogin

-(id)init
{
    self = [super init];
	
	odbcConn = [[ODBCConnection alloc] init];
	defaultDSN = nil;
	defaultUser = nil;
	defaultPassword = nil;
	loginImage = nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onConnectionCompleted:)
                                                 name:ODBCConnectionDidCompleteNotification
                                               object:nil];
	
	return self;
} 

- (void)beginModalLoginForWindow:(NSWindow *)parent
{
	parentWindow = parent;
	
	// load the nib
	if (![NSBundle loadNibNamed:@"ODBCLogin" owner:self])
    // if (![[NSBundle mainBundle] loadNibNamed:@"ODBCLogin" owner:self topLevelObjects:nil]) // 10.9 and newer methodology
	{
		NSLog(@"Error loading nib for login");
		return;
	}
	
    // clear out and then re-load the list of DSN's
	[connectionList removeAllItems];
	NSArray *list = [odbcConn datasources];
	int i;
	for (i = 0; i < [list count]; i++) {
		[connectionList addItemWithTitle:[[list objectAtIndex:i] valueForKey:@"name"]];
	}
	if (defaultDSN != nil) {
		[connectionList selectItemWithTitle:defaultDSN];		
	}
	
    // set up the rest of the defaults
	if (defaultUser != nil) {
		[loginUserName setStringValue:defaultUser];
	}
	if (defaultPassword != nil) {
		[loginPassword setStringValue:defaultPassword];
	}
	
	// set and reload the icon path
	if (loginImage != nil) {
		[loginIcon setImage:loginImage]; 	
	}
	
    // and bring up a model login panel
	[NSApp beginSheet:loginPanel  
	   modalForWindow:parentWindow 
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
    [NSApp runModalForWindow:loginPanel];
	
    [NSApp endSheet:loginPanel];
    [loginPanel orderOut:self];	
	
	return;
}

- (void)onConnectionCompleted:(NSNotification *)aNotification
{
	// stop observing once we've caught the event,  which prevents
    // multiple event firings
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	NSDictionary *info = [aNotification userInfo];
	
	if ([info valueForKey:@"Error"] == nil) {
		NSLog(@"Connected to ODBC datasouce");
	} else {
		NSLog(@"Unable to connect to ODBC datasouce");
	}
	
    dispatch_async(dispatch_get_main_queue(), ^{
        NSObject* windowDelegate = [self->parentWindow delegate];
        if ([windowDelegate respondsToSelector:@selector(loginCompleted:)])
        {
            [windowDelegate loginCompleted:self->odbcConn];
        }
    });
}

- (IBAction)onLogin:(id)sender
{
	[NSApp stopModal];
		
	// create the connection
	[odbcConn setDsn:[connectionList titleOfSelectedItem]];
	[odbcConn setUserName:[loginUserName stringValue]];
	[odbcConn setPassword:[loginPassword stringValue]];
	
#ifdef USE_SYNC_CONNECT
	if ([odbcConn connect] == YES) {
		NSLog(@"Connected to ODBC datasouce");
	} else {
		// show an alert 
		NSLog(@"Unable to connect to ODBC datasouce");
	}
	
	NSObject* windowDelegate = [parentWindow delegate];
	if ([windowDelegate respondsToSelector:@selector(loginCompleted:)] == YES)
	{
		[windowDelegate loginCompleted:odbcConn];
	}
#endif
	
	[odbcConn connectAsync];
}

- (IBAction)onCancel:(id)sender
{
    odbcConn = nil;
    
	[NSApp stopModal];
	
	// exit the application
	NSObject* windowDelegate = [parentWindow delegate];
	if ([windowDelegate respondsToSelector:@selector(loginCompleted:)] == YES)
	{
		[windowDelegate loginCompleted:odbcConn];
	}
}

- (IBAction)onHelp:(id)sender
{
	// display the help book when it is avaialble
	return;
}

- (ODBCConnection *)connection
{
	if (odbcConn != nil)
	{
		return odbcConn;
	}
	return nil;
}

- (BOOL)isConnected
{
	if (odbcConn != nil)
	{
		return [odbcConn isConnected];
	}
	return NO;
}

- (NSString *)datasourceFilter
{
    return [odbcConn datasourceFilter];
}
- (void)setDatasourceFilter:(NSString *)value
{    
	[odbcConn setDatasourceFilter:value];
}

- (NSString *)defaultDSN
{
    return defaultDSN;
}
- (void)setDefaultDSN:(NSString *)value
{    
	if (defaultDSN != value) {
        defaultDSN = [value copy];
    }
}

- (NSString *)defaultUser
{
    return defaultUser;
}
- (void)setDefaultUser:(NSString *)value
{    
	if (defaultUser != value) {
        defaultUser = [value copy];
    }
}

- (void)setDefaultPassword:(NSString *)value
{    
	if (defaultPassword != value) {
        defaultPassword = [value copy];
    }
}

- (void)setIcon:(NSImage *)value
{
	if (loginImage != value) {
        loginImage = [value copy];
    }
}

@end
