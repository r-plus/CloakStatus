#import <Preferences/Preferences.h>

__attribute__((visibility("hidden")))
@interface CloakStatusPSController : PSListController
@end

@implementation CloakStatusPSController

static NSString *const PLFilterKey = @"pl_filter";

static bool checkFilter(NSDictionary *filter)
{
    //PLLog(@"Checking filter %@", filter);

    if(!filter) return true;
    bool valid = true;

    NSArray *coreFoundationVersion = [filter objectForKey:@"CoreFoundationVersion"];
    if(coreFoundationVersion && coreFoundationVersion.count > 0) {
        NSNumber *lowerBound = [coreFoundationVersion objectAtIndex:0];
        NSNumber *upperBound = coreFoundationVersion.count > 1 ? [coreFoundationVersion objectAtIndex:1] : nil;
        //PLLog(@"%@ <= CF Version (%f) < %@", lowerBound, kCFCoreFoundationVersionNumber, upperBound);
        valid = valid && (kCFCoreFoundationVersionNumber >= lowerBound.floatValue) && (upperBound ? (kCFCoreFoundationVersionNumber < upperBound.floatValue) : true);
    }
    //PLLog(valid ? @"Filter matched" : @"Filter did not match");
    return valid;
}

- (id)specifiers
{
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"CloakStatus" target:self] retain];
        NSMutableArray *removals = [NSMutableArray array];
        for (id spec in _specifiers) {
            if (!checkFilter([spec propertyForKey:PLFilterKey]))
                [removals addObject:spec];
        }
        if (removals.count > 0) {
            NSMutableArray *newSpecifiers = [_specifiers mutableCopy];
            [_specifiers release];
            [newSpecifiers removeObjectsInArray:removals];
            _specifiers = newSpecifiers;
        }
    }
    return _specifiers;
}

- (NSArray *)locales:(id)arg
{
    return [[NSLocale availableLocaleIdentifiers] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

@end

/* vim: set ts=4 sw=4 sts=4 expandtab: */
