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

## OpenSwiftUI as a base (2026-11-20)
github.com/OpenSwiftUIProject/OpenSwiftUI (MIT; also OpenRenderBox, OpenAttributeGraph, OpenCoreGraphics, same org). A source-compatible reimplementation, split like Apple's (OpenSwiftUI + OpenSwiftUICore). Built on the Mac VM (macOS 26.7.2 x86_64, Swift 6.3.3) with `OPENSWIFTUI_LIBRARY_TYPE=dynamic swift build -c release --product OpenSwiftUI`: succeeds in 1713 s, `libOpenSwiftUI.dylib` 38 MB, 38353 exported symbols.

**Binary compatibility measured by exported symbol names** (`dyld_info -exports`; ours with the module name normalised `OpenSwiftUI` -> `SwiftUI`, `OpenSwiftUICore` -> `SwiftUICore`; real = SwiftUI + SwiftUICore of the 26.7.2 cache; symbol lists are Apple data and are not committed):
| | real | present in ours |
|---|---|---|
| all exported symbols | 65526 | 22355 (34 %) |
| `$s7SwiftUI` Swift symbols | 63242 | 21323 (34 %) |
Real SwiftUICore exports its Swift symbols under the module name `SwiftUI`. The count is by name only: a present name can still differ in layout / behaviour, and Swift mangling substitutions may hide some matches (the true figure is a little higher). Missing examples: `TabBarOnlyTabViewStyle`, `GestureState` metadata and members.

**Not done:** module renamed to `SwiftUI` with the real install name (needed so apps' mangled names bind), AppKit/RenderBox/AttributeGraph on pearOS.

## First run of a real SwiftUI app on the image (2026-11-20)
Image: CI run 44487950501 (2026-11-19), `cache.img` of 2026-11-20 12:35. That image predates `wsbsd_macdeps`; its script was run by hand in the VM (`/tmp/macdeps.sh onestart`: Mac dyld + cache mounted, `/usr/lib/dyld` becomes the Mac's dyld). Calculator (macOS 26.7.2, `lipo -thin x86_64`, copied from the Mac VM, not committed) started as a Mach-O:
* Without the cache (machrun): every Swift class reports `instance size N here, N+8 in the program`; then `the program called the unimplemented symbol _swift_getSingletonMetadata`. machrun has no Swift runtime: expected, not our target path.
* With the Mac's dyld and cache: no output, the process does not exit within 40 s (rc 124 from `timeout`). Where it waits is not yet known.
