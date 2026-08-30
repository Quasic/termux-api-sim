#!/bin/bash
set -e -u

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

echo "This is a stub. This line is to make shellcheck happy. $show_progress"
