// A real-AppKit window with a coloured layer-backed view: does the Core Animation commit path of pearOS show a window of a Mac program, without SwiftUI / RenderBox / Metal?
#import <Cocoa/Cocoa.h>
#include <servers/bootstrap.h>
#include <objc/message.h>
#include <dlfcn.h>
#include <objc/runtime.h>
typedef struct { uint32_t platform; uint32_t version; } akh_dbv;
extern bool dyld_program_sdk_at_least(akh_dbv v);
/* a marker in the log of launchd: a look-up of a name that does not exist */
static void mark(const char *n) { mach_port_t p; bootstrap_look_up(bootstrap_port, n, &p); }

@interface Blue : NSView
@end
@implementation Blue
- (BOOL)wantsUpdateLayer { return YES; }
- (void)updateLayer { self.layer.backgroundColor = [NSColor colorWithSRGBRed:0.1 green:0.4 blue:0.9 alpha:1].CGColor; }
@end

int main(void)
{
	@autoreleasepool {
		NSApplication *app = [NSApplication sharedApplication];
		write(2, "AKH: >> setActivationPolicy\n", 28); mark("AKH.begin.policy");
		{ BOOL ok = [app setActivationPolicy:NSApplicationActivationPolicyRegular]; mark("AKH.end.policy"); char b[80]; int n = snprintf(b, sizeof b, "AKH: << setActivationPolicy ok=%d policy=%ld\n", (int)ok, (long)app.activationPolicy); write(2, b, n); }
		NSWindow *w = [[NSWindow alloc] initWithContentRect:NSMakeRect(200, 200, 400, 300) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
		Blue *v = [[Blue alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
		v.wantsLayer = YES;
		w.contentView = v; w.title = @"AppKit hello";
		/* does the main run loop of the real AppKit service the main queue, timers and observers? (write(2): NSLog needs more) */
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ write(2, "AKH: main queue block ran (after 2 s)\n", 38); });
		dispatch_async(dispatch_get_global_queue(0, 0), ^{ dispatch_async(dispatch_get_main_queue(), ^{ write(2, "AKH: main queue block from a thread ran\n", 40); }); });
		[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) { write(2, "AKH: timer fired\n", 17); }];
		CFRunLoopObserverRef ob = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef o, CFRunLoopActivity a) { static int n; if (n++ < 3) write(2, "AKH: runloop before waiting\n", 28); });
		CFRunLoopAddObserver(CFRunLoopGetMain(), ob, kCFRunLoopCommonModes);
		{ char b[400]; int n = snprintf(b, sizeof b, "AKH: before order: active=%d hidden=%d visible=%d anim=%ld alpha=%.2f winnum=%ld occl=%lu level=%ld screen=%d policy=%ld\n", (int)NSApp.isActive, (int)NSApp.isHidden, (int)w.isVisible, (long)w.animationBehavior, w.alphaValue, (long)w.windowNumber, (unsigned long)w.occlusionState, (long)w.level, w.screen != nil, (long)NSApp.activationPolicy); write(2, b, n); }
		if (getenv("AKH_REGULAR")) { BOOL ok = [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular]; char b[80]; int n = snprintf(b, sizeof b, "AKH: setActivationPolicy(Regular) = %d, now %ld\n", (int)ok, (long)NSApp.activationPolicy); write(2, b, n); }
		{ char b[120]; int n = snprintf(b, sizeof b, "AKH: NSRunningApplication policy %ld pid %d\n", (long)[NSRunningApplication currentApplication].activationPolicy, (int)getpid()); write(2, b, n); }
		{ char b[300]; int n = snprintf(b, sizeof b, "AKH: animtype=%ld reducemotion=%d fullscreenMay=%d inFS=%d mini=%d\n",
			(long)((NSInteger (*)(id, SEL, BOOL))objc_msgSend)(w, NSSelectorFromString(@"_effectiveOrderFrontAnimationTypeIfModal:"), NO),
			(int)[[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion],
			(int)((BOOL (*)(id, SEL))objc_msgSend)(w, NSSelectorFromString(@"_windowMayBecomeFullScreen")),
			(int)((BOOL (*)(id, SEL))objc_msgSend)(w, NSSelectorFromString(@"_inFullScreen")), (int)w.isMiniaturized); write(2, b, n); }
		{ char b[300]; akh_dbv v = { 0xffffffff, 0x07e90000 }; void *f1 = dlsym(RTLD_DEFAULT, "NSSolariumEnabledIgnoringCompatibility"), *f2 = dlsym(RTLD_DEFAULT, "_AXInterfaceGetReduceMotionEnabled");
		  int n = snprintf(b, sizeof b, "AKH: sdk26=%d solarium=%d(%p) axreduce=%d(%p)\n", (int)dyld_program_sdk_at_least(v), f1 ? (int)((bool (*)(void))f1)() : -1, f1, f2 ? (int)((bool (*)(void))f2)() : -1, f2); write(2, b, n); }
		{ NSOperatingSystemVersion ov = [[NSProcessInfo processInfo] operatingSystemVersion]; char b[300]; int n = snprintf(b, sizeof b, "AKH: os %ld.%ld.%ld \"%s\" atleast26=%d\n", (long)ov.majorVersion, (long)ov.minorVersion, (long)ov.patchVersion, [[[NSProcessInfo processInfo] operatingSystemVersionString] UTF8String], (int)[[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){26, 0, 0}]); write(2, b, n); }
		{ const char *names[] = { "NSAddTemplate", "NSScrollPocketAdditionalDimming", "MPPocketFadeMinimumPocketAlpha", "NSActionTemplate" }; for (int i = 0; i < 4; i++) { NSImage *im = [NSImage imageNamed:[NSString stringWithUTF8String:names[i]]]; char b[200]; int n = snprintf(b, sizeof b, "AKH: imageNamed %s -> %s %.0fx%.0f\n", names[i], im ? "found" : "nil", im.size.width, im.size.height); write(2, b, n); } }
		{ BOOL (*gb)(NSString *) = dlsym(RTLD_DEFAULT, "_NSGetBoolAppConfig"); const char *keys[] = { "NSTitlebarPocketEnabled", "NSScrollPocketEnabled", "NSSolariumEnabled" }; for (int i = 0; i < 3; i++) { char b[200]; int n = snprintf(b, sizeof b, "AKH: appconfig %s = %d (fn %p)\n", keys[i], gb ? (int)gb([NSString stringWithUTF8String:keys[i]]) : -1, gb); write(2, b, n); } }
		{ id an = ((id (*)(id, SEL, NSInteger, NSInteger, id))objc_msgSend)(w, NSSelectorFromString(@"_windowTransformAnimationForOrdering:animationType:interruptingAnimation:"), 1, 5, nil); char b[200]; int n = snprintf(b, sizeof b, "AKH: transform animation = %s (%s)\n", an ? "non-nil" : "nil", an ? object_getClassName(an) : "-"); write(2, b, n); }
		write(2, "AKH: >> solarium\n", 17); mark("AKH.begin.solar");
		{ Class c = NSClassFromString(@"_NSSolarium"); char b[300]; int n = snprintf(b, sizeof b, "AKH: _NSSolarium class=%p responds=%d value=%d\n", c, c ? (int)[c respondsToSelector:NSSelectorFromString(@"isEnabledIgnoringCompatibility")] : -1, c ? (int)((BOOL (*)(id, SEL))objc_msgSend)((id)c, NSSelectorFromString(@"isEnabledIgnoringCompatibility")) : -1); write(2, b, n); }
		mark("AKH.end.solar"); write(2, "AKH: << solarium\n", 17);
		write(2, "AKH: before makeKeyAndOrderFront\n", 33); mark("AKH.begin.order");
		[w makeKeyAndOrderFront:nil];
		if (getenv("AKH_ACTIVATE")) { [NSApp activateIgnoringOtherApps:YES]; write(2, "AKH: activated\n", 15); }
		mark("AKH.end.order"); write(2, "AKH: after makeKeyAndOrderFront\n", 32);
		w.isVisible ? write(2, "AKH: window isVisible\n", 22) : write(2, "AKH: window NOT visible\n", 24);
		{ char b[300]; int n = snprintf(b, sizeof b, "AKH: after order: active=%d visible=%d key=%d frame=%.0f,%.0f %.0fx%.0f\n", (int)NSApp.isActive, (int)w.isVisible, (int)w.isKeyWindow, w.frame.origin.x, w.frame.origin.y, w.frame.size.width, w.frame.size.height); write(2, b, n); }
		[app activateIgnoringOtherApps:YES];
		[app run];
	}
	return 0;
}
