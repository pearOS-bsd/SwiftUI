// SwiftUI inside a plain AppKit window: an NSHostingView with a Text, and a report of what SwiftUI does with it (layers of the hosting view, display link ticks, window state), printed to stderr every second.
// Built on a Mac (swiftc, x86_64), run on the Mac and on pearOS: the two reports must show the same.
import SwiftUI
import AppKit
import QuartzCore

func say(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

final class DrawLayer: CALayer {
    override func draw(in ctx: CGContext) {
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
        say("HOST: DrawLayer.draw(in:) ran, bounds \(bounds)")
    }
}
final class Ticker: NSObject { var n = 0; @objc func tick(_ l: CADisplayLink) { n += 1 } }

func layerCount(_ l: CALayer?) -> (Int, Int) {
    guard let l = l else { return (0, 0) }
    var n = 1, c = l.contents == nil ? 0 : 1
    for s in l.sublayers ?? [] { let (a, b) = layerCount(s); n += a; c += b }
    return (n, c)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var host: NSHostingView<AnyView>!
    var drawLayer: DrawLayer!
    let ticker = Ticker()
    func applicationDidFinishLaunching(_ n: Notification) {
        do {
            let env = EnvironmentValues()
            say("HOST: resolve red=\(Color.red.resolve(in: env)) blue=\(Color.blue.resolve(in: env)) primary=\(Color.primary.resolve(in: env)) custom=\(Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1).resolve(in: env))")
            say("HOST: NSColor.systemRed=\(NSColor.systemRed) labelColor=\(NSColor.labelColor) cg=\(NSColor.systemRed.cgColor)")
        }
        do {
            func comps(_ c: NSColor?) -> String { guard let c = c else { return "nil" }; return "\(c.cgColor.components ?? [])" }
            say("HOST: appearance current=\(NSAppearance.current.name.rawValue) app=\(NSApp.effectiveAppearance.name.rawValue) drawing=\(NSAppearance.currentDrawing().name.rawValue)")
            for sp in [("sRGB", NSColorSpace.sRGB), ("extSRGB", NSColorSpace.extendedSRGB), ("p3", NSColorSpace.displayP3), ("generic", NSColorSpace.genericRGB), ("linSRGB", NSColorSpace.extendedSRGB)] {
                say("HOST: systemRed in \(sp.0): \(comps(NSColor.systemRed.usingColorSpace(sp.1)))")
            }
            for (n, a) in [("aqua", NSAppearance(named: .aqua)), ("dark", NSAppearance(named: .darkAqua))] {
                a?.performAsCurrentDrawingAppearance { say("HOST: \(n): systemRed \(comps(NSColor.systemRed)) label \(comps(NSColor.labelColor)) blue \(comps(NSColor.systemBlue))") }
            }
            say("HOST: Color.red.resolve in aqua env: \(Color.red.resolve(in: { var e = EnvironmentValues(); e.colorScheme = .light; return e }())) dark: \(Color.red.resolve(in: { var e = EnvironmentValues(); e.colorScheme = .dark; return e }()))")
            say("HOST: Color(NSColor.systemRed).resolve: \(Color(nsColor: .systemRed).resolve(in: EnvironmentValues())) Color.accentColor: \(Color.accentColor.resolve(in: EnvironmentValues())) Color.gray: \(Color.gray.resolve(in: EnvironmentValues())) Color.black \(Color.black.resolve(in: EnvironmentValues())) white \(Color.white.resolve(in: EnvironmentValues())) clear \(Color.clear.resolve(in: EnvironmentValues()))")
        }
        do {
            let dyn = NSColor(name: nil, dynamicProvider: { ap in say("HOST: dyn provider called, appearance \(ap.name.rawValue)"); return NSColor.systemRed })
            say("HOST: dynamic colour: cg=\(dyn.cgColor.components ?? []) srgb=\(String(describing: dyn.usingColorSpace(.sRGB)?.cgColor.components))")
            let named = NSColor(name: NSColor.Name("systemRedColor"), dynamicProvider: { _ in NSColor.systemRed })
            say("HOST: named dynamic: \(named.cgColor.components ?? []) \(Color(nsColor: named).resolve(in: EnvironmentValues()))")
            let sel = NSSelectorFromString("systemRedColor"); let c2 = NSColor.perform(sel)?.takeUnretainedValue() as? NSColor
            say("HOST: perform systemRedColor: \(String(describing: c2?.cgColor.components))")
        }
        do {
            say("HOST: dump red: \(String(reflecting: Color.red))")
            var d = ""; dump(Color.red, to: &d, maxDepth: 4); say("HOST: dumpred \(d.replacingOccurrences(of: "\n", with: " | "))")
            var e = EnvironmentValues(); say("HOST: env contrast=\(e.colorSchemeContrast) scheme=\(e.colorScheme) dpi=\(e.displayScale) legib=\(e.legibilityWeight.map { "\($0)" } ?? "nil")")
            e.colorScheme = .dark
            say("HOST: Color.gray.opacity(0.5)=\(Color.gray.opacity(0.5).resolve(in: e)) Color.orange=\(Color.orange.resolve(in: e)) Color(.systemRed)? n/a Color.secondary=\(Color.secondary.resolve(in: e)) Color.yellow=\(Color.yellow.resolve(in: e))")
        }
        let variant = UserDefaults.standard.integer(forKey: "variant")
        let root: AnyView
        switch variant {
        case 1: root = AnyView(Color.red.frame(width: 60, height: 60))
        case 2: root = AnyView(Circle().fill(Color.red).frame(width: 60, height: 60))
        case 5: root = AnyView(Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1).frame(width: 60, height: 60))
        case 6: root = AnyView(Color(nsColor: .systemRed).frame(width: 60, height: 60))
        case 3: root = AnyView(Text("only text"))
        case 4: root = AnyView(Rectangle().fill(Color.blue).frame(width: 60, height: 20).background(Color.green))
        default: root = AnyView(VStack { Text("Hello from SwiftUI on pearOS").font(.title); Circle().fill(Color.red).frame(width: 60, height: 60); Rectangle().fill(Color.blue).frame(width: 60, height: 20) }.padding(20))
        }
        host = NSHostingView(rootView: root)
        window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 420, height: 260), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "hosting"
        window.contentView = host
        say("HOST: created, host.layer = \(String(describing: host.layer)) wantsLayer \(host.wantsLayer) fittingSize \(host.fittingSize)")
        host.wantsLayer = true
        let dl0 = DrawLayer(); dl0.frame = CGRect(x: 5, y: 5, width: 100, height: 30); dl0.contentsScale = 1; host.layer?.addSublayer(dl0); dl0.setNeedsDisplay(); drawLayer = dl0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        let dl = host.displayLink(target: ticker, selector: #selector(Ticker.tick(_:)))
        dl.add(to: .main, forMode: .common)
        var sec = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] t in
            sec += 1
            let (n, c) = layerCount(host.layer)
            say("HOST: t=\(sec) visible=\(window.isVisible) key=\(window.isKeyWindow) occlusion=\(window.occlusionState.rawValue) active=\(NSApp.isActive) layers=\(n) withContents=\(c) frame=\(host.frame) needsDisplay=\(host.needsDisplay) ticks=\(ticker.n)\(sec % 5 == 0 ? "" : "")")
            if sec == 3 { say("HOST: DrawLayer contents: \(String(describing: drawLayer.contents))") }
            if sec == 3, let sub = host.layer?.sublayers?.first {
                say("HOST: sublayer \(sub) needsDisplay=\(sub.needsDisplay()) drawsAsynchronously=\(sub.drawsAsynchronously) contentsFormat=\(sub.contentsFormat) contentsScale=\(sub.contentsScale) opaque=\(sub.isOpaque)")
                say("HOST: contents description: \(String(describing: sub.contents))")
            }
            if sec == 4 || sec == 6 || sec == 8 || sec == 12 || sec == 24 {
                func dump(_ l: CALayer, _ d: Int) { say("HOST:  \(String(repeating: " ", count: d))\(type(of: l)) \(l.bounds.size) flipped=\(l.isGeometryFlipped) pos=\(l.position) contents=\(String(describing: l.contents).prefix(70))"); for s in l.sublayers ?? [] { dump(s, d + 1) } }
                if let l = host.layer { dump(l, 0) }
            }
            if sec == 10 { say("HOST: resolving Color.red now"); say("HOST: late resolve red=\(Color.red.resolve(in: EnvironmentValues()))") }
            if sec == 5 { say("HOST: poke: rootView reassigned"); host.rootView = host.rootView }
            if sec == 7 { say("HOST: poke: layout + display"); host.needsLayout = true; host.layoutSubtreeIfNeeded(); host.displayIfNeeded(); CATransaction.flush() }
            if sec == 9 { say("HOST: poke: window frame change"); window.setContentSize(NSSize(width: 330, height: 200)) }
            if sec == 26 { NSApp.terminate(nil) }
        }
    }
}

let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.setActivationPolicy(.regular)
app.run()
