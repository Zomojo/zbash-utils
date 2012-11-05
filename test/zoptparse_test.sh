#!/bin/bash

source "./zoptparse.sh"

zrequired=("one" "two|hello there" "three")

unset -v one two three help opt optchar

zoptparse

unset -v one two three help opt optchar

zoptparse --one=hello
echo "one=[$one]"
echo "two=[$two]"
echo "three=[$three]"
echo "help=[$help]"

unset -v one two three help opt optchar

zoptparse --help
echo "one=[$one]"
echo "two=[$two]"
echo "three=[$three]"
echo "help=[$help]"

unset -v four help zrequired opt optchar
zrequired=("four")
zoptional=("five|3" "six|1|help for six" "seven||no value set" "eight|" "nine")

zoptparse --four=12
echo "four=[$four]"
echo "five=[$five]"
echo "six=[$six]"
echo "seven=[$seven]"
echo "eight=[$eight]"
echo "nine=[$nine]"

unset -v four five six seven eight nine help opt optchar

zrequired=("four")
zoptional=("five|3" "six|1|help for six" "seven||no value set" "eight|" "nine")
zoptparse --help
echo "four=[$four]"
echo "five=[$five]"
echo "six=[$six]"
echo "seven=[$seven]"
echo "eight=[$eight]"
echo "nine=[$nine]"
