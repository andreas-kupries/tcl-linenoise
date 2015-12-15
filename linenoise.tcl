# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## A Tcl Binding to antirez's linenoise (Minimal line-editing)
## as modified and extended by Steve Bennett of Workware.
##
## Copyright (c) 2013-2014 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries

# # ## ### ##### ######## ############# #####################
##
# Based on    git@github.com:andreas-kupries/linenoise.git
# Forked from  git@github.com:msteveb/linenoise.git
# Forked from   git@github.com:antirez/linenoise.git
#
# Based on     http://github.com/andreas-kupries/linenoise
# Forked from   http://github.com/msteveb/linenoise
# Forked from    http://github.com/antirez/linenoise

# # ## ### ##### ######## ############# #####################
##
# Notes and ideas regarding the underlying linenoise C library
#
# - Note: Do I need the utf support, or is that term specific?

# # ## ### ##### ######## ############# #####################
## Requisites

package require critcl 3.1
critcl::buildrequirement {
    package require critcl::util 1.1 ; # locate
}

# # ## ### ##### ######## ############# #####################

if {![critcl::compiling]} {
    error "Unable to build linenoise, no proper compiler found."
}

# # ## ### ##### ######## ############# #####################
## Administrivia

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {A line-editor package build on top of Steve Bennet's extensions to Salvator's (antirez) linenoise C library}

critcl::description {
    This package provides access to antirez's linenoise library for
    creating a line editor, as modified and extended by Steve Bennett
    (msteveb) of Workware, and myself. An important difference to
    readline/editline is the minimal approach of linenoise.
}

critcl::subject \
    {line editor} linenoise readline editline \
    {edit line} tty console terminal {read line} \
    {line reader}

critcl::meta location \
    http://github.com/andreas-kupries/tcl-linenoise

critcl::meta location/c-library \
    http://github.com/andreas-kupries/linenoise

critcl::meta location/c-library/msteveb \
    http://github.com/msteveb/linenoise

critcl::meta location/c-library/origin \
    http://github.com/antirez/linenoise

# # ## ### ##### ######## ############# #####################
## Implementation.

critcl::tcl 8.5

# # ## ### ##### ######## ############# #####################
## Find the linenoise sources (via its headers), and figure out their
## configuration.
#
# We specify both paths for where we expect to find the sources of
# linenoise itself. Both are given relative to the directory of this
# file.
#
# (1) A sub directory in our sources.
# (2) A sibling directory to our sources.

critcl::msg "\n"
# With Tcl 8.5+ CK could be replaced by a lambda.
proc PB {label x} { return "${label}: [expr {$x ? "yes" : "no"}]" }
proc CK {p} {
    # Check for "linenoiseAddCompletion", make sure that the found
    # header is the correct one.
    set lines [split [critcl::Cat $p] \n]
    set n [llength [critcl::Grep *linenoiseAddCompletion* $lines]]
    if {!$n} { return 0 }

    # Additional checks to figure out the libraries' configuration.
    set ::hashidden [llength [critcl::Grep *linenoiseGetHidden* $lines]]
    set ::exthidden [llength [critcl::Grep *LN_HIDDEN_STAR* $lines]]
    set ::haslines  [llength [critcl::Grep *linenoiseLines* $lines]]

    return 1
}

critcl::cheaders [critcl::util::locate "Location of Linenoise    " {
    linenoise/linenoise.h
    ../linenoise/linenoise.h
} ::CK]

#                Location of Linenoise
critcl::msg [PB {Support for hidden input } $hashidden]
critcl::msg [PB {Extended hidden input    } $exthidden]
critcl::msg [PB {Access to terminal height} $haslines]

rename CK {}
rename PB {}
critcl::msg ""

# # ## ### ##### ######## ############# #####################
## Declare the Tcl layer aggregating the C primitives into a Tclish
## API.

critcl::tsources policy.tcl

# # ## ### ##### ######## ############# #####################
## Main C section.

## ATTENTION! linenoise operates directly on the process's stdin file
##            descriptor. This makes its operation inherently thread-
##            unsafe.
#
## To rescue what we can we combine the actual prompting with the
## completion callback setup in a single command which mutex locks the
## whole user interaction. This allows it to not only use
## process-global variables, but also prevents multiple threads from
## fighting for user interaction, forcing serialization.

critcl::ccode {
    #include <linenoise.h>
    #include <linenoise.c>
    #include <tcl.h>

    /* The mutex serializing the threads requesting user interaction. */
    TCL_DECLARE_MUTEX (edit)

    /* The Tcl interpreter currently interacting with the user */
    Tcl_Interp* einterp;

    /* The Tcl-level completion callback for the current interaction,
     * if any.
     */
    Tcl_Obj* ecomplete;

    /* The C-level completion callback. Assumes that the e-variables
     * above are properly set, and that everything is locked to the
     * current thread.
     */
    static void
    linenoise_tcl_callback (const char* buffer, linenoiseCompletions* lc)
    {
	Tcl_SavedResult sr;
	Tcl_Obj* completions;
	Tcl_Obj* cmd;
	Tcl_Obj** listv;
	int i, listc, res = TCL_OK;

	/* Generate callback, extend prefix with argument */
	cmd = Tcl_DuplicateObj (ecomplete);
	Tcl_ListObjAppendElement (einterp, cmd, Tcl_NewStringObj (buffer, -1));

	/* Run the callback, result is (expected to be a)
	 * list of completions.
	 */
	Tcl_SaveResult (einterp, &sr);
	res         = Tcl_EvalObj (einterp, cmd);
	completions = Tcl_GetObjResult (einterp);

	/* Ignore failures, and results which are not lists */
	if ((res != TCL_OK) ||
	    (Tcl_ListObjGetElements (einterp, completions, &listc, &listv) != TCL_OK)) {
	    Tcl_RestoreResult (einterp, &sr);
	    return;
	}

	/* Copy the result over to linenoise structures */
	for (i=0; i< listc; i++) {
	    linenoiseAddCompletion (lc, Tcl_GetString (listv[i]));
	}

	Tcl_RestoreResult (einterp, &sr);
    }
}

# # ## ### ##### ######## ############# #####################
## Inner API: History primitives

# - Direct extension of history with a string.
# - Clearing the history
# - Loading the history from file (OS native path).
# - Saving the history to file (OS native path).
# - Setting and retrieving the maximal history size.
# - Retrieving current size of the history.
# - Retrieving the current contents of the history as a Tcl list.
#   (Saving the history to memory)
# - Setting the history from a Tcl list.
#   (Loading the history from memory)

critcl::cproc linenoise::history_add {char* line} boolean {
    return linenoiseHistoryAdd (line);
}

critcl::cproc linenoise::history_clear {} void {
    /* msteveb/linenoise extension */
    linenoiseHistoryFree ();
    /* bugfix! */
    history_len = 0;
}

# The caller is responsible for Tcl VFS integration (temp files, etc.).
# See policy.tcl for the wrapper code.
critcl::cproc linenoise::history_load {char* path} int {
    return linenoiseHistoryLoad (path);
}

# The caller is responsible for Tcl VFS integration (temp files, etc.)
# See policy.tcl for the wrapper code.
critcl::cproc linenoise::history_save {char* path} int {
    return linenoiseHistorySave (path);
}

# maxlen < 1 ==> 0, no change
# else       ==> 1, trim or expand
critcl::cproc linenoise::history_setmax {int maxlen} boolean {
    return linenoiseHistorySetMaxLen (maxlen);
}

# ATTENTION! We are poking into the internals of linenoise again.
critcl::cproc linenoise::history_getmax {} int {
    return linenoiseHistoryGetMaxLen ();
}

critcl::cproc linenoise::history_size {} int {
    /* msteveb/linenoise extension */
    int len;

    (void) linenoiseHistory (&len);
    return len;
}

critcl::cproc linenoise::history_set {
    Tcl_Interp* ip
    Tcl_Obj* list
} ok {
    /* Replace current history with the entries in the specified list */

    int i;
    int       lc;
    Tcl_Obj** lv;

    int r = Tcl_ListObjGetElements (ip, list, &lc, &lv);

    if (r != TCL_OK) {
	return r;
    }

    /* Inlined history_clear */
    /* msteveb/linenoise extension */
    linenoiseHistoryFree ();
    /* bugfix! */
    history_len = 0;

    for (i=0; i < lc; i++) {
       linenoiseHistoryAdd (Tcl_GetString (lv [i]));
    }
    return r;
}

critcl::cproc linenoise::history_list {} Tcl_Obj* {
    /* msteveb/linenoise extension */
    int i, len;
    char** h;
    Tcl_Obj* res;
    Tcl_Obj** lv;
    h = linenoiseHistory (&len);

    lv = (Tcl_Obj**) ckalloc (len * sizeof (Tcl_Obj*));
    for (i=0; i < len; i++) {
       lv [i] = Tcl_NewStringObj (h [i],-1);
    }
    res = Tcl_NewListObj (len, lv);
    ckfree ((char*) lv);

    Tcl_IncrRefCount (res);
    return res;
}

# # ## ### ##### ######## ############# #####################
## Inner API: Main primitives
## - modify/query the "hidden" flag
## - prompt for input, possibly with completion

if {$hashidden} {
    if {$exthidden} {
	critcl::msg -nonewline { (Use: Extended hidden input)}
	# Extended => modes = {no, (echo)stars, all|full|noecho}

	critcl::buildrequirement {
	    package require critcl::emap
	}

	# visible == no  == 0,
	# all     == yes == 1, -- default is full supression.
	# stars   == 2
	critcl::emap::def hiddenmode {
	            no  0 n 0 off 0 false 0 0 0
	    all   1 yes 1 y 1 on  1 true  1 1 1
	    stars 2
	} -nocase
	# result-type: hiddenmode
	# arg-type:    hiddenmode
	critcl::cproc linenoise::hidden_set {hiddenmode enable} void {
	    linenoiseSetHidden (enable);
	}
	critcl::cproc linenoise::hidden_get {} hiddenmode {
	    return linenoiseGetHidden ();
	}
	critcl::cproc linenoise::hidden_extended {} boolean {
	    return 1;
	}
    } else {
	critcl::msg -nonewline { (Use: Basic hidden input)}
	# Basic hidden => enable is boolean <=> on/off.

	critcl::cproc linenoise::hidden_set {boolean enable} void {
	    linenoiseSetHidden (enable);
	}
	critcl::cproc linenoise::hidden_get {} boolean {
	    return linenoiseGetHidden ();
	}
	critcl::cproc linenoise::hidden_extended {} boolean {
	    return 0;
	}
    }
} else {
    critcl::msg -nonewline { (Use: NO hidden input)}
}

if 0 {# may we have this ?
critcl::cproc linenoise::clear {} void {
    linenoiseClearScreen ();
}}

critcl::cproc linenoise::columns {} int {
    return linenoiseColumns ();
}

if {$haslines} {
    critcl::msg -nonewline { (Use: Query terminal height)}
    critcl::cproc linenoise::lines {} int {
	return linenoiseLines ();
    }
} else {
    critcl::msg -nonewline { (Use: NO querying terminal height)}
}

critcl::cproc linenoise::Prompt {
    Tcl_Interp* interp
    char*       prompt
    Tcl_Obj*    complete
} ok {
    Tcl_Obj** lv;
    int lc;
    char* line;

    if (Tcl_ListObjGetElements (einterp, complete,
				&lc, &lv) != TCL_OK) {
	return TCL_ERROR;
    }

    Tcl_MutexLock (&edit);

    if (!lc) {
	/* No completion callback. Simple prompting. */
	einterp   = 0;
	ecomplete = 0;
	linenoiseSetCompletionCallback (0);
    } else {
	einterp   = interp;
	ecomplete = complete;
	linenoiseSetCompletionCallback (linenoise_tcl_callback);
    }

    line = linenoise (prompt);

    linenoiseSetCompletionCallback (0);
    einterp   = 0;
    ecomplete = 0;

    Tcl_MutexUnlock (&edit);

    if (line == NULL) {
	Tcl_SetResult (interp, "aborted", TCL_STATIC);
	return TCL_ERROR;
    }

    Tcl_SetResult (interp, line, TCL_VOLATILE);
    return TCL_OK;
}

# # ## ### ##### ######## ############# #####################
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading linenoise failed."
}

# # ## ### ##### ######## ############# #####################

package provide linenoise 1.3
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
