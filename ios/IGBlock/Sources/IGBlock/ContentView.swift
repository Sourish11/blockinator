import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSettingsPresented = false

    var body: some View {
        WebViewContainer(
            onWebViewCreated: { webView in appState.attach(webView: webView) },
            onRoute: { path in appState.onRouteChanged(path) }
        )
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            SettingsButton { isSettingsPresented = true }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(appState: appState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                appState.appDidBecomeActive()
            } else {
                appState.appDidResignActive()
            }
        }
    }
}
