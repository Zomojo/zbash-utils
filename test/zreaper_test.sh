#!/bin/bash 

set -e

if [ -z "$1" ]; then
    echo "usage: $0 PATH/TO/zoptparse.sh"
    exit 1
fi

[ -e "$1" ];

source "$1"

(yes | while read y; do echo "child process 1 - press ctrl-c to see if it will be killed"; sleep 3; done) &
(yes | while read y; do echo "child process 2 - press ctrl-c to see if it will be killed"; sleep 2; done) &

wait
