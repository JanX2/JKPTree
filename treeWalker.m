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
@property (nonatomic, readwrite) unichar c;

+ (id)frameWithIndent:(int)theIndent c:(unichar)theC;
- (id)initWithIndent:(int)theIndent c:(unichar)theC;

@end


@implementation JXFrame

@synthesize indent = _indent;
@synthesize c = _c;

+ (id)frameWithIndent:(int)theIndent c:(unichar)theC;
{
    id result = [[[self class] alloc] initWithIndent:theIndent c:theC];
	
    return [result autorelease];
}

- (id)initWithIndent:(int)theIndent c:(unichar)theC
{
    self = [super init];
	
    if (self) {
        _indent = theIndent;
        _c = theC;
    }
	
    return self;
}
@end



static void
pushpfx(int indent, unichar c, NSMutableArray *sp)
{
    JXFrame *frame = [JXFrame frameWithIndent:indent c:c];
    [sp addObject:frame];
}


static void
poppfx(NSMutableArray *sp)
{
    [sp removeLastObject];
}


static void
changepfx(NSMutableArray *sp, unichar c)
{
    unichar ch;
	
    if (sp.count == 0)  return;
	
	JXFrame *frame = [sp lastObject];
    ch = frame.c;
	
    if ( ch == '+' || ch == '|' ) {
		frame.c = c;
	}
}


static void
printpfx(NSMutableArray *sp, NSMutableString *out)
{
    unichar c;
	
	NSUInteger stackCount = sp.count;
    if (stackCount == 0)  return;
	
	JXFrame *frame = [sp lastObject];
    c = frame.c;
	
    if ( c == '+' || c == '-' ) {
		[out appendFormat:@"--%C", c];
		frame.c = (c == '-') ? ' ' : '|';
    }
    else {
		for (NSUInteger i = 0; i < stackCount; i++ ) {
			if (i > 0) {
				[out appendString:@"  "];
			}
			frame = [sp objectAtIndex:i];
			c = frame.c;
			[out appendFormat:@"%*s%C", frame.indent + 2, " ", c];
			if ( c == '`' ) {
				frame.c = ' ';
			}
		}
	}
	
	[out appendString:@"--"];
}


static void
dumptree(CFTreeRef currentNode, NSMutableArray *sp, NSMutableString *out)
{
    while (currentNode != NULL) {
		CFTreeRef nextSiblingNode = CFTreeGetNextSibling(currentNode);
		
		if (nextSiblingNode == NULL) {
			changepfx(sp, '`');
		}
		
		printpfx(sp, out);
		
		CFTreeContext theContext;
		CFTreeGetContext(currentNode, &theContext);
		id contentObject = (id)theContext.info;
		NSString *contentObjectDescription = [NSString stringWithFormat:@"[%@]", [contentObject description]];
		[out appendString:contentObjectDescription];
		int d = contentObjectDescription.length;
		
		CFTreeRef firstChildNode = CFTreeGetFirstChild(currentNode);
		if (firstChildNode != NULL) {
			BOOL hasSibling = (CFTreeGetNextSibling(firstChildNode) != NULL);
			pushpfx(d, (hasSibling ? '+' : '-'), sp);
			dumptree(firstChildNode, sp, out);
			poppfx(sp);
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
	pushpfx(title.length, (hasSibling ? '+' : '-'), stack);
	dumptree(rootNode, stack, out);
	
	[stack release];
}
