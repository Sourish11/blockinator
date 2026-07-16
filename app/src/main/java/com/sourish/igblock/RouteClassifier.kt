package com.sourish.igblock

object RouteClassifier {
    private val RESTRICTED_SEGMENTS = setOf("reels", "explore")

    fun isRestricted(path: String): Boolean {
        val firstSegment = path.trim('/').substringBefore('/')
        return firstSegment in RESTRICTED_SEGMENTS
    }
}
