STOW CLONE
----------

### Introduction
This is a simple PowerShell script that wants to emulate GNU Stow's
behaviour on Windows. As of now it really just takes all the files in the given
directory and link them to the specified target.

### Installation
As of now there is no installation method. Also I do not recommend installing it
since it is going to be split in multiple files and modules.  
Just run it like this '.\Main.ps1 \<arguments\>'

### Usage
To understand this program's syntax just run `Main.ps1 -?`, this will give you a
list of possible commands. If you don't really know why this is useful to me, well
let's say you have multiple files, like Dockerfiles, batch scripts or maybe
configuration files for gvim and other programs. These files should be put in
different directories, some of them in a specific path like *shell:startup* while
others are organized in you Desktop, Documents or anything else. Keeping track of
them will eventually bring you to madness. With this script you can have all of
them in one single directory and automatically link them to where those files
should be put.
