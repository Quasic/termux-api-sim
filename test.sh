#!/bin/dash
cd -- "$(dirname -- "$0")" || exit 1
r=0
fail(){
	printf ^^^^^^^^^^^^^%s^^^^^^^^^^^^\\n "$1"
	l="$1
$l"
	r=1
}
run(){
	printf %s\\n "$*" >&2
	"$@" </dev/null||fail "$* exit code $?"
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
		chk "$cmd $f checkbox -v random@" "$ch" "$n" "$ni"
		chk "$cmd $f radio -v random@" "$y" "$n" "$ni"
		chk "$cmd $f sheet -v random@" "$sh" "$n" "$ni"
		chk "$cmd $f spinner -v random@" "$y" "$n" "$ni"
		run "$cmd" "$f";;
	*-torch.sh) run "$cmd" "$f" off;;
	*) run "$cmd" "$f"
	esac
done
if [ 0 = "$r" ]
then printf 'Pass All\n'
else printf 'Failures:\n%s' "$l"
fi
exit "$r"
