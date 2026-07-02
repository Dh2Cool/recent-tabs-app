# Safari Recent Tabs Native App Design

## Goal

Build a native macOS Safari recent-tabs switcher that feels like Command-Tab, but operates on tabs in the frontmost Safari window.

The MVP should solve the Safari WebExtension prototype's main limitation: extension content scripts cannot capture keyboard events when Safari browser chrome, Start Page, blank tabs, settings, or restricted pages have focus. The native app will own the global shortcut, overlay, and tab activation behavior.

## Product Shape

The app will be a background/menu-bar macOS utility. It should not require a normal Dock app window for daily use. The first version can expose only a small menu-bar item for status, quit, and later settings or permission recovery.

The app will ask for macOS Automation permission to control Safari. This is acceptable for the MVP because AppleScript/JXA is the simplest reliable way to read and activate Safari tabs from a native macOS app.

The Safari Web Extension is out of scope for the core MVP. It remains useful future work for richer page metadata and possible live tab snapshots.

## Scope

MVP scope:

- Frontmost Safari window only.
- Global Control-Backtick shortcut.
- Command-Tab-style press-and-hold behavior.
- MRU ordering for tabs in the frontmost Safari window.
- Native overlay panel with favicon or fallback tile, title, and main domain.
- Safari tab discovery and activation through AppleScript/JXA.
- Favicon cache that never blocks overlay display.

Out of scope for MVP:

- Switching across all Safari windows.
- Custom shortcut settings.
- Safari Web Extension integration.
- Live tab snapshots.
- Search, tab groups, history, or cross-browser support.
- App Store packaging and notarization polish.

## Architecture

Use a native Swift macOS app with SwiftUI for views and AppKit for macOS-level behavior.

Primary components:

- `AppController`: owns startup, menu-bar presence, permissions state, and app lifecycle.
- `HotkeyController`: registers the global Control-Backtick shortcut and detects the press-and-hold cycle behavior.
- `SafariAutomationClient`: reads Safari's frontmost window tabs and activates selected tabs through AppleScript/JXA.
- `RecentTabStore`: maintains MRU order for tabs in the frontmost Safari window.
- `SwitcherCoordinator`: converts hotkey events into switcher state: open, cycle, cancel, activate.
- `SwitcherPanel`: displays a floating `NSPanel` styled like Command-Tab and hosts the SwiftUI overlay.
- `FaviconProvider`: loads and caches icons by domain, with polished fallback tiles.

## Interaction Design

The switcher should match Command-Tab semantics:

1. Press Control-Backtick to open the overlay.
2. Show the current tab first in the strip.
3. Highlight the previously used tab, which appears second.
4. While holding `Control`, pressing `` ` `` again cycles forward through the MRU tabs.
5. Releasing `Control` activates the highlighted tab.
6. Pressing `Escape` cancels and leaves the current tab active.
7. If Safari is closed, has no usable frontmost window, or has fewer than two tabs, fail softly.

The overlay should use the chosen tab-aware Command-Tab style:

- Glassy centered panel.
- Horizontal tile strip.
- Current tab first, previous tab highlighted.
- Favicon or fallback tile as the primary visual.
- Page title and main domain beneath each visual.
- Visual polish high enough that the MVP feels like a system feature.

## Performance And Data Flow

Snappiness is a first-class requirement.

On hotkey press, the app should quickly read the frontmost Safari window's tab list, merge that with native MRU state, and render the overlay. Once the overlay is open, cycling should be purely in memory.

On `Control` release, the app should send only one activation command for the highlighted tab. Slow work such as favicon loading must not happen on the activation path.

Favicon loading should be cached by domain. If a favicon is missing or still loading, the overlay should immediately show a fallback tile and update later only if an icon arrives while the overlay is visible.

MRU tracking can start with a pragmatic hybrid:

- Poll or observe Safari's frontmost active tab while Safari is active.
- Update MRU when the active tab changes.
- Refresh tab metadata when the switcher opens.
- Prune closed tabs when Safari's current tab list differs from stored MRU state.

## Error Handling And Permissions

The app should handle permission and runtime edge cases quietly:

- If Automation permission is needed, let macOS prompt on first Safari access.
- If Automation permission is denied, show a menu-bar status and provide a retry or settings path later.
- If Safari is closed, do nothing or show a minimal status hint later.
- If Safari has fewer than two tabs in the frontmost window, do nothing.
- If favicon loading fails, keep the fallback tile.
- If a tab disappears between overlay open and key release, refresh or cancel instead of switching the wrong tab.

## Testing Strategy

Automated tests should cover deterministic app logic:

- MRU ordering: current first, previous highlighted, stale tab pruning.
- Display model formatting: title, domain, fallback labels.
- Switcher state transitions: open, cycle, release-to-activate, escape cancel.
- Favicon cache decisions and fallback behavior.

Manual or thin integration checks should cover macOS-dependent behavior:

- Automation permission prompt and denial path.
- Reading the frontmost Safari window through AppleScript/JXA.
- Activating a selected Safari tab.
- Global hotkey registration.
- Overlay panel position, focus behavior, and keyboard handling.

## Future Work

Keep these follow-ups visible after the MVP:

- Try live tab snapshots, likely through a companion Safari Web Extension or another native capture strategy.
- Support switching across all Safari windows.
- Add custom shortcut settings.
- Add a richer menu-bar status/settings window.
- Reintroduce Safari Web Extension metadata for better favicons, page titles, and optional in-page behavior.
- Explore Accessibility APIs only if AppleScript/JXA proves insufficient for a specific feature.
