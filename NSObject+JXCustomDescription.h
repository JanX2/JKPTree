//
//  NSObject+JXCustomDescription.h
//
//  Created by Jan on 28.09.12.
//  Copyright (c) 2012 Jan Weiß
//
//  Released under the BSD software licence.
//

#import <Foundation/Foundation.h>

@interface NSObject (JXCustomDescription)

- (NSString *)jx_descriptionWithLocale:(id)locale
								indent:(NSUInteger)indentLevel
							isIndented:(BOOL *)isIndented;

@end
