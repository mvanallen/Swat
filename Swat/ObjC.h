//
//  ObjC.h
//  Swat
//
//  Created by Michael VanAllen on 04.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/* See:
	http://stackoverflow.com/a/36454808/3768451
 */

@interface ObjC : NSObject

+ (BOOL)catchException:(void (^)())tryBlock error:(__autoreleasing NSError **)error;
@end


NS_ASSUME_NONNULL_END
