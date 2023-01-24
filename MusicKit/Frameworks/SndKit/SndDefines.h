//
//  SndDefines.h
//  SndKit (Framework)
//
//  Created by C.W. Betts on 1/24/23.
//  Copyright © 2023 MusicKit Project. All rights reserved.
//

#ifndef SndDefines_h
#define SndDefines_h

#import <Foundation/Foundation.h>

#define SndDeprecatedEnum(type, oldname, newval) \
static const type oldname NS_DEPRECATED_WITH_REPLACEMENT_MAC( #newval , 10.0, 10.8) = newval

#endif /* SndDefines_h */
