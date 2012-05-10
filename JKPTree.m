//
//  JKPTree.h
//  A simple CFTree Cocoa wrapper.
//
//  Created by Jamie Kirkpatrick on 02/04/2006.
//  Copyright 2006 JKP. All rights reserved.  
//
//  Released under the BSD software licence.
//

#import "JKPTree.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFTree.h>

//---------------------------------------------------------- 
//  JKPTreeCreateContext()
//---------------------------------------------------------- 
CFTreeContext JKPTreeCreateContext( id content )
{
    CFTreeContext context;
    memset( &context, 0, sizeof( CFTreeContext ) );
    context.info            = (void *) content;
    context.retain          = CFRetain;
    context.release         = CFRelease;
    context.copyDescription = CFCopyDescription;
    return context;
}

//---------------------------------------------------------- 
//  JXDescriptionForObject()
//---------------------------------------------------------- 
NSString *JXDescriptionForObject(id object, id locale, NSUInteger indentLevel, BOOL *isIndented)
{
	NSString *descriptionString;
	BOOL addQuotes = NO;
	
    if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
        *isIndented = YES;
        return [(id)object descriptionWithLocale:locale indent:indentLevel];
    }
    else {
        *isIndented = NO;
        if ([object respondsToSelector:@selector(descriptionWithLocale:)]) {
            descriptionString = [(id)object descriptionWithLocale:locale];
        }
        else {
            descriptionString = [object description];
        }
        
        NSRange range = [descriptionString rangeOfString:@" "];
        if (range.location != NSNotFound)
            addQuotes = YES;
        
        if (addQuotes)
            return [NSString stringWithFormat:@"\"%@\"", descriptionString];
        else
            return descriptionString;
    }
}

#pragma mark -

@interface JKPTree (Private)
- (id) initWithCFTree:(CFTreeRef)backing;
@end

#pragma mark -

@implementation JKPTree

//---------------------------------------------------------- 
//  treeWithContentObject:
//---------------------------------------------------------- 
+ (id) treeWithContentObject:(id)theContentObject;
{
    return [[[self alloc] initWithContentObject:theContentObject] autorelease];
}

//---------------------------------------------------------- 
//  initWithContentObject:
//---------------------------------------------------------- 
- (id) initWithContentObject:(id)theContentObject;
{
    self = [super init];
    if ( !self )
        return nil;
    
    CFTreeContext theContext = JKPTreeCreateContext( theContentObject );
    treeBacking = CFTreeCreate( kCFAllocatorDefault, &theContext );
    
    return self;
}

//---------------------------------------------------------- 
//  dealloc
//---------------------------------------------------------- 
- (void) dealloc;
{
    CFRelease( treeBacking );
    [super dealloc];
}


- (NSString *)description
{
	return [self descriptionWithLocale:nil indent:0 describeChildren:YES];
}

- (NSString *)descriptionWithChildren:(BOOL)describeChildren;
{
	return [self descriptionWithLocale:nil indent:0 describeChildren:describeChildren];
}

- (NSString *)descriptionWithLocale:(id)locale;
{
	return [self descriptionWithLocale:locale indent:0 describeChildren:YES];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;
{
	return [self descriptionWithLocale:locale indent:level describeChildren:YES];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level describeChildren:(BOOL)describeChildren;
{
	NSMutableString *treeDescription = [[NSMutableString alloc] init];
	
	CFIndex indentationDepth = (level+1) * 4;
	CFIndex indentationDepth2 = (level+2) * 4;
	
	UniChar indentation_chars[indentationDepth2];
    for (int i = 0; i < indentationDepth2; i++) {
        indentation_chars[i] = 0x0020; // Unicode code point of the space character.
    }
	
	//NSString *indentation2 = [NSMakeCollectable(CFStringCreateWithCharacters(kCFAllocatorDefault, (const UniChar *)&indentation_chars, indentationDepth2)) autorelease];
	NSString *indentation = [NSMakeCollectable(CFStringCreateWithCharacters(kCFAllocatorDefault, (const UniChar *)&indentation_chars, indentationDepth)) autorelease];
	
    BOOL isIndented = NO;
	NSString *thisDescription = JXDescriptionForObject(self.contentObject, locale, level+1, &isIndented);

    if (isIndented) {
        [treeDescription appendString:thisDescription]; 
    }
    else {
        [treeDescription appendFormat:
         @"%@%@,\n", 
         indentation, 
         thisDescription
         ];
    }

	if (describeChildren && self.childCount > 0) {
		[treeDescription appendFormat:@"%@%@ = (\n", indentation, @"children"];
		
        NSArray *allChildren = self.childNodes;
        id lastChild = [allChildren lastObject];
		
		for (id child in allChildren) {
			thisDescription = JXDescriptionForObject(child, locale, level+1, &isIndented);
            if (isIndented) {
                [treeDescription appendString:thisDescription]; 
            }
            else {
                [treeDescription appendFormat:@"%1$@%2$@\n", 
                 thisDescription,
                 (child == lastChild) ? @"" : @","];
            }
		}
		
		[treeDescription appendFormat:@"%@)\n", indentation];
	}
    
	return [treeDescription autorelease];
}

#pragma mark -
#pragma mark adding / removing children

//---------------------------------------------------------- 
//  addChildObject:
//---------------------------------------------------------- 
- (void) addChildObject:(id)childObject;
{
    CFTreeContext theContext = JKPTreeCreateContext( childObject );
    CFTreeRef childTree = CFTreeCreate( kCFAllocatorDefault, &theContext );
    CFTreeAppendChild( treeBacking, childTree );
    CFRelease( childTree );
}

//---------------------------------------------------------- 
//  addChildObject:atIndex:
//---------------------------------------------------------- 
- (void) addChildObject:(id)childObject atIndex:(NSUInteger)index;
{
    CFTreeContext theContext = JKPTreeCreateContext( childObject );
    CFTreeRef childTree = CFTreeCreate( kCFAllocatorDefault, &theContext );
    CFTreeRef precedingSibling = CFTreeGetChildAtIndex( treeBacking, (CFIndex) index - 1U );
    CFTreeInsertSibling( precedingSibling, childTree );
    CFRelease( childTree );
}

//---------------------------------------------------------- 
//  removeChildObject:
//---------------------------------------------------------- 
- (BOOL) removeChildObject:(id)childObject;
{
    // grab pointers to all the children...
    CFIndex childCount = CFTreeGetChildCount( treeBacking );
    CFTreeRef *children = (CFTreeRef *)malloc( childCount * sizeof( CFTreeRef ) );
    CFTreeGetChildren( treeBacking, children );
    
    // iterate over the children....if a child matches, then remove it and stop...
    BOOL result = NO;
    CFIndex i;
    for ( i = 0; i < childCount; i++ )
    {
        CFTreeRef child = children[i];
        CFTreeContext theContext;
        CFTreeGetContext( child, &theContext );
        
        // is this the node...?
        if ( ![childObject isEqual:(id)theContext.info] )
            continue;
        
        // we found it...
        result = YES;
        CFTreeRemove( child );
    }
    
    // cleanup and return result...
    free( children );
    return result;
}

//---------------------------------------------------------- 
//  removeChildObjectAtIndex: 
//---------------------------------------------------------- 
- (void) removeChildObjectAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
    CFTreeRemove( child );
}

//---------------------------------------------------------- 
//  removeAllChildren
//---------------------------------------------------------- 
- (void) removeAllChildren;
{
    CFTreeRemoveAllChildren( treeBacking);
}

#pragma mark -
#pragma mark examining the tree

//---------------------------------------------------------- 
//  root
//---------------------------------------------------------- 
- (JKPTree *) root;
{
    CFTreeRef root = CFTreeFindRoot( treeBacking );
    return [[[JKPTree alloc] initWithCFTree:root] autorelease];
}

//---------------------------------------------------------- 
//  parent
//---------------------------------------------------------- 
- (JKPTree *) parent;
{
    CFTreeRef parent = CFTreeGetParent( treeBacking );
    if ( parent != NULL )
        return [[[JKPTree alloc] initWithCFTree:parent] autorelease];
    return nil;
}

//---------------------------------------------------------- 
//  firstChild
//---------------------------------------------------------- 
- (JKPTree *) firstChild;
{
    CFTreeRef firstChild = CFTreeGetFirstChild( treeBacking );
    if ( firstChild != NULL )
        return [[[JKPTree alloc] initWithCFTree:firstChild] autorelease];
    return nil;
}

//---------------------------------------------------------- 
//  nextSibling
//---------------------------------------------------------- 
- (JKPTree *) nextSibling;
{
    CFTreeRef nextSibling = CFTreeGetNextSibling( treeBacking );
    if ( nextSibling != NULL )
        return [[[JKPTree alloc] initWithCFTree:nextSibling] autorelease];
    return nil;
}

//---------------------------------------------------------- 
//  childCount
//---------------------------------------------------------- 
- (NSUInteger) childCount;
{
    return (NSUInteger)CFTreeGetChildCount( treeBacking );
}

//---------------------------------------------------------- 
//  nodeAtIndex:
//---------------------------------------------------------- 
- (JKPTree *) nodeAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
    if ( child != NULL )
        return [[[JKPTree alloc] initWithCFTree:child] autorelease];
    return nil; 
}

//---------------------------------------------------------- 
//  childObjectAtIndex:
//---------------------------------------------------------- 
- (id) childObjectAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
    CFTreeContext theContext;
    CFTreeGetContext( child, &theContext );
    return (id)theContext.info;
}

//---------------------------------------------------------- 
//  allSiblings
//---------------------------------------------------------- 
- (NSArray *) allSiblingNodes;
{
    return [[self parent] childNodes];
}

//---------------------------------------------------------- 
//  allSiblingObjects
//---------------------------------------------------------- 
- (NSArray *) allSiblingObjects;
{
    return [[self parent] childObjects];
}

//---------------------------------------------------------- 
//  childNodes
//---------------------------------------------------------- 
- (NSArray *) childNodes;
{
    // grab pointers to all the children...
    CFIndex childCount = CFTreeGetChildCount( treeBacking );
    CFTreeRef *children = (CFTreeRef *)malloc( childCount * sizeof( CFTreeRef ) );
    CFTreeGetChildren( treeBacking, children );
    
    // iterate over the children wrapping each in turn and adding to the return array...
    NSMutableArray *childWrappers = [NSMutableArray arrayWithCapacity:childCount];
    CFIndex i;
    for ( i = 0; i < childCount; i++ )
    {
        JKPTree *child = [[JKPTree alloc] initWithCFTree:children[i]];
        [childWrappers addObject:child];
        [child release];
    }
    
    // cleanup and return result...
    free( children );
    return ( childCount ? [[childWrappers copy] autorelease] : nil );
}

//---------------------------------------------------------- 
//  childObjects
//---------------------------------------------------------- 
- (NSArray *) childObjects;
{
    // grab pointers to all the children...
    CFIndex childCount = CFTreeGetChildCount( treeBacking );
    CFTreeRef *children = (CFTreeRef *)malloc( childCount * sizeof( CFTreeRef ) );
    CFTreeGetChildren( treeBacking, children );
    
    // iterate over the children extracting contentObjects and adding to array...
    NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:childCount];
    CFIndex i;
    for ( i = 0; i < childCount; i++ )
    {
        CFTreeContext theContext;
        CFTreeGetContext( children[i], &theContext );
        if ( (id)theContext.info )
            [childObjects addObject:(id)theContext.info];
    }
    
    // cleanup and return result...
    free( children );
    return ( [childObjects count] ? [[childObjects copy] autorelease] : nil );
}

//---------------------------------------------------------- 
//  isLeaf
//---------------------------------------------------------- 
- (BOOL) isLeaf;
{
    return ( (NSUInteger)CFTreeGetChildCount( treeBacking ) ? NO : YES );
}

#pragma mark -
#pragma mark accessors

//---------------------------------------------------------- 
//  contentObject
//---------------------------------------------------------- 
- (id) contentObject;
{
    CFTreeContext theContext;
    CFTreeGetContext( treeBacking, &theContext );
    return (id)theContext.info;
}

//---------------------------------------------------------- 
//  setContentObject:
//---------------------------------------------------------- 
- (void) setContentObject: (id) theContentObject;
{
    CFTreeContext theContext = JKPTreeCreateContext( theContentObject );
    CFTreeSetContext( treeBacking, &theContext );
}


CFTreeRef getNextNodeFor(CFTreeRef currentNode) {
    CFTreeRef nextNode;
    
    // If the node has children, then next node is the first child
    nextNode = CFTreeGetFirstChild(currentNode);

    if ( nextNode == NULL ) {
        // If the node has a next sibling, then next node is the next sibling
        nextNode = CFTreeGetNextSibling( currentNode );
    }
    
    if ( nextNode == NULL ) {
        // There are no children, and no more siblings, so we need to get the next sibling of the parent.
        // If that is NULL, we need to get the next sibling of the grandparent, etc.
        CFTreeRef parent = CFTreeGetParent( currentNode );
        CFTreeRef node = NULL;
        while (parent != NULL) {
            CFTreeRef parentNextSibling = CFTreeGetNextSibling( parent );
            if (parentNextSibling != NULL) {
                node = parentNextSibling;
                break;
            }
            else {
                parent = CFTreeGetParent( parent );
            }
        }
        
        nextNode = node;
    }
    
    return nextNode;
}

#define FIRST_CALL          0
#define ENUMERATION_STARTED 1

#define NODE_ENTRY        0

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state 
                                   objects: (id *) stackbuf 
                                     count: (NSUInteger) len;
{
    // plan of action: extra[0] will contain pointer to node
    // that contains next object to iterate
    // because extra[0] is a long, this involves ugly casting
    if (state->state == FIRST_CALL)
    {
        CFTreeRef root = CFTreeFindRoot( treeBacking );
        
        // state FIRST_CALL means it's the first call, so get things set up
        // point somewhere that's guaranteed not to change
        // unless there are mutations
        state->mutationsPtr = (unsigned long *)root;
        
        // set up extra[0] to point to the head to start in the right place
        state->extra[NODE_ENTRY] = (long)root;
        
        // and update state to indicate that enumeration has started
        state->state = ENUMERATION_STARTED;
    }
    
    // pull the node out of extra[NODE_ENTRY]
    CFTreeRef currentNode = (CFTreeRef)state->extra[NODE_ENTRY];
    
    // if it's NULL then we're done enumerating, return 0 to end
    if (currentNode == NULL)  return 0;
    
    // otherwise, point itemsPtr at the node's value
    CFTreeContext theContext;
    CFTreeGetContext( currentNode, &theContext );
    state->itemsPtr = (id *)&(theContext.info);
    
    // update extra[NODE_ENTRY]
    //if (currentNode != NULL) // always true!
    
    CFTreeRef nextNode = getNextNodeFor(currentNode);
    
    state->extra[NODE_ENTRY] = (long)nextNode;
    
    // we're returning exactly one item
    return 1;
}


@end

#pragma mark -

@implementation JKPTree (Private)

//---------------------------------------------------------- 
//  initWithCFTree:
//---------------------------------------------------------- 
- (id) initWithCFTree:(CFTreeRef)backing;
{
    self = [super init];
    if ( !self )
        return nil;
    
    CFRetain( backing );
    treeBacking = backing;
    
    return self;
}

@end

