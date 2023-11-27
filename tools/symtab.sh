#!/bin/sh

split() {
    cut -c1-16 "$1"
    cut -c20-35 "$1"
    cut -c39-54 "$1"
    cut -c58-73 "$1"
    cut -c77-92 "$1"
    cut -c96-111 "$1"
}

for i in "$@"; do
    split "$i"
done
