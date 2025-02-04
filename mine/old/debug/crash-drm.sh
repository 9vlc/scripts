#!/bin/sh
#
# an overengineered script to memleak/crash FreeBSD's linux drm port
#

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin" # just in case
chromedata="$(mktemp -dt chromedata)" # using a temp dir to not corrupt your chrome data

# how many chrome instances to launch
tospawn=5

if ! which chrome>/dev/null; then
	echo 'Please install the "chromium" package'
	exit 1
	# yep. chromium. any app using gpu acceleration should work, look out for a text like
	# " amdgpu: os_same_file_description couldn't determine if two DRM fds reference the same file description. "
	# " If they do, bad things may happen! "
	# when starting the app from terminal.
elif ! which icesh>/dev/null; then
	echo 'Please install the "icewm" package'
	exit 1
	# no, you don't need to use this window manager. i just decided to use icesh for interacting with windows.
fi

[ "$1" != "run" ] && cat<<EOF && exit
!!! WARNING WARNING WARNING WARNING !!!

This script generates lots of flashing lights
and is meant to memory leak and/or crash your
DRM kernel module. To ignore this warning,
run it like "$0 run" instead.

!!! WARNING WARNING WARNING WARNING !!!
EOF

resizethread() {
while :; do
	if [ -f /tmp/.stopresize ]; then
		rm /tmp/.stopresize
		return
	else
		icesh -c Chromium-browser sizeby 0 100 || return
		icesh -c Chromium-browser sizeby 0 -100 || return
	fi
done
}

wirestatus() {
while :; do
	# TODO
	# spoiler: it will never be done
done
}

echo "Starting chrome, logs at ./chromelogs"
for chrome in $(seq $tospawn); do
	chrome --user-data-dir="$chromedata" --incognito >>chromelogs 2>> chromelogs &
done

echo 'Starting resizethread in three seconds'
echo 'To forcefully stop it, run "touch /tmp/.stopresize"'
sleep 3
icesh -c Chromium-browser sizeto 5000 200
resizethread
echo "Exiting!"

pkill chrome # ughhh

if [ -d "$chromedata" ]; then
	rm -rf "$chromedata"
fi
