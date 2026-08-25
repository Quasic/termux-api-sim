#!/bin/sh
set -e -u

SCRIPTNAME=termux-clipboard-get

for clipfile in "$TERMUX_CLIPFILE" /dev/shm/termux.clip /tmp/termux.clip ~/termux.clip
do [ -r "$clipfile" ]&&break
done

show_usage () {
	cat >&2 <<EOF
Usage: $SCRIPTNAME
Get the dummy clipboard text from $clipfile.
EOF
    exit 0
}

while getopts :h option
do
    case "$option" in
	h) show_usage;;
	?) echo "$SCRIPTNAME: illegal option -$OPTARG"; exit 1;
    esac
done
shift $((OPTIND-1))

if [ $# != 0 ]; then echo "$SCRIPTNAME: too many arguments"; exit 1; fi

cat "$clipfile"
