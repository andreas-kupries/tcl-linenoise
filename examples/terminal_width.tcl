
package require linenoise

puts "linenoise [package require linenoise]"
#puts [package ifneeded linenoise [package present linenoise]]

puts "Terminal width = [linenoise columns]"
