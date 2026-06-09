#!/bin/bash
# creates ~50000 test files under /home/pi/testdata (created for rpi deployment)
# usage: ./setup_test_files.sh [output_dir]

BASE="${BASE:-${1:-/home/pi/testdata}}"
FOLDER_COUNT=50
FILES_PER_FOLDER=1000

EXTENSIONS=(txt md cfg log dat bak sh py html css xml json csv sql proto yaml)

FOLDER_NAMES=(
    audio   video   image   backup  source  config  archive temp    data    logs
    cache   queue   stack   node    patch   error   event   frame   block   chain
    route   track   shift   blend   draft   final   copy    merge   quick   basic
    extra   hello   world   report  secret  public  common  simple  sample  starter
    debug   release home    about   help    info    hint    guide   notes   assets
)

FILE_NAMES=(
    readme  index   main    setup   init    build   run     test
    page    style   script  layout  header  footer  input   output
    cache   queue   stack   node    patch   log     error   event
    frame   block   chain   route   track   shift   blend   draft
    final   copy    merge   quick   basic   extra   hello   world
    report  secret  public  common  simple  sample  starter debug
    release home    about   help    info    hint    guide   notes
    config  setup   start   stop    check   list    find    search
    fetch   send    move    save    load    read    write   exec
    compile run     debug   trace   dump    flush   clear   reset
    grab    pull    push    sync    clone   stash   query   table
    index   view    create  drop    insert  select  auth    login
    logout  token   session user    admin   role    api     route
    handler request response client  server  proxy   store   pool
    queue   bus     topic   stream  pipe
)

rm -rf "$BASE"
mkdir -p "$BASE"

for dir_name in "${FOLDER_NAMES[@]:0:$FOLDER_COUNT}"; do
    dir="$BASE/$dir_name"
    mkdir -p "$dir"
    for ((f = 0; f < FILES_PER_FOLDER; f++)); do
        name="${FILE_NAMES[$((RANDOM % ${#FILE_NAMES[@]}))]}"
        ext="${EXTENSIONS[$((RANDOM % ${#EXTENSIONS[@]}))]}"
        touch "$dir/${name}_${f}.${ext}"
    done
    # create exact-named files for hash O(1) lookup testing
    for name in readme index main config setup; do
        touch "$dir/${name}"
    done
done

total=$((FOLDER_COUNT * (FILES_PER_FOLDER + 5)))
echo "created ~$total test files in $BASE"
find "$BASE" -type f | wc -l
