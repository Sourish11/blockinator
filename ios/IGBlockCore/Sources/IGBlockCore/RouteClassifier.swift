public enum RouteClassifier {
    private static let restrictedSegments: Set<String> = ["reels", "explore"]

    public static func isRestricted(path: String) -> Bool {
        let firstSegment = path.split(separator: "/", omittingEmptySubsequences: true).first.map(String.init) ?? ""
        return restrictedSegments.contains(firstSegment)
    }
}
