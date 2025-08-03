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

RUN apt update && \
	apt install -y meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev libxkbcommon-x11-dev \
		libxkbregistry-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev \
		libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev libtomlplusplus3 \
		git libpugixml-dev \
		libwayland-dev wayland-protocols libgbm-dev libdisplay-info-dev hwdata libzip-dev libcairo2-dev librsvg2-dev libtomlplusplus-dev \
		libjxl-dev libmagic-dev libxcursor-dev libre2-dev libxcb-errors-dev \
		libsdbus-c++-dev libpam0g-dev libaudit-dev libglvnd-dev libglvnd-core-dev file \
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

RUN git clone https://github.com/hyprwm/hyprwayland-scanner && \
	cd hyprwayland-scanner && git checkout v0.4.5 && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr -B build && \
	cmake --build build -j `nproc` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprwayland-scanner_v0.4.5.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprutils.git && \
	cd hyprutils && git checkout v0.8.2 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprutils_v0.8.1.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/aquamarine && \
	cd aquamarine && git checkout v0.9.2 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/aquamarine_v0.9.2.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprlang && \
	cd hyprlang && git checkout v0.6.4 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target hyprlang -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install ./build && \
	tar -cvf /opt/hyprland/archives/hyprlang_v0.6.3.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprcursor && \
	cd hyprcursor && git checkout v0.1.13 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprcursor_v0.1.12.tar.gz -T build/install_manifest.txt

RUN	git clone https://github.com/hyprwm/hyprgraphics && \
	cd hyprgraphics/ && git checkout v0.1.5 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprgraphics_v0.1.5.tar.gz -T build/install_manifest.txt

RUN git clone --recursive https://github.com/hyprwm/Hyprland && \
	cd Hyprland && git checkout v0.50.1 && \
	make all && make install && \
	tar -cvf /opt/hyprland/archives/Hyprland_v0.50.1.tar.gz -T build/install_manifest.txt

RUN cd /opt/hyprland/Hyprland/subprojects/hyprland-protocols && \
	meson setup build && \
	ninja -C build && \
	ninja -C build install && \
    echo "Install log:" &&  cat build/meson-logs/install-log.txt && echo "----" && \
    grep -v '^#' build/meson-logs/install-log.txt > build/install_manifest.txt && \
    echo "Install Manifest:" &&  cat build/install_manifest.txt && echo "----" && \
	tar -cvf /opt/hyprland/archives/hyprland-protocols_v0.6.4-rec.tar.gz -T build/install_manifest.txt

# Hyprland Utils

RUN git clone https://github.com/hyprwm/hyprlock && \
	cd hyprlock && git checkout v0.9.1 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build && \
	cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprlock_v0.9.0.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprpaper && \
	cd hyprpaper && git checkout v0.7.5 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
	cmake --build ./build --config Release --target hyprpaper -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install ./build && \
	tar -cvf /opt/hyprland/archives/hyprpaper_v0.7.5.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hypridle && \
	cd hypridle && git checkout v0.1.6 && \
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build && \
	cmake --build ./build --config Release --target hypridle -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF` && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hypridle_v0.1.6.tar.gz -T build/install_manifest.txt

RUN git clone --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland && \
	cd xdg-desktop-portal-hyprland && git checkout v1.3.10 && \
	cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build && \
	cmake --build build && \
	cmake --install build && \
	tar -cvf /opt/hyprland/archives/xdg-desktop-portal-hyprland_v1.3.10.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprland-qtutils && \
    cd hyprland-qtutils && git checkout v0.1.4 && \
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
   	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprland-qtutils_v0.1.4.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprland-qt-support && \
    cd hyprland-qtutils && git checkout v0.1.0 && \
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
   	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprland-qt-support_v0.1.0.tar.gz -T build/install_manifest.txt

RUN git clone https://github.com/hyprwm/hyprpolkitagent && \
    cd hyprpolkitagent && git checkout v0.1.3 && \
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build && \
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF` && \
   	cmake --install build && \
	tar -cvf /opt/hyprland/archives/hyprpolkitagent_v0.1.2.tar.gz -T build/install_manifest.txt

ENTRYPOINT ["/usr/bin/bash"]
