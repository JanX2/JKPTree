//
//  JXFrame.m
//
//  Created by Jan on 28.09.12.
//  Copyright 2012-2014 Jan Weiß
//
//  Released under the BSD software licence.
//

#import "JXFrame.h"

#import "JXArcCompatibilityMacros.h"

@implementation JXFrame

@synthesize indent = _indent;
@synthesize unichar = _c;

+ (instancetype)frameWithIndent:(int)theIndent unichar:(unichar)theUnichar;
{
    id result = [[[self class] alloc] initWithIndent:theIndent unichar:theUnichar];
	
    return JX_AUTORELEASE(result);
}

- (instancetype)initWithIndent:(int)theIndent unichar:(unichar)theUnichar
{
    self = [super init];
	
    if (self) {
        _indent = theIndent;
        _c = theUnichar;
    }
	
    return self;
}
@end
