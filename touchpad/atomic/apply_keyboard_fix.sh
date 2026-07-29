#!/bin/bash
# apply_keyboard_fix.sh (Atomic Version) - 修复 HONOR MagicBook 14 2026 键盘问题
# 适用于 Fedora Atomic (Silverblue / Kinoite / Sericea / bootc) 等基于 rpm-ostree 的系统
#
# 适用问题：
#   - 键盘按键重复
#   - 键盘响应延迟
#   - 某些键无响应
#
# 解决方案：通过 rpm-ostree kargs 添加内核参数 i8042.dumbkbd=1

set -euo pipefail

echo "=========================================="
echo "HONOR MagicBook 14 2026 键盘修复 (Fedora Atomic)"
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
    echo "如果是传统 Fedora 系统，请使用 touchpad/apply_keyboard_fix.sh"
    exit 1
fi

# 检查当前配置
echo "[1/2] 检查当前内核参数..."
CURRENT_KARGS=$(rpm-ostree kargs 2>/dev/null || echo "")

if echo "$CURRENT_KARGS" | grep -q "i8042.dumbkbd=1"; then
    echo "  当前系统已配置键盘修复参数 (i8042.dumbkbd=1)"
    echo
    read -p "是否要移除键盘修复? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[2/2] 正在通过 rpm-ostree 移除参数..."
        rpm-ostree kargs --delete=i8042.dumbkbd=1
        echo
        echo "=========================================="
        echo "键盘修复参数已移除！"
        echo "请重启系统生效: sudo reboot"
        echo "=========================================="
    else
        echo "取消操作"
        exit 0
    fi
else
    echo "  当前系统未配置键盘修复参数"
    echo
    read -p "是否要添加键盘修复参数 (i8042.dumbkbd=1)? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        exit 0
    fi

    echo "[2/2] 正在通过 rpm-ostree 添加参数..."
    rpm-ostree kargs --append=i8042.dumbkbd=1
    echo
    echo "=========================================="
    echo "键盘修复参数添加成功！"
    echo
    echo "请重启系统生效:"
    echo "  sudo reboot"
    echo
    echo "重启后可运行以下命令验证:"
    echo "  cat /proc/cmdline | grep i8042"
    echo "=========================================="
fi
