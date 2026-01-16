# Ralphus Research

> *"I'm learnding!" — Ralph Wiggum*

**Ralphus Research** adapts the Ralphus autonomous coding loop for **learning and research**. Instead of implementing features, it builds mental models. Instead of running tests, it validates understanding through self-quizzes.

## The Idea

> "If you don't understand a domain > run ralphus in a loop > have it commit each increment in super thin commits > read each commit. Super fast way to learn the theory of any domain. The goal isn't shippable software—it's to automatically build your brain's mental model. One commit at a time."

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    THE RESEARCH CYCLE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│    ┌──────────┐     ┌──────────┐     ┌──────────┐              │
│    │  Study   │────▶│  Learn   │────▶│  Commit  │              │
│    │  Plan    │     │  Topic   │     │ Knowledge│              │
│    └──────────┘     └──────────┘     └──────────┘              │
│         ▲                                  │                    │
│         │                                  │                    │
│         │         ┌──────────┐             │                    │
│         └─────────│  Fresh   │◀────────────┘                    │
│                   │ Context  │                                  │
│                   │ (forget) │                                  │
│                   └──────────┘                                  │
│                                                                 │
│    "I choo-choo-choose to understand this concept!"            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Each iteration:
1. **Agent wakes up** with no memory of previous iterations
2. **Reads the plan** (RESEARCH_PLAN.md) to find the next topic
3. **Validates existing knowledge** via self-quiz (if artifact exists)
4. **Researches** using web search and documentation
5. **Writes artifacts** (SUMMARY.md, QUIZ.md, CONNECTIONS.md)
6. **Commits** the knowledge increment
7. **Context clears** and the loop repeats

## Domain Translation

| Coding (Ralphus) | Research (Ralphus Research) |
|------------------|----------------------------|
| specs/*.md | questions/*.md |
| IMPLEMENTATION_PLAN.md | RESEARCH_PLAN.md |
| Build code | Write explanations |
| Run tests | Self-quiz validation |
| Commit code | Commit knowledge artifacts |
| "Feature complete" | "Topic mastered" |

## Quick Start

```bash
# Copy files to your research project
cp ralphus_research/scripts/loop.sh .
cp ralphus_research/instructions/PROMPT_research_plan.md .
cp ralphus_research/instructions/PROMPT_research_build.md .
mkdir -p questions knowledge

# Create your research question
echo "# What is [topic]?" > questions/my-topic.md

# Phase 1: Create learning plan
./loop.sh plan

# Phase 2: Learn iteratively
./loop.sh

# Read the commits to build your mental model
git log --oneline
```

## The Backpressure Mechanism

In coding, tests provide feedback. In research, **self-quizzes** provide backpressure:

1. Each topic produces a QUIZ.md with 3-5 questions
2. Next iteration attempts to answer WITHOUT reading the summary
3. If >80% correct → topic validated, move on
4. If <80% correct → topic needs reinforcement

This creates the self-correcting loop that makes Ralphus work.

## File Structure

```
my-research-project/
├── loop.sh                    # The eternal research loop
├── PROMPT_research_plan.md    # Planning instructions
├── PROMPT_research_build.md   # Research instructions
├── RESEARCH_PLAN.md           # Learning progress (generated)
├── questions/                 # What you want to learn
│   └── my-topic.md
└── knowledge/                 # What you've learned
    └── 001-first-concept/
        ├── SUMMARY.md         # The explanation
        ├── QUIZ.md            # Self-validation
        └── CONNECTIONS.md     # Knowledge graph
```

## Reading the Commits

The magic is in the git history. Each commit is one learned concept:

```bash
git log --oneline
# abc1234 Learn: quantum-entanglement
# def5678 Learn: superposition
# ghi9012 Learn: qubits-vs-bits

# Read a specific learning increment
git show abc1234
```

This creates a **learning journal** you can review to rebuild your mental model.

## License

MIT — Learn whatever you want. Ralphus certainly will.
