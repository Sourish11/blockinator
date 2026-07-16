package com.sourish.igblock

import android.util.Log
import android.webkit.JavascriptInterface

class RouteBridge(private val onRoute: (String) -> Unit) {
    @JavascriptInterface
    fun onRouteChanged(path: String) {
        Log.d("RouteBridge", "route changed: $path")
        onRoute(path)
    }
}
