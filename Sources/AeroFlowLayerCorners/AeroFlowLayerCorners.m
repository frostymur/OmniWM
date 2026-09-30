// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

#import "AeroFlowLayerCorners.h"
#import <objc/runtime.h>
#import <string.h>

static BOOL AeroFlowLayerMethodMatches(Method method, const char *returnType,
                                    const char *argumentType) {
    if (method == NULL || method_getNumberOfArguments(method) != (argumentType ? 3 : 2)) {
        return NO;
    }
    NSMethodSignature *signature =
        [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    return strcmp(signature.methodReturnType, returnType) == 0 &&
           (argumentType == NULL ||
            strcmp([signature getArgumentTypeAtIndex:2], argumentType) == 0);
}

BOOL aeroflow_layer_border_available(void) {
    static dispatch_once_t onceToken;
    static BOOL available;
    dispatch_once(&onceToken, ^{
        const struct {
            SEL getter;
            SEL setter;
            const char *type;
        } properties[] = {
            {@selector(cornerRadii), @selector(setCornerRadii:), @encode(CACornerRadii)},
            {@selector(rimColor), @selector(setRimColor:), @encode(CGColorRef)},
            {@selector(rimWidth), @selector(setRimWidth:), @encode(double)},
            {@selector(rimOpacity), @selector(setRimOpacity:), @encode(float)},
        };
        available = YES;
        for (size_t i = 0; i < sizeof(properties) / sizeof(properties[0]); i++) {
            if (!AeroFlowLayerMethodMatches(
                    class_getInstanceMethod(CALayer.class, properties[i].getter),
                    properties[i].type, NULL) ||
                !AeroFlowLayerMethodMatches(
                    class_getInstanceMethod(CALayer.class, properties[i].setter),
                    @encode(void), properties[i].type)) {
                available = NO;
                break;
            }
        }
        if (!available) {
            NSLog(@"[AeroFlowLayerCorners] Native border layer API is unavailable or incompatible");
        }
    });
    return available;
}
