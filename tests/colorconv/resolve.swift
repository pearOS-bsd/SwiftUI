import SwiftUI
import AppKit

// SwiftUI's own colour resolution (Color.Resolved) and its gradient colour mixing, printed to be diffed between the Mac and pearOS.
let env = EnvironmentValues()
for (n, c) in [("red", Color.red), ("blue", Color.blue), ("white", Color.white), ("black", Color.black)] {
    let r = c.resolve(in: env)
    print("\(n): linear \(r.linearRed) \(r.linearGreen) \(r.linearBlue) \(r.opacity) | srgb \(r.red) \(r.green) \(r.blue)")
}
let m = Color.red.mix(with: Color.blue, by: 0.5, in: .perceptual).resolve(in: env)
print("mix perceptual: \(m.red) \(m.green) \(m.blue)")
let n = Color.red.mix(with: Color.blue, by: 0.5, in: .device).resolve(in: env)
print("mix device: \(n.red) \(n.green) \(n.blue)")
