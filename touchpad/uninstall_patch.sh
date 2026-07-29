#!/bin/bash
# uninstall_patch.sh - 卸载 HONOR MagicBook 14 2026 触摸板补丁

set -euo pipefail

echo "=========================================="
echo "卸载触摸板补丁"
echo "=========================================="
echo

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "错误: 请使用 sudo 运行此脚本"
   exit 1
fi

# 获取内核版本
KERNEL_VERSION=$(uname -r)

# 查找备份目录
BACKUP_DIRS=(/root/acpi_backup_*)

if [[ ${#BACKUP_DIRS[@]} -eq 0 ]] || [[ ! -d "${BACKUP_DIRS[-1]}" ]]; then
    echo "警告: 未找到备份目录"
    echo "手动恢复请:"
    echo "  1. 删除 /boot/acpi_override.cpio"
    echo "  2. 删除 /boot/acpi_override/"
    echo "  3. 编辑 /boot/loader/entries/*.conf 删除 initrd 行中的 /acpi_override.cpio"
    exit 1
fi

BACKUP_DIR="${BACKUP_DIRS[-1]}"
echo "找到备份目录: $BACKUP_DIR"
echo

# 确认操作
read -p "确认卸载补丁? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消卸载"
    exit 0
fi

echo "[1/4] 恢复 BLS 配置..."

BLS_ENTRY=$(ls /boot/loader/entries/*-${KERNEL_VERSION}.conf 2>/dev/null | head -1)

if [[ -z "$BLS_ENTRY" ]]; then
    BLS_ENTRY=$(ls /boot/loader/entries/*.conf 2>/dev/null | head -1)
fi

if [[ -n "$BLS_ENTRY" ]] && [[ -f "$BACKUP_DIR/"$(basename "$BLS_ENTRY") ]]; then
    cp "$BACKUP_DIR/"$(basename "$BLS_ENTRY") "$BLS_ENTRY"
    echo "  已恢复: $BLS_ENTRY"
elif [[ -n "$BLS_ENTRY" ]]; then
    # 移除 initrd 中的 acpi_override.cpio
    sed -i 's|initrd /acpi_override.cpio ||g' "$BLS_ENTRY"
    echo "  已修改: $BLS_ENTRY"
fi
echo

echo "[2/4] 删除补丁文件..."
rm -f /boot/acpi_override.cpio
rm -rf /boot/acpi_override
rm -f /boot/SSDT-HONOR-I2C_DEVT.aml
echo "  已删除补丁文件"
echo

echo "[3/4] 清理 dracut 配置..."
rm -f /etc/dracut.conf.d/99-acpi-override.conf 2>/dev/null || true
echo "  已清理 dracut 配置"
echo

echo "[4/4] 完成！"
echo
echo "=========================================="
echo "卸载完成！"
echo
echo "请重启系统:"
echo "  sudo reboot"
echo
echo "备份仍保存在: $BACKUP_DIR"
echo "=========================================="
