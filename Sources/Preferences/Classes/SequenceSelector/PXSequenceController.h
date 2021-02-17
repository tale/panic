#import <Preferences/PSViewController.h>
#import <Preferences/PSSpecifier.h>
#import "PXSequenceController.h"
#import <UIKit/UIKit.h>

typedef enum {
	PXPhysicalButtonTypeVolumeUp = 102,
	PXPhysicalButtonTypeVolumeDown = 103,
	PXPhysicalButtonTypePower = 104,
	PXPhysicalButtonTypeInvalid = 106
} PXPhysicalButtonType;

@interface PXSequenceController: PSViewController
@property UITableView *tableView;
@property NSMutableArray *builder;
- (void)encodePreferenceValue;
- (NSMutableArray *)parsedPreferenceValue;
- (NSString *)localizedKeywordForNumber:(PXPhysicalButtonType)buttonType;
@end