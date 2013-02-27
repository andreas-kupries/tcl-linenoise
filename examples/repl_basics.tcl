#!/usr/bin/env tclsh
# -*- tcl -*-
package require Tcl 8.5
package require linenoise

puts "Linenoise [package require linenoise] loaded."
#puts [package ifneeded linenoise [package present linenoise]]

set counter 0
linenoise cmdloop \
    -exit {apply {{} {
	global counter
	expr {$counter > 3}
    }}} -prompt1 {apply {{} {
	global counter
	return "[file tail [pwd]] ([incr counter]): "
    }}} -prompt2 {apply {{} {
	global counter
	return "[file tail [pwd]] ($counter)> "
    }}} -history on
puts done
exit
