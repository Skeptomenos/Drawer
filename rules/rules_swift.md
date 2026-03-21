---
created: 2026-02-01
updated: 2026-02-01
---

# Swift & SwiftUI Principles (2026)

> **Mandate:** Modern APIs, Accessibility, No Deprecated Patterns.

## 1. Deprecated API Replacements

| AI Generates | Replace With |
|-------------|--------------|
| `foregroundColor()` | `foregroundStyle()` |
| `cornerRadius()` | `clipShape(.rect(cornerRadius:))` |
| `onChange()` 1-param | 2-param or 0-param variant |
| `tabItem()` | `Tab` API |
| `NavigationView` | `NavigationStack` |
| `NavigationLink` inline | `navigationDestination(for:)` |
| `ObservableObject` | `@Observable` macro |
| `Task.sleep(nanoseconds:)` | `Task.sleep(for: .seconds(1))` |
| `UIGraphicsImageRenderer` | `ImageRenderer` |
| `String(format: "%.2f", x)` | `Text(x, format: .number.precision(...))` |
| `ForEach(Array(x.enumerated())...)` | `ForEach(x.enumerated()...)` |
| Finding documents directory | `URL.documentsDirectory` |

## 2. SwiftUI Architecture

- **NO computed properties for subviews.** Extract to separate `View` structs.
- **One type per file.** Multiple types = longer build times.
- **NO `GeometryReader`** unless required. Prefer `visualEffect()`, `containerRelativeFrame()`.
- **NO fixed frame sizes** unless design requires.

## 3. Accessibility (Non-Negotiable)

- **Replace `onTapGesture()` with `Button`** - VoiceOver, eye tracking support.
- **NO image-only buttons.** Use `Button("Label", systemImage: "plus", action: fn)`.
- **NO hardcoded fonts.** Use Dynamic Type: `.font(.body)`, not `.font(.system(size: 18))`.

## 4. Type Safety

- **NO force unwraps (`!`)** in production. Use `guard let` or `if let`.
- `fontWeight(.bold)` and `bold()` are NOT equivalent. Be explicit.
- `@Attribute(.unique)` does NOT work with CloudKit.

## 5. Hallucination Watch

LLMs invent nonexistent APIs. Verify unfamiliar APIs in Apple docs before trusting.

---
**See Also:** [[rules_swift_concurrency]] | [[rules_ios_agentic]]
