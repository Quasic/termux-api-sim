#!/bin/dash
r=0
fail(){
	printf %s^^^^^^^^^^^^^^^^^^^^^^^\\n "$1"
	r=1
}
for f in ./*.sh scripts/*.sh
do bash -n "$f"||fail "bash -n $f"
done
if command -v shellcheck
then shellcheck ./*.sh scripts/*.sh||fail shellcheck
fi
dpkg-query -L termux-api >/dev/null && for f in scripts/*.sh
do bash cmpui.sh "${f#*/}" -h||fail "cmpui $f"
done
[ 0 = "$r" ]&&printf 'Pass All\n'
exit "$r"
