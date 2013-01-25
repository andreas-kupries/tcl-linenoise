## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Copyright (C) 2013 Andreas Kupries
#
## This is the policy file aggregating the C primitives into a tcl-ish
## interface.

# # ## ### ##### ######## ############# #####################
## History sub interface.
## The saving and loading primitives are wrapped for proper
## integration of the exported commands within Tcl's VFS.

namespace eval linenoise::history {}

if {[package vsatisfies [package present Tcl] 8.6]} {
    # Tcl 8.6, and higher. We have "file tempfile".

    proc ::linenoise::history::TempFile {} {
	close [file tempfile tmp linenoise_history_]
	return $tmp
    }
} else {
    # Before Tcl 8.6, we have to make our own tempfile command.
    # The code here snarfed from Tcllib, module/package "fileutil".
    # BSD license.

    proc ::linenoise::history::TempFile {} {
	set tmpdir [file normalize [TempDir]]
	set prefix linenoise_history_

	set chars "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	set nrand_chars 10
	set maxtries 10
	set access [list RDWR CREAT EXCL TRUNC]
	set permission 0600
	set channel ""
	set checked_dir_writable 0
	set mypid [pid]
	for {set i 0} {$i < $maxtries} {incr i} {
	    set newname $prefix
	    for {set j 0} {$j < $nrand_chars} {incr j} {
		append newname [string index $chars \
				    [expr {int(rand()*62)}]]
	    }
	    set newname [file join $tmpdir $newname]
	    if {[file exists $newname]} {
		after 1
	    } else {
		if {[catch {open $newname $access $permission} channel]} {
		    if {!$checked_dir_writable} {
			set dirname [file dirname $newname]
			if {![file writable $dirname]} {
			    return -code error "Directory $dirname is not writable"
			}
			set checked_dir_writable 1
		    }
		} else {
		    # Success
		    close $channel
		    return $newname
		}
	    }
	}
	if {[string compare $channel ""]} {
	    return -code error "Failed to open a temporary file: $channel"
	} else {
	    return -code error "Failed to find an unused temporary file name"
	}
    }

    #	Return the correct directory to use for temporary files.
    #	Python attempts this sequence, which seems logical:
    #
    #       1. The directory named by the `TMPDIR' environment variable.
    #
    #       2. The directory named by the `TEMP' environment variable.
    #
    #       3. The directory named by the `TMP' environment variable.
    #
    #       4. A platform-specific location:
    #            * On Macintosh, the `Temporary Items' folder.
    #
    #            * On Windows, the directories `C:\\TEMP', `C:\\TMP',
    #              `\\TEMP', and `\\TMP', in that order.
    #
    #            * On all other platforms, the directories `/tmp',
    #              `/var/tmp', and `/usr/tmp', in that order.
    #
    #       5. As a last resort, the current working directory.
    #
    # Arguments:
    #	None.
    #
    # Side Effects:
    #	None.
    #
    # Results:
    #	The directory for temporary files.

    proc ::linenoise::history::TempDir {} {
	global tcl_platform env

	set candidates [list]
	set problems   {}

	foreach tmp {TMPDIR TEMP TMP} {
	    if { [info exists env($tmp)] } {
		lappend candidates $env($tmp)
	    } else {
		lappend problems "No environment variable $tmp"
	    }
	}

	switch $tcl_platform(platform) {
	    windows {
		lappend candidates "C:\\TEMP" "C:\\TMP" "\\TEMP" "\\TMP"
	    }
	    macintosh {
		lappend candidates $env(TRASH_FOLDER)  ;# a better place?
	    }
	    default {
		lappend candidates \
		    [file join / tmp] \
		    [file join / var tmp] \
		    [file join / usr tmp]
	    }
	}

	lappend candidates [pwd]

	foreach tmp $candidates {
	    if { [file isdirectory $tmp] && [file writable $tmp] } {
		return $tmp
	    } elseif { ![file isdirectory $tmp] } {
		lappend problems "Not a directory: $tmp"
	    } else {
		lappend problems "Not writable: $tmp"
	    }
	}

	# Fail if nothing worked.
	return -code error "Unable to determine a proper directory for temporary files\n[join $problems \n]"
    }
}

proc ::linenoise::history::load {path} {
    if {[lindex [file system $path] 0] eq "native"} {
	::linenoise::history_load $path
    } else {
	# Unload the history from VFS to a tempfile on disk, and then
	# load it from there.
	set tmp [TempFile]
	file copy -force $path $tmp
	::linenoise::history_load $tmp
	file delete $tmp
    }
}

proc ::linenoise::history::save {path} {
    if {[lindex [file system $path] 0] eq "native"} {
	::linenoise::history_save $path
    } else {
	# Save history to a temp file on disk, and then move to the
	# final destination in the VFS.
	set tmp [TempFile]
	::linenoise::history_save $tmp
	file rename -force $tmp $path
    }
}

proc ::linenoise::history::maxsize {{new {}}} {
    if {[llength [info level 0]] == 2} {
	if {![string is int -strict $new] || ($new < 1)} {
	    return -code error "Expected an integer >= 1, got \"$new\""
	}
	::linenoise::history_setmax $new
    }
    return [::linenoise::history_getmax]
}

namespace eval linenoise::history {
    namespace ensemble create -map {
	add     ::linenoise::history_add
	clear   ::linenoise::history_clear
	list    ::linenoise::history_list
	load    ::linenoise::history::load
	maxsize ::linenoise::history::maxsize
	save    ::linenoise::history::save
	size    ::linenoise::history_size
    }
}

# # ## ### ##### ######## ############# #####################
## Main interface, ensemble of the main primitives, plus the history
## sub-ensemble.

proc ::linenoise::prompt {args} {
    array set config {
	-prompt    {% }
	-history   0
	-hidden    0
	-complete  {}
    }

    foreach {o v} $args {
	switch -exact -- $o {
	    -complete -
	    -prompt   {
		set config($o) $v
	    }
	    -hidden -
	    -history {
		if {![string is boolean -strict $v]} {
		    return -code error \
			"Expected boolean, got \"$v\""
		}
		set config($o) $v
	    }
	    default {
		return -code error \
		    "Unknown option \"$o\", expected one of -prompt, -hidden, -history, or -complete"
	    }
	}
    }

    set savedhidden [hidden]
    hidden $config(-hidden)

    set code [catch {
	set result [Prompt $prompt $config(-complete)]
    } result options]

    if {!$code && $config(-history)} {
	history add $buffer
    }

    # Restore outer status of hidden
    hidden $savedhidden

    return -options $options $result
}

proc ::linenoise::hidden {{new {}}} {
    if {[llength [info level 0]] == 2} {
	if {![string is boolean -strict $new]} {
	    return -code error "Expected a boolean, got \"$new\""
	}
	::linenoise::hidden_set $new
    }
    return [::linenoise::hidden_get]
}

proc ::linenoise::cmdloop {args} {
    array set config {
	-prompt1   {apply {{} { return "% " }}}
	-prompt2   {apply {{} { return "> " }}}
	-dispatch  {uplevel 1}
	-continued {apply {{line} {expr {![info complete $line]}}}
	-complete  {}
	-history   0
    }

    foreach {o v} $args {
	switch -exact -- $o {
	    -complete -
	    -prompt1  -
	    -prompt2  -
	    -dispatch {
		set config($o) $v
	    }
	    -history {
		if {![string is boolean -strict $v]} {
		    return -code error \
			"Expected boolean, got \"$v\""
		}
		set config($o) $v
	    }
	    default {
		return -code error \
		    "Unknown option \"$o\", expected one of -prompt1, -prompt2, -history, -dispatch, -continued, or -complete"
	    }
	}
    }

    # Hidden input does not make sense for a command loop. But save
    # the current state (and restore it at the end), in case this is
    # nested.
    set savedhidden [hidden]

    set run 1
    while {$run} {
	set prompt [{*}$config(-prompt1)]
	set buffer {}
	while 1 {
	    hidden 0
	    if {[catch {
		# Inlined low-level command.
		Prompt $prompt $config(-complete)
	    } line]} {
		# Stop not only the collection loop, but the outer
		# prompt loop as well. Nothing is dispatched.
		set run 0
		break
	    }
	    append buffer $line
	    if {[{*}$config(-continued) $buffer\n]} {
		append buffer \n
		set prompt [{*}$config(-prompt2)]
		continue
	    }
	    # Stop collection loop.
	    break
	}
	if {$config(-history)} {
	    history add $buffer
	}
	set fail [catch {
	    {*}$config(-dispatch) $buffer
	} res]
	if {$fail || ($res ne {})} {
	    puts [expr {$fail ? "stderr" : "stdout"}] $res
	}
    }

    # Restore outer status of hidden
    hidden $savedhidden
    return
}

# # ## ### ##### ######## ############# #####################

namespace eval linenoise {
    # primitive commands:
    # - clear
    # - prompt (with completion) | wrapped
    # - history_add              | sub-ensemble, see above.
    # - history_clear            |
    # - history_load             | wrapped to handle VFS
    # - history_save             | ditto
    # - history_size             |
    # - history_getmax           | wrapped into combination
    # - history_setmax           | accessor command => history::max
    # - hidden_set               | wrapped into combination
    # - hidden_get               | accessor command => hidden
    # porcelain
    # - cmdloop

    namespace export clear history hidden prompt cmdloop
    namespace ensemble create
}
