over5 is a program for transferring between c64/vic20 machines and
Amiga/PC/UNIX boxes.

It supports serial transfer at 38400 bps using only a RS-232 level
converter and a 3-line standard nullmodem cable.  No special serialport
chips are needed.  It features read/write/execute memory, filecopy with
wildcards, read/write raw disk, read/write ZIPCODE archive, the ability
to use the Amiga/PC/UNIX box as a harddisk server ($0801-$f600),
builtin diskturbo, and a fast basic bootstrap for most cbm 8-bitters.

See the file INSTALL for building and installation instructions.
See the file INSTALL.cbm for instructions on how to transfer the binaries
to your cbm-machine.
This is beta software, see the file BUGS for more information.

common mistake:
  If the error 'Over5: Permission denied!' occurs, you have probably
forgotten to set the right device in .over5rc, or maybe the permissions
on the device are messed up.

CONTACT:
  If you find this program useful, have suggestions and/or comments
please mail the team at <over5@kahlin.net>, so that we know that 
further development is wanted.

/Daniel Kahlin 


Here follows Andreas' original notes:

README for the Linux version (well, sort of...)
-----------------------------------------------

** For more general issues, check out the main README file (Over5.readme)
** and all the files in the 'doc' subdirectory.

Everything seems to be working fine (if a bit slow) now. It needs a
little bit more work to be able to compile right away for more OS:es.
I didn't have a c64 handy, so I haven't actually tested Over5 under any
other OS or even on any other computer than my own, but it _could_ work
(yeah, right ;).

This is uname output from some systems I've at least gotten it to compile on:
(So you know what to expect.)

Linux 2.2.16-9mdk i686 **verified**
SunOS 5.6 sparc
OSF1 V4.0 alpha
Also I'm hoping to test it on IRIX 6.4 soon...

On most of these systems I have no access whatsoever to the actual hardware,
so naturally I haven't tested anything on them. The only real problem is
that some parts of the original code seems to think that pointers can be no
more than 32 bits long. I'm not sure if this will be a problem though, but
I get warnings about it from gcc...

If you try it with any configuration significantly different from mine
(The Linux one above of course) please let me know if it works. (If it bombs,
there's an even bigger reason to let me know of course.) It should work just
as well on _a lot_ older machines, but who knows.

Differences from Amiga/win32 versions:
--------------------------------------

The executable is named 'over5'.

The config file is named '.over5rc' and must exist in either your home
directory (the dir pointed to by your HOME environment variable that is) or
the directory you are in when you run over5. If over5 can't find the config
file, no warning is given, but default settings of DEVICE=8 and
SERIALDEVICE=/dev/ttyS0 are used.

The 'SERIALDEVICE' entry in the config file should of course be something like
'/dev/ttySx' (where x is 0-3 on your 'normal' pc) rather than 'serial.device'
(for the Amiga) or 'COMx' (for the win32 version).

There is an example '.over5rc' file in the 'over5' subdir. Edit it to your
liking and copy it to your homedir (or make a link to it of course).

Bugs(!):
--------

If you're using a 1571, you _have_to_disable_the_diskturbo_ when reading
single files with Diskslave. This applies to all versions.
A timing bug from hell has turned up in the diskturbo that only shows on
my machine (a C128DCR). (I will try to fix it, but it's kind of low
priority at the moment. Plus it's not my code.)

Other things still left to do:
------------------------------

GetSerialError() is a bit ugly, so serial error reporting can be fairly
crappy at times. The error handling _is_ there, doing it's job. It just
never brags about it :)

The autoconf support is kind of stupid. I might improve it in the future.
(*It is a bit improved now but it's still stupid*)

Some kind of translation of filenames. Right now only filnames with
CAPITAL letters are worth using. I haven't really found a good way around
this yet. (Every solution I could think of was evil in its own way...)

/pitch <e92_aan@e.kth.se>

EOF
