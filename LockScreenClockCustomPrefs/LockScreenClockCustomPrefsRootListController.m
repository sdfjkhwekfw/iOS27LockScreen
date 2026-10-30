#import "LockScreenClockCustomPrefsRootListController.h"
#import <Preferences/PSSpecifier.h>

@implementation LockScreenClockCustomPrefsRootListController

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"LockScreenClockRoot" target:self];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.yourname.lockscreenclock.plist";
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    id v = dict[key];
    return v ?: [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.yourname.lockscreenclock.plist";
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath] ?: [NSMutableDictionary dictionary];
    dict[key] = value;
    [dict writeToFile:prefsPath atomically:YES];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.yourname.lockscreenclock.prefschanged"),
                                         NULL, NULL, YES);
}

@end
