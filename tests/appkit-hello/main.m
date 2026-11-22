// A real-AppKit window with a coloured layer-backed view: does the Core Animation commit path of pearOS show a window of a Mac program, without SwiftUI / RenderBox / Metal?
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include <servers/bootstrap.h>
#include <objc/message.h>
#include <dlfcn.h>
#include <CoreGraphics/CoreGraphics.h>
static void dump_windows(const char *tag) { CFArrayRef a = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID); int me = (int)getpid(); for (CFIndex i = 0; a && i < CFArrayGetCount(a); i++) { NSDictionary *d = (__bridge NSDictionary *)CFArrayGetValueAtIndex(a, i); if ([d[(id)kCGWindowOwnerPID] intValue] != me) continue; NSDictionary *b = d[(id)kCGWindowBounds]; char l[300]; int n = snprintf(l, sizeof l, "AKH: %s window %d layer %d onscreen %d alpha %.2f bounds %.0f,%.0f %.0fx%.0f\n", tag, [d[(id)kCGWindowNumber] intValue], [d[(id)kCGWindowLayer] intValue], [d[(id)kCGWindowIsOnscreen] intValue], [d[(id)kCGWindowAlpha] doubleValue], [b[@"X"] doubleValue], [b[@"Y"] doubleValue], [b[@"Width"] doubleValue], [b[@"Height"] doubleValue]); write(2, l, n); } if (a) CFRelease(a); }
#include <objc/runtime.h>
typedef struct { uint32_t platform; uint32_t version; } akh_dbv;
extern bool dyld_program_sdk_at_least(akh_dbv v);
/* a marker in the log of launchd: a look-up of a name that does not exist */
static void mark(const char *n) { mach_port_t p; bootstrap_look_up(bootstrap_port, n, &p); }


#define BQ2(o, name) (int)((BOOL (*)(id, SEL))objc_msgSend)((id)(o), NSSelectorFromString(@name))
/* a trace of selected methods: the original is called after the line is written */
static void trace_void(Class c, const char *sel) {
	SEL s = sel_registerName(sel); Method m = class_getInstanceMethod(c, s); if (!m) { write(2, "AKH: no method ", 15); write(2, sel, strlen(sel)); write(2, "\n", 1); return; }
	IMP orig = method_getImplementation(m); char *name = strdup(sel); char *cn = strdup(class_getName(c));
	IMP n = imp_implementationWithBlock(^(__unsafe_unretained id self_, __unsafe_unretained id a1, __unsafe_unretained id a2) { char b[200]; int k = snprintf(b, sizeof b, "AKH: >> %s %s\n", cn, name); write(2, b, k); ((void (*)(id, SEL, id, id))orig)(self_, s, a1, a2); k = snprintf(b, sizeof b, "AKH: << %s %s\n", cn, name); write(2, b, k); });
	method_setImplementation(m, n);
}

/* the same for methods that return a number: the value is written */
static void trace_ret(Class c, const char *sel) {
	SEL s = sel_registerName(sel); Method m = class_getInstanceMethod(c, s); if (!m) { write(2, "AKH: no method ", 15); write(2, sel, strlen(sel)); write(2, "\n", 1); return; }
	IMP orig = method_getImplementation(m); char *name = strdup(sel);
	IMP n = imp_implementationWithBlock(^long(__unsafe_unretained id self_, __unsafe_unretained id a1, __unsafe_unretained id a2, __unsafe_unretained id a3) { long r = ((long (*)(id, SEL, id, id, id))orig)(self_, s, a1, a2, a3); char b[200]; int k = snprintf(b, sizeof b, "AKH: %s(%ld) = %ld\n", name, (long)a1, r); write(2, b, k); return r; });
	method_setImplementation(m, n);
}
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
		{ CGDirectDisplayID d0 = CGMainDisplayID(); char pb[300]; int pn = snprintf(pb, sizeof pb, "AKH: display %u asleep=%d active=%d online=%d main=%d builtin=%d inMirrorSet=%d accel=%d unit=%u vendor=%x model=%x\n", d0, (int)CGDisplayIsAsleep(d0), (int)CGDisplayIsActive(d0), (int)CGDisplayIsOnline(d0), (int)CGDisplayIsMain(d0), (int)CGDisplayIsBuiltin(d0), (int)CGDisplayIsInMirrorSet(d0), (int)CGDisplayUsesOpenGLAcceleration(d0), CGDisplayUnitNumber(d0), CGDisplayVendorNumber(d0), CGDisplayModelNumber(d0)); write(2, pb, pn); }
		{ NSScreen *sc = NSScreen.mainScreen; CGDirectDisplayID did = CGMainDisplayID(); CGDisplayModeRef dm = CGDisplayCopyDisplayMode(did); char b[400]; int n = snprintf(b, sizeof b, "AKH: screen %p maxFPS=%ld minRefreshInterval=%.6f displayModeRefresh=%.2f displayID=%u frame=%.0fx%.0f scale=%.1f\n", sc, (long)sc.maximumFramesPerSecond, (double)sc.minimumRefreshInterval, dm ? CGDisplayModeGetRefreshRate(dm) : -1.0, did, sc.frame.size.width, sc.frame.size.height, (double)sc.backingScaleFactor); write(2, b, n); if (dm) CGDisplayModeRelease(dm); }
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
		{ id an = ((id (*)(id, SEL, NSInteger, NSInteger, id))objc_msgSend)(w, NSSelectorFromString(@"_windowTransformAnimationForOrdering:animationType:interruptingAnimation:"), 1, 5, nil); char b[300]; int n = snprintf(b, sizeof b, "AKH: transform animation = %s (%s) currentProgress=%f isAnimating=%d duration=%f\n", an ? "non-nil" : "nil", an ? object_getClassName(an) : "-", an ? (double)((float (*)(id, SEL))objc_msgSend)(an, @selector(currentProgress)) : -1.0, an ? (int)((BOOL (*)(id, SEL))objc_msgSend)(an, @selector(isAnimating)) : -1, an ? (double)((double (*)(id, SEL))objc_msgSend)(an, @selector(duration)) : -1.0); write(2, b, n); }
		{ Class ta = NSClassFromString(@"_NSWindowTransformAnimation"); trace_void(ta, "startAnimation"); trace_void(ta, "stopAnimation"); trace_void(ta, "reconfigureAnimationBlock"); trace_void(ta, "setCurrentProgress:"); trace_void(ta, "_windowTransformAnimationWillBegin:"); trace_void(ta, "startAnimationWithDuration:completionHandler:");
		  trace_void([NSWindow class], "_reallyDoOrderWindow:"); trace_void([NSWindow class], "_doOrderWindow:"); }
		{ long (*lv)(void) = dlsym(RTLD_DEFAULT, "_NSAutomaticWindowAnimationsLevel"); char b[400];
		  #define BQ(o, name) (int)((BOOL (*)(id, SEL))objc_msgSend)((id)(o), NSSelectorFromString(@name))
		  int n = snprintf(b, sizeof b, "AKH: gates: animlevel=%ld(%p) doingHide=%d doingUnhide=%d sheet=%d dealloc=%d terminating=%d tabbed=%d modal=%d reallyVisible=%d\n", lv ? lv() : -9, lv, BQ(NSApp, "_isDoingHide"), BQ(NSApp, "_isDoingUnhide"), BQ(w, "isSheet"), BQ(w, "_isDeallocating"), BQ(NSApp, "_isTerminating"), BQ(w, "_isTabbedWithOtherWindows"), BQ(w, "_isModalWindow"), BQ(w, "_reallyIsVisible")); write(2, b, n); }
		{ Class wc = [NSWindow class]; trace_ret(wc, "_effectiveOrderFrontAnimationTypeIfModal:"); trace_ret(wc, "_effectiveAnimationBehaviorIfModal:"); trace_ret(wc, "_wantsSolariumWindowAnimations"); trace_ret(wc, "_windowTransformAnimationForOrdering:animationType:interruptingAnimation:"); trace_ret(wc, "_runningWindowTransformAnimation"); trace_ret(wc, "isVisible"); trace_ret(wc, "_reallyIsVisible"); trace_ret(wc, "isMiniaturized"); trace_ret(wc, "_inFullScreen"); trace_ret(wc, "_isTabbedWithOtherWindows"); trace_ret(wc, "_isModalWindow"); trace_ret(wc, "_effectiveOrderOutAnimationTypeIfModal:"); trace_ret(wc, "hasFinishedRestoringWindows"); }
		{ Class pm = NSClassFromString(@"NSPersistentUIManager"); id mgr = pm ? ((id (*)(id, SEL))objc_msgSend)((id)pm, NSSelectorFromString(@"sharedManager")) : nil; char b[300];
		  int n = snprintf(b, sizeof b, "AKH: NSPersistentUIManager %p finishedRestoring=%d\n", mgr, mgr ? BQ2(mgr, "hasFinishedRestoringWindows") : -1); write(2, b, n); }
		{ NSBundle *mb = [NSBundle mainBundle]; char b[500]; int n = snprintf(b, sizeof b, "AKH: mainBundle id=%s path=%s name=%s\n", mb.bundleIdentifier ? [mb.bundleIdentifier UTF8String] : "(nil)", [mb.bundlePath UTF8String], [[[NSProcessInfo processInfo] processName] UTF8String]); write(2, b, n); }
		write(2, "AKH: >> solarium\n", 17); mark("AKH.begin.solar");
		{ Class c = NSClassFromString(@"_NSSolarium"); char b[300]; int n = snprintf(b, sizeof b, "AKH: _NSSolarium class=%p responds=%d value=%d\n", c, c ? (int)[c respondsToSelector:NSSelectorFromString(@"isEnabledIgnoringCompatibility")] : -1, c ? (int)((BOOL (*)(id, SEL))objc_msgSend)((id)c, NSSelectorFromString(@"isEnabledIgnoringCompatibility")) : -1); write(2, b, n); }
		mark("AKH.end.solar"); write(2, "AKH: << solarium\n", 17);
		for (int i = 1; i <= 24; i++) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * (NSEC_PER_SEC / 4)), dispatch_get_main_queue(), ^{ char t[40]; snprintf(t, sizeof t, "t+%d00ms", i * 250 / 100); dump_windows(t); });
		{	/* does a display link tick?  (what drives the update cycle of AppKit: CA::Display::DisplayLink) */
			static int dlticks; static double dlfirst, dllast;
			CADisplayLink *dl = [w.contentView displayLinkWithTarget:[NSBlockOperation blockOperationWithBlock:^{ double t = CACurrentMediaTime(); if (!dlticks) dlfirst = t; dllast = t; dlticks++; }] selector:@selector(main)];
			[dl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ char b[200]; int n = snprintf(b, sizeof b, "AKH: display link: %d ticks in 3 s (paused=%d, first %.3f last %.3f)\n", dlticks, (int)dl.paused, dlfirst, dllast); write(2, b, n); });
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ dump_windows("4 s later"); { char b[200]; int n = snprintf(b, sizeof b, "AKH: 4 s later active=%d key=%d visible=%d occlusion=%lu\n", (int)NSApp.isActive, (int)w.isKeyWindow, (int)w.isVisible, (unsigned long)w.occlusionState); write(2, b, n); } });
		dump_windows("before order");
		write(2, "AKH: before makeKeyAndOrderFront\n", 33); mark("AKH.begin.order");
		[w makeKeyAndOrderFront:nil];
		if (getenv("AKH_ACTIVATE")) { [NSApp activateIgnoringOtherApps:YES]; write(2, "AKH: activated\n", 15); }
		if (getenv("AKH_DISPLAY")) { [w display]; [CATransaction flush]; write(2, "AKH: displayed\n", 15); }
		mark("AKH.end.order"); write(2, "AKH: after makeKeyAndOrderFront\n", 32);
		dump_windows("after order");
		w.isVisible ? write(2, "AKH: window isVisible\n", 22) : write(2, "AKH: window NOT visible\n", 24);
		{ char b[300]; int n = snprintf(b, sizeof b, "AKH: after order: active=%d visible=%d key=%d frame=%.0f,%.0f %.0fx%.0f\n", (int)NSApp.isActive, (int)w.isVisible, (int)w.isKeyWindow, w.frame.origin.x, w.frame.origin.y, w.frame.size.width, w.frame.size.height); write(2, b, n); }
		[app activateIgnoringOtherApps:YES];
		[app run];
	}
	return 0;
}
