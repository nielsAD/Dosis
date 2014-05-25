Dosis
=====

Adds a `TreeMap` tab to the file properties dialog in Windows Explorer. This tab displays an interactive [treemap](http://en.wikipedia.org/wiki/Treemapping) visualization of the directory layout according to the relative size of files and folders. The following gif displays the treemap for a directory called `MinGW`:

![Demo](https://raw.githubusercontent.com/nielsAD/Dosis/master/demo.gif)

The tab is visible when at least one directory **or** multiple files are selected. Left click on a directory in the treemap zooms in. Zooming out is done with a right mouse click or a click on the ellipses in the upper left corner.

Installation
------------

Download the [latest release](https://github.com/nielsAD/Dosis/releases/latest). There are two versions available. You need only one, depending on your architecture. If you are running a 64-bit version of Windows, download the `_x64` release, otherwise download the `x_86` release. The library can be placed in an arbitrary directory.

Open command prompt (`Win+R` hotkey, enter `cmd` and press OK) and navigate to the library folder (`cd ENTER YOUR FOLDER HERE`). Then, register the library with `regsvr32 DoSiS_x86.dll` (`_x64` if you're running 64-bit Windows).

Removal of the library is done in a similar fashion: follow the steps above, but use `regsvr32 /u DoSiS_x86.dll` (`_x64` respectively) for the last step.
