#!/bin/bash

script_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $script_dir/zoptparse.sh

# no set-e

function log()
{
    payload="$1"
    log=${2-cmd.log}
    # Hack. Silently lets logging failures go unnoticed. 
    # This is to get passed an issue on KCG cluster.
    # TODO think of a better long term solution.
    echo $(date) $payload 2>/dev/null >> $log  || :
}

# log eval
# logs the command 
# returns the return code of the command
function leval()
{
    log "$*" cmd.log  
    eval $@ 
    return $?
}

# "no fail log eval"
# logs the command 
# issues a zerror if it fails
# if set -e program, will exit on zerror
# returns the return code of the command
function nfleval()
{
    log "$*" cmd.log
    if ! eval $@; then
        ret_code=$?
        zerror "Failed running cmd \"%s\"" "$*"
        return $ret_code
    fi
    return 0
}

function log_echo()
{
    log "$*" cmd.log  
    echo "$@" 
}

function fix_forward_slash_for_regex()
{
    echo $1 | sed 's/\//\\\//g'
}

: <<=cut
=pod

=head1 NAME

    zcommon.sh - zomojo cluster logging tools

=head1 SYNOPSIS

    source '/usr/bin/zcommon.sh'
    
=head1 DESCRIPTION

Testing

=head2 ZREQUIRED

Testing

=head2 ZOPTIONAL

Testing

=head1 SEE ALSO

Testing

=cut
