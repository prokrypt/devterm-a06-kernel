# Linux 7.2 for the ClockworkPi DevTerm A06

A current kernel for the ClockworkPi DevTerm with the A06 core (RK3399):
the A06 patches, forward-ported from the last maintained kernel (6.2.7, 2023)
to Linux 7.2.10, plus fixes for everything that broke on the way.

There's an Arch Linux ARM `PKGBUILD`, but the patches are plain `git
format-patch` files on top of vanilla 7.2.10. Any distro can use them.

## Status

Running daily on a DevTerm A06 since 2026-10-11 (Arch Linux ARM, sway).

| | |
|---|---|
| Display (cwd686 panel), full 1280x480 with no clipped rows | works |
| Backlight | works |
| Suspend to RAM (deep) and resume | works |
| Battery, charger, fuel gauge (AXP228) | works, plus energy/power/calibrate properties |
| microSD in UHS-I SDR104 (148.5MHz, 1.8V) | works since 2026-10-21: ~59MB/s sequential read, was ~22MB/s at 50MHz (see below) |
| WiFi (brcmfmac) | works |
| Audio (ES8388) | works |
| Thermal trip points and fan | works |
| HDMI out | untested |
| Ext-cart overlay (yatli's 0034) | not ported |
| Battery-adjust patch (yatli's 0032) | not ported (see below) |

### Battery cutoff

The device tree keeps the 3.3 V cutoff. yatli's 0032 lowered it to 2.85 V,
but it was disabled in his PKGBUILD and also set a one-cell capacity. For a
lower cutoff, set it at runtime, for example from `/etc/rc.local` (the AXP228
has 0.1 V steps):

```
echo 2900000 > /sys/class/power_supply/axp20x-battery/voltage_min
```

## Patches

| | |
|---|---|
| 0001 | Rockchip vendor suspend: SIP calls, `rockchip_pm_config`, regulator suspend states |
| 0002 | OCP8178 backlight driver |
| 0003 | CWD686 panel driver |
| 0004 | `rockchipdrm.dsi_hpad`: end-of-line padding for the panel's lost pixels ([cwd686-fix](https://github.com/prokrypt/cwd686-fix)) |
| 0005 | AXP228 battery/charger additions, RK808 power-off preparation |
| 0006 | rk3399_dmc ondemand thresholds |
| 0007 | The A06 device tree, with `sd-uhs-sdr104` enabled on the microSD slot |

Each patch builds on its own. The commit messages say where each one comes
from and what changed. Sources: ClockworkPi, Max Fierke, Yatao Li
([yatli/arch-linux-arm-clockworkpi](https://github.com/yatli/arch-linux-arm-clockworkpi)),
Manjaro ARM (Dan Johansen), and the Rockchip vendor kernel by way of the
Pinebook Pro suspend patch.

`config` is the kernel config: yatli's 6.2.7 config run through
`olddefconfig`, with the renamed options fixed by hand (see below).

## Installing (Arch Linux ARM)

```
git clone https://github.com/prokrypt/devterm-a06-kernel
cd devterm-a06-kernel
makepkg -si          # natively on the DevTerm: takes hours
```

Or cross-build on an x86_64 Arch box, then copy the packages over:

```
CROSS_COMPILE=aarch64-linux-gnu- makepkg -A --nodeps --config <makepkg.conf with CARCH=aarch64>
```

The package installs `/boot/Image-devterm-a06`,
`/boot/dtbs-devterm-a06/rockchip/rk3399-clockworkpi-a06.dtb` and
`/boot/initramfs-devterm-a06.img`. It doesn't touch `linux-clockworkpi-a06`,
so both kernels can be installed side by side. It does **not** change your
boot entry. Add one to `/boot/extlinux/extlinux.conf` and keep the old one:

```
DEFAULT devterm-a06

LABEL devterm-a06
KERNEL /Image-devterm-a06
FDT /dtbs-devterm-a06/rockchip/rk3399-clockworkpi-a06.dtb
APPEND initrd=/initramfs-devterm-a06.img root=/dev/mmcblk... rw rootwait
```

U-Boot shows nothing on the DevTerm screen, so you can't pick an entry at boot.
To go back, change `DEFAULT`. If the new kernel doesn't boot, edit the file
on the SD card's FAT partition from another computer.

The package also installs `/usr/lib/modprobe.d/devterm-a06.conf`
(`options rockchipdrm dsi_hpad=5`).

## Porting notes (6.2 → 7.2)

These traps apply to anyone moving DevTerm/uConsole A06 support to a newer
kernel, whatever the distro:

- **Sync polarity.** Since 6.x the Rockchip VOP drives positive H/V syncs only
  if the mode has `DRM_MODE_FLAG_PHSYNC/PVSYNC`. Older kernels treated "no
  flag" as positive. The cwd686 mode had no flags, so VSYNC came out inverted,
  the DSI host saw each frame ~5 lines late, and the left edge of the
  landscape picture was cut off, with a black stripe on the right. The fix:
  set both flags in the panel mode. A test `modeline ... +hsync +vsync` in sway
  hides the bug, because it changes the polarity too.
- **VOPB vs VOPL.** `drm_of_find_possible_crtcs()` ignores `status` on graph
  endpoints, so the dts's `&mipi_in_vopb { status = "disable"; }` does nothing,
  and on 7.2 the panel ended up on VOPB. The endpoints are now deleted with
  `/delete-node/`.
- **Suspend wake-up.** The vendor BL31 needs `rockchip,wakeup-config`
  (`RKPM_GPIO_WKUP_EN`), otherwise nothing wakes the board. It used to live in
  `rk3399.dtsi`. When moving the node, compare its properties with the old DTB
  (`fdtget -p`).
- **GPIO numbering.** GPIO bases are dynamic since 6.x, but the firmware wants
  `bank*32+pin` for `rockchip,power-ctrl`. The suspend driver now computes that
  from the `gpioN` alias.
- **Kconfig renames.** `MFD_RK808` became `MFD_RK8XX_I2C`. `olddefconfig`
  silently drops it, and with it the PMIC (clock, regulators, RTC, power key).
  Re-enable it, plus `COMMON_CLK_RK808`, `REGULATOR_RK808`, `RTC_DRV_RK808`
  and `PINCTRL_RK805`. `HID_LOGITECH` now needs `LEDS_CLASS_MULTICOLOR`.
- **rk3399.dtsi split.** Include `rk3399-base.dtsi`, because `rk3399.dtsi` now
  has its own OPP tables and the A06 brings its own.
- **microSD speed.** ClockworkPi's DTS has `sd-uhs-sdr104` commented out on
  `&sdmmc`, so the card runs at 50MHz "high speed". All the UHS wiring is there
  (`vqmmc-supply` = RK808 LDO4, 1.8–3.0V; `io_domains` `sdmmc-supply`), and
  SDR104 tunes and runs cleanly on a SanDisk 128GB card: `btrfs scrub` of 19GB
  with no errors, sequential read 22.5 → 59.4MB/s. If your card misbehaves,
  comment the line out again.
- **API changes.** Panels use `devm_drm_panel_alloc()` and `.get_orientation`.
  Backlights use `backlight_is_blank()` (no more `fb_blank`).
  `linux/of_gpio.h` is gone.

## Building with podman (any distro)

```
podman build -t kbuild-a64 -f Containerfile .
tar xf linux-7.2.10.tar.xz && cd linux-7.2.10
for p in ../devterm-a06-kernel/0*.patch; do patch -Np1 -i $p; done
mkdir -p ~/out && cp ../devterm-a06-kernel/config ~/out/.config
KSRC=$PWD KOUT=~/out ../devterm-a06-kernel/kb.sh olddefconfig
KSRC=$PWD KOUT=~/out ../devterm-a06-kernel/kb.sh Image modules dtbs
```

A full build takes about 4.5 minutes on 16 cores. Install the results with
`modules_install INSTALL_MOD_PATH=...`, then copy `Image` and
`rk3399-clockworkpi-a06.dtb` to /boot yourself.

## License

GPL-2.0, like the kernel.
