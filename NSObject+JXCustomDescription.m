//
//  NSObject+JXCustomDescription.m
//
//  Created by Jan on 28.09.12.
//  Copyright (c) 2012 Jan Weiß
//
//  Released under the BSD software licence.
//

#import "NSObject+JXCustomDescription.h"

@implementation NSObject (JXCustomDescription)

- (NSString *)jx_descriptionWithLocale:(id)locale
								indent:(NSUInteger)indentLevel
							isIndented:(BOOL *)isIndented
{
	NSString *descriptionString;
	BOOL addQuotes = NO;
	
	if ([self respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
		if (isIndented != NULL)  *isIndented = YES;
		return [(id)self descriptionWithLocale:locale indent:indentLevel];
	}
	else {
		if (isIndented != NULL)  *isIndented = NO;
		if ([self respondsToSelector:@selector(descriptionWithLocale:)]) {
			descriptionString = [(id)self descriptionWithLocale:locale];
		}
		else {
			descriptionString = [self description];
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

@end
