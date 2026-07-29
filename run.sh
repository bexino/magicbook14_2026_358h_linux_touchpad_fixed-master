#!/bin/bash
# HONOR MagicBook 14 2026 修复脚本统一导航入口

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

prompt_reboot() {
    echo -e "\n${GREEN}===============================================${NC}"
    echo -e "${GREEN} 修复脚本已运行完毕！建议重启系统以使修改生效。${NC}"
    echo -e "${GREEN}===============================================${NC}"
    read -rp "是否立即重启系统？(y/N): " choice
    case "$choice" in
        [Yy]* )
            echo -e "${YELLOW}正在重启系统...${NC}"
            sudo reboot
            ;;
        * )
            echo -e "${BLUE}请稍后手动重启系统以生效。${NC}"
            ;;
    esac
}

run_touchpad_and_keyboard_fix() {
    local patch_script="$1"
    local kbd_script="$2"

    echo -e "\n${BLUE}>>> 1/2 开始运行触摸板修复脚本: ${patch_script}${NC}"
    bash "$SCRIPT_DIR/$patch_script"

    echo -e "\n${BLUE}>>> 2/2 开始运行键盘修复脚本: ${kbd_script}${NC}"
    bash "$SCRIPT_DIR/$kbd_script"

    prompt_reboot
}

run_fprint_fix() {
    local fprint_script="$1"

    echo -e "\n${BLUE}>>> 开始运行指纹修复脚本: ${fprint_script}${NC}"
    bash "$SCRIPT_DIR/$fprint_script"
}

show_fedora_menu() {
    while true; do
        echo -e "\n${GREEN}===============================================${NC}"
        echo -e "${GREEN}          Fedora 修复选项 Menu                 ${NC}"
        echo -e "${GREEN}===============================================${NC}"
        echo "1) 运行触摸板 + 键盘修复 (同时运行 apply_patch.sh 和 apply_keyboard_fix.sh)"
        echo "2) 运行指纹修复 (install-fprint_fedora.sh)"
        echo "3) 返回主菜单"
        echo "4) 退出脚本"
        echo -e "${GREEN}===============================================${NC}"
        read -rp "请选择操作 [1-4]: " fed_choice

        case "$fed_choice" in
            1)
                run_touchpad_and_keyboard_fix "touchpad/apply_patch.sh" "touchpad/apply_keyboard_fix.sh"
                ;;
            2)
                run_fprint_fix "fprint/install-fprint_fedora.sh"
                ;;
            3)
                break
                ;;
            4)
                echo "已退出修复向导。"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择。${NC}"
                ;;
        esac
    done
}

show_atomic_menu() {
    while true; do
        echo -e "\n${GREEN}===============================================${NC}"
        echo -e "${GREEN}     Fedora Atomic (Silverblue/Bazzite) 菜单   ${NC}"
        echo -e "${GREEN}===============================================${NC}"
        echo "1) 运行触摸板 + 键盘修复 (同时运行 atomic/apply_patch.sh 和 apply_keyboard_fix.sh)"
        echo "2) 运行指纹修复 (install-fprint_atomic.sh)"
        echo "3) 返回主菜单"
        echo "4) 退出脚本"
        echo -e "${GREEN}===============================================${NC}"
        read -rp "请选择操作 [1-4]: " atom_choice

        case "$atom_choice" in
            1)
                run_touchpad_and_keyboard_fix "touchpad/atomic/apply_patch.sh" "touchpad/atomic/apply_keyboard_fix.sh"
                ;;
            2)
                run_fprint_fix "fprint/install-fprint_atomic.sh"
                ;;
            3)
                break
                ;;
            4)
                echo "已退出修复向导。"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择。${NC}"
                ;;
        esac
    done
}

show_debian_menu() {
    while true; do
        echo -e "\n${GREEN}===============================================${NC}"
        echo -e "${GREEN}     Debian / Ubuntu / Mint 修复选项 Menu       ${NC}"
        echo -e "${GREEN}===============================================${NC}"
        echo "1) 运行触摸板 + 键盘修复 (同时运行 ubuntu/apply_patch.sh 和 apply_keyboard_fix.sh)"
        echo "2) 返回主菜单"
        echo "3) 退出脚本"
        echo -e "${GREEN}===============================================${NC}"
        read -rp "请选择操作 [1-3]: " deb_choice

        case "$deb_choice" in
            1)
                run_touchpad_and_keyboard_fix "touchpad/ubuntu/apply_patch.sh" "touchpad/ubuntu/apply_keyboard_fix.sh"
                ;;
            2)
                break
                ;;
            3)
                echo "已退出修复向导。"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择。${NC}"
                ;;
        esac
    done
}

main_menu() {
    while true; do
        echo -e "\n${BLUE}===============================================${NC}"
        echo -e "${BLUE}    HONOR MagicBook 14 2026 硬件修复向导        ${NC}"
        echo -e "${BLUE}===============================================${NC}"
        echo "请选择您的操作系统类型："
        echo "1. Fedora"
        echo "2. Fedora atomic(sliverblue, bizzite)"
        echo "3. debian (Ubuntu, Mint)"
        echo "4. 退出"
        echo -e "${BLUE}===============================================${NC}"
        read -rp "请输入选项数字 [1-4]: " main_choice

        case "$main_choice" in
            1)
                show_fedora_menu
                ;;
            2)
                show_atomic_menu
                ;;
            3)
                show_debian_menu
                ;;
            4)
                echo "已退出修复向导。"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新输入。${NC}"
                ;;
        esac
    done
}

main_menu
