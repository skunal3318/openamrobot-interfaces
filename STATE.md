# STATE

Read this file before any work in this repository and update it in the same PR as the work.
The PR evidence check fails when STATE.md exists and a PR neither updates it nor says
"no change" with a reason. Keep it under 60 lines; facts only, each with a date or SHA.

## Repository

- Type and lifecycle: interface, active
- Readiness: R1 (evidence: ROS 2 Jazzy workflow running `tools/verify.sh` on main, run 37936438992)
- Owner role: software-lead
- Verification: `bash tools/verify.sh`; last PASS on main at 87ab8a9 (2026-10-09), run 37936438992

## Current work

| Work package | Branch or PR | Status | Next step |
|---|---|---|---|
| C10 dataset quality gate | PR #25 | draft / synthetic evidence only | Work-package owner reviews placement and supplies real-episode evidence |
| Shared rules v2 (rollout step a, pilot) | PR #26 | in review | merge, then step (b) pin the harness |

## Decisions this repository implements

- CHARGING, DOCK-NO-CONTACTS, DOCKING-NOT-CHARGING (register scope includes this repository;
  `DockingStatus.msg` carries no charging or contact state). Watchdog decisions check: 0
  findings at e63311d (2026-10-17).

## PR #28 snapshot follow-up (2026-11-09)

- Based on fbb7b3f: compatibility/jazzy.json now includes MapIdentity from
  exact-head hosted artifact 13579087673 (run 42384588332). Existing interface
  hashes, definitions and versions are unchanged. Local compatibility tests pass.
- MapIdentity #34 remains Proposed; no owner acceptance is implied. PR #28
  still requires author DCO correction and downstream producer/observer review.
- Fresh ROS verification is pending; local Docker is unavailable.

## Known gaps

- Harness rollout steps (b) to (e) not done as of main 87ab8a9: `repository-quality` calls the
  reusable workflow at `@main`; Watchdog reports 3 unpinned actions (2026-10-17).
- C10 real-episode and production-acceptance evidence is not verified; see PR #25.
- No runtime ownership or approved release pin is claimed for the proposed C10 reference checker.

## Not verified

- This step-(a) PR changes repository guidance only; it does not run ROS, DDS, hardware or production acceptance tests.
- No physical robot, safety-chain, released binary or cross-version deployment evidence is claimed.
