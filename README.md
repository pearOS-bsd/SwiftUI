# SwiftUI

Goal: macOS SwiftUI applications run on pearOS BSD unmodified, with the real look and behaviour.

**Layer 3 (UI).** This repository holds no copy of Apple's SwiftUI. SwiftUI, SwiftUICore and RenderBox are Apple's closed frameworks and come from the owner's Mac through `macdeps` (dyld shared cache). Here we keep what is ours: the probe applications, the tests, the evidence of what the real frameworks need from the system, and the tracking of every gap (`docs/GAPS.md`).

## Why SwiftUI does not run today
Evidence in `docs/EVIDENCE.md`. In short:
1. SwiftUI links the **real AppKit** (`NSHostingView`, `NSApplication`). Our `/open/AppKit` replaces AppKit for AppKit-only apps; a SwiftUI app then has two AppKits in one process (bringup-log 2026-11-15).
2. SwiftUICore draws through **RenderBox**, which has no software path: `RBDevice` wraps an `MTLDevice`, `RBShader` compiles Metal shaders, textures and events are `MTLTexture` / `MTLEvent`. No Metal, no pixels.
3. SwiftUI also needs the real QuartzCore render path, CoreImage, IOSurface, Symbols, Combine, the Swift runtime and overlays.

## Plan (each step is a test that must pass before the next)
1. Probe: a minimal SwiftUI app (`Text`, `Button`, `List`), built on the Mac, run on pearOS through the real dyld and cache. Record where it stops (`docs/GAPS.md`).
2. Metal: the `Metal` repository (Metal API over Vulkan). Milestone: `MTLCreateSystemDefaultDevice()` returns a device inside the real RenderBox.
3. Real AppKit from the cache for SwiftUI processes (as the real Dock and Control Center already use), on our SkyLight / WindowServer, with our QuartzCore where the real one needs the GPU.
4. Window with a `Text`; then input, controls, lists, sheets, menus, Settings scene, Charts, Swift Concurrency.
5. Real Apple apps as the compatibility suite: Calculator, Font Book, Preview, Notes, System Settings.

## Rules
Apple's files are never committed. Everything we write is BSD-2-Clause. Observed Apple behaviour is recorded with its evidence (`docs/EVIDENCE.md`).
