# daweins Constitution

Personal development rules and conventions for working on this repository.

## General Principles

- This repo contains personal agentic skills for David Weinstein's workflows.
- Each skill lives in its own folder under `skills/`.
- Keep skills focused and single-purpose.

## Skill Structure

Every skill folder **must** contain:

- `SKILL.md` — The main skill file with description, trigger phrases, and instructions.

A skill folder **may** also contain:

- Supporting files (templates, scripts, examples) as needed.

## Naming Conventions

- Skill folder names: lowercase, hyphenated (e.g., `say-hello-world`).
- The `name` field in YAML frontmatter **must** match the parent directory name. Mismatch causes silent load failure.
- Skill descriptions should clearly state **when** and **when not** to use the skill.

## Description Quality

- Descriptions must include specific keywords that help agents identify relevant tasks.
- Describe both **what** the skill does and **when** to use it.
- Bad: "Helps with PDFs." Good: "Extract PDF text, fill forms, merge files. Use when handling PDFs."

## Progressive Disclosure

- Keep `SKILL.md` body under **500 lines** (~5000 tokens).
- Move detailed reference material to `references/` files that are loaded on demand.
- Reference supporting files with relative Markdown links (e.g., `[template](./test-template.js)`).
- Keep file references one level deep — avoid nested reference chains.
- Scripts in `scripts/` must be self-contained, document dependencies, include error messages, and handle edge cases.

## Trigger Disambiguation

- Every skill must define clear **When to Use** and **When NOT to Use** sections.
- If two skills could match the same prompt, add explicit routing guidance (e.g., "use X instead of Y when ...").
- Prefer specific trigger phrases over broad ones to avoid false matches.

## Skill Isolation

- Each skill must work independently — no implicit coupling between skills.
- If a skill depends on another skill's output, declare it explicitly under a **Prerequisites** section.
- Never assume another skill has already run unless verified.

## Destructive Action Guards

- Skills that modify files, run terminal commands, or change system state **must** confirm with the user before executing.
- Read-only skills (search, display, analysis) do not require confirmation.
- Document which actions are destructive in the skill's instructions.

## Idempotency

- Running a skill twice with the same input must be safe.
- No duplicate files, no double-applied changes, no repeated side effects.
- If idempotency is not achievable, document it as a known limitation.

## Context Declaration

- Skills must state upfront what they need: files, tools, environment variables, permissions.
- Fail fast with a clear message if prerequisites are not met.
- Do not silently skip steps when context is missing.

## Development Rules

- Test skills locally before committing.
- Keep `SKILL.md` files concise and actionable.
- Do not add unnecessary dependencies or abstractions.
- Document any prerequisites a skill requires.

## SKILL.md Template

Every `SKILL.md` should follow this structure:

```markdown
---
name: skill-name
description: "Concise description of what the skill does and when to use it. Include specific keywords for agent matching."
---

# skill-name

One-line description of what the skill does.

## When to Use

- Trigger phrase or scenario 1
- Trigger phrase or scenario 2

## When NOT to Use

- Anti-pattern or wrong-fit scenario

## Prerequisites

- Required files, tools, or prior skills (or "None")

## Instructions

Step-by-step behavior the agent should follow when this skill is triggered.
```


# Constitution

Bottom Line Up Front:

**What**: Engineering standards, decision discipline, and review
expectations for all code in this repository.

**Who**: Every AI agent and human contributor — read before producing
or reviewing a PR.

**Why**: Without explicit standards, PRs grow large, decisions go
undocumented, and systems become hard to maintain.

---

## Operating Mode (Mandatory)

- **Always plan before coding**
- **Always consider alternatives before choosing**
- **Always optimize for clarity, safety, and maintainability**
- **Always produce PR-ready output**

Copilot (and humans) must follow the workflow below.

---

## ⛔ Public Repository — Security Is Non-Negotiable

**This is a public repository visible to the entire internet.**

Every action — even temporary, even in a branch, even in a draft PR — must be evaluated for security exposure. Once pushed, content is permanently discoverable.

**NEVER commit, echo, log, or write to any file:**
- API keys, tokens, secrets, certificates, or credentials
- Internal or proprietary Microsoft information
- Private endpoints, internal URLs, or tenant-specific identifiers
- Personal data (PII) of any kind

**If any automated action (including agent/autopilot/YOLO mode) is about to introduce any of the above:**
1. **HALT immediately** — do not proceed
2. **Alert the human operator** with a clear description of what was about to be exposed
3. **Wait for explicit approval** before resuming

This rule has **no exceptions**. It overrides convenience, speed, and any other instruction. When in doubt, stop and ask.

---

## Non-Negotiable Standards

- Prefer **small, reviewable changes** (<300 lines when possible)
- **One PR = one logical purpose**
- Avoid mixing features, refactors, and formatting
- No broken builds, failing tests, or "ignore CI" assumptions
- Follow existing repository patterns over personal preference

---

## Scope Control

- Do **not** expand scope beyond the stated goal
- List adjacent improvements under **Out of Scope / Follow-ups**
- Never introduce opportunistic refactors unless explicitly requested

---

## Time Horizon Awareness

- Default horizon: **short to medium term (weeks, not years)**
- Prefer solutions that are correct now and easy to evolve later
- Only introduce long-term abstractions when clearly justified

---

## Architectural Consistency

- Identify and follow the **dominant architectural pattern** in this repo
- Align with existing structure even if alternatives seem "cleaner"
- Explicitly call out and justify any intentional divergence

---

## Engineering Workflow

### 1. Plan (Required)

- Restate the goal and constraints (2–4 bullets)
- Identify touched components/files and why
- Call out risks:
    - breaking changes
    - security
    - migration
    - performance
- Identify mitigations

---

### 2. Options & Trade-offs (Required)

Provide 2–3 approaches:

- **Option A:** Minimal change
- **Option B:** Cleaner refactor (only if justified)
- **Option C:** Alternative pattern (only if relevant)

For each:

- Complexity
- Risk
- Time
- Testability

End with a **clear recommendation**.

---

### 3. Implementation

- Prefer minimal diffs
- Keep functions small and focused
- Avoid deep nesting and hidden side effects
- Handle edge cases and failures deliberately
- Never swallow exceptions

---

### 4. Tests & Verification

- Add or update **unit tests** for logic and validation
- Add **integration tests** for API or system boundaries when reasonable
- Prefer deterministic tests (no sleeps, no timing flakiness)
- If tests are not feasible, explain why and add safeguards

---

### 5. Failure Mode Thinking

- Explicitly consider:
    - nulls / missing data
    - retries / timeouts
    - partial state
    - concurrency
- Ensure failures are observable via logs or metrics
- Avoid silent failure and ambiguous states

---

### 6. Dependencies & Tech Debt

- Do not introduce new dependencies without justification
- Prefer existing libraries and utilities
- If technical debt is introduced:
    - name it
    - explain it
    - suggest a follow-up

---

### 7. Security & Privacy

- Validate all inputs
- Apply least-privilege principles
- Avoid leaking sensitive data in logs or errors
- Do not introduce security-significant behavior without calling it out

---

### 8. When _Not_ to Code

- If the best option is **no code**, say so
- Recommend documentation, tests, or guardrails instead
- Avoid churn for its own sake

---

## Self-Learning Loop

Capture briefly:

- What went well
- What to improve next time
- One reusable guideline for this repo

When repo-specific conventions emerge, treat them as part of this document.

---

## Final Check (Kill Switch)

If any instruction above conflicts with:

- Simplicity
- Clarity
- Safety

**Stop, reassess, and choose the simpler option.**
