#!/bin/bash
# test_search.sh: comprehensive test suite for filesearch
# runs hundreds of searches across edge cases and compares
# linear vs hash table performance
#
# requires: ./filesearch binary and /home/pi/testdata
# usage: ./test_search.sh

ITERATIONS=5

echo "============================================="
echo "  filesearch performance test suite"
echo "============================================="
echo ""

FILE_COUNT=$(find /home/pi/testdata -type f 2>/dev/null \
    | wc -l)
echo "test dataset: $FILE_COUNT files"
echo "iterations per query: $ITERATIONS"
echo ""

# test cases: "query|expect_results(yes/no)|category"
# categories: exact, ext, sub, none, short
TEST_CASES=(
    # exact filenames - should match
    "hello|yes|exact"
    "readme|yes|exact"
    "script|yes|exact"
    "index|yes|exact"
    "debug|yes|exact"
    "merge|yes|exact"
    "config|yes|exact"
    "output|yes|exact"
    "input|yes|exact"
    "setup|yes|exact"
    "start|yes|exact"
    "stop|yes|exact"
    "query|yes|exact"
    "table|yes|exact"
    "auth|yes|exact"
    "login|yes|exact"
    "token|yes|exact"
    "session|yes|exact"
    "user|yes|exact"
    "admin|yes|exact"
    "role|yes|exact"
    "api|yes|exact"
    "route|yes|exact"
    "handler|yes|exact"
    "request|yes|exact"
    "response|yes|exact"
    "client|yes|exact"
    "server|yes|exact"
    "proxy|yes|exact"
    "store|yes|exact"
    "pool|yes|exact"
    "queue|yes|exact"
    "bus|yes|exact"
    "topic|yes|exact"
    "stream|yes|exact"
    "pipe|yes|exact"

    # extension matches - should match
    ".txt|yes|ext"
    ".cfg|yes|ext"
    ".log|yes|ext"
    ".yaml|yes|ext"
    ".proto|yes|ext"
    ".json|yes|ext"
    ".xml|yes|ext"
    ".html|yes|ext"
    ".css|yes|ext"
    ".py|yes|ext"
    ".sh|yes|ext"
    ".bak|yes|ext"
    ".dat|yes|ext"
    ".sql|yes|ext"
    ".csv|yes|ext"
    ".md|yes|ext"

    # substring matches - should match
    "re|yes|sub"
    "se|yes|sub"
    "in|yes|sub"
    "ou|yes|sub"
    "lo|yes|sub"
    "st|yes|sub"
    "ch|yes|sub"
    "an|yes|sub"
    "te|yes|sub"
    "bl|yes|sub"
    "ex|yes|sub"
    "fi|yes|sub"
    "da|yes|sub"
    "co|yes|sub"
    "pr|yes|sub"

    # no matches expected
    "notfound|no|none"
    "xyz|no|none"
    "zzzzz|no|none"
    "aaabbbccc|no|none"
    "qwerty|no|none"
    "abcdef|no|none"
    "12345|no|none"
    "!@#$|no|none"

    # single and short chars
    "a|yes|short"
    "b|yes|short"
    "c|yes|short"
    "ab|yes|short"
    "xy|yes|short"
)

# category aggregators
declare -A CAT_LIN CAT_HASH CAT_CNT

PASS=0
FAIL=0
TOTAL_LIN=0
TOTAL_HASH=0
COUNT=0

printf "%-24s %6s %10s %10s  %-6s %s\n" \
    "QUERY" "FOUND" "LIN(us)" "HASH(us)" "STATUS" "CAT"
printf "%-24s %6s %10s %10s  %-6s %s\n" \
    "------------------------" "------" \
    "----------" "----------" "------" "---"

for case in "${TEST_CASES[@]}"; do
    IFS='|' read -r query expected cat <<< "$case"

    # build input: repeat query N times then quit
    input=""
    for ((i = 0; i < ITERATIONS; i++)); do
        input+="${query}"$'\n'
    done
    input+="quit"$'\n'

    # capture full output
    output=$(echo "$input" | ./filesearch 2>/dev/null)

    # grab last timing lines
    last_lin=$(echo "$output" | grep "^linear:" | tail -1)
    last_hash=$(echo "$output" | grep "^hash:" | tail -1)

    lin_time=$(echo "$last_lin" | awk '{print $2}')
    hash_time=$(echo "$last_hash" | awk '{print $2}')
    lin_count=$(echo "$last_lin" \
        | awk -F', ' '{print $2}' | awk '{print $1}')
    hash_count=$(echo "$last_hash" \
        | awk -F', ' '{print $2}' | awk '{print $1}')

    lin_time=${lin_time:-0}
    hash_time=${hash_time:-0}
    lin_count=${lin_count:-0}
    hash_count=${hash_count:-0}

    # correctness check
    if [ "$expected" = "no" ]; then
        if [ "$lin_count" = "0" ] \
            && [ "$hash_count" = "0" ]; then
            status="PASS"; PASS=$((PASS + 1))
        else
            status="FAIL"; FAIL=$((FAIL + 1))
        fi
    else
        if [ "$lin_count" -gt 0 ] 2>/dev/null \
            && [ "$hash_count" -gt 0 ] 2>/dev/null; then
            status="PASS"; PASS=$((PASS + 1))
        else
            status="FAIL"; FAIL=$((FAIL + 1))
        fi
    fi

    TOTAL_LIN=$((TOTAL_LIN + lin_time))
    TOTAL_HASH=$((TOTAL_HASH + hash_time))
    COUNT=$((COUNT + 1))

    # aggregate by category
    CAT_LIN[$cat]=$((CAT_LIN[$cat] + lin_time))
    CAT_HASH[$cat]=$((CAT_HASH[$cat] + hash_time))
    CAT_CNT[$cat]=$((CAT_CNT[$cat] + 1))

    printf "%-24s %6s %10s %10s  %-6s %s\n" \
        "\"$query\"" "$lin_count" \
        "$lin_time" "$hash_time" "$status" "$cat"
done

echo ""
echo "============================================="
echo "  SUMMARY"
echo "============================================="
echo ""

AVG_LIN=$((TOTAL_LIN / COUNT))
AVG_HASH=$((TOTAL_HASH / COUNT))
TOTAL_SEARCHES=$((COUNT * ITERATIONS))

printf "test cases:      %d\n" "$COUNT"
printf "total searches:  %d\n" "$TOTAL_SEARCHES"
printf "passed:          %d\n" "$PASS"
printf "failed:          %d\n" "$FAIL"
echo ""

echo "============================================="
echo "  TIMING CHART:  linear vs hash  (all in us)"
echo "============================================="
echo ""

# overall row
AVG_LIN=$((TOTAL_LIN / COUNT))
AVG_HASH=$((TOTAL_HASH / COUNT))
AVG_DIFF=$((AVG_LIN > AVG_HASH ? AVG_LIN - AVG_HASH : AVG_HASH - AVG_LIN))
if [ "$AVG_LIN" -gt "$AVG_HASH" ]; then
    FAST="hash"
    RATIO=$((AVG_LIN * 100 / AVG_HASH - 100))
elif [ "$AVG_HASH" -gt "$AVG_LIN" ]; then
    FAST="linear"
    RATIO=$((AVG_HASH * 100 / AVG_LIN - 100))
else
    FAST="tie"
    RATIO=0
fi

printf "%-20s  %8s  %8s  %8s  %s\n" \
    "CATEGORY" "CASES" "LIN(us)" "HASH(us)" "FASTER"
printf "%-20s  %8s  %8s  %8s  %s\n" \
    "--------------------" "--------" \
    "--------" "--------" "----------------"

printf "%-20s  %8d  %8d  %8d  " \
    "ALL" "$COUNT" "$AVG_LIN" "$AVG_HASH"
if [ "$FAST" = "tie" ]; then
    printf "%s\n" "tie"
else
    printf "%s by %d%%\n" "$FAST" "$RATIO"
fi

echo ""

# per-category rows
for cat_label in "exact:exact filename" "ext:extension" "sub:substring" \
                 "none:no match" "short:single/short char"; do
    IFS=':' read -r cat_key cat_name <<< "$cat_label"
    n=${CAT_CNT[$cat_key]}
    n=${n:-0}
    if [ "$n" -gt 0 ]; then
        a_lin=$((CAT_LIN[$cat_key] / n))
        a_hash=$((CAT_HASH[$cat_key] / n))
        diff=$((a_lin > a_hash ? a_lin - a_hash : a_hash - a_lin))
        if [ "$a_lin" -gt "$a_hash" ]; then
            f="hash"
            r=$((a_lin * 100 / a_hash - 100))
        elif [ "$a_hash" -gt "$a_lin" ]; then
            f="linear"
            r=$((a_hash * 100 / a_lin - 100))
        else
            f="tie"
            r=0
        fi

        printf "%-20s  %8d  %8d  %8d  " \
            "$cat_name" "$n" "$a_lin" "$a_hash"
        if [ "$f" = "tie" ]; then
            printf "%s\n" "tie"
        elif [ "$r" -lt 1 ]; then
            printf "%s (<1%%)\n" "$f"
        else
            printf "%s by %d%%\n" "$f" "$r"
        fi
    fi
done

echo ""

echo "--- asymptotic complexity ---"
echo "linear array search:  O(n)"
echo "hash exact filename:  O(1) average  (single bucket)"
echo "hash substring/ext:   O(n)          (scans all buckets)"
echo ""

