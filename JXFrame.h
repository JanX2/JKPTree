//
//  JXFrame.h
//  AttributedStringDumper
//
//  Created by Jan on 28.09.12.
//  Copyright 2012 Jan Weiß
//
//  Released under the BSD software licence.
//

#import <Foundation/Foundation.h>

@interface JXFrame : NSObject {
    int indent;
    unichar c;
}

@property (nonatomic, readwrite) int indent;
@property (nonatomic, readwrite) unichar unichar;

+ (instancetype)frameWithIndent:(int)theIndent unichar:(unichar)theUnichar;
- (instancetype)initWithIndent:(int)theIndent unichar:(unichar)theUnichar;

@end
