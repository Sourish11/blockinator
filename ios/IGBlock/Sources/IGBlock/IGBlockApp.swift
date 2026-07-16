import SwiftUI
import IGBlockCore

@main
struct IGBlockApp: App {
    var body: some Scene {
        WindowGroup {
            Text("igblock core linked: \(RouteClassifier.isRestricted(path: "/reels/"))")
        }
    }
}
