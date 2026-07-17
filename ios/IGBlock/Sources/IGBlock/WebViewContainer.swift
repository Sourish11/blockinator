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
        // Instant autoplay, matching the native app. Trade-off (deliberate, per
        // product decision): this does increase how often WebKit's content process
        // gets killed for memory pressure during extended Reels scrolling, since every
        // reel starts decoding video the instant it's in view rather than gating on a
        // tap. The friction this app adds is meant to target the scrolling itself, not
        // degrade Instagram's actual playback quality — so autoplay stays on, and the
        // crash is handled via recovery (see webViewWebContentProcessDidTerminate)
        // instead of disabling the feature that triggers it more often.
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.preferredContentMode = .mobile
        configuration.defaultWebpagePreferences = webpagePreferences

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
        // Heavy autoplaying video (exactly what Reels is) can push WebKit's content
        // process over its memory budget, causing iOS to kill it outright. Without a
        // navigation delegate to catch that, the WebView is left permanently blank
        // (black/white screen) with no way to recover short of force-quitting the app.
        // Reloading on termination is the standard, documented recovery.
        webView.navigationDelegate = context.coordinator
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
    final class Coordinator: NSObject, WKNavigationDelegate {
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

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            // Reload the site root rather than `webView.reload()` (which retries the
            // exact URL that was loaded when the crash happened). A deep client-side
            // route like /reels/<id>/ is only meaningful as a pushState destination
            // within a live SPA session -- hitting it as a fresh, real HTTP GET (which
            // is what a genuine reload after a process kill is) isn't the same
            // situation the SPA router expects, and can redirect somewhere unpredictable.
            // Reloading the root is the one URL guaranteed to load cleanly.
            #if DEBUG
            NSLog("[IGBLOCK-DIAG] WebContent process terminated (likely memory pressure) — reloading site root")
            #endif
            webView.load(URLRequest(url: URL(string: "https://www.instagram.com")!))
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
    // See ReelsSessionTracker in IGBlockCore: allows the one specific reel someone
    // sends you directly (never having visited /reels/ or /explore/ first), but starts
    // counting the moment a DIFFERENT reel appears while still in reel territory —
    // i.e. swiping onward into the algorithmic feed, not watching what was sent.
    private var reelsSession = ReelsSessionTracker()

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func onRouteChanged(_ path: String) {
        lastKnownPath = path
        tracker.resetIfNewDay()

        let restricted = reelsSession.update(path: path)

        #if DEBUG
        NSLog("[IGBLOCK-DIAG] onRouteChanged path=\(path) inSession=\(reelsSession.inSession) restricted=\(restricted) exhausted=\(tracker.isExhausted()) remaining=\(tracker.remainingSeconds())")
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
