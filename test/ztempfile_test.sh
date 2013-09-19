#!/bin/bash 

set -e

if [ -z "$1" ]; then
    echo "usage: $0 PATH/TO/zoptparse.sh"
    exit 1
fi

[ -e "$1" ];

source "$1"

ztempfile tmp1
[ -f "$tmp1" ]
ztempdir tmp2 "label"
[ -d "$tmp2" ]
echo "$tmp2" | grep -q label
before="$(pwd)"
pushd "$tmp2" >/dev/null
now="$(pwd)"

test "$now" '=' "$tmp2" 

_zcleaner

if [ "$before" = "$(pwd)" ]; then
    echo "SUCCESS" 
else
    echo "FAIL : " $(pwd) " != " "$before"
fi
