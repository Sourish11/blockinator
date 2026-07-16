import SwiftUI
import WebKit
import IGBlockCore

struct WebViewContainer: UIViewRepresentable {
    let onWebViewCreated: (WKWebView) -> Void
    let onRoute: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(RouteBridge(onRoute: onRoute), name: "RouteBridge")

        guard let shimURL = Bundle.module.url(forResource: "route_shim", withExtension: "js"),
              let shimSource = try? String(contentsOf: shimURL, encoding: .utf8) else {
            fatalError("route_shim.js missing from bundle resources")
        }
        let shimScript = WKUserScript(source: shimSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(shimScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        onWebViewCreated(webView)
        webView.load(URLRequest(url: URL(string: "https://www.instagram.com")!))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@MainActor
final class AppState: ObservableObject {
    private let tracker = AllowanceTracker(store: UserDefaultsAllowanceStore())
    private var countdownTimer: Timer?
    private var overlayShown = false
    private weak var webView: WKWebView?
    private var lastKnownPath: String?

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func onRouteChanged(_ path: String) {
        lastKnownPath = path
        tracker.resetIfNewDay()

        guard RouteClassifier.isRestricted(path: path) else {
            stopCountdown()
            hideOverlayIfShown()
            return
        }

        if tracker.isExhausted() {
            showOverlayIfNotShown()
            stopCountdown()
        } else {
            hideOverlayIfShown()
            startCountdown()
        }
    }

    /// Called when the app resigns active (backgrounded) — stops the countdown without
    /// touching the persisted allowance, mirroring the Android `onPause` fix.
    func appDidResignActive() {
        stopCountdown()
    }

    /// Called when the app returns to active — re-derives state from the last known
    /// route rather than assuming anything, mirroring the Android `onResume` fix.
    func appDidBecomeActive() {
        guard let lastKnownPath else { return }
        onRouteChanged(lastKnownPath)
    }

    private func startCountdown() {
        guard countdownTimer == nil else { return }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.tracker.consumeSecond()
                if self.tracker.isExhausted() {
                    self.stopCountdown()
                    self.showOverlayIfNotShown()
                }
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func showOverlayIfNotShown() {
        guard !overlayShown, let webView else { return }
        OverlayController.show(in: webView)
        overlayShown = true
    }

    private func hideOverlayIfShown() {
        guard overlayShown, let webView else { return }
        OverlayController.hide(in: webView)
        overlayShown = false
    }
}
