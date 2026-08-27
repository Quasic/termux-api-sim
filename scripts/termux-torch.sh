#!/bin/sh
set -e -u

SCRIPTNAME=termux-torch

for torchfile in "${TERMUX_TORCHFILE:-}" "${TERMUX_SIM_DIR:-}/termux.toast" /dev/shm/termux.toast /tmp/termux.toast ~/termux.toast
do [ -n "$torchfile" ]&&touch "$torchfile" 2>/dev/null&&break
done

show_usage () {
	echo "Usage: $SCRIPTNAME [on | off]"
	echo "Toggle LED Torch on dummy device"
	exit 1
}

if [ "$#" -ne 1 ]; then
	echo "Illegal param count"
	show_usage
fi

PARAMS=""

if [ "$1" = on ]; then
	PARAMS="--ez enabled true"
elif [ "$1" = off ]; then
	PARAMS="--ez enabled false"
else
	echo "Illegal parameter: $1"
	show_usage
fi

printf %s "@TERMUX_PREFIX@/libexec/termux-api Torch $PARAMS">"$torchfile"
