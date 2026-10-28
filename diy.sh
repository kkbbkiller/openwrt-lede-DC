#!/bin/bash
# Description: OpenWrt DIY script (Patch RK3576 device tree and build definition)

echo ">>> Applying RK3576 device tree and target board definition..."

# 1. 查找 rockchip dts 目录
DTS_DIR="target/linux/rockchip/dts"
if [ ! -d "$DTS_DIR" ]; then
    DTS_DIR=$(find target/linux/rockchip/ -type d -name "dts" | head -n 1)
fi

# 拷贝自定义 DTS
if [ -d "$DTS_DIR" ]; then
    cp -vf rk3576-custom-router.dts "$DTS_DIR/"
    echo "Copied rk3576-custom-router.dts to $DTS_DIR"
fi

# 2. 检查内核 dts 路径并补充（针对 linux 6.1 / 6.6 / 6.12 补丁树）
for dts_arch in target/linux/rockchip/files/arch/arm64/boot/dts/rockchip; do
    if [ -d "$dts_arch" ]; then
        cp -vf rk3576-custom-router.dts "$dts_arch/"
        echo "Copied to kernel arch dts: $dts_arch"
    fi
done

# 3. 向 target/linux/rockchip/image/armv8.mk 中追加板级目标
MK_FILE="target/linux/rockchip/image/armv8.mk"
if [ -f "$MK_FILE" ]; then
    if ! grep -q "rk3576-custom-router" "$MK_FILE"; then
        cat << 'EOF' >> "$MK_FILE"

define Device/rockchip_rk3576-custom-router
  DEVICE_VENDOR := Rockchip
  DEVICE_MODEL := RK3576 Custom Router
  SOC := rk3576
  DEVICE_DTS := rk3576-custom-router
  DEVICE_PACKAGES := kmod-r8169 kmod-usb3 kmod-usb-dwc3 kmod-usb-storage
endef
TARGET_DEVICES += rockchip_rk3576-custom-router
EOF
        echo "Successfully added rockchip_rk3576-custom-router target to $MK_FILE"
    fi
fi

# 4. 修改默认 LAN IP 为 192.168.1.1
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate || true

echo ">>> DIY script finished successfully."
