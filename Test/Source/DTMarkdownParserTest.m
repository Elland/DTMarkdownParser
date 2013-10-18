//
//  DTMarkdownParserTest.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 18.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTMarkdownParser.h"
#import "DTInvocationRecorder.h"
#import "DTInvocationTestFunctions.h"


@interface DTMarkdownParserTest : SenTestCase

@end

@implementation DTMarkdownParserTest
{
	DTInvocationRecorder *_recorder;
}

- (void)setUp
{
    [super setUp];
	
	_recorder = [[DTInvocationRecorder alloc] init];
	[_recorder addProtocol:@protocol(DTMarkdownParserDelegate)];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 
    [super tearDown];
}

- (void)performTest:(SenTestRun *)aRun
{
	// clear recorder before each test
	[_recorder clearLog];
	
	[super performTest:aRun];
}

- (DTMarkdownParser *)_parserForString:(NSString *)string
{
	DTMarkdownParser *parser = [[DTMarkdownParser alloc] initWithString:string];
	STAssertNotNil(parser, @"Should be able to create parser");
	
	assertThat(parser, is(notNilValue()));
	
	if (_recorder)
	{
		parser.delegate = (id<DTMarkdownParserDelegate>)_recorder;
	}
	
	return parser;
}

- (void)testStartDocument
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidStartDocument:), nil);
}

- (void)testEndDocument
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parserDidEndDocument:), nil);
}

- (void)testSimpleLine
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];

	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));

	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown");
}

- (void)testMultipleLines
{
	NSString *string = @"Hello Markdown\nA second line\nA third line";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"Hello Markdown\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A second line\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A third line");
}

- (void)testParagraphBeginEnd
{
	NSString *string = @"Hello Markdown";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"p");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"p");
}

- (void)testBlockquote
{
	NSString *string = @"> A Quote\n> With multiple lines\n";
	DTMarkdownParser *parser = [self _parserForString:string];
	
	BOOL result = [parser parse];
	assertThatBool(result, is(equalToBool(YES)));
	
	// there should be a one blockquote tag
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didStartElement:attributes:), @"blockquote");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:didEndElement:), @"blockquote");
	
	// test trimming off of blockquote prefix
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"A Quote\n");
	DTAssertInvocationRecorderContainsCallWithParameter(_recorder, @selector(parser:foundCharacters:), @"With multiple lines\n");

	// there should be only a single tag even though there are two \n
	NSArray *tagStarts = [_recorder invocationsMatchingSelector:@selector(parser:didStartElement:attributes:)];
	assertThatInteger([tagStarts count], is(equalToInteger(1)));

	NSArray *tagEnds = [_recorder invocationsMatchingSelector:@selector(parser:didEndElement:)];
	assertThatInteger([tagEnds count], is(equalToInteger(1)));
}

@end
