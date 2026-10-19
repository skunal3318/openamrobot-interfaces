"""Hardware-free, two-process navigation message exchange and consumer contract."""

import argparse
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import uuid

from ament_index_python.packages import get_package_prefix
from openamr_nav_msgs.msg import NavigationStatus, SensorStatus
import rclpy
from rclpy.qos import DurabilityPolicy, QoSProfile, ReliabilityPolicy


def qos():
    return QoSProfile(
        depth=1,
        reliability=ReliabilityPolicy.RELIABLE,
        durability=DurabilityPolicy.TRANSIENT_LOCAL,
    )


def publish(topic, ready):
    rclpy.init()
    node = rclpy.create_node("verification_publisher")
    try:
        publisher = node.create_publisher(NavigationStatus, topic, qos())
        message = NavigationStatus()
        message.header.frame_id = "map"
        message.header.stamp.sec = 123
        message.contract_version = NavigationStatus.CONTRACT_VERSION
        message.profile_id = "verification-profile"
        message.thresholds_id = "verification-thresholds"
        message.health = NavigationStatus.HEALTH_DEGRADED
        message.navigation_readiness = NavigationStatus.NAVIGATION_READINESS_NOT_READY
        message.not_ready_reasons = [NavigationStatus.BASE_LINK_LOST]
        message.active_reasons = [NavigationStatus.BASE_LINK_LOST]
        # CONTRACT_VERSION 2: site_config round-trips as a nested field, same as the
        # existing sensors[] / stack / localization sub-messages below.
        message.site_config.state = message.site_config.STATE_MATCHED
        message.site_config.floor_coverage = message.site_config.COVERAGE_FULL
        message.site_config.reason = NavigationStatus.NONE
        message.site_config.map_id = "verification-map"
        message.site_config.map_version = "a" * 64
        message.site_config.config_id = "verification-config"
        message.site_config.config_version = "b" * 64
        sensor = SensorStatus()
        sensor.id = "test-lidar"
        sensor.kind = SensorStatus.KIND_LIDAR
        sensor.state = SensorStatus.STATE_OK
        sensor.rate_hz = 10.0
        sensor.required = True
        message.sensors = [sensor]
        publisher.publish(message)
        Path(ready).write_text("published", encoding="utf-8")
        # Publish exactly once: the late consumer must receive retained data.
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            rclpy.spin_once(node, timeout_sec=0.1)
    finally:
        node.destroy_node()
        rclpy.shutdown()


def check_values(message):
    expected = {
        "contract_version": NavigationStatus.CONTRACT_VERSION,
        "profile_id": "verification-profile",
        "thresholds_id": "verification-thresholds",
        "health": NavigationStatus.HEALTH_DEGRADED,
        "navigation_readiness": NavigationStatus.NAVIGATION_READINESS_NOT_READY,
    }
    for field, value in expected.items():
        if getattr(message, field) != value:
            raise RuntimeError(f"FAIL: unexpected {field}: {getattr(message, field)!r}")
    if message.header.frame_id != "map" or message.header.stamp.sec != 123:
        raise RuntimeError("FAIL: header did not round-trip")
    if (
        list(message.not_ready_reasons) != [NavigationStatus.BASE_LINK_LOST]
        or list(message.active_reasons) != [NavigationStatus.BASE_LINK_LOST]
    ):
        raise RuntimeError("FAIL: reason arrays did not round-trip")
    if len(message.sensors) != 1:
        raise RuntimeError("FAIL: nested sensor array did not round-trip")
    sensor = message.sensors[0]
    if (sensor.id, sensor.kind, sensor.state, sensor.rate_hz, sensor.required) != (
        "test-lidar", SensorStatus.KIND_LIDAR, SensorStatus.STATE_OK, 10.0, True
    ):
        raise RuntimeError("FAIL: nested sensor values did not round-trip")
    site_config = message.site_config
    if (
        site_config.state != site_config.STATE_MATCHED
        or site_config.floor_coverage != site_config.COVERAGE_FULL
        or site_config.reason != NavigationStatus.NONE
        or site_config.map_id != "verification-map"
        or site_config.map_version != "a" * 64
        or site_config.config_id != "verification-config"
        or site_config.config_version != "b" * 64
    ):
        raise RuntimeError("FAIL: site_config (CONTRACT_VERSION 2) did not round-trip")


def consume():
    # This same preflight runs for both real and deliberately reverted installs.
    # Exit 42 is reserved for this exact consumer requirement, never a timeout.
    if NavigationStatus.get_fields_and_field_types().get("thresholds_id") != "string":
        print("CONTRACT_MISMATCH: NavigationStatus.thresholds_id expected string", flush=True)
        return 42
    site_config_type = NavigationStatus.get_fields_and_field_types().get("site_config")
    if site_config_type != "openamr_nav_msgs/SiteConfigStatus":
        print(
            "CONTRACT_MISMATCH: NavigationStatus.site_config missing or wrong type "
            f"(CONTRACT_VERSION 2 expected, got {site_config_type!r}) - this exit code "
            "is also what a deliberately-reverted install should produce",
            flush=True,
        )
        return 42
    print(f"RMW loaded: {rclpy.utilities.get_rmw_implementation_identifier()}", flush=True)
    topic = f"/interface_verification/navigation_{uuid.uuid4().hex}"
    with tempfile.TemporaryDirectory(prefix="navigation-exchange-") as temporary:
        ready = Path(temporary) / "published"
        publisher = subprocess.Popen(
            [sys.executable, __file__, "--publish", topic, "--ready", str(ready)]
        )
        node = None
        try:
            deadline = time.monotonic() + 10
            while not ready.exists():
                if publisher.poll() is not None:
                    raise RuntimeError("FAIL: publisher exited before publishing")
                if time.monotonic() >= deadline:
                    raise RuntimeError("FAIL: publisher startup timeout")
                time.sleep(0.05)
            rclpy.init()
            node = rclpy.create_node("verification_consumer")
            received = []
            subscription = node.create_subscription(
                NavigationStatus, topic, received.append, qos()
            )
            deadline = time.monotonic() + 10
            while not received:
                if publisher.poll() is not None:
                    raise RuntimeError("FAIL: publisher exited before receipt")
                if time.monotonic() >= deadline:
                    raise RuntimeError("FAIL: consumer receive timeout")
                rclpy.spin_once(node, timeout_sec=0.1)
            check_values(received[0])
            node.destroy_subscription(subscription)
            print("PASS: late consumer received and validated retained navigation message")
            return 0
        finally:
            if node is not None:
                node.destroy_node()
                rclpy.shutdown()
            publisher.terminate()
            try:
                publisher.wait(timeout=3)
            except subprocess.TimeoutExpired:
                publisher.kill()
                publisher.wait()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-prefix")
    parser.add_argument("--publish")
    parser.add_argument("--ready")
    args = parser.parse_args()
    if args.publish:
        publish(args.publish, args.ready)
        return 0
    if args.expected_prefix is None:
        parser.error("--expected-prefix is required for the consumer")
    if Path(get_package_prefix("openamr_nav_msgs")).resolve() != Path(args.expected_prefix).resolve():
        raise RuntimeError("FAIL: consumer resolved an unexpected interface install")
    return consume()


if __name__ == "__main__":
    sys.exit(main())
