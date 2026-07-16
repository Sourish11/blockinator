package com.sourish.igblock

import android.util.Log
import android.webkit.JavascriptInterface
import com.sourish.igblock.BuildConfig

class RouteBridge(private val onRoute: (String) -> Unit) {
    @JavascriptInterface
    fun onRouteChanged(path: String) {
        if (BuildConfig.DEBUG) {
            Log.d("RouteBridge", "route changed: $path")
        }
        onRoute(path)
    }
}
