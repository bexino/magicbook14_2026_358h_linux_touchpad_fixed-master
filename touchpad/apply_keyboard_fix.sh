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

# 查找所有 BLS entries
BLS_ENTRIES=$(ls /boot/loader/entries/*.conf 2>/dev/null || echo "")

if [[ -z "$BLS_ENTRIES" ]]; then
    echo "  错误: 未找到 BLS 条目"
    exit 1
fi

# 备份所有 BLS 条目
for BLS_ENTRY in $BLS_ENTRIES; do
    if [[ -f "$BLS_ENTRY" ]]; then
        cp "$BLS_ENTRY" "$BACKUP_DIR/"
        echo "  备份: $(basename "$BLS_ENTRY")"
    fi
done
echo

# 检查是否已经应用
echo "[2/5] 检查当前配置..."
INSTALLED_COUNT=0
TOTAL_COUNT=0

for BLS_ENTRY in $BLS_ENTRIES; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if grep -q "i8042.dumbkbd=1" "$BLS_ENTRY" 2>/dev/null; then
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
done

if [[ $INSTALLED_COUNT -eq $TOTAL_COUNT ]] && [[ $TOTAL_COUNT -gt 0 ]]; then
    echo "  键盘修复已经应用到所有条目！"
    echo
    read -p "是否要移除键盘修复? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[3/5] 移除键盘修复..."
        for BLS_ENTRY in $BLS_ENTRIES; do
            sed -i 's/i8042.dumbkbd=1 //g' "$BLS_ENTRY"
            sed -i 's/ i8042.dumbkbd=1//g' "$BLS_ENTRY"
            sed -i 's/i8042.dumbkbd=1$//g' "$BLS_ENTRY"
            sed -i 's/  */ /g' "$BLS_ENTRY"
            sed -i 's/ $//' "$BLS_ENTRY"
            echo "  已修改: $(basename "$BLS_ENTRY")"
        done
        echo "  已移除 i8042.dumbkbd=1"
    else
        echo "取消操作"
        exit 0
    fi
else
    echo "  键盘修复尚未应用到所有条目"
    echo
    read -p "是否要添加键盘修复? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        exit 0
    fi
    
    echo "[3/5] 添加键盘修复参数..."
    
    # 添加参数到所有 BLS 条目
    for BLS_ENTRY in $BLS_ENTRIES; do
        # 检查是否有 options 行
        if grep -q "^options" "$BLS_ENTRY"; then
            # 在现有选项后添加空格和参数
            sed -i 's/\(options.*\)/\1 i8042.dumbkbd=1/' "$BLS_ENTRY"
            echo "  已添加: $(basename "$BLS_ENTRY")"
        fi
    done
fi
echo

# 同时添加到 /etc/default/grub（这样新内核会自动包含）
echo "[4/5] 更新 /etc/default/grub..."
if grep -q "i8042.dumbkbd=1" /etc/default/grub; then
    echo "  /etc/default/grub 已包含参数"
else
    sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="i8042.dumbkbd=1 /' /etc/default/grub
    echo "  已添加 i8042.dumbkbd=1 到 /etc/default/grub"
fi
echo

# 更新 GRUB
echo "[5/5] 更新 GRUB 配置..."
if command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
    echo "  已更新: /boot/grub2/grub.cfg"
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
    echo "  已更新: /boot/grub/grub.cfg"
else
    echo "  跳过: 未找到 grub2-mkconfig 或 grub-mkconfig"
fi
echo

# 显示结果
echo "[完成] 当前引导配置:"
for BLS_ENTRY in $BLS_ENTRIES; do
    echo "  $(basename "$BLS_ENTRY"):"
    grep "^options" "$BLS_ENTRY" 2>/dev/null | head -1 | sed 's/^/    /'
done
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
