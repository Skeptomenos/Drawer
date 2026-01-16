<p align="center">
	<img width="200" height="200" src="https://github.com/dwarvesf/hidden/blob/develop/img/icon_512%402x.png?raw=true">
</p>

<h1 align="center">Drawer</h1>

<p align="center">
	A modern macOS menu bar utility that declutters your menu bar by hiding icons into a collapsible drawer.
</p>

<p align="center">
	<img src="https://img.shields.io/badge/platform-macOS%2014.0+-blue.svg" alt="platform">
	<img src="https://img.shields.io/badge/swift-5.9+-orange.svg" alt="swift">
	<img src="https://img.shields.io/badge/license-MIT-green.svg" alt="license">
</p>

---

## What is Drawer?

Drawer is a high-performance macOS menu bar utility (forked from [Hidden Bar](https://github.com/dwarvesf/hidden)) that hides menu bar icons into a secondary, collapsible section. When you need them, they're just a click, hover, or swipe away.

```
[Hidden Icons] ● < [Visible Icons] [System Icons]
               ↑ ↑
               │ └── Toggle (click to show/hide)
               └──── Separator (⌘+drag icons relative to this)
```

## Features

- **One-Click Toggle**: Click to expand/collapse hidden icons
- **Gesture Controls**: Swipe down in the menu bar to reveal the drawer, swipe up to hide
- **Show on Hover**: Automatically reveal icons when your mouse enters the menu bar
- **Click-Through**: Click icons in the drawer panel - actions forward to the real items
- **Customizable Triggers**: Configure which gestures show/hide the drawer
- **Native Experience**: Built with SwiftUI and AppKit for a seamless macOS feel
- **Lightweight**: Minimal CPU and memory footprint
- **Open Source**: MIT licensed, contributions welcome

## Requirements

- macOS 14.0 (Sonoma) or later
- Screen Recording permission (for icon capture)
- Accessibility permission (for click forwarding and gesture detection)

## Installation

### Manual Download

1. Download the latest release from [Releases](https://github.com/Skeptomenos/Drawer/releases)
2. Drag `Drawer.app` to your Applications folder
3. Launch Drawer
4. Grant the required permissions when prompted

### Build from Source

```bash
git clone https://github.com/Skeptomenos/Drawer.git
cd Drawer
xcodebuild -scheme Drawer -configuration Release build
```

## Usage

### Quick Start

1. **Launch Drawer** - Two icons appear in your menu bar: `●` (separator) and `<`/`>` (toggle)
2. **Hide icons** - Hold `⌘` and drag any icon to the left of the separator
3. **Toggle visibility** - Click the `<`/`>` button, hover, or swipe down to show/hide

### Gesture Controls

| Gesture | Action |
|---------|--------|
| Swipe down (two-finger) in menu bar | Show drawer |
| Swipe up (two-finger) | Hide drawer |
| Click outside drawer | Hide drawer |
| Hover over menu bar | Show drawer (if enabled) |

All gestures are configurable in Preferences.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ + Drag` | Reposition menu bar icons |
| `⌘,` | Open Preferences |
| `⌘Q` | Quit Drawer |

### Context Menu

Right-click the separator (`●`) for options:
- Show Drawer
- Preferences...
- Quit Drawer

## How It Works

Drawer uses a clever technique called the **"10k Pixel Hack"**:

1. A separator `NSStatusItem` sits between hidden and visible icons
2. When collapsed, the separator expands to 10,000 pixels wide
3. This pushes hidden icons off the left edge of the screen
4. When expanded, the separator shrinks to 20 pixels, revealing all icons

For displaying hidden icons in a floating panel, Drawer uses **ScreenCaptureKit** to capture the menu bar region and slice it into individual icons.

## Project Structure

```
Drawer/
├── App/                    # App entry point
├── Core/
│   ├── Managers/           # Business logic (MenuBarManager, HoverManager, etc.)
│   └── Engines/            # Icon capture engine
├── UI/
│   ├── Panels/             # Drawer panel
│   ├── Settings/           # Preferences
│   └── Onboarding/         # First-run experience
├── Models/                 # Data structures
├── Utilities/              # Helpers (EventSimulator, GlobalEventMonitor, etc.)
└── specs/                  # Feature specifications and PRDs
```

## Development

### Setup

1. Clone the repository
2. Open `Hidden Bar.xcodeproj` in Xcode
3. Select the `Drawer` scheme
4. Build and run

### Code Style

- Swift 5.9+
- SwiftUI for UI, AppKit for system integration
- `@MainActor` for UI-related classes
- See [AGENTS.md](AGENTS.md) for detailed guidelines

### Running Tests

```bash
xcodebuild test -scheme Drawer -destination 'platform=macOS'
```

## Credits

Drawer is forked from [Hidden Bar](https://github.com/dwarvesf/hidden) by [Dwarves Foundation](https://github.com/dwarvesf). We're grateful for their original work that made this project possible.

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
	Made with care for a cleaner Mac experience.
</p>
