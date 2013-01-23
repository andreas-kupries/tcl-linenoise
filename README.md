# Tcl Binding to the Linenoise minimal line editor

 *  Welcome to TclLinnoise, a line editor based on the linenoise library.

# Website

 *  The main website of this project is http://andreas-kupries.github.com/tcl-linenoise

    It provides access to archives for various revisions and the full
    documentation, especially the guides to building and using it.

    Because of the latter this document contains only the most basic
    instructions on getting, building, and using TclLinenoise.

# Versions

 *  Version 1 is the actively developed version of TclLineNoise.

# Getting, Building, and Using TclLineNoise

 *  Retrieve the sources:

    ```% git clone http://github.com/andreas-kupries/tcllinenoise```

    Your working directory now contains a directory ```tcllinenoise```.

 *  Build and install it:

    Install requisites: linenoise itself.

    Create a link from within the tcl-linenoise top directory to
    linenoise itself. Or copy linenoise into a subdirectory of that
    name.

    ```% cd tcl-linenoise```

    ```% tclsh ./build.tcl install```

    The generated package is placed into the **[info library]**
    directory of the **tclsh** used to run build.tcl. This may require
    administrative (root) permissions, depending on the system setup.

 *  It is expected that a working C compiler is available. Installation and
    setup of such a compiler is platform and vendor specific, and instructions
    for doing so are very much outside of scope for this document. Please find
    and read the documentation, how-tos, etc. for your platform or vendor.

 *  With tcl-linenoise installed try out one of the examples:

# Documentation

 *  Too much to cover here. Please go to
    http://andreas-kupries.github.com/tcl-linenoise
    for online reading, or the directories **embedded/www** and
    **embedded/man** for local copies of the documentation in HTML and
    nroff formats, respectively.
