# Aggregated navigation health/readiness. Functional status only, not a safety
# function, and scoped to the navigation subsystem — not whole-robot readiness.
# Arm/base authority and E-stop logic live in I1/I8, not here.

std_msgs/Header header

uint16 CONTRACT_VERSION=2         # current version of this interface — bumped 1->2 for
                                   # site_config (field addition, see CONTRACT.md)
uint16 contract_version           # producer sets this to CONTRACT_VERSION

string profile_id
string thresholds_id              # "UNSET" if no threshold profile applied

uint8 HEALTH_UNKNOWN=0            # unset field should never read as healthy
uint8 HEALTH_OK=1
uint8 HEALTH_DEGRADED=2
uint8 HEALTH_FAULT=3
uint8 health

uint8 NAVIGATION_READINESS_NOT_READY=0   # conservative default
uint8 NAVIGATION_READINESS_READY=1
uint8 navigation_readiness         # navigation only — not a whole-robot signal

uint16[] not_ready_reasons
uint16[] active_reasons
uint8 sensor_gaps

NavStackStatus stack
LocalizationStatus localization
SensorStatus[] sensors
NavTaskStatus task
RecoveryStatus recovery
ProtectionStatus protection
ActiveConstraint[] constraints
SiteConfigStatus site_config      # added in CONTRACT_VERSION 2 (platform-sw#36,
                                   # interfaces#27) - map/site-config identity and
                                   # floor-coverage. UNKNOWN until the producer has
                                   # loaded a site profile and compared it.
# base/I8 controller has no dedicated status yet - see reason codes below

# reason codes: 0=NONE everywhere, groups start at x001, append-only
uint16 NONE=0

# stack
uint16 NAV_STACK_NOT_STARTED=1001
uint16 NAV_STACK_STARTING=1002
uint16 NAV_STACK_RESETTING=1003
uint16 NAV_NODE_INACTIVE=1004
uint16 NAV_CONFIG_FAULT=1005

# sensors
uint16 SENSOR_DATA_STALE=2001
uint16 SENSOR_NOT_CONFIGURED=2002
uint16 SENSOR_NO_DATA_YET=2003
uint16 SENSOR_DATA_INVALID=2004
uint16 SENSOR_RATE_LOW=2005

# localization
uint16 LOCALIZATION_NOT_INITIALIZED=3001
uint16 LOCALIZATION_UNCERTAIN=3002
uint16 LOCALIZATION_STALE_WHILE_MOVING=3003
uint16 LOCALIZATION_PAUSED_FOR_DOCKING=3004
uint16 TF_UNAVAILABLE=3005

# nav task
uint16 GOAL_OUTSIDE_MAP=4001
uint16 GOAL_BLOCKED=4002
uint16 START_BLOCKED=4003
uint16 NO_VALID_PATH=4004
uint16 PLANNER_TIMEOUT=4005
uint16 CONTROLLER_TIMEOUT=4006
uint16 STUCK=4007
uint16 LOCAL_BLOCKED=4008
uint16 NAV_UNKNOWN_FAULT=4009

# recovery
uint16 RECOVERY_IN_PROGRESS=5001
uint16 RECOVERY_LIMIT_REACHED=5002

# protection
uint16 COLLISION_LAYER_INACTIVE=6001
uint16 MOTION_SOURCE_UNPROTECTED=6002
uint16 REAR_COVERAGE_UNAVAILABLE=6003
uint16 PROTECTION_STATE_UNKNOWN=6004
uint16 SPEED_LIMIT_ACTIVE=6005
uint16 REVERSE_SPEED_LIMITED=6006
uint16 MOTION_SOURCE_PARTIALLY_PROTECTED=6007   # PARTIAL collision-monitor coverage, distinct from fully UNPROTECTED
uint16 COLLISION_APPROACH_ACTIVE=6008           # collision_monitor's "approach" polygon has triggered

# docking
uint16 DOCK_ENGAGEMENT_UNKNOWN=7001
uint16 DOCK_TAGS_NOT_VISIBLE=7002
uint16 DOCK_ALIGNMENT_FAILED=7003
uint16 DOCK_TIMEOUT=7004
uint16 DOCK_STAGING_FAILED=7005
uint16 UNDOCK_FAILED=7006
uint16 UNDOCKING_BEFORE_GOAL=7007
uint16 DOCK_REASON_UNSPECIFIED=7008

# parking
uint16 PARK_TARGET_UNREACHABLE=8001
uint16 PARK_POSE_MISSED=8002
uint16 PARKING_NOT_IMPLEMENTED=8003

# base / I8
uint16 BASE_LINK_LOST=9001
uint16 BASE_NOT_READY=9002
uint16 ESTOP_ACTIVE=9003          # only on fresh I8 telemetry reporting E-stop
                                   # active; stale/missing telemetry is
                                   # BASE_LINK_LOST/BASE_NOT_READY, not this
uint16 BATTERY_LOW=9004

# site configuration (CONTRACT_VERSION 2, platform-sw#36 / interfaces#27)
uint16 SITE_CONFIG_NOT_LOADED=10001
uint16 MAP_ID_MISMATCH=10002
uint16 MAP_STALE=10003
uint16 CONFIG_ID_MISMATCH=10004
uint16 FLOOR_COVERAGE_INSUFFICIENT=10005   # a required zone is missing - blocks readiness
uint16 SITE_CONFIG_UNKNOWN=10006
uint16 FLOOR_COVERAGE_OPTIONAL_GAP=10007   # only an optional zone is missing - degrades
                                            # health, does not block readiness
