#!/usr/bin/env bash

OPTIND=1
SHOW_COLOR=false
DELETE_LOGS=false
THRESHOLD="0.0005"

while getopts "cDt:" opt; do
	case "$opt" in
	c)
		SHOW_COLOR=true
		;;
    D)
        DELETE_LOGS=true
        ;;
	t)
		THRESHOLD=$OPTARG
		;;
	*)
		;;
	esac
done

shift $((OPTIND-1))

if $DELETE_LOGS; then
    rm /tmp/sample-time*
    exit 0
fi

if $SHOW_COLOR; then
	COLOR_CMD="awk -v threshold=$THRESHOLD "
	# shellcheck disable=SC2016
	COLOR_CMD+=''\''{if ($1 > threshold) print "\033[1;31m" $0; else print "\033[0m" $0; fi;}'\'''
else
	COLOR_CMD='cat'
fi

SCRIPT="$1"
shift

# Profiling
exec 3>&2 2> >(tee /tmp/sample-time.$$.log |
                 sed -u 's/^.*$/now/' |
                 date -f - +%s.%N >/tmp/sample-time.$$.tim)
set -x

# shellcheck source=/dev/null
source "$SCRIPT"

# Profiling
set +x
exec 2>&3 3>&-

readarray -n 2 FILE_NAMES< <(find /tmp -type f -name "sample-time*" -printf '%T@ %p\n' 2>/dev/null \
	| sort -n | tail -2 | cut -f2- -d" "); \
	LOG_FILE="${FILE_NAMES[0]//[$'\t\r\n']}" \
	TIME_FILE="${FILE_NAMES[1]//[$'\t\r\n']}"

paste <(
    while read -r tim ;do
        crt=000000000$((${tim//.}-10#0$last))
        printf "%12.9f\n" ${crt:0:${#crt}-9}.${crt:${#crt}-9}
        last=${tim//.}
      done < "$TIME_FILE"
  ) "$LOG_FILE" | eval $COLOR_CMD

printf "\033[0m"

echo "Total" "$(bc -l <<< "$(tail -n 1 "$TIME_FILE") - $(head -n 1 "$TIME_FILE")")"
