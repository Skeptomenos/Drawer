---
created: 2026-02-01
updated: 2026-02-01
---

# iOS Agentic Development Rules (2026)

> **Mandate:** Enable 30+ minute unsupervised agent sessions.

## 1. XcodeBuildMCP (Required)

Use XcodeBuildMCP instead of raw `xcodebuild`. Provides:
- Scheme/simulator discovery
- Build/test execution
- Simulator interaction (tap, screenshot)
- Console log reading

## 2. Long-Running Task Pattern

```
Implement → Build → Test → Fix failures → Run app → Screenshot → Verify → Repeat
```

## 3. Project Structure

- **Document patterns in AGENTS.md immediately** (architecture, navigation, naming)
- **Create one reference feature first** - agents duplicate patterns well
- **Clear scheme organization** - separate app/test/UI test schemes

## 4. Multi-Repo Workflow

Cross-reference freely:
```
"Look at ../backend and implement the corresponding API client here"
"Review changes in ../web-app since yesterday, retrofit to iOS"
```

## 5. Test-Driven Agent Loop

1. Agent writes tests
2. Human reviews tests carefully
3. If tests are correct, trust the code
4. Run `/review` multiple times (each pass finds different issues)

## 6. Context Building

- Point to example files with `@path/to/file.swift`
- Paste Figma mockups for layout intent
- Let agent ask for more context if needed

## 7. Skills

Use dedicated skills for: changelog generation, SwiftUI performance, Swift concurrency debugging.

## 8. Editor Setup

- **Cursor** + Sweetpad/Flowdeck for build shortcuts
- **Terminal pane** for Codex CLI
- **Xcode** only for debugging/profiling (~2% of time)

## 9. Cloud Workflow

Bug → Codex (mobile/web) → PR → Xcode Cloud → TestFlight. No computer needed.

## 10. Anti-Patterns

- **NO** raw `xcodebuild` (use MCP)
- **NO** skipping tests
- **NO** single mega-prompts (break into steps)
- **NO** ignoring `/review` findings
- **NO** undocumented patterns

---
**See Also:** [[rules_swift]] | [[rules_swift_concurrency]] | [[../guides/15_iOS_Agentic_Development]]
