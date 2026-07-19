public enum RouteClassifier {
    public static func isRestricted(path: String, enabledSections: Set<RestrictedSection>) -> Bool {
        guard let segment = firstSegment(of: path) else { return false }
        if enabledSections.contains(.reels) && segment == "reels" { return true }
        if enabledSections.contains(.explore) && segment == "explore" { return true }
        return false
    }

    /// Broader than `isRestricted` — also includes the singular `/reel/<id>/` permalink
    /// pattern used both for reels shared via DM/profile AND, potentially, for an
    /// individual full-screen reel reached by browsing the Reels tab itself. This does
    /// NOT by itself mean "block this route" (a freshly-opened DM-shared reel must stay
    /// accessible) — callers combine it with whether the user was already in a
    /// restricted session to decide that.
    ///
    /// Each segment only counts when its corresponding section is enabled: `"reel"`
    /// (singular) is tied to `.reels` (it's the reels-tab-adjacent permalink pattern),
    /// and `"explore"` is tied to `.explore` — so disabling Explore also stops it from
    /// keeping an active Reels session "sticky."
    public static func isPartOfReelsSession(path: String, enabledSections: Set<RestrictedSection>) -> Bool {
        guard let segment = firstSegment(of: path) else { return false }
        if enabledSections.contains(.reels) && (segment == "reels" || segment == "reel") { return true }
        if enabledSections.contains(.explore) && segment == "explore" { return true }
        return false
    }

    private static func firstSegment(of path: String) -> String? {
        path.split(separator: "/", omittingEmptySubsequences: true).first.map(String.init)
    }
}
