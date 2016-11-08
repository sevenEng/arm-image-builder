#!/bin/sh

source ./variables.sh

set -ex

cd src/u-boot
make CROSS_COMPILE=arm-linux-gnueabi- V=$V ${TARGET}_defconfig
make CROSS_COMPILE=arm-linux-gnueabi- V=$V -j12

cat > boot.uscr <<"EOF"
setenv xen_addr_r 0x42e00000
setenv bootargs "console=dtuart dtuart=/soc@01c00000/serial@01c28000 dom0_mem=512M,max:512M"

load mmc 0 ${xen_addr_r} /boot/xen
load mmc 0 ${fdt_addr_r} /boot/${fdtfile}
load mmc 0 ${kernel_addr_r} /boot/vmlinuz

fdt addr ${fdt_addr_r}
fdt resize

fdt set /chosen \#address-cells <1>
fdt set /chosen \#size-cells <1>

fdt mknod /chosen module@0
fdt set /chosen/module@0 compatible "xen,linux-zimage" "xen,multiboot-module"
fdt set /chosen/module@0 reg <${kernel_addr_r} 0x${filesize} >
fdt set /chosen/module@0 bootargs "modules=loop,squashfs,sd-mod,usb-storage clk_ignore_unused rootflags=size=512M"
fdt set /chosen xen,xen-bootargs "conswitch=x dom0_mem=512M dtuart=/soc@01c00000/serial@01c28000"

load mmc 0 ${ramdisk_addr_r} /boot/initramfs-grsec
bootz ${xen_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
EOF

mkimage -T script -A arm -d boot.uscr boot.scr
