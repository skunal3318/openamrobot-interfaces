<!-- BEGIN OPENAMROBOT SHARED RULES v2 -->
# OpenAMRobot rules for contributors and agents
Canonical: openAMRobot/.github, agent-rules/SHARED_RULES.md, copied verbatim into every
repository's AGENTS.md (tools/check_agent_rules.py reports drift). This file holds process;
approved technical values live in openAMRobot/.github decisions.yaml. Labels: [check: tool]
means the tool detects that violation, and only in repositories where its workflow is installed
and required (rollout/README.md); [template: file]; [human: role, evidence] is a reviewer
decision. A text check proves textual consistency, never mechanical, electrical or safety correctness.

## Decisions
- decisions.yaml is the only register of approved values, limits, exclusions and distinctions.
  No file states a contradicting value; kept history carries `decision-allow: <ID> <reason>`.
  [check: check_decisions.py, listed patterns only] [human: entry's reviewer, entry's evidence]
- Changing a decision: (1) open a contract change request issue naming the entry; (2) the
  owner updates the source document; (3) one reviewed PR updates the register entry, its
  supersedes history, its check patterns with a test, and every affected consumer, or links
  each consumer PR; (4) the owner approves. [template: contract change request] [human: owner]
- Source documents are provenance. CI reads only the pinned register, never a drive or the
  docs site; a disagreement is reported to the owner, and no tool rewrites either side. [human: owner]
- Read STATE.md before work in a repository; update it in the same PR. [check: check_pr_evidence.py]

## Contracts
- Messages, services, actions, schemas, topic names, launch argument names and configuration
  IDs change only through a contract change request and one PR that updates the contract
  package and its consumers together. [template: contract change request] [human: software lead]
- New contract proposals stay labelled Proposed until the owner accepts them. [human: software lead]

## Tests
- Every behaviour change carries a test that fails when the change is reverted; the Tests
  section shows that failing run. [template: PR Tests section] [human: reviewer, the revert run]
- A suite that executes zero tests fails. [check: verify.sh; check_pr_evidence.py on reported counts]
- skip, xfail and importorskip name a tracking issue on the same line. [check: verify.sh]
- SKIP or BLOCKED is not PASS. Fixtures and fake hardware are not simulation, physical
  acceptance or release readiness. [human: reviewer, Not verified section]

## Evidence
- Every PR states base SHA, head SHA, exact commands, test counts and a Not verified section.
  [check: check_pr_evidence.py, presence only] [human: reviewer, that the commands were run]
- A draft becomes ready only when the evidence check passes on the current head. [human: author;
  ruleset required check once installed]

## Dependencies and licences
- Nothing is added, removed or upgraded as a side effect. A changed dependency manifest needs
  a Dependencies section naming each change, its licence and source. [check: check_pr_evidence.py]
- Licence headers and package.xml tags match the licence map: MIT software and firmware,
  CERN-OHL-P-2.0 hardware, CC-BY-4.0 documentation. [human: repository owner]
- The Integration Gate section lists overlapping PRs, reused existing or upstream work and
  what was rejected. Third-party provenance stays intact. [template: PR template]
- LICENSE, LICENSING.md, NOTICE and CODEOWNERS change only in a PR whose task names them.
  [human: platform lead]

## Safety
- No agent authors or modifies E-stop, brake, contactor, watchdog, motor-enable or
  charge-inhibit logic; agents report the need in an issue. [check: check_pr_evidence.py fails
  a safety-path change whose AI disclosure is not None] [human: platform lead, undisclosed use]
- A safety-path change needs two human approvals including the platform lead. The check only
  reports "safety path touched, two human approvals required" and that reviewers are requested;
  approvals are a ruleset requirement. [human: platform lead and one more maintainer]
- Functional telemetry, watchdogs, status displays and fixtures are never safety evidence.
  [check: check_decisions.py wording only] [human: platform lead, hardwired safety-chain test record]
- Automated or untrusted PR jobs never reach motion hardware or secrets. [human: CI owner]

## Publication
- Public material (docs/, assets/, README.md, any path containing "public") has no internal
  document links, prices, contact data or credentials. [check: check_public_extract.py]
- It names no private person, customer or partner; the application name is Use_Case_1. [human: docs owner]

## Agents
- Before any write, state a precondition block: repository (exact full name), branch, parent
  SHA, expected outcome. Read-only unless the task says otherwise. [template: agent-prompts/]
- Agent PRs stay draft until the work-package owner writes adopt, adapt or reject in the thread.
  [human: work-package owner]
- The PR's AI disclosure section names the tool and what it produced. [check: section present]
- Commits carry DCO sign-off with the contributor's own identity; never invent an identity or
  attestation. [human: maintainer; DCO check where installed]
- Gate A Teensy/MPU6500 and Gate B STM32/ICM-42688-P stay distinct; Jetson is the 2.0 compute.
  [check: check_decisions.py] Arm vendor SDKs stay behind device packages. [human: software lead]

## Failure
- A failed precondition (repository, branch, SHA, access, source) stops the task. Report the
  command, the error and the next step; never work around it. [template: agent-prompts/]
- Never merge, force-push, change settings, weaken a check or invent a result. [human: ruleset]

## Learning
- Every agent or process mistake gets an issue labelled harness. [template: harness mistake form]
- The monthly retro turns harness issues into one PR against this block. [human: software lead]
<!-- END OPENAMROBOT SHARED RULES v2 -->

# Repository-specific rules: openamrobot-interfaces
## Scope
- This repository owns shared ROS 2 messages, services, actions, schemas and interface contracts
  for the OpenAMRobot ecosystem.
- Keep application behavior, firmware implementations, hardware files and UI logic in their
  owning repositories; consumers must depend on these interfaces rather than redefining them.
- Keep interfaces hardware-agnostic, reusable, version-aware and transport-independent where
  possible.

## Contract changes
- Treat existing message, service, action, schema, field, constant, version and reason-code
  changes as contract changes. Do not silently change a wire contract or invent compatibility
  values.
- A contract change must include the compatibility evidence and consumer impact described in
  docs/verification.md, with any unresolved policy clearly marked rather than guessed.
- Preserve third-party provenance and the repository's MIT software and CC BY 4.0 documentation
  licensing boundaries.

## Verification
- Run `bash tools/verify.sh` from the checkout; it is the same combined gate used by CI.
- The gate covers dependency checks, schema and lint validation, clean ROS 2 Jazzy builds,
  generated-interface loading, compatibility checks, installed-consumer checks and both DDS
  middleware exchange tests.
- Missing dependencies, timeouts, skipped tests and unavailable evidence are failures or blocked
  evidence; do not convert them into PASS or weaken the gate.
- This repository verification does not prove physical robot, safety, release or production
  acceptance.
