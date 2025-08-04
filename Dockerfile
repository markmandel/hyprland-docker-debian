# Copyright 2025 Mark Mandel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


FROM debian:testing

# enable experimental for g++15
COPY ./experimental.sources /etc/apt/sources.list.d/experimental.sources
# packaging helper
COPY ./debify.sh /usr/local/bin/debify.sh
RUN chmod +x /usr/local/bin/debify.sh

RUN apt update && \
	apt install -y meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev libxkbcommon-x11-dev \
		libxkbregistry-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev \
		libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev libtomlplusplus3 \
		git libpugixml-dev \
		libwayland-dev wayland-protocols libgbm-dev libdisplay-info-dev hwdata libzip-dev libcairo2-dev librsvg2-dev libtomlplusplus-dev \
		libjxl-dev libmagic-dev libxcursor-dev libre2-dev libxcb-errors-dev \
		libsdbus-c++-dev libpam0g-dev libaudit-dev libglvnd-dev libglvnd-core-dev file rsync \
		qt6-base-dev libspa-0.2-dev libpipewire-0.3-dev \
		qt6-wayland-dev qt6-declarative-dev qt6-declarative-private-dev qt6-wayland-private-dev libspng-dev \
        libpolkit-agent-1-dev libpolkit-qt6-1-dev

# enabling gcc 15
RUN apt -t experimental install -y g++-15
RUN gcc --version && gcc-15 --version
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 100

# installing and enabling gcc 14
RUN apt install -y g++-14
RUN gcc-14 --version
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 90 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 90

# explicitly set gcc-15 and g++-15 as the default compilers
RUN update-alternatives --set gcc /usr/bin/gcc-15 \
    && update-alternatives --set g++ /usr/bin/g++-15

RUN gcc --version && gcc-15 --version && gcc-14 --version
RUN update-alternatives --get-selections

# play to do hyprland work
RUN mkdir -p /opt/hyprland/archives
WORKDIR /opt/hyprland

ARG HYPRWAYLAND_SCANNER_VERSION=v0.4.5
RUN git clone https://github.com/hyprwm/hyprwayland-scanner && \
	cd hyprwayland-scanner && git checkout ${HYPRWAYLAND_SCANNER_VERSION} && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr -B build && \
	cmake --build build -j `nproc` && \
		cmake --install build && \
	debify.sh hyprwayland-scanner ${HYPRWAYLAND_SCANNER_VERSION} build/install_manifest.txt

ARG HYPRUTILS_VERSION=v0.8.2
RUN git clone https://github.com/hyprwm/hyprutils.git && \
	cd hyprutils && git checkout ${HYPRUTILS_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	cmake --install build && \
	debify.sh hyprutils ${HYPRUTILS_VERSION} build/install_manifest.txt

ARG AQUAMARINE_VERSION=v0.9.2
RUN git clone https://github.com/hyprwm/aquamarine && \
	cd aquamarine && git checkout ${AQUAMARINE_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	debify.sh aquamarine ${AQUAMARINE_VERSION} build/install_manifest.txt

ARG HYPRLANG_VERSION=v0.6.4
RUN git clone https://github.com/hyprwm/hyprlang && \
	cd hyprlang && git checkout ${HYPRLANG_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target hyprlang -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install ./build && \
	debify.sh hyprlang ${HYPRLANG_VERSION} build/install_manifest.txt

ARG HYPRCURSOR_VERSION=v0.1.13
RUN git clone https://github.com/hyprwm/hyprcursor && \
	cd hyprcursor && git checkout ${HYPRCURSOR_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	debify.sh hyprcursor ${HYPRCURSOR_VERSION} build/install_manifest.txt

ARG HYPRGRAPHICS_VERSION=v0.1.5
RUN	git clone https://github.com/hyprwm/hyprgraphics && \
	cd hyprgraphics/ && git checkout ${HYPRGRAPHICS_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	cmake --install build && \
	debify.sh hyprgraphics ${HYPRGRAPHICS_VERSION} build/install_manifest.txt

ARG HYPRLAND_VERSION=v0.50.1
RUN git clone --recursive https://github.com/hyprwm/Hyprland && \
	cd Hyprland && git checkout ${HYPRLAND_VERSION} && \
	make all && make install && \
	debify.sh Hyprland ${HYPRLAND_VERSION} build/install_manifest.txt

ARG HYPRLAND_PROTOCOLS_VERSION=v0.6.4-rec
RUN cd /opt/hyprland/Hyprland/subprojects/hyprland-protocols && \
	meson setup build && \
	ninja -C build && \
	ninja -C build install && \
    echo "Install log:" &&  cat build/meson-logs/install-log.txt && echo "----" && \
    grep -v '^#' build/meson-logs/install-log.txt > build/install_manifest.txt && \
   	echo "Install Manifest:" &&  cat build/install_manifest.txt && echo "----" && \
	debify.sh hyprland-protocols ${HYPRLAND_PROTOCOLS_VERSION} build/install_manifest.txt

# Hyprland Utils

ARG HYPRLOCK_VERSION=v0.9.1
RUN git clone https://github.com/hyprwm/hyprlock && \
	cd hyprlock && git checkout ${HYPRLOCK_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build && \
	cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	debify.sh hyprlock ${HYPRLOCK_VERSION} build/install_manifest.txt

ARG HYPRPAPER_VERSION=v0.7.5
RUN git clone https://github.com/hyprwm/hyprpaper && \
	cd hyprpaper && git checkout ${HYPRPAPER_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target hyprpaper -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install ./build && \
	debify.sh hyprpaper ${HYPRPAPER_VERSION} build/install_manifest.txt

ARG HYPRIDLE_VERSION=v0.1.6
RUN git clone https://github.com/hyprwm/hypridle && \
	cd hypridle && git checkout ${HYPRIDLE_VERSION} && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build && \
	cmake --build ./build --config Release --target hypridle -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	debify.sh hypridle ${HYPRIDLE_VERSION} build/install_manifest.txt

ARG XDPH_VERSION=v1.3.10
RUN git clone --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland && \
	cd xdg-desktop-portal-hyprland && git checkout ${XDPH_VERSION} && \
	cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build && \
	cmake --build build && \
	cmake --install build && \
	debify.sh xdg-desktop-portal-hyprland ${XDPH_VERSION} build/install_manifest.txt

ARG HYPRLAND_QTUTILS_VERSION=v0.1.4
RUN git clone https://github.com/hyprwm/hyprland-qtutils && \
    cd hyprland-qtutils && git checkout ${HYPRLAND_QTUTILS_VERSION} && \
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	   	cmake --install build && \
	debify.sh hyprland-qtutils ${HYPRLAND_QTUTILS_VERSION} build/install_manifest.txt

ARG HYPRLAND_QT_SUPPORT_VERSION=v0.1.0
RUN git clone https://github.com/hyprwm/hyprland-qt-support && \
    cd hyprland-qtutils && git checkout ${HYPRLAND_QT_SUPPORT_VERSION} && \
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	   	cmake --install build && \
	debify.sh hyprland-qt-support ${HYPRLAND_QT_SUPPORT_VERSION} build/install_manifest.txt

ARG HYPRPOLKITAGENT_VERSION=v0.1.3
RUN git clone https://github.com/hyprwm/hyprpolkitagent && \
    cd hyprpolkitagent && git checkout ${HYPRPOLKITAGENT_VERSION} && \
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	   	cmake --install build && \
	debify.sh hyprpolkitagent ${HYPRPOLKITAGENT_VERSION} build/install_manifest.txt

ENTRYPOINT ["/usr/bin/bash"]
