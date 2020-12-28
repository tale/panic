#import "PXSequenceController.h"

@implementation PXSequenceController
- (NSMutableArray *)parsedPreferenceValue {
	NSString *rawValue = [self readPreferenceValue:self.specifier];
	if (rawValue.length > 1 && [rawValue containsString:@"."]) {
		NSString *clipped = [rawValue substringToIndex:rawValue.length - 1];
		return [[clipped componentsSeparatedByString:@"."] mutableCopy];
	} else {
		return [NSMutableArray new];
	}
}

- (void)encodePreferenceValue {
	NSArray *preferenceArray = [self.builder copy];
	NSString *combinedArray = [preferenceArray componentsJoinedByString:@"."];
	[self setPreferenceValue:[NSString stringWithFormat:@"%@.", combinedArray] specifier:self.specifier];
}

- (NSString *)localizedKeywordForNumber:(PXPhysicalButtonType)buttonType {
	switch (buttonType) {
		case PXPhysicalButtonTypePower: return @"Power/Sleep";
		case PXPhysicalButtonTypeVolumeUp: return @"Volume Up";
		case PXPhysicalButtonTypeVolumeDown: return @"Volume Down";
		default: return @"Invalid Data";
	}
}
@end