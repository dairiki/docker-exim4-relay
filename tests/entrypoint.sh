#!/bin/bash -e

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>- && pwd)"
# PATH="${here}/bin:${PATH}"

# FD 3 is for debug information, normally it goes to /dev/null
if [[ $SUT_VERBOSE ]]; then
    exec 3>&1
else
    exec 3>/dev/null
fi

failed="$(mktemp)"
trap "rm -f '$failed'" 0

run_test () {
    local test="$1"
    echo "Running $test ... "
    if "$test"; then
	echo "PASSED $test"
    else
	echo "FAILED $test" 1>&2
	echo "$test" >> "$failed"
    fi
}

    
for test in "$here"/test_*; do
    tests+=("$test")
    run_test "$test" &
done
wait
failures="$(wc -l <"$failed")"
if (( failures )); then
    echo "*** Failed $failures of ${#tests[@]} tests ***" >&2
    [[ $SUT_VERBOSE ]] ||
	echo "Run with SUT_VERBOSE=1 for more verbose output." >&2
    exit 1
else
    echo "Passed all ${#tests[@]} tests"
fi
