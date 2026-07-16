package com.sourish.igblock

import android.os.Bundle
import android.os.CountDownTimer
import android.util.Log
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    private lateinit var allowanceTracker: AllowanceTracker
    private var countdownTimer: CountDownTimer? = null
    private var overlayShown = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        allowanceTracker = AllowanceTracker(SharedPreferencesAllowanceStore(applicationContext))

        webView = findViewById(R.id.webview)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true

        CookieManager.getInstance().setAcceptCookie(true)
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true)

        webView.addJavascriptInterface(RouteBridge { path -> onRouteChanged(path) }, "AndroidBridge")

        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String?) {
                super.onPageFinished(view, url)
                view.evaluateJavascript(loadAsset("route_shim.js"), null)
            }
        }

        webView.loadUrl("https://www.instagram.com")
    }

    private fun onRouteChanged(path: String) {
        Log.d("MainActivity", "route changed: $path")
        allowanceTracker.resetIfNewDay()

        if (!RouteClassifier.isRestricted(path)) {
            stopCountdown()
            hideOverlayIfShown()
            return
        }

        if (allowanceTracker.isExhausted()) {
            showOverlayIfNotShown()
            stopCountdown()
        } else {
            hideOverlayIfShown()
            startCountdown()
        }
    }

    private fun startCountdown() {
        if (countdownTimer != null) return
        val remainingMillis = allowanceTracker.remainingSeconds() * 1000L
        countdownTimer = object : CountDownTimer(remainingMillis, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                allowanceTracker.consumeSecond()
            }

            override fun onFinish() {
                allowanceTracker.consumeSecond()
                countdownTimer = null
                showOverlayIfNotShown()
            }
        }.also { it.start() }
    }

    private fun stopCountdown() {
        countdownTimer?.cancel()
        countdownTimer = null
    }

    private fun showOverlayIfNotShown() {
        if (!overlayShown) {
            OverlayController.show(webView)
            overlayShown = true
        }
    }

    private fun hideOverlayIfShown() {
        if (overlayShown) {
            OverlayController.hide(webView)
            overlayShown = false
        }
    }

    private fun loadAsset(name: String): String =
        assets.open(name).bufferedReader().use { it.readText() }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        webView.saveState(outState)
    }

    override fun onRestoreInstanceState(savedInstanceState: Bundle) {
        super.onRestoreInstanceState(savedInstanceState)
        webView.restoreState(savedInstanceState)
    }
}
