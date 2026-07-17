import WebKit

final class RouteBridge: NSObject, WKScriptMessageHandler {
    private let onRoute: (String) -> Void

    init(onRoute: @escaping (String) -> Void) {
        self.onRoute = onRoute
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        #if DEBUG
        NSLog("[IGBLOCK-DIAG] RouteBridge received message.body=\(message.body), asString=\(message.body as? String ?? "nil")")
        #endif
        guard let path = message.body as? String else { return }
        onRoute(path)
    }
}
