# [Feature] <concise title>

## Summary
What’s the user-facing outcome? One or two lines.

## Context / Problem
Link issues (e.g., Closes #123, M2-03). Briefly restate the problem and constraints.

## Solution
High-level approach. Mention modules touched (Features/{…}, Core/{Networking, Persistence, …}).

## Screenshots / Video
Attach UI changes (loading/empty/error states).

## Acceptance Criteria
- [ ] Matches linked issue AC
- [ ] Empty/loading/error states implemented
- [ ] VoiceOver labels + Dynamic Type verified
- [ ] Performance acceptable on iPhone 16 simulator

## Test Plan
- [ ] Unit tests added/updated
- [ ] Snapshot tests updated (search/results/empty)
- [ ] Manual QA: steps below

**Manual QA Steps**
1. …
2. …
3. …

## Risk / Rollback
Main risks + how to disable/roll back (feature flag, revert, or server toggle).

## Rollout & Telemetry
- [ ] Behind feature flag
- [ ] Metrics/analytics added (if applicable)

## Accessibility
Notes on traits, focus order, hit targets, contrast.

## Performance
Any notable work (debounce, main-thread checks, allocations). Add signposts if relevant.

## Privacy & Security
Keys, user data, and logging reviewed. No secrets in code or logs.

## Dependencies
New packages, tools, or system capabilities.

## Notes for Reviewers
Anything non-obvious (tradeoffs, TODOs, follow-ups).
