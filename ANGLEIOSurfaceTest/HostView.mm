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

- (void)awakeFromNib
{
    CALayer *rootLayer = [CALayer layer];
    rootLayer.backgroundColor = CGColorCreateGenericRGB(0.2f, 0.7f, 0.7f, 1.0f);

    // Make this view use CA for rendering.
    self.layer = rootLayer;
    self.wantsLayer = YES;
}

- (IOSurfaceRef)createIOSurfaceWithWidth:(int)width Height:(int)height Format:(unsigned)format
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

    IOSurfaceRef ioSurface = IOSurfaceCreate((CFDictionaryRef)options);
    CFRetain(ioSurface);
    return ioSurface;
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
