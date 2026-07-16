package com.sourish.igblock

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RouteClassifierTest {

    @Test
    fun `reels tab is restricted`() {
        assertTrue(RouteClassifier.isRestricted("/reels/"))
    }

    @Test
    fun `explore tab is restricted`() {
        assertTrue(RouteClassifier.isRestricted("/explore/"))
    }

    @Test
    fun `explore with a sub path is restricted`() {
        assertTrue(RouteClassifier.isRestricted("/explore/tags/travel/"))
    }

    @Test
    fun `a single reel permalink is not restricted`() {
        assertFalse(RouteClassifier.isRestricted("/reel/CxYzAbC123/"))
    }

    @Test
    fun `a post permalink is not restricted`() {
        assertFalse(RouteClassifier.isRestricted("/p/CxYzAbC123/"))
    }

    @Test
    fun `direct messages are not restricted`() {
        assertFalse(RouteClassifier.isRestricted("/direct/inbox/"))
    }

    @Test
    fun `a profile page is not restricted`() {
        assertFalse(RouteClassifier.isRestricted("/someusername/"))
    }

    @Test
    fun `the home feed is not restricted`() {
        assertFalse(RouteClassifier.isRestricted("/"))
    }
}
