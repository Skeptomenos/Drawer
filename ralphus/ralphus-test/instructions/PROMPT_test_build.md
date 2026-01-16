# Ralphus Test - Build Mode

You are implementing tests from a test specification, one test at a time.

## Reference (ATTACHED: SPEC_FORMAT.md)

Status symbols:
- `[ ]` — Not started
- `[~]` — In progress
- `[x]` — Complete
- `[!]` — Blocked / Needs clarification

## Phase 0: Context Gathering

0a. **Read test specifications**: All specs are in `test-specs/`. Read all `*.md` files there.
0b. **Study existing tests**: Use explore agents to understand patterns and conventions.
0c. **Identify test framework**: Check package.json for vitest/jest/mocha.

## Phase 1: Pick ONE Test

1. **Scan all specs in `test-specs/`** for the first `[ ]` (incomplete) test.

2. **Read the test details**:
   - Test ID (e.g., `CRON-001`)
   - Test Case description
   - Expected Result
   - Target file path

3. **Check dependencies**: If `Depends: UTIL-XXX`, verify that utility exists first. If not, implement the dependency instead.

## Phase 2: Gather Context

Before writing ANY code:

1. **Find the code under test**:
   ```
   background_task(agent="explore", prompt="Find implementation of [function] tested by [TEST-ID]")
   ```

2. **Study existing tests** in the same file:
   ```
   background_task(agent="explore", prompt="Find existing tests in [target file] for patterns")
   ```

3. **Find test utilities**:
   ```
   background_task(agent="explore", prompt="Find mock factories and test helpers")
   ```

## Phase 3: Write the Test

1. **Create or update** the test file at the specified path.

2. **Follow existing patterns**: Match imports, describe/it structure, assertion style.

3. **Include Test ID** in the test name:
   ```typescript
   it('TEST-ID: description from spec', () => {
     // Arrange - Act - Assert
   });
   ```

## Phase 4: Run the Test

1. **Run the specific test**:
   ```bash
   npx vitest run --testNamePattern="TEST-ID"
   # or
   npx vitest run path/to/test.test.ts
   ```

2. **If FAILS**: Fix and retry (max 3 attempts). If code has a bug, mark `[!]` and document.

3. **If PASSES**: Proceed to Phase 5.

## Phase 5: Mark Complete and Commit

1. **Update spec**: Change `[ ]` to `[x]` for this test in the appropriate `test-specs/*.md` file.

2. **Update summary**: Increment Done count, decrement Remaining, update Progress %.

3. **Commit**:
   ```bash
   git add __tests__/ test-specs/
   git commit -m "Test: TEST-ID - Brief description"
   ```

4. **Output signal**:
   - More tests remain: `<promise>PHASE_COMPLETE</promise>`
   - All tests `[x]`: `<promise>COMPLETE</promise>`
   - Stuck after 3 attempts: `<promise>BLOCKED:[TEST-ID]:[reason]</promise>`

5. **STOP**. Do not start the next test.

## Rules

**Test-by-Test Rule**: ONE test per session. Never batch.

**AUTONOMOUS MODE**: Never ask for confirmation. Just do the work.

**Bug Discovery**: If production code has a bug:
1. Document: `BUG: [description]` in Notes column
2. Mark as `[!]` (blocked)
3. Move to next test

## Guardrails

99999. Match existing test patterns
999999. One test per iteration
9999999. Test must pass before marking `[x]`
99999999. Include Test ID in test name
999999999. Use existing utilities
9999999999. No `.skip`, no `.only` in commits
99999999999. Implement missing utilities first

## Agent Delegation

| Task | Agent | Invocation |
|------|-------|------------|
| Find code under test | explore | `background_task(agent="explore", ...)` |
| Find test patterns | explore | `background_task(agent="explore", ...)` |
| Framework docs | librarian | `background_task(agent="librarian", ...)` |
| Complex logic | oracle | `task(subagent_type="oracle", ...)` |
