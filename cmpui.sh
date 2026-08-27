#!/data/data/com.termux/files/usr/bin/bash

self_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
scripts_dir=$(realpath --relative-to . "$self_dir/scripts")

usage(){
	cat >&2 <<EOF
cmpui.sh: compares actual installed termux-ui scripts to sims
usage: ${BASH_SOURCE[0]} SUFFIX PARAMS
SUFFIX is the termux-ui command (termux- may be omitted)
PARAMS are the arguments for that script
EOF
	exit 0
}

cmph(){
	r=0
	run2 "$@"
	case "$?" in
	2) r=2;;
	0)
		r=1
		printf 'helps match (sim should identify)\n' >&2
	esac
	if [ "$realq" != "$simq" ]
	then
		r=1
		printf 'exit codes differ: real %i sim %i\n' "$realq" "$simq" >&2
	fi
	[ 0 = "$r" ]&&printf 'Pass\n' >&2
	exit "$r"
}

run2(){
	printf 'cmpui.sh: note: comparing %s...\n' "$*"
	real=$("$@" 2>&1)
	realq=$?
	s="$scripts_dir/$1.sh"
	shift
	printf 'cmpui.sh: note: ... to %s\n' "$s $*"
	sim=$(
		if [ -x "$s" ]
		then "$s" "$@"
		else
			case "$(sed Nq "$s" 2>/dev/null)" in
			*dash*) dash "$s" "$@";;
			*bash*) bash "$s" "$@";;
			*sh*) sh "$s" "$@";;
			*) bash "$s" "$@"
			esac
		fi 2>&1
	)
	simq=$?
	diff -u --label termux-ui <(printf %s\\n "$real") --label Sim <(printf %s\\n "$sim")
}

[ 0 = $# ]&&usage

cmd="$1"
shift
case "$cmd" in
-h|--help) usage;;
termux-*) :;;
*) cmd="termux-$cmd"
esac

for o in "$@"
do
	case "$o" in
	-h|--help) cmph "$cmd" "$@";;
	--) break;;
	esac
done

run2 "$cmd" "$@"
diff=$?

if [ "$realq" != "$simq" ]
then
	[ 0 = "$diff" ]&&diff=1
	printf 'Exit codes differ: real %i sim %i\n' "$realq" "$simq"
fi

case "$diff" in
0) printf Pass.\\n;;
2) printf 'Errors prevented complete comparison.\n';;
esac

exit "$diff"
