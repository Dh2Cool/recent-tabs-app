# Safari Recent Tabs

**Command-Tab for Safari tabs.**

![Safari Recent Tabs demo](assets/demo.gif)

Safari Recent Tabs is a native macOS utility that lets you switch between Safari tabs in most-recently-used order, using a Command-Tab-style overlay.

It is built for the places Safari extensions cannot reliably reach: the address bar, Start Page, blank tabs, and browser chrome.

## What It Does

- Press Control-Tab to open a Safari tab switcher.
- See tabs from the frontmost Safari window in recent order.
- Keep holding Control and press Tab to cycle.
- Keep holding Control and press Shift-Tab to cycle backward.
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

Control-Tab is registered only while Safari is frontmost, then unregistered when you switch away from Safari. That keeps the shortcut scoped to Safari without overriding Control-Tab in the rest of macOS.

The switcher uses favicons, titles, and domains by default. That keeps the app fast and avoids asking for broad screen-capture permissions.

## Current Status

This is an early native MVP.

Working:

- Native menu-bar/background app.
- Safari-scoped Control-Tab shortcut.
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

### Requirements

- A Mac running macOS 13 (Ventura) or newer.
- Safari, with at least two tabs open in the window you want to switch.
- Xcode 15 or newer, or the Xcode Command Line Tools (Swift 5.9+).
- Git, to clone the repository.

There are no third-party package dependencies, accounts, cloud services, or
browser extensions to install.

### Install and run

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

## Permissions

On first use, macOS will ask whether Safari Recent Tabs can control Safari.
Click **Allow**. This Automation permission is required for the app to list
and activate tabs.

If the shortcut does not work as expected, check:

```text
System Settings > Privacy & Security > Automation
```

Accessibility is no longer required for the main Control-Tab shortcut path. The app still includes an **Open Accessibility Settings** menu item because some development builds may need it for auxiliary global-key behavior such as Escape-to-cancel.

If you do need to add the app manually, click **+** under Accessibility and add:

```text
dist/SafariRecentTabs.app
```

The app does not require Screen Recording permission, a network connection,
an account, or a Safari extension for its core functionality.

## How To Use

1. Open Safari.
2. Open a few tabs in one Safari window.
3. Launch Safari Recent Tabs.
4. Press Control-Tab while Safari is frontmost.
5. Keep holding Control and press Tab again to cycle.
6. Press Shift-Tab while holding Control to cycle backward.
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

## Before You Share This Project

This repository is ready to be public as source code, but it is currently an
early MVP: releases are not signed or notarized, and there is no packaged
installer. Ask people to run it from source and expect the Automation prompt
on first launch.

Before inviting contributions, add a license. Until a license is included,
GitHub visitors can view the source but do not have clear permission to reuse
or distribute it. An MIT license is a simple choice for a small open-source
utility; Apache-2.0 is another permissive option with an explicit patent
grant.

## Name

The working name is **Safari Recent Tabs**. The product promise is simpler:

> Command-Tab for Safari tabs.
