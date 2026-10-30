#import <UIKit/UIKit.h>
#import <substrate.h>

static NSString *const kPrefsPath = @"/var/mobile/Library/Preferences/com.yourname.lockscreenclock.plist";

static NSDictionary *getPrefs(void) {
    return [NSDictionary dictionaryWithContentsOfFile:kPrefsPath] ?: @{};
}

static CGFloat readFloat(NSDictionary *prefs, NSString *key, CGFloat def) {
    id v = prefs[key];
    if (v == nil || [v isKindOfClass:[NSNull class]]) return def;
    return [v doubleValue];
}

static UIColor *readColor(NSDictionary *prefs, NSString *prefix, CGFloat defaultR, CGFloat defaultG, CGFloat defaultB) {
    CGFloat r = readFloat(prefs, [NSString stringWithFormat:@"%@R", prefix], defaultR) / 255.0;
    CGFloat g = readFloat(prefs, [NSString stringWithFormat:@"%@G", prefix], defaultG) / 255.0;
    CGFloat b = readFloat(prefs, [NSString stringWithFormat:@"%@B", prefix], defaultB) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

static CGFloat fontWeightFromInt(NSInteger w) {
    switch (w) {
        case 0: return UIFontWeightUltraLight;
        case 1: return UIFontWeightThin;
        case 2: return UIFontWeightLight;
        case 3: return UIFontWeightRegular;
        case 4: return UIFontWeightMedium;
        case 5: return UIFontWeightSemibold;
        case 6: return UIFontWeightBold;
        case 7: return UIFontWeightHeavy;
        case 8: return UIFontWeightBlack;
        default: return UIFontWeightBold;
    }
}

static UILabel *findLabel(UIView *parent, NSInteger tag) {
    for (UIView *sub in parent.subviews) {
        if (sub.tag == tag) return (UILabel *)sub;
    }
    return nil;
}

static void setupLabel(UILabel **label, UIView *parent, NSInteger tag, NSDictionary *prefs, 
                       CGFloat defaultX, CGFloat defaultY, CGFloat defaultSize, NSInteger defaultWeight,
                       NSString *prefix) {
    if (!*label) {
        *label = [[UILabel alloc] init];
        (*label).tag = tag;
        (*label).backgroundColor = [UIColor clearColor];
        [parent addSubview:*label];
    }
    
    CGFloat x = readFloat(prefs, [NSString stringWithFormat:@"%@X", prefix], defaultX);
    CGFloat y = readFloat(prefs, [NSString stringWithFormat:@"%@Y", prefix], defaultY);
    CGFloat size = readFloat(prefs, [NSString stringWithFormat:@"%@Size", prefix], defaultSize);
    NSInteger weight = (NSInteger)readFloat(prefs, [NSString stringWithFormat:@"%@Weight", prefix], defaultWeight);
    UIColor *color = readColor(prefs, [NSString stringWithFormat:@"%@Color", prefix], 0, 0, 0);
    
    (*label).frame = CGRectMake(x, y, 400, size + 20);
    (*label).font = [UIFont systemFontOfSize:size weight:fontWeightFromInt(weight)];
    (*label).textColor = color;
}

static void applyCustomDateView(id dateViewObj) {
    UIView *dateView = (UIView *)dateViewObj;
    NSDictionary *prefs = getPrefs();
    
    // 时间 label (tag 1001)
    UILabel *timeLabel = findLabel(dateView, 1001);
    setupLabel(&timeLabel, dateView, 1001, prefs, 50, 100, 60, 6, @"Time");
    
    // 日期 label (tag 1002)
    UILabel *dateLabel = findLabel(dateView, 1002);
    setupLabel(&dateLabel, dateView, 1002, prefs, 180, 115, 30, 5, @"Date");
    
    // 星期 label (tag 1003)
    UILabel *weekdayLabel = findLabel(dateView, 1003);
    setupLabel(&weekdayLabel, dateView, 1003, prefs, 350, 115, 30, 5, @"Weekday");
    
    // 更新时间文本
    NSDateFormatter *timeFmt = [[NSDateFormatter alloc] init];
    timeFmt.dateFormat = @"HH:mm";
    timeLabel.text = [timeFmt stringFromDate:[NSDate date]];
    
    // 更新日期文本
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    dateFmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    dateFmt.dateFormat = @"M月d日";
    dateLabel.text = [dateFmt stringFromDate:[NSDate date]];
    
    // 更新星期文本
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSArray *weekdays = @[@"日", @"一", @"二", @"三", @"四", @"五", @"六"];
    weekdayLabel.text = [NSString stringWithFormat:@"周%@", weekdays[comps.weekday - 1]];
    
    // 递归隐藏系统自带的所有内容（只保留我们自定义的 tag 1001/1002/1003）
    NSMutableArray *stack = [NSMutableArray arrayWithArray:dateView.subviews];
    while (stack.count) {
        UIView *v = stack.lastObject;
        [stack removeLastObject];
        
        if (v.tag != 1001 && v.tag != 1002 && v.tag != 1003) {
            v.hidden = YES;
        }
        
        for (UIView *sub in v.subviews) {
            if (sub.tag != 1001 && sub.tag != 1002 && sub.tag != 1003) {
                [stack addObject:sub];
            }
        }
    }
}

%hook SBFLockScreenDateView

- (void)layoutSubviews {
    %orig;
    @autoreleasepool {
        applyCustomDateView(self);
    }
}

%end

// 实时刷新
static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    @autoreleasepool {
        UIApplication *app = [UIApplication sharedApplication];
        NSMutableArray *windows = [NSMutableArray array];

        if (@available(iOS 13.0, *)) {
            for (UIScene *sc in app.connectedScenes) {
                if ([sc respondsToSelector:@selector(windows)]) {
                    NSArray *ws = [(id)sc windows];
                    if (ws) [windows addObjectsFromArray:ws];
                }
            }
        }

        for (UIWindow *win in windows) {
            NSMutableArray *stack = [NSMutableArray arrayWithObject:win];
            while (stack.count) {
                UIView *v = stack.lastObject;
                [stack removeLastObject];

                if ([NSStringFromClass(v.class) isEqualToString:@"SBFLockScreenDateView"]) {
                    applyCustomDateView(v);
                }

                for (UIView *sub in v.subviews) [stack addObject:sub];
            }
        }
    }
}

%ctor {
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL, &prefsChanged,
                                        CFSTR("com.yourname.lockscreenclock.prefschanged"),
                                        NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
