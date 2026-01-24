//
//  MyDocument.m
//  ODBCQueryTool
//
//  Created by Andy Satori on 8/6/06.
//  Copyright Druware Software Designs 2006 . All rights reserved.
//

#import "MyDocument.h"

#import "MyDocumentToolbar.h"
#import "EditorDelegate.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        
		// init the keyword arrays used for syntax highlighting
		NSBundle *bundleApp = [NSBundle mainBundle];
		NSString *pathToSqlPlist = [bundleApp pathForResource:@"sql" ofType:@"plist"];
		NSDictionary *sqlHighlights = [[NSDictionary alloc] initWithContentsOfFile:pathToSqlPlist];
        keywords = [[NSArray alloc] initWithArray:[sqlHighlights objectForKey:@"keywords"]];

		//NSString *temp = [[[NSString alloc] 
		//initWithString:@"select from where order group by asc desc insert into delete drop create alter table procedure view function values"] autorelease];
		//keywords = [[NSArray alloc] initWithArray:[temp componentsSeparatedByString:@" "]];
		
		// baseDataTypes
		
		// additionalKeywordsTSQL
		// additionalKeywordsPLSQL
		// additionalKeywordsPLPGSQLa
		
		keywordColor = [NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 1.0 alpha: 1.0];
		
		tableNameColor = [NSColor colorWithCalibratedRed: 1.0 green: 0.2 blue: 0.2 alpha: 1.0];

		schemaData = nil;
		login = nil;
    }
    return self;
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	
	NSFont *fixedFont;
	NSTextContainer *textContainer;
	NSSize  theSize;
	
	fixedFont = [NSFont fontWithName:@"Menlo Regular" size:11];
	[query setFont:fixedFont];
    query.automaticQuoteSubstitutionEnabled = NO;
	
	textContainer = [query textContainer];
    theSize = [textContainer containerSize];
    theSize.width = 1.0e7;
    [textContainer setContainerSize:theSize];
    [textContainer setWidthTracksTextView:NO];

	[documentWindow makeFirstResponder: query];
	
	dataSource = [[DataSource alloc] init];
	[resultsTable setDataSource:dataSource];
	
	[self setupToolbar];
	
	// set up the coloring delegate
	[query setDelegate:self];
    
    // if the window was opened with a file passed to it, copy the contents
    // into the window, and color it
	if (fileContent != nil)  {
		[query setString:fileContent];
		[self colorRange:NSMakeRange(0, [fileContent length])];
		[self updateChangeCount:NSChangeCleared];
	}
	
    // and then fire up the connection dialog
    // FIXME: MSM 20-Jun-12: this should be wrapped in a pref
	[self performSelector:@selector(onConnect:) withObject:self afterDelay:0.0];
    
    // and title the window
	[self setDocumentWindowTitle];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    
    // For applications targeted for Tiger or later systems, you should use the new Tiger API -dataOfType:error:.  In this case you can also choose to override -writeToURL:ofType:error:, -fileWrapperOfType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	return [[query string] dataUsingEncoding:NSASCIIStringEncoding];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    
    // For applications targeted for Tiger or later systems, you should use the new Tiger API readFromData:ofType:error:.  In this case you can also choose to override -readFromURL:ofType:error: or -readFromFileWrapper:ofType:error: instead.
	[query setString:[[NSString alloc] initWithBytes:[data bytes]
                                               length:[data length]
                                             encoding:NSASCIIStringEncoding]];
    
    return YES;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
	fileContent = [[NSString alloc] initWithContentsOfFile:fileName];
	return fileContent != nil;
}

- (IBAction)onConnect:(id)sender
{
    // there are three cases here:
    //        conn == nil, so clicking the connect button means "open connection"
    //        conn != nil but is disconnected, which means "re-open connection"
    //        conn != nil and is connected, which means "disconnect"
    
    // check for the disconnect case
	if (conn != nil && [conn isConnected]) {
        
        // release the connection
        conn = nil;
        [status setStringValue:@"Connection closed."];
        
        // clear the schema
        if (schemaData != nil) {
            schemaData = nil;
        }
        [schemaSourceList setDataSource:nil];

        return;
    }
    
    // now the reconnection case, just dispose the existing (failed) connection and continue
	if (conn != nil) {
		conn = nil;
	}
	
    // now the conn is gone, so we continue by releasing any existing login...
	if (login != nil) {
		login = nil;
	}
    
    // and then start the login process
	login = [[ODBCLogin alloc] init];
	[login beginModalLoginForWindow:documentWindow]; 	
}

- (id)loginCompleted:(ODBCConnection *)connection
{
    // This needs to be restructured to better deal with calling the UI thread
    
    // the connection object will be pulled down if the user clicked Cancel
	if (connection == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->status setStringValue:@"Connection cancelled."];
        });
		return nil;
	}
	
    // otherwise let's retain it for future reference
	conn = connection;
	
    // check for errors and report them
	if (![conn isConnected]) {
        NSMutableString* currentStatus = [[NSMutableString alloc] init];

        // if there was any error, put it into the status area
        NSString *err = [conn lastError];
		if (err != nil && [err length] > 0) {
            currentStatus.string = err;

            // but that code might be too long to be useful, so let's try parsing it down a bit...
            // FIXME: MSM 15-Jun-12: did I handle memory correctly here?
            NSRange pos = [err rangeOfString:@"Error: "];
            if (pos.length > 0) {
                NSString *shtErr = [err substringFromIndex:(pos.location + pos.length)];
                currentStatus.string = [NSString stringWithFormat:@"Connecton failed with error: %@", shtErr];
            }
		}
        // if there was no error, report a generic problem
        else {
            currentStatus.string = @"Connection failed, no error reported.";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [status setStringValue:currentStatus];
        });

        // and return nil any time the connection was not opened properly
		return nil;
	}
    
    NSMutableString* currentStatus = [NSMutableString stringWithCapacity:255];

    
    // update the display to show the connection status
    NSString *user = [conn userName];
    if ([user length] == 0) { user = @"<none>"; }
    
    currentStatus.string = [NSString stringWithFormat:@"Connected via DSN '%@' as user '%@'. Note: no database is selected.", [conn dsn], user];

    // if we attached to a default catalog, mention that too
    NSString *cat = [conn database];
    if (cat != nil && [cat length] > 0) {
        currentStatus.string = [NSString stringWithFormat:@"Connected via DSN '%@' to database '%@' as user '%@'.", [conn dsn], cat, user];
    }
    
	// build the schema and display it in the schema browser
	schemaData = [[SchemaDataSource alloc] initWithConnection:conn];
	[schemaSourceList setDataSource:[schemaData rootNode]];
	
	login = nil;
    
    // [connection setDefaultEncoding:NSUTF8StringEncoding];
	[connection setDefaultEncoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setDocumentWindowTitle];
        [self->status setStringValue:currentStatus];
    });
	
	return nil;
}

// execute the current query on the current database
- (IBAction)onExecuteQuery:(id)sender
{
    // start timing...
    NSDate *start = [NSDate date];
    
    // clear any existing status display
    [status setStringValue:@""];

    // check to make sure we're connected
    if (conn == nil) {
        [status setStringValue:@"You are not connected to a data source."];
        return; 
    }
	if (![conn isConnected]) {
        [status setStringValue:@"You are not connected to a data source."];
        return; 
    }
    
    // see if there is a query to run, and what it is - either the selected text or everything
	NSString *sql;
	if ([query selectedRange].length > 0) {
		sql = [[query string] substringWithRange:[query selectedRange]];
	} else {
		sql = [query string];
	}
	
	if ([sql length] == 0) {
		[status setStringValue:@"Cannot execute an empty command."];
		return;
	}

    // start the busy animation and update the status bar
    [working startAnimation:sender];
	[status setStringValue:@"Executing query."];
    
	// clear any cached column information
	[dataSource clear];

    // and now clear out any previous results
	long i;
	for (i = [[resultsTable tableColumns] count] - 1; i >= 0; i--) {
		[resultsTable removeTableColumn:(NSTableColumn *)[[resultsTable tableColumns] objectAtIndex:i]];
	}
		
	// now save out the existing catalog name, if any, so we can see if it changes
    NSString *oldCat = [conn database];
	
    // ok, start the query
	ODBCRecordset *rs = [conn open:sql];
    
    // stop the timer, calculate the elapsed time, and format it nicely
    // note the lack of a way to do this with NSDateFormatter
    NSDate *stop = [NSDate date];
    NSTimeInterval duration = [stop timeIntervalSinceDate:start];
//    long sec = (long)duration % 60;    // divide by 60 and trunc
//    double mil = duration * 1000.0;   
    NSString *elapsed = [[NSString alloc] initWithFormat:@"%02.4f", duration];

	// here we roll over the columns and try to find a useful width for display
    if (rs != nil) {
		long x = 0;
		for (x = 0; x < [[rs columns] count]; x++) {
			ODBCColumn *column = [[rs columns] objectAtIndex:x];
			NSTableColumn *tc = [[NSTableColumn alloc] init];
			[tc setIdentifier:[NSString stringWithFormat:@"%ld", x]];
			[[tc headerCell] setStringValue:[column name]];
			
			int charWidth = 8; // this is a placeholder, it will need to be 
			                   // adjusted to be the average width of a 
			                   // character in the current font.  For the 
			                   // moment, '8' will have to do.
            
			if ([column size] > 1) {
				[tc setWidth:[column size] * charWidth];
				if ([[column name] length] * charWidth > [tc width]) {
					[tc setWidth:[[column name] length] * charWidth];
				}
			} else {
				[tc setWidth:[[column name] length] * charWidth];
			}
			[resultsTable addTableColumn:tc];
		}
		
		while (![rs isEOF]) {
			long x = 0;
			NSMutableDictionary *dict = [dataSource addItem];
			for (x = 0; x < [[rs columns] count]; x++) {
				[dict setValue:[[rs fieldByIndex:x] asString]
						forKey:[NSString stringWithFormat:@"%ld", x]];
			}
			[rs moveNext];
		}
		[rs close];
		[resultsTable reloadData]; 
        
        long rc = [rs rowCount];
        if (rc > 0) {
            [status setStringValue:[NSString stringWithFormat:@"Query completed, %lu returned in %@ sec.", rc, elapsed]];
        } else {
            [status setStringValue:[NSString stringWithFormat:@"Query completed in %@ sec.", elapsed]];
        }
	} else {
		[status setStringValue:@""];
		if ([conn lastError] != nil) {
			[status setStringValue:[conn lastError]];
		}
	}
    
    // now get the new database name, and see if it's changed during the call
    // if it has, we want to update the schema display
    NSString *newCat = [conn database];
    if (newCat != nil && ![newCat isEqualToString:oldCat]) {
        [status setStringValue:[NSString stringWithFormat:@"Query completed, database changed to '%@'.", [conn database]]];

        // clear out the old schema and it's display
        if (schemaData != nil) {
            schemaData = nil;
        }
        [schemaSourceList setDataSource:nil];
        
        // now re-create it
        schemaData = [[SchemaDataSource alloc] initWithConnection:conn];
        [schemaSourceList setDataSource:[schemaData rootNode]];
    }
	
    // we're done, stop the animation
	[working stopAnimation:sender];
}

-(IBAction)onExportResults:(id)sender
{
	// select the file path
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	// set the allowed types (csv, txt)
	NSMutableArray *allowedTypes = [[NSMutableArray alloc] init];
	[allowedTypes addObject:@"csv"];
	[allowedTypes addObject:@"txt"];
	[allowedTypes addObject:@"json"];
    
	[panel setAllowedFileTypes:allowedTypes];
	[panel beginSheetModalForWindow:documentWindow
				  completionHandler:^(NSInteger returnCode) {
                      if (returnCode == NSFileHandlingPanelOKButton) {
                          
                          // the completion handler
                          [self savePanelDidEnd:panel
                                     returnCode:returnCode
                                    contextInfo:nil];
                      }
                  }];
	return;
}

-(void)setDocumentWindowTitle
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // default the window title
        NSString *docFileName = [documentWindow representedFilename];
        if (docFileName == nil) {
            docFileName = @"Untitled";
        }
        
        if ([docFileName length] == 0) {
            docFileName = @"Untitled";
        }
        
        [documentWindow setTitle:[NSString stringWithFormat:@"%@ (disconnected)", docFileName]];
        
        // but if we are connected, add that to the title
        if (conn != nil) {
            if ([conn isConnected]) {
                [documentWindow setTitle:[NSString stringWithFormat:@"%@ on %@@%@",
                                          docFileName, [conn userName], [conn dsn]]];
            }
        }
    });
}

- (IBAction)onBrowseForImage:(id)sender
{
	// use the file browser and get an image path
    NSSavePanel *panel = [NSSavePanel savePanel];
	[panel beginSheetModalForWindow:documentWindow
				  completionHandler:^(NSInteger returnCode) {
                      if (returnCode == NSFileHandlingPanelOKButton) {
                          
                          // the completion handler
                          [self savePanelDidEnd:panel
                                     returnCode:returnCode
                                    contextInfo:nil];
                      }
                  }];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet
			returnCode:(int)returnCode 
		   contextInfo:(void *)x
{
	// using the path, load and display the image.
	
	// set the imageData on the image using the displayed image.
    if (returnCode == NSOKButton)
    {
        NSURL *url = [sheet URL];
        
        NSString *file = [url absoluteString];
		NSMutableString *exportContent = [[NSMutableString alloc] init];
		NSArray *columns = [resultsTable tableColumns];
		
        // export as csv or txt
        
        if ([file rangeOfString:@"json"].location == NSNotFound)
        {
            int x = 0;
            for (x = 0; x < [columns count]; x++)
            {
                [exportContent appendFormat:@"\"%@\"", [[[columns objectAtIndex:x] headerCell] title]];
                if (x < [columns count])
                {
                    [exportContent appendString:@","];
                }
            }
            
            int i;
            [exportContent appendString:@"\n"];
            for (i = 0; i < [dataSource count]; i++)
            {
                NSDictionary *dict = [dataSource itemAtIndex:i];
                int y = 0;
                for (y = 0; y < [columns count]; y++)
                {
                    [exportContent appendFormat:@"\"%@\"", [dict valueForKey:[[columns objectAtIndex:y] identifier]]];
                    if (y < [columns count])
                    {
                        [exportContent appendString:@","];
                    }
                }
                [exportContent appendString:@"\n"];
            }
        } else {
            // export as JSON
            [exportContent appendString:@"["];
            
            int i;
            for (i = 0; i < [dataSource count]; i++)
            {
                NSDictionary *dict = [dataSource itemAtIndex:i];
                [exportContent appendString:@"{"];

                int x = 0;
                for (x = 0; x < [columns count]; x++)
                {
                    [exportContent appendFormat:@"\"%@\" : \"%@\"", [[[columns objectAtIndex:x] headerCell] title],
                        [dict valueForKey:[[columns objectAtIndex:x] identifier]]];
                    
                    
                    if (x < [columns count])
                    {
                        [exportContent appendString:@","];
                    }
                }

                if (i < [dataSource count])
                    [exportContent appendString:@"},\n"];
                else
                    [exportContent appendString:@"}\n"];
                    
            }
            [exportContent appendString:@"]"];
        }
        
		NSError *error;
		[exportContent writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
}

@end
