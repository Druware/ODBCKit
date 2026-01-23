//
//  ODBCLogin.h
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

#import <Cocoa/Cocoa.h>
#import "ODBCConnection.h"

@interface ODBCLogin : NSObject {
	IBOutlet NSWindow *loginPanel;
	IBOutlet NSTextField *loginUserName;
	IBOutlet NSSecureTextField *loginPassword;
    IBOutlet NSPopUpButton *connectionList;
	IBOutlet NSTextField *dialogLabel;
	IBOutlet NSImageView *loginIcon; // 92x92
	
	NSWindow *parentWindow;
	
	ODBCConnection *odbcConn;
	
	// add a variable for a default DSN that can be set by the programmer.
	NSString *defaultDSN;	
	NSString *defaultUser;
	NSString *defaultPassword;
	NSImage *loginImage;
}

- (void)beginModalLoginForWindow:(NSWindow *)parent;

- (IBAction)onCancel:(id)sender;
- (IBAction)onLogin:(id)sender;
- (IBAction)onHelp:(id)sender;

- (BOOL)isConnected;

- (ODBCConnection *)connection;

- (NSString *)datasourceFilter;
- (void) setDatasourceFilter:(NSString *)value;

- (void)setDefaultDSN:(NSString *)value;
- (NSString *)defaultDSN;

- (void)setDefaultUser:(NSString *)value;
- (NSString *)defaultUser;

- (void)setDefaultPassword:(NSString *)value;

- (void)setIcon:(NSImage *)value;

- (void)onConnectionCompleted:(NSNotification *)aNotification;

@end

@interface NSObject (ODBCKitDelegateMethods)

- (id)loginCompleted:(ODBCConnection *)connection;

@end
