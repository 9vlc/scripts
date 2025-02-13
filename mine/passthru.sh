#!/bin/sh
pptdevs="2:0:0 45:0:0 45:0:1 47:0:0 47:0:1 47:0:3 47:0:4"

if [ "$(whoami)" != "root" ]; then
	exit 1
fi

for i in $pptdevs; do
	devctl detach pci0:$i
done

sleep 1

for i in $pptdevs; do
	devctl detach -f pci0:$i
done

sleep 1

for i in $pptdevs; do
	devctl set driver pci0:$i ppt
done

if ! kldstat | grep -q nmdm; then
	kldload nmdm
fi

if [ -e "/dev/vmm/windows" ]; then
	bhyvectl --destroy --vm=windows
fi

conscontrol delete ttyv0

bhyve \
	-D -S -H -P -A -w \
	-c sockets=1,cores=16 \
	-m 16G \
	`: thing2` \
	-o bios.vendor="FeeBSD" \
	-o bios.version="10.32" \
	-o bios.release_date="2024/8/26" \
	-o bios.family_name="super binary blob" \
	\
	-o system.manufacturer="APPLE" \
	-o system.product_name="MNT Reform" \
	-o system.serial_number="neofetch 2" \
	-o system.version="1.0" \
	\
	-o board.manufacturer="APPLE" \
	-o board.product_name="iMac11,3" \
	-o board.version="ughhh" \
	-o board.serial_number="cereal" \
	-o board.asset_tag="FNT-fortnite" \
	\
	-o chasis.manufacturer="playstation" \
	-o chasis.version="6" \
	-o chasis.serial_number="maybe" \
	-o chasis.asset_tag="ASD-foobar" \
	-o chasis.sku="FGH-thething" \
	`: ` \
	-s 0,amd_hostbridge \
	-s 31,lpc \
	`: asd` \
	-o pci.0.31.0.pcireg.vendor=host \
	-o pci.0.31.0.pcireg.device=host \
	-o pci.0.31.0.pcireg.subvendor=host \
	-o pci.0.31.0.pcireg.subdevice=host \
	-l com1,/dev/nmdm0A \
	-l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd \
	-s 1:0,ahci,hd:/dev/zvol/epic/zvols/windows \
	-s 5:0,e1000,tap0 \
	`: passthru devices` \
	-s 2:0,passthru,2/0/0 \
	-s 7:0,passthru,45/0/0,rom=../rx7600.rom \
	-s 7:1,passthru,45/0/1,rom=../AmdGopDriver.rom \
	-s 9:0,passthru,47/0/1 \
	-s 9:3,passthru,47/0/3 \
	-s 9:4,passthru,47/0/4 \
	`: thing` \
	windows > /root/vmlog 2>/root/vmlog
