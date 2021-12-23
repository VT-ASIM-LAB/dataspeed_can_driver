Dataspeed Drive-by-Wire Kit CAN Driver for CARMA
================================================

This is a fork of the [dbw_mkz_ros](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/src/master/) package that is used for connecting to and configuring the [Dataspeed Drive-by-Wire Kit](https://www.dataspeedinc.com/adas-by-wire-system/) for Lincoln MKZ / Ford Fusion vehicles. This fork has been modified to allow for building a Docker image that can serve as a CAN driver for the [CARMA Platform](https://github.com/usdot-fhwa-stol/carma-platform).

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
</include>
```

ROS API (stable)
----------------

### dbw_mkz_can

#### Nodes
* `can_node`
* `vehicle/dbw_node`

#### Published Topics
* `can_node/can_err [can_msgs/Frame]`: publishes error messages read from the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).
* `can_node/can_rx [can_msgs/Frame]`: publishes CAN messages read from the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus) (772 Hz).
* `can_node/version [std_msgs/String]`: publishes the Dataspeed CAN USB Driver version.
* `vehicle/antilock_brakes_active [std_msgs/Bool]`: publishes whether the vehicle's anti-lock brake system (ABS) is active (50 Hz).
* `vehicle/brake_feedback [automotive_platform_msgs/BrakeFeedback]`: publishes the current brake pedal position (50 Hz).
* `vehicle/brake_info_report [dbw_mkz_msgs/BrakeInfoReport]`: publishes braking-related data including information on wheel torques, vehicle acceleration, brake pedal quality factor, hill start assist system, anti-lock braking system (ABS), stability control system, traction control system (TCS), and parking brake (50 Hz).
* `vehicle/brake_report [dbw_mkz_msgs/BrakeReport]`: publishes braking data including information on brake pedal position, braking torque, braking deceleration, and braking status (50 Hz).
* `vehicle/dbw_enable [std_msgs/Bool]`: publishes whether the Drive-by-Wire system has been enabled.
* `vehicle/discovery`: publishes the CARMA [DriverStatus](https://github.com/usdot-fhwa-stol/carma-msgs/blob/develop/cav_msgs/msg/DriverStatus.msg) message.

#### Subscribed Topics
* `vehicle/can_tx [can_msgs/Frame]`: `can_node` subscribes to this topic to receive commands that should be published to the vehicle [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).

#### Services
* ``

#### Parameters
* `can_node/bitrate`: bit rate of the [CAN bus](https://en.wikipedia.org/wiki/CAN_bus).
* `can_node/mask_0`: [CAN bus](https://en.wikipedia.org/wiki/CAN_bus) filter mask.
* `can_node/match_0`: [CAN bus](https://en.wikipedia.org/wiki/CAN_bus) filter match.

Examples
--------

See the `dbw.launch` file in the `dbw_mkz_can/launch` directory that is used to launch the Drive-by-Wire Kit.

Original Dataspeed ADAS Development Vehicle Kit Documentation
=============================================================
![rviz screenshot](https://bytebucket.org/DataspeedInc/dbw_mkz_ros/raw/d74e90d89c4e3da56d4c9e008d5feda8cff2447d/img/mkz_rviz.png)

Documentation and firmware updates
----------------------------------
The latest release can be found on the [downloads](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/downloads) page

ROS
---
If using ROS, setup your workspace and get started with the joystick demo [here](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/src/d74e90d89c4e3da56d4c9e008d5feda8cff2447d/ROS_SETUP.md).  
Get started early with recorded data [here](https://bitbucket.org/DataspeedInc/dbw_mkz_ros/src/d74e90d89c4e3da56d4c9e008d5feda8cff2447d/ROS_BAGS.md).  
