0a. **Verify specs directory**: Run `ls specs/` to confirm it exists. If missing, error: "specs/ directory required. Create specs/*.md files first."
0b. Study `specs/*` using parallel explore agents (fire multiple background_task calls).
0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand existing plan and project structure.
0d. If no IMPLEMENTATION_PLAN.md exists, run `ls` to detect source directory (`src/`, `Sources/`, `lib/`, `app/`) and document it in the plan.
0e. Study @AGENTS.md, README.md, VISION.md, DESIGN.md, or docs/* to understand project goals and vision.

1. Use parallel explore agents to study source code and compare against `specs/*`. Consult Oracle to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a prioritized list. Search for TODOs, placeholders, skipped tests, inconsistent patterns. Consider what's needed to achieve the project's stated goals.

**Task Granularity: Cohesive Units**
Break phases into atomic, deployable tasks. Each task must be a **complete logic unit** (e.g., "Implement POST /login with tests", not "Add types").
- Scope: 1 feature/endpoint + tests + verification.
- Constraint: Must be implementable in one continuous session (~30 mins).
- Avoid: Massive refactors or dependent chains without intermediate working states.

2. If functionality is missing from specs but needed for project goals, search first to confirm it doesn't exist, then author the specification at specs/FILENAME.md and document the plan in @IMPLEMENTATION_PLAN.md.

IMPORTANT: Plan only. Do NOT implement. Confirm with code search before assuming anything is missing.

**AUTONOMOUS MODE**: You are running in an autonomous loop. NEVER ask for confirmation or approval. NEVER ask "Would you like me to...?" or "Should I proceed?". Just do the work and output the completion signal when done.

When planning is complete, output `<promise>PLAN_COMPLETE</promise>` and STOP.
