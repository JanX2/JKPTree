//
//  JKPTree.h
//  A simple CFTree Cocoa wrapper.
//
//  Created by Jamie Kirkpatrick on 02/04/2006.
//  Copyright 2006 JKP. All rights reserved.  
//
//  Released under the BSD software licence.
//
//  Version History
//
//  2-Apr-06: Initial Release
//

#import <Foundation/Foundation.h>


@interface JKPTree : NSObject <NSFastEnumeration> {
    CFTreeRef       treeBacking;
}

+ (id) treeWithContentObject:(id)theContentObject;
- (id) initWithContentObject:(id)theContentObject;

- (NSString *)descriptionWithLocale:(id)locale;
- (NSString *)descriptionWithChildren:(BOOL)describeChildren;
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level describeChildren:(BOOL)describeChildren;

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

@end
