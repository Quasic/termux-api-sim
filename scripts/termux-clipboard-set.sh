#!/bin/dash
set -e -u

SCRIPTNAME=termux-clipboard-set

for clipfile in "${TERMUX_CLIPFILE:-${TERMUX_SIM_DIR:-/dev/shm}/termux.clip}" /tmp/termux.clip "${HOME:-~}/termux.clip"
do [ -n "$clipfile" ]&&touch "$clipfile" 2>/dev/null&&break
done

show_usage () {
	cat >&2 <<EOF
Usage: $SCRIPTNAME [text]
Set dummy clipboard ($clipfile) text. The text to set is either supplied as arguments or read from stdin if no arguments are given."
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

if [ $# = 0 ]; then
	cat
else
	echo -n "$@"
fi > "$clipfile"

