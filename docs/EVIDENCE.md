# Evidence

## RenderBox needs Metal (2026-11-20)
Read from the thin x86_64h slice extracted from the dyld shared cache of macOS 26.7.2 (`ipsw dyld extract`), not committed.
* Load commands: Metal, QuartzCore, CoreImage, IOSurface, Accelerate, CoreGraphics, CoreText, ImageIO, CoreFoundation, Foundation.
* Imports `_MTLCreateSystemDefaultDevice`; ObjC classes `RBDevice` (ivar `_device`, `+allDevices`, `+appleGPUFamily`, `+allowsRenderingInBackground`), `RBShader` (`-[RBDevice compileShader:completionQueue:handler:]`), `RBMetalRenderState`, `RBImageQueueLayer`, `RBLayer`, `RBDisplayList`; blocks capture `MTLTexture` and `MTLEvent`.
* Imported by: AppKit, SwiftUI, SwiftUICore, Symbols, IconFoundation, IconRendering, WidgetRenderer, TextAnimationSupport, WritingToolsUI, DesktopServicesUI, ContactsUICore, PassKitCore, UIKitCore (iOSSupport); executables: Dock, iconservicesagent, passd.
* `_kCIContextUseSoftwareRenderer` is referenced (CoreImage option), but no software path of RenderBox itself was found.
Conclusion: real RenderBox cannot draw without a Metal implementation. Not yet verified at run time on pearOS.

## Open
* Which AppKit the real Dock loads on pearOS today, and how it gets past RenderBox (STATE.md 2c says unverified).
