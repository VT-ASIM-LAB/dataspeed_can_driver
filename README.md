Dataspeed Drive-by-Wire Kit CAN Driver for CARMA
================================================

This is a fork of the [dbw_mkz_ros](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/src/master/) package that is used for connecting to and configuring the [Dataspeed Drive-by-Wire Kit](https://www.dataspeedinc.com/adas-by-wire-system/) for Lincoln MKZ / Ford Fusion vehicles. It may also work for other vehicles compatible with the [Dataspeed Drive-by-Wire Kit](https://www.dataspeedinc.com/adas-by-wire-system/), though this is not guaranteed. This fork has been modified to allow for building a Docker image that can serve as a CAN driver for the [CARMA Platform](https://github.com/usdot-fhwa-stol/carma-platform).

Ubuntu 20.04 Installation
-------------------------
Assuming the CARMA Platform is installed at `~/carma_ws/src`,
```
cd ~/carma_ws/src
git clone https://github.com/VT-ASIM-LAB/dataspeed_can_driver.git
cd dataspeed_can_driver/docker
sudo ./build-image.sh -d
```
After the Docker image is successfully built, connect the Drive-by-Wire Kit USB cable to your device and run `lsusb` in the terminal to determine which bus and device number it has been assigned to. Assuming here that it is Device 007 on Bus 001, add the following lines to the appropriate `docker-compose.yml` file in the `carma-config` directory, and make sure that the current user (and not `root`) is the owner of `/dev/bus/usb/001/007`.
```
dataspeed-can-driver:
  image: usdotfhwastoldev/carma-dataspeed-can-driver:develop
  container_name: dataspeed-can-driver
  network_mode: host
  privileged: true
  devices:
    - /dev/bus/usb/001/007:/dev/bus/usb/001/007
  volumes_from:
    - container:carma-config:ro
  environment:
    - ROS_IP=127.0.0.1
  volumes:
    - /opt/carma/logs:/opt/carma/logs
    - /opt/carma/.ros:/home/carma/.ros
    - /opt/carma/vehicle/calibration:/opt/carma/vehicle/calibration
  command: bash -c '. ./devel/setup.bash && export ROS_NAMESPACE=$${CARMA_INTR_NS} && wait-for-it.sh localhost:11311 -- roslaunch /opt/carma/vehicle/config/drivers.launch drivers:=dataspeed_can'
```
Finally, add the following lines to the `drivers.launch` file in the same directory as `docker-compose.yml`.
```
<include if="$(arg dataspeed_can)" file="$(find dbw_mkz_can)/launch/dbw.launch">
  <arg name="frame_id" value="base_link"/>
  <arg name="load_urdf" value="false"/>
</include>
```

ROS API
-------

### dbw_mkz_can

#### Nodes
* `can_node`
* `vehicle/dbw_node`

#### Published Topics
Publication frequencies are provided for a Dataspeed Drive-by-Wire Kit installed on a 2017 Ford Fusion Hybrid SE.
* `can_node/can_err [can_msgs/Frame]`: publishes error messages received from the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).
* `can_node/can_rx [can_msgs/Frame]`: publishes CAN messages received from the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus) (772 Hz).
* `can_node/version [std_msgs/String]`: publishes the Dataspeed CAN USB Driver version.
* `vehicle/can_tx [can_msgs/Frame]`: publishes commands intended for the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).
* `vehicle/antilock_brakes_active [std_msgs/Bool]`: publishes True if the vehicle's [anti-lock braking system (ABS)](https://en.wikipedia.org/wiki/Anti-lock_braking_system) is active (50 Hz), False otherwise.
* `vehicle/brake_feedback [automotive_platform_msgs/BrakeFeedback]`: publishes the current brake pedal position (50 Hz).
* `vehicle/brake_info_report [dbw_mkz_msgs/BrakeInfoReport]`: publishes braking-related information including wheel torques, vehicle acceleration, brake pedal quality factor, and status of the [hill start assist system](https://mycardoeswhat.org/safety-features/hill-start-assist/), [anti-lock braking system (ABS)](https://en.wikipedia.org/wiki/Anti-lock_braking_system), [electronic stability control system (ESC)](https://en.wikipedia.org/wiki/Electronic_stability_control), [traction control system (TCS)](https://en.wikipedia.org/wiki/Traction_control_system), and parking brake (50 Hz).
* `vehicle/brake_report [dbw_mkz_msgs/BrakeReport]`: publishes braking information including brake pedal position, braking torque, braking deceleration, and braking status (50 Hz).
* `vehicle/dbw_enabled [std_msgs/Bool]`: publishes True if the Drive-by-Wire system has been enabled, False otherwise.
* `vehicle/driver_assist_report [dbw_mkz_msgs/DriverAssistReport]`: publishes information pertaining to advanced driver assistant systems (ADAS), including whether any such systems ([forward collision warning (FCW)](https://www.kbb.com/car-advice/how-does-forward-collision-warning-work/), [automatic emergency braking (AEB)](https://www.jdpower.com/cars/shopping-guides/what-is-automatic-emergency-braking), and [adaptive cruise control (ACC)](https://en.wikipedia.org/wiki/Adaptive_cruise_control)) are enabled or active, as well as vehicle deceleration.
* `vehicle/fuel_level_report [dbw_mkz_msgs/FuelLevelReport]`: publishes vehicle fuel level and battery voltage data (10 Hz).
* `vehicle/gear_report [dbw_mkz_msgs/GearReport]`: publishes gear data including gear status and current gear enumeration (20 Hz).
* `vehicle/gps/fix [sensor_msgs/NavSatFix]`: publishes the Navigation Satellite fix for any [Global Navigation Satellite System (GNSS)](https://en.wikipedia.org/wiki/Satellite_navigation#Global_navigation_satellite_systems), specified using the [WGS84](https://en.wikipedia.org/wiki/World_Geodetic_System#1984_version) reference ellipsoid (1 Hz).
* `vehicle/gps/time [sensor_msgs/TimeReference]`: publishes time reported by the [Global Navigation Satellite System (GNSS)](https://en.wikipedia.org/wiki/Satellite_navigation#Global_navigation_satellite_systems) in use (1 Hz).
* `vehicle/gps/vel [geometry_msgs/TwistStamped]`: publishes linear and angular velocity (twist) measured by the [Global Navigation Satellite System (GNSS)](https://en.wikipedia.org/wiki/Satellite_navigation#Global_navigation_satellite_systems) in use (1 Hz).
* `vehicle/imu/data_raw [sensor_msgs/Imu]`: publishes data from the vehicle's IMU (100 Hz).
* `vehicle/misc_1_report [dbw_mkz_msgs/Misc1Report]`: publishes miscellaneous information obtained from the [CAN bus](https://en.wikipedia.org/wiki/CAN_bus), including the status of turn signals, high beam, windshield wipers, steering wheel buttons, doors, passenger seat, and seat belt, as well as ambient light sensor and outside air temperature measurements (20 Hz).
* `vehicle/parking_brake [std_msgs/Bool]`: publishes True if the vehicle's parking brake is active, False otherwise (50 Hz).
* `vehicle/sonar_cloud [sensor_msgs/PointCloud2]`: publishes a point cloud created from the observations of the vehicle's ultrasound sensors.
* `vehicle/steering_feedback [automotive_platform_msgs/SteeringFeedback]`: publishes the current steering wheel angle (100 Hz).
* `vehicle/steering_report [dbw_mkz_msgs/SteeringReport]`: publishes steering information including steering wheel angle, steering torque, and vehicle speed (100 Hz).
* `vehicle/stability_ctrl_active [std_msgs/Bool]`: publishes True if the vehicle's [electronic stability control system (ESC)](https://en.wikipedia.org/wiki/Electronic_stability_control) is active, False otherwise (50 Hz).
* `vehicle/stability_ctrl_enabled [std_msgs/Bool]`: publishes True if the vehicle's [electronic stability control system (ESC)](https://en.wikipedia.org/wiki/Electronic_stability_control) is enabled, false otherwise (50 Hz).
* `vehicle/surround_report [dbw_mkz_msgs/SurroundReport]`: publishes data obtained from the vehicle's ultrasound sensors as well as [cross traffic alert (CTA)](https://www.autotrader.com/car-tech/what-is-cross-traffic-alert-and-how-does-it-work) and [blind spot information system (BLIS)](https://www.jdpower.com/cars/shopping-guides/what-is-a-blind-spot-monitor) data.
* `vehicle/throttle_feedback [automotive_platform_msgs/ThrottleFeedback]`: publishes the current throttle pedal position (100 Hz).
* `vehicle/throttle_info_report [dbw_mkz_msgs/ThrottleInfoReport]`: publishes throttle-related information including throttle pedal position and rate of change, engine rpm, gear number, ignition status, and battery current (100 Hz).
* `vehicle/throttle_report [dbw_mkz_msgs/ThrottleReport]`: publishes throttle pedal data (50 Hz).
* `vehicle/tire_pressure_report [dbw_mkz_msgs/TirePressureReport]`: publishes tire pressure data (2 Hz).
* `vehicle/traction_ctrl_active [std_msgs/Bool]`: publishes True if the vehicle's [traction control system (TCS)](https://en.wikipedia.org/wiki/Traction_control_system) is active, False otherwise (50 Hz).
* `vehicle/traction_ctrl_enabled [std_msgs/Bool]`: publishes True if the vehicle's [traction control system (TCS)](https://en.wikipedia.org/wiki/Traction_control_system) is enabled, False otherwise (50 Hz).
* `vehicle/transmission_state [j2735_msgs/TransmissionState]`: publishes the current state of the vehicle's transmission (20 Hz).
* `vehicle/twist [geometry_msgs/TwistStamped]`: publishes the absolute value of the vehicle's current twist (velocity in free space broken down into its linear and angular parts) (100 Hz).
* `vehicle/signed_twist [geometry_msgs/TwistStamped]`: publishes the vehicle's current twist (velocity in free space broken down into its linear and angular parts) with correct signs (i.e. negative linear velocity when driving in reverse) (100 Hz).
* `vehicle/vin [std_msgs/String]`: publishes the [vehicle identification number (VIN)](https://en.wikipedia.org/wiki/Vehicle_identification_number).
* `vehicle/wheel_position_report [dbw_mkz_msgs/WheelPositionReport]`: publishes individual wheel positions (50 Hz).
* `vehicle/wheel_speed_report [dbw_mkz_msgs/WheelSpeedReport]`: publishes individual wheel speeds (100 Hz).
* `vehicle/discovery`: publishes the CARMA [DriverStatus](https://github.com/usdot-fhwa-stol/carma-msgs/blob/develop/cav_msgs/msg/DriverStatus.msg) message (1.25 Hz).

#### Subscribed Topics
* `vehicle/can_tx [can_msgs/Frame]`: `can_node` subscribes to this topic to receive commands that should be published to the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).
* `can_node/can_rx [can_msgs/Frame]`: `vehicle/dbw_node` subscribes to this topic.
* `vehicle/enable [std_msgs/Empty]`: `vehicle/dbw_node` subscribes to this topic to receive the command for enabling the Drive-by-Wire system.
* `vehicle/disable [std_msgs/Empty]`: `vehicle/dbw_node` subscribes to this topic to receive the command for disabling the Drive-by-Wire system.
* `vehicle/brake_cmd [dbw_mkz_msgs/BrakeCmd]`: `vehicle/dbw_node` subscribes to this topic to receive the braking command intended for the Drive-by-Wire system.
* `vehicle/gear_cmd [dbw_mkz_msgs/GearCmd]`: `vehicle/dbw_node` subscribes to this topic to receive the gear change command intended for the Drive-by-Wire system.
* `vehicle/steering_cmd [dbw_mkz_msgs/SteeringCmd]`: `vehicle/dbw_node` subscribes to this topic to receive the steering command intended for the Drive-by-Wire system.
* `vehicle/throttle_cmd [dbw_mkz_msgs/ThrottleCmd]`: `vehicle/dbw_node` subscribes to this topic to receive the throttle command intended for the Drive-by-Wire system.
* `vehicle/turn_signal_cmd [dbw_mkz_msgs/TurnSignalCmd]`: `vehicle/dbw_node` subscribes to this topic to receive the turn signal command intended for the Drive-by-Wire system.

#### Services
N/A

#### Parameters
* `can_node/bitrate`: bit rate of the [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).
* `can_node/mask_0`: [CAN bus](https://en.wikipedia.org/wiki/CAN_bus) filter mask of a mask/match filter pair.
* `can_node/match_0`: [CAN bus](https://en.wikipedia.org/wiki/CAN_bus) filter match of a mask/match filter pair.
* `vehicle/dbw_node/ackermann_track`: distance between the left and right tires in [Ackermann steering geometry](https://en.wikipedia.org/wiki/Ackermann_steering_geometry).
* `vehicle/dbw_node/ackermann_wheelbase`: distance between the front and rear tires in [Ackermann steering geometry](https://en.wikipedia.org/wiki/Ackermann_steering_geometry).
* `vehicle/dbw_node/buttons`: enable/disable buttons.
* `vehicle/dbw_node/frame_id`: [TF2](http://www.ros.org/wiki/tf2) frame ID of CAN messages.
* `vehicle/dbw_node/joint_states`: enable/disable publishing joint states.
* `vehicle/dbw_node/pedal_luts`: pedal look-up tables.
* `vehicle/dbw_node/steering_ratio`: steering ratio in [Ackermann steering geometry](https://en.wikipedia.org/wiki/Ackermann_steering_geometry).
* `vehicle/dbw_node/warn_cmds`: warn on received commands.

Examples
--------

See the `dbw.launch` file in the `dbw_mkz_can/launch` directory that is used to launch the Drive-by-Wire Kit.

Original Dataspeed ADAS Development Vehicle Kit Documentation
=============================================================
![rviz screenshot](https://bytebucket.org/DataspeedInc/dbw_mkz_ros/raw/d74e90d89c4e3da56d4c9e008d5feda8cff2447d/img/mkz_rviz.png)

Documentation and firmware updates
----------------------------------
The latest release can be found on the [downloads](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/downloads) page.

ROS
---
If using ROS, setup your workspace and get started with the joystick demo [here](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/src/d74e90d89c4e3da56d4c9e008d5feda8cff2447d/ROS_SETUP.md).  
Get started early with recorded data [here](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/src/d74e90d89c4e3da56d4c9e008d5feda8cff2447d/ROS_BAGS.md).  
