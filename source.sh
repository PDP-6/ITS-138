#!/bin/sh

fix() {
    case "$1" in
        *page0000.txt) return;;       #Skip "ITS 138" page.
        *page0010.txt) ;;             #No page break before first page.
        *page1190.txt) exit 0;;       #Leave out symbol table.
        *page???0.txt) printf '\f';;
    esac
    head -1 "$1" | cut -c17- | sed 's/ *PAGE [0-9.]*$//' | ./tabify
    tail -n +2 "$1" | cut -c17- | ./tabify
}

make tabify >/dev/null 2>&1

for i in transcribed/page*.txt; do
    fix "$i"
done
