// A small SwiftUI app: a window (WindowGroup) with Text, a Button that counts, a Toggle and shapes.  Built on a Mac (swiftc, x86_64) and run on pearOS to see how far real SwiftUI gets.
import SwiftUI

struct Content: View {
    @State private var n = 0
    @State private var on = true
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 12) {
            Text("Hello from SwiftUI on pearOS").font(.title)
            Text("count: \(n)").foregroundColor(.secondary)
            Button("Add one") { n += 1 }
            Toggle("Enabled", isOn: $on)
            TextField("Type here", text: $text).frame(width: 200).focused($focused)
            Text("typed: \(text)")
            if UserDefaults.standard.bool(forKey: "stroke") { RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 4).frame(width: 100, height: 50) }
            if UserDefaults.standard.bool(forKey: "box") { Rectangle().fill(Color.gray).frame(width: 200, height: 70) }
            if UserDefaults.standard.bool(forKey: "scroll") { ScrollView { VStack { ForEach(0..<40, id: \.self) { Text("row \($0)") } } }.scrollIndicators(UserDefaults.standard.bool(forKey: "noind") ? .hidden : .automatic).frame(width: 200, height: 70) }
            HStack { Circle().fill(.red).frame(width: 30, height: 30); Rectangle().fill(.blue).frame(width: 60, height: 30) }
        }.padding(30)
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in if UserDefaults.standard.bool(forKey: "tick") { n += 1 } }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { if UserDefaults.standard.bool(forKey: "focus") { NSApp.activate(ignoringOtherApps: true); NSApp.windows.first?.makeKeyAndOrderFront(nil) } }
            DispatchQueue.main.asyncAfter(deadline: .now() + (UserDefaults.standard.double(forKey: "focusdelay") > 0 ? UserDefaults.standard.double(forKey: "focusdelay") : 4)) { if UserDefaults.standard.bool(forKey: "focus") { focused = true } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                let u = UserDefaults.standard
                FileHandle.standardError.write("DEFS showScrollBars=\(String(describing: u.object(forKey: "AppleShowScrollBars"))) paging=\(String(describing: u.object(forKey: "AppleScrollerPagingBehavior"))) style=\(NSScroller.preferredScrollerStyle.rawValue) mainWindow=\(String(describing: NSApp.mainWindow)) n=\(NSApp.windows.count)\n".data(using: .utf8)!)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if UserDefaults.standard.bool(forKey: "poke") {
                    FileHandle.standardError.write("POKE displayIfNeeded\n".data(using: .utf8)!)
                    if let w = NSApp.windows.first { w.contentView?.needsDisplay = true; w.displayIfNeeded(); w.makeKeyAndOrderFront(nil); w.contentView?.layer?.setNeedsDisplay(); CATransaction.flush() }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                for w in NSApp.windows { FileHandle.standardError.write("WINS \(type(of: w)) frame=\(w.frame) key=\(w.isKeyWindow) main=\(w.isMainWindow) visible=\(w.isVisible) level=\(w.level.rawValue) title=\(w.title) fr=\(String(describing: w.firstResponder.map { String(describing: type(of: $0)) })) num=\(w.windowNumber)\n".data(using: .utf8)!) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                func dump(_ l: CALayer, _ d: Int) {
                    let c = l.backgroundColor.flatMap { $0.components } ?? []
                    let line = String(repeating: " ", count: d) + "\(type(of: l)) f=\(l.frame) op=\(l.opacity) hid=\(l.isHidden) bg=\(c) cr=\(l.cornerRadius) contents=\(l.contents != nil)"
                    FileHandle.standardError.write(("TREE " + line + "\n").data(using: .utf8)!)
                    if let sh = l as? CAShapeLayer {
                        var els: [String] = []
                        sh.path?.applyWithBlock { e in let p = e.pointee; switch p.type { case .moveToPoint: els.append("M \(p.points[0].x),\(p.points[0].y)"); case .addLineToPoint: els.append("L \(p.points[0].x),\(p.points[0].y)"); case .addQuadCurveToPoint: els.append("Q"); case .addCurveToPoint: els.append("C \(p.points[2].x),\(p.points[2].y)"); case .closeSubpath: els.append("Z"); @unknown default: els.append("?") } }
                        FileHandle.standardError.write(("TREESHAPE bbox=\(String(describing: sh.path?.boundingBox)) fill=\(String(describing: sh.fillColor?.components)) stroke=\(String(describing: sh.strokeColor?.components)) lw=\(sh.lineWidth) cap=\(sh.lineCap.rawValue) join=\(sh.lineJoin.rawValue) path=\(els.joined(separator: " "))\n").data(using: .utf8)!)
                    }
                    for s in l.sublayers ?? [] { dump(s, d + 1) }
                }
                if let w = NSApp.windows.first, let tf = w.contentView?.superview { FileHandle.standardError.write("TREE window active=\(w.isKeyWindow) main=\(w.isMainWindow) appearance=\(w.effectiveAppearance.name.rawValue)\n".data(using: .utf8)!); if let l = tf.layer { dump(l, 0) } }
            }
        }
        .onAppear { NSEvent.addLocalMonitorForEvents(matching: .any) { e in FileHandle.standardError.write("EVENT \(e.type.rawValue) chars=\(e.type == .keyDown || e.type == .keyUp ? "\(e.characters ?? "nil")/\(e.keyCode)/\(e.modifierFlags.rawValue)" : "-") at \(e.locationInWindow) win \(e.windowNumber) frame \(String(describing: e.window?.frame)) content \(String(describing: e.window?.contentLayoutRect)) screen \(String(describing: NSScreen.main?.frame)) vis \(String(describing: NSScreen.main?.visibleFrame)) cg \(String(describing: e.cgEvent?.location))\n".data(using: .utf8)!); return e } }
    }
}

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup { Content().preferredColorScheme(UserDefaults.standard.bool(forKey: "dark") ? .dark : nil) }
    }
}
