//
//  HostView.m
//  ANGLEIOSurfaceTest
//
//  Created by dino on 3/8/18.
//  Copyright © 2018 dino. All rights reserved.
//

#import "HostView.h"

#import <CoreFoundation/CoreFoundation.h>
#import <IOSurface/IOSurface.h>
#import <QuartzCore/QuartzCore.h>

#import <ANGLE/entry_points_egl.h>

#include <vector>

#pragma mark CALayer SPI

// FIXME: Is there a way to do this without SPI?
@interface CALayer ()
- (void)reloadValueForKeyPath:(NSString *)keyPath;
@end

#pragma mark HostView internal

@interface HostView ()
{
    IOSurfaceRef _contentsBuffer;
//    IOSurfaceRef _drawingBuffer;
//    IOSurfaceRef _spareBuffer;
}
@end

#pragma mark HostView implementation

@implementation HostView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (!(self = [super initWithFrame:frameRect])) {
        NSLog(@"Unable to initialize HostView");
        return nil;
    }
    [self sharedSetup];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (!(self = [super initWithCoder:decoder])) {
        NSLog(@"Unable to initialize HostView");
        return nil;
    }
    [self sharedSetup];
    return self;
}

- (void)sharedSetup
{
    CALayer *rootLayer = [CALayer layer];
    rootLayer.name = @"ANGLEIOSurfaceTest Root Layer";
    // Make the default background color a bright red, so that we can tell
    // if our IOSurface contents are being used or have no data.
    rootLayer.backgroundColor = CGColorCreateGenericRGB(1.f, 0.f, 0.f, 1.0f);

    _contentsBuffer = [self createIOSurfaceWithWidth:10 height:10 format:'BGRA'];

    auto eglDisplay = egl::GetDisplay(EGL_DEFAULT_DISPLAY);
    if (eglDisplay == EGL_NO_DISPLAY)
        return;

    EGLint majorVersion, minorVersion;
    if (egl::Initialize(eglDisplay, &majorVersion, &minorVersion) == EGL_FALSE) {
        NSLog(@"EGLDisplay Initialization failed.");
        return;
    }
    NSLog(@"EGL initialised Major: %d Minor: %d", majorVersion, minorVersion);

    // Fill the IOSurface with a solid blue.
    [self fillIOSurface:_contentsBuffer withRed:0 green:0 blue:255 alpha:255];

    // Tell the NSView to be layer-backed.
    self.layer = rootLayer;
    self.wantsLayer = YES;

    self.layer.contents = (__bridge id)_contentsBuffer;
    [self.layer reloadValueForKeyPath:@"contents"];
}

- (IOSurfaceRef)createIOSurfaceWithWidth:(int)width height:(int)height format:(unsigned)format
{
    unsigned bytesPerElement = 4;
    unsigned bytesPerPixel = 4;

    size_t bytesPerRow = IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, width * bytesPerPixel);
    size_t totalBytes = IOSurfaceAlignProperty(kIOSurfaceAllocSize, height * bytesPerRow);

    NSDictionary *options = @{
                              (id)kIOSurfaceWidth: @(width),
                              (id)kIOSurfaceHeight: @(height),
                              (id)kIOSurfacePixelFormat: @(format),
                              (id)kIOSurfaceBytesPerElement: @(bytesPerElement),
                              (id)kIOSurfaceBytesPerRow: @(bytesPerRow),
                              (id)kIOSurfaceAllocSize: @(totalBytes),
                              (id)kIOSurfaceElementHeight: @(1)
                            };

    return IOSurfaceCreate((CFDictionaryRef)options);
}

- (void)fillIOSurface:(IOSurfaceRef)ioSurface withRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue alpha:(uint8_t)alpha
{
    IOSurfaceLock(_contentsBuffer, 0, nullptr);

    uint8_t* data = (uint8_t*)IOSurfaceGetBaseAddress(_contentsBuffer);
    size_t bytesPerRow = IOSurfaceGetBytesPerRow(_contentsBuffer);

    for (int i = 0; i < 10; ++i) {
        for (int j = 0; j < 10; ++j) {
            size_t base = i * bytesPerRow + j * 4;
            data[base] = blue;
            data[base + 1] = green;
            data[base + 2] = red;
            data[base + 3] = alpha;
        }
    }

    IOSurfaceUnlock(_contentsBuffer, 0, nullptr);
}

- (void)swapSurfaceContents
{
//    if (_drawingBuffer) {
//        std::swap(_contentsBuffer, _drawingBuffer);
//        self.layer.contents = (__bridge id)_contentsBuffer;
//        [self.layer reloadValueForKeyPath:@"contents"];
//    }
}

@end
