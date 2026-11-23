import CoreGraphics
import AppKit

// The colour space of the main display as AppKit/CoreGraphics see it, to be diffed between the Mac and pearOS.
let id = CGMainDisplayID()
let cs = CGDisplayCopyColorSpace(id)
print("display \(id): name=\(String(describing: cs.name)) model=\(cs.model.rawValue) comps=\(cs.numberOfComponents)")
if let icc = cs.copyICCData() as Data? { print("icc bytes=\(icc.count) head=\(icc.prefix(48).map { String(format: "%02x", $0) }.joined())") }
print("NSScreen.main colorSpace=\(String(describing: NSScreen.main?.colorSpace?.localizedName)) bounds=\(CGDisplayBounds(id))")
print("CGWindow default: \(String(describing: CGColorSpace(name: CGColorSpace.sRGB)?.name))")
