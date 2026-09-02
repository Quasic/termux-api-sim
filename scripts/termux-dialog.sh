#!/bin/bash
set -e -u

DEFAULT_WIDGET="text"

SCRIPTNAME=termux-dialog
show_usage() {
	cat >&2 <<EOF
Usage: $SCRIPTNAME [widget] [options]
Simulate user input w/ different widgets! Default: $DEFAULT_WIDGET
   [-h] Show this help
   [-l] List all widgets and their options
   $OPT_TITLE_DESC

This simulation returns a random result.
Sim filters limit the allowed responses.
A sim filter may be given in \$TERMUX_DIALOG_SIM, -t, or -i,
in that order of precedence. Additionally, each item in -v may be one.
Example Filters:
no@ or cancel@ chooses to cancel if that is an option
yes@ or pick@ try to not cancel
maybe@ or random@ explicitly choose randomly
pick@<option> chooses that option if found
index@<#> choose option with that index# or other numeric parameter
turn@ simulate bugged output as when changing orientation in old versions
Each widget uses these a little differently.
See their list and individual help for more specific info:
$SCRIPTNAME -l
$SCRIPTNAME <Widget> -h
EOF
    exit 0
}

declare -a widgets=("confirm" "checkbox" "counter" "date" "radio" "sheet" "spinner" "speech" "text" "time")

# Descriptions for various options that multiple widgets can use
OPT_HINT_DESC="[-i hint] text hint (used for sim filter if not -t title, optional)"
OPT_MULTI_LINE_DESC="[-m] multiple lines instead of single (optional)"
OPT_PASS_DESC="[-p] enter input as password (optional)"
OPT_NUMERIC_DESC="[-n] enter input as numbers (optional)"
#shellcheck disable=SC2016
OPT_TITLE_DESC='[-t filter] Sim filter if not in $TERMUX_DIALOG_SIM (optional)
(-t title is dialog title in real version)'
OPT_RANGE_DESC="[-r min,max,start] comma delim of (3) numbers to use (optional)"
OPT_VALUES_DESC="[-v \",,,\"] comma delim values to use (required)
special values:
yes@ or pick@ will choose or check that item
no@ will avoid checking or choosing that item
maybe@ or random@ may or may not choose or check that item
otherwise, the main filter applies"
OPT_DATEFORMAT_DESC="[-d \"dd-MM-yyyy k:m:s\"] SimpleDateFormat Pattern for date widget output (optional)"

# Widget hints
ARG_I=""
OPT_I=""

# Text widget multiline
ARG_M=""
OPT_M=""

# Text widget numeric
ARG_N=""
OPT_N=""

# Counter range
ARG_R=""
OPT_R=""

# Text widget input as password
ARG_P=""
OPT_P=""

# Dialog title (supported by all widgets)
ARG_T=""
OPT_T=""

# Values for list-type widgets
OPT_V=""
ARG_V=""

# Date output format (supported by date widget)
ARG_D=""
OPT_D=""

# Widget type
ARG_W=""
WIDGET=""

# Flags for detecting invalid option combinations
HINT_FLAG=1
MULTI_LINE_FLAG=2
PASS_FLAG=4
RANGE_FLAG=8
VALUES_FLAG=16
NUM_FLAG=32

FLAGS=0


# Show usage help for a specific widget
widget_usage() {
    local widget=$1

    case "$widget" in
        confirm)
            cat <<EOF
$widget - Show a confirmation dialog

Options:
  $OPT_HINT_DESC
  $OPT_TITLE_DESC

Simulation filters:
  yes@                  Return yes
  no@ or cancel@        Return no
  pick@yes              Return yes
  pick@no               Return no
EOF
            ;;

        checkbox)
            cat <<EOF
$widget - Select zero or more values using checkboxes

Options:
  $OPT_VALUES_DESC
  $OPT_TITLE_DESC

Simulation filters:
  yes@                  Check a value and choose ok
  no@                   Check no values
  maybe@ or random@     Randomly check a value
  pick@[index,...]      Check values by zero-based index
  pick@[text,...]       Check values by displayed text
  cancel@               Cancel the dialog
EOF
            ;;

        counter)
            cat <<EOF
$widget - Pick a number in a specified range

Options:
  $OPT_RANGE_DESC

The range consists of minimum, maximum, and starting values:
  -r min,max,start

Defaults:
  Minimum: 0
  Maximum: 100
  Start:   50

  $OPT_TITLE_DESC

Simulation filters:
  index@number          Use the specified number
  cancel@ or no@        Cancel the dialog
EOF
            ;;

        date)
            cat <<EOF
$widget - Pick a date (default is within 35 yeats of now)

Options:
  $OPT_DATEFORMAT_DESC
  $OPT_TITLE_DESC

Simulation filters:
  cancel@ or no@        Cancel the dialog
  yes@                  Tries not to cancel
  pick@<date>           Uses this date (uses date -d <date>)
  index@<#>             Picks a date within # days of now (uses date -d "... days")
EOF
            ;;

        radio)
            cat <<EOF
$widget - Pick one value from a group of radio buttons

Options:
  $OPT_TITLE_DESC
  $OPT_VALUES_DESC

Simulation filters:
  yes@                  Select the first eligible value
  pick@text             Select the value matching text
  index@number          Select the value at the zero-based index
  maybe@ or random@     Randomly select a value
  no@ or cancel@        Cancel the dialog
EOF
            ;;

        sheet)
            cat <<EOF
$widget - Pick one value from a sliding bottom sheet

Options:
  $OPT_TITLE_DESC
  $OPT_VALUES_DESC

Simulation filters:
  yes@ or pick@         Select the first eligible value
  pick@text             Select the value matching text
  index@number          Select the value at the zero-based index
  maybe@ or random@     Randomly select a value
  no@ or cancel@        Cancel the dialog
EOF
            ;;

        speech)
            cat <<EOF
$widget - Obtain speech input using the device microphone

Options:
  $OPT_HINT_DESC
  $OPT_TITLE_DESC

Simulation filters:
  cancel@ or no@        Cancel the dialog
  turn@                 Simulate an orientation-change response

If available, termux-speech-to-text.sh is sourced to generate speech-like
responses. Otherwise, simulated text is generated locally.
EOF
            ;;

        spinner)
            cat <<EOF
$widget - Pick one value from a dropdown spinner

Options:
  $OPT_TITLE_DESC
  $OPT_VALUES_DESC

Simulation filters:
  yes@ or pick@         Select the first eligible value
  pick@text             Select the value matching text
  index@number          Select the value at the zero-based index
  maybe@ or random@     Randomly select a value
  no@ or cancel@        Cancel the dialog
EOF
            ;;

        text)
            cat <<EOF
$widget - Enter text (the default widget)

Options:
  $OPT_HINT_DESC
  $OPT_MULTI_LINE_DESC
  $OPT_NUMERIC_DESC
  $OPT_PASS_DESC
  $OPT_TITLE_DESC

Notes:
  -m and -n cannot be used together.
  -p masks the entered value as a password.
  -n generates or accepts numeric input.
  -m allows multiline input.

Simulation filters:
  cancel@ or no@        Cancel the dialog
  index@number          Generate text with approximately that length
EOF
            ;;

        time)
            cat <<EOF
$widget - Pick a time value

Options:
  $OPT_TITLE_DESC

Output format:
  HH:MM using a 24-hour clock

Simulation filters:
  cancel@ or no@        Cancel the dialog
EOF
            ;;

        *)
            printf "Unknown widget: %s\n" "$widget"
            return 1
            ;;
    esac
}

# List all widgets
list_widgets() {
    printf 'Supported widgets:\n\n'

    local w
    for w in "${widgets[@]}"; do
        widget_usage "$w"
        printf \\n
    done
}

# Checks to see if widgets array contains specified widget
has_widget () {
    for w in "${widgets[@]}"; do
        [ "$w" == "$1" ] && return 0
    done
    return 1
}

set_flag () {
    FLAGS=$((FLAGS | $1));
}

# Convenience method to get all supported options, regardless of specified widget
# NOTE: Option combination validation doesn't occur here
parse_options() {
    while getopts :hlmnpr:i:t:d:v: option
    do
        case "$option" in
            h) show_usage ;;
            l) list_widgets; exit 0;;
            i) ARG_I="--es input_hint"; OPT_I="$OPTARG"; set_flag $HINT_FLAG; ;;
            m) ARG_M="--ez multiple_lines"; OPT_M="true"; set_flag $MULTI_LINE_FLAG; ;;
            p) ARG_P="--ez password"; OPT_P="true"; set_flag $PASS_FLAG; ;;
            n) ARG_N="--ez numeric"; OPT_N="true"; set_flag $NUM_FLAG; ;;
            t) ARG_T="--es input_title"; OPT_T="$OPTARG" ;;
            d) ARG_D="--es date_format"; OPT_D="$OPTARG";;
            v) ARG_V="--es input_values"; OPT_V="$OPTARG"; set_flag $VALUES_FLAG; ;;
            r) ARG_R="--eia input_range"; OPT_R=$OPTARG; set_flag $RANGE_FLAG; ;;
            ?) echo "$SCRIPTNAME: illegal option -$OPTARG"; exit 1;
        esac
    done
}

options_error () {
    echo -e "ERROR: Invalid option(s) detected for '$1'\n"
    echo "Usage '$1'"
    widget_usage "$1"
    exit 1
}

if [ $# -eq 0 ]; then
    WIDGET=$DEFAULT_WIDGET
# First argument wasn't a widget
elif ! has_widget "$1"; then
    # we didn't receive a widget as an argument, check to see if we
    # at least options (even if they're illegal)
    if ! [[ $1 =~ -[a-z] ]]; then
        echo -e "ERROR: Illegal argument $1\n"
        show_usage
    fi
    WIDGET="$DEFAULT_WIDGET"
else
    WIDGET="$1"
    shift
fi

parse_options "$@"
shift $((OPTIND - 1))

# Ensure proper option combinations for the specific type of widget
case "$WIDGET" in
    # Text (default) if no widget specified
    "text")
        if [ $((FLAGS & (RANGE_FLAG | VALUES_FLAG))) -ne 0 ]; then
            options_error "$WIDGET"
        fi

        if [ $((FLAGS & MULTI_LINE_FLAG)) -ne 0 ] && [ $((FLAGS & NUM_FLAG)) -ne 0 ]; then
            options_error "$WIDGET"
        fi
        ;;

    "confirm")
        if [ $((FLAGS & (MULTI_LINE_FLAG | PASS_FLAG | RANGE_FLAG | VALUES_FLAG | NUM_FLAG))) -ne 0 ]; then
            options_error "$WIDGET"
        fi
        ;;

    "counter")
        if [ $((FLAGS & (MULTI_LINE_FLAG | PASS_FLAG | VALUES_FLAG | NUM_FLAG))) -ne 0 ]; then
            options_error "$WIDGET"
        fi
        ;;

    "speech")
        if [ $((FLAGS & (MULTI_LINE_FLAG | PASS_FLAG | RANGE_FLAG | VALUES_FLAG | NUM_FLAG))) -ne 0 ]; then
            options_error "$WIDGET"
        fi
        ;;

    "date" | "time")
        if [ $((FLAGS & (HINT_FLAG | MULTI_LINE_FLAG | PASS_FLAG | RANGE_FLAG | VALUES_FLAG | NUM_FLAG))) -ne 0 ]; then
            options_error "$WIDGET"
        fi
        ;;

    "checkbox" | "radio" | "sheet" | "spinner")
        if [ "$ARG_V" == "" ]; then
            echo "ERROR: '$WIDGET' must be called with $OPT_VALUES_DESC"
            exit 1
        fi

        if [ $((FLAGS & (HINT_FLAG | MULTI_LINE_FLAG | PASS_FLAG | RANGE_FLAG | NUM_FLAG))) -ne 0 ]; then
            options_error "$WIDGET"
        fi
        ;;

    *)
        echo "$SCRIPTNAME: unsupported widget '$WIDGET'"; show_usage ;;
esac

# All valid args should be consumed by this point
if [ $# -gt 0 ]; then
    echo "ERROR: Too many arguments!"
    show_usage
fi

ARG_W="--es input_method"

dump="codes:
w $ARG_W $WIDGET
i $ARG_I $OPT_I
t $ARG_T $OPT_T
r $ARG_R $OPT_R
v $ARG_V $OPT_V
m $ARG_M $OPT_M
p $ARG_P $OPT_P
n $ARG_N $OPT_N
d $ARG_D $OPT_D"

# https://github.com/termux/termux-api/blob/master/app%2Fsrc%2Fmain%2Fjava%2Fcom%2Ftermux%2Fapi%2Fapis%2FDialogAPI.java

code=''
text=''
index=''
values=''
error=''
incomp=''
look=''

trysimread(){
	case "$1" in
	'') return 1;;
	cancel@|no@) code=-2;return 0;; #TODO: checkbox can have no mean no checks
	yes@) code=-1;return 0;;
	pick@*) code=-1;text="${1#pick@}";look=text;return 0;;
	index@*)
		index="${1#index@}"
		case "$index" in
		*[^0-9]*) index='';return 1;;
		*) code=-1;look=index;return 0;;
		esac;;
	turn@) code=-2;incomp=1;return 0;;
	random@|maybe@) return 0;;
	esac
	return 1
}
trysimread "${TERMUX_DIALOG_SIM:-}"||trysimread "$OPT_T"||trysimread "$OPT_I"||: rnd

getnum(){
	NUM=$((RANDOM&7))
	while ((RANDOM&7<5))&&((NUM<32000))
	do ((NUM+=(RANDOM&3)+1))
	done
}

# better to use jq or python or something but this avoids dependencies for now
json_quote() {
	Q="${1//\\/\\\\}"
	Q="${Q//
/\\n}"
	Q="${Q//\"/\\\"}"
	Q="${Q//	/\t}"
}

case "$WIDGET" in
confirm)
	if [ "$code" = '' ]
	then code=$(((RANDOM&1)-2))
	fi
	if [ "$code" = -1 ]&&[ "$text" != no ]
	then text=yes
	else text=no
	fi
	index=0
	code=0;;
counter)
	if [ -z "$ARG_R" ]
	then
		min=0
		max=100
		counter=50
		extra=''
	else IFS=, read -r min max counter extra <<<"$OPT_R"
	fi
	if [ -n "$extra" ]||[ -z "$counter" ]||[[ "$counter" =~ [^0-9] ]]||[ -z "$min" ]||[[ "$min" =~ [^0-9] ]]||[ -z "$max" ]||[[ "$max" =~ [^0-9] ]]
	then
		error="Invalid range! Must be 3 int values!";
		code=-2
	else
		if [ "$min" -gt "$max" ]
		then
			tmp=$min
			min=$max
			max=$tmp
		fi
		# counter can extend past bounds
		[ "$counter" -lt "$min" ]&&min="$counter"
		[ "$counter" -gt "$max" ]&&max="$counter"
		if [ "$code" = '' ]
		then
			text=$(( min + RANDOM % (max - min + 2) ))
			if [ "$text" -gt "$max" ]||[ "$text" -lt "$min" ]
			then
				code=-2
				text=''
			else code=-1
			fi
		fi
		if [ "$code" = -1 ]
		then
			case "$text" in
			*[^0-9]*) text=$(( min + RANDOM % (max - min + 1) ));;
			*)
				if [ "$text" -gt "$max" ]||[ "$text" -lt "$min" ]
				then text=$(( min + RANDOM % (max - min + 1) ))
				fi
			esac
		else
			code=-2
			text=''
		fi
	fi;;
checkbox)
 [ '' = "$code" ]&&if ((RANDOM%50==0))
 then code=-2
 else code=-1
 fi
 if [ -2 = "$code" ]
 then text=''
 else
	V=()
	Y=()
	declare -A B
	while read -rd, v
	do
		i=${#V[@]}
		V[i]="$v"
		B[$v]+="$i,"
		case "$v" in
		yes@) Y[i]=1;;
		no@) Y[i]=0;;
		maybe@|random@) Y[i]=$((RANDOM&1));;
		*)
			if [ -z "$text" ]&&(((RANDOM&3)==0))
			then Y[i]=1
			else Y[i]=''
			fi
		esac
	done <<<"$OPT_V,"
	if [[ "$text" = \[*\] ]]
	then
		t="${text#\[}"
		while read -rd, v
		do
			# not quite json unquote, but for now
			printf -v v %b "$v"
			if [ -n "${B[$v]}" ]
			then
				read -rd, -a A<<<"${B[$v]}"
				for ((i=0;i<${#A[@]};i++))
				do
					[ -z "${Y[A[i]]}" ]&&{
						Y[A[i]]=1
						break
					}
				done
			fi
		done <<<"${t%\]},"
	fi
	text=''
	for ((i=0;i<${#V[*]};i++))
	do
		if [ 1 = "${Y[i]:-}" ]
		then
			json_quote "${V[i]}"
			if [ -z "$text" ]
			then text="[$Q"
			else text+=", $Q"
			fi
			[ -z "$values" ]||values+='    },
    {
'
			printf -v values '%s      "index": %i,
      "text": "%s"
' "$values" "$i" "$Q"
		fi
	done
	if [ -n "$text" ]
	then text+=']'
	else text='[]'
	fi
 fi
 index='';;
radio|sheet|spinner)
	V=()
	while read -rd, v
	do
		i=${#V[*]}
		V[i]="$v"
		case "$look" in
		text) [ "$text" = "$v" ]&&index="$i";;
		index) [ "$index" = "$i" ]&&text="$v";;
		'')
			case "$v" in
			yes@|pick@)
				code=-1
				index="$i"
				text="$v"
				look=found
				break;;
			maybe@|random@)
				if ((RANDOM&1==0))
				then
					code=-1
					index="$i"
					text="$v"
					look=found
					break
				fi;;
			#no@ handled later
			esac
		esac
	done <<<"$OPT_V,"
	[ -z "$index" ]||[ "$index" -lt "${V[*]}" ]||index=''
	[ -z "$index" ]&&[ -n "$text" ]&&text=''
	if [ "$code" = '' ]
	then
		if [ -z "$index" ]
		then
			index=$((RANDOM%(2+${#V[*]})))
			if [ "$index" -lt "${#V[*]}" ]
			then
				text="${V[index]}"
				if [ no@ = "$text" ]
				then
					code=-2
					text=''
					# leave index
				else code=-1
				fi
			else
				code=-2
				index=''
			fi
		else code=$(((RANDOM&3)-2))
		fi
	fi
	if [ "$code" = -2 ]
	then text=''
	else
		if [ sheet = "$WIDGET" ]
		then code=0
		else code=-1
		fi
		# look for ",$text," in ",$OPT_V," ?

	fi;;
text|speech)
	if [ "$code" = -2 ]
	then text=''
	elif [ -n "$ARG_N" ]
	then
		if [ -z "$text" ]||[[ "$text" =~ [^0-9] ]]
		then
			if [ $((RANDOM%50)) = 0 ]
			then
				code=-2
				text=''
			else
				getnum
				b=$NUM
				getnum

				t=''
				while ((${#t}<b+NUM))
				do printf -v t %s%09i "$t" $(((RANDOM*32768+RANDOM)%1000000000))
				# 9 digits from 2 randoms is better ratio than 4 from 1 or 13 from 3
				done

				case $((RANDOM&3)) in
				0) text="${t:0:NUM}";;
				1) text="${t:0:b}.${t:b:NUM}";;
				2) text="-${t:0:NUM}";;
				3) text="-${t:0:b}.${t:b:NUM}";;
				esac
				code=-1
			fi
		fi
	elif [ -z "$text" ]
	then
		if [ -n "$index" ]
		then c="$index"
		elif [ "$WIDGET" = speech ]
		then c=$((RANDOM&16#2fff))
		elif [ -n "$ARG_P" ]
		then c=$((8+(RANDOM&31)))
		elif [ -n "$ARG_M" ]
		then c=$((RANDOM&16#ffff))
		else c=$((RANDOM&16#3ff))
		fi
		if [ 0 = $((RANDOM&63)) ]
		then code=-2
		else
			#shellcheck source=scripts/termux-speech-to-text.sh
			if source "$(dirname -- "${BASH_SOURCE[0]}")/termux-speech-to-text.sh"
			then sourced=y
			else sourced=''
			fi
			lorem=(lorem ipsum dolor amet consectetur adipiscing elit sed eiusmod tempor incididunt ut labore et dolore magna aliqua enim ad minim veniam quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo consequat Duis aute irure in reprehenderit voluptate velit esse cillum eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt culpa qui officia deserunt mollit anim id est laborum)
lat_starts=(al ba ca de el fa ga la lo ma na pa ra sa ta va)
lat_middles=(be ci da fe li mo ne pa re si ta ve)
lat_endings=(us um i a en is or ae)

t=\$\'\"\`\\0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
t+=' ?;:-!¿¡@#%&*()[]{}<>《》¤▪︎☆♧◇♡♤■□●○•°₩¥£€|~_/=÷×+^.,öøōőœ'
t+='ⁿ¹²³⁴⁵⁶⁷⁸⁹⁰⅞⅚⅝⅘¾⅗⅜⅔⅖½⅓¼⅕⅙⅛ýþťțţŕřèéêëēėęěĕəùúûüūůűųìíîïīįıòóôõ'
t+='àáâãäåæāăąªß§śšşďđģğķĺļľłñńņňçćčźżž'
t+='🥭🍍🍌🍋🍊🍉🍈🍇🍒🍎🍏🍐🍓😋😛🤩😍🥰😇😊😉🙃🙂😂🤣😅😆😁😄😃😀🏁'

			[ -n "$ARG_M" ]&&text="$dump"

			while [ ${#text} -lt "$c" ]
			do
				if [ text = "$WIDGET" ]&&(((RANDOM&7)==0))
				then # non-speech: emojis, codes
					wl=$((RANDOM&255))
					w=''
					while [ ${#w} -lt $wl ]
					do w+="${t:RANDOM%${#t}:RANDOM%3+1}"
					done
				elif [ -z "$sourced" ]||(((RANDOM&7)==0))
				then # unsourced speech
					w="${lorem[RANDOM%${#lorem[@]}]}"
					L=$((RANDOM&15))
					for ((i=0;i<L;i++))
					do
						if ((RANDOM&1))
						then w+=" ${lorem[RANDOM%${#lorem[@]}]}"
						else
        						w+=" ${lat_starts[RANDOM % ${#lat_starts[@]}]}"
							((RANDOM&1))&&w+="${lat_middles[RANDOM % ${#lat_middles[@]}]}"
        						w+="${lat_endings[RANDOM % ${#lat_endings[@]}]}"
						fi
					done
				else # speech from stt lib
					if ((RANDOM&1))
					then
						setSentence
						w="$Sentence"
					else
						setQuestion
						w="$Question"
					fi
					((RANDOM&1))||w+=' '
				fi
				if [ -n "$ARG_M" ]&&[ $((RANDOM&7)) = 0 ]
				then text+="$w
"
				else text+="$w "
				fi
			done
			(((RANDOM&3)==0))||text="${text% }"
			code=-1
		fi
	fi
	index='';;
time)
	if [ "$code" = '' ]
	then
		t=$((RANDOM%1500))
		if [ "$t" -gt 1439 ]
		then code=-2
		else
			code=-1
			printf -v text %02i:%02i "$((t/60))" "$((t%60))"
		fi
	fi
	if [ "$code" = -1 ]
	then
		case "$text" in
		[01][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]) :;;
		*) printf -v text %02i:%02i "$((RANDOM%24))" "$((RANDOM%60))"
		esac
	else text=''
	fi
	index='';; # real returns random index sometimes (last one sent)
date)
	if [ "$look" = index ]
	then
		if ((RANDOM&1))
		then offset=-1
		else offset=1
		fi
		text=$(date -d "$(((RANDOM%index)*offset)) days" '+%a %b %d 00:00:00 %Z %Y')
		code=-1
	elif [ "$look" = text ]
	then
		# Validate and normalize a simulated date selection.
		if ! text=$(date -d "$text" '+%a %b %d 00:00:00 %Z %Y')
		then
			code=-2
			text=''
		fi
	elif [ "$code" = -2 ]
	then text=''
	else
		# Randomly simulate either cancellation or a date within ±34 years.
		if [ "$code" != -1 ]&&[ $((RANDOM % 50)) = 0 ]
		then
			code=-2
			text=''
		else
			now=$(date +%s)
			offset=$((RANDOM * 32768 + RANDOM))
			[ $((RANDOM & 1)) = 0 ] && offset=$((offset * -1))

			if ! text=$(date -d "@$((now + offset))" '+%a %b %d 00:00:00 %Z %Y')
			then
				code=-2
				text=''
			else
				code=-1
			fi
		fi
	fi
	index='';;
*) error="unknown widget: $WIDGET
$dump"
esac

json_quote "$text"

printf '{
  "code": %i,
  "text": "%s"' "$code" "$Q"
[ '' = "$index" ]||printf ',
  "index": %i' "$index"
if [ -n "$values" ]
then
	printf ',
  "values": [
    {
%s    }
  ]' "$values"
fi
if [ -n "$error" ]
then
	json_quote "$error"
	printf ',
  "error": "%s"' "$Q"
fi
[ -n "$incomp" ]||printf '
}
'
