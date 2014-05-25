Dosis
=====
Adds a `TreeMap` tab to the file properties dialog in Windows Explorer. This tab displays an interactive [treemap](http://en.wikipedia.org/wiki/Treemapping) visualization of the directory layout according to the relative size of files and folders. The following gif displays the treemap for a directory called `MinGW`:

![Demo](https://raw.githubusercontent.com/nielsAD/Dosis/master/demo.gif)

The tab is visible when at least one directory **or** multiple files are selected. Left click on a directory in the treemap zooms in. Zooming out is done with a right mouse click or a click on the ellipses in the upper left corner.

Requirements
------------
* Windows XP or newer
* Internet Explorer 8+

For development of the plugin, [Delphi](http://www.embarcadero.com/products/delphi) is required.

Installation
------------
Download the [latest release](https://github.com/nielsAD/Dosis/releases/latest). There are two versions available. You need only one, depending on your architecture. If you are running a 64-bit version of Windows, download the `_x64` release, otherwise download the `x_86` release. The library can be placed in an arbitrary directory.

Open command prompt (`Win+R` hotkey, enter `cmd` and press OK) and navigate to the library folder (`cd ENTER YOUR FOLDER HERE`). Then, register the library with `regsvr32 DoSiS_x86.dll` (`_x64` if you're running 64-bit Windows).

Removal of the library is done in a similar fashion: follow the steps above, but use `regsvr32 /u DoSiS_x86.dll` (`_x64` respectively) for the last step.

Development
-----------
Pull requests are welcome! There are two parts to this plugin. The interface to the file system and integration with the file dialog is implemented in Delphi (see `/src/Sheet`). The user interface is written in HTML5, CSS, and Javascript (see `/src/TreeMap`). Development of either part is encouraged; I welcome pull requests!

It is possible to develop the user interface without compiling the plugin. Install the library in the `/src` folder to load the user interface directly from the `/src/TreeMap` directory, instead of the plugin's resources.

Credits
-------
* [JavaScript InfoVis Toolkit](http://philogb.github.io/jit/)
* [Jason Penny](github.com/jasonpenny/twebbrowser.utilities)
* [Explorer Canvas](https://code.google.com/p/explorercanvas/) - Apache License 2.0
* [SpinKit](http://tobiasahlin.com/spinkit/) - MIT License
* [P.D. Johnson](http://delphidabbler.com/articles?article=18) - Lesser GPL

Alternatives
------------
* [WinDirStat](https://windirstat.info/)
* [Space Sniffer](http://www.uderzo.it/main_products/space_sniffer/index.html)
* [KDirStat](http://kdirstat.sourceforge.net/) (Linux)
* [Boabab](https://wiki.gnome.org/Apps/Baobab) (Linux)
