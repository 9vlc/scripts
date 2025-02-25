#!/bin/sh

# something something awful unfinished fetch written in 20 minutes
# something something

[ -e /etc/os-release ] && . /etc/os-release

red="$(echo -e '\e[31')"
green="$(echo -e '\e[32')"
yellow="$(echo -e '\e[33')"
blue="$(echo -e '\e[34')"
magenta="$(echo -e '\e[35')"
cyan="$(echo -e '\e[36')"
white="$(echo -e '\e[37')"

reset="$(echo -e '\e[0m')"
bold="$(echo -e '\e[1m')"
italic="$(echo -e '\e[3m')"
uscore="$(echo -e '\e[4m')"

#pcol() {
#	text="$1"
#	shift 1
#	props=""
#	for prop in "$@"; do
#		if [ -z "$(eval echo \$p_$prop)" ]; then
#			echo "no such text format property: $prop"
#		else
#			props="$props$(eval \$p_$prop)"
#		fi
#	done
#	printf "$text$reset"
#
#}

# os
if [ "$PRETTY_NAME" ]; then
	os="$PRETTY_NAME"
elif [ "$NAME" ] && [ "$VERSION" ]; then
	os="$NAME $VERSION"
elif [ "$NAME" ]; then
	os="$NAME"
else
	os="$(uname)$(uname -r 2>/dev/null)"
fi

if [ "$ANSI_COLOR" ]; then
	os_color="$(echo -e "\e[${ANSI_COLOR}m")"
else
	os_color="$(echo -e '\e[33m')"
fi

# hostname
if command -v hostname > /dev/null; then
	hostname="$(hostname -f)"
elif [ -e "/etc/hostname" ]; then
	hostname="$(head -1 /etc/hostname)"
elif [ "$HOSTNAME" ]; then
	hostname="$HOSTNAME"
else
	hostname="I_HAVE_NO_NAME"
fi

# username
if [ "$USER" ]; then
	user="$USER"
elif command -v whoami > /dev/null; then
	user="$(whoami)"
else
	user="$(I_HAVE_NO_NAME)"
fi

sepchar="-"
sep="$sepchar"
for char in $(seq $(printf "${user}${hostname}"|wc -c)); do
	sep="$sep$sepchar"
done

# screw it, freebsd only
packages=$(pkg info|wc -l|sed -e 's/^[ \t]*//')
shell=$(basename $SHELL)
uptime="$(uptime | awk -F, '{sub(".*up ",x,$1);print $1}' | sed -e 's/^[ \t]*//')"


echo "${italic}${uscore}By the way I use:${reset}"
echo
echo "  ${bold}$user${reset}@${bold}$hostname${reset}"
echo "  ${italic}$sep${reset}"
echo "  OS: ${os_color}$os${reset}"
echo "  Uptime: $uptime"
echo "  Shell: $shell"
echo "  Packages: $packages"
echo "  Neofetch: 2"
