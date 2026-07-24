#!/bin/bash
# apply_patch.sh - 安装 HONOR MagicBook 14 2026 触摸板补丁
# 适用于 Fedora / dracut 系统

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BACKUP_DIR="/root/acpi_backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "HONOR MagicBook 14 2026 Touchpad Fix"
echo "=========================================="
echo

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "错误: 请使用 sudo 运行此脚本"
   exit 1
fi

# 检查补丁文件
if [[ ! -f "$REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml" ]]; then
    echo "错误: 补丁文件不存在: $REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml"
    exit 1
fi

# 创建备份目录
echo "[1/6] 创建备份..."
mkdir -p "$BACKUP_DIR"

# 备份原始文件
if [[ -f /boot/acpi_override.cpio ]]; then
    cp /boot/acpi_override.cpio "$BACKUP_DIR/"
    echo "  备份: /boot/acpi_override.cpio"
fi

if [[ -d /boot/acpi_override ]]; then
    cp -r /boot/acpi_override "$BACKUP_DIR/"
    echo "  备份: /boot/acpi_override/"
fi

echo "  备份保存到: $BACKUP_DIR"
echo

# 获取内核版本
KERNEL_VERSION=$(uname -r)
echo "[2/6] 内核版本: $KERNEL_VERSION"

# 获取 BLS entry
BLS_ENTRY=$(ls /boot/loader/entries/*-${KERNEL_VERSION}.conf 2>/dev/null | head -1)

if [[ -z "$BLS_ENTRY" ]]; then
    echo "警告: 未找到 BLS 条目，尝试查找其他条目..."
    BLS_ENTRY=$(ls /boot/loader/entries/*.conf 2>/dev/null | head -1)
fi

if [[ -n "$BLS_ENTRY" ]]; then
    echo "  找到 BLS 条目: $BLS_ENTRY"
    BLS_BASENAME=$(basename "$BLS_ENTRY")
    BLS_BACKUP="$BACKUP_DIR/$BLS_BASENAME"
    cp "$BLS_ENTRY" "$BLS_BACKUP"
    echo "  备份: $BLS_ENTRY -> $BLS_BACKUP"
else
    echo "警告: 未找到 BLS 条目"
fi
echo

# 安装补丁文件
echo "[3/6] 安装补丁文件..."

# 创建 /boot/acpi_override 目录
mkdir -p /boot/acpi_override
cp "$REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml" /boot/acpi_override/SSDT29.aml
echo "  安装: /boot/acpi_override/SSDT29.aml"

# 复制到其他位置
cp "$REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml" /boot/SSDT-HONOR-I2C_DEVT.aml
echo "  安装: /boot/SSDT-HONOR-I2C_DEVT.aml"
echo

# 创建 early CPIO
echo "[4/6] 创建 Early CPIO..."

# 创建临时目录
TEMP_DIR=$(mktemp -d)
ACPI_CPIO_DIR="$TEMP_DIR/kernel/firmware/acpi"
mkdir -p "$ACPI_CPIO_DIR"

# 复制补丁文件
cp "$REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml" "$ACPI_CPIO_DIR/SSDT29.aml"

# 创建 CPIO
cd "$TEMP_DIR"
find . | cpio -o -H newc > /boot/acpi_override.cpio
cd /

# 清理临时目录
rm -rf "$TEMP_DIR"

# 设置权限
chmod 644 /boot/acpi_override.cpio

echo "  创建: /boot/acpi_override.cpio"
echo

# 配置 GRUB/BLS
echo "[5/6] 配置引导加载器..."

if [[ -n "$BLS_ENTRY" ]] && [[ -f "$BLS_ENTRY" ]]; then
    # 检查是否已经有 early initrd
    if grep -q "initrd.*acpi_override.cpio" "$BLS_ENTRY"; then
        echo "  BLS 已配置使用 acpi_override.cpio"
    else
        # 修改 initrd 行
        sed -i 's|initrd /acpi_override.cpio /initramfs|initrd /acpi_override.cpio /initramfs|' "$BLS_ENTRY" 2>/dev/null || true
        sed -i 's|initrd /initramfs|initrd /acpi_override.cpio /initramfs|' "$BLS_ENTRY" 2>/dev/null || true
        echo "  已更新 BLS: $BLS_ENTRY"
    fi
fi
echo

# 完成
echo "[6/6] 完成！"
echo
echo "=========================================="
echo "安装完成！"
echo
echo "请重启系统:"
echo "  sudo reboot"
echo
echo "重启后验证:"
echo "  sudo dmesg | grep -iE 'Table Upgrade|SSDT.*I2C_DEVT'"
echo "  xinput list"
echo
echo "备份已保存到: $BACKUP_DIR"
echo "=========================================="
