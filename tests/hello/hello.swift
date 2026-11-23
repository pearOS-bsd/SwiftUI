// A small SwiftUI app: a window (WindowGroup) with Text, a Button that counts, a Toggle and shapes.  Built on a Mac (swiftc, x86_64) and run on pearOS to see how far real SwiftUI gets.
import SwiftUI
import Darwin

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
            if UserDefaults.standard.bool(forKey: "settext") { Button("Set text") { text = "zzz" } }
            Toggle("Enabled", isOn: $on)
            TextField("Type here", text: $text).frame(width: 200).focused($focused).onChange(of: text) { FileHandle.standardError.write("TEXTCHANGE \(text)\n".data(using: .utf8)!) }
            Text("typed: \(text)")
            if UserDefaults.standard.bool(forKey: "gradient") { Rectangle().fill(LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing)).frame(width: 100, height: 30) }
            if UserDefaults.standard.bool(forKey: "pathstroke") { Path { p in p.move(to: CGPoint(x: 4, y: 4)); p.addLine(to: CGPoint(x: 70, y: 40)); p.addQuadCurve(to: CGPoint(x: 4, y: 40), control: CGPoint(x: 40, y: 4)) }.stroke(Color.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)).frame(width: 80, height: 50) }
            if UserDefaults.standard.bool(forKey: "radial") { Rectangle().fill(RadialGradient(colors: [.white, .black], center: .center, startRadius: 0, endRadius: 40)).frame(width: 80, height: 50) }
            if UserDefaults.standard.bool(forKey: "angular") { Rectangle().fill(AngularGradient(colors: [.red, .blue, .red], center: .center)).frame(width: 60, height: 60) }
            if UserDefaults.standard.bool(forKey: "gradient2") {
                Rectangle().fill(LinearGradient(colors: [.white, .black], startPoint: .leading, endPoint: .trailing)).frame(width: 90, height: 20)
                Rectangle().fill(LinearGradient(colors: [.red, .red], startPoint: .leading, endPoint: .trailing)).frame(width: 90, height: 21)
                Rectangle().fill(LinearGradient(colors: [.blue, .blue], startPoint: .leading, endPoint: .trailing)).frame(width: 90, height: 22)
            }
            if UserDefaults.standard.bool(forKey: "shadow") { Rectangle().fill(Color.white).frame(width: 80, height: 40).shadow(color: .black, radius: 8, x: 4, y: 6) }
            if UserDefaults.standard.bool(forKey: "stroke") { RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 4).frame(width: 100, height: 50) }
            if UserDefaults.standard.bool(forKey: "box") { Rectangle().fill(Color.gray).frame(width: 200, height: 70) }
            if UserDefaults.standard.bool(forKey: "scroll2") { ScrollView { Text("one row") }.frame(width: 100, height: 40) }
            if UserDefaults.standard.bool(forKey: "scroll3") { ScrollView(.horizontal) { Text("one row") }.frame(width: 100, height: 40) }
            if UserDefaults.standard.bool(forKey: "nsscroll") { PlainScroll().frame(width: 150, height: 60) }
            if UserDefaults.standard.bool(forKey: "scroll") { ScrollView { VStack { ForEach(0..<40, id: \.self) { Text("row \($0)") } } }.scrollIndicators(UserDefaults.standard.bool(forKey: "noind") ? .hidden : .automatic).frame(width: 200, height: 70) }
            HStack { Circle().fill(.red).frame(width: 30, height: 30); Rectangle().fill(.blue).frame(width: 60, height: 30) }
        }.padding(30)
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in if UserDefaults.standard.bool(forKey: "tick") { n += 1 } }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { if UserDefaults.standard.bool(forKey: "focus") { NSApp.activate(ignoringOtherApps: true); NSApp.windows.first?.makeKeyAndOrderFront(nil) } }
            DispatchQueue.main.asyncAfter(deadline: .now() + (UserDefaults.standard.double(forKey: "focusdelay") > 0 ? UserDefaults.standard.double(forKey: "focusdelay") : 4)) { if UserDefaults.standard.bool(forKey: "focus") { focused = true } }
            let dumpTree: () -> Void = {
                let u = UserDefaults.standard
                FileHandle.standardError.write("DEFS test=\(String(describing: u.object(forKey: "HelloTestKey"))) testApp=\(String(describing: u.object(forKey: "HelloAppKey")))\n".data(using: .utf8)!)
                FileHandle.standardError.write("DEFS style=\(String(describing: u.string(forKey: "AppleInterfaceStyle"))) cf=\(String(describing: CFPreferencesCopyValue("AppleInterfaceStyle" as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost))) cfCurHost=\(String(describing: CFPreferencesCopyValue("AppleInterfaceStyle" as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost))) app=\(NSApp.effectiveAppearance.name.rawValue)\n".data(using: .utf8)!)
                FileHandle.standardError.write("DEFS showScrollBars=\(String(describing: u.object(forKey: "AppleShowScrollBars"))) paging=\(String(describing: u.object(forKey: "AppleScrollerPagingBehavior"))) style=\(NSScroller.preferredScrollerStyle.rawValue) mainWindow=\(String(describing: NSApp.mainWindow)) n=\(NSApp.windows.count)\n".data(using: .utf8)!)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if UserDefaults.standard.bool(forKey: "poke") {
                    FileHandle.standardError.write("POKE displayIfNeeded\n".data(using: .utf8)!)
                    if let w = NSApp.windows.first { w.contentView?.needsDisplay = true; w.displayIfNeeded(); w.makeKeyAndOrderFront(nil); w.contentView?.layer?.setNeedsDisplay(); CATransaction.flush() }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                for w in NSApp.windows { FileHandle.standardError.write("WINS cs=\(String(describing: w.colorSpace?.localizedName)) screen=\(String(describing: w.screen?.localizedName)) \(type(of: w)) frame=\(w.frame) key=\(w.isKeyWindow) main=\(w.isMainWindow) visible=\(w.isVisible) level=\(w.level.rawValue) title=\(w.title) fr=\(String(describing: w.firstResponder.map { String(describing: type(of: $0)) })) num=\(w.windowNumber)\n".data(using: .utf8)!) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                func dump(_ l: CALayer, _ d: Int) {
                    let c = l.backgroundColor.flatMap { $0.components } ?? []
                    let line = String(repeating: " ", count: d) + "\(type(of: l)) f=\(l.frame) op=\(l.opacity) hid=\(l.isHidden) bg=\(c) cr=\(l.cornerRadius) contents=\(l.contents != nil) shadow[op=\(l.shadowOpacity) r=\(l.shadowRadius) off=\(l.shadowOffset) col=\(String(describing: l.shadowColor?.components))] border=\(l.borderWidth)" + ((l as? CAGradientLayer).map { g in " GRAD colors=\((g.colors ?? []).map { c in String(describing: (c as! CGColor).components) }) loc=\(String(describing: g.locations)) start=\(g.startPoint) end=\(g.endPoint) cs=\(String(describing: (g.colors?.first).map { ($0 as! CGColor).colorSpace?.name }))" } ?? "")
                    FileHandle.standardError.write(("TREE " + line + "\n").data(using: .utf8)!)
                    if let sh = l as? CAShapeLayer {
                        var els: [String] = []
                        sh.path?.applyWithBlock { e in let p = e.pointee; switch p.type { case .moveToPoint: els.append("M \(p.points[0].x),\(p.points[0].y)"); case .addLineToPoint: els.append("L \(p.points[0].x),\(p.points[0].y)"); case .addQuadCurveToPoint: els.append("Q"); case .addCurveToPoint: els.append("C \(p.points[2].x),\(p.points[2].y)"); case .closeSubpath: els.append("Z"); @unknown default: els.append("?") } }
                        FileHandle.standardError.write(("TREESHAPE bbox=\(String(describing: sh.path?.boundingBox)) fill=\(String(describing: sh.fillColor?.components)) stroke=\(String(describing: sh.strokeColor?.components)) lw=\(sh.lineWidth) cap=\(sh.lineCap.rawValue) join=\(sh.lineJoin.rawValue) path=\(els.joined(separator: " "))\n").data(using: .utf8)!)
                    }
                    for s in l.sublayers ?? [] { dump(s, d + 1) }
                }
                if let w = NSApp.windows.first(where: { $0.frame.width > 800 }), let tf = w.contentView?.superview { FileHandle.standardError.write("TREE window active=\(w.isKeyWindow) main=\(w.isMainWindow) appearance=\(w.effectiveAppearance.name.rawValue)\n".data(using: .utf8)!); if let l = tf.layer { dump(l, 0) } }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { dumpTree() }
            if UserDefaults.standard.integer(forKey: "treeat") > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(UserDefaults.standard.integer(forKey: "treeat"))) { FileHandle.standardError.write("TREE2 ---\n".data(using: .utf8)!); dumpTree() } }
        }
        .onAppear { NSEvent.addLocalMonitorForEvents(matching: .any) { e in FileHandle.standardError.write("EVENT \(e.type.rawValue) chars=\(e.type == .keyDown || e.type == .keyUp ? "\(e.characters ?? "nil")/\(e.keyCode)/\(e.modifierFlags.rawValue)" : "-") at \(e.locationInWindow) win \(e.windowNumber) frame \(String(describing: e.window?.frame)) content \(String(describing: e.window?.contentLayoutRect)) screen \(String(describing: NSScreen.main?.frame)) vis \(String(describing: NSScreen.main?.visibleFrame)) cg \(String(describing: e.cgEvent?.location))\n".data(using: .utf8)!); return e } }
    }
}

/* -msglog N: from N seconds on (for 15 s) the Objective-C runtime logs every message send that misses the cache to /tmp/msgSends-<pid> */
@_silgen_name("instrumentObjcMessageSends") func instrumentObjcMessageSends(_ on: Bool)
func installMsgLog(from secs: Int) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(secs)) { instrumentObjcMessageSends(true) }
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(secs + 15)) { instrumentObjcMessageSends(false) }
}

/* -stackdump N: after N seconds every thread prints its call stack (where is a program that never commits waiting?) */
func installStackDump(after secs: Int) {
    signal(SIGUSR2) { _ in
        var bt = [UnsafeMutableRawPointer?](repeating: nil, count: 48); let n = backtrace(&bt, 48)
        let hdr = "STACKDUMP thread \(mach_thread_self()):\n"; _ = hdr.withCString { write(2, $0, strlen($0)) }
        backtrace_symbols_fd(&bt, n, 2)
    }
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(secs)) {
        var th: thread_act_array_t? = nil; var cnt: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &th, &cnt) == KERN_SUCCESS, let ths = th else { return }
        FileHandle.standardError.write("STACKDUMP threads \(cnt)\n".data(using: .utf8)!)
        var sent = 0
        for i in 0..<Int(cnt) { if ths[i] == mach_thread_self() { continue }; if let pt = pthread_from_mach_thread_np(ths[i]) { pthread_kill(pt, SIGUSR2); sent += 1; usleep(150_000) } }
        FileHandle.standardError.write("STACKDUMP sent \(sent)\n".data(using: .utf8)!)
    }
}

final class DLCounter: NSObject { var ticks = 0; @objc func tick(_ l: CADisplayLink) { ticks += 1 } }
let dlCounter = DLCounter()
func startDLCount() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        guard let v = NSApp.windows.first(where: { $0.contentView != nil })?.contentView else { return }
        let l = v.displayLink(target: dlCounter, selector: #selector(DLCounter.tick(_:))); l.add(to: .main, forMode: .common)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { FileHandle.standardError.write("DLCOUNT \(dlCounter.ticks) ticks in 3 s\n".data(using: .utf8)!) }
    }
}

struct PlainScroll: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView {
        let sv = NSScrollView(); sv.hasVerticalScroller = true
        let doc = NSView(frame: NSRect(x: 0, y: 0, width: 130, height: 300)); doc.wantsLayer = true; doc.layer?.backgroundColor = NSColor.systemOrange.cgColor
        sv.documentView = doc; return sv
    }
    func updateNSView(_ nsView: NSScrollView, context: Context) {}
}

@main
struct HelloApp: App {
    init() { let ml = UserDefaults.standard.integer(forKey: "msglog"); if ml > 0 { installMsgLog(from: ml) }; if UserDefaults.standard.bool(forKey: "dlcount") { startDLCount() }; let n = UserDefaults.standard.integer(forKey: "stackdump"); if n > 0 { installStackDump(after: n) } }
    var body: some Scene {
        WindowGroup { Content().preferredColorScheme(UserDefaults.standard.bool(forKey: "dark") ? .dark : nil) }
    }
}
