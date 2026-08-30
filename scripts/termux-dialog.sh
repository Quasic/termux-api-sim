#!/bin/bash
set -e -u
# https://github.com/termux/termux-api/blob/master/app%2Fsrc%2Fmain%2Fjava%2Fcom%2Ftermux%2Fapi%2Fapis%2FDialogAPI.java

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
values=''
error=''
incomp=''
look=''

trysimread(){
	case "$1" in
	'') return 1;;
	cancel@|no@) code=-2;return 0;;
	yes@) code=-1;return 0;;
	pick@*) code=-1;text="${1#pick@}";look=text;return 0;;
	index@*)
		index="${1#index@}"
		case "$index" in
		*[^0-9]*) index='';return 1;;
		*) code=-1;look=index;return 0;;
		esac;;
	turn@) code=-2;incomp=1;return 0;;
	random@) return 0;;
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
	V=()
	Y=()
	while read -rd, v
	do
		i=${#V[*]}
		V[i]="$v"
		case "$v" in
		yes@) Y[i]=1;;
		no@) Y[i]=0;;
		maybe@|random@) Y[i]=$((RANDOM&1));;
		'') [ -z "$code" ]&&Y[i]=$((RANDOM&3));;
		esac
	done <<<"$OPT_V,"
	if [[ "$text" = [*] ]]
	then
		t="${text#[}"
		t="${t%]}"
		while read -rd, v
		do [[ "$v" =~ [^0-9] ]]||Y[v]=1
		done
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
	then
		code=-1
		text+=']'
	else code=-2
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
	# igonore -p, detect -m or -n [only used in text]
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
			beginnings=(the com con re pro de un inter)
			middles=(ma na ra la ti ven fer port)
			endings=(ing er ed ly tion ment ness able s)

			lorem=(lorem ipsum dolor sit amet consectetur adipiscing elit sed 'do' eiusmod tempor incididunt ut labore et dolore magna aliqua enim ad minim veniam quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo consequat Duis aute irure in reprehenderit voluptate velit esse cillum eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt culpa qui officia deserunt mollit anim id est laborum)
			loremlen=${#lorem[@]}

			subject=(we he she they you I it both one)
			subjectlen=${#subject[@]}
			gensubjPLURAL(){
				W="${subject[RANDOM%subjectlen]}"
				case "$W" in
				he|she|it|one) :;;
				*) PLURAL=1
				esac
			}
			adverb=(lazily happily angrily busily heavily easily gently simply terribly)
			transitive=(move ignore insult poke inspect watch imagine attack see bring consult teach blame dox wiggle jostle invoke emulate yeet visit like wash help stop shun reward award recognize criticize jumble challenge view refresh love discover evaluate discuss ask respect appreciate value call report balance check narrate encourage)
			intransitive=(dance jump go fly stare move work walk box unbox buzz play run consult teach skip agree disagree zoom sit check strut travel apologize live learn land crawl party talk)
			preposition=(with over around at by near toward behind under above below 'in front of' in on for from to about across after against along among before beneath beside between beyond during except into of off through until upon within without)
			prepositionlen=${#preposition[@]}
			getverb(){
				local I="${1:-}"
				local av
				local v
				local prep
				case $((RANDOM%3)) in
				0) av='';;
				1) av=" ${adverb[RANDOM % adverblen]}";;
				2) av=" very ${adverb[RANDOM % adverblen]}";;
				esac
				if [ $((RANDOM&1)) = 0 ]
				then
					v="${transitive[RANDOM % ${#transitive[@]}]}"
					prep=''
				else
					v="${intransitive[RANDOM %${#intransitive[@]}]}"
					prep=" ${preposition[RANDOM%prepositionlen]}"
				fi
				local past="${v%e}ed"
				local pastp="$past"
				local ing="${v%e}ing"
				local present
				case "$v" in
				*ch|*sh|*s|*x|*z) present="${v}es";;
				*[bcdfghj-np-tv-z]y) present="${v%y}ies";;
				*) present="${v}s"
				esac
				case "$v" in
				go)
					present=goes
					pastp=gone
					past=went;;
				eat)
					pastp=eaten
					past=ate;;
				fly)
					past=flew
					pastp=flown;;
				run)
					past=ran
					pastp=run;;
				sit)
					past=sat
					pastp=seated;;
				see)
					past=saw
					pastp=seen
					ing=seeing;;
				teach) past=taught;;
				bring) past=brought;;
				[bcdfghj-np-tv-z][bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz])
					past="$v${v:${#v}-1}ed"
					ing="$v${v:${#v}-1}ing";;
				esac
				case $((RANDOM%18)) in
				0) VERB="$av $past$prep";;
				1)
					if [ -z "$PLURAL" ]
					then VERB="$av $present$prep"
					else VERB="$av $v$prep"
					fi;;
				2) VERB=" will$av $v$prep";;
				3)
					if [ I = "$I" ]
					then VERB=" am$av $ing$prep"
					elif [ -n "$PLURAL" ]
					then VERB=" are$av $ing$prep"
					else VERB=" is$av $ing$prep"
					fi;;
				4) VERB=" will have been$av $ing$prep";;
				5) VERB=" will have$av $pastp$prep";;
				6) VERB=" will be$av $ing$prep";;
				7) VERB=" did$av $v$prep";;
				8)
					if [ -n "$PLURAL" ]
					then VERB=" do$av $v$prep"
					else VERB=" does$av $v$prep"
					fi;;
				9)
					if [ -n "$PLURAL" ]
					then VERB=" were$av $ing$prep"
					else VERB=" was$av $ing$prep"
					fi;;
				10) VERB="$av will $v$prep";; #metaphore n/a
				11)
					if ((RANDOM&127==0))
					then ing='' #metaphore
					else ing=" $ing$prep"
					fi
					if [ I = "$I" ]
					then VERB="$av am$ing"
					elif [ -n "$PLURAL" ]
					then VERB="$av are$ing"
					else VERB="$av is$ing"
					fi;;
				12)
					if ((RANDOM&127==0))
					then ing='' #metaphore
					else ing=" $ing$prep"
					fi
					VERB="$av will have been$ing";;
				13) VERB="$av will have $pastp$prep";; # metaphore n/a
				14)
					if ((RANDOM&127==0))
					then ing='' #metaphore
					else ing=" $ing$prep"
					fi
					VERB="$av will be$ing";;
				15) VERB="$av did $v$prep";;
				16) # metaphore n/a
					if [ -n "$PLURAL" ]
					then VERB="$av do $v$prep"
					else VERB="$av does $v$prep"
					fi;;
				17)
					if ((RANDOM&127==0))
					then ing='' #metaphore
					else ing=" $ing$prep"
					fi
					if [ -n "$PLURAL" ]
					then VERB="$av were$ing"
					else VERB="$av was$ing"
					fi;;
				esac
			}

			object=(them you me it him her us both one)
			objectlen=${#object[@]}
			adj=(quick slow large careful fearful beautiful impactful dark bright brisk careless quiet loud polite rude beautiful clear correct different final fortunate honest patient perfect recent serious sudden usual transitive intransitive proper random forceful strong colorful courageous blind deaf limp lame dumb emphatic)
			adjective=("${adj[@]}" lazy happy angry busy heavy brown white black red green blue yellow orange purple small silly lively lonely friendly lovely gentle simple terrible tiny giant)
			adjectivelen=${#adjective[@]}
			noun=(book table car goat horse cow chicken pig elephant oyster clam turkey fox cat dog gerbil yeti newt person plant amoeba worm eggplant turtle giraffe bird duck penguin bear muskrat ox donkey baby lady bus bug box quiz dish class swarm bee tomato potato goose photo piano radio play day week hour minute second millisecond month year decade century olympiad millenium word verb noun adjective adverb preposition pronoun subject object farm land party grass lawn report statement evaluation account agreement rock paper scissors knife fire deer sheep aircraft series mouse)
			for w in "${transitive[@]}" "${intransitive[@]}"
			do
				case "$w" in
				*e) w="${w}r";;
				*[^aeiou]y) w="${w%y}ier";; #space/punct. not expected to be problem only 1 char b4 end
				[bcdfghj-np-tv-z][bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]) w="$w${w:${#w}-1}er";;
				go) w=partygoer;;
				*) w="${w}er"
				esac
				noun[${#noun[@]}]=$w
			done
			nounlen=${#noun[@]}
			for w in "${adj[@]}"
			do adverb[${#adverb[@]}]="${w}ly"
			done
			adj=() #done with it
			adverblen=${#adverb[@]}
			genadjnoun(){
				local c=$((RANDOM%4))
				local i
				local n
				if [ 0 != "$c" ]
				then
					case $((RANDOM&7)) in
					1) W='very ';;
					2) W="${adverb[RANDOM % adverblen]} ";;
					3) W="very ${adverb[RANDOM % adverblen]} ";;
					4) W="very very ${adverb[RANDOM % adverblen]} ";;
					5) W="${adverb[RANDOM % adverblen]} very ${adverb[RANDOM % adverblen]} ";;
					*) W=''
					esac
				else W=''
				fi
				for ((i=0;i<c;i++))
				do
					n="${adjective[RANDOM % adjectivelen]} "
					[[ " $W" = *" $n"* ]]||W+="$n"
				done
				W+="${noun[RANDOM%nounlen]}"
			}
			genoun(){
				local i
				genadjnoun
				case "$((RANDOM%10))${W:0:1}" in
				0[aeiou]) W="an $W";;
				0*) W="a $W";;
				1*) W="one $W";;
				2*)
					case "$W" in
					scissors|deer|sheep|aircraft|series) :;;
					ox) W+=en;;
					*ch|*sh|*s|*x|*z|[tp]o[mt]ato) W+=es;;
					*[bcdfghj-np-tv-z]y) W="${W%y}ies";;
					goose) W=geese;;
					mouse) W=mice;;
					*) W+=s;
					esac
					((0==RANDOM&1))&&W="$(((RANDOM&127)+2)) $W"
					PLURAL="${1:-}";;
				3*) W="her $W";;
				4*) W="his $W";;
				5*) W="its $W";;
				6[aeiou])
					i="$W"
					genadjnoun
					W="an $i's $W";;
				6*)
					i="$W"
					genadjnoun
					W="a $i's $W";;
				7*)
					i="$W"
					genadjnoun
					W="the $W's $i";;
				8*)
					i="$W"
					genadjnoun
					W="one $W's $i";;

				*) W="the $W"
				esac
			}

t=\$\'\"\`\\0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
t+='?;:-!¿¡@#%&*()[]{}<>《》¤▪︎☆♧◇♡♤■□●○•°₩¥£€|~_/=÷×+^.,öøōőœ'
t+='ⁿ¹²³⁴⁵⁶⁷⁸⁹⁰⅞⅚⅝⅘¾⅗⅜⅔⅖½⅓¼⅕⅙⅛ýþťțţŕřèéêëēėęěĕəùúûüūůűųìíîïīįıòóôõ'
t+='àáâãäåæāăąªß§śšşďđģğķĺļľłñńņňçćčźżž'
t+='🥭🍍🍌🍋🍊🍉🍈🍇🍒🍎🍏🍐🍓😋😛🤩😍🥰😇😊😉🙃🙂😂🤣😅😆😁😄😃😀🏁'
			tlen=${#t}

			if [ speech = "$WIDGET" ]
			then m=14
			else m=16
			fi
			while [ ${#text} -lt "$c" ]
			do
				case $((RANDOM%m)) in
				0)
					w=${beginnings[RANDOM % ${#beginnings[@]}]}
					(( RANDOM % 2 )) && w+=${middles[RANDOM % ${#middles[@]}]}
					(( RANDOM % 2 )) && w+=${endings[RANDOM % ${#endings[@]}]}
					;;
				1)
					if [ speech = "$WIDGET" ]
					then C=9
					else C=14
					fi
					case "$((RANDOM%C))" in
					0|1|2) w=and;;
					3|4) w=but;;
					5) w=or;;
					6) w='while';;
					7) w='if';;
					8) w='then';;
					9) w=':';;
					10) w=';';;
					11) w=',';;
					12) w='#';;
					13) w=' ';;
					esac;;
				2)
					PLURAL=''
					case $((RANDOM%3)) in
					0) gensubjPLURAL;;
					*) genoun PLURAL
					esac
					w="$W"
					if [ 0 = $((RANDOM%3)) ]
					then
						PLURAL=1
						case $((RANDOM%3)) in
						0) gensubjPLURAL;;
						*) genoun PLURAL
						esac
						if ((RANDOM&1==0))
						then w+=" and $W"
						else w="both $w and $W"
						fi
						case $((RANDOM%3)) in
						0)
							w+=' but not'
							case $((RANDOM%3)) in
							0) w+=" ${subject[RANDOM%subjectlen]}";;
							*)
								genoun
								w+=" $W"
							esac;;
						2)
							w+=' but neither'
							case $((RANDOM%3)) in
							0) w+=" ${subject[RANDOM%subjectlen]}";;
							*)
								genoun
								w+=" $W"
							esac
							w+=' nor'
							case $((RANDOM%3)) in
							0) w+=" ${subject[RANDOM%subjectlen]}";;
							*)
								genoun
								w+=" $W"
							esac;;
						esac
					fi
					getverb "$w"
					w+="$VERB"
					case $((RANDOM%3)) in
					0) w+=" ${object[RANDOM % objectlen]}";;
					*)
						genoun
						w+=" $W"
					esac
					if [ 0 = $((RANDOM%3)) ]
					then
						w+=' and'
						case $((RANDOM%3)) in
						0) w+=" ${object[RANDOM % objectlen]}";;
						*)
							genoun
							w+=" $W"
						esac
						if [ 0 = $((RANDOM%3)) ]
						then
							w+=' but not'
							case $((RANDOM%3)) in
							0) w+=" ${object[RANDOM % objectlen]}";;
							*)
								genoun
								w+=" $W"
							esac
						fi
					fi
					[ speech = "$WIDGET" ]||[ $((RANDOM&1)) = 0 ]||w+=.
					;;
				3) w="${subject[RANDOM%subjectlen]}";;
				4)
					case $((RANDOM%6)) in
					0) w=an;;
					1|2) w=a;;
					*) w=the;;
					esac;;
				5) w="${adjective[RANDOM % adjectivelen]}";;
				6)
					genoun
					w="$W";;
				7) w="${adverb[RANDOM % adverblen]}";;
				8)
					PLURAL=''
					getverb
					w="${VERB:1}";;
				9)
					PLURAL=1
					getverb
					w="${VERB:1}";;
				10)
					PLURAL=1
					getverb I
					w="I$VERB";;
				11) w="${preposition[RANDOM %prepositionlen]}";;
				12) w="${object[RANDOM % objectlen]}";;
				13) w="${lorem[RANDOM%loremlen]}";;
				14)
					wl=$((RANDOM%6+RANDOM%6))
					w=''
					while [ ${#w} -lt $wl ]
					do w+="${t:RANDOM%tlen:RANDOM%3+1}"
					done;;
				15)
					getnum
					w=''
					while ((${#w}<NUM))
					do w+="${t:RANDOM%tlen:RANDOM%3+1}"
					done;;
				esac
				if [ -n "$ARG_M" ]&&[ $((RANDOM%10)) = 0 ]
				then text+="$w
"
				else text+="$w "
				fi
			done
			[ $((RANDOM%4)) = 0 ]||text="${text% }"
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
	if [ "$code" = '' ]
	then
		# Randomly simulate either cancellation or a date within ±34 years.
		if [ $((RANDOM % 50)) = 0 ]
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
	elif [ "$code" = -1 ]
	then
		# Validate and normalize a simulated date selection.
		if ! text=$(date -d "$text" '+%a %b %d 00:00:00 %Z %Y')
		then
			code=-2
			text=''
		fi
	else
		code=-2
		text=''
	fi
	index='';;
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
