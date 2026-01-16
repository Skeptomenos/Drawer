# Test Specification: [Project Name]

**Document Version:** 1.0  
**Created:** [Date]  
**Status:** Ready for Ralphus Test

---

## Test Implementation Status

| Priority | Category | Total | Done | Remaining |
|----------|----------|-------|------|-----------|
| CRITICAL | [Category 1] | 0 | 0 | 0 |
| HIGH | [Category 2] | 0 | 0 | 0 |
| MEDIUM | [Category 3] | 0 | 0 | 0 |
| LOW | [Category 4] | 0 | 0 | 0 |

**Next up**: [First test to implement]

---

## Priority 0: Test Utilities & Mocks

> Implement these first—other tests depend on them.

**File:** `__tests__/utils/test-utils.ts`

| Status | Test ID | Utility | Purpose |
|--------|---------|---------|---------|
| [ ] | UTIL-001 | `mockSession()` | Create mock auth sessions |
| [ ] | UTIL-002 | `createTestUser()` | Factory for test user data |
| [ ] | UTIL-003 | `setupMocks()` | Configure API mocking (MSW) |

---

## Priority 1: [Critical Category] (CRITICAL)

### 1.1 [Module Name] (`path/to/module.ts`)

**File:** `__tests__/path/to/module.test.ts`

| Status | Test ID | Test Case | Expected Result |
|--------|---------|-----------|-----------------|
| [ ] | MOD-001 | Valid input returns success | Returns `{ success: true }` |
| [ ] | MOD-002 | Missing required field | Throws `ValidationError` |
| [ ] | MOD-003 | Invalid format | Returns 400 status |

```typescript
// Example test structure (for reference)
describe('moduleName', () => {
  it('MOD-001: valid input returns success', () => {
    // Arrange
    const input = { ... };
    
    // Act
    const result = moduleName(input);
    
    // Assert
    expect(result).toEqual({ success: true });
  });
});
```

---

## Priority 2: [High Category] (HIGH)

### 2.1 [Another Module] (`path/to/another.ts`)

**File:** `__tests__/path/to/another.test.ts`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | ANO-001 | Basic functionality | Works as expected | |
| [ ] | ANO-002 | Edge case handling | Handles gracefully | Depends: UTIL-001 |
| [ ] | ANO-003 | Error scenario | Returns error object | |

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| `[ ]` | Not implemented |
| `[x]` | Implemented and passing |
| `[B]` | Blocked by bug in production code |
| `[S]` | Skipped (needs clarification) |

---

## Notes

- Tests are ordered by priority and dependency
- Each test should be atomic (one behavior per test)
- Include Test ID in the test name for traceability
- Use existing test utilities from `__tests__/utils/`
