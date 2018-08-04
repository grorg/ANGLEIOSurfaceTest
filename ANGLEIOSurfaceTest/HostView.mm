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
#import <ANGLE/entry_points_egl_ext.h>

#include <vector>

static const int bufferWidth = 10;
static const int bufferHeight = 10;

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
    EGLDisplay _eglDisplay;
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

- (void)dealloc
{
    if (_eglDisplay != EGL_NO_DISPLAY) {
        NSLog(@"Terminating ANGLE");
        egl::Terminate(_eglDisplay);
    }
}

- (void)sharedSetup
{
    CALayer *rootLayer = [CALayer layer];
    rootLayer.name = @"ANGLEIOSurfaceTest Root Layer";
    // Make the default background color a bright red, so that we can tell
    // if our IOSurface contents are being used or have no data.
    rootLayer.backgroundColor = CGColorCreateGenericRGB(1.f, 0.f, 0.f, 1.0f);

    // Tell the NSView to be layer-backed.
    self.layer = rootLayer;
    self.wantsLayer = YES;

    _contentsBuffer = [self createIOSurfaceWithWidth:bufferWidth height:bufferHeight format:'BGRA'];

    _eglDisplay = egl::GetDisplay(EGL_DEFAULT_DISPLAY);
    if (_eglDisplay == EGL_NO_DISPLAY)
        return;

    EGLint majorVersion, minorVersion;
    if (egl::Initialize(_eglDisplay, &majorVersion, &minorVersion) == EGL_FALSE) {
        NSLog(@"EGLDisplay Initialization failed.");
        return;
    }
    NSLog(@"ANGLE initialised Major: %d Minor: %d", majorVersion, minorVersion);

    const char *displayExtensions = egl::QueryString(_eglDisplay, EGL_EXTENSIONS);
    NSLog(@"Extensions: %s", displayExtensions);

    EGLConfig config;

    EGLint configAttributes[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_NONE
    };

    EGLint numberConfigsReturned = 0;
    egl::ChooseConfig(_eglDisplay, configAttributes, &config, 1, &numberConfigsReturned);
    if (numberConfigsReturned != 1) {
        NSLog(@"EGLConfig Initialization failed.");
        return;
    }
    NSLog(@"Got EGLConfig");

    egl::BindAPI(EGL_OPENGL_ES_API);
    if (egl::GetError() != EGL_SUCCESS) {
        NSLog(@"Unabled to bind to OPENGL_ES_API");
        return;
    }

    EGLint contextAttributes[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_CONTEXT_WEBGL_COMPATIBILITY_ANGLE, EGL_TRUE,
        EGL_EXTENSIONS_ENABLED_ANGLE, EGL_TRUE,
        EGL_NONE
    };

    EGLContext context = egl::CreateContext(_eglDisplay, config, EGL_NO_CONTEXT, contextAttributes);
    if (context == EGL_NO_CONTEXT) {
        NSLog(@"EGLContext Initialization failed.");
        return;
    }
    NSLog(@"Got EGLContext");

    EGLint surfaceAttributes[] = {
        EGL_NONE
    };

    EGLNativeWindowType window = (__bridge EGLNativeWindowType)rootLayer;
    EGLSurface surface = egl::CreateWindowSurface(_eglDisplay, config, window, surfaceAttributes);
    if (egl::GetError() != EGL_SUCCESS) {
        NSLog(@"EGLSurface Initialization failed");
        return;
    }
    NSLog(@"Got EGLSurface");

    egl::MakeCurrent(_eglDisplay, surface, surface, context);
    if (egl::GetError() != EGL_SUCCESS) {
        NSLog(@"Unable to make context current.");
        return;
    }

    // Fill the IOSurface with a solid blue.
    [self fillIOSurface:_contentsBuffer withRed:0 green:0 blue:255 alpha:255];

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

    for (int i = 0; i < bufferWidth; ++i) {
        for (int j = 0; j < bufferHeight; ++j) {
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
