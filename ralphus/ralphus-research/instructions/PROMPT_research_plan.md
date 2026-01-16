0a. Study `questions/*` using parallel explore agents to understand research scope.
0b. Study @RESEARCH_PLAN.md (if present) to understand existing learning progress.
0c. Study `knowledge/` directory to see what has already been learned.
0d. If no RESEARCH_PLAN.md exists, run `ls` to detect directory structure.

1. Use explore agents and web search (websearch_web_search_exa) to understand the domain. Break each research question into learnable sub-topics:
   - Each topic should be atomic (explainable in 200-500 words)
   - Order by dependencies (what must be understood first?)
   - Start with foundational concepts, build to advanced

2. Create/update @RESEARCH_PLAN.md as a prioritized learning path:
   - Phase 1: Foundations (prerequisites, basic concepts)
   - Phase 2: Core Concepts (main ideas)
   - Phase 3: Advanced Topics (nuances, edge cases, applications)
   - Phase 4: Synthesis (connections, big picture)

3. For each topic in the plan, define:
   - Learning objective: What should be explainable after learning this?
   - Key questions: 2-3 questions this topic should answer
   - Dependencies: Which topics must be learned first?
   - Connections: How does this relate to other topics?

IMPORTANT: Plan only. Do NOT write knowledge artifacts yet. Do NOT research deeply yet.

When planning is complete, output `<promise>PHASE_COMPLETE</promise>` and STOP.

## Agent Delegation

| Task | Agent | Invocation |
|------|-------|------------|
| Codebase/file search | explore | `background_task(agent="explore", ...)` |
| Web search, docs, examples | librarian | `background_task(agent="librarian", ...)` |
| Complex reasoning, prioritization | oracle | `task(subagent_type="oracle", ...)` |
