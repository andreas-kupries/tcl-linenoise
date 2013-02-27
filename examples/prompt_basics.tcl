#!/usr/bin/env tclsh
# -*- tcl -*-
package require Tcl 8.5
package require linenoise

puts "Linenoise [package require linenoise] loaded."
#puts [package ifneeded linenoise [package present linenoise]]

puts "Max history: [linenoise history max]"
puts "New Max:     [linenoise history max 20]"

proc do-complete {line} {
    if {$line ne "h"} return
    list hello {hello there}
}

linenoise history load history.txt
puts "In history: [linenoise history size]"

set value [linenoise prompt \
	       -prompt "hello> " \
	       -complete do-complete]

puts "Entered: $value"

linenoise history clear
puts "In history: [linenoise history size]"
linenoise history add alpha
linenoise history add eta
linenoise history add omega
linenoise history add upsilon
puts "In history: [linenoise history size]"
puts \t[join [linenoise history list] \n\t]

puts "Entered: [linenoise prompt -prompt "world> "]"

linenoise history save history_saved.txt
exit
