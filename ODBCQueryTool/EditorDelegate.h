//
//  EditorDelegate.h
//  Query Tool for Postgres
//
//  Created by Andy Satori on 9/25/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface MyDocument (MyDocumentEditor)

- (void)textViewDidChangeSelection:(NSNotification *)aNotification;
- (void)setAttributesForWord:(NSRange)rangeOfCurrentWord;
- (void)colorRange:(NSRange)rangeToColor;

/* in theory, the following should allow to triggr the syntax highlights early */
//- (NSRange *)textView:willChangeSelectionFromCharacterRange:toCharacterRange:


@end
