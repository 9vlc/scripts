#!/bin/sh

# WARNING: this script doesn't work on busybox
# This script converts Xresources to Linux TTY colorschemes
# If you want to convert your existing color scheme to Xresources first, use https://terminal.sexy
#
# - Where to put the output
# The output of this script goes into your kernel CMDLINE bootloader option
# Don't forget to add "vt.color=0xF0" or "vt.color=0x0F" for light and dark themes respectively
# If the foreground color looks off / is too bright, replace F with a 7

# vars and stuff
basecols1="color1 color2 color3 color4 color5 color6"
basecols2="color8 color9 color10 color11 color12 color13 color14"
vt_red="vt.default_red="
vt_grn="vt.default_grn="
vt_blu="vt.default_blu="

[ -z "$1" ] && cat <<EOF>&2&&exit 0
Usage: $0 xresources_file [--alt]

Example: $0 ~/.Xresources

This script can be used to convert Xresources to Linux TTY colorschemes.
Use --alt for alternative foreground and background colors.

For some more info read the top comments inside this file.
EOF

if [ "$2" = "--alt" ]
then resources="background $basecols1 foreground $basecols2 foreground"
else resources="color0 $basecols1 color7 $basecols2 color15"
fi

for resource in $resources
do
	curcol=$(awk "/$resource:/{print\$2}" "$1"| # get the color
	sed 's/#//'|dd conv=ucase 2>/dev/null) # remove "#"'s and uppercase all the symbols
	vt_red="${vt_red}$(echo "ibase=16; $(echo "${curcol}"|cut -c1-2)"|bc)," # black magic
	vt_grn="${vt_grn}$(echo "ibase=16; $(echo "${curcol}"|cut -c3-4)"|bc),"
	vt_blu="${vt_blu}$(echo "ibase=16; $(echo "${curcol}"|cut -c5-6)"|bc),"
done

echo ${vt_red%?}
echo ${vt_grn%?}
echo ${vt_blu%?}
