//
//  JXArcCompatibilityMacros.h
//
//  Created by Jan on 29.09.12.
//  Copyright 2012 Jan Weiß
//
//	Based on “DDMathParser.h” by Dave DeLong.
//
//  Released under the BSD software licence.
//

#ifndef JXArcCompatibilityMacros_h
#define JXArcCompatibilityMacros_h

#ifdef __clang__
#define JX_STRONG strong
#else
#define JX_STRONG retain
#endif

/*
Porting help (pretty crude, could use improvement):
\[(.+) retain\]				JX_RETAIN(\1)
\[(.+) release\]			JX_RELEASE(\1)
\[(.+) autorelease\]		JX_AUTORELEASE(\1)

\(id\)([\w\d.]+|\[.+\])		JX_BRIDGED_CAST(id, \1)
 
The above have usual problems with nesting. Don’t use them with “Replace all”!
*/

#if __has_feature(objc_arc)

#define JX_HAS_ARC 1
#define JX_RETAIN(_o) (_o)
#define JX_RELEASE(_o)
#define JX_AUTORELEASE(_o) (_o)

#define JX_BRIDGED_CAST(_type, _o) (__bridge _type)(_o)

#else

#define JX_HAS_ARC 0
#define JX_RETAIN(_o) [(_o) retain]
#define JX_RELEASE(_o) [(_o) release]
#define JX_AUTORELEASE(_o) [(_o) autorelease]

#define JX_BRIDGED_CAST(_type, _o) (_type)(_o)

#endif


#endif
