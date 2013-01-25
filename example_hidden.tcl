package require linenoise

puts "linenoise [package require linenoise]"
#puts [package ifneeded linenoise [package present linenoise]]

# To check that we are unable to access this.
linenoise history add alpha
linenoise history add eta
linenoise history add omega
linenoise history add upsilon
puts "History: [linenoise history size]"

linenoise hidden 1
puts hidden=[linenoise hidden]
puts "echo: [linenoise prompt "password> "]"
linenoise hidden 0
puts hidden=[linenoise hidden]
puts done
