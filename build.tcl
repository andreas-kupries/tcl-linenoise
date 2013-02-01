#!/bin/sh
# -*- tcl -*- \
# https://chiselapp.com/user/andreas_kupries/repository/Kettle \
exec kettle -f "$0" "${1+$@}"
kettle critcl3
kettle gh-pages
