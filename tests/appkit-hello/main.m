// A real-AppKit window with a coloured layer-backed view: does the Core Animation commit path of pearOS show a window of a Mac program, without SwiftUI / RenderBox / Metal?
#import <Cocoa/Cocoa.h>

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
		[app setActivationPolicy:NSApplicationActivationPolicyRegular];
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
		write(2, "AKH: before makeKeyAndOrderFront\n", 33);
		[w makeKeyAndOrderFront:nil];
		write(2, "AKH: after makeKeyAndOrderFront\n", 32);
		w.isVisible ? write(2, "AKH: window isVisible\n", 22) : write(2, "AKH: window NOT visible\n", 24);
		[app activateIgnoringOtherApps:YES];
		[app run];
	}
	return 0;
}
