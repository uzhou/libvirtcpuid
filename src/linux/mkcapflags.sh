#!/bin/sh
# The content of this file is from the Linux kernel:
# - arch/x86/kernel/cpu/mkcapflags.sh
# Took out the file header and bugs array
#


# SPDX-License-Identifier: GPL-2.0
#
# Generate the x86_cap/bug_flags[] arrays from include/asm/cpufeatures.h
#

set -e

IN=$1
OUT=$2

dump_array()
{
	ARRAY=$1
	SIZE=$2
	PFX=$3
	POSTFIX=$4

	PFX_SZ=$(echo $PFX | wc -c)
	TABS="$(printf '\t\t\t\t\t')"

	echo "const char * const $ARRAY[$SIZE] = {"

	# Iterate through any input lines starting with #define $PFX
	sed -n -e 's/\t/ /g' -e "s/^ *# *define *$PFX//p" $IN |
	while read i
	do
		# Name is everything up to the first whitespace
		NAME="$(echo "$i" | sed 's/ .*//')"

		# If the /* comment */ starts with a quote string, grab that.
		VALUE="$(echo "$i" | sed -n 's@.*/\* *\("[^"]*"\).*\*/@\1@p')"
		[ -z "$VALUE" ] && VALUE="\"$NAME\""
		# Note: In the cpufeatures.h, names of "" are skipped.
		# We don't want to skip them.
		#[ "$VALUE" = '""' ] && continue
		[ "$VALUE" = '""' ] && VALUE="\"$NAME\""

		# Name is uppercase, VALUE is all lowercase
		VALUE="$(echo "$VALUE" | tr A-Z a-z)"

        if [ -n "$POSTFIX" ]; then
            T=$(( $PFX_SZ + $(echo $POSTFIX | wc -c) + 2 ))
	        TABS="$(printf '\t\t\t\t\t\t')"
		    TABCOUNT=$(( ( 6*8 - ($T + 1) - $(echo "$NAME" | wc -c) ) / 8 ))
		    printf "\t[%s - %s]%.*s = %s,\n" "$PFX$NAME" "$POSTFIX" "$TABCOUNT" "$TABS" "$VALUE"
        else
		    TABCOUNT=$(( ( 5*8 - ($PFX_SZ + 1) - $(echo "$NAME" | wc -c) ) / 8 ))
            printf "\t[%s]%.*s = %s,\n" "$PFX$NAME" "$TABCOUNT" "$TABS" "$VALUE"
        fi
	done
	echo "};"
}

trap 'rm "$OUT"' EXIT

(
	echo "// Autogenerated file"
	dump_array "x86_cap_flags" "NCAPINTS*32" "X86_FEATURE_" ""

) > $OUT

trap - EXIT
