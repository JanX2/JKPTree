//
//  JKPTree.h
//  A simple CFTree Cocoa wrapper.
//
//  Created by Jamie Kirkpatrick on 02/04/2006.
//  Copyright 2006 JKP. All rights reserved.  
//  Copyright 2012-2014 Jan Weiß
//
//  Released under the BSD software licence.
//
//  Version History
//
//  2006-04-02: Initial Release.
//  2011-05-29: Cleanup. 64-bit compatibility.
//  2012-05-10: NSFastEnumeration support. Block enumeration.
//  2012-09-28: Visual tree printing. See -description methods.
//

#import <Foundation/Foundation.h>


struct JKPTOpaqueNode;
typedef struct JKPTOpaqueNode * JKPTOpaqueNodeRef;

enum {
    //JKPTEnumerationConcurrent = (1UL << 0),
    JKPTEnumerationReverse = (1UL << 1),
    JKPTEnumerationAncestors = (1UL << 2),
	JKPTEnumerationNodeObjectNotRequired = 1UL << 31,
};
typedef NSUInteger JKPTEnumerationOptions;

// If we want the tree description to be formatted properly when the tree is contained in a collection, we can temporarily “subclass” NSArray here.
// For details see http://stackoverflow.com/questions/7521683/nsdictionary-description-formatting-problem-treats-structure-like-char-data

@interface JKPTree : NSObject <NSFastEnumeration> {
    CFTreeRef       treeBacking;
}

+ (instancetype) treeWithContentObject:(id)theContentObject;
- (instancetype) initWithContentObject:(id)theContentObject;

+ (JKPTree *) treeWithOpaqueNode:(JKPTOpaqueNodeRef)treeNode;
- (JKPTree *) initWithOpaqueNode:(JKPTOpaqueNodeRef)treeNode;

- (NSString *)descriptionWithLocale:(id)locale;
- (NSString *)descriptionWithChildren:(BOOL)describeChildren;
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;
- (NSString *)descriptionWithLocale:(id)locale
                             indent:(NSUInteger)level
                   describeChildren:(BOOL)describeChildren
                         nestedMode:(BOOL)nestedMode;

- (void) addChildObject:(id)childObject;
- (void) addChildObject:(id)childObject atIndex:(NSUInteger)index;
- (BOOL) removeChildObject:(id)childObject;
- (void) removeChildObjectAtIndex:(NSUInteger)index;
- (void) removeAllChildren;

- (JKPTree *) root;
- (JKPTree *) parent;
- (JKPTree *) firstChild;
- (JKPTree *) nextSibling;

- (NSUInteger) childCount;
- (JKPTree *) nodeAtIndex:(NSUInteger)index;
- (id) childObjectAtIndex:(NSUInteger)index;

- (NSArray *) allSiblingNodes;
- (NSArray *) allSiblingObjects;
- (NSArray *) childNodes;
- (NSArray *) childObjects;

- (BOOL) isLeaf;

- (id) contentObject;
- (void) setContentObject:(id) theContentObject;

- (void)enumerateObjectsWithOptions:(JKPTEnumerationOptions)opts usingBlock:(void (^)(JKPTOpaqueNodeRef node, id nodeObj, id contentObj, BOOL *stop))block;
- (void)enumerateContentObjectsUsingBlock:(void (^)(id contentObj, BOOL *stop))block;

@end
