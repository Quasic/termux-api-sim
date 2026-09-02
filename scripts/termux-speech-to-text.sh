#!/bin/bash
set +e -u

alphabet=abcdefghijklmnopqrstuvwxyz

beginnings=(the com con re pro de un interi ex)
middles=(ma na ra la ti ven fer port)
endings=(ing er ed ly tion ment ness able)
setWordGlish(){
	Word=${beginnings[RANDOM % ${#beginnings[@]}]}
	(( RANDOM & 1 )) || Word+=${middles[RANDOM % ${#middles[@]}]}
	(( RANDOM & 1 )) || Word+=${endings[RANDOM % ${#endings[@]}]}
}

subject=(he she it one that this 'this one' 'that one')
subjectPlural=(we they you I both those these)
setNounPro(){
	if [ -z "${1:-}" ]
	then Noun="${subject[RANDOM%${#subject[@]}]}"
	else Noun="${subjectPlural[RANDOM%${#subjectPlural[@]}]}"
	fi
}
object=(them you me it him her us both one this that these those)

name_beginnings=(
	al an ar be ca el em er fa ga ha is jo la ma na ol ra sa the va wi
)
name_middles=(ba bel da den li lon mar mel na nel ri ron sa sel ta tor ven)
name_endings=(a ah en ia ian el ella ine on or us yn)
surname_endings=(son sen man ley wood stone field ford smith ward)
place_endings=(
    berg bury by chester dale ford gate ham hill land
    mouth ton ville burg stead worth field port wood
)
setNamePlace(){
	Name="${name_beginnings[RANDOM%${#name_beginnings[@]}]}"
	((RANDOM&1))||Name+="${name_middles[RANDOM%${#name_middles[@]}]}"
	Name+="${place_endings[RANDOM%${#place_endings[@]}]}"
	Name="${Name^}"
}
setName(){
	Name="${name_beginnings[RANDOM%${#name_beginnings[@]}]}"
	((RANDOM&1))||Name+="${name_middles[RANDOM%${#name_middles[@]}]}"
	if [ -n "${1:-}" ]
	then Name+="${surname_endings[RANDOM%${#surname_endings[@]}]}"
	elif (((RANDOM&3)==0))
	then Name+="${name_middles[RANDOM%${#name_middles[@]}]}${name_endings[RANDOM%${#name_endings[@]}]}"
	else Name+="${name_endings[RANDOM%${#name_endings[@]}]}"
	fi
	Name="${Name^}"
}

initials="$alphabet"
for I in "${name_beginnings[@]}" "${name_middles[@]}" "${name_endings[@]}" "${surname_endings[@]}"
do initials+="${I:0:1}"
done
initials="${initials^^}"
#"${initials:RANDOM%${#initials}:1}."
titles=(doctor professor pastor councilor officer deputy admiral general colonel major captain commander sergeant private corporal lieutenant representative sheriff judge mayor administrator honorable president senator ambassador governor secretary director mister miss misses master)
titleAb=(Dr. Prof. Rev. Lieut. Rep. Pvt. Cpl. Sgt. Lt. Cmdr. Capt. Maj. Col. Gen. Adm. Pres. Sen. Hon. Mr. Mrs. Ms. Mx. Gov. Pres. Sen. Amb. Dir. Sec.)
suffix=(junior senior esquire)
suffixAb=(Jr. Sr. Esq. III)
setNameFull(){
	local t
	local n
	local s
	case $((RANDOM&7)) in
	0)
		t="${titles[RANDOM%${#titles[@]}]}"
		t="${t^} ";;
	1) t="${titleAb[RANDOM%${#titleAb[@]}]} ";;
	*) t=''
	esac
	case $((RANDOM&15)) in
	# i,n,s,ii,is,ni,ns,iii,iis,ini,ins,nii,nis,nni,nns
	0) n="${initials:RANDOM%${#initials}:1}.";;
	1)
		setName
		n="$Name";;
	2|15)
		setName sur
		n="$Name";;
	3) n="${initials:RANDOM%${#initials}:1}. ${initials:RANDOM%${#initials}:1}.";;
	4)
		setName sur
		n="${initials:RANDOM%${#initials}:1}. $Name";;
	5)
		setName
		n="$Name ${initials:RANDOM%${#initials}:1}.";;
	6)
		setName
		n="$Name"
		setName sur
		n+=" $Name";;
	7) n="${initials:RANDOM%${#initials}:1}. ${initials:RANDOM%${#initials}:1}. ${initials:RANDOM%${#initials}:1}.";;
	8)
		setName sur
		n="${initials:RANDOM%${#initials}:1}. ${initials:RANDOM%${#initials}:1}. $Name";;
	9)
		setName
		n="${initials:RANDOM%${#initials}:1}. $Name ${initials:RANDOM%${#initials}:1}.";;
	10)
		setName
		n="${initials:RANDOM%${#initials}:1}. $Name"
		setName sur
		n+=" $Name";;
	11)
		setName
		n="$Name ${initials:RANDOM%${#initials}:1}. ${initials:RANDOM%${#initials}:1}.";;
	12)
		setName
		n="$Name ${initials:RANDOM%${#initials}:1}."
		setName sur
		n+=" $Name";;
	13)
		setName
		n="$Name"
		setName
		n="$Name";;
	14)
		setName
		n="$Name"
		setName
		n+=" $Name"
		setName sur
		n+=" $Name";;
	# 4 names? iiii iiis iini iins inii inis inni inns niii niis nini nins nnii nnis nnni nnns
	esac
	case $((RANDOM&31)) in
	0) s=", ${suffix[RANDOM%${#suffix[@]}]}";;
	1) s=", ${suffixAb[RANDOM%${#suffixAb[@]}]}";;
	*) s=''
	esac
	# degrees too much? should match title
	Name="$t$n$s"
}

group=(handful group assortment jumble arrangement gaggle herd family set menagerie conglomerate company council throng crowd class swarm hive party flock series house school collection line circle couple)
noun=(nobody noone none void book table car goat horse cow chicken pig elephant oyster clam turkey fox cat dog gerbil yeti newt person friend plant amoeba worm eggplant turtle giraffe bird duck penguin bear muskrat ox donkey baby lady bus bug box quiz dish bee tomato potato goose photo piano radio play day week hour minute second millisecond month year decade century olympiad millenium word verb noun adjective adverb preposition pronoun subject object farm land grass lawn report statement evaluation account agreement rock paper scissors knife fire view question challenge experiment deer sheep aircraft mouse "${titles[@]}" "${suffix[@]}" "${group[@]}")
setNoun(){ #plural?
	local p="${1:-}"
	if [ -z "$p" ]&&(((RANDOM&7)==0))
	then
		if ((RANDOM&1))
		then setNameFull
		else setNamePlace
		fi
		Noun="$Name"
	elif ((RANDOM%7==0))
	then
		setWordGlish
		Noun="$Word"
	else Noun="${noun[RANDOM%${#noun[@]}]}"
	fi
	if [ -n "$p" ]
	then
		case "$Noun" in
		scissors|deer|sheep|aircraft|series) :;;
		ox) Noun+=en;;
		*ch|*sh|*s|*x|*z|[tp]o[mt]ato) Noun+=es;;
		*[bcdfghj-np-tv-z]y) Noun="${Noun%y}ies";;
		goose) Noun=geese;;
		mouse) Noun=mice;;
		*) Noun+=s;
		esac
	fi
}

adjectiveEn=(
 colorful brown white gray black red green blue yellow orange purple violet pink
 angry beautiful bright brisk busy
 careless careful clear correct common courageous crazy dark educated elusive
 fearful final friendly gentle giant heavy happy
 lovely lively lonely lazy
 small silly simple terrible tiny quick slow large impactful quiet loud polite rude different fortunate honest patient perfect recent serious sudden usual transitive intransitive proper random forceful strong blind deaf limp lame dumb emphatic transparent elusive shy short smart near far short long tall
)
setAdj(){
	if ((RANDOM%7==0))
	then
		setWordGlish
		Adj="$Word"
	else Adj="${adjectiveEn[RANDOM%${#adjectiveEn[@]}]}"
	fi
}
setAdv(){
	local pre="${1:-}"
	local post="${2:-}"
	setAdj
	case "$Adj" in
	*le) Adv="$pre${Adj%e}y$post";;
	*[^aeiou]y) Adv="$pre${Adj%y}ily$post";;
	*) Adv="$pre${Adj}ly$post"
	esac
}
setAdvPrePhrase(){
	case $((RANDOM&7)) in
	0|5|7) Adv='';;
	1|6) setAdv '' ' ';;
	2) setAdv 'very ' ' ';;
	3) setAdv 'quite ' ' ';;
	4)
		setAdv
		setAdv '' " $Adv ";;
	esac
}
setAdjPhrase(){
	local a
	if (((RANDOM&3)==0))
	then
		setAdv '' ' '
		if (((RANDOM&3)==0))
		then a="very $Adv"
		else a="$Adv"
		fi
	else a=''
	fi
	if (((RANDOM&3)==0))
	then setAdvPrePhrase
	else Adv=''
	fi
	setAdj
	Adj="$a$Adv$Adj"
}

adNoun(){
	local c=$((RANDOM&3))
	local i
	for ((i=0;i<c;i++))
	do
		setAdjPhrase
		Noun="$Adj $Noun"
	done
}

possessive=(his her its their our)
possessNoun(){
	local i
	#TODO: name, plural
	if ((RANDOM&1))
	then Noun="${possessive[RANDOM%${#possessive[@]}]} $Noun"
	else
		i="$Noun"
		setNoun
		adNoun
		case "$((RANDOM%3))${Noun:0:1}" in
		0[aeiou]) Noun="an $Noun's $i";;
		0*) Noun="a $Noun's $i";;
		1*) Noun="one $Noun's $i";;
		2*) Noun="the $Noun's $i";;
		esac
	fi
}
setNounPhrase(){ #plural?
	if [ -z "${1:-}" ]
	then
		setNoun
		adNoun
		case "$((RANDOM%6))${Noun:0:1}" in
		0[aeiou]) Noun="an $Noun";;
		0*) Noun="a $Noun";;
		1*) Noun="one $Noun";;
		2*)
			case $((RANDOM&3)) in
			0) Noun="only $Noun";;
			1) Noun="one $Noun";;
			2) Noun="one and only $Noun";;
			#3 keep
			esac
			possessNoun;;
		3*) Noun="this $Noun";;
		4*) Noun="that $Noun";;
		*) Noun="the $Noun";;
		esac
	else
		setNoun plural
		adNoun
		if ((RANDOM&1))
		then
			case $((RANDOM%5)) in
			1) Noun="${group[RANDOM%${#group[@]}]} of $Noun";;
			2) Noun="$(((RANDOM&127)+2)) $Noun";;
			3)
				Noun="few $Noun"
				(((RANDOM&3)==0))&&Noun="quite $Noun";;
			4) Noun="several $Noun";;
			*) Noun="many $Noun";;
			esac
			possessNoun
		else
			case $((RANDOM&7)) in
			0) Noun="some $Noun";;
			1) Noun="a ${group[RANDOM%${#group[@]}]} of $Noun";;
			2) Noun="$(((RANDOM&127)+2)) $Noun";;
			3)
				Noun="a few $Noun"
				(((RANDOM&3)==0))&&Noun="quite $Noun";;
			4) Noun="several $Noun";;
			5) Noun="those $Noun";;
			6) Noun="these $Noun";;
			*) Noun="many $Noun";;
			esac
		fi
	fi
}

prepositionEn=(with over around at by near toward behind under above below 'in front of' in on for from to about across after against along among before beneath beside between beyond during into of off through until upon within without up as past) # except than
prepositionLatin=(ad ante apud circa contra de extra intra per post pro sine sub super trans)
prep_beginnings=(a ad de in per pro sub con trans)
prep_middles=(la ri tu ve na po)
prep_endings=(a e i o um us)
setPrep(){
	local pre="${1:-}"
	case $((RANDOM&7)) in
	0)
		Prep="$pre${prep_beginnings[RANDOM%${#prep_beginnings[@]}]}"
		((RANDOM&1))&&Prep+="${prep_middles[RANDOM%${#prep_middles[@]}]}"
		(((RANDOM&3)==0))&&Prep+="${prep_endings[RANDOM%${#prep_endings[@]}]}";;
	1) Prep="$pre${prepositionLatin[RANDOM%${#prepositionLatin[@]}]}";;
	*) Prep="$pre${prepositionEn[RANDOM%${#prepositionEn[@]}]}"
	esac
}

#verb
transitive=(move ignore insult poke inspect watch imagine attack see bring consult teach blame dox wiggle jostle invoke emulate yeet visit like wash help stop shun reward award recognize criticize visualize refresh love discover evaluate discuss ask respect appreciate value call report balance check narrate encourage)
intransitive=(dance jump go fly stare move work walk box unbox buzz play run consult teach skip agree disagree zoom sit check strut travel apologize live learn land crawl party talk experiment)
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
pastVerb(){
	case "$Verb" in
	[bcdfghj-np-tv-z][bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]) Verb="$Verb${Verb:${#Verb}-1}ed";;
	go) Verb=went;;
	eat) Verb=ate;;
	run) Verb=ran;;
	fly) Verb=flew;;
	sit) Verb=sat;;
	see) Verb=saw;;
	teach) Verb=taught;;
	bring) Verb=brought;;
	*) Verb="${Verb%e}ed"
	esac
}
perfectVerb(){ # past perfect
	case "$Verb" in
	run) :;;
	go) Verb=gone;;
	see) Verb=seen;;
	eat) Verb=eaten;;
	fly) Verb=flown;;
	sit) Verb=seated;;
	*) Verb="${Verb%e}ed"
	esac
}
presentVerb(){
	case "$Verb" in
	*ch|*sh|*s|*x|*z|go) Verb="${Verb}es";;
	*[bcdfghj-np-tv-z]y) Verb="${Verb%y}ies";;
	*) Verb="${Verb}s"
	esac
}
participleVerb(){ # present (gerund) participle
	case "$Verb" in
	[bcdfghj-np-tv-z][bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]|[bcdfghj-np-tv-z][aeiou][bcdfghj-np-tvz]) Verb="$Verb${Verb:${#Verb}-1}ing";;
	see) Verb=seeing;;
	*) Verb="${Verb%e}ing"
	esac
}
metaphore(){
	if (((RANDOM&127)==0))
	then Verb='' #metaphore
	else
		participleVerb
		Verb+="$Prep"
	fi
}
setVerbPrep(){
	if ((RANDOM&1))
	then
		Verb="${transitive[RANDOM % ${#transitive[@]}]}"
		Prep=''
	else
		Verb="${intransitive[RANDOM %${#intransitive[@]}]}"
		setPrep ' '
	fi
}
setVerbPhrase(){ # I plural
	local I="${1:-}"
	local plural="${2:-}"
	setVerbPrep
	setAdvPrePhrase
	case $((RANDOM%18)) in
	0)
		pastVerb
		Verb="$Adv$Verb$Prep";;
	1)
		[ -z "$plural" ]&&presentVerb
		Verb="$Adv$Verb$Prep";;
	2) Verb="will $Adv$Verb$Prep";;
	3)
		participleVerb
		if [ I = "$I" ]
		then Verb="am $Adv$Verb$Prep"
		elif [ -n "$plural" ]
		then Verb="are $Adv$Verb$Prep"
		else Verb="is $Adv$Verb$Prep"
		fi;;
	4)
		participleVerb
		Verb="will have been $Adv$Verb$Prep";;
	5)
		perfectVerb
		Verb="will have $Adv$Verb$Prep";;
	6)
		participleVerb
		Verb="will be $Adv$Verb$Prep";;
	7) Verb="did $Adv$Verb$Prep";;
	8)
		if [ -n "$plural" ]
		then Verb="do $Adv$Verb$Prep"
		else Verb="does $Adv$Verb$Prep"
		fi;;
	9)
		participleVerb
		if [ -n "$plural" ]
		then Verb="were $Adv$Verb$Prep"
		else Verb="was $Adv$Verb$Prep"
		fi;;
	10) Verb="${Adv}will $Verb$Prep";; #metaphore n/a
	11)
		metaphore
		if [ I = "$I" ]
		then Verb="${Adv}am $Verb"
		elif [ -n "$plural" ]
		then Verb="${Adv}are $Verb"
		else Verb="${Adv}is $Verb"
		fi;;
	12)
		metaphore
		Verb="${Adv}will have been $Verb";;
	13)
		perfectVerb
		Verb="${Adv}will have $Verb$Prep";; # metaphore n/a
	14)
		metaphore
		Verb="${Adv}will be $Verb";;
	15) Verb="${Adv}did $Verb$Prep";;
	16) # metaphore n/a
		if [ -n "$plural" ]
		then Verb="${Adv}do $Verb$Prep"
		else Verb="${Adv}does $Verb$Prep"
		fi;;
	17)
		metaphore
		if [ -n "$plural" ]
		then Verb="${Adv}were $Verb"
		else Verb="${Adv}was $Verb"
		fi;;
	esac
}
setSubj(){
	local plural="${1:-}"
	if (((RANDOM&3)==0))
	then setNounPro "$plural"
	else setNounPhrase "$plural"
	fi
	Subj="$Noun"
	if (((RANDOM&3)==0))
	then
		if ((RANDOM&1))
		then plural=3
		else plural=''
		fi
		if (((RANDOM&3)==0))
		then setNounPro "$plural"
		else setNounPhrase "$plural"
		fi
		if ((RANDOM&1))
		then Subj+=" and $Noun"
		else Subj="both $Subj and $Noun"
		fi
		if ((RANDOM&1))
		then plural=3
		else plural=''
		fi
		case $((RANDOM&7)) in
		1)
			if ((RANDOM%3==0))
			then setNounPro "$plural"
			else setNounPhrase "$plural"
			fi
			Subj+=", but not $Noun,";;
		2)
			if ((RANDOM%3==0))
			then setNounPro "$plural"
			else setNounPhrase "$plural"
			fi
			Subj+=", but neither $Noun nor"
			if ((RANDOM&1))
			then plural=3
			else plural=''
			fi
			if ((RANDOM%3==0))
			then setNounPro "$plural"
			else setNounPhrase "$plural"
			fi
			Subj+=" $Noun,";;
		esac
	fi
}
setObj(){
	local plural=''
	((RANDOM&1))&&plural=3
	if (((RANDOM&3)==0))
	then Obj="${object[RANDOM %${#object[@]}]}"
	else
		setNounPhrase "$plural"
		Obj="$Noun"
	fi
	if (((RANDOM&3)==0))
	then
		Obj+=' and'
		if (((RANDOM&3)==0))
		then Obj+=" ${object[RANDOM %${#object[@]}]}"
		else
			if ((RANDOM&1))
			then plural=3
			else plural=''
			fi
			setNounPhrase "$plural"
			Obj+=" $Noun"
		fi
		if (((RANDOM&3)==0))
		then
			Obj+=' but not'
			if (((RANDOM&3)==0))
			then Obj+=" ${object[RANDOM %${#object[@]}]}"
			else
				if ((RANDOM&1))
				then plural=3
				else plural=''
				fi
				setNounPhrase "$plural"
				Obj+=" $Noun"
			fi
		fi
	fi
}
setSentence(){
	local plural=''
	local w
	(((RANDOM&3)==0))&&plural=3
	setSubj "$plural"
	setVerbPhrase "$Subj" "$plural"
	w="$Subj $Verb"
	setObj
	w+=" $Obj"
	#TODO: other clauses -- prep : ; conj
	case $((RANDOM&15)) in
	0) w+='?';;
	1|9) w+='!';;
	2) w+='!?';;
	*) w="${w%.}."
	esac
	Sentence="${w^}"
}
interrogative=(who what when where why how)
setQuestion(){
	local q="${interrogative[RANDOM%${#interrogative[@]}]}"
	case $((RANDOM&3)) in
	0) : 1 word;; 
	1)
		setSubj
		setVerbPrep
		if [ "$q" != who ]&&[ "$q" != what ]&&((RANDOM&1))
		then
			setObj
			Obj=" $Obj"
		else Obj=''
		fi
		if ((RANDOM&1))
		then
			participleVerb
			if ((RANDOM&1))
			then q+=" was"
			else q+=" is"
			fi
		elif ((RANDOM&1))
		then q+=" did"
		else q+=" does"
		fi
		# q had s been ving [o]
		# how adj has/have/had s been ving
		# how transitiving [is/are/was/were o]
		# q is/are/was/were o
		setAdvPrePhrase
		q+=" $Subj $Adv$Verb$Prep$Obj";;
	2)
		setSubj plural
		setVerbPrep
		if [ "$q" != who ]&&[ "$q" != what ]&&((RANDOM&1))
		then
			setObj
			Obj=" $Obj"
		else Obj=''
		fi
		if ((RANDOM&1))
		then
			participleVerb
			if [ "$Subj" = I ]
			then
				if ((RANDOM&1))
				then q+=" was"
				else q+=" am"
				fi
			else
				if ((RANDOM&1))
				then q+=" were"
				else q+=" are"
				fi
			fi
		elif ((RANDOM&1))
		then q+=" did"
		else q+=" do"
		fi
		setAdvPrePhrase
		q+=" $Subj $Adv$Verb$Prep$Obj";;
	3) : #who/what is ving that? where/why/how is s/that [NounPhrase]? or ... are s pl/they/those [NounPhrase pl]
	esac
	Question="${q^}?"
}

[[ "${BASH_SOURCE[0]}" != "$0" ]]||{

SCRIPTNAME=termux-speech-to-text
show_usage () {
    echo "Usage: $SCRIPTNAME"
    echo "Converts simulated speech to text, sending to stdout."
    exit 0
}

show_progress=false
while getopts :hp option
do
    case "$option" in
        h) show_usage;;
        p) show_progress=true;;
        ?) echo "$SCRIPTNAME: illegal option -$OPTARG"; exit 1;
    esac
done
shift $((OPTIND-1))

if [ $# != 0 ]; then echo "$SCRIPTNAME: too many arguments"; exit 1; fi

: "$show_progress" # don't know exactly what this does, not working for me

for i in 1 2 3
do
	((RANDOM&1))&&setSentence&&printf %s "$Sentence  "
	((RANDOM&1))&&setQuestion&&printf %s "$Question  "
done
printf \\n
}

