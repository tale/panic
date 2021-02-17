#import "RXHeaderCell.h"

@implementation RXHeaderCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		UILabel *title = [[UILabel alloc] init];
		title.text = [self infoFromPackage:specifier.properties[@"identifier"] value:@"Name"];
		title.font = [UIFont systemFontOfSize:50 weight:UIFontWeightBold];
		title.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self addSubview:title];
		[title.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:25].active = YES;
		[title.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-15].active = YES;

		UILabel *version = [[UILabel alloc] init];
		version.text = [self infoFromPackage:specifier.properties[@"identifier"] value:@"Version"];
		version.font = [UIFont systemFontOfSize:20];
		version.translatesAutoresizingMaskIntoConstraints = NO;
		version.alpha = 0.75;

		[self addSubview:version];
		[version.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:25].active = YES;
		[version.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:25].active = YES;

		NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", specifier.properties[@"bundleName"]]];
		UIImage *logo = [UIImage imageNamed:@"headerIcon" inBundle:bundle compatibleWithTraitCollection:nil];
		UIImageView *icon = [[UIImageView alloc] initWithImage:logo];
		icon.translatesAutoresizingMaskIntoConstraints = NO;
		icon.layer.masksToBounds = YES;
		icon.layer.cornerRadius = 15;

		[self addSubview:icon];
		[icon.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20].active = YES;
		[icon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
		[icon.widthAnchor constraintEqualToConstant:70].active = YES;
		[icon.heightAnchor constraintEqualToConstant:70].active = YES;
	}

	return self;
}

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
	return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RXHeaderCell" specifier:specifier];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
	return 140.0f;
}

- (NSString *)infoFromPackage:(NSString *)identifier value:(NSString *)key {
	NSString *infoQuery = [NSString stringWithFormat:@"${%@}", key];
	int status;

	NSMutableArray<NSString *> *argsv0 = [NSMutableArray array];
	for (NSString *string in @[ @"/usr/bin/dpkg-query", @"-Wf", infoQuery, identifier ]) {
		[argsv0 addObject:[NSString stringWithFormat:@"'%@'", [string stringByReplacingOccurrencesOfString:@"'" withString:@"\\'" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)]]];
	}

	NSString *argsv1 = [argsv0 componentsJoinedByString:@" "];
	FILE *file = popen(argsv1.UTF8String, "r");
	if (!file) {
		return nil;
	}

	char data[1024];
	NSMutableString *output = [NSMutableString string];

	while (fgets(data, 1024, file) != NULL) {
		[output appendString:[NSString stringWithUTF8String:data]];
	}

	int result = pclose(file);
	status = result;

	if (status == 0) {
		return output ?: @"Unknown";
	}

	return @"Unknown";
}
@end
