0a. **Verify specs directory**: Run `ls specs/` to confirm it exists. All specifications MUST be in `specs/`.
0b. **Detect project structure**: Run `ls` to identify source directory (`src/`, `Sources/`, `lib/`, `app/`) and test directory (`tests/`, `Tests/`, `test/`). Use actual names in all searches.
0c. Study `specs/*` using parallel explore agents (fire multiple background_task calls).
0d. Study @IMPLEMENTATION_PLAN.md.

1. Follow @IMPLEMENTATION_PLAN.md. Pick the **first incomplete task**. Complete ONLY this task: implement → build → test → mark complete. Before changes, search codebase using explore agents via background_task. Consult Oracle when stuck after 2+ attempts.
2. After each task, run build and tests. If functionality is missing, add it per specs. Ultrathink.
3. When you discover issues, update @IMPLEMENTATION_PLAN.md immediately using a background agent.
4. When the **single task** passes: update @IMPLEMENTATION_PLAN.md, `git add -A && git commit && git push`, create git tag, output `<promise>PHASE_COMPLETE</promise>`, then **STOP**. When ALL tasks done: `<promise>COMPLETE</promise>`. If stuck after 3 attempts: `<promise>BLOCKED:[task]:[reason]</promise>`.

**Task-by-Task Rule**: ONE task per session. Do NOT start the next task. The loop restarts you with fresh context. Do NOT edit multiple files before building.

**AUTONOMOUS MODE**: You are running in an autonomous loop. NEVER ask for confirmation or approval. NEVER ask "Would you like me to...?" or "Should I proceed?". Just do the work and output the completion signal when done.

99999. Document the why in code and specs.
999999. Single sources of truth, no adapters. Fix unrelated failing tests.
9999999. Create git tag when tests pass (start at 0.0.1 if no tags exist).
99999999. You may add temporary logging to debug issues.
99999999999. Keep @IMPLEMENTATION_PLAN.md current using background agents.
999999999999. Update @AGENTS.md with operational learnings (keep brief).
9999999999999. Resolve or document ALL bugs found.
99999999999999. No placeholders. No stubs. Complete implementations only.
999999999999999. Periodically clean completed items from @IMPLEMENTATION_PLAN.md using a background agent.
9999999999999999. If you find inconsistencies in specs/*, consult Oracle to analyze and update the specs.

## Agent Delegation

| Task | Agent | Invocation |
|------|-------|------------|
| Codebase search | explore | `background_task(agent="explore", ...)` |
| Docs/OSS examples | librarian | `background_task(agent="librarian", ...)` |
| Complex reasoning | oracle | `task(subagent_type="oracle", ...)` |
| Frontend UI/UX | frontend-ui-ux-engineer | `task(subagent_type="frontend-ui-ux-engineer", ...)` |
| Documentation | document-writer | `task(subagent_type="document-writer", ...)` |
