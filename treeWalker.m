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

@interface JXFrame : NSObject {
    int indent;
    unichar c;
}

@property (nonatomic, readwrite) int indent;
@property (nonatomic, readwrite) unichar unichar;

+ (id)frameWithIndent:(int)theIndent unichar:(unichar)theUnichar;
- (id)initWithIndent:(int)theIndent unichar:(unichar)theUnichar;

@end


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


static void
printPrefix(NSMutableArray *stack, NSMutableString *out)
{
    unichar c;
	
	NSUInteger stackCount = stack.count;
    if (stackCount == 0)  return;
	
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
}


static void
dumpTree(CFTreeRef currentNode, NSMutableArray *stack, NSMutableString *out)
{
    while (currentNode != NULL) {
		CFTreeRef nextSiblingNode = CFTreeGetNextSibling(currentNode);
		
		if (nextSiblingNode == NULL) {
			changePrefix(stack, '`');
		}
		
		printPrefix(stack, out);
		
		CFTreeContext theContext;
		CFTreeGetContext(currentNode, &theContext);
		id contentObject = (id)theContext.info;
		NSString *contentObjectDescription = [NSString stringWithFormat:@"[%@]", [contentObject description]];
		[out appendString:contentObjectDescription];
		int d = contentObjectDescription.length;
		
		CFTreeRef firstChildNode = CFTreeGetFirstChild(currentNode);
		if (firstChildNode != NULL) {
			BOOL hasSibling = (CFTreeGetNextSibling(firstChildNode) != NULL);
			pushPrefix(d, (hasSibling ? '+' : '-'), stack);
			dumpTree(firstChildNode, stack, out);
			popPrefix(stack);
		}
		else {
			[out appendString:@"\n"];
		}
		currentNode = nextSiblingNode;
    }
}


void makeTreeDescription(CFTreeRef rootNode, NSMutableString *out, NSString *title)
{
    NSMutableArray *stack = [[NSMutableArray alloc] init];
			
	[out appendString:title];
	
	BOOL hasSibling = (CFTreeGetNextSibling(rootNode) != NULL);
	pushPrefix(title.length, (hasSibling ? '+' : '-'), stack);
	dumpTree(rootNode, stack, out);
	
	[stack release];
}
