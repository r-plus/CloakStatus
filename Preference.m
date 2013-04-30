#import <filterPrefs.h>

__attribute__((visibility("hidden")))
@interface CloakStatusPSController : PSListController
@end

@implementation CloakStatusPSController

- (id)specifiers
{
    if (!_specifiers) {
        _specifiers = FilteredSpecifiers([[self loadSpecifiersFromPlistName:@"CloakStatus" target:self] retain]);
    }
    return _specifiers;
}

- (NSArray *)locales
{
    return [[NSLocale preferredLanguages] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    //return [[NSLocale availableLocaleIdentifiers] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

@end

/* vim: set ts=4 sw=4 sts=4 expandtab: */
