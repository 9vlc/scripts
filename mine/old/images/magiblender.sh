#!/bin/sh
# github.com/9vlc
VARLIST="VIEW_X VIEW_Y OFF_X OFF_Y"
ROTATE=0
DEPTH=8
COLS=1024
VIRTUAL=Dither

[ -z "$1" ] && cat << EOF && exit

 $0 Help Message

 INPUT   (-i=)  - Input file
 OUTPUT  (-o=)  - Output file
 VIRTUAL (-f=)  - Pixel mash method
 DEPTH   (-d=)  - Image depth
 COLS    (-c=)  - Number of colors
 VIEW_X  (-vx=) - Image size (X)
 VIEW_Y  (-vy=) - Image size (Y)
 OFF_X   (-ox=) - Viewport offset X
 OFF_Y   (-oy=) - Viewport offset Y
 ROTATE  (-r=)  - Rotation in degrees
 SRC     (-s=)  - Path to file with predefined variables
 DITHER  (--dh) - Use "+dither" option

EOF

switches() {
local args="$*"
for arg in $args; do
	case $arg in
		-i=*) INPUT="${arg#*=}" ;;
		-o=*) OUTPUT="${arg#*=}" ;;
		-f=*) VIRTUAL="${arg#*=}" ;;
		-d=*) DEPTH="${arg#*=}" ;;
		-c=*) COLS="${arg#*=}" ;;
		-vx=*) VIEW_X="${arg#*=}" ;;
		-vy=*) VIEW_Y="${arg#*=}" ;;
		-ox=*) OFF_X="${arg#*=}" ;;
		-oy=*) OFF_Y="${arg#*=}" ;;
		-r=*) ROTATE="${arg#*=}" ;;
		-s=*) SRC="${arg#*=}" ;;
		--dh) DITHER=y ;;
		*) ;;
	esac
done
}
switches "$*"

error() {
	printf "%s\n" "$@"
	exit 1
}

[ -f "$INPUT" ] || error "Input file not found!"
[ -z "$OUTPUT" ] && OUTPUT="$(md5sum "$INPUT"|head -c10).png" && printf "%s\n" "Output not specified!" "Defaulting to $(pwd)/${OUTPUT}"
[ -f "$SRC" ] && printf "%s\n" "Using $3 to source variables" && . "$3"
# [ -f "$OUTPUT" ] && # do somethin here

readvar() { printf %s "Magick ${1}: " && read "$1"; }

for var in $VARLIST
do [ -z "$(eval printf %s\$$var)" ] && readvar $var
done

magick "$INPUT" \
	-depth $DEPTH -colors $COLS \
	-set option:distort:viewport ${VIEW_X}x${VIEW_Y}-${OFF_X}-${OFF_Y} \
	-virtual-pixel $VIRTUAL \
	-filter point \
	-distort SRT $ROTATE \
	+repage $([ -z $DITHER ]||printf %s+dither) \
	"$OUTPUT"
