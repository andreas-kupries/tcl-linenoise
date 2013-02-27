
package require linenoise

puts "linenoise [package require linenoise]"
#puts [package ifneeded linenoise [package present linenoise]]

puts "Max history: [linenoise history max]"
puts "New Max:     [linenoise history max 20]"

puts "Width: [linenoise columns]"

proc do-complete {line} {
    if {$line ne "h"} return
    list hello {hello there}
}

linenoise history load history.txt
puts "In history: [linenoise history size]"

puts "echo: [linenoise prompt -prompt "hello> " -complete do-complete]"

linenoise history clear
puts "In history: [linenoise history size]"
linenoise history add alpha
linenoise history add eta
linenoise history add omega
linenoise history add upsilon
puts "In history: [linenoise history size]"
puts \t[join [linenoise history list] \n\t]

puts "echo: [linenoise prompt -prompt "world> "]"

linenoise history save history_saved.txt


linenoise hidden 1
puts "echo: [linenoise prompt -prompt "password> "]"
linenoise hidden 0
