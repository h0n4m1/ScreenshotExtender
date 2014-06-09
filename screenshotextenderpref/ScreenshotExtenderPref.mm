#import <Preferences/Preferences.h>

@interface ScreenshotExtenderPrefListController: PSListController {
}
@end

@implementation ScreenshotExtenderPrefListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ScreenshotExtenderPref" target:self] retain];
	}
	return _specifiers;
}

- (void)openTwitter
{
    NSURL *URL = ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])?
    [NSURL URLWithString:@"twitter://user?screen_name=h0n4m1"] : [NSURL URLWithString:@"http://twitter.com/h0n4m1"];
    [[UIApplication sharedApplication] openURL:URL];
}
- (void)sendMail
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://h0n4m1chan+screenshotextender@gmail.com"]];
}

- (void)openGithub
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/h0n4m1/ScreenshotExtender"]];
}


@end

// vim:ft=objc
