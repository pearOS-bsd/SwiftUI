import CoreGraphics
import Foundation

// Converts a few colours between colour spaces and prints the components: run on the Mac and on pearOS and diff.
let names: [(String, CFString)] = [
    ("sRGB", CGColorSpace.sRGB), ("extSRGB", CGColorSpace.extendedSRGB), ("linSRGB", CGColorSpace.linearSRGB),
    ("displayP3", CGColorSpace.displayP3), ("genericRGB", CGColorSpace.genericRGBLinear), ("genericGray", CGColorSpace.genericGrayGamma2_2),
]
let reds: [(String, CGColor)] = [
    ("red", CGColor(srgbRed: 1, green: 0.258824, blue: 0.270588, alpha: 1)),
    ("blue", CGColor(srgbRed: 0, green: 0.568627, blue: 1, alpha: 1)),
    ("gray", CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1)),
]
for (cn, c) in reds {
    for (n, id) in names {
        guard let cs = CGColorSpace(name: id) else { print("\(cn) -> \(n): no colour space"); continue }
        if let o = c.converted(to: cs, intent: .defaultIntent, options: nil) {
            print("\(cn) -> \(n): \(o.components ?? [])")
        } else { print("\(cn) -> \(n): conversion failed") }
    }
}
