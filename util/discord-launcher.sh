#!/bin/sh
# dependencies:
# linux-rl9
# pulseaudio (optional, needed for sound)

discord_branch="canary" # stable, ptb, canary
discord_dir="$HOME/.local/share/discord"
linux_shell="/compat/linux/bin/bash"

export ELECTRON_IS_DEV=0
export LIBGL_DRI3_DISABLE=1
export NODE_ENV=production

_inst_app() {
	local tmp_dir="$(mktemp -d)"
	local prev_dir="$PWD"
	cd "$tmp_dir"
	
	fetch -o "$tmp_dir"/app.tar.gz "https://discord.com/api/download/${1}?platform=linux&format=tar.gz" 1>&2
	tar xpf app.tar.gz
	local discord_exec="$(echo Discord*)"
	mv Discord* "$2"

	cd "$prev_dir"
	rm -rf "$tmp_dir"
	echo "$discord_exec"
}

_inst_runner() {
cat << RUNNER > "$3/run.sh"
#!$2

# workaround Chromium bug https://bugs.chromium.org/p/chromium/issues/detail?id=918234
if [ "\$DBUS_SESSION_BUS_ADDRESS" = "" ]; then
    export DBUS_SESSION_BUS_ADDRESS="autolaunch:"
fi

if command -v pulseaudio >/dev/null; then
	pulseaudio --start
fi

exec -a "\$0" "$3/$1" --no-sandbox --no-zygote "\$@"
RUNNER
chmod +x "$3/run.sh"
}

_inst_shortcut() {
	local name="Discord $(echo $2 | sed 's/Discord//')"
	if [ ! -e "$HOME/.local/share/applications" ]; then
		mkdir -p "$HOME/.local/share/applications"
	fi
cat << DESKTOP > "$HOME/.local/share/applications/discord.desktop"
[Desktop Entry]
Name=$name
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=$1/run.sh
Icon=$1/discord.png
Type=Application
Categories=Network;InstantMessaging;
DESKTOP
}

case "$1" in
	upd*|upg*)
		if [ -z "$discord_dir" ] || \
			[ "$discord_dir" = "/" ]; then
			[ "$discord_dir" = "$HOME" ] || \
			echo "discord_dir is set incorrectly." 1>&2
			exit 1
		elif [ -d "$discord_dir" ]; then
			rm -rf "$discord_dir"
		fi
		discord_exec="$(_inst_app "$discord_branch" "$discord_dir")"
		
		_inst_runner "$discord_exec" "$linux_shell" "$discord_dir"
		_inst_shortcut "$discord_dir" "$discord_exec"
	;;
	run|*)
		if [ ! -x "$discord_dir/run.sh" ]; then
			echo "discord / runner not installed in $discord_dir"
			exit 1
		fi

		shift 1
		exec "$discord_dir/run.sh" "$@"
	;;
esac
