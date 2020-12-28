#import "RXCreditCell.h"

@interface RXCreditCell()
@property UIImageView *picture;
@end

@implementation RXCreditCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		[self setURLSchema:specifier];
		[self loadPicture:specifier];

		self.picture = [[UIImageView alloc] init];
		self.picture.layer.masksToBounds = YES;
		self.picture.layer.cornerRadius = 20;
		self.picture.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.picture];
		[self.picture.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:15].active = YES;
		[self.picture.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
		[self.picture.widthAnchor constraintEqualToConstant:40].active = YES;
		[self.picture.heightAnchor constraintEqualToConstant:40].active = YES;

		UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
		title.text = specifier.properties[@"user"];
		title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
		title.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:title];
		[title.leadingAnchor constraintEqualToAnchor:self.picture.trailingAnchor constant:15].active = YES;
		[title.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;

		if (@available(iOS 13.0, *)) {
			UIImageView *link = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"safari"]];
			link.translatesAutoresizingMaskIntoConstraints = NO;

			[self addSubview:link];
			[link.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-22].active = YES;
			[link.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
			[link.widthAnchor constraintEqualToConstant:26].active = YES;
			[link.heightAnchor constraintEqualToConstant:26].active = YES;
		}

		if (specifier.properties[@"description"]) {
			UILabel *description = [[UILabel alloc] initWithFrame:CGRectZero];
			description.text = specifier.properties[@"description"];
			description.font = [UIFont systemFontOfSize:10];
			description.translatesAutoresizingMaskIntoConstraints = NO;

			[self addSubview:description];
			[description.leadingAnchor constraintEqualToAnchor:self.picture.trailingAnchor constant:15].active = YES;
			[description.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:8].active = YES;
			[title.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-8].active = YES;
		}
	}

	return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];

	[self.specifier setTarget:self];
	[self.specifier setButtonAction:@selector(openURL)];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
	return 60.0f;
}

- (void)openURL {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.specifier.properties[@"url"]] options:@{} completionHandler:nil];
}

- (void)setURLSchema:(PSSpecifier *)specifier {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aphelion://"]]) {
		specifier.properties[@"url"] = [@"aphelion://profile/" stringByAppendingString:specifier.properties[@"user"]];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
		specifier.properties[@"url"] = [@"tweetbot:///user_profile/" stringByAppendingString:specifier.properties[@"user"]];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific://"]]) {
		specifier.properties[@"url"] = [@"twitterrific:///profile?screen_name=" stringByAppendingString:specifier.properties[@"user"]];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings://"]]) {
		specifier.properties[@"url"] = [@"tweetings:///user?screen_name=" stringByAppendingString:specifier.properties[@"user"]];
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
		specifier.properties[@"url"] = [@"twitter://user?screen_name=" stringByAppendingString:specifier.properties[@"user"]];
	} else {
		specifier.properties[@"url"] = [@"https://mobile.twitter.com/" stringByAppendingString:specifier.properties[@"user"]];
	}
}

- (void)loadPicture:(PSSpecifier *)specifier {
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://mobile.twitter.com/%@/profile_image?size=original", specifier.properties[@"user"]]];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		[request setValue:@"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)" forHTTPHeaderField:@"User-Agent"];
		NSURLSessionDataTask *dataTask = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			if (!data) return;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.picture.image = [UIImage imageWithData:data];
			});
		}];

		[dataTask resume];
	});
}
@end
