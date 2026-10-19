uint8 STATE_UNKNOWN=0
uint8 STATE_MATCHED=1
uint8 STATE_MISMATCHED=2
uint8 STATE_STALE=3
uint8 STATE_MISSING=4
uint8 state

uint8 COVERAGE_UNKNOWN=0
uint8 COVERAGE_INSUFFICIENT=1
uint8 COVERAGE_PARTIAL=2
uint8 COVERAGE_FULL=3
uint8 floor_coverage              # meaningful only when state==STATE_MATCHED; UNKNOWN otherwise

uint16 reason                     # see NavigationStatus.msg; NONE only when
                                   # state==STATE_MATCHED and floor_coverage==COVERAGE_FULL

string map_id
string map_version                # SHA-256 over canonicalized map YAML fields + raw image
                                   # bytes; "" when state==STATE_UNKNOWN or STATE_MISSING
string config_id
string config_version             # SHA-256 over canonicalized site-config file content;
                                   # same validity rule as map_version
