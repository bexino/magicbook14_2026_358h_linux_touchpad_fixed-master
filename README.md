# HONOR MagicBook 14 2026 (BCC-N, M1070) — Fix

修复 HONOR MagicBook 14 2026 (BCC-N, M1070) 在 Linux 系统上的：触摸板、键盘、指纹识别问题。

## 适用于
- Fedora
- Fedora atomic(sliverblue, bizzite)
- debian (Ubuntu, Mint)

## 快速启动

- 下载并解压: https://github.com/bexino/magicbook14_fixed/archive/refs/heads/main.zip

### 交互式向导

```bash
sudo bash run.sh
```

### 手动执行

1. Fedora:  
触控板修复：`sudo bash touchpad/apply_patch.sh`  
键盘修复：`sudo bash touchpad/apply_keyboard_fix.sh`  
指纹修复：`sudo bash fprint/install-fprint_fedora.sh`  

2. Fedora atomic(sliverblue, bizzite):  
触控板修复：`sudo bash touchpad/atomic/apply_patch.sh`  
键盘修复：`sudo bash touchpad/atomic/apply_keyboard_fix.sh`  
指纹修复：`sudo bash fprint/install-fprint_atomic.sh`

3. debian (Ubuntu, Mint):  
触控板修复：`sudo bash touchpad/ubuntu/apply_patch.sh`  
键盘修复：`sudo bash touchpad/ubuntu/apply_keyboard_fix.sh`  

---

鸣谢：https://gitee.com/syhun/magicbook14_2026_358h_fedora_linux_touchpad_fixed