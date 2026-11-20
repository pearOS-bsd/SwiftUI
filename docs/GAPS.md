# Gaps (fill from probe runs; one line each: symptom, cause, owner repository, status)
| symptom | cause | repository | status |
|---|---|---|---|
| Calculator aborts at start in HIServices `_RegisterApplication` (version check) | no `SystemVersion.plist`, no `kern.osproductversion` / `kern.osversion` | iso (plist), darwinator (sysctls) | worked around by hand, to do |
| Calculator blocks in `NSApplication init` -> `_initializeSafeAperture` -> `NSURL getResourceValue` -> LaunchServices `_LSCopyServerStore` (sync XPC to lsd `com.apple.lsd.mapdb`, unanswered) | no lsd | d (`lsd-objc`, then own lsd + csstore) | passes with `lsd-objc` started in the stack |
| Calculator then blocks in `NSApplication _initializeRegisteredDefaults` -> `CFPrefsPlistSource withUncanonicalizedPaths:` (sync XPC to cfprefsd unanswered) | cfprefsd of the Mac does not answer in this stack (started by hand, services looked up too early?) | d (own cfprefsd, NO-MAC roadmap step 1) | open, next |
| RenderBox / Metal | not reached yet (the app never gets past `NSApplication init`) | Metal | open |
| machrun: `_swift_getSingletonMetadata` unimplemented, Swift class instance sizes 8 short | machrun has no Swift runtime; the cache path is the right one | darwinator / dyld | by design |
| CI image lacks `wsbsd_macdeps` / `wsbsd_macstack` (image of 2026-11-19) | the iso workflow runs of 2026-11-19 failed or were cancelled; no newer image | iso | open |
| OpenSwiftUI exports 34 % of SwiftUI's symbol names | early-stage upstream | upstream/OpenSwiftUI | measured |
