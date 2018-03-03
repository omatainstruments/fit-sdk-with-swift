//
//  WrapperForSwift.h
//  exampleios
//
//  Created by Julian Bleecker on 2/23/17.
//
//
//
#ifndef WrapperForSwift_h
#define WrapperForSwift_h
#import <Foundation/Foundation.h>

@class SwiftThatUsesWrapperForSwift;

@interface WrapperForSwift : NSObject
- (id)init:(SwiftThatUsesWrapperForSwift *)_supervisor;
- (NSData *)decode:(NSString *)path;
- (UInt8)encode;
- (void)method_callback:(Float64)val;
- (void)setSupervisor:(SwiftThatUsesWrapperForSwift *)_supervisor;
@end

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#endif /* WrapperForSwift_h */
