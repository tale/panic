#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <spawn.h>

typedef enum {
	PXPhysicalButtonTypeVolumeUp = 102,
	PXPhysicalButtonTypeVolumeDown = 103,
	PXPhysicalButtonTypePower = 104,
	PXPhysicalButtonTypeInvalid = 106
} PXPhysicalButtonType;

typedef enum {
	PXPhysicalButtonStateReleased = 0,
	PXPhysicalButtonStatePressed = 1
} PXPhysicalButtonState;

@interface PXHandler : NSObject
@property NSArray<NSString *> *sequences;
@property BOOL respringEnabled;
@property BOOL safemodeEnabled;
+ (instancetype)globalHandler;
- (void)handlePressesFrom:(UIPressesEvent *)event;
@end
