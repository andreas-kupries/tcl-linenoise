#!/usr/bin/env tclsh
# -*- tcl -*-
package require Tcl 8.5
package require linenoise

puts "Linenoise [package require linenoise] loaded."
#puts [package ifneeded linenoise [package present linenoise]]

puts "Terminal width: [linenoise columns]"
exit
