import WebKit

enum OverlayController {
    private static let overlayElementID = "igblock-overlay"

    static func show(in webView: WKWebView) {
        let js = """
            (function() {
              if (document.getElementById('\(overlayElementID)')) { return; }
              var overlay = document.createElement('div');
              overlay.id = '\(overlayElementID)';
              overlay.style.position = 'fixed';
              overlay.style.top = '0';
              overlay.style.left = '0';
              overlay.style.width = '100vw';
              overlay.style.height = '100vh';
              overlay.style.zIndex = '999999';
              overlay.style.backdropFilter = 'blur(20px)';
              overlay.style.background = 'rgba(0,0,0,0.4)';
              overlay.style.display = 'flex';
              overlay.style.alignItems = 'center';
              overlay.style.justifyContent = 'center';
              overlay.style.color = 'white';
              overlay.style.fontSize = '20px';
              overlay.style.fontFamily = 'sans-serif';
              overlay.style.textAlign = 'center';
              overlay.textContent = 'Out of time \\u2014 back tomorrow';
              document.body.appendChild(overlay);
            })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    static func hide(in webView: WKWebView) {
        let js = """
            (function() {
              var overlay = document.getElementById('\(overlayElementID)');
              if (overlay) { overlay.remove(); }
            })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
