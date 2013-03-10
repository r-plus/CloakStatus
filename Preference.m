#import <Preferences/Preferences.h>
#import <libprefs/prefs.h>

__attribute__((visibility("hidden")))
@interface CloakStatusPSController : PSListController
@end

@implementation CloakStatusPSController

- (id)specifiers
{
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"CloakStatus" target:self] retain];
        NSMutableArray *removals = [NSMutableArray array];
        for (id spec in _specifiers) {
            if (![PSSpecifier environmentPassesPreferenceLoaderFilter:[spec propertyForKey:PLFilterKey]])
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
