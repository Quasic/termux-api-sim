#!/bin/bash
set -e -u

DEFAULT_WIDGET="text"

SCRIPTNAME=termux-dialog
show_usage() {
    echo "Usage: $SCRIPTNAME widget [options]"
    echo "Simulate user input w/ different widgets! Default: $DEFAULT_WIDGET"
    echo "   -h, help   Show this help"
    echo "   -l, list   List all widgets and their options"
    echo "   -t, title  Set title of input dialog (optional)"
    exit 0
}

declare -a widgets=("confirm" "checkbox" "counter" "date" "radio" "sheet" "spinner" "speech" "text" "time")

# Descriptions for various options that multiple widgets can use
OPT_HINT_DESC="[-i hint] text hint (optional)"
OPT_MULTI_LINE_DESC="[-m] multiple lines instead of single (optional)"
OPT_PASS_DESC="[-p] enter input as password (optional)"
OPT_NUMERIC_DESC="[-n] enter input as numbers (optional)"
OPT_TITLE_DESC="[-t title] set title of dialog (optional)"
OPT_RANGE_DESC="[-r min,max,start] comma delim of (3) numbers to use (optional)"
OPT_VALUES_DESC="[-v \",,,\"] comma delim values to use (required)"
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


# Show usage help for specific widget
widget_usage () {
    echo -n -e "$1 - "

    case "$1" in
        "confirm")
            echo "Show confirmation dialog"
            echo "    $OPT_HINT_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "checkbox")
            echo "Select multiple values using checkboxes"
            echo "    $OPT_VALUES_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "counter")
            echo "Pick a number in specified range"
            echo "    $OPT_RANGE_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "date")
            echo "Pick a date"
            echo "    $OPT_TITLE_DESC"
            echo "    $OPT_DATEFORMAT_DESC"
            ;;
        "radio")
            echo "Pick a single value from radio buttons"
            echo "    $OPT_VALUES_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "sheet")
            echo "Pick a value from sliding bottom sheet"
            echo "    $OPT_VALUES_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "speech")
            echo "Obtain speech using device microphone"
            echo "    $OPT_HINT_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "spinner")
            echo "Pick a single value from a dropdown spinner"
            echo "    $OPT_VALUES_DESC"
            echo "    $OPT_TITLE_DESC"
            ;;
        "text")
            echo "Input text (default if no widget specified)"
            echo "    $OPT_HINT_DESC"
            echo "    $OPT_MULTI_LINE_DESC*"
            echo "    $OPT_NUMERIC_DESC*"
            echo "    $OPT_PASS_DESC"
            echo "    $OPT_TITLE_DESC"
            echo "       * cannot use [-m] with [-n]"
            ;;
        "time")
            echo "Pick a time value"
            echo "    $OPT_TITLE_DESC"
            ;;
        *)
            echo "    Unknown usage for '$1'"
            ;;
    esac
}

# List all widgets
list_widgets() {
    echo "Supported widgets:"
    echo

    for w in "${widgets[@]}"; do
        widget_usage "$w"
        echo
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

code=''
text=''
index=''
error=''
incomp=0

trysimread(){
	case "$1" in
	cancel|no) code=-2;return 0;;
	yes) code=-1;return 0;;
	pick\ *) code=0;text="${1%pick }";return 0;;
	turn) code=-2;incomp=1;return 0;;
	random) return 0;;
	esac
	return 1
}
trysimread "$TERMUX_DIALOG_SIM"||trysimread "$OPT_T"||trysimread "$OPT_I"

case "$WIDGET" in
confirm)
	if [ "$code" = '' ]
	then code=$(((RANDOM&1)-2))
	fi
	if [ "$code" = -1 ]
	then text=yes
	else text=no
	fi;;
*)
ARG_W="--es input_method"

# Set options, ensuring whitespace isn't lost
echo "w  $ARG_W $WIDGET"
echo "i $ARG_I $OPT_I"
echo "t $ARG_T $OPT_T"
echo "r $ARG_R $OPT_R"
echo "v $ARG_V $OPT_V"
echo "m $ARG_M $OPT_M"
echo "p $ARG_P $OPT_P"
echo "n $ARG_N $OPT_N"
echo "d  $ARG_D $OPT_D"

printf %s\\n "$*"
esac

# better to use jq or python or something but this avoids dependencies for now
json_quote_sed() {
    sed \
            -e 's/\\/\\\\/g' \
            -e 's/"/\\"/g' \
            -e 's/	/\\t/g' |
    sed ':a;N;$!ba;s/\n/\\n/g'
}


printf '{
 code: %i,
 text: "%s"' "$code" "$(json_quote_sed <<<"$text")"
[ '' = "$index" ]||printf ',
 index: %i' "$index"
# items
[ '' = "$error" ]||printf ',
error: "%s"' "$(json_quote_sed <<<"$error")"
[ 0 = "$incomp" ]||printf '
}
'
