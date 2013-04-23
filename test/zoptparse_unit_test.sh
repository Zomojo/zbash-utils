#!/bin/bash
# perform a series of unit tests for zoptparse.sh

set -e

if [ -z "$1" ]; then
    echo "usage: $0 PATH/TO/zoptparse.sh"
    exit 1
fi

[ -e "$1" ];

tmp=$(mktemp -d -q --tmpdir="/tmp" "zbash-unit-test.XXXXXXXX")
trap "rm -rf $tmp" EXIT

if ! pushd "$tmp" >/dev/null ; then
    echo "couldn't cd into temporary directory [$tmp]"
    exit 1
fi

# check that an unspecified variable causes an error in strict mode
cat <<_unspecified1 > test_unspecified1
#!/bin/bash
source "$1"

[ "x\${_zstrict}" = x1 ] || exit 1

zoptparse "\$@" 2>/dev/null || exit 0

exit 1

./test_unspecified1 --date=20130415
_unspecified1

# check that an unspecified variable causes no errors if _zstrict=0
cat <<_unspecified0 > test_unspecified0
#!/bin/bash
source "$1"

_zstrict=0
zoptparse "\$@" || exit 1

[ -z "\$date" ] || exit 1

exit 0

./test_unspecified0 --date=20130415
_unspecified0

# check that an unspecified variable overrides an existing value
cat <<_unspecified2 > test_unspecified2
#!/bin/bash
source "$1"

_zstrict=2
myvar=baz
zoptparse "\$@" || exit 1

[ "\$myvar" = "foo" ] || exit 1
exit 0

./test_unspecified2 --myvar=foo
_unspecified2

# check that an optional variable is set properly if _zstrict=0
cat <<_strict0 > test_strict0
#!/bin/bash
source "$1"

zoptional=("date")
_zstrict=0
zoptparse "\$@" || exit 1

[ "\$date" = "20130415" ] || exit 1

exit 0

./test_strict0 --date=20130415
_strict0

# check that a required value is read properly 
cat <<_required0 > test_required0
#!/bin/bash
source "$1"

zrequired=( "date" )
zoptparse "\$@" || exit 1

[ "\$date" = "20130415" ] || exit 1
exit 0

./test_required0 --date=20130415
_required0

# check that a required value can accept spaces
cat <<_required1 > test_required1
#!/bin/bash
source "$1"

zrequired=( "date" )
zoptparse "\$@" || exit 1

[ "\$date" = "20130415 blah" ] || exit 1
exit 0

./test_required1 --date='20130415 blah'
_required1

# spaces must be quoted else value is truncated
cat <<_required2 > test_required2
#!/bin/bash
source "$1"

zrequired=( "date" )
zoptparse "\$@" || exit 1

[ "\$date" = "20130415" ] || exit 1
exit 0

./test_required2 --date=20130415 blah
_required2

# check that an optional value is properly set
cat <<_optional0 > test_optional0
#!/bin/bash
source "$1"

zoptional=( "date" )
zoptparse "\$@" || exit 1

[ "\$date" = "20130415" ] || exit 1
exit 0

./test_optional0 --date='20130415'
_optional0

# check that an optional value is properly set
cat <<_optional1 > test_optional1
#!/bin/bash
source "$1"

zoptional=( "date" )
zoptparse "\$@" || exit 1

[ -z "\$date" ] || exit 1
exit 0

./test_optional1
_optional1

# check that an optional value is properly set
cat <<_optional2 > test_optional2
#!/bin/bash
source "$1"

zoptional=( "date" )
zoptparse "\$@" || exit 1

[ "\$date" = "date" ] || exit 1
exit 0

./test_optional2 --date
_optional2

# check that an optional value can accept spaces
cat <<_optional3 > test_optional3
#!/bin/bash
source "$1"

zoptional=( "date" )
zoptparse "\$@" || exit 1

[ "\$date" = "20130415 blah" ] || exit 1
exit 0

./test_optional3 --date="20130415 blah"
_optional3

# check that an optional value has correct default value if unspecified
cat <<_optional4 > test_optional4
#!/bin/bash
source "$1"

zoptional=( "date|20120101" )
zoptparse "\$@" || exit 1

[ "\$date" = "20120101" ] || exit 1
exit 0

./test_optional4 
_optional4

# check that an optional value is not defaulted if unspecified but it already has a value
cat <<_optional5 > test_optional5
#!/bin/bash
source "$1"

date=20120315

zoptional=( "date|20120101" )
zoptparse "\$@" || exit 1

[ "\$date" = "20120315" ] || exit 1
exit 0

./test_optional5
_optional5

# a complex example
cat <<_complex0 > test_complex0
#!/bin/bash
source "$1"

zrequired=( "date" "time" )
zoptional=( "one|1" "two|2" )
zoptparse "\$@" || exit 1

[ "\$date" = "20130415" ] && [ "\$time" = "2:30 pm" ] && [ "\$one" = 1 ] && [ "\$two" = 3 ] || exit 1
exit 0

./test_complex0 --date=20130415 --two=3 --time='2:30 pm'
_complex0

# option processing ends early when a non-option is seen, causing
# an error due to a required variable not being set
cat <<_complex1 > test_complex1
#!/bin/bash
source "$1"

zrequired=( "date" "time" )
zoptional=( "one|1" "two|2" )
zoptparse "\$@" || exit 1

exit 0

./test_complex1 --date=20130415 bar --two=3 --time='2:30 pm' 2>&1 | grep -q 'time'
_complex1

# --foo bar is not supported, unfortunately
cat <<_unsupported0 > test_unsupported0
#!/bin/bash
source "$1"

zrequired=( "foo" )
zoptparse "\$@" || exit 1

[ "\$foo" = "bar" ] || exit 1
exit 0

./test_unsupported0 --foo bar 2>&1 | grep -q 'spaces'
_unsupported0


# now each unit test is run in its own subshell
for t in *; do
    chmod +x $t \
        && ( bash -c "$(tail -1 $t)" ) \
        && echo "$t SUCCESS" \
        || (echo "$t FAIL" && cat $t && mv $t /tmp && exit 1)
done

popd >/dev/null
