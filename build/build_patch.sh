#!/usr/bin/env bash
# build_patch.sh - 重新构建 ACPI 补丁
#
# 步骤:
#   1. 编译 DSL 文件
#   2. 修改 OEM Revision (0x1000 -> 0x2000)
#   3. 重新计算 ACPI checksum
#
# 需要: iasl (acpica-tools), python3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SRC="$REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.dsl"
OUT="$REPO_DIR/patch/SSDT29_MagicBook14_2026_BCC-N_358H.aml"

# 检查依赖
command -v iasl >/dev/null || { echo "缺少 iasl (安装: sudo dnf install acpica-tools)"; exit 1; }
command -v python3 >/dev/null || { echo "缺少 python3"; exit 1; }

echo "=========================================="
echo "构建 ACPI 补丁"
echo "=========================================="
echo

# 创建临时目录
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cp "$SRC" "$WORK/SSDT29.dsl"

echo "[1/3] iasl 编译..."
( cd "$WORK" && iasl SSDT29.dsl ) | tail -3
echo

echo "[2/3] 修改 OEM Revision (0x1000 -> 0x2000) 和 checksum..."

python3 <<'PY'
import sys

aml_path = "$WORK/SSDT29.aml"
data = bytearray(open(aml_path, "rb").read())

old_rev = int.from_bytes(data[24:28], "little")
print(f"  原始 OEM Revision: 0x{old_rev:04x}")

# 修改 OEM revision
data[24:28] = (0x2000).to_bytes(4, "little")

# 重新计算 checksum
data[9] = 0
new_checksum = (-sum(data)) & 0xFF
data[9] = new_checksum

verify = sum(data) & 0xFF
print(f"  新 OEM Revision: 0x2000")
print(f"  新 Checksum: 0x{new_checksum:02x}")
print(f"  验证: 0x{verify:02x}")

assert verify == 0, "Checksum 计算错误！"
print("  Checksum 验证通过！")

open(aml_path, "wb").write(data)
PY

echo

echo "[3/3] 安装..."
install -m0644 "$WORK/SSDT29.aml" "$OUT"
echo "  输出: $OUT"
echo

echo "=========================================="
echo "构建完成！"
echo
echo "请运行: sudo ./apply_patch.sh"
echo "=========================================="
