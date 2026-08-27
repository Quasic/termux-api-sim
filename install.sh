#!/bin/dash

self_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 1

usage()
{
	cat <<EOF
Usage: $0 [options] [install-bin-dir]

Install scripts from:
  $self_dir/scripts

Options:
  -d, --dash PATH   Use #!PATH for scripts using dash
  -s, --sh PATH     Use #!PATH for scripts using sh
  -b, --bash PATH   Use #!PATH for scripts using bash
  -h, --help    Show this help message

If a shell PATH is not specified, install-bin-dir is checked for an executable with the shell name. If that is not found, command -v is used, and if that fails, the shebang is unchanged.

If install-bin-dir is omitted, scripts are installed in:
  $self_dir/bin

Notice: If this is accidentally installed in termux over the real termux scripts,
functionality can be restored by running:
apt install --reinstall termux-api
EOF
}

dash_shebang=
sh_shebang=
bash_shebang=
bindir=

while [ "$#" -gt 0 ]
do
	case "$1" in
		-d|-s|-b|--dash|--sh|--bash)
			option=$1
			shift

			if [ "$#" -eq 0 ] || [ "$1" = '' ]
			then
				echo "$0: $option requires a path" >&2
				exit 2
			fi

			case "$option" in
				-d|--dash) dash_shebang=$1 ;;
				-s|--sh)   sh_shebang=$1 ;;
				-b|--bash) bash_shebang=$1 ;;
			esac
			shift
			;;

		-h*|--help)
			usage
			exit 0
			;;

		--)
			shift
			if [ "$#" -gt 1 ]
			then
				echo "$0: too many arguments" >&2
				usage >&2
				exit 2
			fi
			bindir=$1
			shift
			;;

		-*)
			echo "$0: unknown option: $1" >&2
			usage >&2
			exit 2
			;;

		*)
			if [ -n "$bindir" ]
			then
				echo "$0: too many arguments" >&2
				usage >&2
				exit 2
			fi
			bindir=$1
			shift
			;;
	esac
done

if [ -z "$bindir" ]
then
	bindir=$self_dir/bin
fi

mkdir -p "$bindir" || exit 1

findsh(){
	local f="$bindir/$1"
	if [ -x "$f" ]
	then realpath "$f"
	else command -v "$1" 2>/dev/null
	fi
}
[ -z "$bash_shebang" ]&&bash_shebang=$(findsh bash)
[ -z "$dash_shebang" ]&&dash_shebang=$(findsh dash)
[ -z "$sh_shebang" ]&&sh_shebang=$(findsh sh)

for src in "$self_dir"/scripts/*.sh
do
	[ -f "$src" ] || continue

	dest=${src%.sh}
	dest=$bindir/${dest##*/}

	# Determine the shell from the source script's existing shebang.
	shebang=
	first_line=$(sed Nq "$src")

	case "$first_line" in
		*bash*) shebang=$bash_shebang ;;
		*dash*) shebang=$dash_shebang ;;
		*sh*)   shebang=$sh_shebang ;;
	esac

	if [ -n "$shebang" ]
	then
		tmp=$(
			printf '#!%s\n' "$shebang"
			sed '1d' "$src"
		)||exit 1

		printf %s "$tmp" > "$dest"||exit 1
	else
		cp "$src" "$dest" || exit 1
	fi

	chmod +x "$dest" || exit 1
done
