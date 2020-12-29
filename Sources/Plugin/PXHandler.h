#import <Foundation/NSUserDefaults+Domain.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <spawn.h>

#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) (void)0
#endif

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
- (void)handlePressWithType:(PXPhysicalButtonType)type state:(PXPhysicalButtonState)state;
@end