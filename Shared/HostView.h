//
//  HostView.h
//  ANGLEIOSurfaceTest
//
//  Created by dino on 3/8/18.
//  Copyright © 2018 dino. All rights reserved.
//

#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_OSX
@interface HostView : NSView
#else
@interface HostView : UIView
#endif

@end

NS_ASSUME_NONNULL_END
