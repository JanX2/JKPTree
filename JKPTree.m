//
//  JKPTree.h
//  A simple CFTree Cocoa wrapper.
//
//  Created by Jamie Kirkpatrick on 02/04/2006.
//  Copyright 2006 JKP. All rights reserved.
//  Copyright 2012 Jan Weiß
//
//  Released under the BSD software licence.
//

#import "JKPTree.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFTree.h>

#import "JXArcCompatibilityMacros.h"

#import "NSObject+JXCustomDescription.h"

const BOOL nestedModeIsDefault = NO;

typedef struct __CFTree JKPTOpaqueNode;

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

NS_INLINE id getContentObject( CFTreeRef target )
{
    CFTreeContext theContext;
    CFTreeGetContext( target, &theContext );
    id content = JX_BRIDGED_CAST(id, theContext.info);
    return content;
}

#include "JKPTreeWalker.m"

//----------------------------------------------------------

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
    return JX_AUTORELEASE([[self alloc] initWithContentObject:theContentObject]);
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

+ (JKPTree *) treeWithOpaqueNode:(JKPTOpaqueNodeRef)treeNode;
{
    return JX_AUTORELEASE([[JKPTree alloc] initWithOpaqueNode:treeNode]);
}

- (JKPTree *) initWithOpaqueNode:(JKPTOpaqueNodeRef)treeNode;
{
    CFTreeRef tree = (CFTreeRef)treeNode;
    
    self = [super init];
    if ( !self )
        return nil;
    
    CFRetain( tree );
    treeBacking = tree;
    
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
    return [self descriptionWithLocale:nil indent:0 describeChildren:YES nestedMode:nestedModeIsDefault];
}

- (NSString *)descriptionWithChildren:(BOOL)describeChildren;
{
    return [self descriptionWithLocale:nil indent:0 describeChildren:describeChildren nestedMode:nestedModeIsDefault];
}

- (NSString *)descriptionWithLocale:(id)locale;
{
    return [self descriptionWithLocale:locale indent:0 describeChildren:YES nestedMode:nestedModeIsDefault];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;
{
    return [self descriptionWithLocale:locale indent:level describeChildren:YES nestedMode:nestedModeIsDefault];
}

- (NSString *)descriptionWithLocale:(id)locale
                             indent:(NSUInteger)level
                   describeChildren:(BOOL)describeChildren
                         nestedMode:(BOOL)nestedMode;
{
    NSString *indentationString = @"    ";
    NSUInteger indentationStringLength = 4;
    
    NSMutableString *treeDescription = [[NSMutableString alloc] init];
    
    if (nestedMode == NO) {
        makeTreeDescription(treeBacking, locale, treeDescription, (level * indentationStringLength), @"");
        return JX_AUTORELEASE(treeDescription);
    }

    NSUInteger indentationDepth = (level+1) * indentationStringLength;
    //NSUInteger indentationDepth2 = (level+2) * indentationStringLength;
    
    NSString *indentation = [@"" stringByPaddingToLength:indentationDepth withString:indentationString startingAtIndex:0];
    //NSString *indentation2 = [@"" stringByPaddingToLength:indentationDepth2 withString:indentationString startingAtIndex:0];
    
    BOOL isIndented = NO;
    NSString *thisDescription = [self.contentObject jx_descriptionWithLocale:locale indent:level+1 isIndented:&isIndented];

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
            thisDescription = [child jx_descriptionWithLocale:locale indent:level+1 isIndented:&isIndented];
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
    
    return JX_AUTORELEASE(treeDescription);
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
        id content = getContentObject(child);
        
        // is this the node...?
        if ( ![childObject isEqual:content] )
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
    return JX_AUTORELEASE([[JKPTree alloc] initWithCFTree:root]);
}

//---------------------------------------------------------- 
//  parent
//---------------------------------------------------------- 
- (JKPTree *) parent;
{
    CFTreeRef parent = CFTreeGetParent( treeBacking );
    if ( parent != NULL )
        return JX_AUTORELEASE([[JKPTree alloc] initWithCFTree:parent]);
    return nil;
}

//---------------------------------------------------------- 
//  firstChild
//---------------------------------------------------------- 
- (JKPTree *) firstChild;
{
    CFTreeRef firstChild = CFTreeGetFirstChild( treeBacking );
    if ( firstChild != NULL )
        return JX_AUTORELEASE([[JKPTree alloc] initWithCFTree:firstChild]);
    return nil;
}

//---------------------------------------------------------- 
//  nextSibling
//---------------------------------------------------------- 
- (JKPTree *) nextSibling;
{
    CFTreeRef nextSibling = CFTreeGetNextSibling( treeBacking );
    if ( nextSibling != NULL )
        return JX_AUTORELEASE([[JKPTree alloc] initWithCFTree:nextSibling]);
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
        return JX_AUTORELEASE([[JKPTree alloc] initWithCFTree:child]);
    return nil; 
}

//  childObjectAtIndex:
//---------------------------------------------------------- 
- (id) childObjectAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
    id content = getContentObject(child);
    return content;
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
        JX_RELEASE(child);
    }
    
    // cleanup and return result...
    free( children );
    return ( childCount ? JX_AUTORELEASE([childWrappers copy]) : nil );
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
        id content = getContentObject(children[i]);
        if ( content )
            [childObjects addObject:content];
    }
    
    // cleanup and return result...
    free( children );
    return ( [childObjects count] ? JX_AUTORELEASE([childObjects copy]) : nil );
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
    id content = getContentObject(treeBacking);
    return content;
}

//---------------------------------------------------------- 
//  setContentObject:
//---------------------------------------------------------- 
- (void) setContentObject: (id) theContentObject;
{
    CFTreeContext theContext = JKPTreeCreateContext( theContentObject );
    CFTreeSetContext( treeBacking, &theContext );
}


CFTreeRef getNextForwardNodeDepthFirstFor(CFTreeRef currentNode) {
    CFTreeRef nextNode;
    
    // If the node has a next sibling, then next node is the next sibling
    nextNode = CFTreeGetNextSibling( currentNode );
    
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

// Depth-first enumeration for CFTree
CFTreeRef getNextNodeDepthFirstFor(CFTreeRef currentNode) {
    CFTreeRef nextNode;
    
    // If the node has children, then next node is the first child
    nextNode = CFTreeGetFirstChild( currentNode );

    if (nextNode == NULL) {
        nextNode = getNextForwardNodeDepthFirstFor( currentNode );
    }
    
    return nextNode;
}

CFTreeRef getPreviousSibling(CFTreeRef currentNode) {
    CFTreeRef currentNodeParent = CFTreeGetParent(currentNode);
    if (currentNodeParent == NULL)  return NULL;
    
    CFIndex index = 0;
    CFTreeRef nextNode = CFTreeGetFirstChild(currentNodeParent);
    while (nextNode == NULL) {
        if (currentNode == nextNode) {
            break;
        }
        
        nextNode = CFTreeGetNextSibling(currentNode);
        index++;
    }
    
    if (index == 0) {
        return NULL;
    }
    else {
        return CFTreeGetChildAtIndex(currentNodeParent, index-1);
        
    }
}

CFTreeRef getLastChild(CFTreeRef currentNode) {
    CFIndex childCount = CFTreeGetChildCount(currentNode);
    
    if (childCount == 0) {
        return NULL;
    }
    else {
        return CFTreeGetChildAtIndex(currentNode, childCount-1);
    }
}

CFTreeRef getPreviousBackwardsNodeDepthFirstFor(CFTreeRef currentNode) {
    CFTreeRef prevNode = getPreviousSibling(currentNode);
    
    if (prevNode == NULL) {
        prevNode = CFTreeGetParent(currentNode);
    }

    return prevNode;
}

// Depth-first reverse enumeration for CFTree
CFTreeRef getPreviousNodeDepthFirstFor(CFTreeRef currentNode) {
    CFTreeRef prevNode;
    
    // If the node has a previous sibling,
    // then we need the last child of the last child of the last child etc.
    CFTreeRef previousSibling = getPreviousSibling(currentNode);
    
    if (previousSibling != NULL) {
        CFTreeRef previousSiblingLastChild = getLastChild(previousSibling);
        
        if (previousSiblingLastChild != NULL) {
            CFTreeRef lastChild = previousSiblingLastChild;
            CFTreeRef lastChildLast = getLastChild(lastChild);
            while (lastChildLast != NULL) {
                lastChild = lastChildLast;
                lastChildLast = getLastChild(lastChild);
            }
            
            return lastChild;
        }
        else {
            // The previous sibling has no children, so the previous node is simply the previous sibling.
            return previousSibling;
        }
    }

    // If there are no previous siblings, then the previous node is simply the parent.
    prevNode = CFTreeGetParent(currentNode);
    return prevNode;
}

#define FIRST_CALL          0
#define ENUMERATION_STARTED 1

#define NODE_ENTRY          0
#define END_NODE_ENTRY      1

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state 
                                   objects: (id *) stackbuf 
                                     count: (NSUInteger) len;
{
    // Plan of action: extra[NODE_ENTRY] will contain pointer to node
    // that contains the next object to iterate.
    // Because extra[NODE_ENTRY] is a long, this involves ugly casting.
    // We accumulate multiple nodes at once.
    if (state->state == FIRST_CALL)
    {
        // Point mutationsPtr somewhere that's guaranteed not to change
        // unless there are mutations.
        state->mutationsPtr = (unsigned long *)treeBacking;
        
        // Set up extra[NODE_ENTRY] to point to the root so that we start in the right place.
        state->extra[NODE_ENTRY] = (long)treeBacking;
        state->extra[END_NODE_ENTRY] = (long)getNextForwardNodeDepthFirstFor(treeBacking);
        
        // and update state to indicate that enumeration has started
        state->state = ENUMERATION_STARTED;
    }
    
    // Pull the node out of extra[NODE_ENTRY].
    CFTreeRef currentNode = (CFTreeRef)state->extra[NODE_ENTRY];
    CFTreeRef endNode = (CFTreeRef)state->extra[END_NODE_ENTRY];
    
    // If it's NULL then we're done enumerating, return 0 to end the enumeration.
    if (currentNode == NULL)  return 0;
    
    // Keep track of how many objects we iterated over so we can return that value.
    NSUInteger objCount = 0;
    
    // We'll be putting objects in stackbuf, so point itemsPtr to it.
    state->itemsPtr = stackbuf;
    
    // Loop through until either we fill up stackbuf or run out of nodes.
    while (currentNode != endNode && objCount < len)
    {
        // Fill current stackbuf location...
        id content = getContentObject(currentNode);
        *stackbuf++ = content;
        
        // ...move to the next node...
        currentNode = getNextNodeDepthFirstFor(currentNode);
        
        // ...and keep our count.
        objCount++;
    }
    
    // Update extra[NODE_ENTRY]
    state->extra[NODE_ENTRY] = (long)currentNode;
    
    return objCount;
}

CF_INLINE CFTreeRef getNextNodeWithOptions(CFTreeRef currentNode, JKPTEnumerationOptions opts)
{
    CFTreeRef nextNode;
    switch (opts) {
        case JKPTEnumerationReverse:
            nextNode = getPreviousNodeDepthFirstFor(currentNode);
            break;
            
        case JKPTEnumerationAncestors:
            nextNode = CFTreeGetParent(currentNode);
            break;
            
        default:
            nextNode = getNextNodeDepthFirstFor(currentNode);
            break;
    }
    
    return nextNode;
}

- (void)enumerateObjectsWithOptions:(JKPTEnumerationOptions)opts usingBlock:(void (^)(JKPTOpaqueNodeRef node, id nodeObj, id contentObj, BOOL *stop))block;
{
    CFTreeRef currentNode;
    CFTreeRef endNode;
    BOOL wantNodeObjects = !(opts & JKPTEnumerationNodeObjectNotRequired);
    NSUInteger switchOpts = opts & ~JKPTEnumerationNodeObjectNotRequired;
    
    switch (switchOpts) {
        case JKPTEnumerationReverse:
            currentNode = treeBacking;
            endNode = getPreviousBackwardsNodeDepthFirstFor(treeBacking);
            break;
            
        case JKPTEnumerationAncestors:
            currentNode = CFTreeGetParent(treeBacking);
            endNode = NULL;
            break;
            
        default:
            currentNode = treeBacking;
            endNode = getNextForwardNodeDepthFirstFor(treeBacking);
            break;
    }
    
    BOOL stop = NO;
    
    JKPTree *nodeObject = nil;
    while (currentNode != endNode)
    {
        if (wantNodeObjects) {
            nodeObject = JX_AUTORELEASE([[JKPTree alloc] initWithCFTree:currentNode]);
        }
        
        id content = getContentObject(currentNode);
        
        block((JKPTOpaqueNodeRef)currentNode,
              nodeObject, 
              content, 
              &stop);
        
        if (stop)  break;
        
        currentNode = getNextNodeWithOptions(currentNode, switchOpts);
    }
}

- (void)enumerateContentObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block;
{
    CFTreeRef currentNode = treeBacking;
    CFTreeRef endNode = getNextForwardNodeDepthFirstFor(treeBacking);;
    BOOL stop = NO;
    
    while (currentNode != endNode)
    {
        id content = getContentObject(currentNode);
        
        block(content, &stop);
        
        if (stop)  break;
        
        currentNode = getNextNodeDepthFirstFor(currentNode);
    }
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

