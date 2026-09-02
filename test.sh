#!/bin/dash
cd -- "$(dirname -- "$0")" || exit 1

exec </dev/null

for f in "${TERMUX_CLIPFILE:-${TERMUX_SIM_DIR:-/dev/shm}/termux.clip}" /tmp/termux.clip "${HOME:-~}/termux.clip"
do
	if [ -z "$clipfile" ]
	then touch "$f"&&clipfile="$f"&&break
	elif [ -f "$f" ]
	then
		printf 'Unused clipfile found at %s with contents:\n' "$f"
		cat "$f"
		l="Warning: Unused clipfile $f
$l"
	fi
done
clipfilecontents=$(cat "$clipfile")
printf 'Clipfile: %s Contents:\n%s\n' "$clipfile" "$clipfilecontents"

r=0
fail(){
	printf ^^^^^^^^^^^^^%s^^^^^^^^^^^^\\n "$1"
	l="Error: $1
$l"
	r=1
}
run(){
	printf %s\\n "$*" >&2
	"$@"||fail "$* exit code $?"
}
chk(){
	local cmd="$1"
	shift
	local c
	local s
	printf %s\\n "$cmd"
	s=$(eval "$cmd")||fail "$cmd exit code $?"
	for c in "$@"
	do [ "$c" = "$s" ]&&printf Pass\\n&&return 0
		#printf %s\\n "$c$s"
	done
	fail "$cmd result $s"
	return 1
}
for f in ./*.sh scripts/*.sh
do bash -n "$f"||fail "bash -n $f"
done
if command -v shellcheck
then shellcheck ./*.sh scripts/*.sh||fail shellcheck
fi
if dpkg-query -L termux-api >/dev/null
then
	for f in scripts/*.sh
	do
		f="${f#*/}"
		if command -v "${f%.sh}"
		then bash cmpui.sh "$f" -h||fail "cmpui $f"
		else fail "real $f missing on termux"
		fi
	done
else printf 'Not running on termux, skipping comparison\n'
fi
run bash -c 'source scripts/termux-speech-to-text.sh'
t1="testing 1,2,3..."
ta="testing again 1,2, a 1 2 3 4..."
for f in scripts/*.sh
do
	case "$(sed Nq "$f" 2>/dev/null)" in
	*dash*) cmd=dash;;
	*bash*) cmd=bash;;
	*sh*) cmd='sh';;
	*) cmd=bash
	esac
	case "$f" in
	*-dialog.sh)
		for p in -l confirm counter date speech text -n -mp time
		do run "$cmd" "$f" "$p"
		done
		y='{
  "code": -1,
  "text": "random@",
  "index": 0
}'
		n='{
  "code": -2,
  "text": ""
}'
		ni='{
  "code": -2,
  "text": "",
  "index": 0
}'
		sh='{
  "code": 0,
  "text": "random@",
  "index": 0
}'
		ch='{
  "code": -1,
  "text": "[random@]",
  "values": [
    {
      "index": 0,
      "text": "random@"
    }
  ]
}'
		ch0='{
  "code": -1,
  "text": "[]"
}'
		chk "$cmd $f checkbox -v random@" "$ch" "$n" "$ni" "$ch0"
		chk "$cmd $f radio -v random@" "$y" "$n" "$ni"
		chk "$cmd $f sheet -v random@" "$sh" "$n" "$ni"
		chk "$cmd $f spinner -v random@" "$y" "$n" "$ni"
		# test when source fail
		for d in /dev/shm /tmp "$TEMP" "$TMP"
		do [ -d "$d" ]&&cp "$f" "$d/termux-dialog.sh"&&break
			d=''
		done
		if [ -z "$d" ]
		then printf 'Skipping dialog unsourced stt test\n'
		else run "$cmd" "$d/termux-dialog.sh" speech -t index@99
			rm "$d/termux-dialog.sh"
		fi
		run "$cmd" "$f";;
	*-toast.sh)
		chk "TERMUX_TOASTFILE=/dev/fd/1 $cmd $f" '@TERMUX_PREFIX@/libexec/termux-api Toast  '
		chk "TERMUX_TOASTFILE=/dev/fd/1 $cmd $f '$t1'" "@TERMUX_PREFIX@/libexec/termux-api Toast  $t1"
		chk "TERMUX_TOASTFILE=/dev/fd/1 $cmd $f" "@TERMUX_PREFIX@/libexec/termux-api Toast  $ta" <<EOF
$ta
EOF
	;;
	*-torch.sh)
		chk "TERMUX_TORCHFILE=/dev/fd/1 $cmd $f on" '@TERMUX_PREFIX@/libexec/termux-api Torch --ez enabled true'
		chk "TERMUX_TORCHFILE=/dev/fd/1 $cmd $f off" '@TERMUX_PREFIX@/libexec/termux-api Torch --ez enabled false';;
	*-clipboard-get.sh)
		chk "TERMUX_CLIPFILE=/dev/fd/0 $cmd $f" ''
		chk "TERMUX_CLIPFILE=/dev/fd/0 $cmd $f" "$t1" <<EOF
$t1
EOF
	;;
	*-clipboard-set.sh)
		chk "TERMUX_CLIPFILE=/dev/fd/1 $cmd $f" ''
		chk "TERMUX_CLIPFILE=/dev/fd/1 $cmd $f '$t1'" "$t1"
		chk "TERMUX_CLIPFILE=/dev/fd/1 $cmd $f" "$ta" <<EOF
$ta
EOF
	;;
	*) run "$cmd" "$f"
	esac
done
if [ "$clipfilecontents" != "$(cat "$clipfile")" ]
then
	printf 'Clipfile contents changed to:\n'
	cat "$clipfile"
	fail 'clipfile changed'
else printf 'Clipfile Pass\n'
fi
if [ 0 = "$r" ]
then printf 'Pass All\n'
else printf 'Failures:\n%s' "$l"
fi
exit "$r"
