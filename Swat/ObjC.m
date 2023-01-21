//
//  ObjC.m
//  Swat
//
//  Created by Michael VanAllen on 04.04.17.
//  Copyright © 2017 ReactiveCode Studios. All rights reserved.
//

#import "ObjC.h"


@implementation ObjC

+ (BOOL)catchException:(void (^)())tryBlock error:(NSError * _Nullable __autoreleasing *)error {
	BOOL success = NO;
	
	@try {
		tryBlock(); success = YES;
	}
	@catch (NSException *exception) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		info[NSLocalizedDescriptionKey] = exception.reason;
		[info addEntriesFromDictionary:exception.userInfo];
		
		*error = [[NSError alloc] initWithDomain:exception.name code:-1 userInfo:info.copy];
	}
	
	return success;
}

@end
