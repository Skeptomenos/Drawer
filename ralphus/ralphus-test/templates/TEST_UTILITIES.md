# Test Utilities Section Format

Every test specification MUST include a Priority 0 section for test infrastructure and utilities.

## Required Structure

```markdown
## 0. Priority 0: Test Infrastructure (PREREQUISITE)

> **MUST complete before any other tests.** See `specs/tests/TEST_SETUP.md` for implementation details.

### 0.1 Dependencies & Configuration

**File:** `app/package.json`, `app/vitest.config.ts`

| Status | Test ID | Test Case | Expected Result | File Path |
|--------|---------|-----------|-----------------|-----------|
| [ ] | SETUP-001 | Install vitest and testing dependencies | All packages install without errors | `app/package.json` |
| [ ] | SETUP-002 | Create vitest.config.ts | Config file exists and is valid | `app/vitest.config.ts` |
| [ ] | SETUP-003 | Create test setup file | Setup file initializes MSW server | `app/__tests__/setup.ts` |

### 0.2 Mock Utilities

**Files:** `app/__tests__/mocks/`, `app/__tests__/utils/`

| Status | Test ID | Test Case | Expected Result | File Path |
|--------|---------|-----------|-----------------|-----------|
| [ ] | SETUP-004 | Create MSW server with API handlers | Server intercepts API calls | `app/__tests__/mocks/server.ts` |
| [ ] | SETUP-005 | Create database mock utility | Deep mock of DB client works | `app/__tests__/utils/prisma-mock.ts` |
| [ ] | SETUP-006 | Create session mock utilities | Session mocks return correct roles | `app/__tests__/utils/session-mock.ts` |
| [ ] | SETUP-007 | Create factory functions | Factories generate valid test data | `app/__tests__/utils/factories.ts` |
```

## Common Utility Categories

### 1. Session/Auth Mocking
Required for any test that checks authorization:
- `mockUserSession()` - Standard user session
- `mockAdminSession()` - Admin user session
- `mockNoSession()` - Unauthenticated state

### 2. Database Mocking
Required for any test that interacts with the database:
- Deep mock of ORM client (Prisma, Drizzle, etc.)
- Reset between tests to prevent state leakage

### 3. API Mocking (MSW)
Required for any test that calls external APIs:
- Graph API handlers (Microsoft Entra)
- Slack API handlers
- Email service handlers

### 4. Factory Functions
Required for generating consistent test data:
- `createTestUser()` - Generate user objects
- `createTestAccount()` - Generate account objects
- `createTestBucket()` - Generate bucket objects

## Dependency Order

Test utilities MUST be implemented in this order:

1. **Dependencies** - Install packages first
2. **Configuration** - Set up test runner config
3. **Setup File** - Initialize mocking infrastructure
4. **Mock Utilities** - Create reusable mocks
5. **Factory Functions** - Create data generators

## Verification

Each utility should have a simple verification test:

```typescript
describe('Test Setup Verification', () => {
  it('should run tests', () => {
    expect(1 + 1).toBe(2);
  });

  it('should have environment variables', () => {
    expect(process.env.TEST_SECRET).toBeDefined();
  });
});
```
