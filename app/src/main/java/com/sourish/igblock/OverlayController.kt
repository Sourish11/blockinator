package com.sourish.igblock

import android.webkit.WebView

object OverlayController {

    private const val OVERLAY_ELEMENT_ID = "igblock-overlay"

    fun show(webView: WebView) {
        val js = """
            (function() {
              if (document.getElementById('$OVERLAY_ELEMENT_ID')) { return; }
              var overlay = document.createElement('div');
              overlay.id = '$OVERLAY_ELEMENT_ID';
              overlay.style.position = 'fixed';
              overlay.style.top = '0';
              overlay.style.left = '0';
              overlay.style.width = '100vw';
              overlay.style.height = '100vh';
              overlay.style.zIndex = '999999';
              overlay.style.backdropFilter = 'blur(20px)';
              overlay.style.background = 'rgba(0,0,0,0.4)';
              overlay.style.display = 'flex';
              overlay.style.alignItems = 'center';
              overlay.style.justifyContent = 'center';
              overlay.style.color = 'white';
              overlay.style.fontSize = '20px';
              overlay.style.fontFamily = 'sans-serif';
              overlay.style.textAlign = 'center';
              overlay.textContent = 'Out of time — back tomorrow';
              document.body.appendChild(overlay);
            })();
        """.trimIndent()
        webView.evaluateJavascript(js, null)
    }

    fun hide(webView: WebView) {
        val js = """
            (function() {
              var overlay = document.getElementById('$OVERLAY_ELEMENT_ID');
              if (overlay) { overlay.remove(); }
            })();
        """.trimIndent()
        webView.evaluateJavascript(js, null)
    }
}
