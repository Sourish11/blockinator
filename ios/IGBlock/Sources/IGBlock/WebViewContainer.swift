import SwiftUI
import WebKit
import IGBlockCore

struct WebViewContainer: UIViewRepresentable {
    let onWebViewCreated: (WKWebView) -> Void
    let onRoute: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onRoute: onRoute)
    }

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
        // Instagram serves a different (often broken/desktop-ish/degraded) layout to
        // WebViews it detects aren't real mobile Safari, and it also does version-aware
        // content negotiation — an outdated OS/Safari version in the UA can get served
        // an older, simplified template. Spoof a UA matching the device's ACTUAL iOS
        // version (checked directly via `ideviceinfo`, not assumed) to get the real,
        // current mobile experience.
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.1 Mobile/15E148 Safari/604.1"
        // Real Safari lets you swipe from the left edge to go back — without this,
        // there's no way to navigate "back" out of a section (e.g. DMs) since we
        // provide no native chrome of our own and rely entirely on Instagram's own
        // in-page navigation, which isn't always sufficient on its own.
        webView.allowsBackForwardNavigationGestures = true
        // Lock the page to exact 1:1 rendering. Without this, the page can render at
        // a zoomed-out scale (e.g. if its viewport meta isn't being honored the way
        // real Safari would, or pinch-zoom state gets stuck) — which shrinks
        // everything visually AND desyncs where a button visually appears from where
        // its actual tap target is, since WebKit's hit-testing operates in the page's
        // own zoomed coordinate space. Forcing scale to 1.0 makes visual position and
        // touch position match exactly, regardless of what the page's own viewport
        // meta tag does or doesn't declare.
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bouncesZoom = false
        onWebViewCreated(webView)
        // Belt-and-suspenders route detection: the JS shim's pushState/replaceState
        // patching can be silently overridden if Instagram's own SPA router captures
        // and reassigns history.pushState after our WKUserScript runs. WKWebView's own
        // `url` property is updated by WebKit at the engine level for ALL navigation,
        // including client-side route changes, independent of whatever the page's JS
        // does to the history API — so it's a more reliable signal than the JS shim
        // alone. Both report the same path; onRouteChanged is idempotent per-path.
        context.coordinator.observe(webView)
        webView.load(URLRequest(url: URL(string: "https://www.instagram.com")!))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject {
        private let onRoute: (String) -> Void
        private var observation: NSKeyValueObservation?

        init(onRoute: @escaping (String) -> Void) {
            self.onRoute = onRoute
        }

        func observe(_ webView: WKWebView) {
            observation = webView.observe(\.url, options: [.new]) { [weak self] _, change in
                Task { @MainActor [weak self] in
                    guard let url = change.newValue ?? nil else { return }
                    #if DEBUG
                    NSLog("[IGBLOCK-DIAG] KVO webView.url changed, path=\(url.path)")
                    #endif
                    self?.onRoute(url.path)
                }
            }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    private let tracker = AllowanceTracker(store: UserDefaultsAllowanceStore())
    private var countdownTimer: Timer?
    private var overlayShown = false
    private weak var webView: WKWebView?
    private var lastKnownPath: String?
    // Sticky flag: once a route change lands on a genuinely restricted path
    // (/reels/, /explore/), this stays true across subsequent navigation within the
    // "reels family" (including the singular /reel/<id>/ pattern) — e.g. tapping into
    // an individual full-screen reel from within the Reels tab — so that browsing
    // individual reels reached FROM an already-restricted session still counts against
    // the allowance, regardless of what URL segment that per-reel view happens to use.
    // It only clears once the user reaches a path outside the reels family entirely
    // (DMs, profile, home, search, ...). A reel opened directly via a DM/profile link,
    // without ever passing through /reels/ or /explore/ first, never sets this flag,
    // so it correctly stays unrestricted — the deliberate DM-shared-reel exception.
    private var inReelsSession = false

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func onRouteChanged(_ path: String) {
        lastKnownPath = path
        tracker.resetIfNewDay()

        let baseRestricted = RouteClassifier.isRestricted(path: path)
        let partOfReelsSession = RouteClassifier.isPartOfReelsSession(path: path)

        let restricted: Bool
        if baseRestricted {
            inReelsSession = true
            restricted = true
        } else if partOfReelsSession && inReelsSession {
            restricted = true
        } else {
            inReelsSession = false
            restricted = false
        }

        #if DEBUG
        NSLog("[IGBLOCK-DIAG] onRouteChanged path=\(path) baseRestricted=\(baseRestricted) partOfReelsSession=\(partOfReelsSession) inReelsSession=\(inReelsSession) restricted=\(restricted) exhausted=\(tracker.isExhausted()) remaining=\(tracker.remainingSeconds())")
        #endif

        guard restricted else {
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
        guard countdownTimer == nil else {
            #if DEBUG
            NSLog("[IGBLOCK-DIAG] startCountdown: already running, skipping")
            #endif
            return
        }
        #if DEBUG
        NSLog("[IGBLOCK-DIAG] startCountdown: starting new timer, remaining=\(tracker.remainingSeconds())")
        #endif
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.tracker.consumeSecond()
                #if DEBUG
                NSLog("[IGBLOCK-DIAG] tick: remaining=\(self.tracker.remainingSeconds())")
                #endif
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
        #if DEBUG
        NSLog("[IGBLOCK-DIAG] showOverlayIfNotShown called: overlayShown=\(overlayShown) webViewIsNil=\(webView == nil)")
        #endif
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
