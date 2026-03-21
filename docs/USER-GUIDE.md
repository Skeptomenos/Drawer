# Drawer User Guide

Drawer is a macOS menu bar utility that helps you declutter your menu bar by hiding icons you don't need to see all the time.

## Getting Started

### First Launch

When you first open Drawer, you'll see two new icons in your menu bar:

```
[Your Hidden Icons] ● < [Your Visible Icons] [System Icons]
                    ↑ ↑
                    │ └── Toggle button (click to show/hide)
                    └──── Separator (drag icons relative to this)
```

- **Separator** (`●`): The divider between hidden and visible icons
- **Toggle** (`<` or `>`): Click to expand or collapse hidden icons

### Required Permissions

Drawer needs two macOS permissions to work:

| Permission | Why It's Needed |
|------------|-----------------|
| **Screen Recording** | To capture images of your hidden menu bar icons |
| **Accessibility** | To forward clicks to hidden icons |

You'll be prompted to grant these during onboarding. You can also enable them in **System Settings → Privacy & Security**.

---

## Basic Usage

### Hiding Icons

1. **Hold ⌘ (Command)** and drag any menu bar icon
2. **Move it to the left** of the separator (`●`)
3. **Release** - the icon is now in the "hidden" zone

### Showing Hidden Icons

**Click the toggle button** (`<` or `>`) to expand or collapse the hidden section.

- `>` means icons are hidden (click to show)
- `<` means icons are visible (click to hide)

### Rearranging Icons

Hold **⌘ (Command)** and drag icons to reorder them. This works for:
- Moving icons into the hidden zone
- Moving icons out of the hidden zone
- Reordering within either zone

---

## Features

### Show on Hover

Enable this to automatically show hidden icons when your mouse enters the menu bar area.

**To enable:**
1. Right-click the separator (`●`) or toggle button
2. Select **Preferences...**
3. Enable **Show on Hover**

When enabled:
- Move your mouse to the menu bar → hidden icons appear
- Move your mouse away → hidden icons disappear after a short delay

### Auto-Collapse

Automatically hide icons after a set time.

**To configure:**
1. Open **Preferences...**
2. Enable **Auto-Collapse**
3. Set the delay (e.g., 5 seconds)

### Launch at Login

Start Drawer automatically when you log in.

**To enable:**
1. Open **Preferences...**
2. Enable **Launch at Login**

---

## The Drawer Panel

When you hover over the menu bar (with "Show on Hover" enabled), a floating panel appears showing your hidden icons.

### Clicking Icons in the Drawer

Click any icon in the Drawer panel - the click is forwarded to the actual menu bar item. Menus will open, actions will trigger, just like clicking the real icon.

### Panel Behavior

- The panel appears below the menu bar
- It stays visible while your mouse is over it
- It disappears when you move your mouse away
- It has a slight delay before appearing/disappearing to prevent accidental triggers

---

## Context Menu

Right-click the separator (`●`) to access:

| Option | Description |
|--------|-------------|
| **Show Drawer** | Manually show the Drawer panel |
| **Preferences...** | Open settings (⌘,) |
| **Quit Drawer** | Exit the app (⌘Q) |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘ + Drag** | Reposition menu bar icons |
| **⌘,** | Open Preferences (from context menu) |
| **⌘Q** | Quit Drawer (from context menu) |

---

## Tips & Tricks

### Which Icons to Hide?

Good candidates for hiding:
- Apps you rarely interact with (backup utilities, cloud sync)
- System monitors you only check occasionally
- Apps with persistent icons but infrequent use

Keep visible:
- Apps you interact with frequently
- Time-sensitive notifications
- System essentials (Wi-Fi, battery, clock)

### Optimal Setup

1. **Start with everything visible** - use your Mac normally for a day
2. **Identify rarely-used icons** - which ones do you never click?
3. **Hide those first** - ⌘+drag them left of the separator
4. **Iterate** - unhide anything you find yourself needing

### Multi-Display Setup

Drawer works on your primary display's menu bar. If you have multiple displays, the hidden icons are on the main screen.

---

## Troubleshooting

### Icons Not Appearing

**Symptom**: The toggle (`<`/`>`) or separator (`●`) icons don't show up.

**Solutions**:
1. Quit and relaunch Drawer
2. Check if another app is conflicting (Bartender, Vanilla, etc.)
3. Reset Drawer's saved state:
   ```bash
   defaults delete com.drawer.app
   ```
4. Restart your Mac

### Permissions Not Working

**Symptom**: Drawer asks for permissions but features don't work.

**Solutions**:
1. Open **System Settings → Privacy & Security**
2. Find **Screen Recording** and **Accessibility**
3. Remove Drawer from the list
4. Re-add it and grant permission
5. Restart Drawer

### Click-Through Not Working

**Symptom**: Clicking icons in the Drawer panel does nothing.

**Solutions**:
1. Ensure **Accessibility** permission is granted
2. Check if the target app is responding
3. Try clicking the actual menu bar icon directly

### Drawer Panel Stuck

**Symptom**: The Drawer panel won't disappear.

**Solutions**:
1. Click elsewhere on the screen
2. Press **Escape**
3. Click the toggle button to collapse

---

## Uninstalling

1. Quit Drawer (right-click → Quit Drawer)
2. Drag Drawer.app to Trash
3. Optionally, remove saved preferences:
   ```bash
   defaults delete com.drawer.app
   ```

---

## FAQ

**Q: Is Drawer free?**
A: Yes, Drawer is open source under the MIT license.

**Q: Does Drawer work with Bartender/Vanilla/other menu bar apps?**
A: We recommend using only one menu bar management app at a time to avoid conflicts.

**Q: Why does Drawer need Screen Recording permission?**
A: To capture images of your hidden icons for display in the Drawer panel. Drawer does not record your screen or save any images.

**Q: Why does Drawer need Accessibility permission?**
A: To forward your clicks from the Drawer panel to the actual menu bar icons.

**Q: Can I hide system icons (Wi-Fi, Battery, etc.)?**
A: Yes! ⌘+drag works on most system icons. Some system icons (like Control Center) may have restrictions.

**Q: Does Drawer work on Apple Silicon Macs?**
A: Yes, Drawer is a universal app that runs natively on both Intel and Apple Silicon Macs.

**Q: What macOS versions are supported?**
A: macOS 14.0 (Sonoma) and later.

---

## Getting Help

- **GitHub Issues**: Report bugs or request features
- **Documentation**: Check `docs/ARCHITECTURE.md` for technical details
- **Source Code**: Explore the codebase to understand how it works

---

## Credits

Drawer is forked from [Hidden Bar](https://github.com/dwarvesf/hidden) by Dwarves Foundation. We're grateful for their original work that made this project possible.

**License**: MIT
