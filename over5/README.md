Over5 - Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
------------------------------------------------------------------

This directory contains the source code for the Amiga programs of
the Over5 package.

Over5 on the WWW: (contains the latest release)
  http://www.stacken.kth.se/~tlr/computing/over5.html

If you modify this, and want the modifications to be released then
send me the new code (source additions), and I will release it as
soon as possible. (with proper credit to you of course.)

I would very much like bug fixes but please don't release any
versions of these programs yourself.  Send your updates to me
and I will administrate the releases.

You need:
  SAS/C 6.51 by SAS Institute Inc or compatible
  'Flexrev' 0.55 or later by Daniel Kahlin


NOTE:
  All C-files '.c' & '.h' are written with tabsize=2, and all
  ASM-files '.asm' & '.i' are written with tabsize=8.


Source files:
  main.h                     - protos and defs for 'main.c'
  main.c                     - the main program
  mach.h                     - protos and defs for 'mach.c'
  mach.c                     - most of the machine dependant code
  cbm.h                      - protos and defs for 'cbm_*'
  cbm_zipcode.c              - zipcode/uncode diskimages
  cbm_directory.c            - directory code for cbm
  convert.h                  - protos and defs for 'convert.c'
  convert.c                  - filename conversion (petscii)
  config_file.h              - protos and defs for 'config_file.c'
  config_file.c              - config file parser

  o5.h                       - protos and defs for 'o5_*'
  o5_disk.c                  - disk commands
  o5_file.c                  - file commands
  o5_memory.c                - memory commands
  o5_server.c                - server commands
  o5_simple.c                - simple commands (BOOT)

  o5protocol.h               - defs and structs for the protocol

  protocol.h                 - protos and defs for 'pr_*'
  pr_protocol.c              - most high level protocols
  pr_server.c                - server code
  pr_simple.c                - FastRS and boot support
  pr_support.c               - body send/receive, etc...

  block.h                    - protos and defs for 'bl_*'
  bl_block.c                 - block transfer routines (not dep)
  bl_serial.c                - serial routines

  booter.asm                 - the new bootcode (6502 asm) 
  copytail64.asm             - the old copytail code for booting (6502 asm)
  booter.h                   - c-source of booter.asm
  copytail64.h               - c-source of copytail.asm

  Main_rev.h                 - autogenerated revision file
  Makefile                   - Smake makefile
  README                     - this file


Snail:
  Daniel Kahlin
  Vanadisv�gen 6, 2tr
  s-113 46 Stockholm
  SWEDEN
Email: <tlr@stacken.kth.se>


/Daniel Kahlin <tlr@stacken.kth.se>