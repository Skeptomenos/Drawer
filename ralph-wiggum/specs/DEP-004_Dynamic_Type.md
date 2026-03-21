# Spec: DEP-004 - Implement Dynamic Type

## Context
Project rules strictly forbid hardcoded font sizes (e.g., `.system(size: 12)`) to ensure the app is accessible to users with different visual needs. The app must use Dynamic Type styles that scale automatically.

## Problem
18 instances of hardcoded font sizes were found across 5 major UI files.

**Locations:**
- `UI/Settings/SettingsMenuBarLayoutView.swift` (10 instances)
- `UI/Panels/DrawerContentView.swift` (5 instances)
- `UI/Onboarding/TutorialStepView.swift`
- `UI/Onboarding/CompletionStepView.swift`
- `UI/Onboarding/PermissionsStepView.swift`

## Mitigation Plan
1. **Map Sizes to Styles:** Map existing pixel sizes to their closest Dynamic Type semantic equivalents:
   - 10-11pt → `.caption2`
   - 12pt → `.caption`
   - 13pt → `.footnote`
   - 14-15pt → `.subheadline`
   - 16-17pt → `.body`
   - 18-20pt → `.title3`
   - 24-28pt → `.title2`
   - 34-47pt → `.title`
   - 48pt+ → `.largeTitle`
2. **Handle Weights:** For fonts with specific weights (e.g., `.medium`), use the `.weight()` modifier on the semantic style: `.font(.footnote.weight(.medium))`.
3. **Special Cases:** For the main "Big Icon" in onboarding (size 64/48), use `.largeTitle` with a custom scaling factor if needed, or maintain as a named constant if it's purely illustrative.

## How to Test
1. **System Settings:** Change the "Text Size" in macOS System Settings > Accessibility > Display.
2. **Verification:** Ensure the text in Drawer's Settings and Onboarding scales accordingly.
3. **Layout:** Ensure layouts don't break when text is scaled to its maximum size (use `.lineLimit()` or scroll views where necessary).

## References
- `rules/rules_swift.md` Section 3 - Accessibility.
- `AGENTS.md` Hard Constraints.
