/// Tracks whether the current position in Instagram's reel-viewing flow should count
/// against the daily allowance.
///
/// A reel opened directly (e.g. shared via DM, or tapped from a friend's profile,
/// without ever visiting the Reels/Explore tab) is exempt for exactly that one reel —
/// "watch the specific thing someone sent you" is the deliberate use case this app
/// preserves. But Instagram's reel player lets you swipe from any reel into its
/// algorithmic recommendation stream regardless of entry point, so the moment a
/// *different* reel appears while still inside reel territory — without the user
/// having navigated away to a genuinely different section first — that's swiping
/// onward into the feed, not watching what was sent, and starts counting.
///
/// Entering the Reels or Explore tab directly is always counted immediately, with no
/// grace period — there's no legitimate "someone sent me a link to the whole tab" case.
public struct ReelsSessionTracker {
    public private(set) var inSession = false
    private var coldEntryPath: String?

    public init() {}

    /// Call on every route change. Returns whether the new path should count against
    /// the allowance, and updates internal state for the next call.
    @discardableResult
    public mutating func update(path: String, enabledSections: Set<RestrictedSection>) -> Bool {
        let baseRestricted = RouteClassifier.isRestricted(path: path, enabledSections: enabledSections)
        let partOfReelsSession = RouteClassifier.isPartOfReelsSession(path: path, enabledSections: enabledSections)

        if baseRestricted {
            inSession = true
            coldEntryPath = nil
            return true
        }

        guard partOfReelsSession else {
            inSession = false
            coldEntryPath = nil
            return false
        }

        if inSession {
            return true
        }

        if coldEntryPath == nil || coldEntryPath == path {
            coldEntryPath = path
            return false
        }

        inSession = true
        coldEntryPath = nil
        return true
    }
}
