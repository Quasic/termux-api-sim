# termux-api-sim
Testing tools to simulate calls to exposed API methods in the [Termux:API](https://github.com/termux/termux-api) app in a headless environment for testing purposes, like other scripted event tools.

## Work in progress
This is currently a work in progress. As need arises, or the inspiration hits me, I convert a .in file into a .sh simulation. I plan to rebase on termux updates from time to time.

## Installation

run dash install.sh [options|--help] <bin install dir>

## Usage

A lot of the commands leave temporary files behind when run. These files can be placed into a directory given by environment variable $TERMUX_SIM_DIR. They also have individual ones that override that one. If neither is set the default is one of /dev/shm, /tmp, or the home directory are used, in that order of precedence.

Currently functional simulations:
* termux-clipboard-get reads the clip file created by termux-clipboard-set ($TERMUX_CLIPFILE can be used to select which one)
* termux-clipboard-set creates a file named termux.clip in $TERMUX_SIM_DIR or default directory. This may be changed by setting TERMUX_CLIPFILE to the file path to use, (absolute path recommended.)
* termux-dialog simulates user input, either randomly or by following queues in $TERMUX_DIALOG_SIM, title or hint text, whichever matches first (I am currently working on supporting more widgets)
* termux-toast creates a file named termux.toast in $TERMUX_SIM_DIR or default directory. This may be changed by setting TERMUX_TOASTFILE to the file path to use, (absolute path recommended.)
* termux-torch creates a file named termux.torch in $TERMUX_SIM_DIR or default directory. This may be changed by setting TERMUX_TORCHFILE to the file path to use, (absolute path recommended.)


## License
MIT, as I based this on the original scripts under that license.

## References
This is a fork from [termux/termux-api-package](https://github.com/termux/termux-api-package) and [termux/termux-api](https://github.com/termux/termux-api-package) was used for reference.
