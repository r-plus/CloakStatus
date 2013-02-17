#import <Preferences/Preferences.h>

__attribute__((visibility("hidden")))
@interface CloakStatusPSController : PSListController
@end

@implementation CloakStatusPSController

- (id)specifiers
{
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"CloakStatus" target:self] retain];
    }
    return _specifiers;
}

- (NSArray *)locales:(id)arg
{
    return [[NSLocale availableLocaleIdentifiers] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

@end

/* vim: set ts=4 sw=4 sts=4 expandtab: */
