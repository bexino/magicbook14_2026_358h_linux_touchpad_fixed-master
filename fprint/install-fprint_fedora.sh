#!/bin/bash

# 添加设备 ID 并编译安装
cd ~
git clone https://gitlab.freedesktop.org/libfprint/libfprint.git
cd libfprint

# 添加设备 ID
sed -i '/0x6984,/a\  { .vid = 0x27c6,  .pid = 0x6f94,  },' libfprint/drivers/goodixmoc/goodix.c

# 安装依赖
sudo dnf install -y meson gcc glib2-devel libgusb-devel openssl-devel libgudev-devel ninja-build

# 编译安装
meson setup builddir --prefix=/usr --buildtype=release
ninja -C builddir
sudo ninja -C builddir install

# 配置
sudo ldconfig
sudo systemctl restart fprintd

echo "Done! Run: fprintd-enroll"