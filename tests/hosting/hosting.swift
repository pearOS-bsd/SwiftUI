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
        host = NSHostingView(rootView: AnyView(VStack { Text("Hello from SwiftUI on pearOS").font(.title); Circle().fill(Color.red).frame(width: 60, height: 60); Rectangle().fill(Color.blue).frame(width: 60, height: 20) }.padding(20)))
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
            if sec == 4 || sec == 8 || sec == 14 || sec == 24 {
                func dump(_ l: CALayer, _ d: Int) { say("HOST:  \(String(repeating: " ", count: d))\(type(of: l)) \(l.bounds.size) contents=\(String(describing: l.contents).prefix(70))"); for s in l.sublayers ?? [] { dump(s, d + 1) } }
                if let l = host.layer { dump(l, 0) }
            }
            if sec == 26 { NSApp.terminate(nil) }
        }
    }
}

let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.setActivationPolicy(.regular)
app.run()
