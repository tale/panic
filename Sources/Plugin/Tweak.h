#import <objc/runtime.h>
#include <substrate.h>

@interface SpringBoard : UIApplication
@end

static void (*orig_SpringBoard_handlePhysicalButtonEvent) (SpringBoard *, SEL, UIPressesEvent *);
static void hooked_SpringBoard_handlePhysicalButtonEvent (SpringBoard *, SEL, UIPressesEvent *);
