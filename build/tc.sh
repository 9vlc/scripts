#!/bin/sh
# 9vlc
set -eu

#
# script for quickly using bootlin toolchains
#

tc_dir="${1:-}"; [ "$tc_dir" ] && tc_dir="$(pwd)/.toolchain"
target="${2:-mips32}"
tc_version="${3:-musl--stable-2025.08-1}"

###

tc_site="https://toolchains.bootlin.com/downloads/releases/toolchains"
tc="$tc_site/$target/tarballs/$target--$tc_version"

_Cln()
{ [ -d "${_tc_tmp:-}" ] && rm -rf "$_tc_tmp"; }
trap _Cln EXIT

if [ ! -e "$tc_dir" ]; then
	_tc_tmp="$(mktemp -d)"
	cd "$_tc_tmp"
	>&2 echo "installing a $tc_version toolchain in $tc_dir"
	>&2 echo "temporarily working in $_tc_tmp"

	curl -o "sha256" "$tc.sha256"
	curl -o "$target--$tc_version.tar.xz" "$tc.tar.xz"

	sha256sum -c sha256
	tar xJvpf "$target--$tc_version.tar.xz" |while IFS= read -r _;do printf .;done
	echo

	mv "$target--$tc_version" "$tc_dir"
	rm "$target--$tc_version.tar.xz" sha256

	cd "$tc_dir/bin"
	for e in *buildroot-linux-*-*; do
		if [ "$e" = '*buildroot-linux-*-*' ]; then
			>&2 echo "broken toolchain, aborting"
			>&2 echo "please manually remove '$tc_dir'"
			exit 1
		fi
		
		e_new="$(printf '%s' "$e" | sed -E 's/.*linux-[a-Z]+-//g')"
		[ -e "$e_new" ] || ln -sv "$e" "$e_new"
	done
	cd ../..

	cd ..
fi

export PATH="$tc_dir/bin:$PATH"
unset target tc_version tc_dir tc_site e_new tc e

"$@"
