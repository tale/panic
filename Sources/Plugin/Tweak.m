#import <UIKit/UIKit.h>
#import "Tweak.h"
#import "PXHandler.h"

static void hooked_SpringBoard_handlePhysicalButtonEvent (SpringBoard *self, SEL cmd, UIPressesEvent *sender) {
	if (([PXHandler globalHandler].safemodeEnabled || [PXHandler globalHandler].respringEnabled) && sender.allPresses.allObjects[0] != nil) {
		PXPhysicalButtonType buttonType = sender.allPresses.allObjects[0].type;
		PXPhysicalButtonState buttonState = sender.allPresses.allObjects[0].force;
		[[PXHandler globalHandler] handlePressWithType:buttonType state:buttonState];
	}

	orig_SpringBoard_handlePhysicalButtonEvent(self, cmd, sender);
}

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"me.renai.panic"];

	NSNumber *respringEnabled = [defaults objectForKey:@"respring_enabled"];
	NSNumber *safemodeEnabled = [defaults objectForKey:@"safemode_enabled"];
	NSString *respringSequence = [defaults objectForKey:@"respring_sequence"] ?: @"102.103.104.";
	NSString *safemodeSequence = [defaults objectForKey:@"safemode_sequence"] ?: @"104.103.102.";

	// Unfortunately hacky code that has to be here because I don't want to figure out a proper solution for bad data in the Preferences Table
	if ([defaults objectForKey:@"respring_sequence"] == nil) [defaults setObject:@"102.103.104." forKey:@"respring_sequence"];
	if ([defaults objectForKey:@"safemode_sequence"] == nil) [defaults setObject:@"104.103.102." forKey:@"safemode_sequence"];

	[PXHandler globalHandler].respringEnabled = [respringEnabled boolValue] ?: YES;
	[PXHandler globalHandler].safemodeEnabled = [safemodeEnabled boolValue] ?: YES;
	[PXHandler globalHandler].sequences = @[ respringSequence, safemodeSequence ];
	NSLog(@"Safemode Sequence: %@ - %@ | Respring: %@ - %@", ([PXHandler globalHandler].safemodeEnabled ? @"YES" : @"NO"), safemodeSequence, ([PXHandler globalHandler].respringEnabled ? @"YES" : @"NO"), respringSequence);
	NSLog(@"Updated Panic! Preferences");
}

__attribute__((constructor)) static void loadTweak(int __unused argc, char __unused **argv, char __unused **envp) {
	// pref callback
	notificationCallback(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, CFSTR("me.renai.panic/options.update"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	// load hook
	MSHookMessageEx(objc_getClass("SpringBoard"),
        @selector(_handlePhysicalButtonEvent:),
        (IMP) &hooked_SpringBoard_handlePhysicalButtonEvent,
        (IMP *) &orig_SpringBoard_handlePhysicalButtonEvent);
}
