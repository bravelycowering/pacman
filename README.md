# bravelycowering/pacman

This is a PAC-MAN clone written in Lua with LOVE2D I started a while back because Namco took PAC-MAN off of the Google Play Store and i wanted to play pac man on my phone. It comes with an imgui-based level editor and a mobile UI.

Be warned, code is messy. This is just a project for me to enjoy and learn from, but I figured someone else might find this useful, feel free to fork. I've tried to make this fairly accurate to the original arcade game, but I'm not writing this in z80 assembly, so inaccuracies are inevitable. The [issues](https://github.com/bravelycowering/pacman/issues) have a list of some inaccuracies and bugs I've encountered.

Pull requests for small things are welcome, but at the end of the day this is still just my personal hobby project.

This project also contains a slightly modified version of [apicici/cimgui-love](https://codeberg.org/apicici/cimgui-love/src/branch/main).

## Running

You will need to install [LOVE2D](https://love2d.org/), at which point you can run the project by using the `love` command (`lovec` on Windows). Using the editor requires a separate cimgui shared library for the UI, along with LOVE2D 12 for the file chooser.
