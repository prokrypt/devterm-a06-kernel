# Linux for the ClockworkPi DevTerm A06 (RK3399)
# Maintainer: prokrypt <prokrypt@edited.us>
# Based on Arch Linux ARM's linux-aarch64 PKGBUILD (Kevin Mihelich, graysky)
# and linux-clockworkpi-a06 (Dan Johansen, Max Fierke, Yatao Li).
#
# Cross-build on x86_64: CROSS_COMPILE=aarch64-linux-gnu- makepkg -A
# (the -headers package then contains host-arch scripts; build natively if you
# need it for DKMS).

pkgbase=linux-devterm-a06
_srcname=linux-7.2
_desc="ClockworkPi DevTerm A06"
pkgver=7.2.10
pkgrel=2
arch=('aarch64')
url="https://github.com/prokrypt/devterm-a06-kernel"
license=('GPL-2.0-only')
makedepends=('kmod' 'bc' 'dtc' 'python' 'cpio' 'zstd')
options=('!strip' '!debug')
source=("https://www.kernel.org/pub/linux/kernel/v7.x/${_srcname}.tar.xz"
        "https://www.kernel.org/pub/linux/kernel/v7.x/patch-${pkgver}.xz"
        '0001-rockchip-add-vendor-suspend-mode-configuration-SIP-p.patch'
        '0002-backlight-add-OCP8178-backlight-driver-ClockworkPi-A.patch'
        '0003-drm-panel-add-ClockworkPi-CWD686-panel-driver.patch'
        '0004-drm-rockchip-dsi-add-dsi_hpad-module-parameter.patch'
        '0005-power-axp20x-mfd-rk8xx-ClockworkPi-A06-power-support.patch'
        '0006-devfreq-rk3399_dmc-more-eager-ondemand-thresholds.patch'
        '0007-arm64-dts-rockchip-add-ClockworkPi-A06-DevTerm.patch'
        'config'
        'linux.preset'
        'devterm-a06.conf')
sha256sums=('f9fef3d14c0df53819026f4be74459835c2a0b0dcbf5b5bbd9ea19f0829402b3'
            '347a2d6a976bd1f34662ac3ca219e51878900b1c440b380bfa40a47082bfdab1'
            '75813ff86addafbeb3e80da1b4672d02c6be96d2140deb5d76798f4c1b4b5f6b'
            'aa1a98e1809200c56a2679eb91262815324792ff508f4ab8c8de5e3da61c47a0'
            '7096a9e2c8c1472639a14097babb8c423e0483268d3950afed1fa66d4473b768'
            '751a2a41d3eaa4caed63a0c885f0a027de56b785d31dcfc9b94679c1ef119fed'
            '8cd4d0687e50018d05ac90beab519d1fc6f3cc1e5eab4343bfeb38a227e09d93'
            '939cc86c2c6c72ca185b31dcfbb0c23327d0498f7f4b342b8fe883c72270676b'
            '1b934f25a2f3ecd408ad973273b1ddf37609c456bd3b1cd384402c7f29e33727'
            '765c0c6590eeeb15f36e18aef2f6133b31932d507d75e2d0a5a497d57915905b'
            'a7d9841fc067b2a5f5cdbfe265fe59a571d80c955e138a1e756d971907b721e1'
            '64172eb26a0adef7403d819473f89d1d886265a611976405dba8ee4e644bacac')

_make() {
  make ARCH=arm64 ${CROSS_COMPILE:+CROSS_COMPILE="$CROSS_COMPILE"} "$@"
}

prepare() {
  cd $_srcname

  echo "Setting version..."
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "${pkgbase#linux}" > localversion.20-pkgname

  # stable update
  patch -Np1 -i ../patch-${pkgver}

  local p
  for p in ../0*.patch; do
    echo "Applying $p"
    patch -Np1 -i "$p"
  done

  cat "${srcdir}/config" > ./.config
  _make olddefconfig
}

build() {
  cd ${_srcname}

  _make -s kernelrelease > version
  unset LDFLAGS
  _make ${MAKEFLAGS} Image modules dtbs
}

_package() {
  pkgdesc="The Linux Kernel and modules - ${_desc}"
  depends=('coreutils' 'kmod' 'mkinitcpio>=0.7')
  optdepends=('linux-firmware: firmware images needed for some devices'
              'wireless-regdb: to set the correct wireless channels of your country')
  provides=("WIREGUARD-MODULE")
  install=${pkgname}.install

  cd $_srcname
  local kernver="$(<version)"
  local modulesdir="$pkgdir/usr/lib/modules/$kernver"

  echo "Installing boot image and dtb..."
  # own names, so it can sit next to another kernel package in /boot
  install -Dm644 arch/arm64/boot/Image "${pkgdir}/boot/Image-devterm-a06"
  install -Dm644 arch/arm64/boot/dts/rockchip/rk3399-clockworkpi-a06.dtb \
    "${pkgdir}/boot/dtbs-devterm-a06/rockchip/rk3399-clockworkpi-a06.dtb"

  echo "Installing modules..."
  _make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 DEPMOD=/doesnt/exist modules_install
  rm -f "$modulesdir"/build

  sed "s|%PKGBASE%|${pkgbase}|g; s|%KERNVER%|${kernver}|g" ../linux.preset |
    install -Dm644 /dev/stdin "${pkgdir}/etc/mkinitcpio.d/${pkgbase}.preset"

  install -Dm644 ../devterm-a06.conf "${pkgdir}/usr/lib/modprobe.d/devterm-a06.conf"

  # let mkinitcpio's 90-mkinitcpio-install.hook build the initramfs
  install -d "${pkgdir}/usr/lib/initcpio/"
  echo "dummy file to trigger mkinitcpio to run" > "${pkgdir}/usr/lib/initcpio/$(<version)"
}

_package-headers() {
  pkgdesc="Header files and scripts for building modules for linux kernel - ${_desc}"

  cd $_srcname
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  echo "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/arm64" -m644 arch/arm64/Makefile
  cp -t "$builddir" -a scripts
  mkdir -p "$builddir"/{fs/xfs,mm}

  echo "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/arm64" -a arch/arm64/include
  install -Dt "$builddir/arch/arm64/kernel" -m644 arch/arm64/kernel/asm-offsets.s
  mkdir -p "$builddir/arch/arm"
  cp -t "$builddir/arch/arm" -a arch/arm/include
  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  echo "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */arm64/ || $arch == */arm/ ]] && continue
    rm -r "$arch"
  done

  rm -rf "$builddir/Documentation"
  find -L "$builddir" -type l -delete
  find "$builddir" -type f -name '*.o' -delete

  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

pkgname=("${pkgbase}" "${pkgbase}-headers")
for _p in ${pkgname[@]}; do
  eval "package_${_p}() {
    _package${_p#${pkgbase}}
  }"
done
