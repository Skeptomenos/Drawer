# Ralphus Test

> *"I'm testing!" — Ralph Wiggum*

**Ralphus Test** adapts the Ralphus autonomous coding loop for **systematic test creation**. Instead of implementing features from specs, it implements tests from a test specification. Each iteration picks one test case, gathers context from the codebase, writes the test, verifies it passes, and marks it complete.

## The Idea

> "You have a massive test specification with 200+ test cases. Running Ralphus Test will systematically implement each one, committing after each test passes. The loop is self-correcting—if a test fails, it fixes the implementation or the test until it passes."

## Two-Phase Workflow

### Phase 1: Plan (Prepare the Spec)

```bash
./loop.sh plan
```

The planning phase:
1. Finds your test specification (any format)
2. Adds status checkboxes (`[ ]` / `[x]`) for tracking
3. Breaks down complex tests into atomic units
4. Identifies shared test utilities needed first
5. Flags unclear or ambiguous test cases

### Phase 2: Build (Create the Tests)

```bash
./loop.sh           # Unlimited
./loop.sh 50        # Max 50 tests
```

The build phase (one test per iteration):
1. Picks the first incomplete test (`[ ]`)
2. Gathers context from the codebase
3. Writes the test following existing patterns
4. Runs the test to verify it passes
5. Marks complete (`[x]`) and commits
6. Stops — loop restarts with fresh context

## How It Works

```
+---------------------------------------------------------------------+
|                      THE TEST CREATION CYCLE                        |
+---------------------------------------------------------------------+
|                                                                     |
|    +----------+     +----------+     +----------+     +----------+  |
|    |   Read   |---->|  Gather  |---->|  Write   |---->|   Run    |  |
|    |   Spec   |     | Context  |     |   Test   |     |   Test   |  |
|    +----------+     +----------+     +----------+     +----------+  |
|         ^                                                  |        |
|         |                                                  |        |
|         |              +----------+                        |        |
|         |              |   Mark   |                        |        |
|         +--------------| Complete |<-----------------------+        |
|                        |  & Stop  |                                 |
|                        +----------+                                 |
|                                                                     |
|    "Me fail test? That's unpossible!"                               |
|                                                                     |
+---------------------------------------------------------------------+
```

Each iteration:
1. **Agent wakes up** with no memory of previous iterations
2. **Reads the test spec** (TEST_SPECIFICATION.md) to find the next incomplete test
3. **Gathers context** by searching the codebase for the code under test
4. **Writes the test** following existing test patterns in the project
5. **Runs the test** to verify it passes
6. **Marks complete** in the spec and commits
7. **Context clears** and the loop repeats

## Domain Translation

| Coding (Ralphus) | Testing (Ralphus Test) |
|------------------|------------------------|
| specs/*.md | TEST_SPECIFICATION.md |
| IMPLEMENTATION_PLAN.md | TEST_SPECIFICATION.md (same file) |
| Build code | Write tests |
| Run tests | Run the specific test |
| Commit code | Commit test + mark complete |
| "Feature complete" | "Test implemented" |

## Quick Start

```bash
# Copy ralphus-test to your project (or clone as submodule)
cp -r path/to/ralphus/ralphus-test ./ralphus/ralphus-test

# Create test-specs directory and add your spec(s)
mkdir -p test-specs
mv docs/technical/TEST_SPECIFICATION.md test-specs/
# Or create new: echo "# Tests" > test-specs/unit-tests.md

# Phase 1: Prepare specs with checkboxes
./ralphus/ralphus-test/scripts/loop.sh plan

# Phase 2: Run the test creation loop
./ralphus/ralphus-test/scripts/loop.sh              # Unlimited iterations
./ralphus/ralphus-test/scripts/loop.sh 20           # Max 20 iterations (20 tests)

# Watch the tests get created one by one
git log --oneline
```

## Directory Convention

```
your-project/
├── specs/              # Ralphus (coding) reads from here
│   └── feature.md
├── test-specs/         # Ralphus Test reads from here
│   ├── unit-tests.md
│   ├── integration-tests.md
│   └── e2e-tests.md
```

**All test specifications MUST be in `test-specs/`**. The loop reads all `*.md` files from this directory.

## Test Specification Format

Files in `test-specs/` should use this format:

```markdown
## Module Name

**File:** `__tests__/path/to/test.test.ts`

| Status | Test ID | Test Case | Expected Result |
|--------|---------|-----------|-----------------|
| [ ] | TEST-001 | Description of test | Expected outcome |
| [x] | TEST-002 | Already implemented | Already done |
```

The loop will:
1. Scan all files in `test-specs/` for the first `[ ]`
2. Implement that test
3. Change `[ ]` to `[x]`
4. Commit and stop

## The Backpressure Mechanism

In coding, tests provide feedback. In test creation, **the test itself** provides backpressure:

1. Write the test based on the specification
2. Run the test
3. If it fails → either the test is wrong OR the code has a bug
4. Fix until the test passes
5. Only then mark complete

This ensures every committed test is a passing test.

## File Structure

```
your-project/
├── ralphus/
│   └── ralphus-test/              # Ralphus Test variant
│       ├── scripts/
│       │   └── loop.sh            # The eternal test loop
│       ├── instructions/
│       │   ├── PROMPT_test_plan.md
│       │   └── PROMPT_test_build.md
│       └── templates/             # Format references
│           ├── SPEC_FORMAT.md
│           ├── SUMMARY_HEADER.md
│           └── TEST_UTILITIES.md
├── test-specs/                    # Test specifications (REQUIRED)
│   ├── security-tests.md
│   ├── account-tests.md
│   └── api-tests.md
├── __tests__/                     # Where tests go
│   ├── lib/
│   │   ├── auth.test.ts
│   │   └── permissions.test.ts
│   └── actions/
│       └── account.test.ts
└── src/                           # Code under test
```

## Reading the Commits

Each commit is one implemented test:

```bash
git log --oneline
# abc1234 Test: CRON-007 - Secret with different length returns 401
# def5678 Test: CRON-006 - Timing-safe comparison verified
# ghi9012 Test: CRON-005 - Missing CRON_SECRET env var returns 500
```

## Completion Signals

| Signal | Meaning |
|--------|---------|
| `<promise>PHASE_COMPLETE</promise>` | One test implemented, loop continues |
| `<promise>COMPLETE</promise>` | All tests in spec implemented |
| `<promise>BLOCKED:[test]:[reason]</promise>` | Stuck, needs human intervention |

## Guardrails

```
99999.       Match existing test patterns in the codebase
999999.      One test per iteration. Never batch.
9999999.     Test must pass before marking complete
99999999.    If code has a bug, document it—don't write a test that expects wrong behavior
999999999.   Use existing test utilities and mocks
9999999999.  Keep tests focused and readable
99999999999. No skipped tests. No `.skip`. Complete implementations only.
```

## Configuration

```bash
# Environment variables
RALPH_AGENT="Sisyphus"           # Agent to use
OPENCODE_BIN="opencode"          # Binary path
TEST_SPEC_FILE="TEST_SPECIFICATION.md"  # Override spec file location
```

## Troubleshooting

| Symptom | Diagnosis | Treatment |
|---------|-----------|-----------|
| Test fails repeatedly | Code might have a bug | Document bug, skip test, move on |
| Can't find code under test | Wrong file path in spec | Update spec with correct path |
| Test pattern mismatch | Didn't study existing tests | Add more context gathering |
| Infinite loop on one test | 3+ failures | Outputs BLOCKED signal |

## License

MIT — Test whatever you want. Ralphus certainly will.
