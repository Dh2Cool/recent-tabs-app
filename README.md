# Safari Recent Tabs

**Command-Tab for Safari tabs.**

Safari Recent Tabs is a native macOS utility that lets you switch between Safari tabs in most-recently-used order, using a Command-Tab-style overlay.

It is built for the places Safari extensions cannot reliably reach: the address bar, Start Page, blank tabs, and browser chrome.

## What It Does

- Press Control-Backtick to open a Safari tab switcher.
- See tabs from the frontmost Safari window in recent order.
- Keep holding Control and press Backtick to cycle.
- Keep holding Control and press Shift-Backtick to cycle backward.
- Release Control to switch to the highlighted tab.
- Use Escape to cancel.
- Works even when focus is in Safari's address bar.

## Why Native?

Safari Web Extensions cannot consistently capture keyboard shortcuts when Safari browser UI has focus. This app uses native macOS APIs for the shortcut and overlay, and Safari automation for tab discovery and switching.

## Privacy

Safari Recent Tabs is designed to stay local.

- No analytics.
- No cloud sync.
- No account.
- No tracking.
- No Screen Recording permission required for the core app.

macOS may ask for Automation permission so the app can read and switch Safari tabs. That permission is used only to control Safari locally.

The switcher uses favicons, titles, and domains by default. That keeps the app fast and avoids asking for broad screen-capture permissions.

## Current Status

This is an early native MVP.

Working:

- Native menu-bar/background app.
- Global Control-Backtick shortcut.
- Command-Tab-style press-and-hold behavior.
- Frontmost Safari window tab switching.
- MRU tab ordering.
- Native floating overlay.
- Favicon/fallback tile display.

Still rough:

- App is not signed/notarized for normal distribution yet.
- No packaged release installer yet.
- All-window switching is planned but not the default yet.

## Run From Source

Requirements:

- macOS 13 or newer
- Xcode command line tools
- Safari

Clone and run:

```bash
git clone https://github.com/Dh2Cool/recent-tabs-app.git
cd recent-tabs-app
./script/build_and_run.sh
```

The script builds a local app bundle at:

```text
dist/SafariRecentTabs.app
```

You can also verify launch:

```bash
./script/build_and_run.sh --verify
```

Run tests:

```bash
swift test
```

## First-Time Permissions

On first use, macOS may ask whether Safari Recent Tabs can control Safari. Click **Allow**.

If the shortcut does not work as expected, check:

```text
System Settings > Privacy & Security > Automation
```

## How To Use

1. Open Safari.
2. Open a few tabs in one Safari window.
3. Launch Safari Recent Tabs.
4. Press Control-Backtick while Safari is frontmost.
5. Keep holding Control and press Backtick again to cycle.
6. Press Shift-Backtick while holding Control to cycle backward.
7. Release Control to switch.

The app intentionally ignores the shortcut when Safari is not the frontmost app.

## Roadmap

- Polished signed release.
- Better README demo media.
- Optional all-Safari-windows mode.
- User-configurable shortcut.
- Cleaner settings/status window.
- Privacy-safe preview strategy for real Safari-rendered tab thumbnails.
- Optional Safari Web Extension companion for richer metadata.

## Development

Project shape:

```text
Sources/SafariRecentTabsApp      macOS app entrypoint and menu-bar lifecycle
Sources/SafariRecentTabsCore     tab models, services, overlay, and testable logic
Tests/SafariRecentTabsTests      XCTest coverage for core behavior
script/build_and_run.sh          local build, bundle, launch, and verify script
```

Useful commands:

```bash
swift test
swift build
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

## Name

The working name is **Safari Recent Tabs**. The product promise is simpler:

> Command-Tab for Safari tabs.
