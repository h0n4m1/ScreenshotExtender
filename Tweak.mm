#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import "BulletinBoard/BulletinBoard.h"

#define kDEFAULT_TITLE @"Photos"
#define kDEFAULT_MESSAGE @"Saving screenshot..."
#define kDEFAULT_FLASH_COLOR @"#FFFFFF"

static BOOL TweakEnabled = YES;

// FLASH CONF
static BOOL FlashEnabled = NO;
// ALERT CONF
static NSString *AlertTitle;
static NSString *AlertMessage;
static NSString *FlashColorString;
static int AlertStyle = 0;
static int AlertIcon = 0;

enum {
    kAlertStyleNone = 0,
    kAlertStyleBanner,
    kAlertStyleAlert
};

enum {
    kAlertIconNone = 0,
    kAlertIconPhotos,
    kAlertIconCamera
};

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (void)observer:(id)observer addBulletin:(BBBulletinRequest *)bulletin forFeed:(int)feed;
@end

%hook  SBScreenShotter

- (void)saveScreenshot:(BOOL)arg1
{
    %orig;
    if (TweakEnabled){
        NSArray *sectionIDs = @[@"", @"com.apple.mobileslideshow", @"com.apple.camera"];

        switch(AlertStyle) {
            case kAlertStyleNone:
                break;
            case kAlertStyleBanner: {
                Class bulletinBannerController = objc_getClass("SBBulletinBannerController");
                Class bulletinRequest = objc_getClass("BBBulletinRequest");
                BBBulletinRequest *bulletin = [[[bulletinRequest alloc] init] autorelease];
                bulletin.title = AlertTitle;
                bulletin.message = AlertMessage;
                NSDate *date = [NSDate date];
                bulletin.date = date;
                bulletin.lastInterruptDate = date;
                bulletin.sectionID = [sectionIDs objectAtIndex:AlertIcon];
                [(SBBulletinBannerController *)[bulletinBannerController sharedInstance] observer:nil addBulletin:bulletin forFeed:1];
            }
                break;
            case kAlertStyleAlert:{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AlertTitle
                                                                message:AlertMessage
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
                [alert show];
                [self performSelector:@selector(dismissAlertView:) withObject:alert afterDelay:0.8f];
                [alert release];
            }
                break;
        }
    }
}

%new(v@:)
-(void)dismissAlertView:(id)alert
{
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
}
%end


%hook SBScreenFlash

-(void)flashColor:(UIColor *)color
{
    NSString *hexValue = FlashColorString;
    if ([hexValue hasPrefix:@"#"] && [hexValue length] > 1) {
        hexValue = [hexValue substringFromIndex:1];
    }
    
    NSUInteger componentLength = 0;
    switch ([hexValue length]){
        case 3:
            componentLength = 1;
            break;
        case 6:
            componentLength = 2;
            break;
        default:
            %orig(color);
            return;
            break;
    }
    
    BOOL isValid = YES;
    CGFloat components[3];
    for (NSUInteger i = 0; i < 3; i++) {
        NSString *component = [hexValue substringWithRange:NSMakeRange(componentLength * i, componentLength)];
        if (componentLength == 1) {
            component = [component stringByAppendingString:component];
        }
        NSScanner *scanner = [NSScanner scannerWithString:component];
        unsigned int value;
        isValid &= [scanner scanHexInt:&value];
        components[i] = (CGFloat)value / 255.0f;
    }
    
    if (TweakEnabled && isValid) {
        %orig([UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:1.0]);
    } else {
        %orig(color);
    }
}

- (void)flash
{
    if (!TweakEnabled || (TweakEnabled && FlashEnabled)){ %orig; }
}
%end


static void ReloadSettings(void) 
{
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.honami.screenshotextender.plist"];
    TweakEnabled = ([[settings allKeys] containsObject:@"enableTweak"])? [[settings objectForKey:@"enableTweak"] boolValue] : YES;
    FlashEnabled = ([[settings allKeys] containsObject:@"enableFlash"])? [[settings objectForKey:@"enableFlash"] boolValue] : NO;
    FlashColorString = ([[settings allKeys] containsObject:@"flashColor"])? [[settings valueForKey:@"flashColor"] copy] : kDEFAULT_FLASH_COLOR;
    AlertStyle = ([[settings allKeys] containsObject:@"alertStyle"])? [[settings objectForKey:@"alertStyle"] integerValue] : kAlertStyleAlert;
    AlertTitle = ([[settings allKeys] containsObject:@"alertTitle"])? [[settings valueForKey:@"alertTitle"] copy] : kDEFAULT_TITLE;
    AlertMessage = ([[settings allKeys] containsObject:@"alertMessage"])? [[settings valueForKey:@"alertMessage"] copy] : kDEFAULT_MESSAGE;
    AlertIcon = ([[settings allKeys] containsObject:@"alertIcon"])? [[settings objectForKey:@"alertIcon"] integerValue] : kAlertIconPhotos;
    [settings release];
}

static void SettingsChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    ReloadSettings();
}

%ctor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ReloadSettings();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, SettingsChangedCallback, CFSTR("com.honami.screenshotextender.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init();
    [pool drain];
}