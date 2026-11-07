# The single map loader's own record of the artifact it most recently
# loaded successfully (openamrobot-interfaces#34, platform-sw#73/#36).
#
# Published transient-local so a late or restarted observer reads the
# retained sample directly, rather than inferring identity from timing or
# from a live /map message it cannot attribute to a specific load_map call.
# A failed load never publishes a new sample - the previous one (if any)
# stays retained and valid until the next successful load.

string artifact_hash      # map_identity_hash() of the map.yaml + image file actually
                          # requested, matching SiteConfigStatus.map_version's definition

uint32 load_generation    # increments by 1 on every successful load since this loader
                          # process started; lets a consumer notice a reload even when
                          # the new artifact's hash happens to equal the previous one

string grid_fingerprint   # fingerprint of the OccupancyGrid nav2_map_server's own
                          # ~/load_map response returned for this load - not a later,
                          # separately-observed /map message, which could have been
                          # produced by any caller, not necessarily this loader
