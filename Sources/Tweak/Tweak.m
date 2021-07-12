#import "PXHandler.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <dlfcn.h>

@interface SpringBoard : UIApplication
@end

// Support generic hooking with either Libhooker or MobileSubstrate :)
static short (*LBHookMessage)(Class class, SEL selector, void *implementation, void *original);
void GenericHook(Class class, SEL selector, IMP implementation, IMP *original) {
	// For what it's worth, I hate writing nested code.
	// Sorry for anyone reading this.
	if (!LBHookMessage) {
		void *lb_handle = dlopen("/usr/lib/libblackjack.dylib", RTLD_NOW);
		if (lb_handle != NULL) {
			LBHookMessage = dlsym(lb_handle, "LBHookMessage");

			if (LBHookMessage == NULL) {
				dlclose(lb_handle);
				lb_handle = NULL;
			}
		}
	}

	// Try to hook via libhooker first, if it fails then revert to Substrate
	if (LBHookMessage) {
		short hook_status = LBHookMessage(class, selector, (void *)implementation, (void **)original);

		// 0 means LIBHOOKER_OK
		// So we don't need to run MSHookMessageEx
		if (hook_status == 0) {
			return;
		}
	}

	MSHookMessageEx(class, selector, implementation, original);
}

static void notificationCallback() {
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

// Springboard hook that delegates press events to PXHandler
BOOL (*originalButtonHandling) (SpringBoard *, SEL, UIPressesEvent *);
BOOL panicButtonHandling(SpringBoard *self, SEL _cmd, UIPressesEvent *sender) {
	[[PXHandler globalHandler] handlePressesFrom:sender];
	return originalButtonHandling(self, _cmd, sender);
}

__attribute__((constructor)) static void init() {
	// Pref callback
	notificationCallback();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, CFSTR("me.renai.panic/options.update"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	// Load hook
	GenericHook(
		objc_getClass("SpringBoard"),
		@selector(_handlePhysicalButtonEvent:),
		(IMP) &panicButtonHandling,
		(IMP *) &originalButtonHandling
	);
}
