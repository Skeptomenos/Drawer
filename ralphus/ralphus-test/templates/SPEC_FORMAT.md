# Test Specification Table Format

All test specifications MUST use this table format with a Status column.

## Required Table Structure

```markdown
| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
| [ ] | XXX-001 | Description of test scenario | Expected outcome | Optional notes |
| [~] | XXX-002 | In-progress test | Expected outcome | |
| [x] | XXX-003 | Completed test | Expected outcome | |
| [!] | XXX-004 | Blocked test | Expected outcome | NEEDS_CLARIFICATION: reason |
```

## Status Symbols

| Symbol | Meaning | When to Use |
|--------|---------|-------------|
| `[ ]` | Not started | Test has not been implemented |
| `[~]` | In progress | Test is currently being written |
| `[x]` | Complete | Test exists and passes |
| `[!]` | Blocked | Test cannot proceed - needs clarification |

## Column Requirements

1. **Status** (REQUIRED): One of the status symbols above
2. **Test ID** (REQUIRED): Unique identifier in format `PREFIX-NNN`
   - PREFIX: 3-5 letter module abbreviation (e.g., CRON, PERM, AUTH)
   - NNN: Sequential number starting at 001
3. **Test Case** (REQUIRED): Clear description of the scenario being tested
   - Should describe the action and condition, not just "it works"
   - Bad: "Test login"
   - Good: "Login with valid credentials returns session token"
4. **Expected Result** (REQUIRED): Verifiable outcome
   - Must be specific and testable
   - Bad: "Works correctly"
   - Good: "Returns 401 response with error code UNAUTHORIZED"
5. **Notes** (OPTIONAL): Additional context, dependencies, or clarifications
   - Use `NEEDS_CLARIFICATION: [reason]` for blocked tests

## Breaking Down Complex Tests

If a test case would require >50 lines of test code, break it into atomic units:

### Before (Too Complex)
```markdown
| [ ] | ACC-001 | Create account with all validations | Account created or appropriate errors |
```

### After (Atomic)
```markdown
| [ ] | ACC-001 | Create account with valid data | Success, account created |
| [ ] | ACC-002 | Create account without session | Error: unauthorized |
| [ ] | ACC-003 | Create account with missing email | Error: validation |
| [ ] | ACC-004 | Create account with invalid email format | Error: validation |
```

## File Path Convention

Each test table section should specify the target test file:

```markdown
### 1.1 Module Name (`lib/module.ts`)

**File:** `app/__tests__/lib/module.test.ts`

| Status | Test ID | Test Case | Expected Result | Notes |
|--------|---------|-----------|-----------------|-------|
```
