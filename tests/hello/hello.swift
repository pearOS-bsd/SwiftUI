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
    }
}

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup { Content() }
    }
}
