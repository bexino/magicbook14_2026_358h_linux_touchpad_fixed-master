#!/bin/bash
# apply_keyboard_fix.sh - 修复 HONOR MagicBook 14 2026 键盘问题
#
# 适用问题：
#   - 键盘按键重复
#   - 键盘响应延迟
#   - 某些键无响应
#
# 解决方案：添加内核参数 i8042.dumbkbd=1
#
# 参考：https://wiki.archlinux.org/title/AT_Keyboard

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/root/keyboard_fix_backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "HONOR MagicBook 14 2026 键盘修复"
echo "=========================================="
echo

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "错误: 请使用 sudo 运行此脚本"
   exit 1
fi

# 创建备份目录
echo "[1/5] 创建备份..."
mkdir -p "$BACKUP_DIR"

# 获取内核版本
KERNEL_VERSION=$(uname -r)
echo "  内核版本: $KERNEL_VERSION"

# 备份 grub 配置
if [[ -f /etc/default/grub ]]; then
    cp /etc/default/grub "$BACKUP_DIR/grub"
    echo "  备份: /etc/default/grub"
else
    echo "  错误: /etc/default/grub 不存在"
    exit 1
fi
echo

# 检查是否已经应用
echo "[2/4] 检查当前配置..."
if grep -q "i8042.dumbkbd=1" /etc/default/grub; then
    echo "  键盘修复已经应用！"
    echo
    read -p "是否要移除键盘修复? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[3/4] 移除键盘修复..."
        sed -i 's/i8042.dumbkbd=1 //g' /etc/default/grub
        sed -i 's/ i8042.dumbkbd=1//g' /etc/default/grub
        sed -i 's/i8042.dumbkbd=1$//g' /etc/default/grub
        echo "  已移除 i8042.dumbkbd=1"
    else
        echo "取消操作"
        exit 0
    fi
else
    echo "  键盘修复尚未应用"
    echo
    read -p "是否要添加键盘修复? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        exit 0
    fi
    
    echo "[3/4] 添加键盘修复参数..."
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="i8042.dumbkbd=1 /' /etc/default/grub
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="i8042.dumbkbd=1"' >> /etc/default/grub
    fi
    echo "  已添加 i8042.dumbkbd=1 到 /etc/default/grub"
fi
echo

# 更新 GRUB
echo "[4/4] 更新 GRUB 配置..."
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

# 显示结果
echo "[完成] 当前引导配置:"
grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub
echo

echo "=========================================="
echo "完成！"
echo
echo "请重启系统:"
echo "  sudo reboot"
echo
echo "验证键盘参数:"
echo "  cat /proc/cmdline | grep i8042"
echo
echo "备份已保存到: $BACKUP_DIR"
echo "=========================================="
