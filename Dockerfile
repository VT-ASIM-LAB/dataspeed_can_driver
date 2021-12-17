ARG ROS_DISTRO=noetic

FROM ros:${ROS_DISTRO}-ros-core AS build-env
ENV DEBIAN_FRONTEND=noninteractive \
    BUILD_HOME=/var/lib/build \
    DS_SDK_PATH=/opt/dataspeed_can

RUN set -xue \
# Kinetic and melodic have python3 packages but they seem to conflict
&& [ $ROS_DISTRO = "noetic" ] && PY=python3 || PY=python \
# Turn off installing extra packages globally to slim down rosdep install
&& echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01norecommend \
&& apt-get update \
&& apt-get install -y \
 build-essential cmake \
 fakeroot dpkg-dev debhelper git \
 $PY-rosdep $PY-rospkg $PY-bloom

# Set up non-root build user
ARG BUILD_UID=1000
ARG BUILD_GID=${BUILD_UID}

RUN set -xe \
&& groupadd -o -g ${BUILD_GID} build \
&& useradd -o -u ${BUILD_UID} -d ${BUILD_HOME} -rm -s /bin/bash -g build build

# Install build dependencies using rosdep
COPY --chown=build:build dbw_mkz_description/package.xml ${DS_SDK_PATH}/dbw_mkz_description/package.xml
COPY --chown=build:build dbw_mkz_msgs/package.xml ${DS_SDK_PATH}/dbw_mkz_msgs/package.xml
COPY --chown=build:build cav_msgs/package.xml ${DS_SDK_PATH}/cav_msgs/package.xml
COPY --chown=build:build j2735_msgs/package.xml ${DS_SDK_PATH}/j2735_msgs/package.xml

RUN set -xe \
&& apt-get update \
&& rosdep init \
&& rosdep update --rosdistro=${ROS_DISTRO} \
&& rosdep install -y --from-paths ${DS_SDK_PATH}

RUN apt-get install -y ros-${ROS_DISTRO}-dataspeed-can-msg-filters

RUN sudo git clone --depth 1 https://github.com/vishnubob/wait-for-it.git ~/.base-image/wait-for-it && \
    sudo mv ~/.base-image/wait-for-it/wait-for-it.sh /usr/bin

# Set up build environment
COPY --chown=build:build dbw_mkz_can ${DS_SDK_PATH}/dbw_mkz_can
COPY --chown=build:build dbw_mkz_description ${DS_SDK_PATH}/dbw_mkz_description
COPY --chown=build:build dbw_mkz_msgs ${DS_SDK_PATH}/dbw_mkz_msgs
COPY --chown=build:build cav_msgs ${DS_SDK_PATH}/cav_msgs
COPY --chown=build:build j2735_msgs ${DS_SDK_PATH}/j2735_msgs

USER build:build
WORKDIR ${BUILD_HOME}

RUN set -xe \
&& mkdir src \
&& ln -s ${DS_SDK_PATH} ./src

FROM build-env

RUN /opt/ros/${ROS_DISTRO}/env.sh catkin_make -DCMAKE_BUILD_TYPE=Release

# Entrypoint for running Dataspeed CAN ROS:
CMD ["bash", "-c", "set -e \
&& . ./devel/setup.bash \
&& roslaunch dbw_mkz_can dbw.launch \"$@\" \
", "ros-entrypoint"]
