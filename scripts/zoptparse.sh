#!/bin/bash
# generic option parser for bash scripts using zomojo command line
# option style.

zrequired=()
zoptional=()

# extract the first word from 

# expand global opt variable from an array of possibilities
function _zexp() 
{
    for v in "$@"; do
        local fullname=$(echo $v | cut -f1 -d\| | sed 's/-/_/g' | grep ^$opt)
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
}


function zoptparse()
{
    unset -v optchar opt val OPTIND OPTARG
   # create and initialize foo=bar whenever we see --foo=bar 
    while getopts ":-:" optchar; do
        case "${optchar}" in
            -)
                val=${OPTARG#*=}
                opt=${OPTARG%=$val}
                opt=${opt//-/_}
                if [ "x$opt" = "xhelp" ]; then
                    _zhelp 
                    eval "help=1"
                    return 0
                fi
                if [ "x$opt" = "x$val" ]; then
                    for w in "${zrequired[@]}"; do
                        w=$(echo $w | cut -f1 -d\|)
                        if [ "x$opt" = "x$w" ]; then
                            zmessage "$0 accepts only options of the form --xxx=yyy"
                            return 1
                        fi
                    done
                    # if we're here then opt is an optional var whose
                    # value wasn't set. This is ok, but make sure dashes are converted to underscores
                    eval "${val}='$opt'"
                fi
                if _zexp "${zrequired[@]}" || _zexp "${zoptional[@]}" ; then
                   eval "${opt}='${val}'"
                fi
                ;;
            *)
                zmessage "$0 accepts only options of the form --xxx=yyy" 
                return 1
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

: <<=cut
=pod

=head1 NAME

    zoptparse.sh - zomojo style option processing in bash scripts

=head1 SYNOPSIS

    source '/usr/bin/zoptparse.sh'
    
    zrequired=( [STRING]... )
    zoptional=( [STRING]... )

    zoptparse "$@" || exit 1

=head1 DESCRIPTION

The function B<zoptparse> converts any option of the form --foo=bar
into a bash variable called I<foo>, with the value I<bar>. All variables
whose names appear in the array B<zrequired> or the array B<zoptional>
are guaranteed to exist.

If I<foo> contains a hyphen, this is transliterated into an underscore,
to comply with bash naming requirements for variables.

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

=head1 EXAMPLES

=head3 Example 1

This doesn't use B<zrequired> nor B<zoptional>. Therefore, all variables listed
on the command line are set (and only those)

 source "/usr/bin/zoptparse.sh"
 zoptparse "$@" || exit 1

=head3 Example 2

This doesn't use B<zrequired> nor B<zoptional>. The variable I<myvar> is
given a default value, which may be overwritten if and only if the
variable appears on the command line

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

=head1 SEE ALSO

zsandbox

=cut
