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
	// Cooldown checks (we have a 1 second cooldown)
	NSTimeInterval interval = [self.cooldown timeIntervalSinceNow];
	self.cooldown = [NSDate date];

	// Negative because intervals are a difference
	if (interval < -1) [self.recentHistory removeAllObjects];

	// The event emitter will give us 105 as a button type which represents haptic home button
	// While we are here we can also filter out events where the button isn't actually pressed down
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIPress *press, NSDictionary *bindings) {
		if (press.type == 105) {
			return NO;
		}

		if (press.force != 1) {
			return NO;
		}

		return YES;
	}];

	NSArray *presses = [[event.allPresses.allObjects mutableCopy] filteredArrayUsingPredicate:predicate];

	// 101 -> Home Button
	// 102 -> Volume Up
	// 103 -> Volume Down
	// 104 -> Power Button

	// Single Buttons
	if (presses.count == 1) {
		UIPress *press = presses[0];
		[self.recentHistory addObject:@(press.type)];
	}

	// 207 -> Volume Down + Power Button
	// 206 -> Volume Up + Power Button
	// 205 -> Volume Up + Volume Down

	// For these, we sum the types and forces together
	if (presses.count == 2) {
		UIPress *firstPress = event.allPresses.allObjects[0];
		UIPress *secondPress = event.allPresses.allObjects[1];

		[self.recentHistory removeLastObject];
		[self.recentHistory addObject:@(firstPress.type + secondPress.type)];
	}

	// This is delayed 150ms so that there's time for us to modify recentHistory on double button presses
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 150 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
		NSLog(@"[Panic Current Info: %@", self.recentHistory);
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
