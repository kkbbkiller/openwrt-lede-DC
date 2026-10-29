#!/bin/bash
# 为固定的 LEDE Rockchip 源码安装自定义设备定义。
set -euo pipefail

echo ">>> 安装 RK3576 DTS、镜像定义和 U-Boot 设备关联..."

DTS_DIR="target/linux/rockchip/files/arch/arm64/boot/dts/rockchip"
mkdir -p "$DTS_DIR"
cp -vf rk3576-custom-router.dts "$DTS_DIR/rk3576-custom-router.dts"

python3 - <<'PY'
from pathlib import Path
import re

name = "rockchip_rk3576-custom-router"
image = Path("target/linux/rockchip/image/armv8.mk")
uboot = Path("package/boot/uboot-rockchip/Makefile")
image_text = image.read_text(encoding="utf-8")
uboot_text = uboot.read_text(encoding="utf-8")

# 移除旧版本定义和注册行，再写入唯一的完整设备块。
image_text = re.sub(
    rf"(?m)^define Device/{re.escape(name)}\s*\n.*?^endef[^\n]*\n?",
    "", image_text, flags=re.S,
)
image_text = re.sub(
    rf"(?m)^TARGET_DEVICES\s*\+=\s*{re.escape(name)}\s*$\n?", "", image_text,
)
device = f"""define Device/{name}
  DEVICE_VENDOR := Rockchip
  DEVICE_MODEL := RK3576 Custom Router
  SOC := rk3576
  DEVICE_DTS := rk3576-custom-router
  UBOOT_DEVICE_NAME := generic-rk3576
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-r8169 kmod-usb3 kmod-usb-dwc3 kmod-usb-storage
endef
TARGET_DEVICES += {name}
"""
image_text = image_text.rstrip() + "\n\n" + device

# include/u-boot.mk 根据 BUILD_DEVICES 生成设备选择时的包默认值。
pattern = r"(?m)^define U-Boot/generic-rk3576\n.*?^endef$"
blocks = list(re.finditer(pattern, uboot_text, flags=re.S))
if len(blocks) != 1:
    raise SystemExit("预期恰好一个 U-Boot/generic-rk3576 定义，拒绝修改未知源码")
block = blocks[0].group()
if not re.search(r"(?m)^\s*BUILD_DEVICES\s*:?=", block):
    raise SystemExit("generic-rk3576 缺少 BUILD_DEVICES，拒绝修改未知源码")
if name not in block.split():
    updated = block.removesuffix("endef") + f"  BUILD_DEVICES += {name}\nendef"
    uboot_text = uboot_text[:blocks[0].start()] + updated + uboot_text[blocks[0].end():]

network = Path("target/linux/rockchip/armv8/base-files/etc/board.d/02_network")
network_text = network.read_text(encoding="utf-8")
compatible = "rockchip,rk3576-custom-router"
if compatible not in network_text:
    anchor = '\tcase "$board" in\n'
    if anchor not in network_text:
        raise SystemExit("网络初始化入口不匹配，拒绝修改未知源码")
    rule = (f"\t{compatible})\n"
            "\t\tucidef_set_interfaces_lan_wan 'eth1' 'eth0'\n"
            "\t\t;;\n")
    network_text = network_text.replace(anchor, anchor + rule, 1)

image.write_text(image_text, encoding="utf-8")
uboot.write_text(uboot_text, encoding="utf-8")
network.write_text(network_text, encoding="utf-8")
print("已更新镜像、U-Boot 关联和 LAN=eth1/WAN=eth0（物理插孔待确认）")
PY

echo ">>> DIY 完成；网络/USB 包仅保留原有选择，不代表板载 PHY 已验证。"
