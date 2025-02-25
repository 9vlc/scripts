#!/bin/sh
# toaster(tm (inc (registered)))·
[ -z "$1" ] && cat <<EOF>&2&&exit 0
Usage: $0 <file> <header size in bytes> <3-5 are toast options>

Examples:
$ $0 image.bmp 56 -a

This script corrupts files using the GSM toast compression. Nothing out of ordinary.
Default header size is 100 bytes.
EOF

hsize=$2
[ -z "$2" ] && hsize=100

hash=$(md5sum<$1|head -c10)
mkdir /tmp/toast-$hash
odir=/tmp/toast-$hash
cp "$1" $odir/input

toast -c $3 $4 $5>$odir/output<$odir/input
untoast -c $3 $4 $5>$odir/corrupt<$odir/output

size=$(wc -c<$odir/corrupt)

head -c$hsize $odir/input>$odir/output
tail -c$(($size-$hsize)) $odir/corrupt|head -c$(($size-$hsize*2))>>$odir/output
tail -c$(($(wc -c<$odir/input)-$(wc -c<$odir/output))) $odir/input>>$odir/output

cp $odir/output "corrupt.$(basename "$1")"
rm -rv $odir
