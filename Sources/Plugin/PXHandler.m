#import "PXHandler.h"

@interface PXHandler ()
@property NSDate *cooldown;
@property NSMutableArray<NSMutableString *> *builders;
@end

@implementation PXHandler
+ (instancetype)globalHandler {
	static PXHandler *handler = nil;
	static dispatch_once_t once_token;

	dispatch_once(&once_token, ^{
		handler = [[self alloc] init];
		handler.cooldown = [NSDate date];
		handler.builders = [handler clearedBuilders];
	});

	return handler;
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
		const char* args[] = {"sbreload", NULL};
		posix_spawnp(&pid, "sbreload", NULL, NULL, (char* const*)args, NULL);
	}
}

- (void)safemodeDevice {
	if (self.safemodeEnabled) {
		pid_t pid;
		const char* args[] = {"killall", "-SEGV", "SpringBoard", NULL};
		posix_spawnp(&pid, "killall", NULL, NULL, (char* const*)args, NULL);
	}
}

- (NSMutableArray<NSMutableString *> *)clearedBuilders {
	return [@[
		[@"" mutableCopy],
		[@"" mutableCopy]
	] mutableCopy];
}

@end