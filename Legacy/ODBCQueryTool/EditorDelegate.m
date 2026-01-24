//
//  EditorDelegate.m
//  Query Tool for Postgres
//
//  Created by Andy Satori on 9/25/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

// SQL Comments:
//   -- single line
//   # single line (MySQL)
//   /* */ multi-line


// SQL Literals:
//   ' string
//   " string 
//   [] quoted identifier

#import "EditorDelegate.h"

@implementation MyDocument (MyDocumentEditor)

#pragma mark Utility Functions
#pragma mark Syntax Match Functions

// checks the string to see if it matches one of the known table names
- (BOOL)isValueTablename:(NSString *)value
{
    // make sure we got something (redundant, but better safe...)
    if (value == nil) { return NO; }
    if ([value length] == 0) { return NO; }
    
    // trim it and make sure we stil have something
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedValue length] == 0) { return NO; }

    // and make sure we have something to test it against
	if (schemaData == nil) { return NO; }
	if ([schemaData tableNames] == nil) { return NO; }
	
    // ok, brute force it
	int x;
	for (x = 0; x < [[schemaData tableNames] count]; x++)
	{
		NSString *tableName = (NSString *)[[schemaData tableNames] objectAtIndex:x];
		if ([tableName caseInsensitiveCompare:trimmedValue] == NSOrderedSame)
		{
			return YES;
		}
	}
	return NO;
}

// checks the string to see if it matches one of the known SQL keywords
- (BOOL)isValueKeyword:(NSString *)value
{
    // make sure we got something (redundant, but better safe...)
    if (value == nil) { return NO; }
    if ([value length] == 0) { return NO; }
    
    // trim it and make sure we stil have something
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedValue length] == 0) { return NO; }
    
    // and make sure we have something to test it against
	if (schemaData == nil) { return NO; }
	if ([schemaData tableNames] == nil) { return NO; }
	
    int x;
    for (x = 0; x < [keywords count]; x++)
	{
		NSString *keyword = (NSString *)[keywords objectAtIndex:x];
		if ([keyword caseInsensitiveCompare:trimmedValue] == NSOrderedSame)
		{
			return YES;
		}
	}
	return NO;	
}

// compares a single char against the list of SQL delimeters
- (BOOL)isCharacterDelimiter:(char)value
{
	if (delimiters == nil)
	{
		delimiters = @" ,.![]();:'\"\t\r\n+=&<>/*-";
	}	
	
	NSRange loc;
	loc = [delimiters rangeOfString:[NSString stringWithFormat:@"%c", value]];
	if (loc.location == NSNotFound) 
	{
		return NO;
	}
	return YES;
}

// compares a single char against the list of SQL newlines
- (BOOL)isCharacterNewLine:(char)value
{
	NSString *lineDelimiters = @"\r\n"; 
	NSRange loc;
	loc = [lineDelimiters rangeOfString:[NSString stringWithFormat:@"%c", value]];
	if (loc.location == NSNotFound) 
	{
		return NO;
	}
	return YES;
}

#pragma mark Syntax Parsing Elements

- (void)colorRange:(NSRange)rangeToColor
{
	// loop through the range, breaking at each delimiter to set the attributes
	NSRange rangeOfWord;
	rangeOfWord.location = rangeToColor.location;
    
    long i;
	for (i = rangeToColor.location; i < (rangeToColor.location + rangeToColor.length); i++) 
	{
		// break on delimiters
		if ([self isCharacterDelimiter:[[query string] characterAtIndex:i]]) // needs to be altered to 'delimiter'
		{
			rangeOfWord.length = i - rangeOfWord.location;
			[self setAttributesForWord:rangeOfWord];
			rangeOfWord.location = i;
			rangeOfWord.length = 0;
		}
	}
	
	rangeOfWord.length = i - rangeOfWord.location;
	[self setAttributesForWord:rangeOfWord];
}

- (void)setAttributesForWord:(NSRange)rangeOfCurrentWord
{
	// set the attributes of the string 
	NSTextStorage *ts = [query textStorage];
	
	// keywords
	//	NSColor *keywordColor = [NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 1.0 alpha: 1.0];
	NSDictionary *keywordAtts = [NSDictionary dictionaryWithObject:keywordColor
															forKey:NSForegroundColorAttributeName];
	//NSColor *tableColor = [NSColor colorWithCalibratedRed: 1.0 green: 0.2 blue: 1.0 alpha: 1.0];
	NSDictionary *tableAtts = [NSDictionary dictionaryWithObject:tableNameColor
															forKey:NSForegroundColorAttributeName];

	// color the word
	[[query layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:rangeOfCurrentWord];
	
	if ([self isValueKeyword:[[ts attributedSubstringFromRange:rangeOfCurrentWord] string]])
	{
		[[query layoutManager] setTemporaryAttributes:keywordAtts forCharacterRange:rangeOfCurrentWord];
	}
	
	if ([self isValueTablename:[[ts attributedSubstringFromRange:rangeOfCurrentWord] string]])
	{
		[[query layoutManager] setTemporaryAttributes:tableAtts forCharacterRange:rangeOfCurrentWord];
	}
}

# pragma mark Edit View Notification Handlers

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	/* scanning logic is as follows:
	 *   1. is the current input text part of a comment
	 *   2. is the current input text part of a string literal
	 *   3. is the current input text a keyword
	 *   4. is the current input text a table name or active field name 
	 *      color it accordingly
	 */
	
	// based upon the current locatiodn, scan forward and backward to the nearest
	// delimiter and highlight the current word based upon that delimiter	
	NSTextStorage *ts = [query textStorage];
	
	NSRange rangeOfEdit = [ts editedRange];
	NSRange rangeToColor = [ts editedRange];
	
	// validate the range and exit if the range makes no sense
	if (rangeOfEdit.location == NSNotFound) {
		return;
	}
	if (rangeOfEdit.length == 0) {
		return;
	}
	
	// note: this particular sanity check may have performance concerns if the
	// document is very long and the user selects all.  it needs to be tested 
	// as the colorRange implementation expands.
	if (rangeOfEdit.length > 1) {
		[self colorRange:rangeOfEdit];
		return;
	}
	
	// the range of the edit is just 1 character.  unless that character is in 
	// our delimiter set then we really don't care and should not do any coloring
	
	// our delimiter characters are tab, cr, lf, (, ), [, ], ;, ", ', space
	long i = rangeOfEdit.location;
	
	if (![self isCharacterDelimiter:[[ts string] characterAtIndex:i]]) {
		// do not do anything on non-delimiter chars.
		return;
	}
	
	// if the character is in our delimiter set then we need to do some processing
	// to determine the appropriate range to select and color before we call 
	// colorRange on it.
	

	// for the moment, we will simply scan to the beginning of the current line.
	if (i >= [[ts string] length]) { i = [[ts string] length] - 1; }
	
	i--;
	if (i < 0) { return; }
	char currentCharacter = [[ts string] characterAtIndex:i];
	while ([self isCharacterNewLine:currentCharacter] == NO) {
		if (i < 0) { break; }
		currentCharacter = [[ts string] characterAtIndex:i];
		i--;
	}
	if (i < 0) { i = 0; }
	
	// if the last item in the range is a '*/' then this is the close of a 
	// multi-line comment, and the rangeToColor needs to go back to the opening
	// '/*' to do a proper coloring.
	rangeToColor.location = i;
	rangeToColor.length = rangeOfEdit.location - rangeToColor.location;
	
	// if the edited range contains no delimiters...
	[self colorRange:rangeToColor];
	[self updateChangeCount:NSChangeDone]; 
}

@end
