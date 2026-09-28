---
name: feature-kickoff
description: Use when planning a feature, creating or converting Plane work items, filing a bug, logging work, or estimating implementation time. Build a project-aware issue set with scope, tasks, risk class, acceptance criteria, and p50/p80 estimates before any Plane write.
---

# Feature kickoff

Prepare a complete, project-aware kickoff before any Plane write. This skill is
the planning layer; the existing `plane-issues` skill remains the only workflow
for Plane deduplication, creation, comments, relations, and state transitions.

## Required discovery

1. Read the active project's root `AGENTS.md` first. Follow its language,
   labels, issue prefixes, environment rules, acceptance requirements, testing
   conventions, and estimation overrides.
2. Identify the active project and repository root. Inspect the repository,
   current Git state and diff, relevant local plans, and existing related issues
   before proposing work. Redact credentials, secrets, customer messages,
   database values, production logs, and private attachments.
3. Resolve the Plane project using the existing `plane-issues` workflow. Never
   guess a project ID or use an unverified project name. If the required Plane
   tools are unavailable, continue with a local kickoff and state that Plane
   conversion was not performed.

## Kickoff record

Produce all of the following before any Plane write:

- **Objective**: the outcome and user or system problem.
- **Scope**: included work and explicit out-of-scope items.
- **Affected components/files**: verified paths, systems, and interfaces.
- **Ordered implementation tasks**: small, actionable tasks in dependency order.
- **Acceptance criteria**: observable checks, including project-required
  browser, accessibility, operational, or deployment checks.
- **Environment and risk class**: local, test, staging, or production, with a
  risk class such as low, medium, high, or critical and its rationale.
- **Dependencies/blockers**: prerequisites, decisions, external waiting, and
  unresolved acceptance questions.
- **Base estimate**, **p50 estimate**, and **p80 commitment estimate**: use
  planning ranges, never session wall-clock duration.

## Estimate calibration

Use project-specific overrides from `AGENTS.md` when present. Otherwise apply:

```text
base = max(15 minutes, 1.4 × planned_tasks)
risk_adjusted = base
+25% for browser/visual acceptance across breakpoints
+35% for database/schema or migration work
+50% for production SSH/server changes
+50% for client or third-party waiting or unclear acceptance
+25% for work spanning UI, backend, and tests
p80 = risk_adjusted × 1.25
```

State the units and assumptions. Treat p50 as the likely completion estimate
and p80 as the commitment estimate under the identified risks; neither is a
guarantee.

## Proposed Plane issue set

After discovery and estimation, prepare a proposed set of Plane issues. For
each issue include its title, description, labels, estimate, parent or epic
relationship, dependency relationships, acceptance criteria, affected scope,
environment, and expected verification evidence. Include the resolved project
name and explain any existing issue that should be updated instead of creating
a duplicate.

Ask for confirmation before creating or updating multiple Plane issues. Do not
perform any Plane write before that confirmation. A single bug still follows
the existing `plane-issues` deduplication and redaction workflow.

After confirmation, delegate the actual Plane deduplication, creation,
comments, relations, and state transitions to the existing `plane-issues`
workflow. This skill does not duplicate, update, or transition issues
independently.

## Completion evidence

An issue may be considered Done only after a closing evidence record contains:

- exact issue identifier;
- tests and checks run, with results;
- browser or production verification when relevant;
- commit or deployment reference;
- remaining risks, blockers, limitations, or explicit non-applicability.

If required evidence is missing, keep the issue open in the appropriate state
and record what remains. Keep all issue content and evidence minimal and
redacted.
