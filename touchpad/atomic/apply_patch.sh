#!/bin/bash
# apply_patch.sh (Atomic Version) - 安装 HONOR MagicBook 14 2026 触摸板补丁
# 适用于 Fedora Atomic (Silverblue / Kinoite / Sericea / bootc) 等基于 rpm-ostree 的系统
#
# 原理：
#   将 ACPI SSDT29 AML 表放入 /etc/acpi/local/，通过 Dracut 配置 (acpi_override="yes")
#   并开启 rpm-ostree initramfs 本地打包，使 ACPI 补丁打包进 initramfs 的 Early CPIO。
#   该方式跨系统更新自动保持生效，无需修改 BLS 引导配置。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/../patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml"

echo "=========================================="
echo "HONOR MagicBook 14 2026 Touchpad Fix (Fedora Atomic)"
echo "=========================================="
echo

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "错误: 请使用 sudo 运行此脚本"
   exit 1
fi

# 检查是否存在 rpm-ostree
if ! command -v rpm-ostree >/dev/null 2>&1; then
    echo "错误: 未检测到 rpm-ostree 命令。此脚本仅适用于 Fedora Atomic / Silverblue 等系统。"
    echo "如果是传统 Fedora 系统，请使用 touchpad/apply_patch.sh"
    exit 1
fi

# 检查补丁文件是否存在
if [[ ! -f "$PATCH_FILE" ]]; then
    echo "错误: 未找到补丁文件: $PATCH_FILE"
    exit 1
fi

# 检查是否已安装
INSTALLED=0
if [[ -f /etc/acpi/local/SSDT29.aml ]] && [[ -f /etc/dracut.conf.d/acpi_override.conf ]]; then
    INSTALLED=1
fi

if [[ $INSTALLED -eq 1 ]]; then
    echo "[状态] 检测到触摸板 ACPI 补丁已配置在系统中。"
    echo
    read -p "是否要移除触摸板补丁配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[1/2] 清理配置与补丁文件..."
        rm -f /etc/acpi/local/SSDT29.aml
        rm -f /etc/dracut.conf.d/acpi_override.conf
        
        echo "[2/2] 禁用 rpm-ostree 本地 initramfs 重构..."
        rpm-ostree initramfs --disable || true

        echo
        echo "=========================================="
        echo "触摸板补丁配置已清理！"
        echo "请重启系统生效: sudo reboot"
        echo "=========================================="
    else
        echo "取消操作"
        exit 0
    fi
else
    echo "[1/3] 部署 ACPI 补丁到 /etc/acpi/local/..."
    mkdir -p /etc/acpi/local
    cp "$PATCH_FILE" /etc/acpi/local/SSDT29.aml
    chmod 644 /etc/acpi/local/SSDT29.aml
    echo "  已复制: /etc/acpi/local/SSDT29.aml"

    echo "[2/3] 配置 Dracut ACPI Override ( /etc/dracut.conf.d/acpi_override.conf )..."
    mkdir -p /etc/dracut.conf.d
    cat <<'EOF' > /etc/dracut.conf.d/acpi_override.conf
# HONOR MagicBook 14 2026 Touchpad ACPI Patch
acpi_override="yes"
acpi_table_dir="/etc/acpi/local"
EOF
    echo "  已创建 Dracut 配置文件"

    echo "[3/3] 开启 rpm-ostree 本地 initramfs 重构..."
    echo "  正在调用 rpm-ostree initramfs --enable ..."
    rpm-ostree initramfs --enable

    echo
    echo "=========================================="
    echo "安装完成！"
    echo
    echo "请重启系统:"
    echo "  sudo reboot"
    echo
    echo "重启后运行以下命令验证 ACPI 表是否成功挂载:"
    echo "  sudo dmesg | grep -iE 'Table Upgrade|SSDT.*I2C_DEVT'"
    echo "=========================================="
fi
