#!/usr/bin/env tclsh
# -*- tcl -*-
package require Tcl 8.5
package require linenoise

puts "Linenoise [package require linenoise] loaded"
#puts [package ifneeded linenoise [package present linenoise]]

# Simple completion callback
proc do-complete {line} {
    if {$line ne "h"} return
    list hello {hello there}
}

# \033\[36m - cyan, foreground
# \033\[0m  - reset
# 5+4 characters which are both width 0 in the end.

set value [linenoise prompt \
	       -prompt "\033\[36mhello\033\[0m> " \
	       -complete do-complete]

puts "Entered: $value"
exit
