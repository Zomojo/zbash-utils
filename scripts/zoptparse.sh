#!/bin/bash
# generic option parser for bash scripts using zomojo command line
# option style.

zrequired=()
zoptional=()
zargs=()
zargs_help=
_zstrict=1
_zonexit=()
_zonkill=()

# extract the first word from 

# expand global opt variable from an array of possibilities
function _zexp() 
{
    for v in "$@"; do
        local fullname=$(echo "$v" | cut -f1 -d\| | sed 's/-/_/g' | grep "^$opt")
        if [ "x${fullname}" != "x" ]; then
            opt="${fullname}"
            return 0
        fi
    done
    return 1
}

# use for out of band messages to stderr (doesn't pollute stdout,
# shows up even when script output is redirected, etc)
function zmessage()
{
    printf "$@" 1>&2
    printf "\n" 1>&2
}

function zerror()
{
    printf ": error : " 1>&2
    printf "$@" 1>&2
    printf "\n" 1>&2
    return 1 # triggers exit when set -e 
}

# Figure out what directory the executing script lives in
function zscript_dir () {
     SOURCE="${BASH_SOURCE[0]}"
     while [ -h "$SOURCE" ]; do
          DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
          SOURCE="$( readlink "$SOURCE" )"
          [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     done
     $( cd -P "$( dirname "$SOURCE" )" )
     pwd
}

# use like zrecord cmd.txt stdout.txt "some command"
# it records the command string into cmd.txt and the output into stdout.txt
# while the command's stderr still gets printed as usual
function zrecord()
{
    local tagfile=$1
    local stdoutfile=$2
    shift 2
    printf "%s " $@ >> $tagfile
    printf "\n" >> $tagfile
    $@ > $stdoutfile || zerror "command failed"
}

# make sure $1 exists, optionally specify rpm name as $2
function zprerequisite()
{
    if [ -z $(which $1 2>/dev/null) ]; then
	    zmessage ": %s : %s is required, please install %s" $(basename $0) $1 $2
	    exit 1
    fi
}

# sleeps until the number of current jobs dips below a threshold
function zmaxjobs()
{
    if [ -n "$1" ]; then
        while [ $(jobs -p | wc -l) -gt "$1" ]; do
            sleep 1
        done
    fi
}

# return a tempfile and make sure it gets cleaned up on exit or error
# see manpage below for usage
function ztempfile()
{
    [ -n "$1" ]
    local label="${2:-zoptparse}"
    local prefix="${3:-${TMPDIR:-/tmp}}"
    [ -d "$prefix" ] || mkdir -p "$prefix" 
    local tmpfile=$(mktemp -q --tmpdir="$prefix" "${label}.XXXXXXXXXX")
    eval "$1=$tmpfile"
    if [ -z "${_zdebug}" ]; then
        eval " _zonexit+=( \"[ -f '$tmpfile' ] && rm -f '$tmpfile' || true\" ) "
    else
        zmessage "$tmpfile" # leave file around
    fi
}

# return a tempdir and make sure it gets cleaned up on exit or error
function ztempdir()
{
    [ -n "$1" ]
    local label="${2:-zoptparse}"
    local prefix="${3:-${TMPDIR:-/tmp}}"
    [ -d "$prefix" ] || mkdir -p "$prefix" 
    local tmpdir=$(mktemp -d -q --tmpdir="$prefix" "${label}.XXXXXXXXXX")
    eval "$1=$tmpdir"
    if [ -z "${_zdebug}" ]; then
        eval " _zonexit+=( \"[ -d '$tmpdir' ] && rm -rf '$tmpdir' && cd ${PWD} 2>/dev/null || true\" ) "
    else
        zmessage "$tmpdir"
    fi
}

function _zstacktrace()
{
    eval echo "$@"
    local cmd=$(basename $0)
    local frame=0
    while echo -n ": $cmd : called by " && caller $frame; do
        let frame++
    done
    exit 1
}

function _zcleaner()
{
    if [ -z "${_zdebug}" ]; then
        for cmd in "${_zonexit[@]}"; do eval "$cmd" ; done
    fi
}

function _zreaper()
{
    for cmd in "${_zonkill[@]}"; do eval "$cmd" ; done
}

function _zexceptions()
{
    case $1 in
        0)
            set +e
            trap '' ERR
            ;;
        1)
            set -e
            trap '1>&2 eval echo : $(basename $0) : line ${LINENO} : ${BASH_COMMAND}' ERR
            ;;
        2)
            set -e
            trap '1>&2 _zstacktrace : $(basename $0) : line ${LINENO} : ${BASH_COMMAND}' ERR
            ;;
        *)
            zmessage "unknown exception level %d" $1
            exit 1
            ;;
    esac
}

function _zhelp()
{
    if [ ${#zrequired[@]} -ne 0 ]; then
        printf "Required Application Options:\n"
        for v in "${zrequired[@]}"; do
            local varname=$(echo "$v" | cut -f1 -d\|)
            local desc=$(echo "$v" | cut -s -f2 -d\|)
            zmessage "  %-30s %s" "--$varname arg" "$desc"
        done
    fi

    if [ ${#zoptional[@]} -ne 0 ]; then
        printf "Optional Application Options:\n"
        for v in "${zoptional[@]}"; do
            local varname=$(echo "$v" | cut -f1 -d\|)
            local varvalue=$(echo "$v" | cut -s -f2 -d\|)
            local desc=$(echo "$v" | cut -s -f3 -d\|)
            zmessage "  %-30s %s" "--$varname arg (=$varvalue)" "$desc"
        done
    fi

    if [ -n "$zargs_help" ]; then
        printf "Args will be interpreted as:\n"
        zmessage "  %s" "$zargs_help"
    fi
}

function _zinit()
{
# we force exceptions (set -e with nice error messages) by default
# but only for NON-INTERACTIVE shells (otherwise your terminal will close
# when the first command with a nonzero exit code returns, d'oh). 
    if [ -z "$PS1" ]; then
        _zexceptions 1
        _zonkill=( "kill -s TERM 0" )
    fi

    trap '_zcleaner' EXIT
    trap '_zreaper' HUP INT TERM QUIT PIPE
}

function zoptparse()
{
    # only zoptparse is always called, so initialize here
    _zinit

    unset -v optchar opt val OPTIND OPTARG

    for var in "$@"
    do
        case "${var}" in
        --*) 
            # create and initialize foo=bar whenever we see --foo=bar 
            var="${var:2}"
            val="${var#*=}"
            opt="${var%%=*}"
            opt="${opt//-/_}"
            echo $val $opt >> /dev/null
            if [ "x$opt" = "xhelp" ]; then
                _zhelp 
                if [ "x${_zstrict}" = "x1" ]; then
                    exit 0
                fi
                eval "help=1"
                return 0 # we don't exit, let user handle this
            fi
            if [ "x$opt" = "xman" ]; then
                zprerequisite pod2man
                local b="Zomojo User Script"
                pod2man --center="$b" --release="$b" $(readlink -f $0) | nroff -man | ${PAGER:-cat}
                exit 0
            fi
            if [ "x$opt" = "x$val" ]; then
                for w in "${zrequired[@]}"; do
                    w=$(echo $w | cut -f1 -d\|)
                    if [ "x$opt" = "x$w" ]; then
                        zmessage "$0 accepts only options of the form --xxx=yyy (no spaces in yyy)"
                        return 1
                    fi
                done
                # if we're here then opt is an optional var whose
                # value wasn't set. This is ok, but make sure dashes
                #  are converted to underscores
                eval "${val}='$opt'"
            fi
            # now eval the var
            # 1) if  zrequired or zoptional always eval
            # 2) if _zstrict=1 and not zrequired or zoptional, fail
            # 3) if _zstrict=2 and not zrequired or zoptional, eval anyway
            # 4) if _zstrict=0 and not zrequired or zoptional, silently ignore
            if [ "x$opt" = "xdebug" ]; then
                _zdebug="debug"
            elif _zexp "${zrequired[@]}" || _zexp "${zoptional[@]}" ; then
                eval "${opt}='${val}'"
            elif [ "x${_zstrict}" = "x1" ]; then
                zmessage "unrecognized option --${opt}"
                return 1
            elif [ "x${_zstrict}" = "x2" ]; then
                eval "${opt}='${val}'"
            fi
            ;;
        -*) 
            if [[ $_zstrict -eq 1 ]]; then
                # zd-exec, zsandbox - what if the subcommand has something in it that uses a single hyphen? (TODO think)
                zmessage "$0 accepts only options of the form --xxx=yyy (no spaces in yyy)" 
                return 1
            fi
            ;;
        *) 
            # treat as args
            zargs[${#zargs[@]}]="$var"
            ;;
        esac
    done

    # make sure required vars exist (are not empty)
    for v in "${zrequired[@]}"; do
        local varname=$(echo "$v" | cut -f1 -d\| | sed 's/-/_/g')
        if (eval "[ \"x\$${varname}\" = 'x' ]"); then
            zmessage "$0 requires --%s=..." ${v%%|*}
            return 1
        fi
    done

    # make sure optional vars have default values if unset
    for v in "${zoptional[@]}"; do
        local varname=$(echo "$v" | cut -f1 -d\| | sed 's/-/_/g')
        local varvalue=$(echo "$v" | cut -s -f2 -d\|)
        if (eval "[ \"x\$${varname}\" = 'x' ]"); then
            eval "${varname}='${varvalue}'"
        fi
    done
    
    return 0
}

# export symbols. This is not needed if you source zoptparse.sh explicitly
# but handy if you don't
export -f _zexp _zhelp _zstacktrace _zexceptions _zinit _zreaper _zcleaner zprerequisite zmaxjobs zmessage zerror zrecord ztempfile ztempdir zoptparse
export zrequired zoptional _zstrict _zonexit _zonkill

: <<=cut
=pod

=head1 NAME

    zoptparse.sh - zomojo style option processing in bash scripts

=head1 SYNOPSIS

    source '/usr/bin/zoptparse.sh'
    
    zrequired=( [STRING]... )
    zoptional=( [STRING]... )

    zoptparse "$@" || exit 1

    total_zargs=${#zargs[@]}

=head1 DESCRIPTION

The function B<zoptparse> converts any option of the form --foo=bar
into a bash variable called I<foo>, with the value I<bar>. All variables
whose names appear in the array B<zrequired> or the array B<zoptional>
are guaranteed to exist.

If I<foo> contains a hyphen, this is transliterated into an underscore,
to comply with bash naming requirements for variables.

Note that options arguments MUST be separated from the option name by
an equal sign, while a space is not supported. 

The first non-option argument marks the end of option processing. Non-
option arguments are stored in the array B<zargs>.
Spaces inside an option argument are supported IF quoted properly, 
otherwise option processing will likely stop.

Note also that the expression "$@" will properly quote strings with
embedded spaces.

=head2 ZREQUIRED

A variable listed in B<zrequired> must be set on the command line.

The format of each entry in B<zrequired> is "foo", which indicates that
the variable foo must appear on the command line. An optional help string
can be included, by using a | separator, eg "foo|help for foo"

=head2 ZOPTIONAL

A variable listed in B<zoptional> need not be set. It will always have 
either an empty string value, or a default value (specified in its declaration)
or the value assigned on the command line. 

The format of each entry in B<zoptional> is "foo|default|help string",
which indicates that variable foo should be set to default if it isn't
set on the command line. Both the default value and the help string are optional,
in particular if "foo" only is specified, then the default value defaults to the 
empty string

If the user calls the option --help or --help=1 then option parsing is
aborted and the B<zoptparse> function returns, with the I<help> variable set.
The programmer can test for -n $help to see if help was called, and act accordingly.

All options must be of the form --foo=bar (note equal sign), or else --foo.
In the latter case, the value of the variable foo will be set as "foo".

Unrecognized options cause an error message when _zstrict=1 (this is the default).
Set _zstrict=0 to silently ignore them instead or _zstrict=2 to accept them as
valid variables.

=head2 TEMPORARY FILES

The commands B<ztempfile> and B<ztempdir> can be used to obtain a
temporary file name of the required type that is also cleaned up
automatically upon exit from the script, except if the variable B<_zdebug> is nonempty.
The cleanup commands are specified in the special arrays B<_zonexit>
and B<_zonkill>, and are executed as signal traps. You should add your
commands to those arrays if you need to do further processing.

Note B<_zonkill> automatically sends SIGTERM to the current process group, which should
kill all child processes. This is only called when an interrupt signal is received.

LOCATION OF TEMPFILES: The third optional parameter of B<ztempfile> / B<ztempdir> specifies
the location of the temporary object. If unspecified, the default will be either
the value of the environment variable TMPDIR, or "/tmp" if the latter is empty.

=head2 ERRORS/EXCEPTIONS

The act of sourcing zoptparse.sh turns on error trapping via "set -e",
I<provided the shell is non-interactive>.
If any subsequent command exits with a nonzero status, your script
is aborted and the offending command line is printed. To turn this
behaviour off, use the function call

 _zexceptions 0

=head2 SPECIAL PREDEFINED OPTIONS

=over 4

=item --help

This option causes the _zhelp() function to be executed, printing all
the variables defined by zrequired and zoptional. If _zstrict=0 then
the $help variable is set upon exit from zoptparse(). If _zstrict=1
(default case), zoptparse() exits 0 after displaying the help.

=item --man

If the current script contains an embedded man page in Perl's I<plain
old documentation> format, this command will display the page on your
terminal. See the source code of /usr/bin/zsandbox for an example.

=back


=head2 ENVIRONMENT

Sourcing the script exports the following functions to the current shell environment:

 zoptparse()
 zmessage()
 zerror()
 zmaxjobs()
 zprerequisite()
 ztempfile()
 ztempdir()
 _zhelp()
 _zexp()
 _zexceptions()
 _zstacktrace()
 _zinit()
 _zreaper()
 _zcleaner()

These functions may also be used independently. See the examples below.

=head1 EXAMPLES

=head3 Example 1

This doesn't use B<zrequired> nor B<zoptional>, and has the default value 
of _zstrict=1. Therefore, all options of the form --foo=bar listed
on the command line will cause an error (unrecognized option). See the next example.

 declare -Ff zoptparse >/dev/null || source "/usr/bin/zoptparse.sh"
 zoptparse "$@" || exit 1

=head3 Example 2

This doesn\'t use B<zrequired> nor B<zoptional>, but _zstrict=2. The variable I<myvar> is
given a default value, which may be overwritten if and only if the
variable appears on the command line

 _zstrict=2
 myvar=baz
 zoptparse "$@" || exit 1
 echo $myvar

=head3 Example 3

Full option parsing with required and optional variables. 
All variables I<one>, I<two>, I<three> will have values, and
the program exits if a required variable is missing. Note help handling.
The function B<zmessage> writes its output to STDERR.

Help for a single required option occurs after an optional |
Help for an optional option occurs after the second optional |

 zrequired=("one" "two|this is help for option two")
 zoptional=("three|3|this is option three")
 zoptparse "$@" || exit 1
 if [ -n "$help" ]; then
    zmessage "usage: ..."
    exit 0
 fi

=head3 Example 4

The function zprerequisite exits the current script gracefully if its
first argument is not available on the system

 zprerequisite perflogread perflogger.x86_64

=head3 Example 5

It is highly recommended to put the following command at the start of your
script. It causes exception behaviour similar to C++, ie any command which
returns a nonzero exit status will immediately stop your script, and
the line will be printed to STDERR. 

 _zexceptions 0 # disable bash exceptions - this is the default
 _zexceptions 1 # enable bash exceptions - highly recommended
 _zexceptions 2 # enable bash exceptions with function stack frame - meh

In recent versions of zoptparse, the second line above is run by default.
Thus, you don't have to do anything unless you want to turn I<off> error
trapping.

=head3 Example 6

Spaces are not supported instead of =, but are supported if quoted properly

 --foo blah # fails space instead of = is not supported
 --foo="blah blah" # succeeds now foo is "blah blah"
 --foo=blah blah # succeeds now foo is "blah" and other blah is ignored

=head3 Example 7

If you run several jobs in parallel using &, you can throttle the number of 
simultaneous processes using zmaxjobs as follows:

 source /usr/bin/zoptparse.sh

 function do_something()
 {
    for j in $(seq 0 3); do echo $1 $j ; sleep 1; done
 }

 for i in $(seq 0 5); do
    do_something $i &
    zmaxjobs 5 # sleep until the number of jobs dips below 5
 done

 wait # until all processes are finished

=head3 Example 8

Here is how to obtain a temporary file name:

 source /usr/bin/zoptparse.sh
 ztempfile tmp1 # evaluates tmp1=/tmp/zoptparse.XXXX
 ztempfile tmp1 "label" # evaluates tmp1=/tmp/label.XXXX
 ztempfile tmp1 "label" "/dev/shm" # evaluates tmp1=/dev/shm/label.XXXX
 ztempdir tmp2 "label" # evaluates tmp2=/tmp/label.XXXX
 pushd $tmp2
 
Upon exit, both tmp1 and tmp2 are deleted automatically and the current 
working directory is reset to what it was before the pushd, 
unless B<_zdebug> is nonempty. 

=head3 Example 9

The zrecord function can be used to record a command string, execute it, and
save its output. For example

 zrecord /tmp/cmd.txt /tmp/stdout.txt echo "hello there"
 cat /tmp/cmd.txt
 echo hello there
 cat /tmp/stdout.txt
 hello there

=head1 SEE ALSO

zsandbox

=cut
