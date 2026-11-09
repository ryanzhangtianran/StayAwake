// Menu bar UI plus the sleep assertion: while on, the system (and network) stays awake;
// the display still sleeps per System Settings. Same as `caffeinate -i`.
// Left click toggles, right click / control-click shows the menu.
#import <Cocoa/Cocoa.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#include "tray.h"

static NSStatusItem *item;
static NSMenu *menu;
static IOPMAssertionID assertion;
static BOOL on;

// The kernel also releases the assertion when the process exits, even on a crash.
static void setOn(BOOL want) {
    if (want && !on) {
        IOReturn rc = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep,
            kIOPMAssertionLevelOn, CFSTR("StayAwake keeps the system and network awake"), &assertion);
        on = rc == kIOReturnSuccess;
        item.button.toolTip = on ? @"StayAwake：已开启"
            : [NSString stringWithFormat:@"StayAwake：无法阻止睡眠（错误 0x%x）", rc];
    } else if (!want && on) {
        IOPMAssertionRelease(assertion);
        on = NO;
        item.button.toolTip = @"StayAwake：已关闭";
    }
    item.button.appearsDisabled = !on; // system gray, like other inactive menu bar icons
}

@interface Tray : NSObject
@end

@implementation Tray
- (void)clicked:(id)sender {
    NSEvent *e = NSApp.currentEvent;
    if (e.type == NSEventTypeRightMouseUp || (e.modifierFlags & NSEventModifierFlagControl)) {
        item.menu = menu; // attach only for this click so a plain left click stays a toggle
        [item.button performClick:nil];
        item.menu = nil;
    } else {
        setOn(!on);
    }
}
@end

void trayRun(const void *iconPNG, int iconLen) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        NSApp.activationPolicy = NSApplicationActivationPolicyAccessory;
        static Tray *tray;
        tray = [Tray new];

        NSImage *img = [[NSImage alloc] initWithData:[NSData dataWithBytes:iconPNG length:iconLen]];
        NSImageRep *rep = img.representations.firstObject;
        img.size = NSMakeSize(rep.pixelsWide / 2.0, rep.pixelsHigh / 2.0); // PNG is @2x
        img.template = YES; // tint like the system icons in light and dark menu bars

        item = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
        item.button.image = img;
        item.button.target = tray;
        item.button.action = @selector(clicked:);
        [item.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];

        menu = [NSMenu new];
        [menu addItemWithTitle:@"退出" action:@selector(terminate:) keyEquivalent:@"q"];

        setOn(YES); // on at launch
        [NSApp run];
    }
}
