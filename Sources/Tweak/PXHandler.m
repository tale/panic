#import "PXHandler.h"

@interface PXHandler ()
@property NSDate *cooldown;
@property NSMutableArray<NSMutableString *> *builders;

// This is needed so we can remove the extra event that's emitted when multiple buttons are triggered
@property NSMutableArray<NSNumber *> *recentHistory;
@end

@implementation PXHandler
+ (instancetype)globalHandler {
	static PXHandler *handler = nil;
	static dispatch_once_t once_token;

	dispatch_once(&once_token, ^{
		handler = [[self alloc] init];
		handler.cooldown = [NSDate date];
		handler.builders = [handler clearedBuilders];
		handler.recentHistory = [NSMutableArray new];
	});

	return handler;
}

- (void)handlePressesFrom:(UIPressesEvent *)event {
	// Single Buttons
	if (event.allPresses.allObjects.count == 1) {
		UIPress *press = event.allPresses.allObjects[0];

		// Press type 105 is the haptic button, we can ignore it
		if (press.type == 105) {
			return;
		}

		// Recent history is used to cleanup double presses
		if (press.force == 1) {
			[self.recentHistory addObject:@(press.type)];
		}

		// Volume Up
		if (press.type == 102 && press.force == 1) {
			NSLog(@"[Panic] Volume Up");
		}

		// Volume Down
		if (press.type == 103 && press.force == 1) {
			NSLog(@"[Panic] Volume Down");
		}

		// Power Button
		if (press.type == 104 && press.force == 1) {
			NSLog(@"[Panic] Power Button");
		}
	}

	// For these, we sum the types and forces together
	if (event.allPresses.allObjects.count == 2) {
		UIPress *firstPress = event.allPresses.allObjects[0];
		UIPress *secondPress = event.allPresses.allObjects[1];

		// Press type 105 is the haptic button, we can ignore it
		if (firstPress.type == 105 || secondPress.type == 105) {
			return;
		}

		// Since this hook is precise, there is a single press event emitted before the multiple press
		// Basically, we need to replace the last event before this

		// 110 is just a random number but it's greater than all the single button types
		if (self.recentHistory.lastObject.intValue < 110) {
			[self.recentHistory removeLastObject];
			[self.recentHistory addObject:@(firstPress.type + secondPress.type)];
		}

		// Volume Down + Power Button
		if (firstPress.type + secondPress.type == 207 && firstPress.force + secondPress.force == 2) {
			NSLog(@"[Panic] Volume Down + Power Button");
		}

		// Volume Up + Power Button
		if (firstPress.type + secondPress.type == 206 && firstPress.force + secondPress.force == 2) {
			NSLog(@"[Panic] Volume Up + Power Button");
		}

		// Volume Up + Volume Down
		if (firstPress.type + secondPress.type == 205 && firstPress.force + secondPress.force == 2) {
			NSLog(@"[Panic] Volume Up + Volume Down");
		}
	}

	// This is delayed 150ms so that there's time for us to modify recentHistory on double button presses
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 150 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
		NSLog(@"[Panic Current Info: %@", self.recentHistory);

		if (self.recentHistory.count == 4) {
			UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.5 dampingRatio:1 animations:^{
				[UIApplication sharedApplication].keyWindow.alpha = 0;
				[UIApplication sharedApplication].keyWindow.transform = CGAffineTransformMakeScale(0.9, 0.9);
			}];

			[animator addCompletion:^ (UIViewAnimatingPosition sender) {
				NSLog(@"[Panic] Respring");
			}];

			[animator startAnimation];
		}
	});
}

- (void)handlePressWithType:(PXPhysicalButtonType)type state:(PXPhysicalButtonState)state {
	// Check to make sure that the button is within the constraints we need it to be
	if (101 < type && type < 105 && state == PXPhysicalButtonStatePressed) {
		// The cooldown time is negative for some reason so we just make sure it's less than -1
		NSTimeInterval interval = [self.cooldown timeIntervalSinceNow];
		if (interval < -1) self.builders = [self clearedBuilders];
		self.cooldown = [NSDate date];

		for (NSMutableString *builder in self.builders) {
			[builder appendString:[NSString stringWithFormat:@"%d.", type]];
			// Get the coordinating sequence value from the preferences loaded array
			for (NSString *sequence in self.sequences) {
				if (builder.length >= sequence.length && [builder containsString:sequence]) {
					self.builders = [self clearedBuilders];
					// 0 = Respring | 1 = Safemode
					if ([self.sequences indexOfObject:sequence] == 0) {
						[self respringDevice];
					} else if ([self.sequences indexOfObject:sequence] == 1) {
						[self safemodeDevice];
					} else {
						NSLog(@"The array was larger than expected");
					}
				}
			}
		}
	}
}

- (void)respringDevice {
	if (self.respringEnabled) {
		pid_t pid;
		BOOL isDirectory;

		// Check to see if 'sbreload' exists, otherwise just respring via 'killall'
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/sbreload" isDirectory:&isDirectory]) {
			const char* args[] = {"sbreload", NULL};
			posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char* const*)args, NULL);
		} else {
			const char* args[] = {"killall", "SpringBoard", NULL};
			posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
		}
	}
}

- (void)safemodeDevice {
	if (self.safemodeEnabled) {
		pid_t pid;
		const char* args[] = {"killall", "-SEGV", "SpringBoard", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	}
}

- (NSMutableArray<NSMutableString *> *)clearedBuilders {
	return [@[
		[@"" mutableCopy],
		[@"" mutableCopy]
	] mutableCopy];
}

@end
