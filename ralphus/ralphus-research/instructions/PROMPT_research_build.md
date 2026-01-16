0a. Study @RESEARCH_PLAN.md to find the next topic to learn.
0b. Study `knowledge/` to understand what's already been learned.
0c. Study `questions/*` to understand the original research questions.

## THE RESEARCH CYCLE

1. **PICK ONE TOPIC** from @RESEARCH_PLAN.md (highest priority incomplete topic).

2. **VALIDATE EXISTING** (if knowledge artifact already exists for this topic):
   - Read `knowledge/[topic]/QUIZ.md`
   - Attempt to answer the questions WITHOUT reading SUMMARY.md
   - Then read SUMMARY.md and compare
   - If your answers were >80% correct: Mark as VALIDATED in plan, move to next topic
   - If <80% correct: This topic needs REINFORCEMENT, proceed to step 3

3. **RESEARCH** (for new topics or reinforcement):
   - Use web search (websearch_web_search_exa) to gather current, accurate information
   - Use librarian agents for academic/technical sources
   - Cross-reference multiple sources for accuracy
   - Synthesize information into your own understanding

4. **WRITE ARTIFACTS** in `knowledge/[NNN-topic-slug]/`:

   **SUMMARY.md** - The knowledge artifact:
   - ELI5: Simple explanation anyone could understand (1-2 paragraphs)
   - Technical: Detailed explanation with proper terminology (2-3 paragraphs)
   - Key Insights: 3-5 bullet points of the most important takeaways
   - Sources: Links/references consulted
   - My Understanding: Your synthesis in your own words

   **QUIZ.md** - Self-validation questions:
   - 3-5 questions that test real understanding (not just recall)
   - Include expected answers for each question
   - At least one question should connect to other topics

   **CONNECTIONS.md** - Knowledge graph edges:
   - Prerequisites: What you need to know first
   - Enables: What this unlocks understanding of
   - Related: Concepts that share ideas with this one

5. **COMMIT**: `git add knowledge/ RESEARCH_PLAN.md && git commit -m "Learn: [topic-name]"`

6. **UPDATE PLAN**: Mark topic as LEARNED in @RESEARCH_PLAN.md

## Rules

**Topic-by-Topic Rule**: ONE topic at a time. Do NOT research multiple topics before committing. Each commit = one learned concept.

**Completion Signals**:
- When topic is complete: `<promise>PHASE_COMPLETE</promise>` and STOP
- When ALL topics in plan are done: `<promise>COMPLETE</promise>`
- If stuck after 3 attempts: `<promise>BLOCKED:[topic]:[reason]</promise>`

## Guardrails

99999. Explain concepts in your own words. No copy-paste from sources.
999999. Every topic MUST have a QUIZ.md for self-validation.
9999999. Connect new learning to existing knowledge in CONNECTIONS.md.
99999999. Cite sources when making factual claims.
999999999. If you discover a prerequisite you don't understand, add it to RESEARCH_PLAN.md.
9999999999. Keep explanations concise. Depth over breadth.
99999999999. The goal is understanding, not comprehensive coverage.

## Agent Delegation

| Task | Agent | Invocation |
|------|-------|------------|
| File/knowledge search | explore | `background_task(agent="explore", ...)` |
| Web search, docs, papers | librarian | `background_task(agent="librarian", ...)` |
| Complex reasoning | oracle | `task(subagent_type="oracle", ...)` |
