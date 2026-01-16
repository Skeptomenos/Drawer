# Ralphus Test - Planning Mode

You are preparing a test specification for autonomous test creation.

## Reference Templates (ATTACHED)

The following template files are attached to this prompt. Study them FIRST:

1. **SPEC_FORMAT.md** — Required table structure, status symbols, column requirements
2. **SUMMARY_HEADER.md** — Progress tracking header format with percentage
3. **TEST_UTILITIES.md** — Priority 0 test infrastructure section

## Phase 0: Discovery

0a. **Verify test-specs directory**: Run `ls test-specs/` to confirm it exists. All test specifications MUST be in `test-specs/`.
0c. **Study test specifications**: Read all `*.md` files in `test-specs/`.
0d. **Study existing tests**: Use explore agents to find `__tests__/`, `*.test.ts`, `*.spec.ts`. Understand conventions.
0e. **Study test utilities**: Find existing mocks, fixtures, factories.
0f. **Identify test framework**: Detect vitest/jest/mocha from package.json.

## Phase 1: Normalize the Specification

1. **Add status column**: Convert all test tables to the format in the attached SPEC_FORMAT.md.

2. **Preserve existing completion**: If a test file already exists and passes, mark as `[x]`.

3. **Keep original structure**: Maintain priority sections, module groupings, file paths.

## Phase 2: Break Down Complex Tests

For each test case, evaluate:
- Can this be implemented in ONE test function (<50 lines)?
- Does it require setup that other tests also need?
- Is the expected behavior clear and testable?

**If too complex**: Break into atomic units per the attached SPEC_FORMAT.md.

**If needs shared setup**: Add to Priority 0 utilities section.

## Phase 3: Identify Prerequisites

If the spec lacks a test utilities section, create one following the attached TEST_UTILITIES.md.

Common utilities to identify:
- Session/auth mocking
- Database mocking (Prisma, etc.)
- API mocking (MSW handlers)
- Factory functions for test data

## Phase 4: Validate Clarity

For each test, ensure:
- [ ] Test ID is unique (format: `PREFIX-NNN`)
- [ ] Test case describes the scenario (not just "it works")
- [ ] Expected result is verifiable
- [ ] File path is specified

**Flag unclear tests**: Add `NEEDS_CLARIFICATION: [reason]` in Notes column and mark as `[!]`.

## Phase 5: Add Summary Header

Add a progress tracking section at the top per the attached SUMMARY_HEADER.md.

## Phase 6: Commit and Complete

1. **Commit**: `git add . && git commit -m "Prepare test spec for Ralphus Test loop"`

2. **Output**: `<promise>PLAN_COMPLETE</promise>` and STOP.

## Rules

**Plan only. Do NOT write any test code yet.**

## Agent Delegation

| Task | Agent | Invocation |
|------|-------|------------|
| Find test files/patterns | explore | `background_task(agent="explore", ...)` |
| Find test framework docs | librarian | `background_task(agent="librarian", ...)` |
| Complex test breakdown | oracle | `task(subagent_type="oracle", ...)` |

## Guardrails

99999. Every test must have a unique ID (PREFIX-NNN format)
999999. Every test must have a clear expected result
9999999. Break down tests that would require >50 lines
99999999. Identify shared utilities before individual tests
999999999. Preserve the original priority order
