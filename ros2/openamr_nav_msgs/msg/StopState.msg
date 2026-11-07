# Stop (software) gate state, platform-sw#119 (Alex's Option B decision, 5 Nov 2026).
#
# Published by safety_stop_gate_node (platform-sw) on /safety/stop_lock's replacement
# contract. Supersedes inferring gate state from /safety/stop_lock (a plain Bool) plus
# guesswork about the since-removed Twist-based rearm latch.
#
# RELEASE_REFUSED means a release was requested (the service was called) but withheld
# because the gate's own release conditions were not yet satisfied - not that the lock
# is still freshly engaged. reason is populated only in this state and names which
# condition is still blocking (e.g. a specific action server's goal, dock_trigger not
# idle, or a specific cmd_vel input not yet zero/silent past its own timeout) - a
# human/UI-readable string, not a numeric code, per the #119 decision.

uint8 STATE_LOCKED=0
uint8 STATE_RELEASE_REFUSED=1
uint8 STATE_RUNNING=2
uint8 state

string reason
