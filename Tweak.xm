#import <UIKit/UIKit.h>
#import "Firmware.h"

typedef struct { 
    BOOL itemIsEnabled[24]; 
    BOOL timeString[64]; 
    int gsmSignalStrengthRaw; 
    int gsmSignalStrengthBars; 
    BOOL serviceString[100]; 
    BOOL serviceCrossfadeString[100]; 
    BOOL serviceImages[2][100]; 
    BOOL operatorDirectory[1024]; 
    unsigned int serviceContentType; 
    int wifiSignalStrengthRaw; 
    int wifiSignalStrengthBars; 
    unsigned int dataNetworkType; 
    int batteryCapacity; 
    unsigned int batteryState; 
    BOOL batteryDetailString[150]; 
    int bluetoothBatteryCapacity; 
    int thermalColor; 
    unsigned int thermalSunlightMode : 1;  
    unsigned int slowActivity : 1;  
    unsigned int syncActivity : 1;  
    BOOL activityDisplayId[256]; 
    unsigned int bluetoothConnected : 1;  
    unsigned int displayRawGSMSignal : 1;  
    unsigned int displayRawWifiSignal : 1;  
    unsigned int locationIconType : 1;  
} _rawData;


@interface SBStatusBarDataManager
+ (id)sharedDataManager;
- (void)_updateTimeString;
- (void)setStatusBarItem:(int)item enabled:(BOOL)enabled;
@end

@interface UIStatusBarItem
@property(readonly, assign, nonatomic) NSString *indicatorName;
@property(readonly) int type;
- (id)indicatorName;  
- (id)itemWithType:(int)type;
- (NSString *)description;
@end

@interface UIStatusBarItemView
+ (id)createViewForItem:(id)item foregroundStyle:(int)style;
+ (id)createViewForItem:(id)item withData:(id)data actions:(int)actions foregroundStyle:(int)style;
@end

@interface UIStatusBarComposedData : NSObject
- (_rawData *)rawData;
@end

static BOOL isBootup;
static BOOL isDateTimeStatusBar;
static NSString *formatLang;
static NSString *customDateFormat;
static NSTimer *timer;

static BOOL isTimeEnabled;
static BOOL isLockEnabled;
static BOOL isQuitEnabled;
static BOOL isAirplaneEnabled;
static BOOL isSignalEnabled;
static BOOL isServiceEnabled;
static BOOL isDataEnabled;
static BOOL isBatteryEnabled;
static BOOL isBatteryPercentEnabled;
static BOOL isNotChargingEnabled;
static BOOL isBluetoothBatteryEnabled;
static BOOL isBluetoothEnabled;
static BOOL isTtyEnabled;
static BOOL isAlarmEnabled;
static BOOL isPlusEnabled;
static BOOL isPlayEnabled;
static BOOL isLocationEnabled;
static BOOL isRotationLockEnabled;
static BOOL isDoubleHeightEnabled;
static BOOL isAirPlayEnabled;
static BOOL isSiriEnabled;
static BOOL isVpnEnabled;
static BOOL isCallForwardEnabled;
static BOOL isActivityEnabled;
static BOOL isThermalColorEnabled;

static NSString *kTimeKey = @"Time (Center)";
static NSString *kLockKey = @"Lock:Lock (Center)";// iOS 4-5
static NSString *kQuitKey = @"QuietMode:QuietMode (Center)";// iOS 6+
static NSString *kAirplaneKey = @"AirplaneMode:Airplane (Left)";
static NSString *kSignalKey = @"SignalStrength (Left)";
static NSString *kServiceKey = @"Service (Left)";
static NSString *kDataKey = @"DataNetwork (Left)";
static NSString *kBatteryKey = @"Battery (Right)";
static NSString *kBatteryPercentKey = @"BatteryPercent (Right)";
static NSString *kNotChargingKey = @"NotCharging (Right)";
static NSString *kBluetoothBatteryKey = @"BluetoothBattery (Right)";
static NSString *kBluetoothKey = @"Bluetooth (Right)";
static NSString *kTtyKey = @"Indicator:TTY (Right)";
static NSString *kAlarmKey = @"Indicator:Alarm (Right)";
static NSString *kPlusKey = @"Indicator:Plus (Right)";
static NSString *kPlayKey = @"Indicator:Play (Right)";
static NSString *kLocationObsoleteKey = @"Indicator:Location (Right)";// iOS 4
static NSString *kLocationKey = @"Location (Right)";// iOS 5+
static NSString *kRotationLockKey = @"Indicator:RotationLock (Right)";
//static NSString *kRecordingAppKey = @"RecordingApp:RecordingApp (Right)";// iOS 4 only
static NSString *kDoubleHeightKey = @"DoubleHeight:DoubleHeight (Right)";// iOS 5+
static NSString *kAirPlayKey = @"Indicator:AirPlay (Right)";// iOS 5+
static NSString *kSiriKey = @"Indicator:Siri (Right)";// iOS 6+
static NSString *kVpnKey = @"Indicator:VPN (Left/Right)";
static NSString *kCallForwardKey = @"Indicator:CallForward (Left/Right)";
static NSString *kActivityKey = @"Activity (Left/Right)";
static NSString *kThermalColorKey = @"ThermalColor (Left/Right)";

// http://stackoverflow.com/questions/7989864/watching-memory-usage-in-ios
#import <mach/mach.h>

static inline vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;

    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

static inline NSString *IconNameFromItem(UIStatusBarItem *item)
{
    NSRange range = [[item description] rangeOfString:@"["];
    NSRange iconNameRange;
    iconNameRange.location = range.location + 1;
    iconNameRange.length = [item description].length - range.location - 2;
    return [[item description] substringWithRange:iconNameRange];
}

#pragma GCC diagnostic ignored "-Wunused-function"
static inline BOOL isSync(UIStatusBarComposedData *data)
{
    return [data rawData]->syncActivity;
}

static inline BOOL isDisabledStatus(UIStatusBarItem *item)
{
    NSString *iconName = IconNameFromItem(item);
    // NOTE: Activitys are NetworkActivity, iTunesSyncActivity.
    if (!isTimeEnabled             && [iconName isEqualToString:kTimeKey]) { return YES; }
    if (!isLockEnabled             && [iconName isEqualToString:kLockKey]) { return YES; }
    if (!isQuitEnabled             && [iconName isEqualToString:kQuitKey]) { return YES; }
    if (!isAirplaneEnabled         && [iconName isEqualToString:kAirplaneKey]) { return YES; }
    if (!isSignalEnabled           && [iconName isEqualToString:kSignalKey]) { return YES; }
    if (!isServiceEnabled          && [iconName isEqualToString:kServiceKey]) { return YES; }
    if (!isDataEnabled             && [iconName isEqualToString:kDataKey]) { return YES; }
    if (!isBatteryEnabled          && [iconName isEqualToString:kBatteryKey]) { return YES; }
    if (!isBatteryPercentEnabled   && [iconName isEqualToString:kBatteryPercentKey]) { return YES; }
    if (!isNotChargingEnabled      && [iconName isEqualToString:kNotChargingKey]) { return YES; }
    if (!isBluetoothBatteryEnabled && [iconName isEqualToString:kBluetoothBatteryKey]) { return YES; }
    if (!isBluetoothEnabled        && [iconName isEqualToString:kBluetoothKey]) { return YES; }
    if (!isTtyEnabled              && [iconName isEqualToString:kTtyKey]) { return YES; }
    if (!isAlarmEnabled            && [iconName isEqualToString:kAlarmKey]) { return YES; }
    if (!isPlusEnabled             && [iconName isEqualToString:kPlusKey]) { return YES; }
    if (!isPlayEnabled             && [iconName isEqualToString:kPlayKey]) { return YES; }
    if (!isLocationEnabled         && [iconName isEqualToString:kLocationObsoleteKey]) { return YES; }
    if (!isLocationEnabled         && [iconName isEqualToString:kLocationKey]) { return YES; }
    if (!isRotationLockEnabled     && [iconName isEqualToString:kRotationLockKey]) { return YES; }
    if (!isDoubleHeightEnabled     && [iconName isEqualToString:kDoubleHeightKey]) { return YES; }
    if (!isAirPlayEnabled          && [iconName isEqualToString:kAirPlayKey]) { return YES; }
    if (!isSiriEnabled             && [iconName isEqualToString:kSiriKey]) { return YES; }
    if (!isVpnEnabled              && [iconName isEqualToString:kVpnKey]) { return YES; }
    if (!isCallForwardEnabled      && [iconName isEqualToString:kCallForwardKey]) { return YES; }
    if (!isActivityEnabled         && [iconName isEqualToString:kActivityKey]) { return YES; }
    if (!isThermalColorEnabled     && [iconName isEqualToString:kThermalColorKey]) { return YES; }
    return NO;
}

static inline void SetStatusBarDate(id self, BOOL isContainDate)
{
    // NOTE: iOS 4, 5 assertion failer fix.
    if (!self)
        self = [%c(SBStatusBarDataManager) sharedDataManager];
    NSDateFormatter *dateFormatter = MSHookIvar<NSDateFormatter *>(self, "_timeItemDateFormatter");
    [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:formatLang] autorelease]];
    NSRange range = [customDateFormat rangeOfString:@"FM"];
    if (isContainDate && range.location != NSNotFound) {
        NSMutableString *memoryReplacedFormat = [[customDateFormat substringToIndex:range.location] mutableCopy];
        [memoryReplacedFormat appendFormat:@"%3.0f'MB'", freeMemory()/1024.0f/1024.0f];
        [memoryReplacedFormat appendString:[customDateFormat substringFromIndex:range.location+2]];
        [dateFormatter setDateFormat:memoryReplacedFormat];
        [memoryReplacedFormat release];
        // timer
        if (!timer)
            timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(updateTimeStringWithMemory) userInfo:nil repeats:YES];
    } else {
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        // default = H:mm
        [dateFormatter setDateFormat:(isContainDate ? customDateFormat : @"H:mm")];
    }
    [self _updateTimeString];
}

static inline void DEBUG()
{
    for (int i=0; i<50; i++) {
        NSLog(@"%@", [%c(UIStatusBarItem) itemWithType:i]);
    }
}

static inline void SetItemFromString(NSString *string)
{
    // NOTE: 30 is hard-coding. Now 24 items exist on iOS 6.1
    for (int i=0; i<30; i++) {
        if ([IconNameFromItem([%c(UIStatusBarItem) itemWithType:i]) isEqualToString:string]) {
            [[%c(SBStatusBarDataManager) sharedDataManager] setStatusBarItem:i enabled:(isDisabledStatus([%c(UIStatusBarItem) itemWithType:i]) ? NO : YES)];
            break;
        }
    }
}

%hook SBStatusBarDataManager
- (BOOL)setStatusBarItem:(int)item enabled:(BOOL)enabled
{
    if (isDisabledStatus([%c(UIStatusBarItem) itemWithType:item]))
        return %orig(item, NO);
    return %orig;
}

- (void)_configureTimeItemDateFormatter
{
    %orig;
    SetStatusBarDate(self, isDateTimeStatusBar);
}

%new(v@:)
- (void)updateTimeStringWithMemory
{
    SetStatusBarDate(self, isDateTimeStatusBar);
}
%end

#define PREF_PATH @"/var/mobile/Library/Preferences/jp.r-plus.CloakStatus.plist"
static void LoadSettings()
{	
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    // CloakStatus
    id timePref                   = [dict objectForKey:kTimeKey];
    id lockPref                   = [dict objectForKey:kLockKey];// iOS 4, 5
    id quitPref                   = [dict objectForKey:kQuitKey];// iOS 6+
    id airPlanePref               = [dict objectForKey:kAirplaneKey];
    id signalPref                 = [dict objectForKey:kSignalKey];
    id servicePref                = [dict objectForKey:kServiceKey];
    id dataPref                   = [dict objectForKey:kDataKey];
    id batteryPref                = [dict objectForKey:kBatteryKey];
    id batteryPercentPref         = [dict objectForKey:kBatteryPercentKey];
    id notChargingPref            = [dict objectForKey:kNotChargingKey];
    id bluetoothBatteryPref       = [dict objectForKey:kBluetoothBatteryKey];
    id bluetoothPref              = [dict objectForKey:kBluetoothKey];
    id ttyPref                    = [dict objectForKey:kTtyKey];
    id alarmPref                  = [dict objectForKey:kAlarmKey];
    id plusPref                   = [dict objectForKey:kPlusKey];
    id playPref                   = [dict objectForKey:kPlayKey];
    id locationPref               = [dict objectForKey:kLocationKey];
    id rotationLockPref           = [dict objectForKey:kRotationLockKey];
    id doubleHeightPref           = [dict objectForKey:kDoubleHeightKey];
    id airPlayPref                = [dict objectForKey:kAirPlayKey];
    id siriPref                   = [dict objectForKey:kSiriKey];
    id vpnPref                    = [dict objectForKey:kVpnKey];
    id callForwardPref            = [dict objectForKey:kCallForwardKey];
    id activityPref               = [dict objectForKey:kActivityKey];
    id thermalColorPref           = [dict objectForKey:kThermalColorKey];

    // DateTimeStatusBar
    id dateTimeStatusBarPref = [dict objectForKey:@"DateTimeStatusBar"];
    isDateTimeStatusBar = dateTimeStatusBarPref ? [dateTimeStatusBarPref boolValue] : YES;
    id langPref = [dict objectForKey:@"Lang"];
    formatLang = langPref ? [langPref copy] : @"en_US";
    id customDateFormatPref = [dict objectForKey:@"CustomDateFormat"];
    if (customDateFormat)
        [customDateFormat release];
    customDateFormat = customDateFormatPref ? [customDateFormatPref copy] : @"M/d H:mm";

    if (isBootup) {
        isTimeEnabled = timePref ? [timePref boolValue] : YES;
        isLockEnabled = lockPref ? [lockPref boolValue] : YES;
        isQuitEnabled = quitPref ? [quitPref boolValue] : YES;
        isAirplaneEnabled = airPlanePref ? [airPlanePref boolValue] : YES;
        isSignalEnabled = signalPref ? [signalPref boolValue] : YES;
        isServiceEnabled = servicePref ? [servicePref boolValue] : YES;
        isDataEnabled = dataPref ? [dataPref boolValue] : YES;
        isBatteryEnabled = batteryPref ? [batteryPref boolValue] : YES;
        isBatteryPercentEnabled = batteryPercentPref ? [batteryPercentPref boolValue] : YES;
        isNotChargingEnabled = notChargingPref ? [notChargingPref boolValue] : YES;
        isBluetoothBatteryEnabled = bluetoothBatteryPref ? [bluetoothBatteryPref boolValue] : YES;
        isBluetoothEnabled = bluetoothPref ? [bluetoothPref boolValue] : YES;
        isTtyEnabled = ttyPref ? [ttyPref boolValue] : YES;
        isAlarmEnabled = alarmPref ? [alarmPref boolValue] : YES;
        isPlusEnabled = plusPref ? [plusPref boolValue] : YES;
        isPlayEnabled = playPref ? [playPref boolValue] : YES;
        isLocationEnabled = locationPref ? [locationPref boolValue] : YES;
        isRotationLockEnabled = rotationLockPref ? [rotationLockPref boolValue] : YES;
        isDoubleHeightEnabled = doubleHeightPref ? [doubleHeightPref boolValue] : YES;
        isAirPlayEnabled = airPlayPref ? [airPlayPref boolValue] : YES;
        isSiriEnabled = siriPref ? [siriPref boolValue] : YES;
        isVpnEnabled = vpnPref ? [vpnPref boolValue] : YES;
        isCallForwardEnabled = callForwardPref ? [callForwardPref boolValue] : YES;
        isActivityEnabled = activityPref ? [activityPref boolValue] : YES;
        isThermalColorEnabled = thermalColorPref ? [thermalColorPref boolValue] : YES;
    } else {
        SetStatusBarDate(nil, isDateTimeStatusBar);
        // Detect what setting is changed.
        BOOL isTmpTimeEnabled = timePref ? [timePref boolValue] : YES;
        BOOL isTmpLockEnabled = lockPref ? [lockPref boolValue] : YES;
        BOOL isTmpQuitEnabled = quitPref ? [quitPref boolValue] : YES;
        BOOL isTmpAirplaneEnabled = airPlanePref ? [airPlanePref boolValue] : YES;
        BOOL isTmpSignalEnabled = signalPref ? [signalPref boolValue] : YES;
        BOOL isTmpServiceEnabled = servicePref ? [servicePref boolValue] : YES;
        BOOL isTmpDataEnabled = dataPref ? [dataPref boolValue] : YES;
        BOOL isTmpBatteryEnabled = batteryPref ? [batteryPref boolValue] : YES;
        BOOL isTmpBatteryPercentEnabled = batteryPercentPref ? [batteryPercentPref boolValue] : YES;
        BOOL isTmpNotChargingEnabled = notChargingPref ? [notChargingPref boolValue] : YES;
        BOOL isTmpBluetoothBatteryEnabled = bluetoothBatteryPref ? [bluetoothBatteryPref boolValue] : YES;
        BOOL isTmpBluetoothEnabled = bluetoothPref ? [bluetoothPref boolValue] : YES;
        BOOL isTmpTtyEnabled = ttyPref ? [ttyPref boolValue] : YES;
        BOOL isTmpAlarmEnabled = alarmPref ? [alarmPref boolValue] : YES;
        BOOL isTmpPlusEnabled = plusPref ? [plusPref boolValue] : YES;
        BOOL isTmpPlayEnabled = playPref ? [playPref boolValue] : YES;
        BOOL isTmpLocationEnabled = locationPref ? [locationPref boolValue] : YES;
        BOOL isTmpRotationLockEnabled = rotationLockPref ? [rotationLockPref boolValue] : YES;
        BOOL isTmpDoubleHeightEnabled = doubleHeightPref ? [doubleHeightPref boolValue] : YES;
        BOOL isTmpAirPlayEnabled = airPlayPref ? [airPlayPref boolValue] : YES;
        BOOL isTmpSiriEnabled = siriPref ? [siriPref boolValue] : YES;
        BOOL isTmpVpnEnabled = vpnPref ? [vpnPref boolValue] : YES;
        BOOL isTmpCallForwardEnabled = callForwardPref ? [callForwardPref boolValue] : YES;
        BOOL isTmpActivityEnabled = activityPref ? [activityPref boolValue] : YES;
        BOOL isTmpThermalColorEnabled = thermalColorPref ? [thermalColorPref boolValue] : YES;
        if (isTimeEnabled != isTmpTimeEnabled) {
            isTimeEnabled = isTmpTimeEnabled;
            SetItemFromString(kTimeKey);
        } else if (isLockEnabled != isTmpLockEnabled) {
            isLockEnabled = isTmpLockEnabled;
            SetItemFromString(kLockKey);
        } else if (isQuitEnabled != isTmpQuitEnabled) {
            isQuitEnabled = isTmpQuitEnabled;
            SetItemFromString(kQuitKey);
        } else if (isAirplaneEnabled != isTmpAirplaneEnabled) {
            isAirplaneEnabled = isTmpAirplaneEnabled;
            SetItemFromString(kAirplaneKey);
        } else if (isSignalEnabled != isTmpSignalEnabled) {
            isSignalEnabled = isTmpSignalEnabled;
            SetItemFromString(kSignalKey);
        } else if (isServiceEnabled != isTmpServiceEnabled) {
            isServiceEnabled = isTmpServiceEnabled;
            SetItemFromString(kServiceKey);
        } else if (isDataEnabled != isTmpDataEnabled) {
            isDataEnabled = isTmpDataEnabled;
            SetItemFromString(kDataKey);
        } else if (isBatteryEnabled != isTmpBatteryEnabled) {
            isBatteryEnabled = isTmpBatteryEnabled;
            SetItemFromString(kBatteryKey);
        } else if (isBatteryPercentEnabled != isTmpBatteryPercentEnabled) {
            isBatteryPercentEnabled = isTmpBatteryPercentEnabled;
            SetItemFromString(kBatteryPercentKey);
        } else if (isNotChargingEnabled != isTmpNotChargingEnabled) {
            isNotChargingEnabled = isTmpNotChargingEnabled;
            SetItemFromString(kNotChargingKey);
        } else if (isBluetoothBatteryEnabled != isTmpBluetoothBatteryEnabled) {
            isBluetoothBatteryEnabled = isTmpBluetoothBatteryEnabled;
            SetItemFromString(kBluetoothBatteryKey);
        } else if (isBluetoothEnabled != isTmpBluetoothEnabled) {
            isBluetoothEnabled = isTmpBluetoothEnabled;
            SetItemFromString(kBluetoothKey);
        } else if (isTtyEnabled != isTmpTtyEnabled) {
            isTtyEnabled = isTmpTtyEnabled;
            SetItemFromString(kTtyKey);
        } else if (isAlarmEnabled != isTmpAlarmEnabled) {
            isAlarmEnabled = isTmpAlarmEnabled;
            SetItemFromString(kAlarmKey);
        } else if (isPlusEnabled != isTmpPlusEnabled) {
            isPlusEnabled = isTmpPlusEnabled;
            SetItemFromString(kPlusKey);
        } else if (isPlayEnabled != isTmpPlayEnabled) {
            isPlayEnabled = isTmpPlayEnabled;
            SetItemFromString(kPlayKey);
        } else if (isLocationEnabled != isTmpLocationEnabled) {
            isLocationEnabled = isTmpLocationEnabled;
            if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_5_0)
                SetItemFromString(kLocationObsoleteKey);
            else
                SetItemFromString(kLocationKey);
        } else if (isRotationLockEnabled != isTmpRotationLockEnabled) {
            isRotationLockEnabled = isTmpRotationLockEnabled;
            SetItemFromString(kRotationLockKey);
        } else if (isDoubleHeightEnabled != isTmpDoubleHeightEnabled) {
            isDoubleHeightEnabled = isTmpDoubleHeightEnabled;
            SetItemFromString(kDoubleHeightKey);
        } else if (isAirPlayEnabled != isTmpAirPlayEnabled) {
            isAirPlayEnabled = isTmpAirPlayEnabled;
            SetItemFromString(kAirPlayKey);
        } else if (isSiriEnabled != isTmpSiriEnabled) {
            isSiriEnabled = isTmpSiriEnabled;
            SetItemFromString(kSiriKey);
        } else if (isVpnEnabled != isTmpVpnEnabled) {
            isVpnEnabled = isTmpVpnEnabled;
            SetItemFromString(kVpnKey);
        } else if (isCallForwardEnabled != isTmpCallForwardEnabled) {
            isCallForwardEnabled = isTmpCallForwardEnabled;
            SetItemFromString(kCallForwardKey);
        } else if (isActivityEnabled != isTmpActivityEnabled) {
            isActivityEnabled = isTmpActivityEnabled;
            SetItemFromString(kActivityKey);
        } else if (isThermalColorEnabled != isTmpThermalColorEnabled) {
            isThermalColorEnabled = isTmpThermalColorEnabled;
            SetItemFromString(kThermalColorKey);
        }
    }
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    LoadSettings();
}

%ctor
{
    @autoreleasepool {
        //DEBUG();
        isBootup = YES;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("jp.r-plus.cloakstatus.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        LoadSettings();
        isBootup = NO;
    }
}

/* vim: set st=4 sw=4 sts=4: */
