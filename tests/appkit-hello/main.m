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
		[w makeKeyAndOrderFront:nil];
		[app activateIgnoringOtherApps:YES];
		[app run];
	}
	return 0;
}
