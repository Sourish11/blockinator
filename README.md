# IG Blocker

Instagram, minus the infinite scroll. IG Blocker wraps Instagram in an embedded browser and blocks the algorithmic **Reels** and **Explore** tabs once a daily time allowance runs out — hard stop, no dismiss button, no "5 more minutes." Everything else (DMs, profile, search, home feed, direct links people send you) stays fully accessible.

No server, no analytics, no account. Your Instagram session and traffic go straight to Instagram's own servers, exactly as if you opened it in a normal browser — this app only decides what to show you.

## Platform status

| Platform | Status |
|---|---|
| **iOS** | Working end-to-end on-device: login persists, Reels/Explore lockout engages correctly (including closing the "swipe through individual reels to dodge the block" loophole), pass-through routes (DMs, profile, search, direct links) unaffected. Built and deployed entirely from Linux via [xtool](https://github.com/xtool-org/xtool) — no Mac, no Xcode required. |
| **Android** | Built, unit tested, and code-reviewed, but not yet exercised on a physical device — full manual QA (allowance countdown, lockout, midnight reset, background persistence) is still outstanding. |

The plan is to bring both platforms to full parity and matching behavior over time — right now iOS is the one that's actually been used and hardened against real Instagram behavior.

## How it works

- **Route detection:** Instagram is a single-page app, so a small JS shim patches `history.pushState`/`replaceState` and reports the current path back to native code (a `@JavascriptInterface` bridge on Android, a `WKScriptMessageHandler` on iOS). iOS also cross-checks against `WKWebView`'s own `url` property as a more robust fallback, since a site's own JS can silently override a patched `pushState`.
- **What counts as "restricted":** the Reels tab, the Explore tab, and — critically — any individual reel reached by browsing *from* either of those, even if that specific reel's URL doesn't itself look like a Reels-tab URL. A reel someone sends you directly (DM, shared link, a friend's profile) is exempt for that one reel, but the moment you swipe past it into more (algorithmically recommended) reels, it starts counting. This distinction is entry-point/sequence based, not just a URL pattern match, since Instagram's own reel player doesn't cleanly separate "the one thing someone sent me" from "the endless recommendation feed" — both live in the same full-screen player.
- **Allowance:** a daily countdown (15 minutes by default), persisted locally, reset once per calendar day. Exhausting it shows a full-screen blurred lockout overlay with no way to dismiss it short of waiting for tomorrow (or leaving the restricted section).

## Setup — iOS (no Mac required)

Built and deployed via [xtool](https://xtool.sh), which builds, signs, and installs iOS apps from Linux/Windows using a Swift toolchain and a Darwin SDK extracted from an Xcode `.xip` — no Xcode installation, no macOS.

1. Install a Swift 6.1+ toolchain (see [swift.org](https://swift.org/install)).
2. Install `xtool`: see the [xtool installation guide](https://github.com/xtool-org/xtool#installation).
3. Download `Xcode.xip` from [developer.apple.com/download](https://developer.apple.com/download/) (any Apple ID, any browser — you're only extracting the SDK, never running Xcode itself). **The Xcode/Swift toolchain versions must match** — a mismatch produces cascading `cannot find type 'Swift' in scope` errors. Swift 6.2 pairs with the Xcode 26.x line.
4. `xtool sdk install <path-to-Xcode.xip>`
5. `xtool auth login` with your Apple ID (free tier works — no paid Developer Program needed for personal device installs).
6. Connect your iPhone via USB, unlock it, and tap "Trust" when prompted.
7. `cd ios/IGBlock && xtool dev` — builds, signs, and installs to your phone.

**Free Apple ID signing expires after 7 days** — just reconnect your phone and re-run `xtool dev` to resign. No paid Developer Program account needed unless you want longer-lived signing or TestFlight distribution.

## Setup — Android

Standard Gradle project.

1. Install Android SDK / command-line tools, set `sdk.dir` in `android/local.properties` (gitignored, not committed).
2. `cd android && ./gradlew assembleDebug`
3. `adb install -r app/build/outputs/apk/debug/app-debug.apk` (with a device connected/emulator running), or `./gradlew installDebug`.

## Testing

- **iOS core logic** (`ios/IGBlockCore/`): pure Swift, no WebKit/UIKit dependency — `cd ios/IGBlockCore && swift test`, no device or simulator needed.
- **Android core logic**: `cd android && ./gradlew testDebugUnitTest`.
- The WebView/UI integration layer on both platforms can only be verified manually, on a real device — there's no iOS Simulator support without a Mac, and the WebView-dependent behavior needs live Instagram to exercise properly.

## Project structure

```
igblock/
├── android/                    Kotlin/Gradle app
└── ios/
    ├── IGBlockCore/             Pure Swift: allowance tracking, route classification (unit tested)
    └── IGBlock/                 xtool/SwiftPM app: WKWebView wrapper, UI, wiring
```

## License

MIT — see [LICENSE](LICENSE).
