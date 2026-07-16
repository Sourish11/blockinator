import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        WebViewContainer(
            onWebViewCreated: { webView in appState.attach(webView: webView) },
            onRoute: { path in appState.onRouteChanged(path) }
        )
        .ignoresSafeArea()
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                appState.appDidBecomeActive()
            } else {
                appState.appDidResignActive()
            }
        }
    }
}
