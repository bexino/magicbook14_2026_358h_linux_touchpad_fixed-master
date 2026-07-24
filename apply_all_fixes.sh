#!/bin/bash
# apply_all_fixes.sh - 一键安装所有修复（触摸板 + 键盘）
#
# 这个脚本会：
#   1. 安装触摸板修复（ACPI SSDT29 补丁）
#   2. 安装键盘修复（i8042.dumbkbd=1 参数）
#   3. 更新 GRUB

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "HONOR MagicBook 14 2026 - 一键修复"
echo "安装触摸板 + 键盘 修复"
echo "=========================================="
echo

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "错误: 请使用 sudo 运行此脚本"
   exit 1
fi

echo "[1/2] 应用触摸板修复..."
echo
if [[ -x "$SCRIPT_DIR/apply_patch.sh" ]]; then
    "$SCRIPT_DIR/apply_patch.sh"
else
    echo "错误: apply_patch.sh 不存在或没有执行权限"
    exit 1
fi
echo

echo "[2/2] 应用键盘修复..."
echo
if [[ -x "$SCRIPT_DIR/apply_keyboard_fix.sh" ]]; then
    "$SCRIPT_DIR/apply_keyboard_fix.sh"
else
    echo "错误: apply_keyboard_fix.sh 不存在或没有执行权限"
    exit 1
fi
echo

echo "=========================================="
echo "全部修复已应用！"
echo
echo "请重启系统:"
echo "  sudo reboot"
echo
echo "重启后验证:"
echo "  xinput list  # 检查触摸板"
echo "  sudo dmesg | grep -iE 'Table Upgrade|ACPI.*Error'  # 检查 ACPI"
echo "=========================================="
