//
//  JXFrame.h
//  AttributedStringDumper
//
//  Created by Jan on 28.09.12.
//
//

#import <Foundation/Foundation.h>

@interface JXFrame : NSObject {
    int indent;
    unichar c;
}

@property (nonatomic, readwrite) int indent;
@property (nonatomic, readwrite) unichar unichar;

+ (id)frameWithIndent:(int)theIndent unichar:(unichar)theUnichar;
- (id)initWithIndent:(int)theIndent unichar:(unichar)theUnichar;

@end
