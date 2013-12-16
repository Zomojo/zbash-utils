#!/bin/bash
# perform a series of unit tests for zoptparse.sh

set -e

if [ -z "$1" ]; then
    echo "usage: $0 FULL/PATH/TO/zsandbox"
    exit 1
fi

ZS="$1"

[ -e "$ZS" ];

tmp=$(mktemp -d -q --tmpdir="/tmp" "zsandbox-unit-test.XXXXXXXX")
#trap "rm -rf $tmp" EXIT

if ! pushd "$tmp" >/dev/null ; then
    echo "couldn't cd into temporary directory [$tmp]"
    exit 1
fi

# check a trivial echo command
cat <<_echotest > test_echo
#!/bin/bash
mkdir -p $tmp/_echotest
$ZS --debug --working-dir=$tmp/_echotest /bin/echo hi
grep '/bin/echo hi' $tmp/_echotest/zsandbox.cmdline && [ ! -s $tmp/_echotest/zsandbox.stderr ]
exit 0

./test_echo
_echotest

# check disk usage
cat <<_echotestdisk > test_echo_disk
#!/bin/bash
set -e
mkdir -p $tmp/_echotestdisk
if $ZS --debug --fail-if-disk-full-above=0 --working-dir=$tmp/_echotestdisk /bin/echo hi 2&>/dev/null; then
  zerror "this command should have failed, but succeeded unexpectedly"
fi
exit 0

./test_echo_disk
_echotestdisk


# check install dummy package
cat <<_echotestbin > test_echo_binaries
#!/bin/bash

mkdir -p ibin
cp /bin/echo ibin
tar cfz binaries.tar.gz ibin

set -e
mkdir -p $tmp/_echotestdisk
$ZS --debug --install-package=localhost:$tmp/binaries.tar.gz --working-dir=$tmp/_echotestbin /bin/echo hi
[ -d $tmp/_echotestbin/ibin ]
[ -f $tmp/_echotestbin/ibin/echo ]
exit 0

./test_echo_binaries
_echotestbin


# now each unit test is run in its own subshell
for t in *; do
    chmod +x $t \
        && ( bash -c "$(tail -1 $t)" ) \
        && echo "$t SUCCESS" \
        || (echo "$t FAIL" && cat $t && mv $t /tmp && exit 1)
done

popd >/dev/null
