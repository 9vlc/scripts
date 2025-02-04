#!/bin/sh

# This script converts Xresources to FreeBSD VT colorschemes
# If you want to convert your existing color scheme to Xresources first, use https://terminal.sexy
# Put the output of this script into /boot/loader.conf.d/colors.conf

# vars and stuff
basecols="color8 color1 color9 color2 color10 color3 color11 color4 color12 color5 color13 color6 color14"

[ -z "$1" ] && cat <<EOF>&2&&exit 0
Usage: $0 xresources_file [--alt]

Example: $0 ~/.Xresources >> /boot/loader.conf

This script can be used to convert Xresources to FreeBSD VT (TTY) colorschemes.
Use --alt for alternative foreground and background colors.
EOF

_dot() {
	if echo $1 | grep -q 'color[0-9]'
	then printf "$1" | sed 's/color\([0-9]\)/color.\1/g'
	elif [ $1 = background ]
	then printf "color.0"
	elif [ $1 = foreground ]
	then printf "color.7"
	fi
}

if [ "$2" = "--alt" ]
then resources="background $basecols foreground color15"
else resources="color0 $basecols color7 color15"
fi

for resource in $resources
do echo kern.vt.$(_dot $resource).rgb=\"$(awk "/$resource:/{print\$2}" "$1")\"
done
