This section describe the available commands.

[para] All of them are found under the [cmd linenoise] ensemble
command.

[list_begin definitions]
[call [cmd {linenoise cmdloop}] [opt options...]]

This command implements the core of a REPL (read-eval-print
loop). While the defaults of the various options are geared towards
the REPL of a Tcl shell, other types of REPL can implemented just fine
by overriding them with the proper callbacks. By default the loop can
be aborted only by entering Control-C on the keyboard, or equivalent. 

[para] The recognized options are

[list_begin options]
[opt_def -complete cmdprefix]

The value of this option is a command prefix taking the current
contents of the line buffer as its single argument and returning a
list of possible completions. The default is the empty command,
disabling command completion.

[opt_def -continued cmdprefix]

The value of this option is a command prefix taking the user-entered
line as its single argument and returning a boolean value telling the
REPL if the line is incomplete and needs more input, i.e. a
"continuation line".

The default value recognizes incomplete Tcl command lines.

[opt_def -dispatch cmdprefix]

The value of this option is a command prefix taking the user-entered
line(s), i.e. command as its single argument and executing it. The
result of the command is the result of the command prefix, and
delivered to option [option -report] for printing. Errors thrown by
the execution are caught and printed through [option -report] as well.

The default value simply runs the command in the context calling the
REPL.

[opt_def -exit cmdprefix]

The value of this option is a command prefix taking no arguments and
returning a boolean value indicating if the command loop should be
stopped ([const true]), or not. The default value never stops the loop.

[opt_def -history boolean]

The value of this option specifies if the command should put the
entered strings into the history ([const true]), or not. The default
value is [const false], leaving the history untouched.

[opt_def -prompt1 cmdprefix]

The value of this option is a command prefix without arguments.  Its
result is treated as the main (primary) prompt used by the REPL. This
callback is run for each iteration of the main loop, allowing for
changes to the prompt in response to a changing system state.

The default value returns "[const {% }]".

[opt_def -prompt2 cmdprefix]

The value of this option is a command prefix without arguments.  Its
result is treated as the secondary prompt used by the REPL, when
entering continuation lines. This callback is run for each iteration
of the secondary loop, allowing for changes to the prompt in response
to a changing system state.

The default value returns "[const {> }]".

[opt_def -report cmdprefix]

The value of this option is a command prefix taking two arguments, the
type of a command result ([const ok], or [const fail]), and the result
itself, and "printing" this data in some way.

The default value prints ok result to stdout and fail results to
stderr.

[list_end]

[call [cmd {linenoise columns}]]

This command returns the current width of the console window the
package is talking to. This enables the user to adapt its output (for
example help texts) to the console.

[call [cmd {linenoise hidden}] [opt [arg enable]]]

This command returns the current state of the system's hidden flag,
which is [const true] if hidden input is activated, and [const false]
otherwise. If the argument is specified it has to be a boolean value
which becomes the new value of the flag. This new value is then returned.

[call [cmd {linenoise history add}] [arg string]]

This command adds the [arg string] to the history. The result of the
command is a boolean flag, [const true] if the addition suceeded, and
[const false] otherwise. The string will not be added if it is
identical to the last entry of the history, preventing entry of
adjacent duplicates.

[para] The history reaching its maximal size does not prevent the
addition of the string. It simply bumps of the oldest entry to make
room for the new.

[call [cmd {linenoise history clear}]]

This command clears (empties) the history.

[call [cmd {linenoise history list}]]

This command returns a list containing the history. The first element
of the result is the oldest entry in the history, and the last element
the newest.

[call [cmd {linenoise history load}] [arg path]]

This command loads the contents of the file at [arg path] into the
history. Note, this is not a replacement, but an appending, like with
[cmd {linenoise history add}].

[call [cmd {linenoise history maxsize}] [opt [arg n]]]

This command returns the current maximal size of the system's history,
as a positive integer number greater than zero. If the argument is
specified it has to be a positive integer number greater than zero,
which becomes the new maximal size of the history. This new value is
then returned.

[para] If the new maximal size is less than the current size of the
history the oldest entries are discarded to bring the history down to
the new size.

[call [cmd {linenoise history save}] [arg path]]

This command takes the history and stores it into the file at the
specified [arg path]. The previous contents of the file are written
over and lost.

[call [cmd {linenoise history size}]]

This command returns the number of entries in the history, as positive
integer number (including zero).

[call [cmd {linenoise prompt}] [opt options...]]

This command implements a one-shot prompt (instead of a REPL),
returning the string entered by the user after completing the
interaction.

[para] The recognized options are similar to what is recognized by
[cmd cmdloop], albeit reduced and simplified:

[list_begin options]
[opt_def -complete cmdprefix]

The value of this option is a command prefix taking the current
contents of the line buffer as its single argument and returning a
list of possible completions. The default is the empty command,
disabling command completion.

[opt_def -hidden boolean]

The value of this option specifies if the command should hide user
input ([const true]), or not. The default value is [const false], for
visible line entry. A use case for this option is the entry of
passwords and the like.

[opt_def -history boolean]

The value of this option specifies if the command should put the
entered string into the history ([const true]), or not. The default
value is [const false], leaving the history untouched.

[opt_def -prompt string]

The value of this option is the string to use as the prompt. The
default value is "[const {% }]".

[list_end]
[list_end]
