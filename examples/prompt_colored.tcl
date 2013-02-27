
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

puts "echo: [linenoise prompt -prompt "\033\[36mhello\033\[0m> " -complete do-complete]"

# \033\[36m - cyan, foreground
# \033\[0m  - reset
# 5+4 characters which are both width 0 in the end.
exit
