#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <spawn.h>

@interface PXHandler : NSObject
@property BOOL respringEnabled;
@property BOOL safemodeEnabled;
@property NSString *respringSequence;
@property NSString *safemodeSequence;
+ (instancetype)globalHandler;
- (void)handlePressesFrom:(UIPressesEvent *)event;
@end
