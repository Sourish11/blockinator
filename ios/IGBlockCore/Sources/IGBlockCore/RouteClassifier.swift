public enum RouteClassifier {
    private static let restrictedSegments: Set<String> = ["reels", "explore"]
    private static let reelsFamilySegments: Set<String> = ["reels", "explore", "reel"]

    public static func isRestricted(path: String) -> Bool {
        firstSegment(of: path).map(restrictedSegments.contains) ?? false
    }

    /// Broader than `isRestricted` — also includes the singular `/reel/<id>/` permalink
    /// pattern used both for reels shared via DM/profile AND, potentially, for an
    /// individual full-screen reel reached by browsing the Reels tab itself. This does
    /// NOT by itself mean "block this route" (a freshly-opened DM-shared reel must stay
    /// accessible) — callers combine it with whether the user was already in a
    /// restricted session to decide that.
    public static func isPartOfReelsSession(path: String) -> Bool {
        firstSegment(of: path).map(reelsFamilySegments.contains) ?? false
    }

    private static func firstSegment(of path: String) -> String? {
        path.split(separator: "/", omittingEmptySubsequences: true).first.map(String.init)
    }
}
