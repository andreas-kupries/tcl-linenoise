lappend auto_path ZZZ/lib
package require linenoise

puts "linenoise [package require linenoise]"
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
