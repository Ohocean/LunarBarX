// LunarBarX v0.1.0
// 状态栏时钟美化：农历/日期/星期、单行合并或双行布局
// 参考: Tappy (b4db1r3, MIT) 对 _UIStatusBarStringView 的 hook 方式
//
// 配置文件: /var/mobile/Library/Preferences/com.local.lunarbarx.plist
// 全部键值见 README.md，缺省时使用下方默认值

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define LB_BOTTOM_TAG 0x1CB20CB2

@interface _UIStatusBarStringView : UIView
-(void)_setText:(id)arg1;
@end

// ---------- 配置 ----------
static BOOL gEnabled      = YES;
static BOOL gTwoLine      = NO;      // NO=单行合并, YES=双行(实验性)
static BOOL gShowLunar    = YES;     // 显示农历
static BOOL gShowDate     = YES;     // 显示 MM/dd
static BOOL gShowWeekday  = NO;      // 显示 周二
static CGFloat gBottomSize = 8.0;    // 第二行字号
static CGFloat gBottomDy   = 0.0;    // 第二行 y 偏移微调
static NSString *gTimeFormat = @"HH:mm";
static BOOL gDebug = NO;
static NSString *gPrefsPath = nil;

static char kLBIsClock;
static char kLBBaseY;

static void LBReadPrefs(void) {
    @autoreleasepool {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:gPrefsPath];
        if (!d) return;
        id v;
        if ((v = d[@"Enabled"]))        gEnabled      = [v boolValue];
        if ((v = d[@"TwoLine"]))        gTwoLine      = [v boolValue];
        if ((v = d[@"ShowLunar"]))      gShowLunar    = [v boolValue];
        if ((v = d[@"ShowDate"]))       gShowDate     = [v boolValue];
        if ((v = d[@"ShowWeekday"]))    gShowWeekday  = [v boolValue];
        if ((v = d[@"BottomFontSize"])) gBottomSize   = [v floatValue];
        if ((v = d[@"BottomOffsetY"]))  gBottomDy     = [v floatValue];
        if ((v = d[@"DebugLog"]))       gDebug        = [v boolValue];
        if ((v = d[@"TimeFormat"]) && [v isKindOfClass:[NSString class]] && [v length]) gTimeFormat = v;
    }
}

// ---------- 农历 ----------
static NSString *LBLunar(NSDate *date) {
    static NSArray *months, *days;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        months = @[@"正月", @"二月", @"三月", @"四月", @"五月", @"六月",
                   @"七月", @"八月", @"九月", @"十月", @"冬月", @"腊月"];
        days = @[@"初一", @"初二", @"初三", @"初四", @"初五", @"初六", @"初七", @"初八", @"初九", @"初十",
                 @"十一", @"十二", @"十三", @"十四", @"十五", @"十六", @"十七", @"十八", @"十九", @"二十",
                 @"廿一", @"廿二", @"廿三", @"廿四", @"廿五", @"廿六", @"廿七", @"廿八", @"廿九", @"三十"];
    });
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
    NSDateComponents *c = [cal components:NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    long m = c.month, dd = c.day;
    if (m < 1 || m > 12 || dd < 1 || dd > 30) return @"";
    return [NSString stringWithFormat:@"%@%@%@", c.isLeapMonth ? @"闰" : @"", months[m - 1], days[dd - 1]];
}

// ---------- 第二行文本: MM/dd 农历 ----------
static NSString *LBExtra(NSDate *date) {
    NSMutableArray *parts = [NSMutableArray array];
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    if (gShowDate) {
        [f setDateFormat:@"MM/dd"];
        NSString *s = [f stringFromDate:date];
        if (s.length) [parts addObject:s];
    }
    if (gShowLunar) {
        NSString *l = LBLunar(date);
        if (l.length) [parts addObject:l];
    }
    return [parts componentsJoinedByString:@" "];
}

// 时钟判定: 短文本且包含冒号 (20:00)。避开电池/百分比等
static BOOL LBIsClockText(NSString *text) {
    return text.length > 0 && text.length <= 8 && [text containsString:@":"];
}

%hook _UIStatusBarStringView

- (void)_setText:(NSString *)text {
    BOOL isClock = gEnabled && LBIsClockText(text);
    if (isClock) objc_setAssociatedObject(self, &kLBIsClock, @YES, OBJC_ASSOCIATION_RETAIN);
    if (!isClock) { %orig; return; }

    NSDate *now = [NSDate date];
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];

    NSString *timeText = text;
    if (gTimeFormat.length) {
        [f setDateFormat:gTimeFormat];
        NSString *s = [f stringFromDate:now];
        if (s.length) timeText = s;
    }

    if (gTwoLine) {
        // 双行: 本体只保留时间, 农历/日期交给第二行标签
        %orig(timeText);
        UILabel *lbl = (UILabel *)[self.superview viewWithTag:LB_BOTTOM_TAG];
        if (lbl) lbl.text = LBExtra(now);
        return;
    }

    // 单行: 周二 20:00 七月廿四
    NSMutableArray *parts = [NSMutableArray array];
    if (gShowWeekday) {
        [f setDateFormat:@"EEE"];
        NSString *w = [f stringFromDate:now];
        if (w.length) [parts addObject:w];
    }
    [parts addObject:timeText];
    NSString *extra = LBExtra(now);
    if (extra.length) [parts addObject:extra];
    %orig([parts componentsJoinedByString:@" "]);
}

- (void)didMoveToWindow {
    %orig;
    if (![objc_getAssociatedObject(self, &kLBIsClock) boolValue]) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        LBReadPrefs();
        if (!gEnabled || !gTwoLine) return;

        UIView *sup = self.superview;
        if (!sup) return;

        // 记录并上移时间, 给第二行腾位置
        CGRect f = self.frame;
        NSNumber *base = objc_getAssociatedObject(self, &kLBBaseY);
        if (!base) {
            base = @(f.origin.y);
            objc_setAssociatedObject(self, &kLBBaseY, base, OBJC_ASSOCIATION_RETAIN);
        }
        CGFloat by = [base floatValue];
        self.frame = CGRectMake(f.origin.x, by - 5.0, f.size.width, f.size.height);

        UILabel *lbl = (UILabel *)[sup viewWithTag:LB_BOTTOM_TAG];
        if (!lbl) {
            lbl = [[UILabel alloc] initWithFrame:CGRectZero];
            lbl.tag = LB_BOTTOM_TAG;
            lbl.textColor = [UIColor whiteColor];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.userInteractionEnabled = NO;
            [sup addSubview:lbl];
        }
        lbl.font = [UIFont systemFontOfSize:gBottomSize weight:UIFontWeightMedium];
        lbl.frame = CGRectMake(f.origin.x + f.size.width / 2.0 - 60.0 + gBottomDy * 0,
                               by + 8.0 + gBottomDy, 120.0, 12.0);
        lbl.text = LBExtra([NSDate date]);

        if (gDebug) NSLog(@"[LunarBarX] two-line ready frame=%@ sup=%@",
                          NSStringFromCGRect(self.frame), NSStringFromClass([sup class]));
    });
}

%end

%ctor {
    @autoreleasepool {
        gPrefsPath = @"/var/mobile/Library/Preferences/com.local.lunarbarx.plist";
        LBReadPrefs();
        if (gEnabled) {
            %init;
            if (gDebug) NSLog(@"[LunarBarX] loaded twoLine=%d lunar=%d", gTwoLine, gShowLunar);
        } else if (gDebug) {
            NSLog(@"[LunarBarX] disabled by prefs, not hooking");
        }
    }
}
