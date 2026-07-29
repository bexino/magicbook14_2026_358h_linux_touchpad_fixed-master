#!/bin/bash
# uninstall_all.sh - 卸载所有修复（触摸板 + 键盘）

set -euo pipefail

echo "=========================================="
echo "卸载所有修复"
echo "=========================================="
echo

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
   echo "错误: 请使用 sudo 运行此脚本"
   exit 1
fi

echo "[1/4] 卸载触摸板修复..."
if [[ -x "$(dirname "$0")/uninstall_patch.sh" ]]; then
    "$(dirname "$0")/uninstall_patch.sh"
else
    echo "  错误: uninstall_patch.sh 不存在或没有执行权限"
fi
echo

echo "[2/3] 卸载键盘修复..."
if [[ -f /etc/default/grub ]] && grep -q "i8042.dumbkbd=1" /etc/default/grub; then
    sed -i 's/i8042.dumbkbd=1 //g' /etc/default/grub
    sed -i 's/ i8042.dumbkbd=1//g' /etc/default/grub
    sed -i 's/i8042.dumbkbd=1$//g' /etc/default/grub
    echo "  已从 /etc/default/grub 移除"
else
    echo "  /etc/default/grub 中没有键盘参数"
fi
echo

echo "[3/3] 更新 GRUB..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub >/dev/null 2>&1
    echo "  已更新 GRUB"
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
    echo "  已更新 GRUB"
fi
echo

echo "=========================================="
echo "卸载完成！"
echo
echo "请重启系统:"
echo "  sudo reboot"
echo "=========================================="
