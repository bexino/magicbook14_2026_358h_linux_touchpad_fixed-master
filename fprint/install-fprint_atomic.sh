#!/bin/bash

# 添加设备 ID 并编译安装 (针对 Fedora Atomic / Silverblue / Kinoite 等系统的版本)
cd ~
if [ -d "libfprint" ]; then
    rm -rf libfprint
fi
git clone https://gitlab.freedesktop.org/libfprint/libfprint.git
cd libfprint

# 添加设备 ID
sed -i '/0x6984,/a\  { .vid = 0x27c6,  .pid = 0x6f94,  },' libfprint/drivers/goodixmoc/goodix.c

# 安装依赖 (Fedora Atomic 使用 rpm-ostree)
if command -v rpm-ostree &> /dev/null; then
    echo "使用 rpm-ostree 安装编译依赖..."
    sudo rpm-ostree install --apply-live --allow-inactive meson gcc glib2-devel libgusb-devel openssl-devel libgudev-devel ninja-build git fprintd fprintd-pam
else
    echo "未检测到 rpm-ostree，回退使用 dnf 安装依赖..."
    sudo dnf install -y meson gcc glib2-devel libgusb-devel openssl-devel libgudev-devel ninja-build git fprintd fprintd-pam
fi

# 编译安装 (Atomic 系统 /usr 只读，故安装至 /usr/local，udev 规则写入 /etc/udev/rules.d)
meson setup builddir --prefix=/usr/local --buildtype=release -Dudev_rules_dir=/etc/udev/rules.d
ninja -C builddir
sudo ninja -C builddir install

# 配置动态链接库查找路径
if [ ! -f /etc/ld.so.conf.d/usrlocal.conf ]; then
    echo -e "/usr/local/lib64\n/usr/local/lib" | sudo tee /etc/ld.so.conf.d/usrlocal.conf > /dev/null
fi
sudo ldconfig

# 重载 udev 规则与服务
sudo udevadm control --reload-rules && sudo udevadm trigger || true
sudo systemctl restart fprintd

echo "Done! Run: fprintd-enroll"
