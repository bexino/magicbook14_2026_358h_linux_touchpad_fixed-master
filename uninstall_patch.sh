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
    echo "  3. 编辑 /etc/default/grub 删除 GRUB_EARLY_INITRD_LINUX_CUSTOM 行，并执行 update-grub"
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

echo "[1/4] 恢复 grub 配置..."

if [[ -f "$BACKUP_DIR/grub" ]]; then
    cp "$BACKUP_DIR/grub" /etc/default/grub
    echo "  已从备份恢复 /etc/default/grub"
else
    if [[ -f /etc/default/grub ]]; then
        sed -i '/^GRUB_EARLY_INITRD_LINUX_CUSTOM=/d' /etc/default/grub
        echo "  已从 /etc/default/grub 移除 GRUB_EARLY_INITRD_LINUX_CUSTOM"
    fi
fi
echo

echo "[2/4] 删除补丁文件..."
rm -f /boot/acpi_override.cpio
rm -rf /boot/acpi_override
rm -f /boot/SSDT-HONOR-I2C_DEVT.aml
echo "  已删除补丁文件"
echo

echo "[3/4] 更新 GRUB 配置..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub >/dev/null 2>&1
    echo "  已执行: update-grub"
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
    echo "  已执行: grub-mkconfig"
else
    echo "  跳过: 未找到 update-grub 或 grub-mkconfig"
fi
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
