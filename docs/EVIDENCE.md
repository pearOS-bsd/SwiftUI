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
* With the Mac's dyld and cache, first run: SIGILL. Symbolised with the cache (`ipsw dyld a2f`, slide = process cache base 0x7FF81940C000 minus 0x7FF800000000 = 0x1940C000, from `DYLD_PRINT_SEGMENTS=1`): `abort` in HIServices `_RegisterApplication_block_invoke`, the branch that logs "application requires at least macOS version ... but is being run on ... and so is exiting". Cause: the image has no `/System/Library/CoreServices/SystemVersion.plist` and darwinator has no `kern.osproductversion` / `kern.osversion` sysctls (the Mac VM has 26.7.2 / 25G332). Our own plist (ProductName, ProductVersion, ProductBuildVersion, ProductUserVisibleVersion, iOSSupportVersion) fixes it. **To do properly:** the image writes that file and darwinator answers those two sysctls (Apple's file itself is not copied).
* After that fix the process starts and blocks in the main thread (state `ulock`, other threads `wqpark`, one `machmsg`). Stack (main thread, SIGILL on the blocked process gives darwinator's backtrace): `SwiftUI.App.main` -> `+[NSApplication sharedApplication]` -> `-[NSApplication init]` -> `_initializeSafeAperture` -> `-[NSURL getResourceValue:forKey:]` (the safe-aperture compatibility key of the app bundle) -> `CFURLCopyResourcePropertyForKey` -> `_FSURLCopyResourcePropertyForKeyInternal` -> `_FileCacheLockTransitionToPreparer` -> `__ulock_wait2`. The real AppKit is used (nothing interposed): this is the path SwiftUI apps take.
* The launchd log shows the Mach services looked up and not found during that run: `com.apple.DiskArbitration.diskarbitrationd` (45 times), `com.apple.tccd.system`, `com.apple.logd`, `com.apple.pasteboard.1`, `com.apple.distributed_notifications@1v3`, `com.apple.CoreServices.coreservicesd`. With a generic `svc-stub` (answers every request with success) for DiskArbitration and coreservicesd the hang is unchanged (requests arrive, id 8, size 0x34): the file cache's preparer needs real replies. Next: decompile what the preparer asks of DiskArbitration (volume info for the bundle's volume) and write a wire-compatible stand-in in `d` (not a generic stub).
* Environment of this run: image of CI run 44487950501 booted with `iso/tools/run-vm.sh` (SSH_KEY mode; the image's sshd cannot write host keys on the read-only root: started by hand with keys in /tmp), stand-ins built with `d/darwin/build.sh` on the dev VM and started by hand in the image's `launchd`, like `wsbsd_macstack` does.
