#import <UIKit/UIKit.h>
#import "PXHandler.h"

%hook SpringBoard

- (void)_handlePhysicalButtonEvent:(UIPressesEvent *)sender {
	if (([PXHandler globalHandler].safemodeEnabled || [PXHandler globalHandler].respringEnabled) && sender.allPresses.allObjects[0] != nil) {
		PXPhysicalButtonType buttonType = sender.allPresses.allObjects[0].type;
		PXPhysicalButtonState buttonState = sender.allPresses.allObjects[0].force;
		[[PXHandler globalHandler] handlePressWithType:buttonType state:buttonState];
	}

	%orig;
}

%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *domain = @"me.renai.panic";

	NSNumber *respringEnabled = [defaults objectForKey:@"respring_enabled" inDomain:domain];
	NSNumber *safemodeEnabled = [defaults objectForKey:@"safemode_enabled" inDomain:domain];
	NSString *respringSequence = [defaults objectForKey:@"respring_sequence" inDomain:domain] ?: @"102.103.104.";
	NSString *safemodeSequence = [defaults objectForKey:@"safemode_sequence" inDomain:domain] ?: @"104.103.102.";

	// Unfortunately hacky code that has to be here because I don't want to figure out a proper solution for bad data in the Preferences Table
	if ([defaults objectForKey:@"respring_sequence" inDomain:domain] == nil) [defaults setObject:@"102.103.104." forKey:@"respring_sequence" inDomain:domain];
	if ([defaults objectForKey:@"safemode_sequence" inDomain:domain] == nil) [defaults setObject:@"102.103.104." forKey:@"safemode_sequence" inDomain:domain];

	[PXHandler globalHandler].respringEnabled = [respringEnabled boolValue] ?: YES;
	[PXHandler globalHandler].safemodeEnabled = [safemodeEnabled boolValue] ?: YES;
	[PXHandler globalHandler].sequences = @[ respringSequence, safemodeSequence ];
	NSLog(@"Safemode Sequence: %@ - %@ | Respring: %@ - %@", ([PXHandler globalHandler].safemodeEnabled ? @"YES" : @"NO"), safemodeSequence, ([PXHandler globalHandler].respringEnabled ? @"YES" : @"NO"), respringSequence);
	NSLog(@"Updated Panic! Preferences");
}

%ctor {
	notificationCallback(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, CFSTR("me.renai.panic/options.update"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}