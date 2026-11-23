// A small SwiftUI app: a window (WindowGroup) with Text, a Button that counts, a Toggle and shapes.  Built on a Mac (swiftc, x86_64) and run on pearOS to see how far real SwiftUI gets.
import SwiftUI

struct Content: View {
    @State private var n = 0
    @State private var on = true
    var body: some View {
        VStack(spacing: 12) {
            Text("Hello from SwiftUI on pearOS").font(.title)
            Text("count: \(n)").foregroundColor(.secondary)
            Button("Add one") { n += 1 }
            Toggle("Enabled", isOn: $on)
            HStack { Circle().fill(.red).frame(width: 30, height: 30); Rectangle().fill(.blue).frame(width: 60, height: 30) }
        }.padding(30)
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in if UserDefaults.standard.bool(forKey: "tick") { n += 1 } }
        .onAppear { NSEvent.addLocalMonitorForEvents(matching: .any) { e in FileHandle.standardError.write("EVENT \(e.type.rawValue) at \(e.locationInWindow) win \(e.windowNumber) frame \(String(describing: e.window?.frame)) content \(String(describing: e.window?.contentLayoutRect)) screen \(String(describing: NSScreen.main?.frame)) vis \(String(describing: NSScreen.main?.visibleFrame)) cg \(String(describing: e.cgEvent?.location))\n".data(using: .utf8)!); return e } }
    }
}

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup { Content().preferredColorScheme(UserDefaults.standard.bool(forKey: "dark") ? .dark : nil) }
    }
}
