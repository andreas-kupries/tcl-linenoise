
package require linenoise

puts "linenoise [package require linenoise]"
#puts [package ifneeded linenoise [package present linenoise]]

puts "Max history: [linenoise history max]"
puts "New Max:     [linenoise history max 20]"

proc do-complete {line} {
    if {$line ne "h"} return
    list hello {hello there}
}

linenoise history load history.txt
puts "In history: [linenoise history size]"

puts "echo: [linenoise prompt "hello> " do-complete]"

linenoise history clear
puts "In history: [linenoise history size]"
linenoise history add alpha
linenoise history add eta
linenoise history add omega
linenoise history add upsilon
puts "In history: [linenoise history size]"

puts "echo: [linenoise prompt "world> "]"

linenoise history save history_saved.txt
