#!/usr/bin/env bash
# Run from any directory. Requires ROS 2 Jazzy and dependencies (see docs).
set -eo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/.verification"
run=$(mktemp -d "$root/.verification/run.XXXXXX")
exec > >(tee "$run/verification.log") 2>&1
stage=prerequisites
finish() {
  result=$?
  if [ "$result" -eq 0 ]; then
    echo "PASS: all implemented verification stages" | tee "$run/result.txt"
  else
    echo "FAIL: $stage (exit $result)" | tee "$run/result.txt"
  fi
  echo "Evidence: $run"
  exit "$result"
}
trap finish EXIT

# Prepare declared dependencies in the shared quality/test container.
# The standalone ros2-jazzy.yml workflow already has these prerequisites;
# this idempotent CI-only bootstrap also supports the shared clean image.
if [ "${CI:-}" = "true" ]; then
  stage=ci-ros-bootstrap
  needs_apt=false
  for pkg in python3-colcon-common-extensions python3-rosdep \
      python3-jsonschema python3-yaml ros-jazzy-rmw-fastrtps-cpp \
      ros-jazzy-rmw-cyclonedds-cpp; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null |
      grep -qx 'install ok installed' || needs_apt=true
  done
  if [ "$needs_apt" = true ]; then
    apt-get update
    apt-get install -y --no-install-recommends \
      python3-colcon-common-extensions python3-rosdep python3-jsonschema \
      python3-yaml ros-jazzy-rmw-fastrtps-cpp ros-jazzy-rmw-cyclonedds-cpp
  fi
  if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    rosdep init
  fi
  if [ ! -d "${ROS_HOME:-$HOME/.ros}/rosdep/sources.cache" ]; then
    rosdep update --rosdistro jazzy
  fi
  rosdep install --from-paths "$root/ros2" --ignore-src --rosdistro jazzy -y
  stage=prerequisites
fi

# Never inherit ROS overlays, Python paths or CMake prefixes from the caller.
mkdir -p "$run/home/.ros"
# rosdep's downloaded index is prerequisite data, not a developer overlay.
if [ -d "${ROS_HOME:-$HOME/.ros}/rosdep" ]; then
  cp -a "${ROS_HOME:-$HOME/.ros}/rosdep" "$run/home/.ros/"
fi
clean_bash() {
  env -i HOME="$run/home" PATH=/usr/bin:/bin LANG=C.UTF-8 PYTHONNOUSERSITE=1 \
    bash --noprofile --norc -eo pipefail "$@"
}
clean_bash -c '
  test -f /opt/ros/jazzy/setup.bash
  source /opt/ros/jazzy/setup.bash
  command -v colcon
  command -v rosdep
  rosdep check --from-paths "$1/ros2" --ignore-src --rosdistro jazzy
' verify "$root"

stage=lint-and-schema
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  python3 "$1/tools/lint_schemas.py" --root "$1" --report "$2/lint-schema.json"
  python3 "$1/tools/run_verification_tests.py" "$1/tests" test_schema_validation.py
' verify "$root" "$run" 2>&1 | tee "$run/lint-schema.log"

stage=interface-build
mkdir -p "$run/producer/src"
cp -a "$root/ros2/." "$run/producer/src/"
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  cd "$1/producer"
  colcon build --base-paths src --event-handlers console_direct+
' verify "$run"

# Relocate an ordinary (not symlink) install and retire the original workspace.
# Absolute source/build/install references now point to paths that do not exist.
cp -a "$run/producer/install" "$run/underlay"
mv "$run/producer" "$run/producer-retired"

stage=generated-interfaces
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  source "$1/underlay/local_setup.bash"
  python3 "$2/tools/verify_interfaces.py" "$1/producer-retired/src"
' verify "$run" "$root" | tee "$run/generated-interfaces.log"

stage=interface-compatibility
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  source "$1/underlay/local_setup.bash"
  python3 "$2/tools/check_compatibility.py" --source "$2/ros2" \
    --baseline "$2/compatibility/jazzy.json" --base-ref "$3" \
    --output "$1/interface-snapshot.json" --report "$1/compatibility.json"
  python3 "$2/tools/run_verification_tests.py" "$2/tests" test_compatibility.py
' verify "$run" "$root" "${VERIFY_BASE_REF:-HEAD^}" 2>&1 | tee "$run/compatibility.log"

stage=clean-consumer-build
mkdir -p "$run/consumer/src"
cp -a "$root/tests/install_consumer" "$run/consumer/src/"
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  source "$1/underlay/local_setup.bash"
  cd "$1/consumer"
  colcon build --base-paths src --event-handlers console_direct+
  source install/local_setup.bash
  ros2 run interface_install_consumer verify_installed_interfaces
' verify "$run"

# Both middleware implementations are mandatory; pass the selection through env -i.
for rmw in rmw_fastrtps_cpp rmw_cyclonedds_cpp; do
  stage="navigation-message-exchange-$rmw"
  clean_bash -c '
    source /opt/ros/jazzy/setup.bash
    source "$1/underlay/local_setup.bash"
    export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
    export RMW_IMPLEMENTATION="$3"
    echo "RMW_IMPLEMENTATION=$RMW_IMPLEMENTATION"
    ros2 pkg prefix "$RMW_IMPLEMENTATION"
    timeout 45s python3 "$2/tests/navigation_exchange.py" \
      --expected-prefix "$1/underlay/openamr_nav_msgs"
  ' verify "$run" "$root" "$rmw" 2>&1 | tee "$run/navigation-exchange-$rmw.log"
done

stage=reverted-interface-build
mkdir -p "$run/reverted/src"
cp -a "$root/ros2/openamr_nav_msgs" "$run/reverted/src/"
python3 - "$run/reverted/src/openamr_nav_msgs/msg/NavigationStatus.msg" "$run/reverted-interface.patch" <<'PY'
import difflib
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
removed = [line for line in lines if line.split("#", 1)[0].split() == ["string", "thresholds_id"]]
if len(removed) != 1:
    raise SystemExit("FAIL: reverted-interface fixture requires exactly one thresholds_id field")
reverted = [line for line in lines if line not in removed]
path.write_text("".join(reverted))
Path(sys.argv[2]).write_text("".join(difflib.unified_diff(
    lines, reverted, fromfile="current/NavigationStatus.msg", tofile="reverted/NavigationStatus.msg"
)))
print("Fixture: removed NavigationStatus.thresholds_id from temporary source only")
PY
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  cd "$1/reverted"
  colcon build --base-paths src --event-handlers console_direct+
' verify "$run"

stage=reverted-interface-consumer
set +e
clean_bash -c '
  source /opt/ros/jazzy/setup.bash
  source "$1/reverted/install/local_setup.bash"
  export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
  export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
  timeout 45s python3 "$2/tests/navigation_exchange.py" \
    --expected-prefix "$1/reverted/install/openamr_nav_msgs"
' verify "$run" "$root" > "$run/reverted-consumer.log" 2>&1
consumer_status=$?
set -e
printf 'Consumer exit: %s\n' "$consumer_status" >> "$run/reverted-consumer.log"
cat "$run/reverted-consumer.log"
if [ "$consumer_status" -ne 42 ] || ! grep -Fxq \
  'CONTRACT_MISMATCH: NavigationStatus.thresholds_id expected string' "$run/reverted-consumer.log"; then
  echo "FAIL: reverted consumer must reject the missing field with exit 42; got $consumer_status"
  exit 1
fi
echo 'PASS: reverted interface rejected by unchanged consumer (expected exit 42)'
