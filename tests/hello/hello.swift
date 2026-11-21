// The smallest SwiftUI app: one window with a Text.  Built on a Mac (swiftc, x86_64) and run on pearOS to see how far real SwiftUI gets without the complexity of an Apple app.
import SwiftUI

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello from SwiftUI on pearOS")
                .padding(40)
        }
    }
}
