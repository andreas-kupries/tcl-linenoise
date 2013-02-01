# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## A Tcl Binding to antirez's linenoise (Minimal line-editing)
## as modified and extended by Steve Bennett of Workware.
##
## Copyright (c) 2013 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries

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
# - Note: Do I need the utf support, or is that term specific.
# - Note: Use (void)-cast in IGNORE_RC istead of "if (EXPR)"?!
# - Idea: Handle Page Up/Down keys to jump to history start/end.
# - Idea: Allow edit mode "hidden input" for password entry and the like.
# - Idea: Put ^K deleted text into a paste buffer, and allow re-entry
#         via ^Y (see bash)
#         Note that ^K works in history of bash, with ^Y in current buffer.

# # ## ### ##### ######## ############# #####################
## Requisites

package require critcl 3.1
critcl::buildrequirement {}

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
## Find the linenoise sources (via its headers).
#
# We try to specify both paths for where we expect to find the sources
# of linenoise itself. Both are given relative to the directory of
# this file.
#
# (1) A sub directory in our sources.
# (2) A sibling directory to our sources.

if {[catch {
    critcl::cheaders linenoise/linenoise.h
}]} {
    critcl::cheaders ../linenoise/linenoise.h
}

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
## - clear screen
## - prompt for input, possibly with completion

critcl::cproc linenoise::hidden_set {boolean enable} void {
    linenoiseSetHidden (enable);
}
critcl::cproc linenoise::hidden_get {} boolean {
    return linenoiseGetHidden ();
}

if 0 {# may we have this ?
critcl::cproc linenoise::clear {} void {
    linenoiseClearScreen ();
}}

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

package provide linenoise 0
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
