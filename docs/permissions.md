# Drawer Permissions Guide

Drawer requires **Accessibility** and **Screen Recording** permissions to function. After rebuilding/reinstalling, macOS TCC invalidates these permissions and they must be reset and re-granted.

## Quick Reference

```bash
# 1. Reset permissions
tccutil reset Accessibility com.drawer.app
tccutil reset ScreenCapture com.drawer.app

# 2. Restart Drawer to trigger prompts
pkill -x Drawer && sleep 1 && open /Applications/Drawer.app

# 3. Grant permissions (see detailed steps below)

# 4. Restart Drawer again to pick up new permissions
pkill -x Drawer && sleep 1 && open /Applications/Drawer.app
```

## Symptom of Missing Permissions

Settings → Menu Bar Layout shows **0 icons** in all sections with a permission warning banner.

## Granting Permissions via Automation

### Step 1: Open Accessibility Settings

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

### Step 2: Click the + Button

```applescript
tell application "System Settings" to activate
delay 0.3
tell application "System Events"
    tell process "System Settings"
        tell window 1
            set allElements to entire contents
            repeat with elem in allElements
                try
                    if class of elem is button then
                        set elemDesc to description of elem
                        set elemPos to position of elem
                        -- Find unnamed buttons near bottom of window (+ and - buttons)
                        -- The + button is the leftmost one
                        if elemDesc is "button" or elemDesc is "" then
                            if (item 2 of elemPos) > 600 then
                                if (item 1 of elemPos) < 600 then
                                    click elem
                                    exit repeat
                                end if
                            end if
                        end if
                    end if
                end try
            end repeat
        end tell
    end tell
end tell
```

### Step 3: Authenticate (if prompted)

A Touch ID or password prompt may appear. Handle it:

```applescript
tell application "System Events"
    tell process "System Settings"
        tell sheet 1 of window 1
            try
                click button "Use Password…"
            end try
        end tell
    end tell
end tell
```

Then enter password manually or use Touch ID.

### Step 4: Navigate to Drawer in File Picker

Once the file picker opens, use Cmd+Shift+G to go to path, or search:

```applescript
-- Use Cmd+Shift+G to open "Go to Folder" dialog
tell application "System Events"
    keystroke "g" using {command down, shift down}
    delay 0.5
    keystroke "/Applications/Drawer.app"
    delay 0.3
    keystroke return
    delay 0.5
    keystroke return  -- Click Open
end tell
```

**Or use the search field:**

```applescript
tell application "System Events"
    -- Type in search field (usually auto-focused or use Cmd+F)
    keystroke "Drawer"
    delay 1
    keystroke return  -- Select first result
    delay 0.3
    keystroke return  -- Click Open
end tell
```

### Step 5: Repeat for Screen Recording

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
```

Then repeat steps 2-4.

### Step 6: Restart Drawer

```bash
pkill -x Drawer && sleep 1 && open /Applications/Drawer.app
```

## One-Liner Automation (Semi-Automated)

This opens the settings and clicks +, but user must complete authentication and file selection:

```bash
# Accessibility
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
sleep 2
osascript -e 'tell application "System Settings" to activate' -e 'delay 0.3' -e 'tell application "System Events" to tell process "System Settings" to tell window 1 to click (first button whose position'\''s second item > 600 and position'\''s first item < 600)'

# Screen Recording
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
sleep 2
osascript -e 'tell application "System Settings" to activate' -e 'delay 0.3' -e 'tell application "System Events" to tell process "System Settings" to tell window 1 to click (first button whose position'\''s second item > 600 and position'\''s first item < 600)'
```

## Verification

Check if permissions are granted:

```bash
# This checks peekaboo's permissions, not Drawer's
peekaboo permissions status --json

# To verify Drawer's permissions, open Settings and check icon count
# Should show > 0 icons in Shown Items section
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 0 icons after granting | Restart Drawer: `pkill -x Drawer && open /Applications/Drawer.app` |
| Permission prompt doesn't appear | Reset first: `tccutil reset Accessibility com.drawer.app` |
| Toggle switches all grey | Authenticate by clicking any toggle, then use + button |
| File picker won't find Drawer | Use Cmd+Shift+G and type `/Applications/Drawer.app` |
