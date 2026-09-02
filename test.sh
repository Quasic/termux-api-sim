#!/bin/dash
cd -- "$(dirname -- "$0")" || exit 1

exec </dev/null

for f in "${TERMUX_CLIPFILE:-${TERMUX_SIM_DIR:-/dev/shm}/termux.clip}" /tmp/termux.clip "${HOME:-~}/termux.clip"
do
	if [ -f "$f" ]
	then printf 'Removing %s for tests, contents:\n' "$f"&&cat "$f"&&printf '' >"$f"&&[ -z "$clipfile" ]&&clipfile="$f"
	elif [ -z "$clipfile" ]
	then touch "$f"&&clipfile="$f"
	fi
done
printf 'Clipfile: %s\n' "$clipfile"

r=0
fail(){
	printf ^^^^^^^^^^^^^%s^^^^^^^^^^^^\\n "$1"
	l="$1
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
		for p in -l confirm counter date speech text -n -m time
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
		else run "$cmd" "$d/termux-dialog.sh"
			rm "$d/termux-dialog.sh"
		fi
		run "$cmd" "$f";;
	*-torch.sh) run "$cmd" "$f" off;;
	*-clipboard-set.sh)
		run "$cmd" "$f"
		run "$cmd" "scripts/termux-clipboard-get.sh"
		t="testing 1,2,3..."
		run "$cmd" "$f" "$t"
		[ "$t" = "$(run "$cmd" "scripts/termux-clipboard-get.sh"|tee /dev/fd/2)" ]||fail "clipboard get differs from $t"
		t="testing again 1,2, a 1 2 3 4..."
		run "$cmd" "$f"<<EOF
$t
EOF
		[ "$t" = "$(run "$cmd" "scripts/termux-clipboard-get.sh"|tee /dev/fd/2)" ]||fail "clipboard get differs from $t";;
	*) run "$cmd" "$f"
	esac
done
printf 'Clipfile contents:\n'
cat "$clipfile"
if [ 0 = "$r" ]
then printf 'Pass All\n'
else printf 'Failures:\n%s' "$l"
fi
exit "$r"
