//
//  Document.m
//  Demo (Mac)
//
//  Created by Oliver Drobnik on 23.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "Document.h"

#import <WebKit/WebKit.h>

#import <DTMarkdownParser/DTMarkdownParser.h>
#import "SimpleHTMLGenerator.h"
#import "SimpleTreeGenerator.h"
#import "TagTreeOutlineController.h"

NSString * const	MarkdownDocumentType	= @"net.daringfireball.markdown";

@implementation Document {
	IBOutlet NSTextView *	_markdownTextView;
	IBOutlet WebView *		_previewWebView;
	
	NSFont *				_defaultFont;
	NSTextStorage *			_markdownText;
	
	IBOutlet TagTreeOutlineController *_tagTreeOutlineController;
	NSMutableArray *		_nodeTree;
	
	IBOutlet NSTextView *	_HTMLTextView;
	NSTextStorage *			_HTMLText;
}

- (id)init
{
    self = [super init];
	
    if (self) {
		_defaultFont = [NSFont fontWithName:@"Menlo"
									   size:18.0];

		_markdownText = [[NSTextStorage alloc] init];

		_HTMLText = [[NSTextStorage alloc] init];
	}
	
    return self;
}

- (NSString *)windowNibName
{
	return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	[[_markdownTextView layoutManager] replaceTextStorage:_markdownText];
	[_markdownTextView setFont:_defaultFont];
	
	_tagTreeOutlineController.tagNodes = _nodeTree;
	
	[[_HTMLTextView layoutManager] replaceTextStorage:_HTMLText];
	[_HTMLTextView setFont:_defaultFont];
	
	[[_previewWebView mainFrame] loadHTMLString:_HTMLText.string
										baseURL:[self fileURL]];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSData *data = nil;
	
	[_markdownTextView breakUndoCoalescing];
	
	data = [[_markdownText string] dataUsingEncoding:NSUTF8StringEncoding];
	
	return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL result;
	
	NSStringEncoding encoding = NSUTF8StringEncoding;
	
	NSString *markdownString = [[NSString alloc] initWithData:data
													 encoding:encoding];
	if (markdownString != nil) {
		[_markdownText replaceCharactersInRange:NSMakeRange(0, _markdownText.length)
									 withString:markdownString];
		
		DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:markdownString
																	options:DTMarkdownParserOptionGitHubLineBreaks];
		
		SimpleTreeGenerator *treeGenerator = [SimpleTreeGenerator new];
		parser.delegate = treeGenerator;
		
		BOOL couldParse = [parser parse];
		if (couldParse) {
			_nodeTree = treeGenerator.nodeTree;
		}
	
		SimpleHTMLGenerator *HTMLGenerator = [SimpleHTMLGenerator new];
		HTMLGenerator.title = self.displayName;
		parser.delegate = HTMLGenerator;
		
		BOOL couldParse2 = [parser parse];
		if (couldParse2) {
			NSMutableString *HTMLString = HTMLGenerator.HTMLString;
			[_HTMLText replaceCharactersInRange:NSMakeRange(0, _HTMLText.length)
										 withString:HTMLString];
		}
		
		// Parsing twice is pretty inefficient, but good enough for illustrative purposes.
		// We could implement a delegate object that distributes the delegate messages
		// to both SimpleTreeGenerator and SimpleHTMLGenerator.
		
		result = YES;
	}
	else {
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain
											code:NSFileReadInapplicableStringEncodingError
										userInfo:nil];
		}
		
		result = NO;
	}
	
	return result;
}

@end
