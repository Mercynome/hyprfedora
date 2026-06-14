#!/bin/bash
updates=$(dnf check-update -q | grep -c -E '^[a-zA-Z0-9]')

if [ "$updates" -gt 0 ]; then
    echo "{\"text\": \"$updates\", \"tooltip\": \"$updates update(s) available via DNF\"}"
else
    echo "{\"text\": \"0\", \"tooltip\": \"System is up to date\"}"
fi
