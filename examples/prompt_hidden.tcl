#!/usr/bin/env tclsh
# -*- tcl -*-
package require Tcl 8.5
package require linenoise

puts "Linenoise [package require linenoise] loaded."
#puts [package ifneeded linenoise [package present linenoise]]

# To check that we are unable to access this in the prompt.
linenoise history add alpha
linenoise history add eta
linenoise history add omega
linenoise history add upsilon
puts "History: [linenoise history size]"
puts "Hidden:  [linenoise hidden]"

if {[linenoise::hidden_extended]} {
    #set hidden stars
    set hidden all
} else {
    set hidden yes
}

set password [linenoise prompt -hidden $hidden -prompt "password> "]

puts "Hidden:  [linenoise hidden]"
puts "Entered: $password"
exit
