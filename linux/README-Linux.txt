Elospeed LedPreResistor for Linux
=================================

Calculates the series resistor for LEDs. Free software (MIT licence).
Project page: https://elospeed.github.io/LedPreResistor/

Start
-----
Unpack the archive and run ./LedPreResistor in the folder.
Nothing to install.

Needs GTK2 (already present on most systems). If the program does not
start, install GTK2:
  Debian/Ubuntu/Mint:  sudo apt install libgtk2.0-0
                       (Ubuntu 24.04 and later: libgtk2.0-0t64)
  Fedora:              sudo dnf install gtk2
  Arch:                sudo pacman -S gtk2

Add to the application menu (optional, no root)
-----------------------------------------------
  ./install.sh              installs program, icon and menu entry
  ./install.sh --uninstall  removes everything again

Settings
--------
The chosen language is stored in ~/.config/LedPreResistor/LedPreResistor.ini.
