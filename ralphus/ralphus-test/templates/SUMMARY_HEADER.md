# Test Specification Summary Header Format

Every test specification document MUST include a progress tracking header at the top.

## Required Format

```markdown
## Progress Summary

| Priority | Category | Total | Done | Remaining | Progress |
|----------|----------|-------|------|-----------|----------|
| P0 | Test Infrastructure | 7 | 0 | 7 | 0% |
| P1 | Security & Authorization | 28 | 0 | 28 | 0% |
| P2 | Account Lifecycle | 22 | 0 | 22 | 0% |
| **TOTAL** | | **57** | **0** | **57** | **0%** |

### Status Legend
- `[ ]` - Not started
- `[~]` - In progress
- `[x]` - Complete
- `[!]` - Blocked / Needs clarification
```

## Column Definitions

| Column | Description |
|--------|-------------|
| Priority | Priority level (P0 = highest) |
| Category | Descriptive name for the test group |
| Total | Total number of test cases in this category |
| Done | Number of tests marked `[x]` |
| Remaining | Total - Done |
| Progress | (Done / Total) * 100, rounded to nearest integer |

## Updating the Summary

The summary MUST be updated when:
1. Tests are added or removed
2. Test status changes to `[x]` (complete)
3. Priority categories are reorganized

## Calculation Rules

```
Done = COUNT of tests with status [x]
Remaining = Total - Done
Progress = ROUND(Done / Total * 100)
```

## Example with Progress

```markdown
## Progress Summary

| Priority | Category | Total | Done | Remaining | Progress |
|----------|----------|-------|------|-----------|----------|
| P0 | Test Infrastructure | 7 | 7 | 0 | 100% |
| P1 | Security & Authorization | 28 | 14 | 14 | 50% |
| P2 | Account Lifecycle | 22 | 0 | 22 | 0% |
| **TOTAL** | | **57** | **21** | **36** | **37%** |
```
