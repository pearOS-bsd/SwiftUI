// SwiftUI inside a plain AppKit window: an NSHostingView with a Text, and a report of what SwiftUI does with it (layers of the hosting view, display link ticks, window state), printed to stderr every second.
// Built on a Mac (swiftc, x86_64), run on the Mac and on pearOS: the two reports must show the same.
import SwiftUI
import AppKit
import QuartzCore

func say(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

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
    let ticker = Ticker()
    func applicationDidFinishLaunching(_ n: Notification) {
        host = NSHostingView(rootView: AnyView(Text("Hello from SwiftUI on pearOS").font(.title).padding(40)))
        window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 420, height: 160), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "hosting"
        window.contentView = host
        say("HOST: created, host.layer = \(String(describing: host.layer)) wantsLayer \(host.wantsLayer) fittingSize \(host.fittingSize)")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        let dl = host.displayLink(target: ticker, selector: #selector(Ticker.tick(_:)))
        dl.add(to: .main, forMode: .common)
        var sec = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] t in
            sec += 1
            let (n, c) = layerCount(host.layer)
            say("HOST: t=\(sec) visible=\(window.isVisible) key=\(window.isKeyWindow) occlusion=\(window.occlusionState.rawValue) active=\(NSApp.isActive) layers=\(n) withContents=\(c) frame=\(host.frame) needsDisplay=\(host.needsDisplay) ticks=\(ticker.n)")
            if sec == 3, let sub = host.layer?.sublayers?.first {
                say("HOST: sublayer \(sub) needsDisplay=\(sub.needsDisplay()) drawsAsynchronously=\(sub.drawsAsynchronously) contentsFormat=\(sub.contentsFormat) contentsScale=\(sub.contentsScale) opaque=\(sub.isOpaque)")
                say("HOST: contents description: \(String(describing: sub.contents))")
            }
            if sec == 12 { NSApp.terminate(nil) }
        }
    }
}

let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.setActivationPolicy(.regular)
app.run()
