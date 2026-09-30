// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

#import <AppKit/AppKit.h>
#import <CoreServices/CoreServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AeroFlowLauncherAppRecord : NSObject

@property(nonatomic, copy, readonly) NSString *path;
@property(nonatomic, copy, readonly) NSString *bundleIdentifier;
@property(nonatomic, copy, readonly) NSString *displayName;
@property(nonatomic, copy, readonly) NSArray<NSString *> *alternateNames;
@property(nonatomic, copy, readonly, nullable) NSString *category;

@end

typedef struct {
    NSUInteger tokenCount;
    NSUInteger matchedTermCount;
    NSUInteger distinctMatchedTokenCount;
    float matchFraction;
    BOOL adjacentInOrder;
    BOOL firstTokenMatched;
    BOOL lastTokenMatched;
    uint64_t matchedTermMask;
} AeroFlowTokenMatch;

enum {
    AeroFlowLauncherSPIApps = 1u << 0,
    AeroFlowLauncherSPIEvaluator = 1u << 1,
    AeroFlowLauncherSPIMatcher = 1u << 2,
    AeroFlowLauncherSPIMDQuery = 1u << 3,
    AeroFlowLauncherSPIMDScope = 1u << 4,
    AeroFlowLauncherSPIFingerprint = 1u << 5,
    AeroFlowLauncherSPICategories = 1u << 6,
    AeroFlowLauncherSPIIcons = 1u << 7
};

NSArray<AeroFlowLauncherAppRecord *> *_Nullable aeroflow_launcher_copy_app_records(void);
NSString *_Nullable aeroflow_launcher_database_fingerprint(uint64_t *sequence);
NSString *_Nullable aeroflow_launcher_app_category(NSString *bundleIdentifier,
                                                  NSString *_Nullable lsCategory);
NSString *_Nullable aeroflow_launcher_category_name(NSString *categoryIdentifier);
CGImageRef _Nullable aeroflow_launcher_create_icon(CFURLRef url, CGFloat points,
                                                  CGFloat scale) CF_RETURNS_RETAINED;
NSImage *_Nullable aeroflow_launcher_private_symbol(NSString *name);

void *_Nullable aeroflow_spotlight_evaluator_create(NSString *query, NSString *language);
void aeroflow_spotlight_evaluator_release(void *_Nullable evaluator);
NSUInteger aeroflow_spotlight_query_term_count(void *_Nullable evaluator);
BOOL aeroflow_spotlight_match(void *_Nullable evaluator, NSString *text, AeroFlowTokenMatch *outMatch);

CFStringRef _Nullable aeroflow_mdquery_create_query_string(CFStringRef text) CF_RETURNS_RETAINED;
CFStringRef _Nullable aeroflow_mdquery_scope_my_files(void) CF_RETURNS_RETAINED;
CFStringRef _Nullable aeroflow_mdquery_menu_relevance_attribute(void) CF_RETURNS_RETAINED;
BOOL aeroflow_mdquery_set_matches_support_files(MDQueryRef query, BOOL matches);
BOOL aeroflow_mdquery_set_matches_only_finder_files(MDQueryRef query, BOOL matches);
CFDictionaryRef _Nullable aeroflow_mdquery_copy_result_attributes(MDQueryRef query, CFIndex index,
                                                                  CFArrayRef attributes) CF_RETURNS_RETAINED;

uint32_t aeroflow_launcher_spi_status(void);

NS_ASSUME_NONNULL_END
