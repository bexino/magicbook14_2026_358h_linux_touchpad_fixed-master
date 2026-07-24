# HONOR MagicBook 14 2026 (BCC-N, M1070) — Touchpad Fix

修复 HONOR MagicBook 14 2026 (BCC-N, M1070) 在 Linux 系统上的触摸板问题。

## 设备信息

| 项目 | 内容 |
|------|------|
| **制造商** | HONOR |
| **产品名称** | BCC-N |
| **营销名称** | HONOR MagicBook 14 2026 |
| **DMI 版本** | M1070 |
| **CPU** | Intel Core Ultra X7 358H |
| **触摸板** | ELAN **ELAN9048** on `\_SB.PC00.I2C0.TPD0` (I²C HID, addr `0x10`) |
| **BIOS** | HONOR (2026) |

## 问题描述

### 原始问题

1. **触摸板无法识别** - ACPI 表加载失败，触摸板设备未枚举
2. **ACPI 错误**:
   ```
   ACPI Error: No pointer back to namespace node in package
   ACPI Error: AE_AML_INTERNAL, While resolving operands for [Index]
   ACPI Error: Aborting method \_SB.GINF due to previous error
   ACPI Error: AE_AML_INTERNAL, (SSDT:I2C_DEVT) while loading table
   ```

### 问题根源

OEM 固件中的 SSDT29 (`I2C_DEVT`) 包含一个 **module-level 语句**，在表加载时执行，但它依赖于内核尚未初始化的数据（`GNUM`），导致 Linux ACPICA 解释器中止整个表。

## 修复内容

### 1. 修复 ACPI 表加载错误
将 `Device (LNFC)` 中的 module-level 语句移到 `_INI` 方法中：

**之前（错误）：**
```asl
CreateWordField (SBGF, 0x17, INT1)
INT1 = GNUM (0x001A088A)  // ← 在表加载时执行，导致错误
```

**现在（正确）：**
```asl
Method (_INI, 0, NotSerialized)
{
    CreateWordField (SBGF, 0x17, INT1)
    INT1 = GNUM (0x001A088A)  // ← 在表加载完成后执行
}
```

### 2. 修正触摸板配置参数
将 **TPTD[0]** 从 `0x00` 改为 `0x03`，让系统正确识别 **ELAN9048** 触摸板。

### 3. 键盘修复（可选）
添加内核参数 `i8042.dumbkbd=1` 解决键盘问题：
- 按键重复
- 键盘响应延迟
- 某些键无响应

## 快速安装

### 触摸板 + 键盘修复（一键安装）
```bash
git clone <repo-url> HONOR_MagicBook14_2026_BCC-N_358H_touchpad_fixed
cd HONOR_MagicBook14_2026_BCC-N_358H_touchpad_fixed
sudo bash ./apply_all_fixes.sh
sudo reboot
```

### 单独安装

#### 仅触摸板修复
```bash
sudo ./apply_patch.sh
sudo reboot
```

#### 仅键盘修复
```bash
sudo ./apply_keyboard_fix.sh
sudo reboot
```

## 验证

重启后运行：

```bash
# 1. 检查 ACPI 表覆盖
sudo dmesg | grep -iE "Table Upgrade|SSDT.*I2C_DEVT"
# 应该看到: ACPI: Table Upgrade: override [SSDT- HONOR-I2C_DEVT]

# 2. 检查是否还有 ACPI 错误
sudo dmesg | grep -iE "ACPI.*Error" | head -5
# 应该没有 AE_AML_INTERNAL 错误

# 3. 检查触摸板设备
ls /sys/bus/acpi/devices/ | grep -iE "elan|tpd"

# 4. 检查 xinput
xinput list
# 应该看到触摸板设备
```

## 卸载

```bash
cd /path/to/HONOR_MagicBook14_2026_BCC-N_358H_touchpad_fixed
sudo ./uninstall_patch.sh
sudo reboot
```

## 测试环境

- **系统**: Fedora Linux 44
- **内核**: 7.0.10
- **initramfs**: dracut
- ** bootloader**: GRUB with BLS

理论上适用于任何使用 dracut 的发行版（Fedora, RHEL, CentOS, SUSE 等）。

## 项目结构

```
HONOR_MagicBook14_2026_BCC-N_358H_touchpad_fixed/
├── README.md                          # 本文件
├── apply_all_fixes.sh                 # 一键安装所有修复（触摸板+键盘）
├── apply_patch.sh                     # 触摸板修复安装脚本
├── apply_keyboard_fix.sh              # 键盘修复安装脚本
├── uninstall_patch.sh                 # 卸载脚本（触摸板）
├── uninstall_all.sh                   # 卸载所有修复
├── patch/
│   ├── SSDT29_MagicBook14_2026_BCC-N_358H.aml    # 编译好的 ACPI 补丁
│   └── SSDT29_MagicBook14_2026_BCC-N_358H.dsl    # 源代码
└── build/
    └── build_patch.sh                 # 构建脚本
```

## 构建补丁

如果需要重新构建（修改源代码后）：

```bash
cd build
./build_patch.sh
```

这将：
1. 用 iasl 编译 DSL 文件
2. 修改 OEM Revision (0x1000 → 0x2000)
3. 重新计算 ACPI checksum

## 注意事项

1. **备份**: 安装脚本会自动备份原始文件到 `/root/acpi_backup/`
2. **内核更新**: 内核更新后可能需要重新应用补丁
3. **权限**: 需要 root 权限运行安装脚本

## 参考

- 原始 Pro 版本项目: [HONOR_ZQC-P_M1010](https://github.com/rs0x29a/Linux-on-HONOR-MagicBook-14-Pro-2026-AI_ZQC-P_M1010)
- Linux ACPI 文档: [initrd_table_override.rst](https://www.kernel.org/doc/html/latest/admin-guide/acpi/initrd_table_override.html)
