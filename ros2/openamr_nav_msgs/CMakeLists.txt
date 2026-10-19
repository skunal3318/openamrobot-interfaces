cmake_minimum_required(VERSION 3.8)
project(openamr_nav_msgs)

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)

find_package(builtin_interfaces REQUIRED)
find_package(std_msgs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/NavigationStatus.msg"
  "msg/SiteConfigStatus.msg"
  "msg/NavStackStatus.msg"
  "msg/LocalizationStatus.msg"
  "msg/SensorStatus.msg"
  "msg/NavTaskStatus.msg"
  "msg/RecoveryStatus.msg"
  "msg/ProtectionStatus.msg"
  "msg/MotionSourceCoverage.msg"
  "msg/ActiveConstraint.msg"
  "msg/DockingStatus.msg"
  "msg/ParkingStatus.msg"
  DEPENDENCIES
    builtin_interfaces
    std_msgs
)

ament_export_dependencies(rosidl_default_runtime)
ament_package()
