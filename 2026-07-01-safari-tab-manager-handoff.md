# Safari Tab Manager Handoff

## Current project

This repo is a Safari Web Extension prototype for switching Safari tabs by most-recently-used order. It is packaged inside the generated `SafariRecentTabs/` macOS host app, but almost all product behavior lives in `Extension/`.

The current extension is best understood as a working WebExtension prototype, not the final architecture for a system-wide Safari tab manager.

## What we built

- MRU tab tracking per Safari window.
- Persistent MRU state through `browser.storage.local`.
- A toolbar popup that lists recent tabs.
- A page overlay that behaves like a simple Command-Tab switcher.
- `Control+\`` handling on normal webpages through a content script.
- Current-tab-aware switcher ordering:
  - current tab appears first
  - previous recent tab is highlighted first
  - releasing `Control` switches to the highlighted previous tab
- Favicon/title enrichment:
  - Safari tab metadata first
  - page-reported `<link rel="icon">`
  - `/favicon.ico`
  - blank tile if no icon resolves
- Automated tests for MRU ordering, hydration, metadata fallback, and manifest shortcut constraints.

## Important files

- `Extension/manifest.json`
  - Safari WebExtension manifest.
  - Content script now runs at `document_start`.
  - No `suggested_key` is declared because Safari rejects backtick shortcuts in the manifest.

- `Extension/background/mruTracker.js`
  - Pure JavaScript MRU tracker.
  - Tested with Node.
  - Owns tab ordering, current-tab inclusion, stale tab pruning, hydration, title fallback, and favicon fallback.

- `Extension/background/background.js`
  - Adapts Safari/WebExtension APIs to the tracker.
  - Tracks tab activation/removal.
  - Persists MRU and page metadata.
  - Handles tab activation messages.

- `Extension/overlay/overlay.js`
  - Content-script overlay.
  - Handles `Control+\`` when page content has focus.
  - Reports page title/favicon metadata to the background script.

- `Extension/overlay/overlay.css`
  - Command-Tab-style tile strip UI.

- `Extension/popup/*`
  - Toolbar popup fallback.

- `test/mruTracker.test.js`
  - Behavior tests for MRU and overlay tab view models.

- `test/manifest.test.js`
  - Guards against reintroducing Safari-rejected backtick `suggested_key` values.

## Current limitations

Safari WebExtension content scripts cannot receive keyboard events while Safari browser chrome has focus. That means `Control+\`` cannot be captured by this extension-only implementation when focus is in:

- the address bar
- a blank new tab
- Safari Start Page
- Safari settings
- pages where the extension is not allowed

Safari also rejects backtick as a declared WebExtension command shortcut in this project. We tried a manifest shortcut path and Safari Settings reported:

```text
Invalid suggested_key in the commands manifest entry.
```

Because of that, the extension intentionally does not ship a `suggested_key`.

The extension also cannot reliably show screenshot previews of inactive tabs. The dependable visual fallback is favicon-or-blank.

## How to test the current extension

Run:

```bash
npm test
```

Then build/run through Xcode:

```bash
./script/build_and_run.sh
```

Open `SafariRecentTabs/SafariRecentTabs.xcodeproj`, build and run the host app, enable the extension in Safari, grant website permissions, and refresh existing test pages.

For overlay testing, use normal webpages. Click inside page content, then use `Control+\``. Do not test the extension-only shortcut from the address bar or blank new tab; that requires a native/global helper.

## Shipping model

A Safari Web Extension ships inside a macOS app. It is not shipped as a standalone extension bundle.

For users, the install flow is:

1. Install/open the containing macOS app.
2. Enable the Safari extension in Safari Settings > Extensions.
3. Grant website permissions.

For distribution, the normal polished path is:

1. Keep the Safari Web Extension as an app extension target inside a macOS app.
2. Sign the containing app and extension with Apple Developer certificates.
3. Archive the macOS app in Xcode.
4. Submit through App Store Connect, or distribute a signed/notarized app outside the App Store if that route fits the project.

## Recommended next project

The next project should be a native macOS Safari tab manager, not just a larger WebExtension.

Best shape:

- Native macOS app as the primary product.
- Safari Web Extension as a companion for page-level metadata and optional in-page UI.
- Menu bar/background helper that stays running.
- Global `Control+\`` shortcut registered natively.
- Native overlay window using `NSPanel`, similar to Command-Tab.
- Safari tab discovery and activation through native automation:
  - AppleScript/JXA for Safari tabs
  - Accessibility APIs if needed for deeper UI control
  - extension metadata where available

This can live in the same containing app as the Safari extension. It does not have to be a separate app. In fact, keeping it as one macOS app with an embedded Safari extension is probably the cleanest product and distribution model.

## Native app responsibilities

The native app should own anything that must work outside webpages:

- global shortcut handling
- overlay window rendering
- keyboard repeat/release behavior
- switching from address bar, Start Page, and blank tabs
- cross-window Safari tab activation
- optional tab search/grouping/history later

The Safari extension should own webpage-local metadata:

- title
- favicon
- URL/domain
- optional page state

## Suggested native implementation plan

1. Build a small menu-bar macOS app target.
2. Register a global `Control+\`` shortcut.
3. Poll Safari tabs with AppleScript/JXA and model them as native tab records.
4. Track MRU order natively.
5. Show a borderless/floating `NSPanel` overlay.
6. Match Command-Tab behavior:
   - current tab visible first
   - previous tab highlighted first
   - repeated shortcut cycles
   - key release activates
   - Escape cancels
7. Use the Safari extension only for extra metadata if native Safari automation cannot provide enough.

## Recommendation

Keep this repo as the WebExtension prototype and use it as a reference. Start a new Codex project for the native app so the architecture can be clean from the beginning.

The native app can later embed or reuse parts of this extension, but it should not be forced into the current WebExtension-first structure.
