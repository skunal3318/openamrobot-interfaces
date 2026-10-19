#include <iostream>

#include "openamr_nav_msgs/msg/navigation_status.hpp"
#include "openamr_nav_msgs/msg/site_config_status.hpp"
#include "openamr_ui_msgs/action/move_base.hpp"
#include "openamr_ui_msgs/msg/array_pose_stamped_with_covariance.hpp"
#include "rosidl_typesupport_cpp/message_type_support.hpp"

int main()
{
  using NavigationStatus = openamr_nav_msgs::msg::NavigationStatus;
  using SiteConfigStatus = openamr_nav_msgs::msg::SiteConfigStatus;
  using Poses = openamr_ui_msgs::msg::ArrayPoseStampedWithCovariance;
  using Goal = openamr_ui_msgs::action::MoveBase::Goal;

  NavigationStatus status;
  status.contract_version = NavigationStatus::CONTRACT_VERSION;
  // CONTRACT_VERSION 2: site_config is part of NavigationStatus itself, not just
  // independently constructible — exercise it through the parent field, the way a
  // real consumer would actually read it off a received message.
  status.site_config.state = SiteConfigStatus::STATE_UNKNOWN;
  status.site_config.floor_coverage = SiteConfigStatus::COVERAGE_UNKNOWN;
  Poses poses;
  poses.poses.resize(1);
  Goal goal;
  goal.target.header.frame_id = "map";

  // Calling exported functions verifies headers, linking, and runtime loading.
  if (!rosidl_typesupport_cpp::get_message_type_support_handle<NavigationStatus>() ||
    !rosidl_typesupport_cpp::get_message_type_support_handle<SiteConfigStatus>() ||
    !rosidl_typesupport_cpp::get_message_type_support_handle<Poses>() ||
    !rosidl_typesupport_cpp::get_message_type_support_handle<Goal>())
  {
    std::cerr << "FAIL: installed C++ type support unavailable\n";
    return 1;
  }
  std::cout << "PASS: installed navigation and UI interfaces; contract version "
            << status.contract_version << ", site_config.state "
            << static_cast<int>(status.site_config.state) << '\n';
  return 0;
}
