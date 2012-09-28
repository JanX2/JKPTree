//
//  treeWalker.m
//
//  Copyright (C) 2007 David L Parsons
//  Copyright (c) 2012 Jan Weiß
//	Based on “dumptree.c”; part of “Discount” by David L Parsons. 
//  Ported to Obj-C by Jan Weiß. 
//
//  Released under the BSD software licence.
//

#import "NSObject+JXCustomDescription.h"

#import "JXFrame.h"

static void
pushPrefix(int indent, unichar c, NSMutableArray *stack)
{
    JXFrame *frame = [JXFrame frameWithIndent:indent unichar:c];
    [stack addObject:frame];
}


NS_INLINE void
popPrefix(NSMutableArray *stack)
{
    [stack removeLastObject];
}


static void
changePrefix(NSMutableArray *stack, unichar c)
{
    unichar ch;
	
    if (stack.count == 0)  return;
	
	JXFrame *frame = [stack lastObject];
    ch = frame.unichar;
	
    if ( ch == '+' || ch == '|' ) {
		frame.unichar = c;
	}
}


static NSUInteger
printPrefix(NSMutableArray *stack, NSMutableString *out)
{
    NSUInteger length = out.length;
	unichar c;
	
	NSUInteger stackCount = stack.count;
    if (stackCount == 0)  return 0;
	
	JXFrame *frame = [stack lastObject];
    c = frame.unichar;
	
    if ( c == '+' || c == '-' ) {
		[out appendFormat:@"--%C", c];
		frame.unichar = (c == '-') ? ' ' : '|';
    }
    else {
		for (NSUInteger i = 0; i < stackCount; i++ ) {
			if (i > 0) {
				[out appendString:@"  "];
			}
			frame = [stack objectAtIndex:i];
			c = frame.unichar;
			[out appendFormat:@"%*s%C", frame.indent + 2, " ", c];
			if ( c == '`' ) {
				frame.unichar = ' ';
			}
		}
	}
	
	[out appendString:@"--"];
	
	length = out.length - length;
	return length;
}


static void
dumpTree(CFTreeRef currentNode, id locale, NSMutableArray *stack, NSMutableString *out)
{
    while (currentNode != NULL) {
		CFTreeRef nextSiblingNode = CFTreeGetNextSibling(currentNode);
		
		if (nextSiblingNode == NULL) {
			changePrefix(stack, '`');
		}
		
		NSUInteger prefixLength = printPrefix(stack, out);
		NSUInteger nextIndentationLevel = ((prefixLength + 2) / 4) + 1;
		
		CFTreeContext theContext;
		CFTreeGetContext(currentNode, &theContext);
		id contentObject = (id)theContext.info;
		NSString *contentObjectDescription = [NSString stringWithFormat:@"[%@]",
											  [contentObject jx_descriptionWithLocale:locale
																			   indent:nextIndentationLevel
																		   isIndented:NULL]];
		[out appendString:contentObjectDescription];
		int d = contentObjectDescription.length;
		
		CFTreeRef firstChildNode = CFTreeGetFirstChild(currentNode);
		if (firstChildNode != NULL) {
			BOOL hasSibling = (CFTreeGetNextSibling(firstChildNode) != NULL);
			pushPrefix(d, (hasSibling ? '+' : '-'), stack);
			dumpTree(firstChildNode, locale, stack, out);
			popPrefix(stack);
		}
		else {
			[out appendString:@"\n"];
		}
		currentNode = nextSiblingNode;
    }
}


void makeTreeDescription(CFTreeRef rootNode, id locale, NSMutableString *out, NSUInteger indentationDepth, NSString *title)
{
    NSMutableArray *stack = [[NSMutableArray alloc] init];
			
	[out appendString:title];
	indentationDepth += title.length;
	
	BOOL hasSibling = (CFTreeGetNextSibling(rootNode) != NULL);
	pushPrefix(indentationDepth, (hasSibling ? '+' : '-'), stack);
	dumpTree(rootNode, locale, stack, out);
	
	[stack release];
}
