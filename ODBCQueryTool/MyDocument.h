//
//  MyDocument.h
//  ODBCQueryTool
//
//  Created by Andy Satori on 8/6/06.
//  Copyright Druware Software Designs. 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ODBCKit.h>
#import "DataSource.h"
#import "SchemaDataSource.h"

#define USE_ASYNC_COMMAND 1

@interface MyDocument : NSDocument <NSToolbarDelegate, NSTextViewDelegate>
{
	IBOutlet NSWindow		*documentWindow;
	IBOutlet NSTextView		*query;
	IBOutlet NSTableView	*resultsTable;
	IBOutlet NSProgressIndicator *working;
	IBOutlet NSTextField	*status;
	IBOutlet NSScrollView	*scrollview;
	IBOutlet NSImageView	*infoImage;
	IBOutlet NSOutlineView  *schemaSourceList;

	NSString				*fileContent;
	NSData					*fileData;
	ODBCLogin				*login;
	ODBCConnection			*conn;
	DataSource				*dataSource;
	SchemaDataSource		*schemaData;
	
	NSString				*delimiters;
	NSArray					*keywords;
	NSArray					*additionalKeywordsTSQL;
	
	NSColor					*keywordColor;
	NSColor					*tableNameColor;
	NSColor					*operatorColor;
	NSColor					*commentColor;
}

-(IBAction)onConnect:(id)sender;
-(IBAction)onExecuteQuery:(id)sender;

-(IBAction)onExportResults:(id)sender;

-(void)setDocumentWindowTitle;

@end
