//
//  JXFrame.m
//  AttributedStringDumper
//
//  Created by Jan on 28.09.12.
//
//

#import "JXFrame.h"

@implementation JXFrame

@synthesize indent = _indent;
@synthesize unichar = _c;

+ (id)frameWithIndent:(int)theIndent unichar:(unichar)theUnichar;
{
    id result = [[[self class] alloc] initWithIndent:theIndent unichar:theUnichar];
	
    return [result autorelease];
}

- (id)initWithIndent:(int)theIndent unichar:(unichar)theUnichar
{
    self = [super init];
	
    if (self) {
        _indent = theIndent;
        _c = theUnichar;
    }
	
    return self;
}
@end
