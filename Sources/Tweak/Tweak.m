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
	NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"me.tale.panic"];

	NSArray *respringSequenceArray = [defaults arrayForKey:@"respring_sequence"] ?: @[ @"102", @"103", @"104" ];
	[PXHandler globalHandler].respringSequence = [respringSequenceArray componentsJoinedByString:@"."];
	[PXHandler globalHandler].respringEnabled = [defaults boolForKey:@"respring_enabled"] ?: YES;

	NSArray *safemodeSequenceArray = [defaults arrayForKey:@"safemode_sequence"] ?: @[ @"104", @"103", @"102" ];
	[PXHandler globalHandler].safemodeSequence = [safemodeSequenceArray componentsJoinedByString:@"."];
	[PXHandler globalHandler].safemodeEnabled = [defaults boolForKey:@"safemode_enabled"] ?: YES;

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
		(IMP)&panicButtonHandling,
		(IMP *)&originalButtonHandling
	);
}
