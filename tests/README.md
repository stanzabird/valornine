Example files:
==============

This folder contains example template files for use with the
valornine tool.

* binary.vn = example use of binary files
* c.vn = simple C language example
* c++.vn = some C++ templates
* updowncase.vn = usage of upcase filters

To put all these .vn files into one big one for use as your
default template that contains everything, there are two scripts.

- First, you type './make-world.sh' to create the 'world.vn' file.
- Then type './show-vars.sh > vars.txt'
- start up your editor, load 'world.vn' and put the contents of 'vars.txt
  at the begining of world.vn, optionally sanitizing it.
- now make it your default template: mv world.vn ~/.default.vn

Available scripts:

* make-world.sh = copy all .vn files into one file called 'world.vn'
* show-all.sh = list projects in all .vn files in this folder
* show-vars.sh = prints all variables in all .vn files
