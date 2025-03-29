#!/bin/sh
set -euo pipefail

# USAGE:
# ./ownlibs.sh [exec] [out libdir]
# creates a directory with all ldd libraries needed for [exec] to run

_usage()
{
cat << EOL 1>&2
usage: $0 [exec] [output libdir]
ownlibs.sh is a script to create a library directory to run an executable
independently from system libraries.
EOL
}

print_liblist()
{
	local libs="$(ldd -f '%p::' "$1")"
	local vdsofix=0
	[ ! -r "$(echo "$libs" | awk -F:: '{print $NF}')" ] && vdsofix=1
	echo "$libs" | awk -F:: -v vdsofix=$vdsofix '{if (1 == vdsofix) $NF=""; print $0}'
}

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
	_usage
	exit 1
elif [ ! -f "$1" ] || [ ! -x "$1" ] || [ ! -r "$1" ]; then
	echo "cannot read '$1'" 1>&2
	exit 1
elif [ ! -d "$2" ]; then
	mkdir -p "$2"
fi

in_exec="$1"
out_dir="$2"

for lib in $(print_liblist "$in_exec"); do
	if [ -L "$lib" ]; then
		real_lib_name="$(readlink "$lib")"
		#cp -fv "$(dirname "$lib")/$real_lib_name" "$out_dir/$real_lib_name"
		cat "$(dirname "$lib")/$real_lib_name" > "$out_dir/$real_lib_name"
		ln -fsv "$real_lib_name" "$out_dir/$(basename "$lib")"
	elif [ -e "$lib" ]
		#cp -fv "$lib" "$out_dir/$(basename "$lib")"
		cat "$lib" > "$out_dir/$(basename "$lib")"
	else
		echo "skipping $lib" 1>&2
	fi
done
chmod -Rv 755 "$out_dir"
