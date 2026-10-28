# OpenWrt / LEDE RK3576 自动编译项目

基于 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 源码，适配自制 RK3576 安卓主板的 OpenWrt 固件自动化编译工程。

## 板载硬件外设特性

- **CPU / SoC**: 瑞芯微 Rockchip RK3576 (4x A72 + 4x A53)
- **网络**: 双千兆网口 (GMAC0, GMAC1 / RGMII-RXID)
- **USB**: 
  - USB 3.0 Type-C / OTG (DWC3 DRD0 + USBDP PHY)
  - USB 3.0 Host (DWC3 DRD1 + Naneng Combo PHY1)
  - 多个独立 5V VBUS 供电开关
- **PCIe**: PCIe 2.0 (RC 模式，Combo PHY0，带板载 3.3V 供电控制与复位引脚)
- **显示**: DP / Type-C DP 控制器 (支持 DP 转 HDMI 扩展与常规显示面板)
- **无线网卡 / 蓝牙**: SDIO 接口 (MMC1, 支持 AIC8800/AP6212) + UART4 蓝牙

## 目录结构

- `rk3576-custom-router.dts`：从主板 ADB 中提取并清洗精简后的标准 Device Tree
- `.config`：OpenWrt / LEDE 内核与组件预配置文件
- `diy.sh`：自动打补丁脚本（自动注入 DTS、注册 target board 目标等）
- `.github/workflows/build-openwrt.yml`：GitHub Actions 自动化云端编译流水线

## 如何运行云端编译

1. 在 GitHub 上新建一个仓库（例如命名为 `openwrt-rk3576`）。
2. 将本项目下的所有文件推送至该仓库的主分支：
   ```bash
   git init
   git add .
   git commit -m "feat: initial commit for rk3576 custom openwrt build"
   git branch -M main
   git remote add origin https://github.com/<你的用户名>/openwrt-rk3576.git
   git push -u origin main
   ```
3. 在 GitHub 网页端进入该仓库：
   - 点击顶部 **Actions** 标签页
   - 在左侧选择 **Build OpenWrt for RK3576 Custom Board**
   - 点击右侧 **Run workflow** -> 点击绿色 **Run workflow** 按钮启动云端构建
4. 编译完成后（约 1.5 ~ 2 小时），固件包（`.img.gz` / `sysupgrade`）会自动发布在仓库的 **Releases** 页面以及 Actions 的 **Artifacts** 中，可直接点击下载刷机。
