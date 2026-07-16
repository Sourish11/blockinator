(function () {
  if (window.__igblockShimInstalled) {
    return;
  }
  window.__igblockShimInstalled = true;

  function reportRoute() {
    if (window.AndroidBridge && window.AndroidBridge.onRouteChanged) {
      window.AndroidBridge.onRouteChanged(window.location.pathname);
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
