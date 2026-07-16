(function () {
  if (window.__igblockShimInstalled) {
    return;
  }
  window.__igblockShimInstalled = true;

  function reportRoute() {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.RouteBridge) {
      window.webkit.messageHandlers.RouteBridge.postMessage(window.location.pathname);
    }
  }

  var originalPushState = history.pushState;
  history.pushState = function () {
    originalPushState.apply(history, arguments);
    reportRoute();
  };

  var originalReplaceState = history.replaceState;
  history.replaceState = function () {
    originalReplaceState.apply(history, arguments);
    reportRoute();
  };

  window.addEventListener('popstate', reportRoute);

  reportRoute();
})();
