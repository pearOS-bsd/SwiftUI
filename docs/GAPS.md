# Gaps (fill from probe runs; one line each: symptom, cause, owner repository, status)
| symptom | cause | repository | status |
|---|---|---|---|
| Calculator (real SwiftUI app, real dyld + cache) runs 40 s without output, never shows a window | not yet located (likely a blocked Mach call or RenderBox / Metal) | SwiftUI (probe), then Metal / d | open |
| machrun: `_swift_getSingletonMetadata` unimplemented, Swift class instance sizes 8 short | machrun has no Swift runtime; the cache path is the right one | darwinator / dyld | by design |
| CI image lacks `wsbsd_macdeps` / `wsbsd_macstack` (image of 2026-11-19) | the iso workflow runs of 2026-11-19 failed or were cancelled; no newer image | iso | open |
| OpenSwiftUI exports 34 % of SwiftUI's symbol names | early-stage upstream | upstream/OpenSwiftUI | measured |
